unit pwEmuCharacterSelectionProtocolHandler;

interface

uses swooshPacket, winsock, windows, pwEmuDataTypes, pwEmuWorldManagerDataExchangeClasses;

type
  TpwEmuCharacterSelectionProtocolHandler = class

    // builder

    function build_s2c_53_RoleList_Re_LastSlot ( accountID: Cardinal; packet: TInternalSwooshPacket ): TInternalSwooshPacket;
    function build_s2c_53_RoleList_Re_Demo ( accountID: Cardinal; packet: TInternalSwooshPacket ): TInternalSwooshPacket;
    function build_s2c_53_RoleList_Re ( accountID: Cardinal; packet: TInternalSwooshPacket ): TInternalSwooshPacket;
    function build_s2c_47_SelectRole_Re ( packet: TInternalSwooshPacket ): TInternalSwooshPacket;

    // parsers
    function parse_c2s_52_RoleList ( packet: TInternalSwooshPacket ): TRoleList_c2s_52;
    function parse_c2s_54_CreateRole_Request ( packet: TInternalSwooshPacket ): TRoleInfo;
    function parse_c2s_48_Enterworld ( packet: TInternalSwooshPacket ): Cardinal;

  end;

implementation

(*

 struct RoleInfo : public Data {
 public:

 /* struct Data                <ancestor>; */     /*     0     0 */

 /* XXX 4 bytes hole, try to pack */

 int                        roleid;               /*     4     4 */
 unsigned char              gender;               /*     8     1 */
 unsigned char              race;                 /*     9     1 */
 unsigned char              occupation;           /*    10     1 */

 /* XXX 1 byte hole, try to pack */

 int                        level;                /*    12     4 */
 int                        level2;               /*    16     4 */
 struct Octets              name;                 /*    20     8 */
 struct Octets              custom_data;          /*    28     8 */
 GRoleInventoryVector       equipment;            /*    36    16 */
 char                       status;               /*    52     1 */

 /* XXX 3 bytes hole, try to pack */

 int                        delete_time;          /*    56     4 */
 int                        create_time;          /*    60     4 */
 /* --- cacheline 1 boundary (64 bytes) --- */
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

function TpwEmuCharacterSelectionProtocolHandler.parse_c2s_54_CreateRole_Request ( packet: TInternalSwooshPacket ): TRoleInfo;
var
  accID: Cardinal;
begin
  result := TRoleInfo.Create;
  accID := packet.readDWORD_BE;
  packet.ReadDWORD;            // local sid?!
  result.unMarshall( packet ); // Only does it half, only important shit
  result.accountID := packet.readDWORD_BE;

end;

/// <remarks>
/// Parse the enterworld packet. Get roleID, only thing we need as far as I can see.
/// </remarks>

function TpwEmuCharacterSelectionProtocolHandler.parse_c2s_48_Enterworld ( packet: TInternalSwooshPacket ): Cardinal;
begin
  packet.ReadCUInt; // opcode
  packet.ReadCUInt; // len
  result := packet.readDWORD_BE; //role id
end;

function TpwEmuCharacterSelectionProtocolHandler.parse_c2s_52_RoleList ( packet: TInternalSwooshPacket ): TRoleList_c2s_52;
begin
  packet.Rewind;
  packet.ReadCUInt; // opcode
  packet.ReadCUInt; // len
  result.accountID := packet.readDWORD_BE;
  result.unknown := packet.readDWORD_BE;
  result.slot := packet.readDWORD_BE;

end;

function TpwEmuCharacterSelectionProtocolHandler.build_s2c_53_RoleList_Re_LastSlot ( accountID: Cardinal; packet: TInternalSwooshPacket )
    : TInternalSwooshPacket;
begin
  result := packet;
  result.Flush;
  result.WriteCUInt( $53 );
  result.WriteCUInt( 17 );
  result.WriteDWORD( 0 );
  result.WriteDWORD( $FFFFFFFF ); // next slot ID = -1
  result.WriteDWORD( accountID );
  result.WriteDWORD( accountID * 2 ); // Connection ID, not sure if important or not.
  result.Writebyte( 0 );              // Ischar = false
end;

function TpwEmuCharacterSelectionProtocolHandler.build_s2c_53_RoleList_Re ( accountID: Cardinal; packet: TInternalSwooshPacket ): TInternalSwooshPacket;
begin
  result := packet;
  result.Flush;

end;

function TpwEmuCharacterSelectionProtocolHandler.build_s2c_53_RoleList_Re_Demo ( accountID: Cardinal; packet: TInternalSwooshPacket ): TInternalSwooshPacket;
begin
  result := packet;
  result.Flush;
  result.WriteCUInt( $53 );
  result.WriteCUInt( 100 );
  result.WriteDWORD( 0 );
  result.WriteDWORD( $FFFFFFFF ); // next slot ID = -1
  result.WriteDWORD_BE( accountID );
  result.WriteDWORD_BE( accountID * 2 ); // Connection ID, not sure if important or not.
  result.Writebyte( 1 );                 // Ischar = false
  result.WriteDWORD_BE( 1104 );          // CharID //BIG ENDIAN
  result.Writebyte( 1 );                 // sex 1 = w
  result.Writebyte( 2 );                 // race
  result.Writebyte( 5 );                 // occupation
  result.WriteDWORD_BE( 15 );            // level
  result.WriteDWORD( 0 );
  result.WriteWIDEString( 'SwooshEmuTest' );
  result.WriteOctets( nil, 0 );       // no custom data, works? Works!
  result.WriteCUInt( 0 );             // no equip!
  result.WriteDWORD( 1 );             // little endian, for whatever fucking reason, unknown
  result.Writebyte( 0 );              // uk
  result.WriteDWORD_BE( 1356463883 ); // 25.12.2012 19:31:23
  result.WriteDWORD_BE( 1360028773 ); // 05.02.2013 01:46:13
  result.WriteDWORD( 4221214276 );    // coordinate X
  result.WriteDWORD( 2093046595 );    // coordinate Y
  result.WriteDWORD( 2500363076 );    // coordinate Z
  result.WriteDWORD_BE( 1 );          // worldID
  result.WriteWord( 0 );              // uk
  result.WriteDWORD( $FFFFFFFF );     // uk
  result.WriteDWORD( 0 );             // uk
end;

function TpwEmuCharacterSelectionProtocolHandler.build_s2c_47_SelectRole_Re ( packet: TInternalSwooshPacket ): TInternalSwooshPacket;
const
  selectRole_Re: array [ 0 .. 37 ] of byte = ( $00, $00, $00, $00, $21, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $64, $65, $66, $67, $68,
      $69, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF, $D0, $D1, $D2, $D3, $D4, $D5, $D6 );
begin
  result := packet;
  result.Flush;
  result.WriteCUInt( $47 );
  result.WriteOctets(@selectRole_Re[ 0 ], Length( selectRole_Re ));

end;

end.
