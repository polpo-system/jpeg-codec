MODULE JPEGMemoryTest;  (** loksh JPEGMemoryTest.Run, JPEGMemoryTest.Fixtures jpegsuite.list: JPEG0 in memory (JPEG0.DecodeBytes, EncodeBytes, ReadInfoBytes) *)

(* After the PictureMemoryTest of voc 4.0.6. Run: a picture made here encoded into memory and decoded again,
  the same bytes as through a rider, the pixel limit and the output limit, and broken or cut data refused.
  Fixtures: each picture of the list read with the byte-array entry points and with the rider ones, the
  same results and pixels. *)

IMPORT Files, Texts, Out, JPEG0;

VAR checks, failed: LONGINT; phase: ARRAY 256 OF CHAR;

PROCEDURE Check(value: BOOLEAN);
BEGIN
  INC(checks);
  IF ~value THEN INC(failed); Out.String("FAIL "); Out.String(phase); Out.String(", check "); Out.Int(checks, 0); Out.Ln END
END Check;

PROCEDURE Equal(VAR a, b: ARRAY OF CHAR; length: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF (length < 0) OR (length > LEN(a)) OR (length > LEN(b)) THEN RETURN FALSE END;
  i := 0; WHILE i < length DO IF a[i] # b[i] THEN RETURN FALSE END; INC(i) END;
  RETURN TRUE
END Equal;

PROCEDURE Fill(VAR bytes: ARRAY OF CHAR);
VAR i, seed: LONGINT;
BEGIN
  seed := 1; i := 0;
  WHILE i < LEN(bytes) DO seed := (seed * 75 + 74) MOD 65537; bytes[i] := CHR(seed MOD 256); INC(i) END
END Fill;

PROCEDURE Load(VAR name: ARRAY OF CHAR; VAR data: Files.Bytes; VAR length: LONGINT): Files.File;
VAR f: Files.File; r: Files.Rider;
BEGIN
  f := Files.Old(name); Check(f # NIL);
  IF f = NIL THEN length := 0; NEW(data, 1); RETURN NIL END;
  length := Files.Length(f);
  IF length = 0 THEN NEW(data, 1) ELSE NEW(data, length) END;
  Files.Set(r, f, 0); Files.ReadBytes(r, data^, length); Check(r.res = 0);
  RETURN f
END Load;

PROCEDURE Line(VAR R: Files.Rider; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR c: CHAR; i: LONGINT;
BEGIN
  i := 0; Files.Read(R, c);
  IF R.eof THEN RETURN FALSE END;
  WHILE ~R.eof & (c # 0AX) DO IF i < LEN(s) - 1 THEN s[i] := c; INC(i) END; Files.Read(R, c) END;
  s[i] := 0X; RETURN TRUE
END Line;

PROCEDURE JPEG;
VAR img, decoded, riderImage, bad: JPEG0.Image; info: JPEG0.Info; data, copy, encoded: Files.Bytes;
  f: Files.File; r: Files.Rider; n, m, res: LONGINT;
BEGIN
  phase := "JPEG memory round trips";
  img := JPEG0.NewImage(160, 160); Fill(img.pix^);
  JPEG0.EncodeBytes(img, 95, 524288, data, n, res); Check((res = JPEG0.ok) & (n > 16384) & (data # NIL));
  JPEG0.ReadInfoBytes(data^, n, info, res); Check((res = JPEG0.ok) & (info.width = 160) & (info.height = 160));
  JPEG0.DecodeBytes(data^, n, 160 * 160, decoded, res); Check((res = JPEG0.ok) & (decoded # NIL));
  f := Files.FromBytes(data^, n); Files.Set(r, f, 0); JPEG0.Decode(r, riderImage, res);
  Check((res = JPEG0.ok) & Equal(decoded.pix^, riderImage.pix^, 160 * 160 * 4));
  f := Files.NewMemory(524288); Files.Set(r, f, 0); JPEG0.Encode(r, img, 95, res); copy := Files.MemoryData(f, m);
  Check((res = JPEG0.ok) & (m = n) & Equal(data^, copy^, n));

  phase := "JPEG limits and malformed buffers";
  JPEG0.DecodeBytes(data^, n, 160 * 160 - 1, decoded, res); Check((res = JPEG0.tooLarge) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, n, 0, decoded, res); Check((res = JPEG0.tooLarge) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, -1, JPEG0.MaxPixels, decoded, res); Check((res = JPEG0.badFormat) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, LEN(data^) + 1, JPEG0.MaxPixels, decoded, res); Check((res = JPEG0.badFormat) & (decoded = NIL));
  JPEG0.DecodeBytes(data^, 5, JPEG0.MaxPixels, decoded, res); Check((res # JPEG0.ok) & (decoded = NIL));
  JPEG0.EncodeBytes(img, 95, n - 1, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0));
  JPEG0.EncodeBytes(img, 95, n, encoded, m, res); Check((res = JPEG0.ok) & (m = n) & Equal(data^, encoded^, n));
  JPEG0.EncodeBytes(img, 95, -1, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0));
  NEW(bad); bad.width := 2; bad.height := 2; NEW(bad.pix, 3);
  JPEG0.EncodeBytes(bad, 95, 4096, encoded, m, res); Check((res = JPEG0.noImage) & (encoded = NIL) & (m = 0));
  bad.width := 65535; bad.height := 65535;
  JPEG0.EncodeBytes(bad, 95, 4096, encoded, m, res); Check((res = JPEG0.tooLarge) & (encoded = NIL) & (m = 0))
END JPEG;

PROCEDURE Fixture(VAR name: ARRAY OF CHAR);
VAR f: Files.File; r: Files.Rider; data: Files.Bytes; length, a, b: LONGINT; j, jc: JPEG0.Image; ji, jic: JPEG0.Info;
BEGIN
  COPY(name, phase); f := Load(name, data, length);
  IF f = NIL THEN RETURN END;
  Files.Set(r, f, 0); JPEG0.ReadInfo(r, ji, a); JPEG0.ReadInfoBytes(data^, length, jic, b); Check(a = b);
  IF a = JPEG0.ok THEN
    Check((ji.width = jic.width) & (ji.height = jic.height) & (ji.components = jic.components) & (ji.progressive = jic.progressive))
  END;
  Files.Set(r, f, 0); JPEG0.Decode(r, j, a); JPEG0.DecodeBytes(data^, length, JPEG0.MaxPixels, jc, b); Check(a = b);
  IF a = JPEG0.ok THEN
    Check((jc # NIL) & (j.width = jc.width) & (j.height = jc.height));
    Check((jc # NIL) & Equal(j.pix^, jc.pix^, j.width * j.height * 4))
  ELSE Check(jc = NIL)
  END;
  Files.Close(f)
END Fixture;

(** JPEGMemoryTest.Run: memory round trips and limits *)
PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0; JPEG;
  Out.String("JPEGMemoryTest: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failed, 0); Out.String(" failed"); Out.Ln
END Run;

(** JPEGMemoryTest.Fixtures list: the byte-array entry points against the rider ones on every picture of list *)
PROCEDURE Fixtures*;
VAR A: Texts.Reader; f: Files.File; r: Files.Rider; list: ARRAY 256 OF CHAR; line, name: ARRAY 256 OF CHAR; i: LONGINT;
BEGIN
  checks := 0; failed := 0; Texts.OpenArgs(A);
  IF ~Texts.Arg(A, list) THEN Out.String("usage: JPEGMemoryTest.Fixtures jpegsuite.list"); Out.Ln; RETURN END;
  f := Files.Old(list);
  IF f = NIL THEN Out.String("FAIL no "); Out.String(list); Out.Ln; RETURN END;
  Files.Set(r, f, 0);
  WHILE Line(r, line) DO
    i := 0; WHILE (line[i] > " ") & (i < LEN(name) - 1) DO name[i] := line[i]; INC(i) END;
    name[i] := 0X;
    IF (i > 0) & (name[0] # "#") THEN Fixture(name) END
  END;
  Out.String("JPEGMemoryTest fixtures: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failed, 0); Out.String(" failed"); Out.Ln
END Fixtures;

END JPEGMemoryTest.
