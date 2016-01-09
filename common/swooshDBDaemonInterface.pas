unit swooshDBDaemonInterface;

interface

uses windows, swooshClient, serverDecl, swooshPacket, classes;

type
  TSwooshDBInterface = class
  public
    constructor Create(config: TbigServerConfig);
    function CreateDB(dbName: string): integer;
    function CreateTable(dbName,tableName : string) : integer;
    procedure ShutdownDB(reason,Key : string; saveData : boolean);
    function GetDatabases: TStringList;
    function GetTables(dbName : string): TStringList;
    function sendData(dbName,tableName : String;dataType : byte;id : cardinal;idString : AnsiString;data : pointer; dataLen : cardinal) : integer;
    function connectionState : TSocketState;
  private
    client: TSwooshClient;
    config: TbigServerConfig;
  end;

implementation

constructor TSwooshDBInterface.Create(config: TbigServerConfig);
begin
  self.config := config;
  self.client := TSwooshClient.Create(self.config.remote_dbDaemonEndpoint,self.config);
end;

function TSwooshDBInterface.connectionState : TSocketState;
begin
  result := self.client.getConnectionState;
end;

function TSwooshDBInterface.CreateDB(dbName: string): integer;
var
  packet: TSwooshPacket;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($26);
  packet.WriteANSIString(dbName);
  self.client.sendPacket(packet);

end;



procedure TSwooshDBInterface.ShutdownDB(reason,Key : string; saveData : boolean);
var
  packet: TSwooshPacket;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($22);
  packet.Writebyte(byte(savedata));
  packet.WriteANSIString(reason);
  packet.WriteANSIString(Key);
  self.client.sendPacket(packet);
end;


function TSwooshDBInterface.CreateTable(dbName,tableName : string) : integer;
var
  packet: TSwooshPacket;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($20);
  packet.WriteANSIString(dbName);
  packet.WriteANSIString(tableName);
  self.client.sendPacket(packet);
end;


function TSwooshDBInterface.GetDatabases: TStringList;
var
  packet: TSwooshPacket;
  I: integer;
  c: cardinal;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($24);
  packet.WriteDWORD($FFFF);

  self.client.sendPacket(packet);

  sleep(50); // hack, wait for response

  packet := self.client.recvPacket;

  packet.ReadCUInt;
  c := packet.ReadCUInt;

  if (c > 0) then
  begin
    result := TStringList.Create;
    for I := 0 to c - 1 do
      result.Add(packet.ReadAnsiString);
  end;

  packet.Free;

end;

function TSwooshDBInterface.GetTables(dbName : string): TStringList;
var
  packet: TSwooshPacket;
  I: integer;
  c: cardinal;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($28);
  packet.WriteANSIString(dbName);

  self.client.sendPacket(packet);

  sleep(50); // hack, wait for response

  packet := self.client.recvPacket;

  packet.ReadCUInt;
  c := packet.ReadCUInt;

  if (c > 0) then
  begin
    result := TStringList.Create;
    result.Clear;
    for I := 0 to c - 1 do
      result.Add(packet.ReadAnsiString);
  end;

  packet.Free;
end;

function TSwooshDBInterface.sendData(dbName,tableName : String;dataType : byte;id : cardinal;idString : AnsiString;data : pointer; dataLen : cardinal) : integer;
var
  packet: TSwooshPacket;
  I: integer;
  c: cardinal;
begin
  packet := TSwooshPacket.Create;
  packet.WriteCUInt($30);
  packet.WriteANSIString(dbName);
  packet.WriteANSIString(tableName);
  packet.Writebyte(dataType);

  if (dataType = 0) or (dataType = 2) then
  packet.WriteDWORD(id)
  else
  begin
    packet.WriteANSIString(idString);
  end;

  packet.WriteCUInt(dataLen);
  packet.WriteOctets(data,dataLen);
  result := self.client.sendPacket(packet);
end;

end.
