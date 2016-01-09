unit swooshConfigHandler;

interface

uses inifiles, windows, serverDecl, classes, System.SysUtils, swooshOctetConverter, System.StrUtils;

type
  TStrArray = array of string; // for explode function only.

type
  TswooshIniHandler = class
    constructor create( filename: string );

    function readString( section, identifier: string ): string;
    function readFloat( section, identifier: string ): Single;
    function readInt( section, identifier: string ): integer;
    function readOctets( section, identifier: string ): TRawData;
    function readIntArray ( section, identifier: string ): TRawData32_512;
    function readStringArray ( section, identifier: string ): TStrArray;

    procedure writeString( section, identifier, value: string );

  private
    ini: TIniFile;
    _oc: TswooshOctetConverter;

    function Explode( var a: TStrArray; Border, S: string ): integer;
  end;

implementation

/// <remarks>
/// Create swooshIniHandler object
/// </remarks>

constructor TswooshIniHandler.create( filename: string );
begin
  self.ini := TIniFile.create( filename );
  self._oc := TswooshOctetConverter.create;

end;

/// <remarks>
/// Read string from ini file.
/// </remarks>

function TswooshIniHandler.readString( section, identifier: string ): string;
begin
  result := self.ini.readString( section, identifier, '' );

end;

/// <remarks>
/// Read int from ini file.
/// </remarks>

function TswooshIniHandler.readInt( section, identifier: string ): integer;
begin
  result := self.ini.ReadInteger( section, identifier, 0 );
end;

function TswooshIniHandler.readFloat( section, identifier: string ): Single;
begin
  result := self.ini.readFloat( section, identifier, 0.0 );
end;

/// <remarks>
/// Write string to ini file.
/// </remarks>

procedure TswooshIniHandler.writeString( section, identifier, value: string );
begin
  self.ini.writeString( section, identifier, value );
end;

function TswooshIniHandler.Explode( var a: TStrArray; Border, S: string ): integer;
var
  S2: string;
begin
  result := 0;
  S2 := S + Border;
  repeat
    SetLength( a, Length( a ) + 1 );
    a[ result ] := Copy( S2, 0, Pos( Border, S2 ) - 1 );
    Delete( S2, 1, Length( a[ result ] + Border ));
    Inc( result );
  until S2 = '';
end;

/// <remarks>
/// Reads string, and explodes to result type.
/// </remarks>
function TswooshIniHandler.readIntArray ( section, identifier: string ): TRawData32_512;
var
  ts         : string;
  ts_exploded: TStrArray;
  nNumbers   : integer;
  i          : integer;
begin
  ts := self.readString( section, identifier );

  if ( ts <> '' )
  then
  begin
    nNumbers := self.Explode( ts_exploded, ',', ts );
    if ( nNumbers < Length( result ))
    then
      for i := 0 to nNumbers - 1 do
        result[ i ] := StrToInt( ts_exploded[ i ]);

  end;

end;

function TswooshIniHandler.readStringArray ( section, identifier: string ): TStrArray;
var
  ts      : string;
  nNumbers: integer;
begin
  ts := self.readString( section, identifier );

  if ( ts <> '' )
  then

    nNumbers := self.Explode( result, ',', ts );

end;

/// <remarks>
/// Read binary data to bytearray from ini file.
/// </remarks>

function TswooshIniHandler.readOctets( section, identifier: string ): TRawData;
var
  octetString: ansistring;
  i          : integer;
begin

  octetString := self.readString( section, identifier );

  result := self._oc.stringToOctets( octetString );

end;

end.
