unit swooshClient;

interface

uses windows, winsock, swooshPacket, serverDecl, swooshSocketBase, classes,
  System.SysUtils, swooshPacketQueue, swooshSocketConnection;

type
  TSwooshClient = class( TThread )
    constructor Create( destEndpoint: TIPEndpoint; config: TbigServerConfig );
    destructor Destroy; override;
    procedure Connect;
    function sendPacket( thePacket: TSwooshPacket ): integer; overload;
    function sendPacket( thePacket: TInternalSwooshPacket ): integer; overload;
    function recvPacket: TSwooshPacket;
    function getConnectionState : TSocketState;

  private

    // this shit is then passed to connection class
    clientSocket: TSocket;
    sa          : SOCKADDR_IN;

    wsaBase       : TSwooshSocketBase;
    connection    : TSwooshSocketConnection;
    remoteEndPoint: TIPEndpoint;
    config        : TbigServerConfig;
    recvPacketQueue   : TSwooshPacketQueue;
    sendPacketQueue   : TSwooshPacketQueue;
    critsect      : TRTLCriticalSection;
    clientState   : TSocketState;

  protected
    procedure Execute; override;
  end;

implementation

/// <summary>sends a TSwooshPacket to the connected server.</summary>
/// <remarks>
/// This actually wraps TSwooshSocketConnection's sendpacket.
/// </remarks>
function TSwooshClient.sendPacket( thePacket: TSwooshPacket ): integer;

begin
  try
    EnterCriticalSection( self.critsect );
    if ( self.clientState = Connected )
    then
    begin
      //anything in queue that needs to be sent before?

      while (self.sendPacketQueue.itemInQueue) and (self.connection.getState = Connected) do
            begin
             self.sendPacket(self.sendPacketQueue.getPacket);
             sleep(20);
             Writeln('sent delayed packet in queue.');
            end;

      result := self.connection.sendPacket( thePacket )
    end
    else
    begin
     result := 0;
     self.sendPacketQueue.addPacket(thePacket);
    end;
  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TSwooshClient.sendPacket( thePacket: TInternalSwooshPacket ): integer;
begin
  try
    EnterCriticalSection( self.critsect );
    if ( self.clientState = Connected )
    then
    begin
      //anything in queue that needs to be sent before?

      while (self.sendPacketQueue.itemInQueue) and (self.connection.getState = Connected) do
            begin
             self.sendPacket(self.sendPacketQueue.getPacket);
             sleep(20);
             Writeln('sent delayed packet in queue.');
            end;

      result := self.connection.sendPacket( thePacket )
    end
    else
    begin
     result := 0;
     self.sendPacketQueue.addPacket(thePacket);
    end;

  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TSwooshClient.recvPacket: TSwooshPacket;
begin
  try
    EnterCriticalSection( self.critsect );
    result := self.recvPacketQueue.getPacket;
  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

function TSwooshClient.getConnectionState : TSocketState;
begin
  try
    EnterCriticalSection( self.critsect );
    result := self.clientState;
  finally
    LeaveCriticalSection( self.critsect );
  end;
end;

destructor TSwooshClient.Destroy;
begin
  self.connection.Free;

  DeleteCriticalSection(self.critsect);

  inherited;
end;

constructor TSwooshClient.Create( destEndpoint: TIPEndpoint; config: TbigServerConfig );
begin
  inherited Create( true );
  // FreeOnTerminate := true;

  InitializeCriticalSection( self.critsect );

  self.remoteEndPoint := destEndpoint;

  self.config := config;

  self.recvPacketQueue := TSwooshPacketQueue.Create( config.maxQueue );

  self.SendPacketQueue := TSwooshPacketQueue.Create( config.maxQueue );

  self.wsaBase := TSwooshSocketBase.Create;

  if wsaBase.wsaStartupReturn = 0
  then
  begin
    self.clientState := Disconnected;
    self.resume;
  end;

end;

procedure TSwooshClient.Connect;
var
  wsd: integer;
  c: integer;
begin
  self.clientSocket := socket( AF_INET, SOCK_STREAM, 0 );
  if ( self.clientSocket <> INVALID_SOCKET )
  then
  begin
    // ...
    self.sa.sin_family := AF_INET;
    self.sa.sin_port := htons( self.remoteEndPoint.port );
    self.sa.sin_addr.S_addr := inet_addr( PAnsichar( self.remoteEndPoint.ip ));
    ZeroMemory(@self.sa.sin_zero, 8 );

    wsd := winsock.Connect( self.clientSocket, self.sa, sizeof( SOCKADDR_IN ));

    if ( wsd = 0 )
    then
    begin
      // we are connected!

      //ioctlsocket( self.clientSocket, FIONBIO, ioctlOne );

      self.connection := TSwooshSocketConnection.Create( self.clientSocket, self.sa, config.recvBuffer );
      // start recv loop
      writeln( 'Connected to ' + self.remoteEndPoint.name + ' on ' + self.remoteEndPoint.ip + ' successfully!' );

      self.clientState := self.connection.getState;
    end
    else
    begin
      writeln( 'Unable to connect to ' + self.remoteEndPoint.name + ' socket! Error=' + IntToStr( WSAGetLastError ));
      sleep( 500 );
    end;

  end
  else
  begin
    writeln( 'Unable to initilize socket! Error=' + IntToStr( WSAGetLastError ));
  end;

end;

procedure TSwooshClient.Execute;
var
  tempPacket: TSwooshPacket;
begin

  while self.Terminated = false do
  begin

    case self.clientState of

      Disconnected:
        begin
          self.Connect;
        end;
      Connected:
        begin

             //recieve, and add to recv queue!
          tempPacket := self.connection.readData;

          try
            EnterCriticalSection( self.critsect );

            if ( tempPacket <> nil )
            then
              self.recvPacketQueue.addPacket( tempPacket )
            else
            begin
              // connection was killed?
              if self.connection.getState = Disconnected
              then
              begin
                writeln( self.remoteEndPoint.name + ' (' + self.remoteEndPoint.ip + ') disconnected!' );
                self.clientState := self.connection.getState; // disconnect
                self.connection.Free;
              end
              else
                writeln( 'Nil packet recieved on ' + self.ToString );


            end;
          finally
            LeaveCriticalSection( self.critsect );
          end;

          sleep(1000); //we are non blocking!

        end;

    end;

  end

end;

end.
