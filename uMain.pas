unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, Vcl.StdCtrls, Vcl.Buttons,
  IdContext, Vcl.ExtCtrls, Vcl.Menus, Winsock, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.FileCtrl,
  JvComponentBase, JvDragDrop, IdIPWatch, Vcl.ComCtrls, IdTCPConnection,
  IdTCPClient, IdHTTP, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL;

type
  TFileInfo = record
    Icon : hIcon;
    Image : Integer;
    DisplayName : String;
    TypeName : String;
    Size : Integer;
    SizeDescription : String;
    DateTime : TDateTime;
    AttrArchive : Boolean;
    AttrReadOnly : Boolean;
    AttrSystem : Boolean;
    AttrHidden : Boolean;
    AttrVolume : Boolean;
    AttrDirectory : Boolean;
  end;

type
  TfrmMain = class(TForm)
    sbStart: TSpeedButton;
    sbStop: TSpeedButton;
    mLog: TMemo;
    Servidor: TIdHTTPServer;
    lbledt: TLabeledEdit;
    ImageList1: TImageList;
    Image1: TImage;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Close1: TMenuItem;
    N1: TMenuItem;
    Startserver1: TMenuItem;
    Stopserver1: TMenuItem;
    Label1: TLabel;
    PopupMenu2: TPopupMenu;
    pmnuDelete: TMenuItem;
    pmnuRename: TMenuItem;
    IdIPWatch1: TIdIPWatch;
    Label3: TLabel;
    lblhttp: TLinkLabel;
    FileList: TListView;
    ImageList2: TImageList;
    idHTTP: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    FileIcons: TImageList;
    StatusBar: TStatusBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    mnClose: TMenuItem;
    mnuSaveAs: TMenuItem;
    N3: TMenuItem;
    SaveDialog: TSaveDialog;
    pmnuOpen: TMenuItem;
    N2: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    sbCopyURL: TSpeedButton;
    N4: TMenuItem;
    Checkall1: TMenuItem;
    Selectall1: TMenuItem;
    N5: TMenuItem;
    CopyURL1: TMenuItem;
    pmnuSaveAs: TMenuItem;
    N6: TMenuItem;
    procedure sbStartClick(Sender: TObject);
    procedure ServidorCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure sbStopClick(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure pmnuDeleteClick(Sender: TObject);
    procedure pmnuRenameClick(Sender: TObject);
    procedure FileListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FileListEdited(Sender: TObject; Item: TListItem; var S: string);
    procedure FileListColumnClick(Sender: TObject; Column: TListColumn);
    procedure FileListCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure mnCloseClick(Sender: TObject);
    procedure mnuSaveAsClick(Sender: TObject);
    procedure FileListItemChecked(Sender: TObject; Item: TListItem);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure pmnuOpenClick(Sender: TObject);
    procedure FileListDblClick(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure sbCopyURLClick(Sender: TObject);
    procedure Checkall1Click(Sender: TObject);
    procedure Selectall1Click(Sender: TObject);
  private
    { Private declarations }
    Descending: Boolean;
    SortedColumn: Integer;
    procedure AddFile(const FileName: string);
    function  IsSupportedFileType(const FileName: string): Boolean;

  public
    { Public declarations }
    // declare our DROPFILES message handler
    procedure AcceptFiles( var msg : TMessage ); message WM_DROPFILES;
    function GetIPLocal: string;
    procedure MakeBasFile;
    procedure ShowFiles;
    function txt2bas (filename : String): string;
    procedure HTTPGetFile;
    function FormatByteSize(const bytes: int64): string;
    procedure scGetFileInfo(StrPath : String; var Info : TFileInfo);
    function  scGetSizeDescription(const IntSize : Int64) : String;
    procedure CreateZIPfile(filename : String);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ShellApi, ClipBrd, idMultipartFormData,
  System.Math, System.Zip;

{$R *.dfm}
const
  cSupportedExts = '*.bas;*.tap;*.tzx;*.z80;*.sna;*.zip;';

// ----------------------------------------------------------------
// Return string with formatted file size (bytes, Kb, Mb or Gb)
// ----------------------------------------------------------------
function TfrmMain.scGetSizeDescription(const IntSize : Int64) : String;
begin
  if IntSize < 1024 then
    Result := IntToStr(IntSize)+' bytes'
  else
  begin
    if IntSize < (1024 * 1024) then
      Result := FormatFloat('####0.##',IntSize / 1024)+' Kb'
    else
      if IntSize < (1024 * 1024 * 1024) then
        Result := FormatFloat('####0.##',IntSize / 1024 / 1024)+' Mb'
      else
        Result := FormatFloat('####0.##',IntSize / 1024 / 1024 / 1024)+' Gb';
  end;
end;

// ----------------------------------------------------------------
// Return record with all information about given file
// How to use icon : ImageFile.Picture.Icon.Handle:=Info.Icon;
// ----------------------------------------------------------------
procedure TfrmMain.scGetFileInfo(StrPath : String; var Info : TFileInfo);
var
  SHFileInfo : TSHFileInfo;
  SearchRec : TSearchRec;
begin
  if Trim(StrPath) = '' then
    Exit;

  ShGetFileInfo(PChar(StrPath), 0, SHFileInfo, SizeOf (TSHFileInfo),
    SHGFI_TYPENAME or SHGFI_DISPLAYNAME or SHGFI_SYSICONINDEX or SHGFI_ICON);

  with Info do
  begin
    Icon  := SHFileInfo.hIcon;
    Image := SHFileInfo.iIcon;
    DisplayName := SHFileInfo.szDisplayName;
    TypeName := SHFileInfo.szTypeName;
  end;

  FindFirst(StrPath, 0, SearchRec);
  with Info do
  begin
    try
      DateTime := FileDateToDateTime(SearchRec.Time);
    except
      DateTime := Now();
    end;

    AttrReadOnly := ((SearchRec.Attr and faReadOnly) > 0);
    AttrSystem := ((SearchRec.Attr and faSysFile) > 0);
    AttrHidden := ((SearchRec.Attr and faHidden) > 0);
    AttrArchive := ((SearchRec.Attr and faArchive) > 0);
    AttrVolume := ((SearchRec.Attr and faVolumeID) > 0);
    AttrDirectory := ((SearchRec.Attr and faDirectory) > 0);

    Size := SearchRec.Size;

    SizeDescription := scGetSizeDescription(Size);
  end;
end;

procedure TfrmMain.Checkall1Click(Sender: TObject);
var
  i : Integer;
begin
  if FileList.Items = nil then
    exit;
  for i := 0 to FileList.Items.Count -1 do
    begin
       FileList.Items[i].Checked := True;
    end;
end;

procedure TfrmMain.Close1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.mnCloseClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.FileListColumnClick(Sender: TObject; Column: TListColumn);
begin
  // Sort by column ASC/DES

  TListView(Sender).SortType := stNone;

  if Column.Index<>SortedColumn then
  begin
    SortedColumn := Column.Index;
    Descending := False;
  end
  else
    Descending := not Descending;
    TListView(Sender).SortType := stText;
end;

procedure TfrmMain.FileListCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
begin

  if SortedColumn = 0 then Compare := CompareText(Item1.Caption, Item2.Caption)
  else
    if SortedColumn <> 0 then Compare := CompareText(Item1.SubItems[SortedColumn-1], Item2.SubItems[SortedColumn-1]);
  if Descending then Compare := -Compare;

end;

procedure TfrmMain.FileListDblClick(Sender: TObject);
begin
  if FileList.Selected <> nil then
    pmnuOpen.OnClick(Self);

end;

procedure TfrmMain.FileListEdited(Sender: TObject; Item: TListItem;
  var S: string);
var
  sFile, NewName : String;

begin
  sFile := Item.Caption;
  RenameFile(sFile, S);
  ShowFiles;
end;

procedure TfrmMain.FileListItemChecked(Sender: TObject; Item: TListItem);
var
  iCount, i : Integer;
  s1, s2 : String;
begin
  s1 := ' checked item';
  s2 := ' checked items';
  iCount := 0;

  for i := 0 to FileList.Items.Count -1 do
  begin
      if FileList.Items[i].Checked then
      begin
        iCount := iCount + 1;

      end;
  end;
  if iCount = 1 then
    StatusBar.Panels[4].Text := IntToStr(iCount) + s1
  else
    StatusBar.Panels[4].Text := IntToStr(iCount) + s2;

end;

procedure TfrmMain.FileListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  iCount, i : Integer;
  s1, s2 : String;

begin
  if Selected then
  begin
    lblhttp.Caption :='.http -h /' + GetIPLocal +' -u /' + Item.Caption + ' -f ' +
    Item.Caption;
    PopupMenu2.AutoPopup := True;
  end;

  s1 := ' selected item';
  s2 := ' selected items';
  iCount := 0;

  for i := 0 to FileList.Items.Count -1 do
  begin
      if FileList.Items[i].Selected then
      begin
        iCount := iCount + 1;
      end;
  end;
  if iCount = 1 then
    StatusBar.Panels[4].Text := IntToStr(iCount) + s1
  else
    StatusBar.Panels[4].Text := IntToStr(iCount) + s2;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Visible := false;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (Sender is TPopupMenu) then
    CanClose := True
  else
  begin
    CanClose := False;
    Hide;
  end;

end;

function TfrmMain.FormatByteSize(const bytes: int64): string;
const
  B = 1; //byte
  KB = (1024 * B); //kilobyte
  MB = 1024 * KB; //megabyte
  GB = 1024 * MB; //gigabyte
begin
  if bytes > GB then
    result := FormatFloat('#.## GB', bytes / GB)
  else if bytes > MB then
    result := FormatFloat('#.## MB', bytes / MB)
  else if bytes > KB then
    result := FormatFloat('#.## KB', bytes / KB)
  else
    if bytes > 0 then
      result := FormatFloat('#.## bytes', bytes)
   else
   result := FormatFloat('0 bytes', bytes);
end;

procedure TfrmMain.ShowFiles;
  var li:TListItem;
    SR: TSearchRec;
    Filetype : String;
    fileinfo : TFileInfo;
begin

    FileList.Items.BeginUpdate;
    try
        FileList.Items.Clear;
        FindFirst(ExtractFilePath(Application.ExeName) +'*.*', faAnyFile, SR);
        try
            repeat
                if IsSupportedFileType(SR.Name) then
                begin
                  scGetFileInfo(SR.Name, fileinfo);
                  li :=  FileList.Items.Add;
                  li.Caption := SR.Name;

                  li.SubItems.Add(FormatByteSize(SR.Size));
                  li.SubItems.Add(FormatDateTime('dd/mm/yy hh:nn', SR.TimeStamp));
                  li.SubItems.Add(fileinfo.TypeName);
                  li.ImageIndex := 1;

                  if ((SR.Attr and faDirectory) <> 0)  then li.ImageIndex := 1
                  else li.ImageIndex := 0;
                end;

            until (FindNext(SR) <> 0);
        finally
            FindClose(SR);
        end;
    finally
        FileList.Items.EndUpdate;
        if FileList.Items.Count > -1 then
          FileList.Items[0].Selected := True;
    end;
    StatusBar.Panels[3].Text := IntToStr(FileList.Items.Count) + ' Items';
end;


procedure TfrmMain.sbCopyURLClick(Sender: TObject);
begin
  Clipboard.AsText := lblhttp.Caption;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  //
  ShowFiles;
  ChangeWindowMessageFilter (WM_DROPFILES, MSGFLT_ADD);
  ChangeWindowMessageFilter (WM_COPYGLOBALDATA, MSGFLT_ADD);
  DragAcceptFiles(Handle, True);
  Hide;
  StatusBar.Panels[4].Text := '0 selected items';
  //PopupMenu2.AutoPopup := false;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Self.Handle, False);
end;

procedure TfrmMain.sbStartClick(Sender: TObject);
begin
  Servidor.DefaultPort := StrToInt(lbledt.Text);
  Servidor.Active := True;
  mLog.Lines.Add( 'Started server on port ' + lbledt.Text + ' ...');
  sbStart.Enabled := False;
  sbStop.Enabled := True;
  TrayIcon1.BalloonHint := 'Server started...';
  StatusBar.Panels[1].Text := 'Running';
end;

procedure TfrmMain.sbStopClick(Sender: TObject);
begin
  Servidor.Active := False;
  mLog.Lines.Add( 'Stopped server' );
  sbStart.Enabled := true;
  sbStop.Enabled := false;
  TrayIcon1.BalloonHint := 'Stopped server';
  StatusBar.Panels[1].Text := 'Stopped';
end;

procedure TfrmMain.Selectall1Click(Sender: TObject);
var
  i : Integer;
begin
  if FileList.Items = nil then
    exit;
  for i := 0 to FileList.Items.Count -1 do
    begin
       FileList.Items[i].Selected := True;
    end;
end;

procedure TfrmMain.ServidorCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

var
  sDocumento: String;
begin
  mLog.Lines.Add( ARequestInfo.RemoteIP  + ': ' +
    ARequestInfo.Command + ARequestInfo.Document );

  // mainpage?
  if ARequestInfo.Document = '/' then
    AResponseInfo.ServeFile( AContext, ExtractFilePath( Application.ExeName ) + 'index.html' )
  else
  begin
    // Load page to send
    sDocumento := ExtractFilePath( Application.ExeName ) +
      Copy( ARequestInfo.Document, 2, Length( ARequestInfo.Document ) );

    // ¿Existe la página que ha solicitado?
    if FileExists( sDocumento ) then
    begin
      // valid user
      {if not ( ( ARequestInfo.AuthUsername = 'admin' ) and
        ( ARequestInfo.AuthPassword = '1234' ) ) then
        AResponseInfo.AuthRealm := 'ServidorHTTP'
      else
      }
        AResponseInfo.ServeFile( AContext, sDocumento );
        AResponseInfo.ResponseNo := 200;
        mLog.Lines.Add(AResponseInfo.ResponseText);
    end
    else
      // Can't find page
      AResponseInfo.ResponseNo := 404;
  end;
  AResponseInfo.CloseConnection := True;
end;

procedure TfrmMain.TrayIcon1DblClick(Sender: TObject);
begin
  Visible :=  True;
end;

procedure TfrmMain.AddFile(const FileName: string);
var
  RealFileName : String;
begin
  if IsSupportedFileType(FileName) then
  begin
    RealFileName := ExtractFileName(FileName);
    CopyFile(PChar(FileName), PChar(Application.GetNamePath+RealFileName), false);
    ShowFiles;
  end

  else
    ShowMessageFmt('File %s is not a supported type', [FileName]);
end;

function TfrmMain.IsSupportedFileType(const FileName: string): Boolean;
begin
  Result := AnsiPos('*' + ExtractFileExt(FileName) + ';', cSupportedExts) > 0;
end;

procedure TfrmMain.pmnuDeleteClick(Sender: TObject);
var
  i : Integer;
begin
  if FileList.Selected = nil then
    exit;

  for i := 0 to FileList.Items.Count -1 do
  begin
    if FileList.Items[i].Selected then
    begin
      DeleteFile(ExtractFilePath(Application.ExeName) +'\' + FileList.Items[i].Caption);
    end;
  end;
  FileList.DeleteSelected;
  ShowFiles;
end;

procedure TfrmMain.pmnuRenameClick(Sender: TObject);
var
  sFile, NewName : String;
begin
  sFile := FileList.Selected.Caption;
  NewName := InputBox('Rename file', 'New name',sFile );
  RenameFile(sFile, NewName);
  ShowFiles;
end;

procedure TfrmMain.PopupMenu2Popup(Sender: TObject);
var
  iSel, i : Integer;
begin
  pmnuRename.Enabled :=  (FileList.SelCount = 1);
  pmnuOpen.Enabled :=  (FileList.SelCount = 1);
  pmnuDelete.Enabled :=  (FileList.SelCount = 1);

  iSel := 0;
  for i := 0 to FileList.Items.Count -1 do
  begin
      if FileList.Items[i].Selected then
        iSel := iSel + 1;
      if FileList.Items[i].Checked then
        pmnuSaveAs.Enabled := True;
  end;
  PopupMenu2.AutoPopup := true;

end;

procedure TfrmMain.mnuSaveAsClick(Sender: TObject);
var
   i, iCount : Integer;
begin
  iCount := 0;
  for i := 0 to FileList.Items.Count -1 do
  begin
      if FileList.Items[i].Checked then
      begin
        iCount := iCount + 1;
      end;
  end;
  if iCount > 0 then
  begin
    SaveDialog.InitialDir := ExtractFilePath(Application.ExeName);
    if SaveDialog.Execute then
    begin
      if SaveDialog.FilterIndex = 1 then
      begin
        // Create a BAS file
        MakeBasFile;
        txt2bas(ExtractFileName(SaveDialog.FileName));
      end
      else
      begin
        // Create a ZIP file
        CreateZIPfile(ExtractFileName(SaveDialog.FileName));
        // Create BAS to load it

      end;
    end;
    ShowFiles;
  end
  else
    ShowMessage('No files were checked. Please checkmark the files you want. ')
end;

procedure TfrmMain.CreateZIPfile(filename : String);
var
  ZipFile: TZipFile;
  i, iCount : Integer;
begin
  try
    ZipFile := TZipFile.Create;
    ZipFile.Open(GetCurrentDir + '\' + filename, zmWrite);

    for i := 0 to FileList.Items.Count -1 do
    begin
        if FileList.Items[i].Checked then
        begin
          ZipFile.Add(FileList.Items[i].Caption);
        end;
    end;
  finally
    MessageDlg('Your zip is ready to be downloaded from your ZX SPectrum Next.', mtInformation, [mbOK], 0);
    ZipFile.Free;
  end;
end;

procedure TfrmMain.About1Click(Sender: TObject);
begin
   ShellAbout(Handle, 'Simple web server".', 'Robert Valverde @2024 ',  Application.Icon.Handle);
end;

procedure TfrmMain.AcceptFiles( var msg : TMessage );
const
  cnMaxFileNameLen = 255;
var
  i,
  nCount     : integer;
  acFileName : array [0..cnMaxFileNameLen] of char;
begin
  // find out how many files we're accepting
  nCount := DragQueryFile( msg.WParam,
                           $FFFFFFFF,
                           acFileName,
                           cnMaxFileNameLen );

  // query Windows one at a time for the file name
  for i := 0 to nCount-1 do
  begin
    DragQueryFile( msg.WParam, i,
                   acFileName, cnMaxFileNameLen );

    // do your thing with the acFileName
    AddFile(acFileName);
    //MessageBox( Handle, acFileName, '', MB_OK );
  end;

  // let Windows know that you're done
  DragFinish( msg.WParam );
end;

function TfrmMain.GetIPLocal: string;
var
   LocalIP: TIdIPWatch;
begin
  LocalIP := TIdIPWatch.Create(nil);
  try
    if LocalIP.LocalIP.Length > 0 then
      Result := LocalIP.LocalIP;
  finally
    LocalIP.Free;
  end;
end;

{function TfrmMain.txt2bas: string;
var
  lHTTP: TIdHTTP;
  lParamList: TStringList;
begin
  lParamList := TStringList.Create;
  lParamList.Add(' -F file=@./download.bas > download.tap');

  lHTTP := TIdHTTP.Create;
  try
    Result := idHTTP.Post('https://zx.remysharp.com/txt2bas',
                         lParamList);
  finally
    lHTTP.Free;
    lParamList.Free;
  end;
end;
}

function TfrmMain.txt2bas (filename : String): string;
var
  sOrigen, sDest  : String;

begin
  sDest := fileName;
  sOrigen := 'download.txt';
  ShellExecute(Handle, nil, 'cmd.exe', PChar('/K curl https://zx.remysharp.com/txt2bas -F file=@./'+ sOrigen +
               ' > ' + sDest), PChar(ExtractFilePath(Application.ExeName)), SW_HIDE); //SW_HIDE
  ShowMessage('Your '+ sDest +' is ready to be downloaded from your ZX Spectrum Next.');
  ShowFiles;
end;


procedure TfrmMain.MakeBasFile;
var
  li:TListItem;
  MyText: TStringlist;
  I, Col: Integer;
begin

  Col := 10;
  MyText:= TStringlist.create;
  try
    MyText.Add('5 REM *** DOWNLOAD BAS FILE');
    MyText.Add('6 INK 7: BORDER 1: PAPER 1: LAYER 1,2: CLS');
    MyText.Add('7 INK 4: PRINT "DOWNLOADING FILES:": INK 7');

    for i := 0 to FileList.Items.Count -1 do
    begin
      li:= FileList.Items[i];
      if li.Checked then
      begin
        MyText.Add(IntToStr(Col) + ' PRINT "' + li.Caption + '...."');
        MyText.Add(IntToStr(Col+1) + ' .http -h 192.168.1.72 -u /' + li.Caption + ' -v 6 -f ' + li.Caption);
        MyText.Add(IntToStr(Col+2) + ' PRINT "OK"');
        Col := Col -1 + 10;
      end;
    end;
    Col := Col +1;
    MyText.Add(IntToStr(Col) + ' PRINT "DOWNLOAD HAS BEEN COMPLETED!"');
    MyText.SaveToFile(ExtractFilePath(Application.ExeName) +  '\download.txt');
    //HTTPGetFile;
  finally
    MyText.Free
  end; {try}
end;

procedure TfrmMain.pmnuOpenClick(Sender: TObject);
begin
  if FileExists(FileList.Selected.Caption) then
    ShellExecute(0, 'open', PChar(FileList.Selected.Caption), nil,
                  nil, SW_SHOWNORMAL); //SW_HIDE

end;

procedure TfrmMain.HTTPGetFile;
var
  IdHTTP: TIdHTTP;
  Params: TIdMultipartFormDataStream;
  LHandler: TIdSSLIOHandlerSocketOpenSSL;
  LOutFile: TFileStream;
  sOrigen, sDest  : String;
begin
  sDest := 'download.bas';
  sOrigen := 'download.txt';
  try
    Params := TIdMultipartFormDataStream.Create;
    try
      Params.AddFile('message', sOrigen);

      IdHTTP := TIdHTTP.Create(nil);
      try
        LHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTP);
        LHandler.SSLOptions.Method := sslvTLSv1;
        IdHTTP.IOHandler := LHandler;

        LOutFile := TFileStream.Create('RecordFileName.bas', fmCreate);
        try
          //IdHTTP.Post('https://esm-db.eu/esmws/eventdata/1/query?eventid=IT-1997-0004&station=CLF&format=ascii', Params, LOutFile);
           IdHTTP.Post('https://zx.remysharp.com/txt2bas -F file=@./'+ sOrigen +' > ' + sDest, Params, LOutFile);
        finally
          LOutFile.Free;
        end;
      finally
        IdHTTP.Free;
      end;
    finally
      Params.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error: ' + E.ToString);
  end;
end;
end.
