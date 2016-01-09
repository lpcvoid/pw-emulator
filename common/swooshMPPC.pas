unit swooshMPPC;

interface

uses windows, classes, serverDecl, swooshPacket, math, uCompressRipRaw,GNet.Compress;

type
  TSwooshMPPC = class
    constructor Create;
    function CompressPacket ( thePacket: TInternalSwooshPacket ) : TInternalSwooshPacket;
    function GNET__Compress__HASH( bufferPos: Integer ): Integer;
    function GNET__Compress__GetPredecitAddr( a1, a2: Integer ): Integer;
    function CalcUncompressedSize(compressedSize: uint32): uint32;

  private const
    MPPE_HIST_LEN = 8192;

  var
    hist      : TRawData;
    hashes    : TRawData16;
    historyPtr: word;

  end;

implementation

constructor TSwooshMPPC.Create;
begin
  setlength( self.hist, MPPE_HIST_LEN * 2 );
  setlength( self.hashes, MPPE_HIST_LEN );
end;

function TSwooshMPPC.CalcUncompressedSize(compressedSize: uint32): uint32;
begin
  result := ((compressedSize * 9) div 8) + 6;
end;

function TSwooshMPPC.CompressPacket ( thePacket: TInternalSwooshPacket ) : TInternalSwooshPacket;
var
  cmp: TGNETCompress;
  pSrc, pSrcEnd, pDst, p1: pbyte;
  SrcSize, tmpSize, Size, TotalCompressedSize: uint32;
begin

  if ( thePacket.GetpacketLength > MPPE_HIST_LEN )
  then
  begin
    writeln( '***Error : swooshMPPC::Packetlen > MPPE_HIST_LEN' );
    exit;
  end;

  // check if there is enough room at the end of the history
  if ( self.historyPtr + thePacket.GetpacketLength >= length( self.hist ))
  then
  begin
    self.historyPtr := self.MPPE_HIST_LEN;
    writeln( '***Error : swooshMPPC::self.historyPtr + thePacket.GetpacketLength >= MPPE_HIST_LEN * 2' );
    exit;
  end;

  result :=thePacket;


  cmp.Create;

  pSrc := @thePacket.buffer[0];
  pSrcEnd := @thePacket.buffer[thePacket.GetpacketLength];
  pDst := nil;
  TotalCompressedSize := 0;
  repeat
    SrcSize := pSrcEnd - pSrc;
    if SrcSize > 8192 then
      SrcSize := 8192;

    tmpSize := self.CalcUncompressedSize(SrcSize);

    result.setPacketLength(TotalCompressedSize + tmpSize);

    move(pSrc^, cmp.Hist[0], SrcSize);

    pDst := @result.buffer[0];

    p1 := Compress(@cmp, pDst, SrcSize);
    Size := p1 - pDst;

    cmp.SrcPtr := @cmp.Hist[0];

    inc(pSrc, SrcSize);
    inc(TotalCompressedSize, Size);

  until pSrc = pSrcEnd;

  // final resize
  result.setPacketLength(TotalCompressedSize);

end;

{*
 int __cdecl GNET__Compress__GetPredecitAddr(int a1, int a2)

 unsigned __int16 v3; // ax@1
 unsigned __int16 v4; // [sp+12h] [bp-6h]@1
 int v5; // [sp+Ch] [bp-Ch]@1

 v3 = GNET__Compress__HASH(a2);
 v4 = v3;
 v5 = a1 + *(_WORD *)(a1 + 2 * v3 + 8192);
 *(_WORD *)(a1 + 2 * v3 + 8192) = a2 - a1; //Error hex rays
 return v5;

 *}

function TSwooshMPPC.GNET__Compress__GetPredecitAddr( a1, a2: Integer ): Integer;
var
  v3: word;
begin
  v3 := self.GNET__Compress__HASH( a2 );
  result := a1 + word( a1 + 2 * v3 + 8196 );
end;

{
 int __cdecl GNET__Compress__HASH(int bufferPos)

 return (40543 * (*(_BYTE *)(bufferPos + 2) ^ 16 * (16 * *(_BYTE *)bufferPos ^ *(_BYTE *)(bufferPos + 1))) >> 4) & 0x1FFF;

}

function TSwooshMPPC.GNET__Compress__HASH( bufferPos: Integer ): Integer;
begin
  result := ( 40543 * (( bufferPos + 2 ) xor 16 * ( 16 * bufferPos xor ( bufferPos + 1 ))) shr 4 ) and $1FFF;
end;

end.
