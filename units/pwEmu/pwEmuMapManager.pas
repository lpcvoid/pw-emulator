unit pwEmuMapManager;

interface

uses windows, types, classes, System.Generics.Collections, serverDecl, swooshConfigHandler, pwEmuDataTypes;

type
  TpwEmuMapManager = class
  public
    constructor Create ( config: TpwEmuWorldConfig );

  private

    _config: TpwEmuWorldConfig;

  end;

implementation

/// <remarks>
/// Create an instance of mapManager. it manages all maps, including their heightmaps, watermaps, collisionmaps, safezones, monsters, players and mines.
/// </remarks>
constructor TpwEmuMapManager.Create ( config: TpwEmuWorldConfig );
begin

  self._config := config;

end;

end.
