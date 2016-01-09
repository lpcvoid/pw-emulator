unit pwEmuTerrainMapSector;

interface

uses windows, System.Types, sysutils, System.Classes, System.Generics.Collections, serverDecl, swooshFileBuffer, pwEmuDataTypes,
  swooshFileSearcher, swooshRectangle;

type
  TpwEmuTerrainMapSector = class
  public
    constructor Create ( worldConfig: TpwEmuWorldConfig; SectorID: Cardinal );
    function isInWater ( p: TPoint3D ): boolean;

  private
    _hmapRawDataBlock: TRawDataFloat;

    _wmapRectangleCount    : Cardinal;
    _wmapRectangles        : TList< TswooshSpanRectangle3D >;
    _wmapWidth, _wmapHeight: single;

    _fs         : TSwooshFileBuffer;
    _sectorID   : Cardinal;
    _worldConfig: TpwEmuWorldConfig;
    function getHeight( x, y: integer ): single;

  end;

implementation

constructor TpwEmuTerrainMapSector.Create( worldConfig: TpwEmuWorldConfig; SectorID: Cardinal );
var
  path    : string;
  dataSize: Cardinal;
  i       : integer;
begin
  self._worldConfig := worldConfig;
  self._sectorID := SectorID;

  // Now we load this sectors hmap, watermap and rmap.

  // hmap

  path := worldConfig.worldFilePath + 'map/' + IntToStr( self._sectorID ) + '.hmap';

  if FileExists( path )
  then
  begin

    self._fs := TSwooshFileBuffer.Create( path );

    dataSize := ( worldConfig.subSectionHeight + 1 ) * ( worldConfig.subSectionWidth + 1 );

    SetLength( self._hmapRawDataBlock, dataSize );

    self._fs.readRawDataFloat( dataSize * 4, self._hmapRawDataBlock );

    self._fs.Free;

  end
  else
    writeln( '***Cannot find heightmap! sectorID=' + IntToStr( self._sectorID ) + ', worldID=' + IntToStr( self._worldConfig.worldTag ));


  // wmaps

  path := worldConfig.worldFilePath + 'watermap/' + IntToStr( self._sectorID ) + '.wmap';

  if FileExists( path )
  then
  begin

    self._fs := TSwooshFileBuffer.Create( path );

    self._fs.readInt; // version
    self._fs.readInt; // uk -16
    self._wmapWidth := self._fs.readFloat;
    self._wmapHeight := self._fs.readFloat;
    self._wmapRectangleCount := self._fs.readInt;

    if ( self._wmapRectangleCount > 0 )
    then
    begin

      self._wmapRectangles := TList< TswooshSpanRectangle3D >.Create;

      for i := 0 to self._wmapRectangleCount - 1 do
      begin
        self._wmapRectangles.Add( TswooshSpanRectangle3D.Create( self._fs.readFloat, self._fs.readFloat, self._fs.readFloat, self._fs.readFloat,
            self._fs.readFloat ) );
        // writeln('TpwEmuWatermapSector::Create : sector=' + IntToStr(sectorID) + ' boundRect=' + self._rects.Items[i].getDimensionString);
      end;

    end;

    self._fs.Free;

  end
  else
    writeln( '***Cannot find watermap! sectorID=' + IntToStr( self._sectorID ) + ', worldID=' + IntToStr( self._worldConfig.worldTag ));

end;

/// <remarks>
/// Returns if a given point is in the water. Also takes height into account.
/// </remarks>
function TpwEmuTerrainMapSector.isInWater( p: TPoint3D ): boolean;
var
  i: integer;
begin
  result := false;
  if self._wmapRectangleCount > 0
  then
  begin
    for i := 0 to self._wmapRectangleCount - 1 do
      if self._wmapRectangles.Items[ i ].isPointInRect3D( p.x, p.Z, p.y )
      then
      begin
        result := true;
        exit;
      end;

  end

end;

/// <remarks>
/// Gets height of terrain at a random point.
/// </remarks>

function TpwEmuTerrainMapSector.getHeight( x, y: integer ): single;
var
  index: integer;
begin

  index := x * y;
  // index := ix * iy;
  result := self._hmapRawDataBlock[ index ] * 800.0;

  (*

   [(((int) pos.x) - (0x200 * (((int) pos.x) / 0x200))) / 2, (((int) pos.z) - (0x200 * (((int) pos.z) / 0x200))) / 2];

  *)

end;

end.
