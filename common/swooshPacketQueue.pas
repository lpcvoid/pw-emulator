unit swooshPacketQueue;

interface

uses windows, swooshPacket, serverDecl, swooshQueue;

type
  TSwooshPacketQueue = class( TSwooshQueue )
    constructor Create( maxQueueSize: integer ); override;
    Function getPacket: TSwooshPacket;
    procedure addPacket( rawData: TRawData ); overload;
    procedure addPacket( thePacket: TSwooshPacket ); overload;
  end;

implementation

constructor TSwooshPacketQueue.Create( maxQueueSize: integer );
begin
  inherited Create( maxQueueSize );
end;

procedure TSwooshPacketQueue.addPacket( rawData: TRawData );
var
  newPacket: TSwooshPacket;
begin
  newPacket := TSwooshPacket.Create( rawData );
  self.addItem( newPacket );
end;

procedure TSwooshPacketQueue.addPacket( thePacket: TSwooshPacket );
begin
  self.addItem( thePacket );
end;

Function TSwooshPacketQueue.getPacket: TSwooshPacket;
begin

  result := TSwooshPacket( self.getItem );

end;

end.
