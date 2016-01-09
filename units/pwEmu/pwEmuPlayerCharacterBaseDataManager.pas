unit pwEmuPlayerCharacterBaseDataManager;

interface

uses windows, System.Types, System.Generics.Collections, pwEmuPlayerCharacterBase, serverDecl, SQLiteTable3, System.SysUtils, pwEmuDatabaseHive,pwEmuWorldManagerDataExchangeClasses;

type
  TpwEmuPlayerCharacterBaseDataManager = class
  public
    constructor Create ( config: TbigServerConfig; dbMan: TpwEmuDatabaseHive );
    function removeCharacter( roleid: cardinal ): integer;
    function getCharacter ( roleid: cardinal ): TpwEmuPlayerCharacterBase;
    procedure createRole (role : TRoleInfo);

  private
    _config    : TbigServerConfig;
    _characters: TDictionary< cardinal, TpwEmuPlayerCharacterBase >;
    _database  : TpwEmuDatabaseHive;
    function getPlayerCharacterBaseDataFromDB ( roleid: cardinal ): integer;
  end;

implementation

constructor TpwEmuPlayerCharacterBaseDataManager.Create( config: TbigServerConfig; dbMan: TpwEmuDatabaseHive );
begin
  self._config := config;
  self._characters := TDictionary< cardinal, TpwEmuPlayerCharacterBase >.Create;
  self._database := dbMan;

end;

/// <remarks>
/// Creates a role. This does not check if role exists. It also performs checks to see start position, start equip, etc.
/// </remarks>

procedure TpwEmuPlayerCharacterBaseDataManager.createRole (role : TRoleInfo);
begin


 //bla



end;


function TpwEmuPlayerCharacterBaseDataManager.removeCharacter( roleid: cardinal ): integer;
var
  tempCharBase: TpwEmuPlayerCharacterBase;
begin

  if self._characters.ContainsKey( roleid )
  then
    if self._characters.TryGetValue( roleid, tempCharBase )
    then
    begin
      self._characters.Remove( roleid );
      tempCharBase.Free;
      self._characters.TrimExcess;
    end
    else
      result := - 1
  else
    result := - 2;

end;

/// <remarks>
/// Public function for retrieving a character's info.
/// </remarks>

function TpwEmuPlayerCharacterBaseDataManager.getCharacter ( roleid: cardinal ): TpwEmuPlayerCharacterBase;
begin
  // does char exist already in dict?
  if ( self._characters.ContainsKey( roleid ))
  then
    self._characters.TryGetValue( roleid, result )
  else
  begin
    // get from database, then pass to result.
    self.getPlayerCharacterBaseDataFromDB( roleid );
    self._characters.TryGetValue( roleid, result );
  end;

end;

/// <remarks>
/// SHOULD ONLY BE USED AT START. OVERWRITES ALL CURRENT DATA.
/// </remarks>

function TpwEmuPlayerCharacterBaseDataManager.getPlayerCharacterBaseDataFromDB( roleid: cardinal ): integer;
var
  sqltable    : TSQLiteTable;
  tempCharBase: TpwEmuPlayerCharacterBase;
begin

  // delete all previous data.
  self.removeCharacter( roleid );

  tempCharBase := TpwEmuPlayerCharacterBase.Create;

  // Don't check existing data, get it straight from the database.

  if self._database.getFullRoleInfo( roleid, tempCharBase ) = roleid
  then
  begin
    self._characters.Add( roleid, tempCharBase );
    result := roleid;
  end
  else
    result := - 1;

end;

end.
