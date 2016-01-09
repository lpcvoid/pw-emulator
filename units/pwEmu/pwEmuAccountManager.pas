{

 Part of worldmanager. Queries the db for accounts and returns result hashes and shit back. Also fills internal IP info and stuff.

}

unit pwEmuAccountManager;

interface

uses windows, sysutils, types, System.Generics.Collections, pwEmuDatabaseHive, serverDecl;

type
  TpwEmuAccountManager = class
  public
    constructor Create ( config: TbigServerConfig; dbMan: TpwEmuDatabaseHive );
    function getAccountInfo ( loginName: ansiString; requestIP: cardinal ): TpwAccountDetails;
    function updateAccountInfo ( loginName: ansiString; lastIP, lastLogin: cardinal ): integer;
    function syncToDB: integer;
    function accountIDExists ( accountID: cardinal ): boolean;
    function getRoleIDFromSlot ( accountID: cardinal; slot: integer ): cardinal;

  private
    _accounts: TDictionary< ansiString, TpwAccountDetails >;

    // account ID ; Account name
    _accountNames: TDictionary< cardinal, ansiString >;

    // accountID ; roles ID array
    _accountRoles: TDictionary< cardinal, TRawData32 >;
    _dbMan       : TpwEmuDatabaseHive;
  end;

implementation

constructor TpwEmuAccountManager.Create ( config: TbigServerConfig; dbMan: TpwEmuDatabaseHive );
begin
  self._dbMan := dbMan;
  self._accounts := TDictionary< ansiString, TpwAccountDetails >.Create;
  self._accountNames := TDictionary< cardinal, ansiString >.Create;
  self._accountRoles := TDictionary< cardinal, TRawData32 >.Create;
end;

/// <remarks>
/// Get a role ID from a slot from a certain account. Used by RoleList.
/// </remarks>

function TpwEmuAccountManager.getRoleIDFromSlot ( accountID: cardinal; slot: integer ): cardinal;
var
  roles: TRawData32;
begin
  // first, check if data is avaliable in dict.

  // we need to convert the slots also. $FFFFFFFF is first role slot request. We will convert this to 0.  add 1.
  inc( slot );

  if ( self._accountRoles.ContainsKey( accountID ))
  then
    self._accountRoles.TryGetValue( accountID, roles )
  else
  begin
    // request this info from db.
    roles := self._dbMan.getAccountRoles( accountID );
  end;

  if ( Length( roles ) > slot ) and ( Length( roles ) >= 0 )
  then
    result := roles[ slot ]
  else
    result := $FFFFFFFF; // If out of bounds for some reason, send 0.

end;

/// <remarks>
/// Used by the RoleList request to check if the acutually requested account ID really exists.
/// </remarks>

function TpwEmuAccountManager.accountIDExists ( accountID: cardinal ): boolean;
begin
  result := ( self._accountNames.ContainsKey( accountID ));

end;

function TpwEmuAccountManager.getAccountInfo ( loginName: ansiString; requestIP: cardinal ): TpwAccountDetails;
begin
  // already loaded?
  if ( self._accounts.ContainsKey( loginName ))
  then
  begin
    // return already saved stuff.
    self._accounts.TryGetValue( loginName, result );

  end
  else
  begin
    // get from database, and put into local then.
    result := self._dbMan.getAccountInfo( loginName );

    if ( result.accountID > 0 )
    then
    // valid account, add to dictionary!
    begin
      result.lastLoginIP := requestIP;
      self._accounts.Add( loginName, result );
      self._accountNames.Add( result.accountID, loginName );
    end;

  end;

end;

function TpwEmuAccountManager.updateAccountInfo ( loginName: ansiString; lastIP, lastLogin: cardinal ): integer;
var
  tempAcc: TpwAccountDetails;
begin
  // Update it. It must exist at this point, since this is only called on an active and checked account.
  // I am paranoid, let's check anyhoe.

  if ( self._accounts.ContainsKey( loginName ))
  then
  begin
    self._accounts.TryGetValue( loginName, tempAcc );
    tempAcc.lastLogin := lastLogin;
    tempAcc.lastLoginIP := lastIP;
    self._accounts.Remove( loginName );
    self._accounts.Add( loginName, tempAcc );
    result := self._accounts.Items[ loginName ].accountID;
  end
  else
    result := - 1;

end;

/// <remarks>
/// This is called by Worldmanager thread.
/// It saves all data to the database.
/// </remarks>

function TpwEmuAccountManager.syncToDB: integer;
var
  tempAcc: TpwAccountDetails;
begin
  if ( self._accounts.Count > 0 )
  then
  begin
    for tempAcc in self._accounts.Values do
      self._dbMan.putAccountInfo( tempAcc );
  end
  else
    result := 0;
end;

end.
