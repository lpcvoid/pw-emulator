unit swooshFileSearcher;

interface

uses windows, classes, System.SysUtils;

type
  TSwooshFileSearcher = class
    procedure listFilesInDirectory( dir: String; out theList: TStringList );
  end;

implementation

procedure TSwooshFileSearcher.listFilesInDirectory( dir: String; out theList: TStringList );
// dir example : './Scripts/*.pgs'
var
  Res    : TSearchRec;
  EOFound: Boolean;
begin
  try
    EOFound := False;
    if FindFirst( dir, faAnyFile, Res ) >= 0
    then
    begin
      while not EOFound do
      begin
        theList.add( Res.Name );
        EOFound := FindNext( Res ) <> 0;
      end;
    end;
  finally
    FindClose( Res );
  end;

end;

end.
