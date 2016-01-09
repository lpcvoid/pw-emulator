unit swooshMemoryBuffer;

interface

uses windows, classes, types, pwEmuDataTypes;

type
  TswooshMemoryBuffer = class( TMemoryStream )
  public
    constructor Create;
    procedure writeCUInt( val: integer );
    procedure writeByte( val: byte );
    procedure writeInt_BE( val: integer );
    procedure writeFloat_BE( val: single );
    procedure writeOctets ( oct: TOctets );
    procedure writeWord ( val: word );
    procedure writeWord_BE ( val: word );
    procedure writeWIDEString ( str: Widestring );

  private
    function SwapEndian32( value: DWORD ): DWORD;
    function SwapEndian32Float( value: single ): single;
    function SwapEndian16 ( value: word ): word;

  end;

implementation

function TswooshMemoryBuffer.SwapEndian32Float( value: single ): single;
asm
  mov edx, value;
  bswap edx;
  mov result, edx;
end;

function TswooshMemoryBuffer.SwapEndian32( value: DWORD ): DWORD;
asm
  mov edx, value;
  bswap edx;
  mov result, edx;
end;

function TswooshMemoryBuffer.SwapEndian16 ( value: word ): word;
begin
  result := Swap( value );
end;

constructor TswooshMemoryBuffer.Create;
begin
  inherited Create;
end;

procedure TswooshMemoryBuffer.writeWord ( val: word );
begin
  self.WriteData( val );
end;

procedure TswooshMemoryBuffer.writeWord_BE ( val: word );
begin
  self.WriteData( self.SwapEndian16( val ));
end;

procedure TswooshMemoryBuffer.writeWIDEString ( str: Widestring );
begin
  self.writeCUInt( length( str ) * 2 );
  self.WriteData(@str[ 1 ], length( str ) * 2 );
end;

procedure TswooshMemoryBuffer.writeOctets ( oct: TOctets );
begin
  self.writeCUInt( oct.octetLen );
  if ( oct.octetLen > 0 )
  then
    self.WriteData( oct.octets[ 0 ], oct.octetLen );
end;

procedure TswooshMemoryBuffer.writeInt_BE( val: integer );
begin
  self.WriteData( self.SwapEndian32( val ), 4 );
end;

procedure TswooshMemoryBuffer.writeFloat_BE( val: single );
begin
  self.WriteData( self.SwapEndian32Float( val ), 4 );
end;

procedure TswooshMemoryBuffer.writeCUInt( val: integer );
var
  w: word;
begin
  if ( val < $80 )
  then

    self.writeByte( val )

  else
  begin

    if ( val < $4000 )
    then
    begin
      w := word( val ) or $8000;
      self.writeByte( w shr 8 );
      self.writeByte( w and $FF );
    end
    else
    begin
      // Error!!
      if ( val < $20000000 )
      then
        self.writeByte( val or $C0000000 );

    end;

  end;
end;

procedure TswooshMemoryBuffer.writeByte( val: byte );
begin
  self.WriteData( val );
end;

end.
