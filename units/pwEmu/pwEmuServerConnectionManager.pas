{


 this class is the main connection manager. It handles all sockets that get passed to it in a non-blocking way.
 It keeps count of the sockets (connections) passed to it. For every 64 (default value; changable), it creates a new
 swooshSocketBundleHandler, which manages the (64) sockets and uses select() to query their status. If new data is read,



}

unit pwEmuServerConnectionManager;

interface

uses windows, winsock, swooshSocketConnection, pwEmuConnectionBundleHandler,
  System.SysUtils, System.Generics.Collections, serverDecl, pwEmuWorldManager;

type
  TpwEmuServerConnectionManager = class
    constructor Create( maxHandlerConnections: Cardinal; config: TbigServerConfig; worldMan: TpwEmuWorldManager );
    function addClient( client: TSwooshSocketConnection ): byte;
    function getBundleHandlerStatus: String;
    function connectionCount: Cardinal;
    function bundleHandlerCount: Cardinal;
    function totalBytesSent : UInt64;
    function totalBytesRecieved : UInt64;
  protected // extender classes can see and work with this shit.
    _maxHandlerConnections: Cardinal;
    // Maximum connections a handler may serve before manager creates new
    _maxHandlers: Cardinal;
    // config and shit
    _config: TbigServerConfig;
    // This is just passed to all new bundlehandlers.
    _worldMan: TpwEmuWorldManager;

    // each handler = _maxHandlerConnections connections!
    _bundleHandlers: TList< TpwEmuConnectionBundleHandler >;

    function addBundleHandler( maxConnections: Cardinal ): TpwEmuConnectionBundleHandler;

  end;

implementation

constructor TpwEmuServerConnectionManager.Create( maxHandlerConnections: Cardinal; config: TbigServerConfig; worldMan: TpwEmuWorldManager );
begin
  self._maxHandlerConnections := maxHandlerConnections;
  self._bundleHandlers := TList< TpwEmuConnectionBundleHandler >.Create( );
  self._config := config;
  self._worldMan := worldMan;
  // Nothing yet, dunno

end;

function TpwEmuServerConnectionManager.totalBytesSent : UInt64;
var
  i, c: integer;
begin
  c := self.bundleHandlerCount;
  Result := 0;
  if c > 0
  then
    for i := 0 to c - 1 do
      inc( result, self._bundleHandlers.Items[ i ].bundlehandler.getSentBytes );
end;

function TpwEmuServerConnectionManager.totalBytesRecieved : UInt64;
var
  i, c: integer;
begin
  c := self.bundleHandlerCount;
  result := 0;
  if c > 0
  then
    for i := 0 to c - 1 do
      inc( result, self._bundleHandlers.Items[ i ].bundlehandler.getReadBytes );
end;


function TpwEmuServerConnectionManager.bundleHandlerCount: Cardinal;
begin
  result := self._bundleHandlers.Count;
end;

function TpwEmuServerConnectionManager.connectionCount: Cardinal;
var
  i, c: integer;
begin
  c := self.bundleHandlerCount;
  if c > 0
  then
    for i := 0 to c - 1 do
      inc( result, self._bundleHandlers.Items[ i ].bundlehandler.countConnections );
end;

function TpwEmuServerConnectionManager.getBundleHandlerStatus: String;
var
  i: integer;
begin
  if self.connectionCount > 0
  then
    result := 'TpwEmuServerConnectionManager::BundleStatus: count=' + IntToStr( self.bundleHandlerCount ) + ', connections=' + IntToStr( self.connectionCount ) + ' bytesSent=' + IntToStr(self.totalBytesSent) + ' ,bytesRecv=' + IntToStr(self.totalBytesRecieved)
  else
    result := 'TpwEmuServerConnectionManager::BundleStatus=No bundleHandlers started.';
end;

function TpwEmuServerConnectionManager.addBundleHandler( maxConnections: Cardinal ): TpwEmuConnectionBundleHandler;
begin

  self._bundleHandlers.Add( TpwEmuConnectionBundleHandler.Create( self._bundleHandlers.Count, maxConnections, self._config ,self._worldMan)); // count is always future pisition in array then.

  result := self._bundleHandlers.Last;

end;

function TpwEmuServerConnectionManager.addClient( client: TSwooshSocketConnection ): byte;
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

      if ( self._bundleHandlers.Items[ i ].bundlehandler.hasCapacity )
      then
      begin
        self._bundleHandlers.Items[ i ].bundlehandler.addConnection( client );
        result := i;
        exit;
      end;

    end;

  // If arrived here, no handler has any space. We need new one.

  result := self.addBundleHandler( self._maxHandlerConnections ).bundlehandler.addConnection( client );
end;

end.
