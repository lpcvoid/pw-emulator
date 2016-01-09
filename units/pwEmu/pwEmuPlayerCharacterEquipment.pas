unit pwEmuPlayerCharacterEquipment;

interface

uses System.Types, System.Classes, windows, System.Generics.Collections, pwEmuItemBase, pwEmuDataTypes;

type
  TpwEmuPlayerCharacterEquipment = class
  public
    constructor Create;

    procedure setEquipItem ( item: TpwEmuItemBase; equipType: integer );
    procedure addEquipItem ( item: TpwEmuItemBase );
    function getEquipItem ( equipType: integer ): TpwEmuItemBase;
    function getEquipCount: integer;
    procedure cloneEquip (equip : TpwEmuPlayerCharacterEquipment);
    destructor Destroy; override;

  private

    _slots: TList< TpwEmuItemBase >;

  const
    MAXSLOTS = 18;
  end;

implementation

constructor TpwEmuPlayerCharacterEquipment.Create;
begin
  Self._slots := TList< TpwEmuItemBase >.Create;

end;

destructor TpwEmuPlayerCharacterEquipment.Destroy;
begin
  // free TList and all items.
end;

/// <remarks>
/// used for roleList function.
/// </remarks>

procedure TpwEmuPlayerCharacterEquipment.cloneEquip (equip : TpwEmuPlayerCharacterEquipment);
var
  i, c: integer;
  cloneItem : TpwEmuItemBase;
begin
    //valid here
  c := Self.getEquipCount;
  if ( c > 0 )
  then
    for i := 0 to c - 1 do
    begin

      cloneItem := Self._slots[ i ].Clone;
      equip.addEquipItem( cloneItem );
      // Hello. I am Result. I am NIL. I am NIL pointer of type TpwEmuPlayerCharEqw.
      // I am nil because no one called a create on me. I started my life as NIL when this method "cloneEquip" was called.
      // Before clone Equipt was called, another Result existed, but that wasd not me, it was my sister. She lives inside another method.
      // She is not NIL, someone called create on here. But not me. So I'm sad.
    end;

end;

function TpwEmuPlayerCharacterEquipment.getEquipCount: integer;
begin
  Result := Self._slots.Count; // does count return number of non-nil items?
end;

procedure TpwEmuPlayerCharacterEquipment.setEquipItem ( item: TpwEmuItemBase; equipType: integer );
begin
  if ( equipType < Self.getEquipCount ) and ( equipType > - 1 )
  then
    Self._slots[ equipType ] := ( item );

end;

procedure TpwEmuPlayerCharacterEquipment.addEquipItem ( item: TpwEmuItemBase );
begin
  Self._slots.Add( item );
end;

/// <remarks>
/// Parameter is the slot. Every equip has certain slot.
/// </remarks>

function TpwEmuPlayerCharacterEquipment.getEquipItem ( equipType: integer ): TpwEmuItemBase;
begin
  if ( equipType < Self.getEquipCount ) and ( equipType > - 1 )
  then
    Result := Self._slots[ equipType ];

end;

end.
