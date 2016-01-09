unit dbWhiteboxTest;

interface

uses
  windows, swooshPacketQueue, classes, swooshPacket, System.SysUtils;

type
  TdbWhiteboxTest = class
    constructor Create;
    function selfTest: integer;

  private
    spq: TSwooshPacketQueue;
  end;

implementation

constructor TdbWhiteboxTest.Create( );
begin
  self.spq := TSwooshPacketQueue.Create( 100 );
end;

function TdbWhiteboxTest.selfTest: integer;
var
  sp     : TSwooshPacket;
  spqTest: boolean;
  i, a   : integer;
begin
  try
    // sleep(50);  //just for breakpoint
    for a := 0 to 99 do
    begin
      // sleep(50);  //just for breakpoint
      // swooshqueue!
      for i := 0 to 99 do
      begin
        sp := TSwooshPacket.Create( );
        sp.WriteCUInt( i + a );
        self.spq.addPacket( sp );
      end;

      // test the queue contents!
      for i := 0 to 99 do
      begin
        spqTest := true;
        sp := TSwooshPacket( self.spq.getPacket );
        if ( a + i ) <> sp.ReadCUInt
        then
        begin
          spqTest := false;
          sp.Free;
          break;
        end;
        sp.Free;
      end;

      if spqTest = false
      then
        break;

      // sleep(50);  //just for breakpoint
    end;

    if spqTest
    then
      result := 0
    else
    begin
      result := 1;
    end;

  except
    result := - 1;
  end;

end;

end.
