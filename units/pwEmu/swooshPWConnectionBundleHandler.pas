unit swooshPWConnectionBundleHandler;


{

 This class does not extend the normal swooshConnectionBundleHandler, it is a complete replacement and used for PW emu.


}

interface

uses winsock, windows, swooshPWSocketConnection, classes, serverDecl,
  System.SysUtils, swooshPacket, swooshInternalPacketQueue,
  swooshPacketCompression;

type
  TswooshSocketGroup = array of TSwooshPWSocketConnection;

type
  TswooshConnectionBundleHandler = class( TThread )
    bundleID: integer;
    readPacketQueue: TSwooshInternalPacketQueue;
    // This handles packets which have the bundle ID, TSocket and pointer to swooshpacket.
    sendPacketQueue: TSwooshInternalPacketQueue;
    // This handles packets which have the bundle ID, TSocket and pointer to swooshpacket.
    constructor Create( _bundleID: integer; maxSockets: cardinal );
    function addConnection( sock: TSwooshPWSocketConnection ): byte;
    function hasCapacity: boolean;
    function countConnections: cardinal;
  private
    _connectionArray: TswooshSocketGroup;
    _maxConnections : cardinal;
    critsect        : TRTLCriticalSection;
    fdSets          : TFDSets;
    procedure fillFDSets;
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
  self._maxConnections := maxSockets;
  self.Resume;
end;

function TswooshConnectionBundleHandler.countConnections: cardinal;
begin
  try
    EnterCriticalSection( self.critsect );

    result := length( self._connectionArray );

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

function TswooshConnectionBundleHandler.addConnection ( sock: TSwooshPWSocketConnection ): byte;
var
  ioctlOne, c: integer;
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

      setlength( self._connectionArray, c + 1 );
      self._connectionArray[ c ] := sock;

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
  i        : integer;
  helpArray: TswooshSocketGroup;
begin
  // clean out all disconnected connections.
  // only called from within CS - no need for own.

  for i := 0 to self.countConnections( ) - 1 do
  begin
    if ( self._connectionArray[ i ].getState = Connected ) and ( self._connectionArray[ i ].getSocket <> INVALID_SOCKET )
    then
    begin
      setlength( helpArray, length( helpArray ) + 1 );
      helpArray[ length( helpArray ) - 1 ] := self._connectionArray[ i ];
    end
    else
      self._connectionArray[ i ].Free;
  end;

  setlength( self._connectionArray, length( helpArray ));
  self._connectionArray := helpArray;
end;

procedure TswooshConnectionBundleHandler.Execute;
var
  selectRet, i, c                       : integer;
  localfdSets                           : TFDSets;
  internalrecvPacket, internalsendPacket: TInternalSwooshPacket;
begin
  while self.Terminated = false do
  begin
    // get newest FDSets, via protected CS

    sleep( 10 );

    try
      EnterCriticalSection( self.critsect );
      self.refreshConnections;
      self.fillFDSets;
      localfdSets := self.fdSets;
    finally
      LeaveCriticalSection( self.critsect );
    end;

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

        internalsendPacket := self.sendPacketQueue.getInternalPacket;

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
            end
            else
            begin
              // disconnected. Don't call manually, the connection does this automatically.
              writeln( 'Client disconnected. ip=' + self._connectionArray[ i ].getIP + ':' + InttoStr( self._connectionArray[ i ].getPort ));
            end;

          end;

          if ( internalsendPacket <> nil ) and ( FD_ISSET( self._connectionArray[ i ].getSocket, localfdSets.writeFD ))
          then
          begin

            if ( internalsendPacket.connectionID = self._connectionArray[ i ].getSocket )
            then
            begin
              // compress packet.

              // self.compressor.CompressPacket(internalsendPacket);

              // send the packet.
              writeln( 'packet sent.' );
              self._connectionArray[ i ].sendPacket( internalsendPacket );
              internalsendPacket.wasSent := True;
            end;

          end;

        end;

        // clean up internalsendPacket if it is still valid, as the socket which it was
        // meant for didn't exist anymore - else it would have been freed.
        if ( internalsendPacket <> nil ) and ( internalsendPacket.wasSent = false )
        then
        begin
          writeln( 'Dropped dead packet from sendQueue.' );
          internalsendPacket.Free;
        end;

      end
      else
      begin
        writeln( 'Select() error! Error=' + InttoStr( WSAGetLastError ));
        sleep( 1000 );
      end;

    finally
      LeaveCriticalSection( self.critsect );
    end;

  end;

end;

end.
