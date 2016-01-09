unit uBytes;

interface

uses
  System.SysUtils;

// Compare buffers and return position where bytes differ.
// Result is: -1 if buffers are same; 0 if buffer length is wrong
function CompareBytes(const a, b: TBytes): integer;

// Create bytes from file.
function FileToBytes(const path: string): TBytes;

implementation

function CompareBytes(const a, b: TBytes): integer;
var
  i, len: integer;
begin
  if (length(a) = 0) or (length(b) = 0) then
    exit(0);

  if (length(a) <> length(b)) then
    exit(0);

  if length(a) < length(b) then
    len := length(a)
  else
    len := length(b);

  for i := 0 to len - 1 do
    if a[i] <> b[i] then
      exit(i);

  exit(-1);
end;

function FileToBytes(const path: string): TBytes;
var
  f: file of byte;
begin
  AssignFile(f, path);
  Reset(f);
  SetLength(Result, filesize(f));
  BlockRead(f, Result[0], filesize(f));
  CloseFile(f);
end;

end.
