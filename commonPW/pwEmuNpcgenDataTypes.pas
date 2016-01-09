unit pwEmuNpcgenDataTypes;

interface

uses windows, types, classes, System.Generics.collections;

type
  TpwEmuNpcGenCreatureGroup = class // see NPCGENFILEAIGEN in structs
    ID: cardinal;
    count: cardinal;
    respawn: integer;
    diedTimes: cardinal;
    aggressive: cardinal;
    offsetWater: Single;
    offsetTerrain: Single;
    faction: cardinal;
    facHelper: cardinal;
    facAccept: cardinal;
    needHelp: boolean;     // Gets help from sourrounding mobs?
    defFaction: boolean;   // defends the sourounding mobs with same faction?
    defFacHelper: boolean; // Dunno
    defFacAccept: boolean; // dunno either
    pathID: integer;
    loopType: integer;
    speedFlag: integer;
    deadTime: integer;
  end;

type
  TpwEmuNpcGenCreatureSet = class // CreatureSet
    spawn_mode: integer;
    creature_groups_count: cardinal;

    position: TPoint3D;
    direction: TPoint3D;
    spread: TPoint3D;

    NPCType: integer;
    groupType: integer;

    initGen: boolean;
    autoRespawn: boolean;
    validOnce: boolean;

    UK_0: integer;  // dwGenID
    GenID: integer; // trigger

    lifeTime: integer;
    maxNum: integer;

    creature_groups: TList< TpwEmuNpcGenCreatureGroup >;
  end;

type
  TpwEmuNpcGenResourceGroup = class // NPCGENFILERES in structs
    resourceType: integer;
    ID: integer;
    respawn: cardinal;
    count: cardinal;
    heightOffset: Single;
  end;

type
  TpwEmuNpcGenResourceSet = class
    position: TPoint3D;
    spread_X: Single;
    spread_Z: Single;
    resource_group_count: integer;
    initGen: boolean;
    respawn: boolean;
    validOnce: boolean;
    GenID: cardinal; // No clue
    dir: array [ 0 .. 1 ] of byte;
    rad: byte;
    idControl: cardinal; // unknown trigger
    maxNum: integer;

    resource_groups: TList< TpwEmuNpcGenResourceGroup >;
  end;

type
  TpwEmuNpcGenDynamic = class
    ID: cardinal; // DynObjID
    position: TPoint3D;
    dir: array [ 0 .. 1 ] of byte;
    rad: byte;
    trigger: integer;
    scale: byte;
  end;

type
  TpwEmuNpcGenControlTime = record
    year: integer;
    month: integer;
    week: integer;
    day: integer;
    hours: integer;
    minutes: integer;
  end;

type
  TpwEmuNpcGenTrigger = class
    ID: cardinal;          // trigger link
    controllerID: integer; // GM activator ID
    name: array [ 0 .. 127 ] of AnsiChar;
    startWithMap: boolean; // start with map?
    autoStartDelay: integer;
    autoStopDelay: integer;
    disableAutoStart: boolean;
    disableAutoStop: boolean;
    activeTimeRange: integer;
    activeTime: TpwEmuNpcGenControlTime;
    stoppingTime: TpwEmuNpcGenControlTime;
    duration: integer;
  end;

implementation

end.
