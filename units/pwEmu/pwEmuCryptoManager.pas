unit pwEmuCryptoManager;

{

 This class maintains a list of TRC4Encoder classes which in turn maintain the keys and shit for each client connection ID.
 The client connection ID is the socket ID.
 After the auth handshake shit, the pwEmuMain calls this call's adders to add a new pair of de/encrypters.
 When needed, it can retrieve them again to de/encrypt packets for a certain connection ID.

}


interface

uses windows, swooshPacket, swooshRC4, classes, serverDecl, winsock, System.Generics.Collections;

// type TIntegerList = TList<NativeInt>;

type
  TpwEmuCryptoManager = class
    constructor Create( );
    destructor Destroy; override;
    procedure addEncryptor( cid: TSocket; key: THashKey );
    procedure addDecryptor( cid: TSocket; key: THashKey );

    procedure deleteEncryptor( cid: TSocket );
    procedure deleteDecryptor( cid: TSocket );

    Function decryptPacket( thePacket: TInternalSwooshPacket ): Boolean;
    Function encryptPacket( thePacket: TInternalSwooshPacket ): Boolean;

    function needsDecrypt ( cid: integer ): Boolean;
    function needsEncrypt ( cid: integer ): Boolean;

  private
    _encList: TDictionary< integer, TRC4Encoder >;
    _decList: TDictionary< integer, TRC4Encoder >;

  end;

implementation

constructor TpwEmuCryptoManager.Create( );
begin
  self._encList := TDictionary< integer, TRC4Encoder >.Create;
  self._decList := TDictionary< integer, TRC4Encoder >.Create;
end;

destructor TpwEmuCryptoManager.Destroy;
var
  i: integer;
begin
  if self._decList.Count > 0
  then
    for i := 0 to self._decList.Count - 1 do
      self._decList.Items[ i ].Free;

  if self._encList.Count > 0
  then
    for i := 0 to self._encList.Count - 1 do
      self._encList.Items[ i ].Free;

  self._encList.Free;
  self._decList.Free;

  inherited;

end;

procedure TpwEmuCryptoManager.addEncryptor( cid: TSocket; key: THashKey );
begin
  if cid <> INVALID_SOCKET
  then
    self._encList.Add( cid, TRC4Encoder.Create( key ));
end;

procedure TpwEmuCryptoManager.addDecryptor( cid: TSocket; key: THashKey );
begin
  if cid <> INVALID_SOCKET
  then
    self._decList.Add( cid, TRC4Encoder.Create( key ));
end;


function TpwEmuCryptoManager.needsDecrypt (cid : integer) : Boolean;
begin
  result := self._decList.ContainsKey(cid);
end;

function TpwEmuCryptoManager.needsEncrypt (cid : integer) : Boolean;
begin
  result := self._encList.ContainsKey(cid);
end;

procedure TpwEmuCryptoManager.deleteEncryptor( cid: TSocket );
var
  tempCrypto: TRC4Encoder;
begin
  if ( self._encList.ContainsKey( cid ))
  then
  begin
    if ( self._encList.TryGetValue( cid, tempCrypto ))
    then
      tempCrypto.Free;
    self._encList.Remove( cid );
    self._encList.TrimExcess;
  end;
end;

procedure TpwEmuCryptoManager.deleteDecryptor( cid: TSocket );
var
  tempCrypto: TRC4Encoder;
begin
  if ( self._decList.ContainsKey( cid ))
  then
  begin
    if ( self._decList.TryGetValue( cid, tempCrypto ))
    then
      tempCrypto.Free;
    self._decList.Remove( cid );
    self._decList.TrimExcess;
  end;
end;

Function TpwEmuCryptoManager.decryptPacket( thePacket: TInternalSwooshPacket ): Boolean;
var
  tempCrypto: TRC4Encoder;
begin
  result := false;
  if self._decList.TryGetValue( thePacket.connectionID, tempCrypto )
  then
  begin
    thePacket.buffer := tempCrypto.ProcessArray( thePacket.buffer );
    result := true;
  end;
end;

Function TpwEmuCryptoManager.encryptPacket( thePacket: TInternalSwooshPacket ): Boolean;
var
  tempCrypto: TRC4Encoder;
begin
  result := false;
  if self._encList.TryGetValue( thePacket.connectionID, tempCrypto )
  then
  begin
    thePacket.buffer := tempCrypto.ProcessArray( thePacket.buffer );
    result := true;
  end;

end;

end.
