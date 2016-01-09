unit pwEmuWorldManagerDataExchangeClasses;

interface

uses windows, System.SysUtils, System.Types, System.Classes, serverDecl,
  pwEmuPlayerCharacterEquipment, pwEmuDataTypes, swooshMemoryBuffer, pwEmuItemBase, swooshPacket;

/// <remarks>
/// SimpleRoleInfo. Packet type S_00_26
/// <PacketInfo Type="0x26" Direction="S2C" Container="True" Name="RoleInfoUpdate">
/// <PacketField Type="Dword" Name="Level" />
/// <PacketField Type="Dword" Name="HP Current" />
/// <PacketField Type="Dword" Name="HP Max" />
/// <PacketField Type="Dword" Name="MP Current" />
/// <PacketField Type="Dword" Name="MP Max" />
/// <PacketField Type="Dword" Name="Current Exp" />
/// <PacketField Type="Dword" Name="Current Spirit" />
/// <PacketField Type="Dword" Name="Vigor Current" />
/// <PacketField Type="Dword" Name="Vigor Max" />
/// </PacketInfo>
/// </remarks>
type
  TSimpleRoleUpdateInfo_26 = class
  private
    FLevel        : cardinal;
    FHPCurrent    : cardinal;
    FHPMax        : cardinal;
    FMPCurrent    : cardinal;
    FMPMax        : cardinal;
    FCurrentSpirit: cardinal;
    FCurrentExp   : cardinal;
    FChiCurrent   : cardinal;
    FChimax       : cardinal;

  const
    _packetType = $0026;

  public
    property Level        : cardinal read FLevel write FLevel;
    property HPCurrent    : cardinal read FHPCurrent write FHPCurrent;
    property HPMax        : cardinal read FHPMax write FHPMax;
    property MPCurrent    : cardinal read FMPCurrent write FMPCurrent;
    property MPMax        : cardinal read FMPMax write FMPMax;
    property ExpCurrent   : cardinal read FCurrentExp write FCurrentExp;
    property SpiritCurrent: cardinal read FCurrentSpirit write FCurrentSpirit;
    property ChiCurrent   : cardinal read FChiCurrent write FChiCurrent;
    property Chimax       : cardinal read FChimax write FChimax;
    // I/O
    function marshall: TMarshallResult;

  end;

type
  TRoleUnknownInfo_08 = class
  private
    Fexp        : cardinal;
    Fsp         : cardinal;
    Froleid     : cardinal;
    Fposition   : TPoint3D;
    Fangle      : byte;
    FinFaction  : byte;
    Ffactionid  : cardinal;
    FfactionRank: byte;

  const
    _packetType = $8;

  public
    property exp        : cardinal read Fexp write Fexp;
    property sp         : cardinal read Fsp write Fsp;
    property roleid     : cardinal read Froleid write Froleid;
    property position   : TPoint3D read Fposition write Fposition;
    property angle      : byte read Fangle write Fangle;
    property inFaction  : byte read FinFaction write FinFaction;
    property factionid  : cardinal read Ffactionid write Ffactionid;
    property factionRank: byte read FfactionRank write FfactionRank;

    function marshall: TMarshallResult;
  end;

  (*
   int                        roleid;               /*     4     4 */
   unsigned char              gender;               /*     8     1 */
   unsigned char              race;                 /*     9     1 */
   unsigned char              occupation;           /*    10     1 */
   int                        level;                /*    12     4 */
   int                        level2;               /*    16     4 */
   struct Octets              name;                 /*    20     8 */
   struct Octets              custom_data;          /*    28     8 */
   GRoleInventoryVector       equipment;            /*    36    16 */
   char                       status;               /*    52     1 */
   int                        delete_time;          /*    56     4 */
   int                        create_time;          /*    60     4 */
   int                        lastlogin_time;       /*    64     4 */
   float                      posx;                 /*    68     4 */
   float                      posy;                 /*    72     4 */
   float                      posz;                 /*    76     4 */
   int                        worldtag;             /*    80     4 */
   struct Octets              custom_status;        /*    84     8 */
   struct Octets              charactermode;        /*    92     8 */
   int                        referrer_role;        /*   100     4 */
   int                        cash_add;             /*   104     4 */
  *)

type
  TRoleInfo = Class
  private
    Froleid       : DWORD;
    Fgender       : byte;
    Frace         : byte;
    Foccupation   : byte;
    FLevel        : DWORD;
    Fclutivation  : DWORD;
    Fnamelen      : byte;
    Fname         : widestring;
    Fcustom_data  : TOctets;
    FequipCount   : DWORD;
    Fequip        : TpwEmuPlayerCharacterEquipment;
    Fstatus       : byte;
    FdeleteTime   : cardinal;
    FcreateTime   : cardinal;
    FlastLoginTime: cardinal;
    Fposition     : TPoint3D;
    FworldID      : cardinal;
    Fcustom_status: TOctets;
    FcharacterMode: TOctets;
    Freferrer_role: cardinal;
    Fcash_add     : cardinal;
    FaccountID    : cardinal;

  public
    property roleid       : DWORD read Froleid write Froleid;
    property gender       : byte read Fgender write Fgender;
    property race         : byte read Frace write Frace;
    property occupation   : byte read Foccupation write Foccupation;
    property Level        : DWORD read FLevel write FLevel;
    property clutivation  : DWORD read Fclutivation write Fclutivation;
    property namelen      : byte read Fnamelen write Fnamelen;
    property name         : widestring read Fname write Fname;
    property custom_data  : TOctets read Fcustom_data write Fcustom_data;
    property equipCount   : DWORD read FequipCount write FequipCount;
    property equip        : TpwEmuPlayerCharacterEquipment read Fequip write Fequip;
    property status       : byte read Fstatus write Fstatus; // 0 = hide from list ; 1 = okay; 2 = delete instant ; 3 = delete based on delete time
    property deleteTime   : cardinal read FdeleteTime write FdeleteTime;
    property createTime   : cardinal read FcreateTime write FcreateTime;
    property lastLoginTime: cardinal read FlastLoginTime write FlastLoginTime;
    property position     : TPoint3D read Fposition write Fposition;
    property worldID      : cardinal read FworldID write FworldID;
    property custom_status: TOctets read Fcustom_status write Fcustom_status;
    property characterMode: TOctets read FcharacterMode write FcharacterMode;
    property referrer_role: cardinal read Freferrer_role write Freferrer_role;
    property cash_add     : cardinal read Fcash_add write Fcash_add;

    // Additional
    property accountID: cardinal read FaccountID write FaccountID;

    function marshall ( roleList: boolean ): TMarshallResult;
    procedure unMarshall ( packet: TInternalSwooshPacket );
    constructor Create;
  end;

type
  TRolelist_re_53 = class
  private
    FnextSlot    : DWORD;
    FaccountID   : DWORD;
    FconnectionID: DWORD;
    FisChar      : byte;
    FroleInfo    : TRoleInfo;

  public

    property nextSlot    : DWORD read FnextSlot write FnextSlot;
    property accountID   : DWORD read FaccountID write FaccountID;
    property connectionID: DWORD read FconnectionID write FconnectionID;
    property isChar      : byte read FisChar write FisChar;
    property roleInfo    : TRoleInfo read FroleInfo write FroleInfo;

    function marshall: TMarshallResult;

    constructor Create ( emptyFF: boolean );

  const
    _packetType = $53;
  end;

implementation

/// <remarks>
/// Represents one pwServer  struct RoleInfo.
/// Used in : Rolelist; CreateCharRequest + response; etc...
/// </remarks>

constructor TRoleInfo.Create;
begin

  self.equip := TpwEmuPlayerCharacterEquipment.Create; // 2. constructor here
  self.roleid := 0;
  self.gender := 0;
  self.race := 0;
  self.occupation := 0;
  self.Level := 0;
  self.clutivation := 0;
  self.namelen := 0;
  self.equipCount := 0;
  self.status := 0;
  self.deleteTime := 0;
  self.createTime := 0;
  self.lastLoginTime := 0;
  self.worldID := 0;
  self.cash_add := 0;
end;

/// <remarks>
/// Unmarshalls (reads) a packet into roleIndo data.
/// </remarks>

procedure TRoleInfo.unMarshall ( packet: TInternalSwooshPacket );
begin
  self.roleid := packet.readDWORD_BE;
  self.gender := packet.ReadByte;
  self.race := packet.ReadByte;
  self.occupation := packet.ReadByte;
  self.Level := packet.readDWORD_BE;
  self.clutivation := packet.readDWORD_BE;
  self.name := packet.ReadWIDEString;
  self.namelen := length( self.name ) * 2; // unicode 2 byte
  self.custom_data := packet.ReadOctets;
  self.equipCount := packet.ReadCUInt;
  // Der rest ist nicht wichtig erstmal, bis ich sehe dass das net richtig ist.

end;

/// <remarks>
/// RoleInfo item struct is fucking big endian in roleList_re packet, hence why the bool argument is needed...
/// True : items are done Big endian; False = good little endian
/// </remarks>

function TRoleInfo.marshall ( roleList: boolean ): TMarshallResult;
var
  buf         : TswooshMemoryBuffer;
  tempItemData: TMarshallResult;
  tempItem    : TpwEmuItemBase;
  i           : integer;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.writeInt_BE( self.Froleid );
  buf.writeByte( self.Fgender );
  buf.writeByte( self.Frace );
  buf.writeByte( self.Foccupation );
  buf.writeInt_BE( self.FLevel );
  buf.writeFloat_BE( self.Fclutivation );
  buf.writeCUInt( self.Fnamelen );
  buf.WriteData(@self.Fname[ 1 ], self.Fnamelen ); // write name
  buf.writeCUInt( self.Fcustom_data.octetLen );
  if ( self.Fcustom_data.octetLen > 0 ) and ( self.Fcustom_data.octetLen = length( self.Fcustom_data.octets ))
  then
    buf.WriteData( @self.Fcustom_data.octets[ 0 ], self.Fcustom_data.octetLen );

  buf.writeCUInt( self.FequipCount );
  if ( self.FequipCount > 0 )
  then
  begin
    // marshall all thingos.
    for i := 0 to self.Fequip.getEquipCount - 1 do
    begin
      tempItem := self.Fequip.getEquipItem( i );
      if ( roleList )
      then
        tempItemData := tempItem.marshall_roleList
      else
        tempItemData := tempItem.marshall;

      // Don't free here... pointers to actual inv!

      buf.WriteData(@tempItemData.data[ 0 ], tempItemData.size );
    end;
  end;

  buf.writeByte( self.status );       // status
  buf.writeInt_BE( self.deleteTime ); // deletetime...
  buf.writeInt_BE( self.FcreateTime );
  buf.writeInt_BE( self.FlastLoginTime );
  buf.writeFloat_BE( self.position.X );
  buf.writeFloat_BE( self.position.Y );
  buf.writeFloat_BE( self.position.Z );
  buf.writeInt_BE( self.FworldID );
  buf.writeOctets( self.custom_status );
  buf.writeOctets( self.characterMode );
  buf.writeInt_BE( self.referrer_role ); // No referrer role.
  buf.writeInt_BE( self.cash_add );      // no cashadd.

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

/// <remarks>
/// Contents of RoleList_53. Missing opcode and len.
/// </remarks>

constructor TRolelist_re_53.Create ( emptyFF: boolean );
begin
  if ( emptyFF = false )
  then
    self.roleInfo := TRoleInfo.Create;
  self.FnextSlot := $FFFFFFFF;
  self.FaccountID := 0;
  self.isChar := 0;
end;

function TRolelist_re_53.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
  mr : TMarshallResult;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.writeInt_BE( 0 ); // Unknown
  buf.writeInt_BE( self.FnextSlot );
  buf.writeInt_BE( self.FaccountID );
  buf.writeInt_BE( self.FaccountID * 2 ); // connection ID, wtf.
  buf.writeByte( self.FisChar );

  if ( self.FisChar = 1 )
  then
  begin
    mr := self.roleInfo.marshall( true );
    buf.WriteData(@mr.data[ 0 ], mr.size );
  end;

  self.roleInfo.Free; // Not needed anymore now

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;

end;

function TSimpleRoleUpdateInfo_26.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.writeWord( _packetType ); // header
  buf.WriteData( self.Level );
  buf.WriteData( self.HPCurrent );
  buf.WriteData( self.HPMax );
  buf.WriteData( self.MPCurrent );
  buf.WriteData( self.MPMax );
  buf.WriteData( self.ExpCurrent );
  buf.WriteData( self.SpiritCurrent );
  buf.WriteData( self.ChiCurrent );
  buf.WriteData( self.Chimax );

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

function TRoleUnknownInfo_08.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.writeWord( _packetType ); // header
  buf.WriteData( self.exp );
  buf.WriteData( self.sp );
  buf.WriteData( self.roleid );
  buf.WriteData( self.position.X );
  buf.WriteData( self.position.Y );
  buf.WriteData( self.position.Z );
  buf.writeWord( 65266 ); // UK
  buf.writeWord( 0 );     // UK
  buf.writeByte( self.angle );
  buf.writeWord( 0 );  // uk
  buf.writeWord( 64 ); // uk
  buf.writeByte( self.inFaction );

  if ( self.inFaction = 1 )
  then
  begin
    buf.WriteData( self.factionid );
    buf.writeByte( self.factionRank );
  end;

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

end.
