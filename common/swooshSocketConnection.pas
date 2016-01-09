unit swooshSocketConnection;

interface

uses winsock, swooshPacket, serverDecl, windows, System.SysUtils, System.Generics.Collections;

type
  TSwooshSocketConnection = class

    constructor Create( theSocket: TSocket; sockAddr: sockaddr_in; maxRecvBuffer: integer );
    destructor Destroy; override;
    function getIP: string;
    function getPort: word;
    function getSocket: TSocket;
    function readData: TInternalSwooshPacket;
    function getState: TSocketState;
    function sendPacket( thePacket: TInternalSwooshPacket ): integer; overload;
    function sendPacket( thePacket: TSwooshPacket ): integer; overload;
    // For non-blocking sockets stuff.
    procedure addPacketToQueue( thePacket: TInternalSwooshPacket );
    function sendAllQueuedPackets: integer;
    procedure disconnect;

  private
    _state        : TSocketState;
    _socket       : TSocket;
    _sockaddr_in  : sockaddr_in;
    _maxRecvBuffer: integer;
    _buffer       : TRawData;
    _encrypted    : Boolean; // If this is set, all swooshpackets get encrypted flag set to true.
    critsect      : TRTLCriticalSection;
    _sendQueue    : TQueue< TInternalSwooshPacket >;
    procedure setSocketState( newState: TSocketState );
  end;

implementation

constructor TSwooshSocketConnection.Create( theSocket: TSocket; sockAddr: sockaddr_in; maxRecvBuffer: integer );
begin

  if ( self._socket <> INVALID_SOCKET )
  then
  begin
    InitializeCriticalSection( self.critsect );
    self._socket := theSocket;
    self._sockaddr_in := sockAddr;
    self._maxRecvBuffer := maxRecvBuffer;
    setlength( self._buffer, self._maxRecvBuffer );
    self._sendQueue := TQueue< TInternalSwooshPacket >.Create;
    self.setSocketState( Connected );
  end
  else
  begin
    self.disconnect;
  end;

end;

procedure TSwooshSocketConnection.addPacketToQueue( thePacket: TInternalSwooshPacket );
begin
  self._sendQueue.Enqueue( thePacket );
end;

function TSwooshSocketConnection.sendAllQueuedPackets: integer;
var
  c, i: integer;
begin
  result := 0;
  c := self._sendQueue.Count;
  if ( c > 0 )
  then
  begin
    for i := 0 to c - 1 do
      result := result + self.sendPacket( self._sendQueue.Dequeue );

  end
  else
    result := 0;
end;

procedure TSwooshSocketConnection.disconnect;
begin
  self.setSocketState( Disconnected );
end;

destructor TSwooshSocketConnection.Destroy;
begin
  shutdown( self._socket, 0 );
  closesocket( self._socket );
end;

function TSwooshSocketConnection.sendPacket ( thePacket: TInternalSwooshPacket ): integer;
begin
  result := winsock.send( self._socket, thePacket.buffer[ 0 ], thePacket.GetpacketLength, 0 );
  FreeAndNil( thePacket );
end;

/// <remarks>
/// This does <c>NOT</c> support the encryption flag.
/// </remarks>
function TSwooshSocketConnection.sendPacket( thePacket: TSwooshPacket ): integer;
begin
  // does NOT support encryption.
  result := winsock.send( self._socket, thePacket.buffer[ 0 ], thePacket.GetpacketLength, 0 );
  FreeAndNil( thePacket );
end;

function TSwooshSocketConnection.getState: TSocketState;
begin
  EnterCriticalSection( self.critsect );
  result := self._state;
  LeaveCriticalSection( self.critsect );
end;

procedure TSwooshSocketConnection.setSocketState( newState: TSocketState );
begin
  EnterCriticalSection( self.critsect );
  self._state := newState;
  LeaveCriticalSection( self.critsect );
end;

function TSwooshSocketConnection.readData: TInternalSwooshPacket;
var
  recvLen, error: integer;
begin
  // No need for CS here, because only thing calling this is creator thread.
  if ( self._socket <> INVALID_SOCKET ) and ( self.getState = Connected )
  then
  begin

    recvLen := recv( self._socket, self._buffer[ 0 ], self._maxRecvBuffer, 0 );

    if ( recvLen > 0 )
    then
    begin
      // connected, maybe packet.
      result := TInternalSwooshPacket.Create( self._buffer );
      result.setPacketLength(recvLen);
    end
    else
    begin

      error := WSAGetLastError;

      // Was buffer too small?
      if error = WSAEMSGSIZE
      then
        writeln( '******WINSOCK ERROR : WSAEMSGSIZE! cid=' + inttostr( self.getSocket ));

      if error = WSAEWOULDBLOCK
      then
        writeln( '******WINSOCK ERROR : WSAEWOULDBLOCK! cid=' + inttostr( self.getSocket ));

      if error = WSAEINPROGRESS
      then
        writeln( '******WINSOCK ERROR : WSAEINPROGRESS! cid=' + inttostr( self.getSocket ));

      self.disconnect;
      result := nil;
    end;

  end
  else
  begin
    self.disconnect;
  end;

end;

function TSwooshSocketConnection.getIP: string;
begin
  result := inet_ntoa( self._sockaddr_in.sin_addr );
end;

function TSwooshSocketConnection.getPort: word;
begin
  result := self._sockaddr_in.sin_port;

end;

function TSwooshSocketConnection.getSocket: TSocket;
begin
  result := self._socket;
end;

end.
