unit pwEmuCoordinateConverter;

interface

uses System.Types, math, serverDecl;

Type
  TCoordinateConverterResult = packed record
    SectorSID: integer;
    X: Single;
    Z: Single;
  end;

type
  TpwEmuCoordinateConverter = class
  public
    constructor Create(nMapColumns, nMapRows, sectorWidth,
      sectorHeight: integer);
    function worldToSector(Point: Tpoint3D): TCoordinateConverterResult;
    function GetHeight(X, Z: Single; SectorID: word;
      SectorMap: TRawdataFloat): Single;
    // array single * 800 coz marc want it so

  private
    _nMapColumns, _nMapRows, _sectorWidth, _sectorHeigth, maxCount: integer;
  end;

implementation

/// <remark>
/// just to get the Number of Columns, Rows and Sector Height, Width.
/// </remark>
constructor TpwEmuCoordinateConverter.Create(nMapColumns, nMapRows, sectorWidth,
  sectorHeight: integer);
begin
  self._nMapColumns := nMapColumns;
  self._nMapRows := nMapRows;
  self._sectorWidth := sectorWidth;
  self._sectorHeigth := sectorHeight;
end;
{$REGION 'WorldToSector'}

/// <remark>
/// returns Sector ID and the position in this sector
/// </remark>
function TpwEmuCoordinateConverter.worldToSector(Point: Tpoint3D)
  : TCoordinateConverterResult;
var
  posX, posZ: Single;
  borderX, BorderZ: Single;
begin
  borderX := (self._nMapColumns / 2) * self._sectorWidth * 2; // 4096
  BorderZ := (self._nMapRows / 2) * self._sectorHeigth * 2; // 5632

  if (Point.X > (borderX-1)) then // so oder Zeile 59 +1 Raus dafür -4095....
    Point.X := borderX-1;

  if (Point.Z < (-BorderZ+1)) then
    Point.Z := -(borderZ-1);

  posX := ((borderX + Point.X) / (self._sectorWidth * 2));
  posZ := ((BorderZ * 2 + (BorderZ + (Point.Z * -1))) / (self._sectorHeigth * 2)
    ) - (self._nMapRows - 1);

  // Result.SectorSID := round(((Int(posz)*8)) - (7-(int(posx))));
  Result.SectorSID := ((Floor(posZ) - 1) * 8 + Floor(posX)) + 1; // +1 -.-

  Result.X := self._sectorWidth*2 * Frac(posX); // Coordinates in a sector
  Result.Z := self._sectorHeigth*2 * Frac(posZ); // Z in a sektor

end;
{$ENDREGION}
// C:\Users\Wartari\Dropbox\bigServer\pwEmu\oldCode\uHeightMap.pas

{$REGION 'GetHeight'}

function TpwEmuCoordinateConverter.GetHeight(X, Z: Single; SectorID: word;
  SectorMap: TRawdataFloat): Single;
var
  ConverterResult: TCoordinateConverterResult;
  Temp: Single;
  XIndex, YIndex, FXIndex, FYIndex, Index1, Index2, Index3, Index4: integer;
  FXFrac, FYFrac, Z1, Z2, Z3, Z4, Z12, Z43: Single;
begin
  Result := -1.0;
  // umrechnen des Punktes mit sektor, glesen des punktes aus dem sektor
  // ConverterResult := self.worldToSector(Point);
  // berechnen der Höhe
  if ((X < 0) or (X > 1024) or (Z < 0) or (Z > 1024)) then
  begin
    Exit;
  end
  else
  begin
    FXIndex := Floor(X / 2.0);
    FYIndex := Floor(Z / 2.0);

    FXFrac := X / 2.0 - FXIndex;
    FYFrac := Z / 2.0 - FYIndex;

    XIndex := round(FXIndex);
    YIndex := round(FYIndex);

    Index1 := XIndex + YIndex * (32 * 16 + 1);
    Index2 := XIndex + 1 + YIndex * (32 * 16 + 1);
    Index3 := XIndex + 1 + (YIndex + 1) * (32 * 16 + 1);
    Index4 := XIndex + (YIndex + 1) * (32 * 16 + 1);

    Z1 := SectorMap[Index1];
    Z2 := SectorMap[Index2];
    Z3 := SectorMap[Index3];
    Z4 := SectorMap[Index4];

    Z12 := (Z2 - Z1) * FXFrac + Z1;
    Z43 := (Z3 - Z4) * FXFrac + Z4;
    Result := (((Z43 - Z12) * FYFrac + Z12 { + 0.01 } ) * 800);
  end;
end;
{$ENDREGION}

end.
