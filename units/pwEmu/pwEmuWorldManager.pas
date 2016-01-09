unit pwEmuWorldManager;

interface

uses
  windows, serverDecl, dateUtils, pwEmuPlayerCharacterInventoryManager, pwEmuPlayerCharacterBaseDataManager, pwEmuPlayerCharacterBase, swooshConfigHandler,
  types, System.Classes, System.SysUtils, pwEmuDatabaseHive, pwEmuAccountManager, pwEmuWorldManagerDataExchangeClasses, System.Generics.Collections,
  pwEmuTasksReader, pwEmuTerritoryManager, pwEmuFriendListManager, pwEmuServerConfigManager, pwEmuNpcgenReader, pwEmuDataTypes;

type
  TpwEmuWorldManager = class( TThread )
  public
    constructor Create( config: TbigServerConfig );
    function getSimpleRoleUpdateInfo ( roleID: cardinal ): TSimpleRoleUpdateInfo_26;
    function getAccountInfo ( loginName: AnsiString; requestIP: cardinal ): TpwAccountDetails;
    function getRoleIDFromSlot ( accountID: cardinal; slot: Integer ): cardinal;
    function getRoleList_Re ( roleID: cardinal ): TRolelist_re_53;
    function getRoleList_Re_FF: TRolelist_re_53;
    function getTWMapResponse_353: TMarshallResult;
    function getUnknownRoleInfo ( roleID: cardinal ): TRoleUnknownInfo_08;
    function createRole ( role: TRoleInfo ): Integer;
    function getMarshalledFriendList ( roleID: cardinal ): TMarshallResult;
    function getServerConfigInfo_CE: TMarshallResult;

  protected
    procedure Execute; override;

  private
    _config                  : TbigServerConfig;
    _inventoryManager        : TpwEmuPlayerCharacterInventoryManager;
    _characterBaseDataManager: TpwEmuPlayerCharacterBaseDataManager;
    _accountManager          : TpwEmuAccountManager;
    _tasksMan                : TpwEmuTasksReader;
    _territoryManager        : TpwEmuTerritoryManager;
    _friendListManager       : TpwEmuFriendListManager;
    _serverConfigManager     : TpwEmuServerConfigManager;
    _NpcGenManager           : TpwEmuNpcgenReader;

    // Holds the last database Sync.
    _lastDbSyncTimestamp: Int64;

    // database manager. Manages access to the sqlite.
    _dbHive: TpwEmuDatabaseHive;

    // map configs
    _mapConfigsWorld    : TList< TpwEmuWorldConfig >;
    _mapConfigsInstances: TList< TpwEmuWorldConfig >;
    _mapBaseDirectory   : string;

    // helper methods
    function loadMapConfig: Integer;

  end;

implementation

constructor TpwEmuWorldManager.Create ( config: TbigServerConfig );
var
  ts: cardinal;
begin
  inherited Create( true );
  ts := DateTimeToUnix( now );
  self._config := config;
  self._dbHive := TpwEmuDatabaseHive.Create( self._config );

  self._serverConfigManager := TpwEmuServerConfigManager.Create( 1, ts, ts, ts, ts );

  self._NpcGenManager := TpwEmuNpcgenReader.Create;

  self._NpcGenManager.loadFile( 'G:\145\server\gamed\config\world\npcgen.data' ); // works for G:\145\server\gamed\config\a13 (v5) also

  writeln( 'TpwEmuNpcgenManager._NpcGenManager:: Loaded ' + IntToStr( self._NpcGenManager.nCreatureSets ) + ' creature sets' );

  self._inventoryManager := TpwEmuPlayerCharacterInventoryManager.Create;
  self._characterBaseDataManager := TpwEmuPlayerCharacterBaseDataManager.Create( self._config, self._dbHive ); // gets pointer to db. Needs to be CSed well.
  self._accountManager := TpwEmuAccountManager.Create( self._config, self._dbHive );
  self._territoryManager := TpwEmuTerritoryManager.Create( self._config );
  self._friendListManager := TpwEmuFriendListManager.Create;

  writeln( 'TpwEmuWorldManager:: Loaded ' + IntToStr( self.loadMapConfig ) + ' map configs from ini...' );

  self._lastDbSyncTimestamp := ts; // Don't update at start!

{$REGION 'Tasks test'}

  self._tasksMan := TpwEmuTasksReader.Create( _config );
  // self._tasksMan.loadTasks;

{$ENDREGION}

  self.Resume;
end;

function TpwEmuWorldManager.loadMapConfig: Integer;
var
  sc       : TswooshIniHandler;
  worldMaps: TStrArray;
  wmC      : cardinal;
  i        : Integer;
  mapConfig: TpwEmuWorldConfig;
begin
  self._mapConfigsWorld := TList< TpwEmuWorldConfig >.Create;
  sc := TswooshIniHandler.Create( './configs/pwEmuMaps.ini' );
  worldMaps := sc.readStringArray( 'mapConfig', 'world_servers' );
  wmC := length( worldMaps );

  if ( wmC > 0 )
  then
  begin

    for i := 0 to wmC - 1 do
    begin
      mapConfig := TpwEmuWorldConfig.Create;
      mapConfig.worldTag := sc.readInt( 'map_' + worldMaps[ i ], 'id' );
      mapConfig.minHeight := sc.readFloat( 'map_' + worldMaps[ i ], 'minHeight' );
      mapConfig.maxHeight := sc.readFloat( 'map_' + worldMaps[ i ], 'maxHeight' );
      mapConfig.nSectors := sc.readInt( 'map_' + worldMaps[ i ], 'nSectors' );
      mapConfig.nColumns := sc.readInt( 'map_' + worldMaps[ i ], 'nColumns' );
      mapConfig.nRows := sc.readInt( 'map_' + worldMaps[ i ], 'nRows' );
      mapConfig.subSectionWidth := sc.readInt( 'map_' + worldMaps[ i ], 'subSectionWidth' );
      mapConfig.subSectionHeight := sc.readInt( 'map_' + worldMaps[ i ], 'subSectionHeight' );
      mapConfig.worldFilePath := sc.readString( 'map_' + worldMaps[ i ], 'base_path' );
      self._mapConfigsWorld.Add( mapConfig );
    end;

  end;

  result := wmC;

  sc.Free;

end;

/// <remarks>
/// Returns marshalled friendlist for a given role.
/// </remarks>

function TpwEmuWorldManager.getMarshalledFriendList ( roleID: cardinal ): TMarshallResult;
begin

  if ( self._friendListManager.friendListExists( roleID ))
  then
  begin
    result := self._friendListManager.getFriendList( roleID ).marshall;
  end
  else
  begin
    self._friendListManager.addFriendList( roleID, self._dbHive.getFriendList( roleID ) );
    result := self._friendListManager.getFriendList( roleID ).marshall;
  end;

end;

/// <remarks>
/// Returns info to construct the 0xCE ServerConfigInfo S2C S_00 subpacket. See TServerConfigInfo.
/// </remarks>
function TpwEmuWorldManager.getServerConfigInfo_CE: TMarshallResult;
begin
  result := self._serverConfigManager.marshall;

end;

/// <remarks>
/// Attempts to create a given role. Check result value for info if succeeded.
/// </remarks>
/// <returns>1 = Okay; 2 = name exists; 3 = general fault; 4 = fuck you</returns>

function TpwEmuWorldManager.createRole ( role: TRoleInfo ): Integer;
begin
  // Check if role name already exists.
  if ( self._dbHive.roleNameExists( role.name ) = false )
  then
  begin
    // create

  end
  else
    result := 2;

end;

/// <remarks>
/// Gets the role ID from certain character on certain account. if account and char not loaded, it instructs character manager to do so.
/// This is ised to handle RoleList requests from client.
/// </remarks>

function TpwEmuWorldManager.getRoleIDFromSlot ( accountID: cardinal; slot: Integer ): cardinal;
begin

  // first, check if account ID even exists.
  if ( self._accountManager.accountIDExists( accountID ))
  then
  begin
    // k, so account exists.
    // Let's get the ID of the slot.
    result := self._accountManager.getRoleIDFromSlot( accountID, slot );

  end
  else
    result := 0;

end;

function TpwEmuWorldManager.getTWMapResponse_353: TMarshallResult;
begin
  result := self._territoryManager.marshall;
end;

function TpwEmuWorldManager.getRoleList_Re ( roleID: cardinal ): TRolelist_re_53;
var
  tempPlayerCharacterBase: TpwEmuPlayerCharacterBase;
begin
  // TODO : Risky here, moar chekcs pls
  tempPlayerCharacterBase := self._characterBaseDataManager.getCharacter( roleID );
  if (@tempPlayerCharacterBase.roleID <> nil )
  then
    result := tempPlayerCharacterBase.getRoleListCharacter;
end;

/// <remarks>
/// End of the slot exchange. represents "noChar" slot.
/// </remarks>
function TpwEmuWorldManager.getRoleList_Re_FF: TRolelist_re_53;
begin
  result := TRolelist_re_53.Create( true );

end;

/// <remarks>
/// Retrieves data for bundlehandler - packet
/// </remarks>

function TpwEmuWorldManager.getSimpleRoleUpdateInfo ( roleID: cardinal ): TSimpleRoleUpdateInfo_26;
var
  tempPlayerCharacterBase: TpwEmuPlayerCharacterBase;
begin
  // TODO : Risky here, moar checks pls
  tempPlayerCharacterBase := self._characterBaseDataManager.getCharacter( roleID );
  if (@tempPlayerCharacterBase.roleID <> nil )
  then
    result := tempPlayerCharacterBase.getSimpleRoleUpdateInfo;

end;

function TpwEmuWorldManager.getUnknownRoleInfo ( roleID: cardinal ): TRoleUnknownInfo_08;
var
  tempPlayerCharacterBase: TpwEmuPlayerCharacterBase;
begin
  // TODO : Risky here, moar checks pls
  tempPlayerCharacterBase := self._characterBaseDataManager.getCharacter( roleID );
  if (@tempPlayerCharacterBase.roleID <> nil )
  then
    result := tempPlayerCharacterBase.getRoleUnknownInfo;

end;

/// <remarks>
/// Gets account login details.
/// </remarks>
function TpwEmuWorldManager.getAccountInfo ( loginName: AnsiString; requestIP: cardinal ): TpwAccountDetails;
begin
  result := self._accountManager.getAccountInfo( loginName, requestIP );
end;

procedure TpwEmuWorldManager.Execute;
begin
  // Jobs of this thread :
  // Instruct all subManagers to save every X minutes.
  // Process Incomming requests and queue them appropriately
  // Process world events (counts, mob movement, etc)
  // Manipulate other world related stuff.
  try
    while self.Terminated = false do
    begin
      sleep( 20 ); // temporary!
      // First, let's check save data stuff.

      {

       if ( self._lastDbSyncTimestamp + ( self._config.dbSaveIntervall * 60 ) <= DateTimeToUnix( now ))
       then
       begin
       // Save all Manager data here.
       // _inventoryManager.SyncWithDB;
       // ...
       self._accountManager.syncToDB;
       if self._dbHive.saveData = 101
       then
       begin

       self._lastDbSyncTimestamp := DateTimeToUnix( now );
       writeln( 'TpwEmuWorldManager:: Synced all manager data with db.' );
       end
       else
       writeln( 'TpwEmuWorldManager:: ***Error synchronizing data with db!' );
       end;

      }

      // Check all incoming queues for information, process.

    end;
  except
    on E: Exception do
    begin
      writeln( '***TpwEmuWorldManager : Exception class name = ' + E.ClassName );
      writeln( '***TpwEmuWorldManager : Exception message = ' + E.Message );
    end;
  end;

end;

end.
