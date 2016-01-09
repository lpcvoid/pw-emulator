unit swooshListener;

interface

uses windows, winsock, classes, serverDecl, swooshSocketBase,
  swooshWinsockImports, sysutils, swooshConnectionQueue, swooshSocketConnection;

type
  TswooshListener = class( TThread )
    // connection queue!
    connectionQueue: TSwooshConnectionQueue;
    constructor create( localEndpoint: TIPEndpoint; serverConfig: TbigServerConfig  );
    destructor Destroy; override;
    procedure startListen;
    function getState: TSocketState;

  private
    listenSocket: TSocket;
    wsaBase     : TSwooshSocketBase;
    hints       : TAddrInfo;

    config: TbigServerConfig;

    localEndpoint : TIPEndpoint;

    // state
    socketState: TSocketState;

    // thread safety
    critsect: TRTLCriticalSection;
    procedure setSocketState( newState: TSocketState );

  protected
    procedure Execute; override;
  end;

implementation

constructor TswooshListener.create( localEndpoint: TIPEndpoint; serverConfig: TbigServerConfig );
begin
  inherited create( true );

  self.FreeOnTerminate := true;

  self.config := serverConfig;

  self.localEndpoint := localEndpoint;

  InitializeCriticalSection( self.critsect );

  self.setSocketState( Disconnected );

  self.wsaBase := TSwooshSocketBase.create;

  self.connectionQueue := TSwooshConnectionQueue.create( serverConfig.maxQueue );

  if wsaBase.wsaStartupReturn = 0
  then
    self.socketState := Connected;

end;

destructor TswooshListener.Destroy;
begin
  closesocket( self.listenSocket );
  WSACleanup;
  inherited
end;

function TswooshListener.getState: TSocketState;
begin
  EnterCriticalSection( self.critsect );
  result := self.socketState;
  LeaveCriticalSection( self.critsect );
end;

procedure TswooshListener.setSocketState( newState: TSocketState );
begin
  EnterCriticalSection( self.critsect );
  self.socketState := newState;
  LeaveCriticalSection( self.critsect );
end;

procedure TswooshListener.startListen;
var
  bindRes: Integer;
  // getAddrInfoRes : integer;
  // getAddrInfoResPtr : PAddrInfo;
begin
  // create listen socket, which will then assign
  // threads and sockets to incomming connections

  self.hints.ai_socktype := SOCK_STREAM;
  // self.hints.ai_addr.sa_family := AF_INET;
  self.hints.ai_addr.sin_family := AF_INET;
  self.hints.ai_flags := AI_PASSIVE;
  self.hints.ai_addr.sin_port := htons( self.localEndpoint.port );
  self.hints.ai_addr.sin_addr := TInAddr( inet_addr( PAnsiChar( self.localEndpoint.ip )));

  // getAddrInfoRes := getaddrinfo(PAnsiChar(self.config.localIP),PAnsiChar(self.config.localPort),@self.hints,getAddrInfoResPtr);

  self.listenSocket := socket( AF_INET, SOCK_STREAM, IPPROTO_TCP );

  if ( self.listenSocket <> INVALID_SOCKET )
  then
  begin
    bindRes := bind( self.listenSocket, self.hints.ai_addr, SizeOf( self.hints.ai_addr ));

    if ( bindRes = 0 )
    then
    begin

      if ( listen( self.listenSocket, self.config.maxBacklog ) = 0 )
      then
        self.Resume
      else
      begin
        writeln( 'listen() error! error=' + InttoStr( WSAGetLastError ));
      end;

    end
    else
    begin
      writeln( 'Bind() error! error=' + InttoStr( WSAGetLastError ));
    end;

  end;

end;

procedure TswooshListener.Execute;
var
  socketConfig: TSwooshSocketConnection;

  tempSocket: TSocket;

  tempAddr: sockaddr_in;

  sockaddr_in_Len: Integer;
begin

  sockaddr_in_Len := SizeOf( sockaddr_in );

  writeln( 'Started main server listener.' );

  while ( self.Terminated = false ) AND ( self.getState = Connected ) do
  begin

    sleep( 500 );
    // EnterCriticalSection(self.critsect);
    while ( self.getState <> Disconnected ) do
    begin
      // accept etc
      //writeln( 'Waiting for client...' );

      tempSocket := accept( self.listenSocket, @tempAddr, @sockaddr_in_Len );
      // writeln('New client! ip=' + inet_ntoa(tempSocket.sockaddr_in.sin_addr) + ':' + IntToStr(tempSocket.sockaddr_in.sin_port));
      // add these to a queue -> TSocketQueue
      socketConfig := TSwooshSocketConnection.create( tempSocket, tempAddr, self.config.recvBuffer );

      self.connectionQueue.addConnection( socketConfig );

      // self.socketState := Disconnected;
    end;
  end;

end;

end.
