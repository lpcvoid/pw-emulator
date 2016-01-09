unit pwEmuDatabaseHive;

interface

uses windows, types, System.SysUtils, swooshDatabaseHive, serverDecl,
  pwEmuPlayerCharacterBase, SQLiteTable3, swooshOctetConverter, pwEmuDataTypes, pwEmuItemBase, pwEmuFriendList;

type
  TpwEmuDatabaseHive = class( TswooshDatabaseHive )
  public
    constructor Create( config: TbigServerConfig );
    function getFullRoleInfo ( roleid: cardinal; roleBase: TpwEmuPlayerCharacterBase ): integer;
    function getAccountInfo ( loginName: AnsiString ): TpwAccountDetails;
    function putAccountInfo ( accInfo: TpwAccountDetails ): integer;
    function getAccountRoles ( accountID: cardinal ): TRawData32;
    function roleNameExists ( role_name: string ): boolean;
    procedure putRole ( role: TpwEmuPlayerCharacterBase );
    function getFriendList ( roleid: cardinal ): TpwEmuFriendList;

  private
    _critsect    : TRTLCriticalSection;
    _swooshOctets: TswooshOctetConverter;
    // helper functions. Slow, avoid usage.
    function getRoleName ( roleid: cardinal ): WideString;
    function getRoleJob ( roleid: cardinal ): byte;
  end;

implementation

constructor TpwEmuDatabaseHive.Create( config: TbigServerConfig );
begin
  inherited Create( config );
  InitializeCriticalSection( self._critsect );
  self._swooshOctets := TswooshOctetConverter.Create;

end;

function TpwEmuDatabaseHive.getRoleName ( roleid: cardinal ): WideString;
var
  sqltable: TSQLiteTable;
begin
  sqltable := self.sqlitedb_memory.GetTable( 'SELECT name FROM "main"."roleBaseInfo" WHERE roleid = ' + IntToStr( roleid ));
  result := '';
  if ( sqltable.Count > 0 )
  then
    result := sqltable.FieldAsString( sqltable.FieldIndex[ 'name' ]);

  sqltable.Free;
end;

/// <remarks>
/// Job is actually not the database job, but the thing wanmei should have done. DBJob + DBRace.
/// </remarks>
function TpwEmuDatabaseHive.getRoleJob ( roleid: cardinal ): byte;
var
  sqltable: TSQLiteTable;
begin
  sqltable := self.sqlitedb_memory.GetTable( 'SELECT job,race FROM "main"."roleBaseInfo" WHERE roleid = ' + IntToStr( roleid ));
  result := 0;
  if ( sqltable.Count > 0 )
  then
    result := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'job' ]) + sqltable.FieldAsInteger( sqltable.FieldIndex[ 'race' ]);

  sqltable.Free;
end;

function TpwEmuDatabaseHive.getFriendList ( roleid: cardinal ): TpwEmuFriendList;
var
  sqltable  : TSQLiteTable;
  tempFriend: TpwEmuFriend;
  tempGroup : TpwEmuFriendGroup;
  // flagged to true in case any friend has group_id <> 0
  needsGroup: boolean;
begin
  result := TpwEmuFriendList.Create( roleid );
  needsGroup := false;
  sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."friendLists" WHERE roleid = ' + IntToStr( roleid ));

  if ( sqltable.Count > 0 )
  then
  begin
    while sqltable.EOF = false do
    begin
      tempFriend := TpwEmuFriend.Create;
      tempFriend.roleid := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'friend_roleid' ]);
      tempFriend.job := self.getRoleJob( roleid );
      tempFriend.groupID := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'group_id' ]);

      needsGroup := ( tempFriend.groupID <> 0 );

      tempFriend.charName := self.getRoleName( roleid );
      result.addFriend( tempFriend );
      sqltable.Next;
    end;

  end;

  sqltable.Free;

  // Now groups

  if ( needsGroup )
  then
  begin
    // k, the ass has groups...ugh
    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."friendGroups" WHERE roleid = ' + IntToStr( roleid ));

    if ( sqltable.Count > 0 )
    then
    begin
      while sqltable.EOF = false do
      begin
        tempGroup := TpwEmuFriendGroup.Create;
        tempGroup.groupID := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'group_id' ]);
        tempGroup.groupName := sqltable.FieldAsString( sqltable.FieldIndex[ 'group_name' ]);
        result.addGroup( tempGroup );
        sqltable.Next;
      end;

    end;

    sqltable.Free;
  end;

end;

procedure TpwEmuDatabaseHive.putRole ( role: TpwEmuPlayerCharacterBase );
var
  istr: string;
begin

  role.Name := self.cleanParameter( role.Name );

  istr := 'INSERT INTO "main"."roleBaseInfo" ("roleid","name","job","race","gender","level","cultivation","exp","spirit","base_hp","base_mp","skill_points","vit","mag","str","dex","reputation","order","chi_max")';
  istr := istr + ' VALUES (';
  istr := istr + IntToStr( role.roleid ) + ',';
  istr := istr + '"' + role.Name + '",';
  istr := istr + IntToStr( role.job ) + ',';
  istr := istr + IntToStr( role.race ) + ',';
  istr := istr + IntToStr( role.Sex ) + ',';
  istr := istr + IntToStr( role.level ) + ',';
  istr := istr + IntToStr( role.Cultivation ) + ',';
  istr := istr + IntToStr( 0 ) + ','; // exp
  istr := istr + IntToStr( 0 ) + ','; // sp
  istr := istr + IntToStr( role.HPBase ) + ',';
  istr := istr + IntToStr( role.MPBase ) + ',';
  istr := istr + IntToStr( role.Skillpoints ) + ',';
  istr := istr + IntToStr( role.Vit ) + ',';
  istr := istr + IntToStr( role.mag ) + ',';
  istr := istr + IntToStr( role.str ) + ',';
  istr := istr + IntToStr( role.dex ) + ',';
  istr := istr + IntToStr( role.Reputation ) + ',';
  istr := istr + IntToStr( role.order ) + ',';
  istr := istr + IntToStr( role.maxChi );
  self.sqlitedb_memory.ExecSQL( istr );
end;

function TpwEmuDatabaseHive.roleNameExists ( role_name: string ): boolean;
var
  sqltable: TSQLiteTable;
begin
  try
    EnterCriticalSection( self._critsect );

    role_name := self.cleanParameter( role_name );

    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."roleBaseInfo" WHERE name = "' + role_name + '"' );

    result := NOT sqltable.EOF;

  finally
    LeaveCriticalSection( self._critsect );
  end;
end;

function TpwEmuDatabaseHive.getFullRoleInfo ( roleid: cardinal; roleBase: TpwEmuPlayerCharacterBase ): integer;
var
  sqltable  : TSQLiteTable;
  temps     : AnsiString;
  tempOctets: TOctets;
  tempItem  : TpwEmuItembase;
  i         : integer;
begin
  try
    EnterCriticalSection( self._critsect );
    // get db shit
    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."roleBaseInfo" WHERE roleid = ' + IntToStr( roleid ));

    if sqltable.Count > 0
    then
    begin

      // roleBaseInfo table
      roleBase.roleid := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'roleid' ]);
      roleBase.Name := sqltable.FieldAsString( sqltable.FieldIndex[ 'name' ]);
      roleBase.job := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'job' ]);
      roleBase.race := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'race' ]);
      roleBase.Sex := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'gender' ]);
      roleBase.level := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'level' ]);
      roleBase.Cultivation := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'cultivation' ]);
      roleBase.Exp := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'exp' ]);
      roleBase.Spirit := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'spirit' ]);
      roleBase.HPBase := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'base_hp' ]);
      roleBase.MPBase := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'base_mp' ]);
      roleBase.Skillpoints := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'skill_points' ]);
      roleBase.Vit := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'vit' ]);
      roleBase.mag := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'mag' ]);
      roleBase.str := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'str' ]);
      roleBase.dex := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'dex' ]);
      roleBase.Reputation := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'reputation' ]);
      roleBase.order := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'order' ]);
      roleBase.maxChi := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'chi_max' ]);

    end
    else
      result := - 1;

    sqltable.Free;

    // rolePosition table
    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."rolePosition" WHERE roleid = ' + IntToStr( roleid ));

    if sqltable.Count > 0
    then
    begin

      roleBase.Position := Tpoint3D.Create( sqltable.FieldAsDouble( sqltable.FieldIndex[ 'x' ]), sqltable.FieldAsDouble( sqltable.FieldIndex[ 'Y' ]),
          sqltable.FieldAsDouble( sqltable.FieldIndex[ 'Z' ]) );
      roleBase.MapID := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'world_id' ]);

    end;

    sqltable.Free;

    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."roleCustomData" WHERE roleid = ' + IntToStr( roleid ));

    if sqltable.Count > 0
    then
    begin
      temps := sqltable.FieldAsString( sqltable.FieldIndex[ 'custom_data' ]);

      tempOctets.octets := self._swooshOctets.stringToOctets( temps );
      tempOctets.octetLen := ( Length( temps ) div 2 );

      roleBase.updateCustom_data( tempOctets.octets, tempOctets.octetLen );

    end;

    sqltable.Free;

    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."roleEquipment" WHERE roleid = ' + IntToStr( roleid ));

    if sqltable.Count > 0
    then
    begin
      // roleInfo.equip.

      for i := 0 to sqltable.Count - 1 do
      begin
        tempItem := TpwEmuItembase.Create;
        tempItem.id := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'itemid' ]);
        tempItem.Slot := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'slot' ]);
        tempItem.Count := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'count' ]);
        tempItem.maxCount := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'max_count' ]);

        temps := sqltable.FieldAsString( sqltable.FieldIndex[ 'octets' ]);
        tempOctets.octets := self._swooshOctets.stringToOctets( temps );
        tempOctets.octetLen := ( Length( temps ) div 2 );
        tempItem.setOctets( tempOctets );

        tempItem.Proctype := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'proctype' ]);
        tempItem.expireDate := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'expire_date' ]);
        tempItem.Mask := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'mask' ]);

        roleBase.equip.addEquipItem( tempItem );

        sqltable.Next;

      end;
    end;

    sqltable.Free;

    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."accountRoles" WHERE roleid = ' + IntToStr( roleid ));

    if sqltable.Count > 0
    then
    begin
      // just for account ID.
      roleBase.accountID := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'account_id' ]);
      roleBase.status := byte( sqltable.FieldAsInteger( sqltable.FieldIndex[ 'status' ]));
      roleBase.deleteTime := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'delete_time' ]);
      roleBase.createTime := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'create_time' ]);
      roleBase.lastLoginTime := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'lastlogin_time' ]);

    end;

    // success!
    result := roleBase.roleid;

  finally

    LeaveCriticalSection( self._critsect );
  end;
end;

function TpwEmuDatabaseHive.getAccountRoles ( accountID: cardinal ): TRawData32;
var
  sqltable: TSQLiteTable;
  i       : integer;
begin
  try
    EnterCriticalSection( self._critsect );
    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."accountRoles" WHERE account_id = ' + IntToStr( accountID ));

    if sqltable.Count > 0
    then
    begin
      setlength( result, sqltable.Count );
      for i := 0 to sqltable.Count - 1 do
      begin
        result[ i ] := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'roleid' ]);
        sqltable.Next;
      end;

    end
    else
      setlength( result, 0 );

  finally

    LeaveCriticalSection( self._critsect );
  end;
end;

function TpwEmuDatabaseHive.getAccountInfo ( loginName: AnsiString ): TpwAccountDetails;
var
  sqltable: TSQLiteTable;
begin
  try
    EnterCriticalSection( self._critsect );
    // get db shit

    loginName := self.cleanParameter( loginName );

    sqltable := self.sqlitedb_memory.GetTable( 'SELECT * FROM "main"."accounts" WHERE login_name = "' + loginName + '"' );

    if sqltable.Count > 0
    then
    begin
      result.accountID := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'account_id' ]);
      result.lastLogin := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'last_login' ]);
      result.lastLoginIP := sqltable.FieldAsInteger( sqltable.FieldIndex[ 'last_login_ip' ]);
      result.loginName := loginName;
      result.loginHash := sqltable.FieldAsString( sqltable.FieldIndex[ 'hash' ]);
    end
    else
      result.accountID := 0;

  finally

    LeaveCriticalSection( self._critsect );
  end;
end;

function TpwEmuDatabaseHive.putAccountInfo ( accInfo: TpwAccountDetails ): integer;
begin
  try
    EnterCriticalSection( self._critsect );

    accInfo.loginName := self.cleanParameter( accInfo.loginName );

    self.sqlitedb_memory.ExecSQL( 'DELETE FROM "main"."accounts" WHERE login_name = "' + accInfo.loginName + '"' );

    // now insert new.

    self.sqlitedb_memory.ExecSQL( 'INSERT INTO "main"."accounts" VALUES (' + IntToStr( accInfo.accountID ) + ',"' + accInfo.loginName + '","' +
        accInfo.loginHash + '",' + IntToStr( accInfo.lastLogin ) + ',' + IntToStr( accInfo.lastLoginIP ) + ')' );

    result := accInfo.accountID;

  finally

    LeaveCriticalSection( self._critsect );
  end;
end;

end.
