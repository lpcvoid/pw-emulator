unit swooshMPPC;

interface

uses windows, classes, System.Generics.Collections, serverDecl, swooshPacket, math;

type
  TSwooshMPPC = class
    constructor Create;
    procedure CompressPacket ( thePacket: TInternalSwooshPacket );

  private
    decompressHistory: TRawData;
    procedure reorderBitArray( src: TBits );
    procedure fillBits ( theBits: TBits; theBytes: TRawData );
    procedure copyBits ( inputBits: TBits; readFrom: integer; outputBits: TBits; writeTo: integer; length: integer );
    procedure bitsToBytes (compressedPacket : TInternalSwooshPacket; bits: TBits; length: integer );

  end;

implementation

constructor TSwooshMPPC.Create;
begin
  setlength( self.decompressHistory, 8192 );
end;

procedure TSwooshMPPC.CompressPacket ( thePacket: TInternalSwooshPacket );
var
  array2          : TBits;
  outputBits      : TBits;
  from, num2, num3: integer;
begin

  from := 0;
  num2 := 0;
  array2 := TBits.Create;
  self.fillBits( array2, thePacket.buffer );

  outputBits := TBits.Create;
  self.fillBits( outputBits, thePacket.buffer );

  self.reorderBitArray( array2 );

  while from < array2.Size do
  begin

    if ( array2.bits[ from ])
    then
    begin
      outputBits.bits[ from + num2 ] := True;
      inc( num2 );
      outputBits.bits[ from + num2 ] := False; // wtf
      self.copyBits( array2, from + 1, outputBits, from + num2 + 1, 7 );
      inc( from, 8 );
    end
    else
    begin
      self.copyBits( array2, from, outputBits, from + num2, 8 );
      inc( from, 8 );
    end;

  end;

  for num3 := 0 to 3 do
    outputBits.bits[ from + num2 + num3 ] := True;

  inc( from, 4 );

  for num3 := 0 to 5 do
    outputBits.bits[ from + num2 + num3 ] := False;

  inc( from, 6 );

  if ( from + num2 ) mod 8 = 0
  then
    outputBits.Size := from + num2
  else
    outputBits.Size := (( from + num2 ) + ( 8 - (( from + num2 ) mod 8 )));

  self.reorderBitArray( outputBits );

  thePacket := self.bitsToBytes(result, outputBits, outputBits.Size );

end;

procedure TSwooshMPPC.bitsToBytes (compressedPacket : TInternalSwooshPacket; bits: TBits; length: integer );
var
  numArray     : array of integer;
  i, j, realLen: integer;
begin
  realLen := length div 8;
  setlength( numArray, realLen );
  setlength( compressedPacket.buffer, realLen );
  compressedPacket.flush;
  for i := 0 to realLen - 1 do
  begin
    for j := 7 downto 0 do
      if bits.bits[( i * 8 ) + j ]
      then
        numArray[ i ] := Round( power( 2, j ));
    compressedPacket.Writebyte( byte( numArray[ i ]));
  end;

end;

procedure TSwooshMPPC.copyBits( inputBits: TBits; readFrom: integer; outputBits: TBits; writeTo: integer; length: integer );
var
  i: integer;
begin
  for i := 0 to length - 1 do
    outputBits.bits[ writeTo + i ] := inputBits.bits[ readFrom + i ];
end;

procedure TSwooshMPPC.reorderBitArray( src: TBits );
var
  i, j: integer;
  flag: boolean;
begin
  i := 0;
  while i < src.Size do
  begin

    for j := 0 to 3 do
    begin
      flag := src.bits[ i + j ];
      src.bits[ i + j ] := src.bits[ i + ( 7 - j )];
      src.bits[ i + ( 7 - j )] := flag;
    end;

    inc( i, 8 );
  end;

end;

procedure TSwooshMPPC.fillBits( theBits: TBits; theBytes: TRawData );
var
  i, j: integer;
begin

  theBits.Size := 0;
  theBits.Size := length( theBytes ) * 8;

  for i := 0 to length( theBytes ) - 1 do
  begin
    for j := 0 to 7 do
      theBits.bits[ i + j ] := boolean( theBytes[ i ] and ( 1 shl j ));
  end;

end;

end.
