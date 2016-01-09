unit swooshLogInterface;

interface

uses windows, swooshPacket, System.DateUtils, sysutils, swooshClient,
  serverDecl, classes;

type
  TSwooshLogInterface = class
  public
    constructor create( callerName: string );
    procedure addLogServer( config: TbigServerConfig );
    function report( did, cid, pid, msgType, priority: dword; msg: string; octets: pointer; octetLen: dword ): byte;

  private
    client      : TSwooshClient;
    clientConfig: TbigServerConfig;
    sl          : TStringList;
    callerName  : String;
  end;

implementation

//test svn show
//DUDE

constructor TSwooshLogInterface.create( callerName: string );
begin
  self.sl := TStringList.create;
  self.callerName := callerName;
end;

procedure TSwooshLogInterface.addLogServer( config: TbigServerConfig );
begin
  self.clientConfig := config;
  self.client := TSwooshClient.create(config.remote_logDaemonEndpoint, self.clientConfig );
end;

function TSwooshLogInterface.report( did, cid, pid, msgType, priority: dword; msg: string; octets: pointer; octetLen: dword ): byte;
var
  packet    : TSwooshPacket;
  timeStamp : int64;
  fs        : TFileStream;
  octetArray: array of byte;
  logMessage: String;
begin

  timeStamp := System.DateUtils.DateTimeToUnix( now );

  if (self.client <> nil)
  then
  begin
    packet := TSwooshPacket.create;

    packet.WriteCUInt( $12 );
    packet.WriteInt64( timeStamp );
    packet.WriteWord( did );
    packet.WriteWord( cid );
    packet.WriteWord( pid );
    packet.Writebyte( priority );
    packet.Writebyte( msgType );

    if (( msgType = 0 ) or ( msgType = 2 ))
    then
      packet.WriteANSIString( msg )
    else
      packet.Writebyte( 0 ); // same as CUINT 0

    if (( msgType = 1 ) or ( msgType = 2 ))
    then
      packet.WriteOctets( octets, octetLen )
    else
      packet.Writebyte( 0 );

    result := self.client.sendPacket( packet );

    if  result = 0 then
        begin
        writeln('Failed to send log message to logDaemon! Announcing here.');
        writeln('log message : ' + msg);
        end;

  end
  else
  begin
    // emergency logging into own directory with hardcoded name, omg
    logMessage := '[' + TimeToStr( now ) + '] did=' + IntToStr( did ) + ',cid=' + IntToStr( cid ) + ',pid=' + IntToStr( pid ) + ',priority=' + IntToStr( priority ) + ',octetLen=' + IntToStr( octetLen ) + ',msg=' + msg;
    writeln( logMessage );
    self.sl.Add( logMessage );
    self.sl.SaveToFile( self.callerName + '.txt' );

    if (( msgType = 1 ) or ( msgType = 2 ))
    then
    begin
      SetLength( octetArray, octetLen );
      CopyMemory(@octetArray[ 0 ], octets, octetLen );
      fs := TFileStream.create( IntToStr( timeStamp ) + '_did_' + IntToStr( did ), fmCreate );
      fs.WriteBuffer( octetArray, octetLen );
      fs.Free;
    end;

  end;

end;

end.
