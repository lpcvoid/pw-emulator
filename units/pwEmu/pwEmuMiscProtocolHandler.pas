unit pwEmuMiscProtocolHandler;

interface

uses swooshPacket, winsock, windows, serverDecl;

type
  TpwEmuMiscProtocolHandler = class
  public
    function build_s2c_5A_KeepalivePong( thePacket: TInternalSwooshPacket ): TInternalSwooshPacket;
  end;

implementation

function TpwEmuMiscProtocolHandler.build_s2c_5A_KeepalivePong( thePacket: TInternalSwooshPacket ): TInternalSwooshPacket;
begin
  result := thePacket;
  result.Flush;
  result.WriteCUInt( $5A );
  result.Writebyte( 1 );
  result.WriteCUInt( $5A );
end;

end.
