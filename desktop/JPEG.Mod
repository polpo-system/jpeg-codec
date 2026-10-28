MODULE JPEG;  (** JPEG pictures for Pictures: "jpg = JPEG.InitPicture" in PictureConverters of Oberon.Text *)

(** Pictures.Open reads .jpg files through InitPicture (the pictures of WebNav, Iris and every program
  on Pictures). The picture is decoded by JPEG0, baseline or progressive, and made a Picture of at most
  256 colours by RGBPictures (of the package png). Store writes a Picture as a JPEG file of the
  quality quality. *)

IMPORT Files, Objects, Pictures, JPEG0, RGBPictures;

VAR
  quality*: LONGINT;  (** of the pictures Store writes, 1 to 100 (75) *)

(* decode the JPEG picture of R into P *)
PROCEDURE Load(VAR R: Files.Rider; P: Pictures.Picture): BOOLEAN;
VAR img: JPEG0.Image; res: LONGINT;
BEGIN
  JPEG0.Decode(R, img, res);
  IF (res # JPEG0.ok) OR (img.width > MAX(INTEGER)) OR (img.height > MAX(INTEGER)) THEN RETURN FALSE END;
  RGBPictures.Make(P, img.width, img.height, img.pix^, RGBPictures.white);
  RETURN TRUE
END Load;

PROCEDURE Handle*(obj: Objects.Object; VAR M: Objects.ObjMsg);
VAR start: LONGINT;
BEGIN
  WITH obj: Pictures.Picture DO
    IF M IS Objects.AttrMsg THEN
      WITH M: Objects.AttrMsg DO
        IF (M.id = Objects.get) & (M.name = "Gen") THEN M.class := Objects.String; M.s := "Pictures.NewPicture"; M.res := 0
        ELSE Pictures.Handle(obj, M)
        END
      END
    ELSIF M IS Objects.FileMsg THEN
      WITH M: Objects.FileMsg DO
        IF M.id = Objects.load THEN
          start := Files.Pos(M.R);
          IF Load(M.R, obj) THEN M.len := Files.Pos(M.R) - start ELSE M.len := 0 END
        ELSE Pictures.Handle(obj, M)
        END
      END
    ELSE Pictures.Handle(obj, M)
    END
  END
END Handle;

(** called by Pictures.Open for a .jpg file: the picture is loaded by Handle *)
PROCEDURE InitPicture*;
BEGIN Objects.NewObj.handle := Handle
END InitPicture;

PROCEDURE NewPicture*;
VAR P: Pictures.Picture;
BEGIN NEW(P); P.handle := Handle; Objects.NewObj := P
END NewPicture;

(** write the picture P to W as a JPEG picture; res as JPEG0.Encode *)
PROCEDURE Store*(P: Pictures.Picture; VAR W: Files.Rider; VAR res: LONGINT);
VAR img: JPEG0.Image; line: POINTER TO ARRAY OF INTEGER; x, y, i: LONGINT; r, g, b: INTEGER;
BEGIN
  img := JPEG0.NewImage(P.width, P.height);
  IF img.pix = NIL THEN res := JPEG0.noImage; RETURN END;
  NEW(line, P.width); y := 0;
  WHILE y < P.height DO
    Pictures.GetLine(P, line^, 0, SHORT(P.height - 1 - y), P.width); x := 0;
    WHILE x < P.width DO
      Pictures.GetColor(P, line[x], r, g, b); i := (y * P.width + x) * 4;
      img.pix[i] := CHR(r); img.pix[i + 1] := CHR(g); img.pix[i + 2] := CHR(b);
      INC(x)
    END;
    INC(y)
  END;
  JPEG0.Encode(W, img, quality, res)
END Store;

BEGIN
  quality := 75
END JPEG.
