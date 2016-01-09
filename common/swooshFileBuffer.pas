unit swooshFileBuffer;

interface

uses windows, classes, System.SysUtils, serverDecl, math;

type
  TSwooshFileBuffer = class
  public
    constructor Create( path: string );

    function readFloat: Single;
    function readWord: word;
    function readInt: Integer;
    function readBoolean: boolean;
    function readbyte: byte;
    function readWideString ( len: Cardinal ): String;
    procedure readRawDataFloat( len: Cardinal; var rawData: TRawDataFloat );
    procedure readRawData( len: Cardinal; var rawData: TRawData );
    procedure readPointerData( ptr: Pointer; len: Cardinal );

    function getFileSize: DWORD;
    procedure setPosition ( pos: int64 );

    destructor Destroy; override;

  private
    _fs: TFileStream;
  end;

implementation

constructor TSwooshFileBuffer.Create( path: string );
begin
  if FileExists( path )
  then
    self._fs := TFileStream.Create( path, fmOpenReadWrite )
  else
  begin
    self._fs := TFileStream.Create( path, fmCreate );
  end;
end;

destructor TSwooshFileBuffer.Destroy;
begin
  self._fs.Position := 0;
  self._fs.Free;
end;

function TSwooshFileBuffer.getFileSize: DWORD;
begin
  result := self._fs.Size;
end;

procedure TSwooshFileBuffer.setPosition ( pos: int64 );
begin
  self._fs.Position := pos;
end;

procedure TSwooshFileBuffer.readPointerData( ptr: Pointer; len: Cardinal );
begin
  self._fs.ReadData( ptr, len );
end;

procedure TSwooshFileBuffer.readRawDataFloat( len: Cardinal; var rawData: TRawDataFloat );
begin
  self._fs.ReadBuffer( rawData[ 0 ], len );
end;

procedure TSwooshFileBuffer.readRawData( len: Cardinal; var rawData: TRawData );
begin
  self._fs.ReadBuffer( rawData[ 0 ], len );
end;

function TSwooshFileBuffer.readWideString ( len: Cardinal ): String;
begin
  self._fs.ReadBuffer( result[ 1 ], len * 2 );
end;

function TSwooshFileBuffer.readWord: word;
begin
  self._fs.Read( result, 2 );
end;

function TSwooshFileBuffer.readbyte: byte;
begin
  self._fs.Read( result, 1 );
end;

function TSwooshFileBuffer.readBoolean: boolean;
begin
  self._fs.Read( result, 1 );
end;

function TSwooshFileBuffer.readFloat: Single;
begin

  self._fs.ReadBuffer( result, 4 );

  if IsNan( result )
  then
    result := 0.0;

end;

function TSwooshFileBuffer.readInt: Integer;
begin
  self._fs.Read( result, 4 );
end;

end.
