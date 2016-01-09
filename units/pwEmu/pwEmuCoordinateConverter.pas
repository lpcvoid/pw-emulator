unit pwEmuCoordinateConverter;

interface

uses windows, System.Classes, System.Types;

type
  TpwEmuCoordinateConverter = class
    function ingameToMapCoords( coord: Tpoint3D ): Tpoint3D; deprecated;
    function mapToIngameCoords( coord: Tpoint3D ): Tpoint3D; deprecated;
  end;

implementation

function TpwEmuCoordinateConverter.ingameToMapCoords( coord: Tpoint3D ): Tpoint3D;
begin
  Result := coord;
  Result.X := Result.X / 10;
  Result.X := Result.X + 400;
  Result.Y := Result.Y / 10; //height FFS
  Result.Z := Result.Z /10;
  Result.Z := Result.Z + 550;
end;

function TpwEmuCoordinateConverter.mapToIngameCoords( coord: Tpoint3D ): Tpoint3D;
begin
  Result := coord;
  Result.X := Result.X * 10;
  Result.X := Result.X - 400;
  Result.Y := Result.Y * 10; //height FFS
  Result.Z := Result.Z *10;
  Result.Z := Result.Z - 550;
end;

end.
