MODULE JPEGImagesTest;  (* loksh JPEGImagesTest.Run: JPEG pictures through Images; needs the desktop's display *)

(* with pictures of jpegsuite.tgz in the current directory: bbig.jpg (colour, baseline), prog.jpg
  (colour, progressive), bgrey.jpg (grey). Images.Load gives the pixels of JPEG0; Images.Store writes
  them with the quality 75, and JPEG0 reads back the pixels it gets from encoding them itself. *)

IMPORT Files, Images, out, JPEG0, JPEGImages;

VAR checks, failed: LONGINT;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(failed); out.String("FAIL "); out.String(what); out.Ln END
END Check;

PROCEDURE Decode(name: ARRAY OF CHAR): JPEG0.Image;
VAR f: Files.File; R: Files.Rider; img: JPEG0.Image; res: LONGINT;
BEGIN
  f := Files.Old(name); IF f = NIL THEN RETURN NIL END;
  Files.Set(R, f, 0); JPEG0.Decode(R, img, res); Files.Close(f);
  IF res # JPEG0.ok THEN RETURN NIL END;
  RETURN img
END Decode;

(* does img (Images) have the pixels of p (JPEG0) *)
PROCEDURE SameImage(img: Images.Image; p: JPEG0.Image): BOOLEAN;
VAR x, y, s, k: LONGINT; mode: Images.Mode; fmt: Images.Format; row: ARRAY 4 OF CHAR;
BEGIN
  IF (img.width # p.width) OR (img.height # p.height) THEN RETURN FALSE END;
  fmt := Images.BGRA8888; Images.InitMode(mode, Images.srcCopy); y := 0;
  WHILE y < p.height DO
    x := 0;
    WHILE x < p.width DO
      Images.GetPixels(img, SHORT(x), SHORT(p.height - 1 - y), 1, fmt, row, mode);
      s := (y * p.width + x) * 4; k := 0;
      WHILE k < 3 DO  (* row: blue, green, red *)
        IF row[k] # p.pix[s + 2 - k] THEN RETURN FALSE END;
        INC(k)
      END;
      INC(x)
    END;
    INC(y)
  END;
  RETURN TRUE
END SameImage;

(* p encoded by JPEG0 with the quality 75 and decoded again *)
PROCEDURE Again(p: JPEG0.Image): JPEG0.Image;
VAR f: Files.File; R: Files.Rider; q: JPEG0.Image; res: LONGINT;
BEGIN
  f := Files.New(""); Files.Set(R, f, 0); JPEG0.Encode(R, p, 75, res);
  Files.Set(R, f, 0); JPEG0.Decode(R, q, res);
  RETURN q
END Again;

PROCEDURE Same(a, b: JPEG0.Image): BOOLEAN;
VAR i, n: LONGINT;
BEGIN
  IF (a = NIL) OR (b = NIL) OR (a.width # b.width) OR (a.height # b.height) THEN RETURN FALSE END;
  i := 0; n := a.width * a.height * 4;
  WHILE (i < n) & (a.pix[i] = b.pix[i]) DO INC(i) END;
  RETURN i = n
END Same;

PROCEDURE ImagesCase(name: ARRAY OF CHAR);
VAR img: Images.Image; done: BOOLEAN; p, q: JPEG0.Image; fname: ARRAY 32 OF CHAR;
BEGIN
  p := Decode(name); NEW(img); Images.Load(img, name, done);
  Check(name, done & (p # NIL) & SameImage(img, p));
  IF done THEN
    JPEGImages.quality := 75; fname := "zq_store.jpg"; Images.Store(img, fname, done);
    q := Decode(fname);
    Check("Images.Store", done & Same(q, Again(p)))
  END
END ImagesCase;

PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0;
  ImagesCase("bbig.jpg"); ImagesCase("prog.jpg"); ImagesCase("bgrey.jpg");
  out.String("JPEGImagesTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END JPEGImagesTest.
