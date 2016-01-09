unit pwEmuPlayerCharacterInventory;

interface

uses windows, types, classes, pwEmuItemBase, System.Generics.Collections;

type
  TpwEmuPlayerCharacterInventory = class
  public
    constructor Create;
    destructor Destroy; override;
    procedure setInvSize( size: cardinal );
    procedure addItem ( item: TpwEmuItemBase );
    procedure setItem ( item: TpwEmuItemBase; slot: cardinal );
    procedure removeItem ( slot: cardinal );
    procedure splitStack ( sourceItemIndex, destItemIndex, amount: cardinal );
    procedure swapItems ( sourceItemIndex, destItemIndex: cardinal );

  private
    _slots: TList< TpwEmuItemBase >;

  end;

implementation

constructor TpwEmuPlayerCharacterInventory.Create;
begin
  self._slots := TList< TpwEmuItemBase >.Create;
end;

destructor TpwEmuPlayerCharacterInventory.Destroy;
var
  I: Integer;
begin
  for I := 0 to self._slots.Count - 1 do
    if ( self._slots.Items[ I ] <> nil )
    then
      self._slots.Items[ I ].Free;
  self._slots.Free;
end;

/// <remarks>
/// Sets the size of the inventory. Mandatory before use!
/// </remarks>

procedure TpwEmuPlayerCharacterInventory.setInvSize( size: cardinal );
begin
  self._slots.Count := size;
end;

/// <remarks>
/// Simply adds and item to the inventory. Index is incremented.
/// </remarks>

procedure TpwEmuPlayerCharacterInventory.addItem ( item: TpwEmuItemBase );
begin
  self._slots.Add( item );
end;

procedure TpwEmuPlayerCharacterInventory.removeItem ( slot: cardinal );
begin

  // No out of bounds for you, faggot
  if ( slot >= self._slots.Count )
  then
    Exit;

  // Does it even exist?
  if ( self._slots.Items[ slot ] = nil )
  then
    Exit;

  self._slots.Items[ slot ].Free;

  self._slots.Items[ slot ] := nil;

end;

/// <remarks>
/// This sets an item to a certain slot. Caution : <b>OVERWRITES!</b>
/// </remarks>

procedure TpwEmuPlayerCharacterInventory.setItem ( item: TpwEmuItemBase; slot: cardinal );
begin
  // No out of bounds for you, nigger
  if ( slot >= self._slots.Count )
  then
    Exit;

  // Item exists? Overwrite!
  if ( self._slots.Items[ slot ] <> nil )
  then
    self._slots.Items[ slot ].Free;

  self._slots.Items[ slot ] := item;

end;

/// <remarks>
/// This simply swaps two items. Doesn't matter what type of ID they are.
/// </remarks>

procedure TpwEmuPlayerCharacterInventory.swapItems ( sourceItemIndex, destItemIndex: cardinal );
begin

  // Is player trying to provoke out of bounds error? :(
  if ( sourceItemIndex >= self._slots.Count ) or ( destItemIndex >= self._slots.Count )
  then
    Exit;

  // let's switch.
  self._slots.Exchange( sourceItemIndex, destItemIndex );

end;

/// <remarks>
/// Splits a stack. Checks for same item, empty dest stack, etc. Safe under every circumstance.
/// </remarks>

procedure TpwEmuPlayerCharacterInventory.splitStack ( sourceItemIndex, destItemIndex, amount: cardinal );
var
  destItem, srcItem: TpwEmuItemBase;
begin

  // Bro do you even lift?
  if amount < 1
  then
    Exit;

  // Is player trying to provoke out of bounds error? :(
  if ( sourceItemIndex >= self._slots.Count ) or ( destItemIndex >= self._slots.Count )
  then
    Exit;

  // dest can be nil, since possibly it can't exist (empty slot). Src must not be nil though.
  if ( self._slots.Items[ sourceItemIndex ] <> nil )
  then
    Exit;

  srcItem := self._slots.Items[ sourceItemIndex ];

  // Can the player move this amount?
  if ( amount > ( srcItem.Count ))
  then
    Exit;

  // If the dest doesn't exist yet, and player has the actual amount of items (checked prior) let's create it.
  if ( self._slots.Items[ destItemIndex ] = nil )
  then
  begin
    destItem := TpwEmuItemBase.Create;
    destItem := srcItem.Clone;
    // But of course we set the count to 0 then ;)
    destItem.Count := 0;
    destItem.maxCount := 1000;
    // add the item to inventory.
    self._slots.Items[ destItemIndex ] := destItem;
  end
  else
    destItem := self._slots.Items[ destItemIndex ];

  // would a split to dest make dest item stack larger then its maxCount?
  if ( amount + destItem.Count > destItem.maxCount )
  then
    Exit;

  // Is player attempting to split stack with same item?
  if destItem.id <> srcItem.id
  then
  begin
    // Okay, then we just swap it for him and exit.
    self.swapItems( sourceItemIndex, destItemIndex );
    Exit;
  end;



  // All seems to be fine, let's do it.

  srcItem.Count := srcItem.Count - amount;
  destItem.Count := destItem.Count + amount;

  // Done!!

end;

end.
