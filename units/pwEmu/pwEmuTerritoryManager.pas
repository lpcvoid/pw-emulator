unit pwEmuTerritoryManager;

{
 struct GTerritoryDetail : public Data

 public:
 short int                  id;                   /*     4     2 */
 short int                  level;                /*     6     2 */
 unsigned int               owner;                /*     8     4 */
 int                        occupy_time;          /*    12     4 */
 unsigned int               challenger;           /*    16     4 */
 unsigned int               deposit;              /*    20     4 */
 int                        cutoff_time;          /*    24     4 */
 int                        battle_time;          /*    28     4 */
 int                        bonus_time;           /*    32     4 */
 int                        color;                /*    36     4 */
 int                        status;               /*    40     4 */
 int                        timeout;              /*    44     4 */
 int                        maxbonus;             /*    48     4 */
 int                        challenge_time;       /*    52     4 */
 struct Octets              challengerdetails;    /*    56     8 */
 /* --- cacheline 1 boundary (64 bytes) --- */
 char                       reserved1;            /*    64     1 */
 char                       reserved2;            /*    65     1 */
 char                       reserved3;            /*    66     1 */


}

interface

uses classes, windows, types, System.Generics.Collections, serverDecl, swooshMemoryBuffer;

type
  TTWLand = class
  private
    Fid        : byte;
    Flevel     : byte;
    Fcolor     : byte;
    Fowner     : Cardinal;
    Fattacker  : Cardinal;
    Fbattletime: Cardinal;
    Fdeposit   : Cardinal;
    FmaxBonus  : Cardinal;

  public
    property id        : byte read Fid write Fid;
    property level     : byte read Flevel write Flevel;
    property color     : byte read Fcolor write Fcolor;
    property owner     : Cardinal read Fowner write Fowner;
    property attacker  : Cardinal read Fattacker write Fattacker;
    property battletime: Cardinal read Fbattletime write Fbattletime;
    property deposit   : Cardinal read Fdeposit write Fdeposit;
    property maxBonus  : Cardinal read FmaxBonus write FmaxBonus;

    constructor Create ( id: byte );

  end;

type
  TpwEmuTerritoryManager = class
  public
    constructor Create ( config: TbigServerConfig );
    procedure addLand ( land: TTWLand );
    function marshall: TMarshallResult;

  private
    _config   : TbigServerConfig;
    _lands    : TList< TTWLand >;
    _landCount: Cardinal;
  end;

implementation

constructor TTWLand.Create ( id: byte );
begin
  self.id := id;
end;

constructor TpwEmuTerritoryManager.Create( config: TbigServerConfig );
var
  i: Integer;
begin
  self._config := config;

  self._landCount := self._config.pwTWLandCount;

  self._lands := TList< TTWLand >.Create;

  for i := 0 to self._landCount - 1 do
    self._lands.Add( TTWLand.Create( i + 1 ) );

end;

procedure TpwEmuTerritoryManager.addLand ( land: TTWLand );
begin
  self._lands.Add( land );
end;

function TpwEmuTerritoryManager.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
  i  : Integer;
begin

  // FUCKING BIG ENDIAN SHIT WHAT THE FUCK GO FUCK YOURSELF WANMEI
  buf := TswooshMemoryBuffer.Create;
  buf.writeWord_BE( 0 ); // retcode
  buf.writeWord_BE( self._config.pwTWMaxBid );
  buf.writeInt_BE( 1 ); // status?
  buf.writeByte( self._landCount );

  if ( self._landCount > 0 )
  then
    for i := 0 to self._landCount - 1 do
    begin
      buf.writeByte( self._lands[ i ].id );
      buf.writeByte( self._lands[ i ].level );
      buf.writeByte( self._lands[ i ].color );
      buf.writeInt_BE( self._lands[ i ].owner );
      buf.writeInt_BE( self._lands[ i ].attacker );
      buf.writeInt_BE( self._lands[ i ].battletime );
      buf.writeInt_BE( self._lands[ i ].deposit );
      buf.writeInt_BE( self._lands[ i ].maxBonus );
    end;
  buf.writeInt_BE( self._config.pwTWBonusItemID );
  buf.writeInt_BE( self._config.pwTWBonusCount1 );
  buf.writeInt_BE( self._config.pwTWBonusCount2 );
  buf.writeInt_BE( self._config.pwTWBonusCount3 );
  buf.writeInt_BE( 94 ); // connection ID, wtf

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

end.
