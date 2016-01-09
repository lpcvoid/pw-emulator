{


 Represents a single friend list of one character.


}

/// <author>Swoosh Copyright 2013</author>
/// <remarks>
/// pwEmu Friend list representation.
/// </remarks>
unit pwEmuFriendList;

interface

uses windows, System.Types, System.classes, System.Generics.Collections, serverDecl, swooshMemoryBuffer;

type
  TpwEmuFriend = class
  private
    Froleid  : cardinal;
    Fjob     : byte;
    FgroupID : byte;
    FcharName: widestring;

  public
    property roleid  : cardinal read Froleid write Froleid;
    property job     : byte read Fjob write Fjob;
    property groupID : byte read FgroupID write FgroupID;
    property charName: widestring read FcharName write FcharName;

  end;

type
  TpwEmuFriendGroup = class
  private
    FgroupID  : byte;
    FgroupName: widestring;

  public
    property groupID  : byte read FgroupID write FgroupID;
    property groupName: widestring read FgroupName write FgroupName;
  end;

type
  TpwEmuFriendList = class
  public
    constructor Create ( roleid: cardinal );
    destructor Destroy; override;
    procedure addFriend ( friend: TpwEmuFriend );
    procedure addGroup ( group: TpwEmuFriendGroup );
    function marshall: TMarshallResult;

  private
    _friends  : TList< TpwEmuFriend >;
    _groups   : TList< TpwEmuFriendGroup >;
    _roleid   : cardinal;
    _cristsect: TRTLCriticalSection;

  end;

implementation

constructor TpwEmuFriendList.Create ( roleid: cardinal );
begin
  self._friends := TList< TpwEmuFriend >.Create;
  self._groups := TList< TpwEmuFriendGroup >.Create;
  InitializeCriticalSection( self._cristsect );
end;

destructor TpwEmuFriendList.Destroy;
begin
  self._friends.Free;
  self._groups.Free;
  DeleteCriticalSection( self._cristsect );
  inherited;
end;

procedure TpwEmuFriendList.addFriend ( friend: TpwEmuFriend );
begin

  try
    EnterCriticalSection( self._cristsect );
    self._friends.Add( friend );
  finally
    LeaveCriticalSection( self._cristsect );
  end;

end;

procedure TpwEmuFriendList.addGroup ( group: TpwEmuFriendGroup );
begin
  try
    EnterCriticalSection( self._cristsect );
    self._groups.Add( group );
  finally
    LeaveCriticalSection( self._cristsect );
  end;
end;

function TpwEmuFriendList.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
  i  : integer;
begin
  try
    EnterCriticalSection( self._cristsect );
    buf := TswooshMemoryBuffer.Create;
    buf.writeInt_BE( self._roleid );
    buf.writeCUInt( self._groups.Count );

    if ( self._groups.Count > 0 )
    then
      for i := 0 to self._groups.Count - 1 do
      begin
        buf.writeByte( self._groups[ i ].groupID );
        buf.writeWIDEString( self._groups[ i ].groupName );
      end;

    buf.writeCUInt( self._friends.Count );

    if ( self._friends.Count > 0 )
    then
      for i := 0 to self._friends.Count - 1 do
      begin
        buf.writeInt_BE( self._friends[ i ].roleid );
        buf.writeByte( self._friends[ i ].job );
        buf.writeByte( self._friends[ i ].groupID );
        buf.writeWIDEString( self._friends[ i ].charName );
      end;

    // followed by 5 00 bytes, unknown function
    buf.writeInt_BE( 0 );
    buf.writeByte( 0 );

    Result.size := buf.size;
    setlength( Result.data, Result.size );
    CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
    buf.Free;
  finally
    LeaveCriticalSection( self._cristsect );
  end;
end;

end.
