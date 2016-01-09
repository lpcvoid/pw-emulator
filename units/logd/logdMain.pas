unit logdMain;

interface

uses windows, winsock, sysutils, serverDecl, swooshListener, swooshLogInterface,
  swooshDBTypes,
  swooshSocketConnection, classes, swooshServerConnectionManager,
  System.Contnrs, swooshPacket;

type
  TlogdMain = class( TThread )

  public
    constructor create( serverConfig: TServerConfig; did, priority: cardinal );
    function active: boolean;
    function getServerStatus: String;

  private
    wsaData            : TWSAData;
    _did, _priority    : cardinal;
    serverConnectionMan: TswooshConnectionManager;
    listener           : TswooshListener;

    procedure reportStatus( msg: String );

  protected
    procedure Execute; override;
  end;

implementation

constructor TlogdMain.create( serverConfig: TServerConfig; did: cardinal; priority: cardinal );
var
  initRet: NativeInt;
begin
  inherited create( true );

  // self.FreeOnTerminate := true;

  self._did := did;
  self._priority := priority;

  self.serverConnectionMan := TswooshConnectionManager.create( 64 );

  // self.logServiceInterface.addLogServer(clientConfig);
  self.reportStatus( 'Starting create!' );

  self.listener := TswooshListener.create( serverConfig );

  if self.listener.getState <> Disconnected
  then
  begin
    self.reportStatus( 'Winsock successfully loaded...' );

    // continue here
    self.Resume; // thread which checks queue and assigns new handlers
    self.listener.startListen;
    // tell server to start listening for connections to put in queue

  end
  else
  begin
    FreeAndNil( self.listener );
    self.reportStatus( 'Winsock failed! error=' + inttoStr( initRet ));
  end;

end;

function TlogdMain.active: boolean;
begin

  result := ( self.listener.getState = connected );

end;

function TlogdMain.getServerStatus: String;
var
  serverStatusString: String;
begin
  serverStatusString := self.serverConnectionMan.getBundleHandlerStatus;

  result := serverStatusString;
end;

procedure TlogdMain.reportStatus( msg: String );
begin
  writeln( msg );
end;

procedure TlogdMain.Execute;
var
  tempSocket        : TSwooshSocketConnection;
  tempInternalPacket: TInternalSwooshpacket;

  // logd data. No extra class, QQ moar.
  timestamp        : Int64;
  did, cid, pid    : word;
  priority, msgType: byte;

  textMessage: AnsiString;
  octetLen : Cardinal;
  octets     : TRawData;

  logMessage: string;

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
          self.reportStatus( 'New connection! ip=' + tempSocket.getIP + ':' + inttoStr( tempSocket.getPort ));
          // pass to a new handler
          self.serverConnectionMan.addClient( tempSocket );
        end;
      end;

      // main query responder and processor

      if ( serverConnectionMan.bundleHasIncomingPackets )
      then
      begin
        // new packet in some bundle connection!

        tempInternalPacket := serverConnectionMan.bundleGetIncomingPacket;

        writeln( 'New packet! bid=' + inttoStr( tempInternalPacket.bundleID ) + ' ,connection=' + inttoStr( tempInternalPacket.connectionID ));

        case tempInternalPacket.getPacketType of
          $12:
            begin
              writeln( 'log packet recieved.' );
              // only one fucking packet will ever be handled by this daemon. Nobody cares.

              tempInternalPacket.ReadCUInt;
              timestamp := tempInternalPacket.ReadInt64;
              did := tempInternalPacket.ReadWord;
              cid := tempInternalPacket.ReadWord;
              pid := tempInternalPacket.ReadWord;
              priority := tempInternalPacket.ReadByte;
              msgType := tempInternalPacket.ReadByte;

              if (( msgType = 0 ) or ( msgType = 2 ))
              then
                textMessage := tempInternalPacket.ReadANSIString
              else
                tempInternalPacket.ReadByte( ); // same as CUINT 0

              if (( msgType = 1 ) or ( msgType = 2 ))
              then
              begin
                octetLen := tempInternalPacket.ReadCUInt;
                octets :=  tempInternalPacket.ReadRawData( octetLen );
              end
              else
                tempInternalPacket.Writebyte( 0 );

              logMessage := '[' + TimeToStr( now ) + '] did=' + inttoStr( did ) + ',cid=' + inttoStr( cid ) + ',pid=' + inttoStr( pid ) + ',priority=' + inttoStr( priority ) + ',octetLen=' + inttoStr( octetLen ) + ',msg=' + textMessage;



              self.reportStatus(logMessage);
            end;

        end;

        // dispose
        tempInternalPacket.Free;

      end
      else
        sleep( 1 ); // big factor!

    except
      writeln( 'TmainDBServer.Execute() Exception!' );
    end;

  end;

end;

end.
