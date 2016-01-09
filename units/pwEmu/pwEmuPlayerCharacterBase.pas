{

 This class represents one live Character in the world.
 It is the base class, and can be inherited by other classes to extend it.

}

unit pwEmuPlayerCharacterBase;

interface

uses windows, system.Types, system.Classes, serverDecl, pwEmuDataTypes, pwEmuWorldManagerDataExchangeClasses, pwEmuPlayerCharacterEquipment;

type
  TCharacterBaseState = ( Idle, Dead, Gathering, Combat, Casting, NormalAttack, Swimming, Riding, Flying, Catshop, Trading, NPCTalk, InstanceEntery );

type
  TpwEmuPlayerCharacterBase = class

  private

    _name       : WideString;
    _sex        : byte;
    _race       : byte;
    _job        : byte;
    _charID     : Cardinal;
    _hp         : Cardinal;
    _mp         : Cardinal;
    _hpBase     : Cardinal;
    _mpBase     : Cardinal;
    _hpMax      : Cardinal;
    _mpMax      : Cardinal;
    _position   : TPoint3D;
    _mapSector  : Cardinal;
    _mapID      : Cardinal;
    _spirit     : Cardinal;
    _exp        : Cardinal;
    _reputation : Cardinal;
    _cultivation: Cardinal;
    _factionID  : Cardinal;
    _factionRank: byte;
    _order      : Cardinal;
    _spouse     : Cardinal; // marriage partner

    // stats
    _skillPoints   : Cardinal;
    _vit           : Cardinal;
    _str           : Cardinal;
    _mag           : Cardinal;
    _dex           : Cardinal;
    _statPointsFree: Cardinal;

    // attributes

    _phyAttackMin: Cardinal;
    _phyAttackMax: Cardinal;
    _magAttackMin: Cardinal;
    _magAttackMax: Cardinal;
    _critPercent : Cardinal;
    _attackRate  : single;
    _accuracy    : Cardinal;
    _evasion     : Cardinal;
    _speed       : single;
    _attackLevel : Cardinal;
    _rageDamage  : Cardinal; // crit strike damage, normally 200%
    _stealthLevel: Cardinal;
    _slayingLevel: Cardinal; // damage to non player target increase in %

    _pDef              : Cardinal;
    _mDef              : Cardinal;
    _metalDef          : Cardinal;
    _woodDef           : Cardinal;
    _waterDef          : Cardinal;
    _fireDef           : Cardinal;
    _earthDef          : Cardinal;
    _defLevel          : Cardinal;
    _soulForce         : Cardinal; // seeker
    _stealthDetectLevel: Cardinal;
    _wardingLevel      : Cardinal; // attack reduce by non player same level enemys in %

    _baseState : TCharacterBaseState;
    _Level     : Cardinal;
    FcurrentChi: Cardinal;
    FmaxChi    : Cardinal;
    FHPBase    : Cardinal;
    FMPBase    : Cardinal;
    custom_data: TOctets;
    FaccountID : Cardinal;

    FcreateTime: Cardinal;

    Fequip         : TpwEmuPlayerCharacterEquipment;
    FlastLoginTime : Cardinal;
    Fcustom_status : TOctets;
    FcharacterMode : TOctets;
    Freferrer_role : Cardinal;
    Fcash_add      : Cardinal;
    FdeleteTime    : Cardinal;
    Fstatus        : byte;
    FcharacterAngle: byte;
    FinFaction     : byte;

  public
    constructor Create;
    procedure updatePosition ( newPos: TPoint3D );
    procedure damageChar( damage: Cardinal );
    function isAlive: Boolean;
    function isDead: Boolean;
    procedure updateCustom_data( octets: TRawData; octetLen: Cardinal );
    function getRoleListCharacter: TRolelist_re_53;
    function getSimpleRoleUpdateInfo: TSimpleRoleUpdateInfo_26;
    function getRoleUnknownInfo: TRoleUnknownInfo_08;
    procedure fillRoleInfo ( role: TRoleInfo );

    property Position: TPoint3D read _position write _position;
    property MapSector: Cardinal read _mapSector write _mapSector;
    property MapID: Cardinal read _mapID write _mapID;
    property equip: TpwEmuPlayerCharacterEquipment read Fequip write Fequip;

    property accountID: Cardinal read FaccountID write FaccountID;
    property Name: WideString read _name write _name;
    property roleid: Cardinal read _charID write _charID;
    property Sex: byte read _sex write _sex;
    property Race: byte read _race write _race;
    property Job: byte read _job write _job;
    property MP: Cardinal read _mp write _mp;
    property HP: Cardinal read _hp write _hp;
    property HPBase: Cardinal read FHPBase write FHPBase;
    property MPBase: Cardinal read FMPBase write FMPBase;
    property HpMax: Cardinal read _hpMax write _hpMax;
    property MpMax: Cardinal read _mpMax write _mpMax;
    property Spirit: Cardinal read _spirit write _spirit;
    property Exp: Cardinal read _exp write _exp;
    property Reputation: Cardinal read _reputation write _reputation;
    property Cultivation: Cardinal read _cultivation write _cultivation;
    property FactionID: Cardinal read _factionID write _factionID;
    property FactionRank: byte read _factionRank write _factionRank;
    property Order: Cardinal read _order write _order;
    property Spouse: Cardinal read _spouse write _spouse;
    property Level: Cardinal read _Level write _Level;
    property currentChi: Cardinal read FcurrentChi write FcurrentChi;
    property maxChi: Cardinal read FmaxChi write FmaxChi;

    property Skillpoints: Cardinal read _skillPoints write _skillPoints;
    property Vit: Cardinal read _vit write _vit;
    property Str: Cardinal read _str write _str;
    property Mag: Cardinal read _mag write _mag;
    property Dex: Cardinal read _dex write _dex;

    property PhyAttackMin: Cardinal read _phyAttackMin write _phyAttackMin;
    property PhyAttackMax: Cardinal read _phyAttackMax write _phyAttackMax;
    property MagAttackMin: Cardinal read _magAttackMin write _magAttackMin;
    property MagAttackMax: Cardinal read _magAttackMax write _magAttackMax;
    property CritPercent: Cardinal read _critPercent write _critPercent;
    property AttackRate: single read _attackRate write _attackRate;
    property Accuracy: Cardinal read _accuracy write _accuracy;
    property Evasion: Cardinal read _evasion write _evasion;
    property Speed: single read _speed write _speed;
    property AttackLevel: Cardinal read _attackLevel write _attackLevel;
    property RageDamage: Cardinal read _rageDamage write _rageDamage;
    property SlayingLevel: Cardinal read _slayingLevel write _slayingLevel;

    property PDef: Cardinal read _pDef write _pDef;
    property MDef: Cardinal read _mDef write _mDef;
    property MetalDef: Cardinal read _metalDef write _metalDef;
    property WoodDef: Cardinal read _woodDef write _woodDef;
    property WaterDef: Cardinal read _waterDef write _waterDef;
    property FireDef: Cardinal read _fireDef write _fireDef;
    property EarthDef: Cardinal read _earthDef write _earthDef;
    property DefLevel: Cardinal read _defLevel write _defLevel;
    property SoulForce: Cardinal read _soulForce write _soulForce;
    property StealthDetectLevel: Cardinal read _stealthDetectLevel write _stealthDetectLevel;
    property WardingLevel: Cardinal read _wardingLevel write _wardingLevel;

    property createTime: Cardinal read FcreateTime write FcreateTime;
    property lastLoginTime: Cardinal read FlastLoginTime write FlastLoginTime;
    property custom_status: TOctets read Fcustom_status write Fcustom_status;
    property characterMode: TOctets read FcharacterMode write FcharacterMode;
    property referrer_role: Cardinal read Freferrer_role write Freferrer_role;
    property cash_add: Cardinal read Fcash_add write Fcash_add;
    property deleteTime: Cardinal read FdeleteTime write FdeleteTime;
    property status: byte read Fstatus write Fstatus;

    /// <remarks>
    /// Rotation of character in world.
    /// </remarks>
    property characterAngle: byte read FcharacterAngle write FcharacterAngle;

    /// <remarks>
    /// Is character in faction? 0=no; 1=yes
    /// </remarks>
    property inFaction: byte read FinFaction write FinFaction;

  end;

implementation

constructor TpwEmuPlayerCharacterBase.Create;
begin
  self.Fequip := TpwEmuPlayerCharacterEquipment.Create;
  // cloneEquip does this. Or not, if the char has no rquip.
end;

/// <remarks>
/// Get class used for marshalling 0x08 Roleinfo container subpacket.
/// </remarks>

function TpwEmuPlayerCharacterBase.getRoleUnknownInfo: TRoleUnknownInfo_08;
begin
  result := TRoleUnknownInfo_08.Create;
  result.Exp := self.Exp;
  result.sp := self.Spirit;
  result.roleid := self.roleid;
  result.Position := self.Position;
  result.angle := self.characterAngle;
  result.inFaction := self.inFaction;
  result.FactionID := self.FactionID;
  result.FactionRank := self.FactionRank;
end;

/// <remarks>
/// Returns class used for sending 0x26 container packet to client.
/// </remarks>
function TpwEmuPlayerCharacterBase.getSimpleRoleUpdateInfo: TSimpleRoleUpdateInfo_26;
begin
  result := TSimpleRoleUpdateInfo_26.Create;
  result.Level := self.Level;
  result.HPCurrent := self.HP;
  result.HpMax := self.HpMax;
  result.MPCurrent := MP;
  result.MpMax := self.MpMax;
  result.ExpCurrent := self.Exp;
  result.SpiritCurrent := self.Spirit;
  result.ChiCurrent := self.currentChi;
  result.Chimax := self.maxChi;
end;

/// <remarks>
/// Fills out roleInfo class. Must be freed and created by receptor.
/// </remarks>
procedure TpwEmuPlayerCharacterBase.fillRoleInfo ( role: TRoleInfo );
begin
  role.roleid := self.roleid;
  role.gender := self.Sex;
  role.Race := self.Race;
  role.occupation := self.Job;
  role.Level := self.Level;
  role.clutivation := self.Cultivation;
  role.namelen := Length( self.Name ) * 2;
  role.Name := self.Name;
  role.custom_data := self.custom_data;
  // get equip infoz!
  role.equipCount := self.Fequip.getEquipCount;

  if ( role.equipCount > 0 )
  then
  begin
    // result equip class created by clone.

    self.equip.cloneEquip( role.equip );
  end;
  role.status := self.status;
  role.deleteTime := self.deleteTime;
  role.createTime := self.createTime;
  role.lastLoginTime := self.lastLoginTime;

  role.Position := self.Position;

  role.worldID := self.MapID;
  role.custom_status := self.custom_status;
  role.characterMode := self.characterMode;
  role.referrer_role := self.referrer_role;
  role.cash_add := self.cash_add;

  // additional
  role.accountID := self.accountID;
end;

/// <remarks>
/// Create smaller info class for sending to bundlehandlers.
/// This contains all info required for roleList packet in char selection screen.
/// </remarks>

function TpwEmuPlayerCharacterBase.getRoleListCharacter: TRolelist_re_53;
var
  i: Integer;
begin
  result := TRolelist_re_53.Create( false ); // here
  result.nextSlot := 0;                      // Set to 0, the bundlehandler will set it for real.  For now. TODO
  result.accountID := self.accountID;        // Gotten from databasehive
  result.connectionID := self.accountID * 2; // again... wtf
  result.isChar := 1;
  self.fillRoleInfo( result.roleInfo );

end;

procedure TpwEmuPlayerCharacterBase.updateCustom_data( octets: TRawData; octetLen: Cardinal );
begin
  self.custom_data.octets := octets;
  self.custom_data.octetLen := octetLen;
end;

procedure TpwEmuPlayerCharacterBase.updatePosition ( newPos: TPoint3D );
begin
  self._position := newPos;
end;

procedure TpwEmuPlayerCharacterBase.damageChar( damage: Cardinal );
begin
  dec( self._hp, damage );

  if self.isDead
  then
    self._baseState := Dead;

end;

function TpwEmuPlayerCharacterBase.isAlive: Boolean;
begin
  result := ( self._hp > 0 );
end;

function TpwEmuPlayerCharacterBase.isDead: Boolean;
begin
  result := ( self._hp = 0 );
end;

end.
