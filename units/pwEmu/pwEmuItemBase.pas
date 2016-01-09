unit pwEmuItemBase;

interface

uses windows, types, classes, serverdecl, pwEmuDataTypes, swooshMemoryBuffer;

(*

 unsigned int               id;                   /*     4     4 */
 int                        pos;                  /*     8     4 */
 int                        count;                /*    12     4 */
 int                        max_count;            /*    16     4 */
 struct Octets              data;                 /*    20     8 */
 int                        proctype;             /*    28     4 */
 int                        expire_date;          /*    32     4 */
 int                        guid1;                /*    36     4 */
 int                        guid2;                /*    40     4 */
 int                        mask;                 /*    44     4 */

*)

type
  TpwEmuItemBase = class
  private
    _id        : cardinal;
    _count     : cardinal;
    _maxCount  : cardinal;
    _name      : WideString; // Also not needed, just sugar
    _slot      : Cardinal;   // Can be set by inventory handling class. //TpwEmuEquipmentIndex
    _proctype  : cardinal;
    _mask      : cardinal;
    _octets    : TOctets;
    _expireDate: cardinal;
    Fguid1: cardinal;
    Fguid2: cardinal;


  public
    constructor Create; Overload;
    constructor Create( id: cardinal ); Overload;
    Constructor Create( id: cardinal; name: WideString ); overload;
    Function Clone: TpwEmuItemBase;
    Function marshall_roleList: TMarshallResult;
    Function marshall: TMarshallResult;
    //procedure unmarshall_roleList (packet : IInt

    Function getOctets: TOctets;
    procedure setOctets( octets: TOctets );

    property id: cardinal read _id write _id;
    property Name: WideString read _name write _name;
    property Slot: Cardinal read _slot write _slot;
    property Proctype: cardinal read _proctype write _proctype;
    property Mask: cardinal read _mask write _mask;
    property Count: cardinal read _count write _count;
    property maxCount: cardinal read _maxCount write _maxCount;
    property expireDate: cardinal read _expireDate write _expireDate;
    property guid1: cardinal read Fguid1 write Fguid1;
    property guid2: cardinal read Fguid2 write Fguid2;


  end;

implementation

constructor TpwEmuItemBase.Create;
begin
  // empty template.
end;

constructor TpwEmuItemBase.Create( id: cardinal );
begin
  self._id := id;
end;

constructor TpwEmuItemBase.Create( id: cardinal; name: WideString );
begin
  self._id := id;
  self._name := name;
end;

/// <remarks>
/// This returns roleList data with the big endian cancer. Only used in roleList, even if it's same struct as 0x2B packet.
/// </remarks>
Function TpwEmuItemBase.marshall_roleList: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.writeInt_BE( self._id );
  buf.writeInt_BE( self._slot );
  buf.writeInt_BE( self._count );
  buf.writeInt_BE(self._maxCount);
  buf.writeCUInt(self._octets.octetLen);
  if self._octets.octetLen > 0 then
  buf.WriteData(@self._octets.octets[0],self._octets.octetLen);
  buf.writeInt_BE(self._proctype);
  buf.writeInt_BE(self._expireDate);
  buf.writeInt_BE(self.guid1);
  buf.writeInt_BE(self.guid2);
  buf.writeInt_BE(self._mask);
  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;
end;

Function TpwEmuItemBase.marshall: TMarshallResult;
var
  buf: TswooshMemoryBuffer;
begin
  buf := TswooshMemoryBuffer.Create;
  buf.WriteData( self._id );
  buf.WriteData( self._slot );
  buf.WriteData( self._count );
  buf.WriteData(self._maxCount);
  buf.writeCUInt(self._octets.octetLen);
  if self._octets.octetLen > 0 then
  buf.WriteData(@self._octets.octets[0],self._octets.octetLen);
  buf.WriteData(self._proctype);
  buf.WriteData(self._expireDate);
  buf.WriteData(self.guid1);
  buf.WriteData(self.guid2);
  buf.WriteData(self._mask);
  Result.size := buf.size;
  setlength( Result.data, Result.size );
  CopyMemory(@Result.data[ 0 ], buf.Memory, Result.size );
  buf.Free;

end;

/// <remarks>
/// Creates a new item class with same propertys as this one.
/// </remarks>

Function TpwEmuItemBase.Clone: TpwEmuItemBase;
begin
  result := TpwEmuItemBase.Create( self._id );
  result.name := self._name;
  result.Slot := self._slot;
  result.Proctype := self._proctype;
  result.Mask := self._mask;
  result.Count := self._count;
  result.maxCount := self._maxCount;
  result.setOctets( self._octets );

  //Simple stuff, no need to explain I guess, let's go back.

end;

Function TpwEmuItemBase.getOctets: TOctets;
begin
  result := self._octets;
end;

procedure TpwEmuItemBase.setOctets( octets: TOctets );
begin
  self._octets := octets;
end;

end.
