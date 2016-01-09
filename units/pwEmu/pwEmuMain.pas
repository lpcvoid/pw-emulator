unit pwEmuMain;

interface

uses windows, winsock, sysutils, serverDecl, swooshListener, swooshLogInterface,
  System.Types,
  swooshSocketConnection, classes, pwEmuServerConnectionManager,pwEmuWorldManager;

type
  TmainpwEmu = class( TThread )

  public
    constructor create( config: TbigServerConfig; did, priority: cardinal );
    function active: boolean;
    function getServerStatus: String;

  private
    wsaData            : TWSAData;
    _did, _priority    : cardinal;
    logServiceInterface: TSwooshLogInterface;
    serverConnectionMan: TpwEmuServerConnectionManager;
    listener           : TswooshListener;
    worldManager       : TpwEmuWorldManager;


    procedure reportStatus( msg: String; callingMethod: string; status: byte; ioMethod: byte );

  protected
    procedure Execute; override;
  end;

implementation

constructor TmainpwEmu.create( config: TbigServerConfig; did: cardinal; priority: cardinal );
var
  initRet: NativeInt;
begin
  inherited create( true );

  // self.FreeOnTerminate := true;

  self._did := did;
  self._priority := priority;

  self.worldManager := TpwEmuWorldManager.create( config );

  self.serverConnectionMan := TpwEmuServerConnectionManager.create( 64, config, self.worldManager );

  self.logServiceInterface := TSwooshLogInterface.create( self.UnitName );

  // self.logServiceInterface.addLogServer(config);

  self.reportStatus( 'Starting create!', 'create', 0, 0 );

  self.listener := TswooshListener.create( config.listenEndpoint, config );

  if self.listener.getState <> Disconnected
  then
  begin
    self.reportStatus( 'Winsock successfully loaded...', 'create', 0, 0 );

    // continue here
    self.Resume; // thread which checks queue and assigns new handlers
    self.listener.startListen;
    // tell server to start listening for connections to put in queue

  end
  else
  begin
    FreeAndNil( self.listener );
    self.reportStatus( 'Winsock failed! error=' + IntToStr( initRet ), 'create', 1, 0 );
  end;

end;

function TmainpwEmu.active: boolean;
begin

  result := ( self.listener.getState = connected );

end;

function TmainpwEmu.getServerStatus: String;
var
  serverStatusString: String;
begin
  serverStatusString := self.serverConnectionMan.getBundleHandlerStatus;

  result := serverStatusString;
end;

procedure TmainpwEmu.reportStatus( msg: String; callingMethod: string; status: byte; ioMethod: byte );
begin
  {
   status : 0 normal, 1 error, 2 critical

  }

  self.logServiceInterface.report( self._did, 0, 0, 0, status, callingMethod + '::' + msg, nil, 0 );

end;

/// <remarks>
/// This only gets connections from listener, and adds to the connectionmanager.
/// </remarks>

procedure TmainpwEmu.Execute;
var
  tempSocket: TSwooshSocketConnection;
  bid       : integer; // bundle ID for sending the challenge packet to.
begin
  while (( self.listener.getState <> Disconnected ) and ( self.Terminated = false )) do
  begin
    try

      if ( self.listener.connectionQueue.itemInQueue )
      then
      begin
        tempSocket := self.listener.connectionQueue.getConnection;
        if ( tempSocket <> nil )
        then
        begin
          self.reportStatus( 'New connection! ip=' + tempSocket.getIP + ':' + IntToStr( tempSocket.getPort ), 'create', 0, 0 );
          // pass to a new handler

          bid := self.serverConnectionMan.addClient( tempSocket );

        end;
      end
      else
      sleep(10);



    except
      writeln( 'TmainpwEmu.Execute() Exception!' );
    end;

  end;

end;

end.
