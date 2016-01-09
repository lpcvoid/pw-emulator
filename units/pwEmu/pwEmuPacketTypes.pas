unit pwEmuPacketTypes;

interface

uses serverDecl;

type
  TC2S_LoginRequest_03 = packed record
    Opcode : Byte;
    PacketLength : Byte;
    UserLogin : ansistring;
    HashLength : Byte;
    Hash : THashKey;
    ForceLogin : Byte;
end;

type
  TS2C_KeyExchange_02 = packed record
    Opcode : Byte;
    PacketLength : Byte;
    Keylength : Byte;
    Key : THashKey;
    ForceLogin : Byte;
  end;

type
  TC2S_KeyExchange_02 = packed record
    Opcode : Byte;
    PacketLength : Byte;
    Keylength : Byte;
    Key : THashKey;
    ForceLogin : Byte;
  end;


implementation

end.
