unit swooshPWSocketConnection;

interface

uses windows, winsock, classes, serverDecl, swooshSocketConnection, pwEmuPacketTypes, swooshRC4, swooshPacket;

type
  TSwooshPWSocketConnection = class( TSwooshSocketConnection )
  public
    constructor Create( theSocket: TSocket; sockAddr: sockaddr_in; maxRecvBuffer: integer );
    procedure activateEncrypt( key: THashKey );
    procedure activateDecrypt( key: THashKey );
    function sendCryptPacket( thePacket: TInternalSwooshPacket ): byte; overload;
    function sendCryptPacket( thePacket: TSwooshPacket ): byte; overload;
    function readCryptPacket: TInternalSwooshPacket;

  private
    cryptoInfo: TpwLoginCrypto;
    encryptRC4: TRC4Encoder;
    decryptRC4: TRC4Encoder;
    _encrypt  : boolean;
    _decrypt  : boolean;
    //mppc later
    _compress : boolean;
  end;

implementation

constructor TSwooshPWSocketConnection.Create( theSocket: TSocket; sockAddr: sockaddr_in; maxRecvBuffer: integer );
begin
  inherited Create( theSocket, sockAddr, maxRecvBuffer );
  self._encrypt := false;
  self._decrypt := false;
end;

procedure TSwooshPWSocketConnection.activateEncrypt( key: THashKey );
begin
  self.encryptRC4 := TRC4Encoder.Create( key );
  self._encrypt := True;
end;

procedure TSwooshPWSocketConnection.activateDecrypt( key: THashKey );
begin
  self.decryptRC4 := TRC4Encoder.Create( key );
  self._decrypt := True;
end;

function TSwooshPWSocketConnection.sendCryptPacket( thePacket: TInternalSwooshPacket ): byte;
begin
  if self._encrypt
  then
    thePacket.buffer := self.encryptRC4.ProcessArray( thePacket.buffer );

  self.sendPacket( thePacket );
end;

function TSwooshPWSocketConnection.sendCryptPacket( thePacket: TSwooshPacket ): byte;
begin
  if self._encrypt
  then
    thePacket.buffer := self.encryptRC4.ProcessArray( thePacket.buffer );

  self.sendPacket( thePacket );
end;

function TSwooshPWSocketConnection.readCryptPacket: TInternalSwooshPacket;
begin

   result := self.readData;

   if result <> nil then
   begin
     if self._decrypt then
        result.buffer := self.decryptRC4.ProcessArray(result.buffer);
   end;

end;

end.
