unit GNET.Compress;

interface

uses
  Classes;

const
  BUFLEN = 8192;

type
  TGNETCompress = packed record

    // Buffer for compression.
    Hist: array [0 .. BUFLEN - 1] of byte;

    // Hash buffer.
    Hash: array [0 .. BUFLEN - 1] of word;

    // After update is always set back to point to Hist.
    SrcPtr: PByte;

    // Number of bytes starting at offset 0 of Hist which are not yet updated.
    NotUpdatedCount: uint32;

  private

    // Compress internal buffer and return current DstPtr.
    function Compress(DstPtr: PByte; Size: integer): PByte;

  public

    // .text:08270690 GNET::Compress::Compress(void)
    procedure Create();

  end;

implementation

{ TGNETCompress }

function TGNETCompress.Compress(DstPtr: PByte; Size: integer): PByte;
begin
  Result := nil;
end;

procedure TGNETCompress.Create;
begin
  self.SrcPtr := @self.Hist[0];
  self.NotUpdatedCount := 0;
  fillchar(self.Hash, sizeof(self.Hash), 0);
end;

end.
