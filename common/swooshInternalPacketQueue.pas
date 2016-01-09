unit swooshInternalPacketQueue;

interface

uses windows, swooshPacket, System.Generics.Collections;

type
  TSwooshInternalPacketQueue = class
  public
    constructor Create( maxQueueSize: integer );
    Function getInternalPacket: TInternalSwooshPacket;
    procedure addInternalPacket( thePacket: TInternalSwooshPacket );
    function itemInQueue: boolean;

  private
    _queue  : TQueue< TInternalSwooshPacket >;
    critsect: TRTLCriticalSection;

  end;

implementation

constructor TSwooshInternalPacketQueue.Create( maxQueueSize: integer );
begin
  self._queue := TQueue< TInternalSwooshPacket >.Create;
  InitializeCriticalSection( self.critsect );
end;

procedure TSwooshInternalPacketQueue.addInternalPacket ( thePacket: TInternalSwooshPacket );
begin
  try
    EnterCriticalSection( self.critsect );

    self._queue.Enqueue( thePacket );

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TSwooshInternalPacketQueue.itemInQueue: boolean;
begin
  try
    EnterCriticalSection( self.critsect );
    Result := self._queue.Count > 0;
  finally
    LeaveCriticalSection( self.critsect );
  end;

end;

Function TSwooshInternalPacketQueue.getInternalPacket: TInternalSwooshPacket;
begin

  try
    EnterCriticalSection( self.critsect );
    if self._queue.Count > 0
    then
      Result := self._queue.Dequeue
    else
      Result := nil;
  finally
    LeaveCriticalSection( self.critsect );
  end;

end;

end.
