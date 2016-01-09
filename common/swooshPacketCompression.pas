unit swooshPacketCompression;

interface

uses windows, swooshCompression, swooshPacket;

type
  TSwooshPacketCompressor = class( TSwooshCompression )
    constructor Create( );
    procedure CompressPacket( thePacket: TInternalSwooshPacket );
  end;

implementation

constructor TSwooshPacketCompressor.Create( );
begin
  inherited Create;
end;

procedure TSwooshPacketCompressor.CompressPacket ( thePacket: TInternalSwooshPacket );
var
  CompressionBuffer: array of Byte;
  CompressionLength: Integer;
begin

  // should work, since compression will always produce smaller or same output.
  // thePacket.setPacketLength(self.Compress(@thePacket.buffer[0],pointer(thePacket.buffer[0]),thePacket.GetpacketLength));

  // should work, since compression will always produce smaller or same output.
  setlength( CompressionBuffer, thePacket.GetpacketLength + 16 );
  // 16 bytes for safety

  CompressionLength := self.Compress(@thePacket.buffer[ 0 ], Pointer( CompressionBuffer[ 0 ]), thePacket.GetpacketLength );

  CopyMemory(@thePacket.buffer[ 0 ], @CompressionBuffer[ 0 ], CompressionLength );

  thePacket.setPacketLength( CompressionLength );

end;

end.
