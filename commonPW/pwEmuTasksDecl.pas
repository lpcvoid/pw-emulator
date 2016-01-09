unit pwEmuTasksDecl;

interface

//Date
type
    TTasksDate = packed record
      year : integer;
      month : integer;
      day : integer;
      hour : integer;
      minute : integer;
      weekday : integer;
    end;

//Dunno what this is...

type
    TTaskTmType = array [0..23] of byte;

implementation

end.
