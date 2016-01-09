unit swooshDBTypes;

interface

uses windows, serverDecl;

{ type
  TSwooshDBTableColumn = packed record
 dataType: byte;
 dataTypeName : String;
 name: string;
 end;

 type
 TSwooshDBTableColumnBundle = array of TSwooshDBTableColumn;
}

type
  // $20 -> $21
  TSwooshDBCreateTableArgument = packed Record
    databaseName: AnsiString;
    tableName: AnsiString;
    // table name that is to be added to database with name DatabaseName
  End;

type
  // $22 - $23
  TSwooshDBShutdownDBArgument = packed record
    saveData: Boolean; // 1 = saves all database to disk; 0 = hard shutdown
    reason: AnsiString;
    authKey: AnsiString;
  end;

  // request DBList struct
type
  TSwooshDBListDatabaseArgument = packed record
    dummy: Cardinal;
  end;

  // DB list response
type
  TSwooshDBListDatabaseResponse = packed record
    dbCount: Cardinal;
    dbList: array of AnsiString;
  end;

type
  TSwooshDBListTablesResponse = packed record
    tableCount: Cardinal;
    tableList: array of AnsiString;
  end;

type
  TSwooshDBCreateDatabaseArgument = packed record
    dbName: AnsiString;
  end;

type
  TSwooshDBGetTablesArgument = packed record
    dbName: AnsiString;
  end;

type
  TSwooshDBTableExistArgument = packed Record
    databaseName: AnsiString;
    tableName: AnsiString;
  End;

type
  TSwooshDBRowData = packed record
    /// <remarks>
    /// dataType : Marks type of data written to sql.
    /// 0 - id is read from packet.
    /// 1 - string is read from packet.
    /// 2 - both are read from packet.
    /// </remarks>
    dataType: byte;
    id: integer;
    idString: AnsiString;
    timestamp: Cardinal;
    dataLen: Cardinal;
    dataLenCompressed: Cardinal;
    data: TRawdata;
  end;

implementation

end.
