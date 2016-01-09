unit swooshOctetConverter;

interface

uses windows, System.SysUtils, types, serverDecl;

type
  TswooshOctetConverter = class
    function stringToOctets ( str: AnsiString ): TRawData;
    function stringToHashkey ( str: AnsiString ): THashKey;
  end;

implementation

function TswooshOctetConverter.stringToOctets ( str: AnsiString ): TRawData;
var
  i: integer;
begin
  if ( str = '' ) or (( length( str ) mod 2 ) = 1 )
  then
    exit;

  setlength( result, round( length( str ) / 2 ));

  for i := 0 to round( length( str ) / 2 ) - 1 do
  begin
    result[ i ] := strtoint( '$' + str[ i * 2 + 1 ] + str[ i * 2 + 2 ]);
  end;
end;

function TswooshOctetConverter.stringToHashkey ( str: AnsiString ): THashKey;
var
  traw: TRawData;
begin

  traw := self.stringToOctets( str );

  if ( length( traw ) = 16 )
  then
    CopyMemory(@result[ 0 ],@traw[ 0 ], 16 );

end;

end.
