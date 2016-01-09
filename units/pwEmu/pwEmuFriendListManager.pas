unit pwEmuFriendListManager;

interface

uses Winapi.Windows, System.Generics.Collections, types, classes, pwEmuFriendList;

type
  TpwEmuFriendListManager = class
  public
    constructor Create;
    procedure addFriendList ( roleid: cardinal; fl: TpwEmuFriendList );
    procedure removeFriendList ( roleid: cardinal );
    function getFriendList ( roleid: cardinal ): TpwEmuFriendList;
    function friendListExists ( roleid: cardinal ): boolean;

  private
    /// Roleid, friendlist
    _friendLists: TDictionary< cardinal, TpwEmuFriendList >;
  end;

implementation

constructor TpwEmuFriendListManager.Create;
begin
  self._friendLists := TDictionary< cardinal, TpwEmuFriendList >.Create;
end;

procedure TpwEmuFriendListManager.addFriendList ( roleid: cardinal; fl: TpwEmuFriendList );
begin
  self._friendLists.Add( roleid, fl );
end;

procedure TpwEmuFriendListManager.removeFriendList ( roleid: cardinal );
begin
  // exists? Then free first.
  if ( self._friendLists.ContainsKey( roleid ))
  then
    self._friendLists.Items[ roleid ].Free;

  self._friendLists.Remove( roleid );
end;

function TpwEmuFriendListManager.getFriendList ( roleid: cardinal ): TpwEmuFriendList;
begin
  if ( self._friendLists.ContainsKey( roleid ))
  then
    self._friendLists.TryGetValue( roleid, result );
end;

function TpwEmuFriendListManager.friendListExists ( roleid: cardinal ): boolean;
begin
  result := self._friendLists.ContainsKey( roleid );
end;

end.
