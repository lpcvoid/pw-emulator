unit pwEmuSingleTask;

interface

uses windows, classes, types,pwEmuTasksDecl;

type
  TpwEmuSingleTask = class
  private
    Fid          : integer;
    Fname        : string;
    FauthorMode  : boolean;
    FpszSignature: integer;
    FType        : integer;
    FTimeLimit   : integer;
    FOfflineFail : boolean;
    FfailAtDate     : boolean;
    FfailDate : TTasksDate;
    FitemNotTakeOff: boolean;
    FsuccessAtTime: boolean;
    FdateSpansCount: integer;
    FtmType: TTaskTmType;
    FtmStart: integer;
    FtmEnd: integer;
    FavailFrequency: integer;
    FperiodLimit: integer;
    FchooseOne: boolean;
    FrandOne: boolean;
    FexeChildInOrder: boolean;
    FparentAlsoFail: boolean;
    FparentAlsoSuceeds: boolean;

  public
    property id          : integer read Fid write Fid;
    property name        : string read Fname write Fname;
    property authorMode  : boolean read FauthorMode write FauthorMode;
    property pszSignature: integer read FpszSignature write FpszSignature;
    property ulType      : integer read FType write FType;
    property TimeLimit : integer read FTimeLimit write FTimeLimit;
    property OfflineFail : boolean read FOfflineFail write FOfflineFail;
    property failAtDate     : boolean read FfailAtDate write FfailAtDate;
    property failDate: TTasksDate read FfailDate write FfailDate;
    property itemNotTakeOff: boolean read FitemNotTakeOff write FitemNotTakeOff;
    property successAtTime: boolean read FsuccessAtTime write FsuccessAtTime;
    property dateSpansCount: integer read FdateSpansCount write FdateSpansCount;
    property tmType: TTaskTmType read FtmType write FtmType;
    property tmStart: integer read FtmStart write FtmStart;
    property tmEnd: integer read FtmEnd write FtmEnd;
    property availFrequency: integer read FavailFrequency write FavailFrequency;
    property periodLimit: integer read FperiodLimit write FperiodLimit;
    property chooseOne: boolean read FchooseOne write FchooseOne;
    property randOne: boolean read FrandOne write FrandOne;
    property exeChildInOrder: boolean read FexeChildInOrder write FexeChildInOrder;
    property parentAlsoFail: boolean read FparentAlsoFail write FparentAlsoFail; //If quest fails, parent also fails?
    property parentAlsoSuceeds: boolean read FparentAlsoSuceeds write FparentAlsoSuceeds; //If quest succeeds, shall parent quest also suceed?



  end;

implementation

{ TpwEmuSingleTask }

end.
