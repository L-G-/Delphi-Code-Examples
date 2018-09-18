program TreeTest;

uses
  Forms,
  TreeTest1 in 'TreeTest1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
