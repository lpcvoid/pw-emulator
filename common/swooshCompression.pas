unit swooshCompression;

interface

uses windows, swooshCompressionImports;

type
  TSwooshCompression = class
    constructor Create;
    function Compress( const Source: Pointer; Dest: Pointer; Count: Cardinal ): Cardinal;
    function Decompress( const Source: Pointer; Dest: Pointer; Count: Cardinal ): Cardinal;

  private
    Compression: Cardinal; // mode
  end;

implementation

constructor TSwooshCompression.Create;
begin
  self.Compression := COMPRESSION_FORMAT_LZNT1 or COMPRESSION_ENGINE_MAXIMUM;

end;

function TSwooshCompression.Compress( const Source: Pointer; Dest: Pointer; Count: Cardinal ): Cardinal;
var
  WorkSpace               : Pointer;
  WorkSpaceSize, ChunkSize: Cardinal;
begin
  Result := 0;
  RtlGetCompressionWorkSpaceSize( Compression, @WorkSpaceSize, @ChunkSize );
  GetMem( Dest, Count );
  GetMem( WorkSpace, WorkSpaceSize );
  RtlCompressBuffer( Compression, Source, Count, Dest, Count, ChunkSize, @Result, WorkSpace );
  FreeMem( WorkSpace );
  if Result = 0
  then
  begin
    Move( Source^, Dest^, Count );
    Result := Count;
  end
  else
    ReallocMem( Dest, Result );
end;

function TSwooshCompression.Decompress( const Source: Pointer; Dest: Pointer; Count: Cardinal ): Cardinal;
var
  WorkSpace                                  : Pointer;
  WorkSpaceSize, ChunkSize, BytesDecompressed: Cardinal;
begin
  Result := 0;
  BytesDecompressed := 0;
  RtlGetCompressionWorkSpaceSize( COMPRESSION_FORMAT_LZNT1, @WorkSpaceSize, @ChunkSize );
  GetMem( WorkSpace, WorkSpaceSize );
  ChunkSize := Count * DECOMPRESSION_MULTIPLICATOR div 100;
  New( Dest );
  repeat
    ReallocMem( Dest, Result + ChunkSize );
    RtlDecompressFragment( COMPRESSION_FORMAT_LZNT1, Pointer( Cardinal( Dest ) + Result ), ChunkSize, Source, Count, Result, @BytesDecompressed, WorkSpace );
    if BytesDecompressed <= ChunkSize
    then
      Inc( Result, BytesDecompressed );
  until BytesDecompressed <> ChunkSize;
  FreeMem( WorkSpace );
  if Result = 0
  then
  begin
    Move( Source^, Dest^, Count );
    Result := Count;
  end
  else
    ReallocMem( Dest, Result );
end;

end.
