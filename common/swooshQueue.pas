unit swooshQueue;

interface

uses windows, classes, System.Generics.Collections;

type
  TSwooshQueue = class
    constructor Create( maxQueueSize: integer ); virtual;
    Function getItem: Pointer;
    procedure addItem( rawData: Pointer );
    function itemInQueue: boolean;

  private
    queue: TQueue< Pointer >;
    // l : TList;
    // maybe use list which does this for us? But is list threadsafe?
    critsect: TRTLCriticalSection;
  end;

implementation

constructor TSwooshQueue.Create( maxQueueSize: integer );
begin
  self.queue := TQueue< Pointer >.Create;
  InitializeCriticalSection( self.critsect );
end;

procedure TSwooshQueue.addItem( rawData: Pointer );
begin
  try
    EnterCriticalSection( self.critsect );

    self.queue.Enqueue( rawData );

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TSwooshQueue.itemInQueue: boolean;
begin
  try
    EnterCriticalSection( self.critsect );
    Result := self.queue.Count > 0;
  finally
    LeaveCriticalSection( self.critsect );
  end;

end;

Function TSwooshQueue.getItem: Pointer;
var
  i: integer;
begin
  try
    EnterCriticalSection( self.critsect );
    if self.queue.Count > 0
    then
      Result := self.queue.Dequeue
  else
    Result := nil;
finally
  LeaveCriticalSection( self.critsect );
end;
end;

end.
