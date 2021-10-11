program diaporama;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  about in 'about.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Diaporama';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
