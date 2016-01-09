{


 this class is the main connection manager. It handles all sockets that get passed to it in a non-blocking way.
 It keeps count of the sockets (connections) passed to it. For every 64 (default value; changable), it creates a new
 swooshSocketBundleHandler, which manages the (64) sockets and uses select() to query their status. If new data is read,



}

unit swooshServerConnectionManager;

interface

uses windows, winsock, swooshSocketConnection, swooshConnectionBundleHandler,
  System.SysUtils, swooshPacket;

type
  TswooshConnectionManager = class
    constructor Create( maxHandlerConnections: Cardinal );
    function addClient( client: TSwooshSocketConnection ): byte;
    function getBundleHandlerStatus: String;
    function connectionCount: Cardinal;
    function bundleHandlerCount: Cardinal;
    function bundleHasIncomingPackets: boolean;
    function bundleGetIncomingPacket: TInternalSwooshPacket;
    procedure bundleSendPacket( thePacket: TInternalSwooshPacket );

  protected //extender classes can see and work with this shit.
    _maxHandlerConnections: Cardinal;
    // Maximum connections a handler may serve before manager creates new
    _maxHandlers: Cardinal;
    // each handler = _maxHandlerConnections connections!
    _bundleHandlers: array of TswooshConnectionBundleHandler;
    function addBundleHandler( maxConnections: Cardinal ): TswooshConnectionBundleHandler;

  end;

implementation

constructor TswooshConnectionManager.Create( maxHandlerConnections: Cardinal );
begin
  self._maxHandlerConnections := maxHandlerConnections;

  // Nothing yet, dunno

end;

procedure TswooshConnectionManager.bundleSendPacket ( thePacket: TInternalSwooshPacket );
begin

  if ( thePacket <> nil ) and ( thePacket.bundleID <= self.bundleHandlerCount )
  then
  begin
    self._bundleHandlers[ thePacket.bundleID ].sendPacketQueue.addInternalPacket ( thePacket );
  end;

end;

function TswooshConnectionManager.bundleHasIncomingPackets: boolean;
var
  i, c: integer;
begin
  c := self.bundleHandlerCount;
  result := false;
  if c > 0
  then
    for i := 0 to c - 1 do
      if self._bundleHandlers[ i ].readPacketQueue.itemInQueue
      then
      begin
        result := true;
        exit;
      end;

end;

function TswooshConnectionManager.bundleGetIncomingPacket: TInternalSwooshPacket;
var
  i, c: integer;
begin

  c := self.bundleHandlerCount;
  if c > 0
  then
    for i := 0 to c - 1 do
      if self._bundleHandlers[ i ].readPacketQueue.itemInQueue
      then
      begin
        result := self._bundleHandlers[ i ].readPacketQueue.getInternalPacket;
        exit;
      end;
end;

function TswooshConnectionManager.bundleHandlerCount: Cardinal;
begin
  result := length( self._bundleHandlers );
end;

function TswooshConnectionManager.connectionCount: Cardinal;
var
  i, c: integer;
begin
  c := self.bundleHandlerCount;
  if c > 0
  then
    for i := 0 to c - 1 do
      inc( result, self._bundleHandlers[ i ].countConnections );
end;

function TswooshConnectionManager.getBundleHandlerStatus: String;
var
  i: integer;
begin
  if self.connectionCount > 0
  then
    result := 'TswooshConnectionManager::BundleStatus: active=' + IntToStr( self.bundleHandlerCount ) + ', connections=' + IntToStr( self.connectionCount )
  else
    result := 'TswooshConnectionManager::BundleStatus=No bundleHandlers started.';
end;

function TswooshConnectionManager.addBundleHandler( maxConnections: Cardinal ): TswooshConnectionBundleHandler;
begin
  setlength( self._bundleHandlers, length( self._bundleHandlers ) + 1 );
  self._bundleHandlers[ length( self._bundleHandlers ) - 1 ] := TswooshConnectionBundleHandler.Create( length( self._bundleHandlers ) - 1, maxConnections );
  result := self._bundleHandlers[ length( self._bundleHandlers ) - 1 ];
end;

function TswooshConnectionManager.addClient ( client: TSwooshSocketConnection ): byte;
var
  i, c: integer;
begin
  // find out what handler still has space.
  // If none have space, create new and assign this connection to it.
  // The handlers themselves do not handle any specific task.
  // for example, it does not specifically handle any database access for dbdaemon.

  c := self.bundleHandlerCount;

  if c > 0
  then
    for i := 0 to c - 1 do
    begin

      if ( self._bundleHandlers[ i ].hasCapacity )
      then
      begin
        self._bundleHandlers[ i ].addConnection( client );
        result := i;
        exit;
      end;

    end;

  // If arrived here, no handler has any space. We need new one.

  result := self.addBundleHandler( self._maxHandlerConnections ).addConnection( client );
end;

end.
