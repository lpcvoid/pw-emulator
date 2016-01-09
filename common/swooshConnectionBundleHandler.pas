unit swooshConnectionBundleHandler;

interface

uses winsock, windows, swooshSocketConnection, classes, serverDecl,
  System.SysUtils, swooshPacket, swooshInternalPacketQueue, swooshBundleCommandQueue, System.Generics.Collections;

type
  TswooshConnectionBundleHandler = class( TThread )
  public
    bundleID: integer;
    // This handles packets which have the bundle ID, TSocket and pointer to swooshpacket.
    readPacketQueue: TSwooshInternalPacketQueue;
    // This handles packets which have the bundle ID, TSocket and pointer to swooshpacket.
    sendPacketQueue: TSwooshInternalPacketQueue;

    // Command queue contains commands for the class which inherits this class. VERY IMPORTANT.

    commandEventQueue: TswooshBundleCommandQueue;

    constructor Create( _bundleID: integer; maxSockets: cardinal );
    function addConnection( sock: TSwooshSocketConnection ): byte;
    function hasCapacity: boolean;
    function countConnections: cardinal;
    function getSentBytes: UInt64;
    function getReadBytes: UInt64;

    // function hasIncomingPackets : boolean; //query readpacketQueue for any new packets, say if new are.
  private
    _connectionArray      : TList< TSwooshSocketConnection >;
    _maxConnections       : cardinal;
    critsect              : TRTLCriticalSection;
    fdSets                : TFDSets;
    _bytesSent, _bytesRead: UInt64;
    procedure fillFDSets;
    procedure fillSendQueues;
    procedure refreshConnections;

  protected
    procedure Execute; override;

  end;

implementation

constructor TswooshConnectionBundleHandler.Create( _bundleID: integer; maxSockets: cardinal );
begin
  inherited Create( True );
  InitializeCriticalSection( self.critsect );
  self.bundleID := _bundleID;
  self.readPacketQueue := TSwooshInternalPacketQueue.Create( maxSockets * 20 );
  self.sendPacketQueue := TSwooshInternalPacketQueue.Create( maxSockets * 20 );
  self.commandEventQueue := TswooshBundleCommandQueue.Create( maxSockets * 20 );
  self._connectionArray := TList< TSwooshSocketConnection >.Create;
  self._maxConnections := maxSockets;
  self.Resume;
end;

function TswooshConnectionBundleHandler.countConnections: cardinal;
begin
  try
    EnterCriticalSection( self.critsect );

    result := self._connectionArray.Count;

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TswooshConnectionBundleHandler.hasCapacity: boolean;
begin
  try
    EnterCriticalSection( self.critsect );

    result := ( self.countConnections( ) < self._maxConnections )

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TswooshConnectionBundleHandler.getSentBytes: UInt64;
begin
  try
    EnterCriticalSection( self.critsect );

    result := self._bytesSent;

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TswooshConnectionBundleHandler.getReadBytes: UInt64;
begin
  try
    EnterCriticalSection( self.critsect );

    result := self._bytesRead;

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

procedure TswooshConnectionBundleHandler.fillFDSets;
var
  i, c: integer;
begin
  // Only called from within CS'ed stuff, so no need for extra CS.

  c := self.countConnections;

  if ( c > 0 )
  then
  begin
    for i := 0 to c - 1 do
    begin
      self.fdSets.readFD.fd_array[ i ] := self._connectionArray[ i ].getSocket;
      self.fdSets.writeFD.fd_array[ i ] := self._connectionArray[ i ].getSocket;
      self.fdSets.errorFD.fd_array[ i ] := self._connectionArray[ i ].getSocket;
    end;

    self.fdSets.readFD.fd_count := c;
    self.fdSets.writeFD.fd_count := c;
    self.fdSets.errorFD.fd_count := c;
    self.fdSets.totalNumber := c * 3;
  end
  else
  begin
    ZeroMemory(@self.fdSets, SizeOf( TfdSet ) * 3 + 4 );
  end;

end;

function TswooshConnectionBundleHandler.addConnection ( sock: TSwooshSocketConnection ): byte;
var
  ioctlOne, c: integer;
  qParams    : TSocketEvent;
begin
  ioctlOne := 1;
  // set non blocking!
  ioctlsocket( sock.getSocket, FIONBIO, ioctlOne );

  c := self.countConnections( );

  // can this handler still accept connections?
  if ( c < self._maxConnections )
  then
  begin
    // add the connection to the connection array.

    try
      EnterCriticalSection( self.critsect );

      // notify that connection was added.
      qParams.socketID := sock.getSocket;
      qParams.eventID := 1;
      self.commandEventQueue.addCommandEvent( qParams );

      self._connectionArray.Add( sock );

      self.fillFDSets; // refresh the select() fdsets.

      result := 0;

    finally
      LeaveCriticalSection( self.critsect );
    end;

  end
  else
  begin
    result := 1; // bundleHandler full
  end;
end;

procedure TswooshConnectionBundleHandler.refreshConnections;
var
  i      : integer;
  qParams: TSocketEvent;
begin
  // clean out all disconnected connections.
  // only called from within CS - no need for own.

  for i := 0 to self.countConnections( ) - 1 do
  begin
    if ( i >= self.countConnections( ))
    then
      Continue;

    if ( self._connectionArray[ i ].getState <> Connected ) or ( self._connectionArray[ i ].getSocket = INVALID_SOCKET )
    then
    begin
      // Add the disconnect event to the eventCommand queue to notify any perhaps waiting classes above.
      // push to queue in reversed order!!

      qParams.socketID := self._connectionArray[ i ].getSocket;
      qParams.eventID := 2;

      self.commandEventQueue.addCommandEvent( qParams ); // disconnect

      self._connectionArray.Items[ i ].Free;

      self._connectionArray.Delete( i );

    end;
  end;

  self._connectionArray.TrimExcess;
end;

/// <remarks>
/// This fills each connection's send queue. It's an architectural function.
/// </remarks>

procedure TswooshConnectionBundleHandler.fillSendQueues;
var
  internalsendPacket: TInternalSwooshpacket;
  c, i              : integer;
begin
  c := self.countConnections;
  if ( c > 0 )
  then
  begin
    while self.sendPacketQueue.itemInQueue do
    begin
      internalsendPacket := self.sendPacketQueue.getInternalPacket;

      if internalsendPacket <> nil
      then
        for i := 0 to c - 1 do
          if ( self._connectionArray.Items[ i ].getSocket = internalsendPacket.connectionID )
          then
            self._connectionArray.Items[ i ].addPacketToQueue( internalsendPacket );

    end;
  end;
end;

procedure TswooshConnectionBundleHandler.Execute;
var
  selectRet, i, c, bytesSent: integer;
  localfdSets               : TFDSets;
  internalrecvPacket        : TInternalSwooshpacket;
begin
  while self.Terminated = false do
  begin
    // get newest FDSets, via protected CS

    try
      EnterCriticalSection( self.critsect );
      self.refreshConnections;
      self.fillFDSets;
      self.fillSendQueues;
      localfdSets := self.fdSets;
    finally
      LeaveCriticalSection( self.critsect );
    end;

    sleep( 10 );

    // select shit here

    c := self.countConnections( );

    if c = 0
    then
      Continue;

    selectRet := 0;

    selectRet := select( 0, @localfdSets.readFD, @localfdSets.writeFD, @localfdSets.errorFD, nil ); // indefinite timeout!

    try
      EnterCriticalSection( self.critsect );

      if selectRet > 0
      then
      begin

        // get next packet from sendQueue.
        // we do this here so the loop below can check if socket ID of packet matches.

        // let's first check for errors!
        for i := 0 to c - 1 do
        begin

          if ( FD_ISSET( self._connectionArray[ i ].getSocket, localfdSets.errorFD ))
          then
          begin
            // Something bad happened on the socket, or the
            // client closed its half of the connection.  Shut
            // the conn down and remove it from the list.
            self._connectionArray[ i ].disconnect;
            // This is then removed by refreshConnections();
            writeln( 'Socket error! ip=' + self._connectionArray[ i ].getIP + ':' + InttoStr( self._connectionArray[ i ].getPort ));

            Continue; // continue with next socket.

          end;

          if ( FD_ISSET( self._connectionArray[ i ].getSocket, localfdSets.readFD ))
          then
          begin
            // read data!
            internalrecvPacket := self._connectionArray[ i ].readData;

            if internalrecvPacket <> nil
            then
            begin

              internalrecvPacket.bundleID := self.bundleID;
              internalrecvPacket.connectionID := self._connectionArray[ i ].getSocket;

              self.readPacketQueue.addInternalPacket( internalrecvPacket );

              inc( self._bytesRead, internalrecvPacket.GetpacketLength );
            end
            else
            begin
              // disconnected. Don't call free manually, the connection does this automatically.
              writeln( 'Client disconnected. ip=' + self._connectionArray[ i ].getIP + ':' + InttoStr( self._connectionArray[ i ].getPort ));
            end;

          end;


          // Send packets?

          if ( FD_ISSET( self._connectionArray[ i ].getSocket, localfdSets.writeFD ))
          then
          begin

            // send any packets which are still in the queue of this socket.
            bytesSent := self._connectionArray[ i ].sendAllQueuedPackets;
            if ( bytesSent > 0 )
            then
            begin
              writeln( InttoStr( bytesSent ) + ' bytes sent. cid =' + InttoStr( self._connectionArray.Items[ i ].getSocket ) );
              inc( self._bytesSent, bytesSent );
            end;
          end;
        end;

      end
      else
      begin
        writeln( 'Select() error! Error=' + InttoStr( WSAGetLastError ));
        // sleep( 1000 );
      end;

    finally
      LeaveCriticalSection( self.critsect );
    end;

  end;

end;

end.
