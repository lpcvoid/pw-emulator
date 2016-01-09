unit pwEmuTasksReader;

interface

uses windows, swooshFileBuffer, classes, types, serverDecl, System.Generics.Collections, System.SysUtils, pwEmuSingleTask, pwEmuTasksDecl;

type
  TpwEmuTasksReader = class
  public
    constructor Create( config: TbigServerConfig );
    function loadTasks: Boolean;

  private
    _fs       : TSwooshFileBuffer;
    _version  : integer;
    _taskCount: integer;

    // the file offset dict.
    taskOffsets: TList< Cardinal >;
    tasks      : TList< TpwEmuSingleTask >;

    // decryption

    function decryptString ( reader: TSwooshFileBuffer; Len: Cardinal; Key: dword ): String;
    function readTaskDate ( reader: TSwooshFileBuffer ): TTasksDate;

  end;

implementation

constructor TpwEmuTasksReader.Create( config: TbigServerConfig );
begin
  self._fs := TSwooshFileBuffer.Create( config.rootDirectory + config.QuestsFile );
  self.taskOffsets := TList< Cardinal >.Create;
  self.tasks := TList< TpwEmuSingleTask >.Create;
end;

function TpwEmuTasksReader.decryptString ( reader: TSwooshFileBuffer; Len: Cardinal; Key: dword ): String;
var
  I         : integer;
  helpBuffer: TRawData;
  dByte     : array [ 0 .. 1 ] of Byte;
begin
  setlength( result, Len div 2 ); // 60 byte for quest name
  setlength( helpBuffer, Len );
  reader.readRawData( Len, helpBuffer );
  CopyMemory(@dByte,@Key, 2 );
  for I := 0 to Len - 1 do
    if ( I mod 2 = 0 )
    then
    begin
      helpBuffer[ I ] := helpBuffer[ I ] xor dByte[ 0 ];
      helpBuffer[ I + 1 ] := helpBuffer[ I + 1 ] xor dByte[ 1 ];
    end;
  CopyMemory(@result[ 1 ],@helpBuffer[ 0 ], Len );
end;

function TpwEmuTasksReader.readTaskDate ( reader: TSwooshFileBuffer ): TTasksDate;
begin
  result.year := reader.readInt;
  result.month := reader.readInt;
  result.day := reader.readInt;
  result.hour := reader.readInt;
  result.minute := reader.readInt;
  result.weekday := reader.readInt;
end;

function TpwEmuTasksReader.loadTasks: Boolean;
var
  I    : integer;
  cTask: TpwEmuSingleTask;
begin
  self._fs.readInt; // unknown
  self._version := self._fs.readInt;
  self._taskCount := self._fs.readInt;

  for I := 0 to self._taskCount - 1 do
    self.taskOffsets.Add( self._fs.readInt );

  for I := 0 to self.taskOffsets.Count - 1 do
  begin
    self._fs.setPosition( self.taskOffsets[ I ]);

    cTask := TpwEmuSingleTask.Create;
    cTask.id := self._fs.readInt;
    cTask.name := self.decryptString( self._fs, 60, cTask.id );
    cTask.authorMode := self._fs.readBoolean;
    cTask.pszSignature := self._fs.readInt;
    cTask.ulType := self._fs.readInt;
    cTask.TimeLimit := self._fs.readInt;
    cTask.OfflineFail := self._fs.readBoolean;
    cTask.failAtDate := self._fs.readBoolean;
    cTask.failDate := self.readTaskDate( self._fs ); // fail at a certain date?
    cTask.itemNotTakeOff := self._fs.readBoolean;
    cTask.successAtTime := self._fs.readBoolean;
    cTask.dateSpansCount := self._fs.readInt;
    self._fs.readPointerData(@cTask.tmType[ 0 ], SizeOf( TTaskTmType ));
    cTask.tmStart := self._fs.readInt;
    cTask.tmEnd := self._fs.readInt;
    cTask.availFrequency := self._fs.readInt;
    cTask.periodLimit := self._fs.readInt;
    cTask.chooseOne := self._fs.readBoolean;
    cTask.randOne := self._fs.readBoolean;
    cTask.exeChildInOrder := self._fs.readBoolean;
    cTask.parentAlsoFail := self._fs.readBoolean;
    cTask.parentAlsoSuceeds := self._fs.readBoolean;

    //TODO :  Continue this shit

    //writeln( 'Loaded task : ' + cTask.name + ' (' + IntToStr( cTask.id ) + ')' + ' parentAlsoFails=' + BoolToStr( cTask.parentAlsoFail, True ) );

    self.tasks.Add( cTask );

  end;

  writeln( 'TpwEmuTasksReader.loadTasks : Loaded ' + IntToStr( self._taskCount ) + ' tasks.' );

end;

end.
