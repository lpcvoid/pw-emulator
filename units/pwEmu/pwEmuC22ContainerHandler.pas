unit pwEmuC22ContainerHandler;

interface

uses windows, swooshPacket, System.Generics.Collections, classes, sysutils, pwEmuWorldManager, serverDecl;

type
  TpwEmuC22ContainerHandler = class
  public
    constructor Create( worldMan: TpwEmuWorldManager; config: TbigServerConfig );
    function handleC22 (packet : TInternalSwooshPacket) : integer;

  private
    _config  : TbigServerConfig;
    _worldMan: TpwEmuWorldManager;
  end;

implementation

constructor TpwEmuC22ContainerHandler.Create( worldMan: TpwEmuWorldManager; config: TbigServerConfig );
begin
  self._config := config;
  self._worldMan := worldMan;

end;

function TpwEmuC22ContainerHandler.handleC22 (packet : TInternalSwooshPacket) : integer;
var
   pckLen : Cardinal;
   opcode : word;
begin
  result := 0; //number of parsed C22 subpackets.
  if (packet.ReadCUInt = $22) then
  begin
       pckLen := packet.ReadCUInt;

       while packet.EOF = false do
       begin

            opcode := packet.ReadWord;

            case opcode of





            end;




       end;





  end;
end;


end.
