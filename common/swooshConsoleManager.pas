unit swooshConsoleManager;

interface

uses windows, System.Classes;

type
  TswooshConsoleManager = class
    constructor Create( width, height: integer );
  end;

implementation

constructor TswooshConsoleManager.Create( width, height: integer );
var
  sr : TSmallRect;
  crd: TCoord;
begin
  sr.Left := 0;        // Didn't affect anything for me
  sr.Top := 0;         // Didn't affect anything for me
  sr.Right := width;   // Width - 1
  sr.Bottom := height; // Height - 1
  crd.X := width;      // Width
  crd.Y := height;     // Heigh
  SetConsoleWindowInfo( GetStdHandle( STD_OUTPUT_HANDLE ), True, sr );
  SetConsoleScreenBufferSize( GetStdHandle( STD_OUTPUT_HANDLE ), crd );

end;

end.
