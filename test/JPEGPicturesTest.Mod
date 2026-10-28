MODULE JPEGPicturesTest;  (* loksh JPEGPicturesTest.Run: JPEG pictures through Pictures; needs the desktop's display *)

(* with pictures of jpegsuite.tgz in the current directory: Pictures.Open gives a picture of their size,
  in the colours of the palette of Display nearest to those of the picture: the mean difference of
  the components, averaged over blocks of 4 by 4 pixels, is less than 20 (the palette of Display is
  coarse: an 8 x 8 x 4 cube with components up to 227, and the 16 colours of the system). The
  pictures: bbig.jpg (colour, baseline), prog.jpg (colour, progressive), bgrey.jpg (grey).
  JPEG.Store writes a picture JPEG0 reads again at the same size. *)

IMPORT Files, Pictures, out, JPEG0, JPEG;

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

(* the mean difference of the components of the picture name opened with Pictures and decoded by
  JPEG0, compared as averages over blocks of 4 by 4 pixels (dithering keeps the averages), times
  10; -1 if it cannot be opened *)
PROCEDURE MeanDiff(name: ARRAY OF CHAR): LONGINT;
VAR P: Pictures.Picture; p: JPEG0.Image; x, y, bx, by, s, sum, n, k: LONGINT; r, g, b: INTEGER;
  a, c: ARRAY 3 OF LONGINT;
BEGIN
  NEW(P); Pictures.Open(P, name, TRUE); p := Decode(name);
  IF (p = NIL) OR (P.width # p.width) OR (P.height # p.height) OR (P.depth # 8) THEN RETURN -1 END;
  sum := 0; n := 0; by := 0;
  WHILE by + 4 <= p.height DO
    bx := 0;
    WHILE bx + 4 <= p.width DO
      a[0] := 0; a[1] := 0; a[2] := 0; c[0] := 0; c[1] := 0; c[2] := 0; y := by;
      WHILE y < by + 4 DO
        x := bx;
        WHILE x < bx + 4 DO
          Pictures.GetColor(P, Pictures.Get(P, SHORT(x), SHORT(p.height - 1 - y)), r, g, b); s := (y * p.width + x) * 4;
          INC(a[0], r); INC(a[1], g); INC(a[2], b);
          INC(c[0], ORD(p.pix[s])); INC(c[1], ORD(p.pix[s + 1])); INC(c[2], ORD(p.pix[s + 2]));
          INC(x)
        END;
        INC(y)
      END;
      k := 0; WHILE k < 3 DO INC(sum, ABS(a[k] - c[k])); INC(k) END;
      INC(n); INC(bx, 4)
    END;
    INC(by, 4)
  END;
  RETURN sum * 10 DIV (3 * 16 * n)
END MeanDiff;

PROCEDURE Case(name: ARRAY OF CHAR);
VAR d: LONGINT;
BEGIN
  d := MeanDiff(name); out.String(name); out.String(": mean difference "); out.Int(d, 0); out.String(" / 10"); out.Ln;
  Check(name, (d >= 0) & (d < 200))
END Case;

PROCEDURE Run*;
VAR P: Pictures.Picture; f: Files.File; W: Files.Rider; res: LONGINT; img: JPEG0.Image;
BEGIN
  checks := 0; failed := 0;
  Case("bbig.jpg"); Case("prog.jpg"); Case("bgrey.jpg");
  NEW(P); Pictures.Open(P, "bbig.jpg", TRUE);
  f := Files.New("zq_store.jpg"); Files.Set(W, f, 0); JPEG.Store(P, W, res); Files.Register(f); Files.Close(f);
  img := Decode("zq_store.jpg");
  Check("JPEG.Store", (res = JPEG0.ok) & (img # NIL) & (img.width = P.width) & (img.height = P.height));
  out.String("JPEGPicturesTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END JPEGPicturesTest.
