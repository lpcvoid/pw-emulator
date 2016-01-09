unit uCompress;

interface

uses
  System.SysUtils;

function CalcUncompressedSize(compressedSize: uint32): uint32; inline;
function CompressBuffer(const src: TBytes): TBytes;

implementation

uses
  GNet.Compress,
  uCompressRipRaw;

function CalcUncompressedSize(compressedSize: uint32): uint32;
begin
  result := ((compressedSize * 9) div 8) + 6;
end;

function CompressBuffer(const src: TBytes): TBytes;
var
  cmp: TGNETCompress;
  pSrc, pSrcEnd, pDst, p1: pbyte;
  SrcSize, tmpSize, Size, TotalCompressedSize: uint32;
begin
  cmp.Create;

  pSrc := @src[0];
  pSrcEnd := @src[length(src)];
  pDst := nil;
  result := nil;
  TotalCompressedSize := 0;
  repeat
    SrcSize := pSrcEnd - pSrc;
    if SrcSize > 8192 then
      SrcSize := 8192;

    tmpSize := CalcUncompressedSize(SrcSize);
    SetLength(result, TotalCompressedSize + tmpSize);

    move(pSrc^, cmp.Hist[0], SrcSize);

    pDst := @result[TotalCompressedSize];

    p1 := Compress(@cmp, pDst, SrcSize);
    Size := p1 - pDst;

    cmp.SrcPtr := @cmp.Hist[0];

    inc(pSrc, SrcSize);
    inc(TotalCompressedSize, Size);

  until pSrc = pSrcEnd;

  // final resize
  SetLength(result, TotalCompressedSize);
end;

end.
