unit pwEmuNpcgenReader;

interface

uses windows, classes, types, System.Generics.Collections, swooshFileBuffer, pwEmuNpcgenDataTypes;

type
  TpwEmuNpcgenReader = class
  private
    _npcGenVersion: Cardinal;
    _nCreatureSets: Cardinal;
    _nResourceSets: Cardinal;
    _nDynamics    : Cardinal;
    _nTriggers    : Cardinal;

    _creatureSets: TList< TpwEmuNpcGenCreatureSet >;
    _resourceSets: TList< TpwEmuNpcGenResourceSet >;
    _dynamics    : TList< TpwEmuNpcGenDynamic >;
    _triggers    : TList< TpwEmuNpcGenTrigger >;

    _fs: TSwooshFileBuffer;

  const
    PWNPCGENVERSION_FULL = 10;

  public
    constructor Create;
    function loadFile( theFile: WideString ): boolean;

    property nCreatureSets: Cardinal read _nCreatureSets;
    property nResourceSets: Cardinal read _nResourceSets;
    property nDynamics: Cardinal read _nDynamics;
    property nTriggers: Cardinal read _nTriggers;

  end;

implementation

constructor TpwEmuNpcgenReader.Create;
begin
  self._creatureSets := TList< TpwEmuNpcGenCreatureSet >.Create;
  self._resourceSets := TList< TpwEmuNpcGenResourceSet >.Create;
  self._dynamics := TList< TpwEmuNpcGenDynamic >.Create;
  self._triggers := TList< TpwEmuNpcGenTrigger >.Create;

end;

function TpwEmuNpcgenReader.loadFile( theFile: WideString ): boolean;
var
  i                      : Integer;
  n                      : Integer;
  tempNpcGenCreatureSet  : TpwEmuNpcGenCreatureSet;
  tempNpcGenCreatureGroup: TpwEmuNpcGenCreatureGroup;

  tempNpcGenResourceSet  : TpwEmuNpcGenResourceSet;
  tempNpcGenResourceGroup: TpwEmuNpcGenResourceGroup;

  tempDynamic: TpwEmuNpcGenDynamic;
  tempTrigger: TpwEmuNpcGenTrigger;

begin
  result := false;
  self._fs := TSwooshFileBuffer.Create( theFile );

  self._npcGenVersion := self._fs.readInt;
  self._nCreatureSets := self._fs.readInt;
  self._nResourceSets := self._fs.readInt;

  // check version. If not 10, then no dynamics or triggers.
  // pw server must be able to handle multiple versions.
  if ( self._npcGenVersion = self.PWNPCGENVERSION_FULL )
  then
  begin
    self._nDynamics := self._fs.readInt;
    self._nTriggers := self._fs.readInt;

  end
  else
  begin
    self._nDynamics := 0;
    self._nTriggers := 0;
  end;

  // load creatures...
  for i := 0 to self._nCreatureSets - 1 do
  begin
    tempNpcGenCreatureSet := TpwEmuNpcGenCreatureSet.Create;

    tempNpcGenCreatureSet.spawn_mode := self._fs.readInt;
    tempNpcGenCreatureSet.creature_groups_count := self._fs.readInt;

    tempNpcGenCreatureSet.position.X := self._fs.readFloat;
    tempNpcGenCreatureSet.position.Y := self._fs.readFloat;
    tempNpcGenCreatureSet.position.Z := self._fs.readFloat;

    tempNpcGenCreatureSet.direction.X := self._fs.readFloat;
    tempNpcGenCreatureSet.direction.Y := self._fs.readFloat;
    tempNpcGenCreatureSet.direction.Z := self._fs.readFloat;

    tempNpcGenCreatureSet.spread.X := self._fs.readFloat;
    tempNpcGenCreatureSet.spread.Y := self._fs.readFloat;
    tempNpcGenCreatureSet.spread.Z := self._fs.readFloat;

    tempNpcGenCreatureSet.NPCType := self._fs.readInt;
    tempNpcGenCreatureSet.groupType := self._fs.readInt;
    tempNpcGenCreatureSet.initGen := self._fs.readBoolean;
    tempNpcGenCreatureSet.autoRespawn := self._fs.readBoolean;
    tempNpcGenCreatureSet.validOnce := self._fs.readBoolean;
    tempNpcGenCreatureSet.UK_0 := self._fs.readInt;

    if ( self._npcGenVersion = self.PWNPCGENVERSION_FULL )
    then
    begin

      tempNpcGenCreatureSet.GenID := self._fs.readInt;
      tempNpcGenCreatureSet.lifeTime := self._fs.readInt;
      tempNpcGenCreatureSet.maxNum := self._fs.readInt;
    end
    else
    begin
      tempNpcGenCreatureSet.GenID := 0;
      tempNpcGenCreatureSet.lifeTime := 0;
      tempNpcGenCreatureSet.maxNum := 0;
    end;

    // creaturegroups

    if ( tempNpcGenCreatureSet.creature_groups_count > 0 )
    then
    begin
      tempNpcGenCreatureSet.creature_groups := TList< TpwEmuNpcGenCreatureGroup >.Create;
      for n := 0 to tempNpcGenCreatureSet.creature_groups_count - 1 do
      begin

        tempNpcGenCreatureGroup := TpwEmuNpcGenCreatureGroup.Create;

        tempNpcGenCreatureGroup.ID := self._fs.readInt;
        tempNpcGenCreatureGroup.count := self._fs.readInt;
        tempNpcGenCreatureGroup.respawn := self._fs.readInt;
        tempNpcGenCreatureGroup.diedTimes := self._fs.readInt;
        tempNpcGenCreatureGroup.aggressive := self._fs.readInt;
        tempNpcGenCreatureGroup.offsetWater := self._fs.readFloat;
        tempNpcGenCreatureGroup.offsetTerrain := self._fs.readFloat;
        tempNpcGenCreatureGroup.faction := self._fs.readInt;
        tempNpcGenCreatureGroup.facHelper := self._fs.readInt;
        tempNpcGenCreatureGroup.facAccept := self._fs.readInt;
        tempNpcGenCreatureGroup.needHelp := self._fs.readBoolean;
        tempNpcGenCreatureGroup.defFaction := self._fs.readBoolean;
        tempNpcGenCreatureGroup.defFacHelper := self._fs.readBoolean;
        tempNpcGenCreatureGroup.defFacAccept := self._fs.readBoolean;
        tempNpcGenCreatureGroup.pathID := self._fs.readInt;
        tempNpcGenCreatureGroup.loopType := self._fs.readInt;
        tempNpcGenCreatureGroup.speedFlag := self._fs.readInt;
        tempNpcGenCreatureGroup.deadTime := self._fs.readInt;

        tempNpcGenCreatureSet.creature_groups.Add( tempNpcGenCreatureGroup );

      end;
    end;

    self._creatureSets.Add( tempNpcGenCreatureSet );

  end;

  // load resources

  for i := 0 to self._nResourceSets - 1 do
  begin

    tempNpcGenResourceSet := TpwEmuNpcGenResourceSet.Create;

    tempNpcGenResourceSet.position.X := self._fs.readFloat;
    tempNpcGenResourceSet.position.Y := self._fs.readFloat;
    tempNpcGenResourceSet.position.Z := self._fs.readFloat;
    tempNpcGenResourceSet.spread_X := self._fs.readFloat;
    tempNpcGenResourceSet.spread_Z := self._fs.readFloat;
    tempNpcGenResourceSet.resource_group_count := self._fs.readInt;
    tempNpcGenResourceSet.initGen := self._fs.readBoolean;
    tempNpcGenResourceSet.respawn := self._fs.readBoolean;
    tempNpcGenResourceSet.validOnce := self._fs.readBoolean;
    tempNpcGenResourceSet.GenID := self._fs.readInt;

    if ( self._npcGenVersion = self.PWNPCGENVERSION_FULL )
    then
    begin
      tempNpcGenResourceSet.dir[ 0 ] := self._fs.readbyte;
      tempNpcGenResourceSet.dir[ 1 ] := self._fs.readbyte;
      tempNpcGenResourceSet.rad := self._fs.readbyte;
      tempNpcGenResourceSet.idControl := self._fs.readInt;
      tempNpcGenResourceSet.maxNum := self._fs.readInt; // sNPCEdit wrong, not 4 bool/chars, but one int probably according to struct

    end
    else
    begin
      tempNpcGenResourceSet.dir[ 0 ] := 192;
      tempNpcGenResourceSet.dir[ 1 ] := 63;
      tempNpcGenResourceSet.rad := 0;
      tempNpcGenResourceSet.idControl := 0;
      tempNpcGenResourceSet.maxNum := 0;
    end;

    if ( tempNpcGenResourceSet.resource_group_count > 0 )
    then
    begin

      tempNpcGenResourceSet.resource_groups := TList< TpwEmuNpcGenResourceGroup >.Create;

      for n := 0 to tempNpcGenResourceSet.resource_group_count - 1 do
      begin

        tempNpcGenResourceGroup := TpwEmuNpcGenResourceGroup.Create;

        tempNpcGenResourceGroup.resourceType := self._fs.readInt;
        tempNpcGenResourceGroup.ID := self._fs.readInt;
        tempNpcGenResourceGroup.respawn := self._fs.readInt;
        tempNpcGenResourceGroup.count := self._fs.readInt;
        tempNpcGenResourceGroup.heightOffset := self._fs.readFloat;

        tempNpcGenResourceSet.resource_groups.Add( tempNpcGenResourceGroup );

      end;

    end;

    self._resourceSets.Add( tempNpcGenResourceSet );

  end;


  // load dynamics

  if ( self._nDynamics > 0 )
  then
  begin

    for i := 0 to self._nDynamics - 1 do
    begin

      tempDynamic := TpwEmuNpcGenDynamic.Create;

      tempDynamic.ID := self._fs.readInt;
      tempDynamic.position.X := self._fs.readFloat;
      tempDynamic.position.Y := self._fs.readFloat;
      tempDynamic.position.Z := self._fs.readFloat;
      tempDynamic.dir[ 0 ] := self._fs.readbyte;
      tempDynamic.dir[ 1 ] := self._fs.readbyte;
      tempDynamic.rad := self._fs.readbyte;
      tempDynamic.trigger := self._fs.readInt;
      tempDynamic.scale := self._fs.readbyte;

      self._dynamics.Add( tempDynamic );

    end;

  end;

  // load triggers

  if ( self._nTriggers > 0 )
  then
  begin

    for i := 0 to self._nTriggers - 1 do
    begin

      tempTrigger := TpwEmuNpcGenTrigger.Create;
      tempTrigger.ID := self._fs.readInt;
      tempTrigger.controllerID := self._fs.readInt;
      self._fs.readPointerData(@tempTrigger.name[ 0 ], 128 );
      tempTrigger.startWithMap := self._fs.readBoolean;
      tempTrigger.autoStartDelay := self._fs.readInt;
      tempTrigger.autoStopDelay := self._fs.readInt;
      tempTrigger.disableAutoStart := self._fs.readBoolean;
      tempTrigger.disableAutoStop := self._fs.readBoolean;
      tempTrigger.activeTimeRange := self._fs.readInt;

      tempTrigger.activeTime.year := self._fs.readInt;
      tempTrigger.activeTime.month := self._fs.readInt;
      tempTrigger.activeTime.week := self._fs.readInt;
      tempTrigger.activeTime.day := self._fs.readInt;
      tempTrigger.activeTime.hours := self._fs.readInt;
      tempTrigger.activeTime.minutes := self._fs.readInt;

      tempTrigger.stoppingTime.year := self._fs.readInt;
      tempTrigger.stoppingTime.month := self._fs.readInt;
      tempTrigger.stoppingTime.week := self._fs.readInt;
      tempTrigger.stoppingTime.day := self._fs.readInt;
      tempTrigger.stoppingTime.hours := self._fs.readInt;
      tempTrigger.stoppingTime.minutes := self._fs.readInt;

      tempTrigger.duration := self._fs.readInt;

      self._triggers.Add( tempTrigger );

    end;

  end;

  self._fs.Free;
  result := true;

end;

end.
