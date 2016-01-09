unit pwEmuS00ContainerBuilder;

interface

uses windows, types, classes, swooshMemoryBuffer, serverDecl;

type
  TpwEmuS00ContainerBuilder = class( TswooshMemoryBuffer )
  public
    constructor Create;
    procedure addSubPacket ( marshalledPacket: TMarshallResult );
    function finalizeContainer: TMarshallResult;
    procedure resetContainer;

  private
    dataSize: Cardinal;

  end;

implementation

constructor TpwEmuS00ContainerBuilder.Create;
begin
  inherited Create;
  self.resetContainer;
end;

procedure TpwEmuS00ContainerBuilder.resetContainer;
begin
  self.Clear;
end;

procedure TpwEmuS00ContainerBuilder.addSubPacket ( marshalledPacket: TMarshallResult );
begin

  {
   -0x22
   -length of subpacket block
   -length of subpacket (above -1)
   -data (opcode = word)
  }

  self.writeCUInt( $22 );                       // Seperator
  self.writeCUInt( marshalledPacket.size + 1); // length of subpacketblock
  self.writeCUInt( marshalledPacket.size );
  self.WriteData(@marshalledPacket.data[ 0 ], marshalledPacket.size );
end;

function TpwEmuS00ContainerBuilder.finalizeContainer: TMarshallResult;
var
  finalBuf: TswooshMemoryBuffer;
begin
  finalBuf := TswooshMemoryBuffer.Create;
  finalBuf.writeCUInt( 0 );             // S_00 container
  finalBuf.writeCUInt( self.Size ); // S_00_comntainer size

  if (self.Size > 0) then
  begin
    finalBuf.WriteData(self.Memory,self.Size);
  end;

  result.size := finalBuf.Size;
  setlength(Result.data,result.size);
  CopyMemory(@result.data[0],finalBuf.Memory,Result.size);
  finalBuf.Free;
end;

end.
