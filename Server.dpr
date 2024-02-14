program Server;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  Vcl.Themes,
  Vcl.Styles,
  UFileCatcher in 'UFileCatcher.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
