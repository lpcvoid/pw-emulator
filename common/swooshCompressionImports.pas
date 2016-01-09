unit swooshCompressionImports;

interface

const
  COMPRESSION_ENGINE_STANDARD = $00000000;
  COMPRESSION_ENGINE_MAXIMUM  = $00000100;
  COMPRESSION_FORMAT_LZNT1    = $00000002;
  DECOMPRESSION_MULTIPLICATOR = 150;

type
  PULONG = ^ULONG;
  ULONG  = Cardinal;

function RtlGetCompressionWorkSpaceSize( CompressionFormatAndEngine: ULONG; CompressBufferWorkSpaceSize, CompressFragmentWorkSpaceSize: PULONG ): Cardinal; stdcall; external 'ntdll.dll' name 'RtlGetCompressionWorkSpaceSize';
function RtlCompressBuffer( CompressionFormatAndEngine: ULONG; UncompressedBuffer: Pointer; UncompressedBufferSize: ULONG; CompressedBuffer: Pointer; CompressedBufferSize: ULONG; UncompressedChunkSize: ULONG; FinalCompressedSize: PULONG; WorkSpace: Pointer ): Cardinal; stdcall;
    external 'ntdll.dll' name 'RtlCompressBuffer';
function RtlDecompressFragment( CompressionFormat: ULONG; UncompressedFragment: Pointer; UncompressedFragmentSize: ULONG; CompressedBuffer: Pointer; CompressedBufferSize: ULONG; FragmentOffset: ULONG; FinalUncompressedSize: PULONG; WorkSpace: Pointer ): Cardinal; stdcall;
    external 'ntdll.dll' name 'RtlDecompressFragment';

implementation

end.
