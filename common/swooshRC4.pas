unit swooshRC4;

{

 Original unit created by vogel. I modified it to suit my needs of
 stream cipher.

}

interface

uses serverDecl;

Type
  TRC4Encoder = class
  public
    constructor Create( aKey: THashKey );
    function ProcessByte( aData: Byte ): Byte;
    function ProcessArray( aData: TRawData ): TRawData;

  private
    _S: array[ 0 .. 255 ] of Byte;
    _x: Byte;
    _y: Byte;
    function getNextKeyByte( ): Byte;
  end;

implementation

constructor TRC4Encoder.Create( aKey: THashKey );
var
  i, j, a, b: Byte;
begin
  // init _S
  for i := 0 to 255 do
    self._S[ i ] := i;

  // init _S with key data
  j := 0;
  for i := 0 to 255 do
  begin
    a := aKey[ i mod length( aKey )];
    j := j + a + self._S[ i ];

    b := self._S[ i ];
    self._S[ i ] := self._S[ j ];
    self._S[ j ] := b;
  end;
end;

function TRC4Encoder.getNextKeyByte( ): Byte;
var
  a: Byte;
begin
  self._x := ( self._x + 1 ) mod 256;
  self._y := ( self._y + self._S[ self._x ]) mod 256;

  // swap;
  a := self._S[ self._x ];
  self._S[ self._x ] := self._S[ self._y ];
  self._S[ self._y ] := a;

  result := self._S[( self._S[ self._x ] + self._S[ self._y ]) mod 256 ];
end;

function TRC4Encoder.ProcessByte( aData: Byte ): Byte;
begin
  result := aData xor self.getNextKeyByte( );
end;

function TRC4Encoder.ProcessArray( aData: TRawData ): TRawData;
var
  i, len: cardinal;
begin
  len := length( aData );
  SetLength( result, len );
  for i := 0 to len - 1 do
    // result[i] := aData[i] xor self.getNextKeyByte();
    result[ i ] := ProcessByte( aData[ i ]);
end;

end.
