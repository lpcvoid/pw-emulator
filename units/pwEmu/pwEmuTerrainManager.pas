{

 Manages sectors with physical propertys of every map.

 hmap
 wmap
 airmap (octree)
 rmap
 npcgen

 Other classes can then recoeve a pointer to ask a sector for this data.

}

unit pwEmuTerrainManager;

interface

uses windows, classes, types, system.Generics.collections, pwEmuTerrainMapSector, pwEmuDataTypes;

type
  TpwEmuTerrainManager = class
  public
    constructor Create( basePath: string; worldMaps, instanceMaps: TList< TpwEmuWorldConfig >);
  end;

implementation

constructor TpwEmuTerrainManager.Create( basePath: string; worldMaps, instanceMaps: TList< TpwEmuWorldConfig >);
begin

end;

end.
