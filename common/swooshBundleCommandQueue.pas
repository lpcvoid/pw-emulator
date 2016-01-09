{


 This queue transmits commands and events for the inheritor class. In pwEmu case it's the pwEmuConnectionBundleHandler.
 events can be disconnection of client, connection of one, and other shit.
 This queue only accepts integers.

 Disconnect :
 2
 [ID of socket disconnected]

 connected
 1
 [ID of socket connected]

}

unit swooshBundleCommandQueue;

interface

uses windows, system.Generics.Collections;

// Socket event handler for the TswooshBundleCommandQueue
type
  TSocketEvent = packed record
    socketID: integer;
    eventID: integer;
  end;

type
  TswooshBundleCommandQueue = class
  public
    constructor Create( maxQueueSize: integer );
    Function getCommand: TSocketEvent;
    procedure addCommandEvent( theCommand: TSocketEvent );
    function hasEvent: Boolean;

  private
    _eventQueue: TQueue< TSocketEvent >;
    _critSect  : TRTLCriticalSection;

  end;

implementation

constructor TswooshBundleCommandQueue.Create( maxQueueSize: integer );
begin
  InitializeCriticalSection( self._critSect );
  self._eventQueue := TQueue< TSocketEvent >.Create;

end;

procedure TswooshBundleCommandQueue.addCommandEvent ( theCommand: TSocketEvent );
begin
  try
    EnterCriticalSection( self._critSect );

    self._eventQueue.Enqueue( theCommand );

  finally

    LeaveCriticalSection( self._critSect );

  end;
end;

Function TswooshBundleCommandQueue.getCommand: TSocketEvent;
begin
  try
    EnterCriticalSection( self._critSect );

    if ( self._eventQueue.Count > 0 )
    then
      result := self._eventQueue.Dequeue;

  finally

    LeaveCriticalSection( self._critSect );

  end;
end;

function TswooshBundleCommandQueue.hasEvent: Boolean;
begin
  try
    EnterCriticalSection( self._critSect );

    result := ( self._eventQueue.Count > 0 );

  finally

    LeaveCriticalSection( self._critSect );

  end;
end;

end.
