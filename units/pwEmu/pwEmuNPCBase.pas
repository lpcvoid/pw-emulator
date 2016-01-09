unit pwEmuNPCBase;

interface

uses windows, sysutils, types, classes, system.Generics.collections, pwEmuDataTypes;

type
  TpwEmuNPCBase = class
  private
    Fid      : cardinal;
    Fdbid    : cardinal;
    FnpcType : byte;
    Fposition: TPoint3D;
    Fspeed   : single;
    Fhp      : TBounds;
    Fmp      : TBounds;

  public
    constructor Create ( wid: cardinal ); overload;
    constructor Create; overload;
    procedure updatePosition ( newPos: TPoint3D );

    property wid: cardinal read Fid write Fid;
    property dbid: cardinal read Fdbid write Fdbid;
    property npcType: byte read FnpcType write FnpcType;
    property position: TPoint3D read Fposition write Fposition;
    property speed: single read Fspeed write Fspeed;
    property hp: TBounds read Fhp write Fhp;
    property mp: TBounds read Fmp write Fmp;

  end;

implementation

constructor TpwEmuNPCBase.Create ( wid: cardinal );
begin
  self.wid := wid;
end;

constructor TpwEmuNPCBase.Create;
begin

end;

/// <remarks>
/// Moves the NPC according to it's speed. Checks if it's possible to move to that in one second.
/// </remarks>

procedure TpwEmuNPCBase.updatePosition ( newPos: TPoint3D );
begin

  self.position := newPos;

end;

end.
