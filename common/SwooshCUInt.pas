unit SwooshCUInt;

interface

uses windows;

type
  TSwooshCUINT = class
    function int2CUINT( value: integer ): integer;
    function CUINT2Int( value: integer ): integer;
  end;

implementation

function TSwooshCUINT.int2CUINT( value: integer ): integer;
begin

  if ( value < $80 )
  then

    result := byte( value )

  else
  begin

    if ( value < $4000 )
    then
      result := word( value or $8000 )
    else
    begin

      if ( value < $20000000 )
      then
        result := integer( value or $C0000000 );

    end;

  end;

end;

function TSwooshCUINT.CUINT2Int( value: integer ): integer;
begin

  if value < $80
  then
    result := byte( value )
  else if value < $C0
  then

    result := word( value ) and $3FFF

  else
    result := ( integer( value ) and $1FFFFFFF );
end;

end.
