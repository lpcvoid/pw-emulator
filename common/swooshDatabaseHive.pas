unit swooshDatabaseHive;

interface

uses SQLiteTable3, windows, swooshDBTypes, System.SysUtils,
  classes, serverDecl, swooshCompression;

type
  TswooshDatabaseHive = class
  public
    constructor Create( config: TbigServerConfig );
    destructor Destroy; override;
    Function getDatabaseName: String;
    function getTables: TSwooshDBListTablesResponse;
    function saveData: integer;

  Protected
    sqlitedb_disk  : TSQLiteDatabase;
    sqlitedb_memory: TSQLiteDatabase;
    sqlite_version : string;
    _dbName        : String;
    _config        : TbigServerConfig;
    function cleanParameter( parameter: String ): string;
  end;

implementation

constructor TswooshDatabaseHive.Create( config: TbigServerConfig );
var
  sqliteRet: integer;
begin
  self._config := config;
  // load all table data!
  // first, we create memory database.

  if not FileExists( self._config.db )
  then
    Exit;

  self.sqlitedb_disk := TSQLiteDatabase.Create( self._config.db );
  self.sqlitedb_memory := TSQLiteDatabase.Create( ':memory:' );
  // now, letz copy the contents of _sldb to the memory one for powa.
  sqliteRet := self.sqlitedb_disk.Backup( self.sqlitedb_memory );
  if ( sqliteRet = 101 )
  then // 101  /* sqlite3_step() has finished executing */
  begin
    // okay, there we go. All operations are now performed on the memory db.

    self.sqlite_version := self.sqlitedb_memory.Version;
    writeln( 'TswooshDatabaseHive.Create() :: Loaded ' + ExtractFileName( self._config.db ) + ' successfully. version=' + self.sqlite_version );
  end;

  self._dbName := ExtractFileName( self._config.db );

end;

destructor TswooshDatabaseHive.Destroy;
begin
  self.sqlitedb_disk.Free;
  self.sqlitedb_memory.Free;
  inherited;
end;

function TswooshDatabaseHive.saveData: integer;
begin
  result := self.sqlitedb_memory.Backup( self.sqlitedb_disk );
end;

Function TswooshDatabaseHive.getDatabaseName: String;
begin
  result := self._dbName;
end;

function TswooshDatabaseHive.cleanParameter( parameter: String ): string;
begin
  result := StringReplace( parameter, '''', '', [ rfReplaceAll, rfIgnoreCase ]);
  result := StringReplace( result, '"', '', [ rfReplaceAll, rfIgnoreCase ]);
end;

function TswooshDatabaseHive.getTables: TSwooshDBListTablesResponse;
var
  sltb: TSQLiteTable;
  I   : integer;
begin
  sltb := self.sqlitedb_memory.GetTable( 'SELECT name FROM sqlite_master WHERE type = "table";' );
  result.tableCount := sltb.Count;
  SetLength( result.tableList, result.tableCount );
  for I := 0 to result.tableCount - 1 do
  begin
    result.tableList[ I ] := sltb.FieldAsString( 0 );
    sltb.Next;
  end;
end;

end.
