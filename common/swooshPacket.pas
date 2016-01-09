unit swooshPacket;

interface

uses windows, classes, System.SysUtils, serverDecl, winsock, pwEmuDataTypes;

type
  TSwooshPacket = class
  private
    // data

    bufferPos: NativeUInt;

    endianess: byte; // 0 - little (standard), 1 = big (faggotry)

  public
    buffer: TRawData;
    constructor Create; overload;
    constructor Create( rawData: TRawData ); overload;
    destructor Destroy; override;
    // destructor Destroy; override;
    Function GetpacketLength: NativeUInt;
    procedure setPacketLength( len: cardinal );
    Function getPacketType: cardinal;
    function getPosition: cardinal;
    function EOF: boolean;
    procedure Rewind;
    procedure Flush;
    procedure skipBytes ( skip: cardinal );
    procedure setBigEndian;
    procedure setLittleEndian;

    Function ReadByte: byte;
    Function ReadCUInt: integer;
    Function ReadCUIntDetail: TCUINTDetailResult;
    Function ReadDWORD: cardinal;
    Function ReadWIDEString: String;
    function ReadAnsiString: AnsiString;
    function ReadRawData ( len: cardinal ): TRawData;
    function ReadHashKey: THashKey;
    function ReadInt64: int64;
    function ReadWord: Word;
    function ReadOctets: TOctets;

    Procedure WriteDWORD( value: DWORD );
    procedure WriteDouble( value: double );
    Procedure WriteInteger( value: integer );
    Procedure Writebyte( value: byte );
    Procedure WriteANSIString( value: AnsiString );
    Procedure WriteWIDEString( value: Widestring );
    procedure WriteWord( value: Word );
    procedure WriteCUInt( value: integer );
    procedure WriteInt64( value: int64 );
    procedure WriteOctets( ptr: pointer; len: DWORD );
    procedure WriteRawData( ptr: pointer; len: DWORD );

    Function packet2String: string;
  end;

type
  TInternalSwooshPacket = class( TSwooshPacket )
  public
    bundleID    : integer;
    connectionID: TSocket;
    constructor Create( ); overload;
    constructor Create( rawData: TRawData; connectionID: cardinal ); overload;
    constructor Create( pRawData: pointer; len: cardinal; connectionID: cardinal ); overload;
    destructor Destroy; override;

    procedure WriteDWORD_BE( value: DWORD );
    function readDWORD_BE: cardinal;

    function SwapEndian( value: DWORD ): DWORD;
  end;

implementation

function TInternalSwooshPacket.SwapEndian( value: DWORD ): DWORD;
asm
  mov edx, value;
  bswap edx;
  mov result, edx;
end;

constructor TInternalSwooshPacket.Create( );
begin
  inherited Create( );
end;

destructor TInternalSwooshPacket.Destroy;
begin
  inherited;
end;

constructor TInternalSwooshPacket.Create( rawData: TRawData; connectionID: cardinal );
begin
  inherited Create( );
  if length( rawData ) > 0
  then
  begin
    self.bufferPos := 0;
    setlength( self.buffer, length( rawData ));
    CopyMemory(@self.buffer[ 0 ], @rawData[ 0 ], length( rawData ));
  end;
  self.connectionID := connectionID;
end;

constructor TInternalSwooshPacket.Create( pRawData: pointer; len: cardinal; connectionID: cardinal );
begin
  if ( len > 0 )
  then
  begin
    self.bufferPos := 0;
    setlength( self.buffer, len );
    CopyMemory(@self.buffer[ 0 ], pRawData, len );
  end;
  self.connectionID := connectionID;
end;

constructor TSwooshPacket.Create;
begin
  self.bufferPos := 0;
end;

function TSwooshPacket.getPosition: cardinal;
begin
  result := self.bufferPos;
end;

function TSwooshPacket.EOF: boolean;
begin
  result := self.bufferPos >= self.GetpacketLength;
end;

procedure TSwooshPacket.setBigEndian;
begin
  self.endianess := 1;
end;

procedure TSwooshPacket.setLittleEndian;
begin
  self.endianess := 0;
end;

procedure TSwooshPacket.skipBytes ( skip: cardinal );
begin
  inc( self.bufferPos, skip );
end;

constructor TSwooshPacket.Create( rawData: TRawData );
begin
  if length( rawData ) > 0
  then
  begin
    self.bufferPos := 0;
    setlength( self.buffer, length( rawData ));
    CopyMemory(@self.buffer[ 0 ], @rawData[ 0 ], length( rawData ));
    self.bufferPos := 0;
  end;
end;

destructor TSwooshPacket.Destroy;
begin
  setlength( self.buffer, 0 );
  inherited;
end;

procedure TSwooshPacket.Rewind;
begin
  self.bufferPos := 0;
end;

procedure TSwooshPacket.Flush;
begin
  self.bufferPos := 0;
  setlength( self.buffer, 0 );
end;

procedure TSwooshPacket.setPacketLength( len: cardinal );
begin
  setlength( self.buffer, len );
end;

function TSwooshPacket.GetpacketLength: NativeUInt;
begin
  result := length( self.buffer );
end;

Function TSwooshPacket.getPacketType: cardinal;
var
  realpos: cardinal;
begin
  realpos := self.bufferPos;
  self.bufferPos := 0;
  if length( self.buffer ) > 0
  then
    result := self.ReadCUInt;
  self.bufferPos := realpos;
end;

procedure TSwooshPacket.WriteOctets( ptr: pointer; len: DWORD );
begin
  self.WriteCUInt( len );
  if ptr <> nil
  then
  begin
    setlength( self.buffer, length( self.buffer ) + len );
    CopyMemory(@self.buffer[ length( buffer ) - len ], ptr, len );
  end;
end;

function TSwooshPacket.ReadOctets: TOctets;
begin
  result.octetLen := self.ReadCUInt;
  setlength( result.octets, result.octetLen );
  result.octets := self.ReadRawData( result.octetLen );

end;

procedure TSwooshPacket.WriteRawData( ptr: pointer; len: DWORD );
begin
  setlength( self.buffer, length( self.buffer ) + len );
  CopyMemory(@self.buffer[ length( buffer ) - len ], ptr, len );
end;

procedure TSwooshPacket.WriteInt64( value: int64 );
begin
  setlength( self.buffer, length( self.buffer ) + 8 );
  CopyMemory(@self.buffer[ length( buffer ) - 8 ], @value, 8 );
end;

procedure TSwooshPacket.WriteDouble( value: double );
begin
  setlength( self.buffer, length( self.buffer ) + 8 );
  CopyMemory(@self.buffer[ length( buffer ) - 8 ], @value, 8 );
end;

procedure TSwooshPacket.WriteDWORD( value: cardinal );
begin
  setlength( self.buffer, length( self.buffer ) + 4 );
  CopyMemory(@self.buffer[ length( buffer ) - 4 ], @value, 4 );
end;

procedure TInternalSwooshPacket.WriteDWORD_BE( value: DWORD );
begin
  value := self.SwapEndian( value );
  setlength( self.buffer, length( self.buffer ) + 4 );
  CopyMemory(@self.buffer[ length( buffer ) - 4 ], @value, 4 );
end;

function TInternalSwooshPacket.readDWORD_BE: cardinal;
begin
  result := self.SwapEndian( self.ReadDWORD );
end;

procedure TSwooshPacket.WriteInteger( value: integer );
begin
  setlength( self.buffer, length( self.buffer ) + 4 );
  CopyMemory(@self.buffer[ length( buffer ) - 4 ], @value, 4 );
end;

procedure TSwooshPacket.WriteWord( value: Word );
begin
  setlength( self.buffer, length( self.buffer ) + 2 );
  CopyMemory(@self.buffer[ length( buffer ) - 2 ], @value, 2 );
end;

procedure TSwooshPacket.Writebyte( value: byte );
begin
  setlength( self.buffer, length( self.buffer ) + 1 );
  CopyMemory(@self.buffer[ length( buffer ) - 1 ], @value, 1 );
end;

Procedure TSwooshPacket.WriteANSIString( value: AnsiString );
begin
  self.WriteCUInt( length( value ));
  setlength( self.buffer, length( self.buffer ) + length( value ));
  CopyMemory(@self.buffer[ length( buffer ) - length( value )], @value[ 1 ], length( value ));
end;

Procedure TSwooshPacket.WriteWIDEString( value: Widestring );
begin
  self.WriteCUInt( length( value ) * 2 );
  setlength( self.buffer, length( self.buffer ) + length( value ) * 2 );
  CopyMemory(@self.buffer[ length( buffer ) - length( value ) * 2 ], @value[ 1 ], length( value ) * 2 );
end;

function TSwooshPacket.ReadRawData ( len: cardinal ): TRawData;
begin

  setlength( result, len );
  CopyMemory(@result[ 0 ],@self.buffer[ self.bufferPos ], len );
  inc( self.bufferPos, len );
end;

function TSwooshPacket.ReadHashKey: THashKey;
begin
  CopyMemory(@result[ 0 ],@self.buffer[ self.bufferPos ], 16 );
  inc( self.bufferPos, 16 );
end;

function TSwooshPacket.ReadByte: byte;
begin
  if bufferPos >= self.GetpacketLength
  then
    Exception.Create( 'TSwooshPacket.Readbyte : bufferPos < Length of packet!' );
  result := self.buffer[ bufferPos ];
  inc( self.bufferPos );
end;

function TSwooshPacket.ReadAnsiString: AnsiString;
var
  len: cardinal;
begin
  len := self.ReadCUInt;
  setlength( result, len );
  CopyMemory(@result[ 1 ], @self.buffer[ self.bufferPos ], len );
  inc( self.bufferPos, len );
end;

Function TSwooshPacket.ReadWIDEString: String;
var
  len: cardinal;
begin
  len := self.ReadCUInt;
  setlength( result, len );
  CopyMemory(@result[ 1 ], @self.buffer[ self.bufferPos ], len * 2 );
  inc( self.bufferPos, len * 2 );
  // Result := WideCharLenToString(Result, Len);
end;

function TSwooshPacket.ReadDWORD: cardinal;
begin
  CopyMemory(@result, @self.buffer[ bufferPos ], 4 );
  inc( self.bufferPos, 4 );
end;

function TSwooshPacket.ReadInt64: int64;
begin
  CopyMemory(@result, @self.buffer[ bufferPos ], 8 );
  inc( self.bufferPos, 8 );
end;

function TSwooshPacket.ReadWord: Word;
begin
  CopyMemory(@result, @self.buffer[ bufferPos ], 2 );
  inc( self.bufferPos, 2 );
end;

Function TSwooshPacket.ReadCUInt: integer;
var
  b1, b2, b3, b4: byte;
begin
  b1 := self.ReadByte( );
  if b1 < $80
  then
  begin
    result := b1;
  end else if b1 < $C0
  then
  begin
    b2 := self.ReadByte( );
    result := (( b1 shl 8 ) or b2 ) and $3FFF;
  end
  else
  begin
    b2 := self.ReadByte( );
    b3 := self.ReadByte( );
    b4 := self.ReadByte( );
    result := (( b1 shl 24 ) or ( b2 shl 16 ) or ( b3 shl 8 ) or b4 ) and $1FFFFFFF;
  end;
end;

/// <remarks>
/// This CUINT decode method returns more information. used for getting exact length of CUINT coded stuff.
/// </remarks>
Function TSwooshPacket.ReadCUIntDetail: TCUINTDetailResult;
var
  b1, b2, b3, b4: byte;
begin
  b1 := self.ReadByte( );
  if b1 < $80
  then
  begin
    result.value := b1;
    result.bytes := 1;
  end else if b1 < $C0
  then
  begin
    b2 := self.ReadByte( );
    result.value := (( b1 shl 8 ) or b2 ) and $3FFF;
    result.bytes := 2;
  end
  else
  begin
    b2 := self.ReadByte( );
    b3 := self.ReadByte( );
    b4 := self.ReadByte( );
    result.value := (( b1 shl 24 ) or ( b2 shl 16 ) or ( b3 shl 8 ) or b4 ) and $1FFFFFFF;
    result.bytes := 4;
  end;

end;

procedure TSwooshPacket.WriteCUInt( value: integer );
var
  w: Word;
begin
  if ( value < $80 )
  then

    self.Writebyte( value )

  else
  begin

    if ( value < $4000 )
    then
    begin
      w := Word( value ) or $8000;
      self.Writebyte( w shr 8 );
      self.Writebyte( w and $FF );
    end
    else
    begin

      if ( value < $20000000 )
      then
        self.WriteInteger( value or $C0000000 );

    end;

  end;
end;

Function TSwooshPacket.packet2String: string;
var
  i, zeros: integer;
  temp    : String;
begin
  temp := '| ';
  zeros := 0;
  if length( self.buffer ) > 0
  then
    for i := 1 to length( buffer ) do
    begin
      if zeros > 20
      then
        Continue;

      if ( self.buffer[ i - 1 ] = 0 )
      then
        inc( zeros );
      temp := temp + IntToHex( self.buffer[ i - 1 ], 2 ) + ' ';
      if ( i mod 16 = 0 ) and ( i <> 0 )
      then
        temp := temp + ' |' + #13#10 + '| ';
    end;

  if zeros > 20
  then
    temp := temp + '... loads of 00';

  result := temp;

end;

end.
