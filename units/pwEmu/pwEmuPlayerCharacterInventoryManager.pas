unit pwEmuPlayerCharacterInventoryManager;

interface

uses windows, classes, types, System.Generics.Collections, pwEmuPlayerCharacterInventory;

type
  TpwEmuPlayerCharacterInventoryManager = class
  public
    constructor Create;
    destructor Destroy; override;
    procedure addInventory ( charID: Cardinal; inv: TpwEmuPlayerCharacterInventory );
    function getInventory ( charID: Cardinal ): TpwEmuPlayerCharacterInventory;
    procedure removeInventory ( charID: Cardinal );

  private
    _inventorys: TDictionary< Cardinal, TpwEmuPlayerCharacterInventory >;
  end;

implementation

constructor TpwEmuPlayerCharacterInventoryManager.Create;
begin
  self._inventorys := TDictionary< Cardinal, TpwEmuPlayerCharacterInventory >.Create;
end;

destructor TpwEmuPlayerCharacterInventoryManager.Destroy;
begin
  // TODO : Destory all inventorys.
end;

procedure TpwEmuPlayerCharacterInventoryManager.addInventory ( charID: Cardinal; inv: TpwEmuPlayerCharacterInventory );
begin
  self._inventorys.Add( charID, inv );
end;

function TpwEmuPlayerCharacterInventoryManager.getInventory ( charID: Cardinal ): TpwEmuPlayerCharacterInventory;
begin
  if ( self._inventorys.TryGetValue( charID, Result )) = false
  then
    Result := nil;
end;

procedure TpwEmuPlayerCharacterInventoryManager.removeInventory ( charID: Cardinal );
var
  inv: TpwEmuPlayerCharacterInventory;
begin
  // free the inventory.

  inv := self.getInventory( charID );

  if ( inv <> nil )
  then
    inv.Free;

  self._inventorys.Remove( charID );
  self._inventorys.TrimExcess;
end;

end.
