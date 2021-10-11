unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, ComCtrls, ToolWin, ImgList;
  
type
  TForm1 = class(TForm)
    tmrRoll: TTimer;
    imgPic1: TImage;
    imgPic2: TImage;
    imgPic3: TImage;
    imgPic4: TImage;
    imgPic5: TImage;
    imgPicRollMask: TImage;
    tmrViewInfo: TTimer;
    ToolBar: TToolBar;
    QuitBtn: TToolButton;
    Separator1: TToolButton;
    Suivant: TToolButton;
    Precedent: TToolButton;
    SaveBtn: TToolButton;
    lbInfo: TLabel;
    ToolList: TImageList;
    Timer1: TTimer;
    Label1: TLabel;
    Bevel1: TBevel;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    procedure imgPic5MouseLeave(Sender: TObject);
    procedure imgPic5MouseEnter(Sender: TObject);
    procedure imgPic4MouseLeave(Sender: TObject);
    procedure imgPic4MouseEnter(Sender: TObject);
    procedure imgPic3MouseLeave(Sender: TObject);
    procedure imgPic3MouseEnter(Sender: TObject);
    procedure imgPic2MouseLeave(Sender: TObject);
    procedure imgPic2MouseEnter(Sender: TObject);
    procedure imgPic1MouseLeave(Sender: TObject);
    procedure imgPic1MouseEnter(Sender: TObject);
    procedure SmallPicsClick(Sender: TObject);
    procedure tmrViewInfoTimer(Sender: TObject);
    procedure tmrRollTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure QuitBtnClick(Sender: TObject);
    procedure SuivantClick(Sender: TObject);
    procedure PrecedentClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCenter;
    procedure SaveBtnClick(Sender: TObject);
    private
    { Private declarations }
    public
    { Public declarations }
  end;
  
const
  Info: Array[0..3] of String = ('Slide Show by OFFLAKE',
  'Realized by OFFLAKE',
  'Copyright 2009',
  'Contacts: sami_inf@hotmail.com');
  
var
  Form1: TForm1;
  BigStream: TBitmap;          // Stocker le rouleau de photos
  DestR: TRect;                // Rectangle de la toile du masque
  SmallW, SmallH: Integer;     // Largeur, la hauteur de petites images
  W,                           // Largeur du masque
  H,                           // Taille du masque
  NewX,                        // Position que les 2 couches se déplace à
  dX1,                         // en position de la couche inférieure
  dX2,                         // ------------------------- supérieur -----
  X1,                          // Position actuelle de la couche inférieure
  X2: Integer;                 // ----------------------- supérieur -----
  
  MaskBevelW,                  // Bevel largeur du masque
  CurrFrame,                   // Cadre actuel
  LastPicId,                   // Dernière image id cliqué
  PicId: Byte;                 // Actuellement, clique sur l'image id
  
  InfoId, Count: Byte;
  
  AFormat: Word;               // Pour mettre à bord format clip
  AData: THandle;              // &
  APalette: HPalette;          // Clip Charge de bord format
  flag1:Integer;
  BlendFunc: TBlendFunction;   // Un paramètre de la fonction Windows.AlphaBlend
  
implementation

uses about;
  
{$R *.dfm}



procedure Tform1.FormCenter;
begin
  with form1 do begin
  Left := Screen.Width  div 2 - Width  div 2;
  Top  := Screen.Height div 2 - Height div 2;
end;
end;



procedure TForm1.FormCreate(Sender: TObject);
var
  i: Byte;
begin
  
  // Aligner la forme
  flag1:=0;
  Left := (Screen.Width - Width) div 2;
  Top := (Screen.Height - Height) div 2 - 16;
  
  // Initialiser BlendFunc. Pour plus d'informations sur TBlendFunction, utilisez Aide
  
  with BlendFunc do
  begin
    BlendOp := AC_SRC_OVER;     // Src over dest
    BlendFlags := 0;            // Doit être 0
    SourceConstantAlpha := 127; // 50% transparent <=> dest = (Src Dest +) / 2
    AlphaFormat := 0;           // 0 pour nous utilisons SourceConstantAlpha
  end;
  
  BigStream := TBitmap.Create;
  with BigStream do
  begin
    LoadFromFile('Pic Stream_Big.bmp');
    PixelFormat := pf24bit;     // Juste pour le sauvetage de la mémoire
    W := Width div 5;
    H := Height;
  end;
  
  X1 := 0;
  X2 := 0;
  dX1 := 0;
  dX2 := 0;
  PicId := 1;
  LastPicId := 1;
  MaskBevelW := 10;
  InfoId := 0;
  lbInfo.Top := ClientHeight;
  
  with imgPic1 do
  begin
    SmallW := Width;
    SmallH := Height;
  end;
  
  with DestR do
  begin
    Left := MaskBevelW;
    Top := MaskBevelW;
    Right := W + MaskBevelW;
    Bottom := H + MaskBevelW;
  end;
  
  with imgPicRollMask do
  begin
    
    // Aligner le masque
    
    Width := W + 3 * MaskBevelW;
    Height := H + 3 * MaskBevelW;
    Left := (Form1.ClientWidth - Width) div 2;
    
    with Canvas do
    begin
      // Dessinez le bevel
      Brush.Color := clBtnFace;
      FillRect(Rect(Width - MaskBevelW, 0, Width, 10));  // Effacer le coin supérieur droit
      FillRect(Rect(0, Height - MaskBevelW, 10, Height));// Effacer le coin inférieur gauche
      for i := 0 to MaskBevelW - 1 do
      begin
        Brush.Color := RGB(10*i, 0, 100 + 15*i);
        FillRect(Rect(i, i, Width - MaskBevelW - i, Height - MaskBevelW - i));
      end;
      
      // Dessiner l'ombre
      Brush.Color := clLtGray;
      FillRect(Rect(Width - MaskBevelW, MaskBevelW, Width, Height));
      FillRect(Rect(MaskBevelW, Height - MaskBevelW, Width, Height));
      
      // Voir la partie de la bobine à l'écran
      CopyRect(DestR, BigStream.Canvas, Rect(0, 0, W, H));
    end;
    
    // Définissez le format de pixel de 24 bits pour sauver la mémoire et nous n'avons pas besoin du 4ème octet
    Picture.Bitmap.PixelFormat := pf24bit;
  end;
  
  // Ces lignes viennent de mode stylo pinceau et la couleur des petites images pour mettre en évidence
  
  with imgPic1.Picture.Bitmap.Canvas do
  begin
    Pen.Mode := pmMask;
    Brush.Color := $DDFFDD;
  end;
  
  with imgPic2.Picture.Bitmap.Canvas do
  begin
    Pen.Mode := pmMask;
    Brush.Color := $DDFFDD;
  end;
  
  with imgPic3.Picture.Bitmap.Canvas do
  begin
    Pen.Mode := pmMask;
    Brush.Color := $DDFFDD;
  end;
  
  with imgPic4.Picture.Bitmap.Canvas do
  begin
    Pen.Mode := pmMask;
    Brush.Color := $DDFFDD;
  end;
  
  with imgPic5.Picture.Bitmap.Canvas do
  begin
    Pen.Mode := pmMask;
    Brush.Color := $DDFFDD;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  BigStream.Free; // Sans le bitmap sinon il va perdre la mémoire
end;

procedure TForm1.imgPic1MouseEnter(Sender: TObject);
begin
  with imgPic1.Picture.Bitmap do
  begin
    SaveToClipboardFormat(AFormat, AData, APalette); // Stocker les données d'origine
    Canvas.Rectangle(0, 0, SmallW, SmallH);          // Mettez en surbrillance l'image
  end;
end;

procedure TForm1.imgPic1MouseLeave(Sender: TObject);
begin
  // Charger les données d'origine
  imgPic1.Picture.Bitmap.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TForm1.imgPic2MouseEnter(Sender: TObject);
begin
  with imgPic2.Picture.Bitmap do
  begin
    SaveToClipboardFormat(AFormat, AData, APalette);
    Canvas.Rectangle(0, 0, SmallW, SmallH);
  end;
end;

procedure TForm1.imgPic2MouseLeave(Sender: TObject);
begin
  imgPic2.Picture.Bitmap.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TForm1.imgPic3MouseEnter(Sender: TObject);
begin
  with imgPic3.Picture.Bitmap do
  begin
    SaveToClipboardFormat(AFormat, AData, APalette);
    Canvas.Rectangle(0, 0, SmallW, SmallH);
  end;
end;

procedure TForm1.imgPic3MouseLeave(Sender: TObject);
begin
  imgPic3.Picture.Bitmap.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TForm1.imgPic4MouseEnter(Sender: TObject);
begin
  with imgPic4.Picture.Bitmap do
  begin
    SaveToClipboardFormat(AFormat, AData, APalette);
    Canvas.Rectangle(0, 0, SmallW, SmallH);
  end;
end;

procedure TForm1.imgPic4MouseLeave(Sender: TObject);
begin
  imgPic4.Picture.Bitmap.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TForm1.imgPic5MouseEnter(Sender: TObject);
begin
  with imgPic5.Picture.Bitmap do
  begin
    SaveToClipboardFormat(AFormat, AData, APalette);
    Canvas.Rectangle(0, 0, SmallW, SmallH);
  end;
end;

procedure TForm1.imgPic5MouseLeave(Sender: TObject);
begin
  imgPic5.Picture.Bitmap.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TForm1.SmallPicsClick(Sender: TObject);
begin
  // Pause de la minuterie pour éviter les conflits
  tmrRoll.Enabled := False;
  
  if Sender = imgPic1 then
    PicId := 1
  else if Sender = imgPic2 then
    PicId := 2
  else if Sender = imgPic3 then
    PicId := 3
  else if Sender = imgPic4 then
    PicId := 4
  else
    PicId := 5;
  
  if PicId <> LastPicId then
  begin
    // Obtenez de nouvelles position des couches. Parce que PicId = 1 .. 5, nous avons besoin de lui soustraire par 1
    NewX := W * (PicId - 1);
    LastPicId := PicId;
    tmrRoll.Enabled := True;
  end;
end;

procedure TForm1.tmrRollTimer(Sender: TObject);
begin
  Suivant.Enabled:=False;
  Precedent.Enabled:=False;
  dX1 := (NewX - X1) div 3; // Maj DX1 vers 0 à ralentir la vitesse de la couche inférieure
  
  if CurrFrame > 2 then     // Retard de la couche supérieure de 3 images
  dX2 := (NewX - X2) div 3; // Maj DX2 vers 0 à ralentir la vitesse de la couche supérieure
  Inc(X1, dX1);             // Déplacer la position de la couche inférieure
  Inc(X2, dX2);             // --------------------------Suppérieur -----
  Inc(CurrFrame);           // Image suivante
  
  with imgPicRollMask.Picture.Bitmap.Canvas do
  begin
    // Copiez la couche inférieure de l'écran
    CopyRect(DestR, BigStream.Canvas, Rect(X1, 0, X1 + W, H));
    
    // Mélange de la couche supérieure de la couche inférieure à l'écran
    // Appuyez sur F1 pour en savoir plus sur la fonction AlphaBlend
    Windows.AlphaBlend(Handle, MaskBevelW, MaskBevelW, W, H, BigStream.Canvas.Handle, X2, 0, W, H, BlendFunc);
    
    // Bien sûr, il ya une seule image bitmap de stocker le déploiement de l'image. Les deux couches
    // point à cette toile de l'image bitmap, mais à différents position.
  end;
  
  if (dX1 = 0) and (dX2 = 0) then // Si les deux couches ont atteint leur nouveau poste,
  begin                           // puis arrêter le décompte et revenir au cadre 0
    CurrFrame := 0;
    tmrRoll.Enabled := False;
  end;
  suivant.Enabled:=True;
  precedent.Enabled:=True;
end;

procedure TForm1.tmrViewInfoTimer(Sender: TObject);
begin
  with lbInfo do
  begin
    if Count < 14 then
      Top := Top - 2
    else if Count > 30 then
    begin
      Count := 0;
      Inc(InfoId);
      if InfoId = 4 then
        InfoId := 0;
      Top := Form1.ClientHeight;
      Caption := Info[InfoId];
      Width := Width + 2;
      Left := (Form1.ClientWidth - Width) div 2;
    end;
  end;
  Inc(Count);
end;

procedure TForm1.QuitBtnClick(Sender: TObject);
begin
  Form2.Close;
  Form1.AlphaBlend:=True;
  Timer1.Interval:=24;
  QuitBtn.Enabled:=False;
end;

procedure TForm1.SuivantClick(Sender: TObject);
begin
  tmrRoll.Enabled := False;
  PicId :=PicId+1;
  if PicId <= 5 then
  begin
    // Obtenez de nouvelles position des couches. Parce que PicId = 1 .. 5, nous avons besoin de lui soustraire par 1
    NewX := W * (PicId - 1);
    LastPicId := PicId;
    tmrRoll.Enabled := True;
  end
  else
  begin
    picId:=5;
    Precedent.Enabled:=True;
    suivant.Enabled:=False;
  end;
end;

procedure TForm1.PrecedentClick(Sender: TObject);
begin
  tmrRoll.Enabled := False;
  PicId :=PicId-1;
  if PicId > 0 then
  begin
    // Obtenez de nouvelles position des couches. Parce que PicId = 1 .. 5, nous avons besoin de lui soustraire par 1
    NewX := W * (PicId - 1);
    LastPicId := PicId;
    tmrRoll.Enabled := True;
  end
  else
  begin
    PicId:=1;
    suivant.Enabled:=True;
    precedent.Enabled:=False;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  inc(flag1);
  if(flag1<=250)then
  begin
    Label1.Left:=(Form1.Width div 2)-(Label1.Width div 2);
    Form1.AlphaBlendValue:=Form1.AlphaBlendValue-1;// < Effet de fondu.
  end
  else
  begin
    timer1.Interval:=0;
    close;
  end;
end;

procedure TForm1.SaveBtnClick(Sender: TObject);
begin
  with Form2 do begin
  Form2 := TForm2.Create(Application);
  FormCenter;
  AnimateWindow(Handle, 360, AW_BLEND);
  Show;
end;
end;

end.

