unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, Vcl.StdCtrls, Vcl.Buttons,
  IdContext, Vcl.ExtCtrls, Vcl.Menus, Winsock, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, System.Win.TaskbarCore, Vcl.Taskbar, Vcl.FileCtrl,
  JvComponentBase, JvDragDrop, IdIPWatch;


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
    FileListBox1: TFileListBox;
    Label1: TLabel;
    Label2: TLabel;
    PopupMenu2: TPopupMenu;
    PopupMenu21: TMenuItem;
    Image3: TImage;
    Rename1: TMenuItem;
    IdIPWatch1: TIdIPWatch;
    Label3: TLabel;
    lblhttp: TLinkLabel;
    Image2: TImage;
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
    procedure PopupMenu21Click(Sender: TObject);
    procedure Rename1Click(Sender: TObject);
    procedure FileListBox1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
  private
    { Private declarations }
    procedure AddFile(const FileName: string);
    function  IsSupportedFileType(const FileName: string): Boolean;

  public
    { Public declarations }
    // declare our DROPFILES message handler
    procedure AcceptFiles( var msg : TMessage ); message WM_DROPFILES;
    function GetIPLocal: string;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ShellApi, ClipBrd;

{$R *.dfm}
const
  cSupportedExts = '*.tap;*.tzx;*.z80;*.sna;*.zip;';

procedure TfrmMain.Close1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.FileListBox1Click(Sender: TObject);
begin
  lblhttp.Caption :='.http -h /' + GetIPLocal +' -u /' +
    ExtractFileName(FileListBox1.FileName) + ' -f ' +
    ExtractFileName(FileListBox1.FileName);

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

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  //

  ChangeWindowMessageFilter (WM_DROPFILES, MSGFLT_ADD);
  ChangeWindowMessageFilter (WM_COPYGLOBALDATA, MSGFLT_ADD);
  DragAcceptFiles(Handle, True);
  Hide;
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
end;

procedure TfrmMain.sbStopClick(Sender: TObject);
begin
  Servidor.Active := False;
  mLog.Lines.Add( 'Stopped server' );
  sbStart.Enabled := true;
  sbStop.Enabled := false;
  TrayIcon1.BalloonHint := 'Stopped server';
end;

procedure TfrmMain.ServidorCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

var
  sDocumento: String;
begin
  mLog.Lines.Add( ARequestInfo.RemoteIP  + ': ' +
    ARequestInfo.Command + ARequestInfo.Document );

  // ¿Va a entrar a la página principal?
  if ARequestInfo.Document = '/' then
    AResponseInfo.ServeFile( AContext, ExtractFilePath( Application.ExeName ) + 'index.html' )
  else
  begin
    // Cargamos la página web que vamos a enviar
    sDocumento := ExtractFilePath( Application.ExeName ) +
      Copy( ARequestInfo.Document, 2, Length( ARequestInfo.Document ) );

    // ¿Existe la página que ha solicitado?
    if FileExists( sDocumento ) then
    begin
      // validamos al usuario
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
      // No hemos encontrado la página
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
    FileListBox1.Update;
  end

  else
    ShowMessageFmt('File %s is not a supported type', [FileName]);
end;

procedure TfrmMain.Image2Click(Sender: TObject);
begin
  Clipboard.AsText := lblhttp.Caption;
end;

function TfrmMain.IsSupportedFileType(const FileName: string): Boolean;
begin
  Result := AnsiPos('*' + ExtractFileExt(FileName) + ';', cSupportedExts) > 0;
end;

procedure TfrmMain.PopupMenu21Click(Sender: TObject);
begin
  DeleteFile(FileListBox1.FileName);
  FileListBox1.Update;
end;

procedure TfrmMain.Rename1Click(Sender: TObject);
var
  sFile, NewName : String;

begin
  sFile := ExtractFileName(FileListBox1.FileName);
  NewName := InputBox('Rename file', 'New name',sFile );
  RenameFile(FileListBox1.FileName, NewName);
  FileListBox1.Update;
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
end.
