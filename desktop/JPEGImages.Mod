MODULE JPEGImages;  (** JPEG pictures for Images: "jpg = JPEGImages.Install" in ImageFormats of Oberon.Text *)

(** Images.Load and Images.Store read and write .jpg files through Install: pictures are loaded as
  BGR888, stored as JPEG pictures of the quality quality (transparent pixels over white). Decoding
  (baseline and progressive) and encoding are JPEG0's. *)

IMPORT Files, Images, JPEG0;

VAR
  quality*: LONGINT;  (** of the pictures Store writes, 1 to 100 (75) *)

PROCEDURE Load(img: Images.Image; VAR fname: ARRAY OF CHAR; VAR done: BOOLEAN);
VAR f: Files.File; R: Files.Rider; p: JPEG0.Image; res, x, y, s, d: LONGINT;
BEGIN
  done := FALSE; f := Files.Old(fname);
  IF f = NIL THEN RETURN END;
  Files.Set(R, f, 0); JPEG0.Decode(R, p, res); Files.Close(f);
  IF (res # JPEG0.ok) OR (p.width > MAX(INTEGER)) OR (p.height > MAX(INTEGER)) THEN RETURN END;
  Images.Create(img, SHORT(p.width), SHORT(p.height), Images.BGR888);
  y := 0;
  WHILE y < p.height DO  (* the top row of the JPEG picture is the last row of the image *)
    s := y * p.width * 4; d := (p.height - 1 - y) * img.bpr; x := 0;
    WHILE x < p.width DO
      img.mem[d] := p.pix[s + 2]; img.mem[d + 1] := p.pix[s + 1]; img.mem[d + 2] := p.pix[s];
      INC(s, 4); INC(d, 3); INC(x)
    END;
    INC(y)
  END;
  done := TRUE
END Load;

(* the premultiplied colour c over white, a = 255 - alpha *)
PROCEDURE Over(c: CHAR; a: LONGINT): CHAR;
BEGIN
  a := ORD(c) + a; IF a > 255 THEN a := 255 END;
  RETURN CHR(a)
END Over;

PROCEDURE Store(img: Images.Image; VAR fname: ARRAY OF CHAR; VAR done: BOOLEAN);
VAR f: Files.File; W: Files.Rider; p: JPEG0.Image; res, x, y, d, a: LONGINT; row: POINTER TO ARRAY OF CHAR;
  fmt: Images.Format; mode: Images.Mode;
BEGIN
  done := FALSE;
  p := JPEG0.NewImage(img.width, img.height);
  IF p.pix = NIL THEN RETURN END;
  fmt := Images.BGRA8888; Images.InitMode(mode, Images.srcCopy);
  NEW(row, LONG(img.width) * 4); y := 0;
  WHILE y < img.height DO
    Images.GetPixels(img, 0, SHORT(img.height - 1 - y), img.width, fmt, row^, mode);
    d := y * img.width * 4; x := 0;
    WHILE x < img.width DO  (* premultiplied: over white *)
      a := 255 - ORD(row[4 * x + 3]);
      p.pix[d] := Over(row[4 * x + 2], a); p.pix[d + 1] := Over(row[4 * x + 1], a); p.pix[d + 2] := Over(row[4 * x], a);
      INC(d, 4); INC(x)
    END;
    INC(y)
  END;
  f := Files.New(fname); Files.Set(W, f, 0);
  JPEG0.Encode(W, p, quality, res);
  IF res = JPEG0.ok THEN Files.Register(f); done := TRUE END;
  Files.Close(f)
END Store;

(** called by Images for .jpg files *)
PROCEDURE Install*;
BEGIN Images.LoadProc := Load; Images.StoreProc := Store
END Install;

BEGIN
  quality := 75
END JPEGImages.
