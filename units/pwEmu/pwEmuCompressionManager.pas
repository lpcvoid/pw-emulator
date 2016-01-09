unit pwEmuCompressionManager;

interface

uses swooshMPPC, swooshPacket, windows, System.SysUtils, types, classes, System.Generics.Collections;

type
  TpwEmuCompressionManager = class
  public
    constructor Create;

    function compressPacket ( cid: integer; thePacket: TInternalSwooshPacket ): TInternalSwooshPacket;
    function needsCompression ( cid: integer ): Boolean;
    procedure removeCompressor ( cid: integer );
    procedure addCompressor ( cid: integer );

  private
    _compressors: TDictionary< integer, TSwooshMPPC >;

  end;

implementation

constructor TpwEmuCompressionManager.Create;
begin
  self._compressors := TDictionary< integer, TSwooshMPPC >.Create;
end;

function TpwEmuCompressionManager.needsCompression ( cid: integer ): Boolean;
begin
  result := self._compressors.ContainsKey( cid );
end;

function TpwEmuCompressionManager.compressPacket ( cid: integer; thePacket: TInternalSwooshPacket ): TInternalSwooshPacket;
var
  tempC: TSwooshMPPC;
begin

  if self._compressors.TryGetValue( cid, tempC )
  then
    result := tempC.compressPacket( thePacket );

end;

procedure TpwEmuCompressionManager.removeCompressor ( cid: integer );
var
  tempC: TSwooshMPPC;
begin
  if self._compressors.TryGetValue( cid, tempC )
  then
  begin
    tempC.Free;
    self._compressors.Remove( cid );
  end;
end;

procedure TpwEmuCompressionManager.addCompressor ( cid: integer );
begin
  // Remove old one first if needed!
  if ( self.needsCompression( cid ))
  then
    self.removeCompressor( cid );

  self._compressors.Add( cid, TSwooshMPPC.Create );
end;

end.
