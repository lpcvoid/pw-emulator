unit swooshMaths;

interface

uses windows;

type
  TswooshMaths = class
  public
    function isPrimeNumber(r: int64): boolean;
    function supplyPrimeNumber : int64;
  end;

implementation

function TswooshMaths.isPrimeNumber(r: int64): boolean;
var
  j: integer;
begin
  if (r = 1) or (r = 2) then
  begin
    result := true;
    exit;
  end;

  for j := 2 to r - 1 do
  begin
    if (r mod j = 0) then
    begin
      result := false; // not prime
      exit;
    end;
  end;
  result := true; // prime
end;


function TswooshMaths.supplyPrimeNumber : int64;
var
seed : dword;
primeFound : boolean;
begin
   primeFound := false;
   seed := getTickCount();

   repeat
     Dec(seed);
     primeFound := self.isPrimeNumber(seed);
   until primeFound;

   result := seed;

end;

end.
