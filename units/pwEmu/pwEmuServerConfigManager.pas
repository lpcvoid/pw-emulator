unit pwEmuServerConfigManager;

interface

uses windows, classes, types, swooshMemoryBuffer, serverDecl;

type
  TpwEmuServerConfigManager = class
  private
    FregionTime  : Cardinal;
    FprecinctTime: Cardinal;
    FmallTime1   : Cardinal;
    FmallTime2   : Cardinal;
    FworldTag    : Cardinal;

  public
    property regionTime  : Cardinal read FregionTime write FregionTime;
    property precinctTime: Cardinal read FprecinctTime write FprecinctTime;
    property mallTime1   : Cardinal read FmallTime1 write FmallTime1;
    property mallTime2   : Cardinal read FmallTime2 write FmallTime2;
    property worldTag    : Cardinal read FworldTag write FworldTag;

    constructor Create ( worldTag, regionTime, precinctTime, mallTime1, mallTime2: Cardinal );

    function marshall: TMarshallResult;

  end;

implementation

constructor TpwEmuServerConfigManager.Create ( worldTag, regionTime, precinctTime, mallTime1, mallTime2: Cardinal );
begin
  self.FregionTime := regionTime;
  self.FprecinctTime := precinctTime;
  self.FmallTime1 := mallTime1;
  self.FmallTime2 := mallTime2;
  self.FworldTag := worldTag;
end;

function TpwEmuServerConfigManager.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
begin
  buf := TswooshMemoryBuffer.Create;

  buf.WriteData( self.worldTag );
  buf.WriteData( self.regionTime );
  buf.WriteData( self.precinctTime );
  buf.WriteData( self.mallTime1 );
  buf.WriteData( self.mallTime2 );

  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

end.
