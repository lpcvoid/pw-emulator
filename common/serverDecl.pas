unit serverDecl;

interface

uses winsock, System.Generics.Collections;

type
  TRawData = array of byte;

type
  TRawData16 = array of word;

type
  TRawData32 = array of Cardinal;

type
  TRawDataFloat = array of Single;

type
  THashKey = array [ 0 .. 15 ] of byte;

type
  TRawData32_512 = array [ 0 .. 511 ] of Cardinal;

type
  TRawDataString_128 = array [ 0 .. 127 ] of string;

type
  TMarshallResult = packed record
    size: Cardinal;
    data: TRawData;
  end;

type
  TpwAccountDetails = packed record
    accountID: Cardinal;
    loginName: String[ 24 ]; // max 24 chars, ansi
    loginHash: String[ 32 ]; // MD5
    lastLogin: Cardinal;     // timestamp
    lastLoginIP: Cardinal;   // cardinal ip repreentation
  end;

type
  TIPEndpoint = packed record
    ip: AnsiString;
    port: word;
    name: AnsiString;
  end;

type
  TbigServerConfig = packed record
    /// <remarks>
    /// IP for listen socket (server) to listen for connections.
    /// Port for listen socket to listen for connections (server).
    /// </remarks>
    listenEndpoint: TIPEndpoint;

    /// <remarks>
    /// endpoint of dbDaemon server. Used for clients to connect.
    /// </remarks>
    remote_dbDaemonEndpoint: TIPEndpoint;

    /// <remarks>
    /// endpoint of log daemon server. Used for clients to connect.
    /// </remarks>
    remote_logDaemonEndpoint: TIPEndpoint;

    /// <remarks>
    /// directory where database files are.
    /// </remarks>
    db: string;
    /// <remarks>
    /// directory where backups.
    /// </remarks>
    dbBackup: String;
    /// <remarks>
    /// intervall (in seconds) where daemon saves data from memory to disk.
    /// </remarks>
    dbSaveIntervall: integer;

    /// <remarks>
    /// directoy where log daemon shall place log files. Only applies to logd.
    /// </remarks>
    logDir: String;

    /// <remarks>
    /// 4 byte version indicator for pwEmu to send in challenge packet.
    /// </remarks>
    pwVersion: TRawData;

    /// <remarks>
    /// This is the challengeKey which pw server uses to check auth. See overview paper.
    /// </remarks>
    pwChallengeKey: TRawData;

    /// <remarks>
    /// This contains some data used by client to check current version and other thingos.
    /// </remarks>
    pwCrcHash: TRawData;

    /// <remarks>
    /// Array of rare item IDs.
    /// </remarks>
    rareItems: TRawData32_512;

    /// <remarks>
    /// Root directory for all other file paths and files.
    /// </remarks>
    rootDirectory: AnsiString;



    // files

    itemDataFile: AnsiString;
    QuestsFile: AnsiString;
    DynamicQuestsFile: AnsiString;
    GlobalDataFile: AnsiString;
    PolicyDataFile: AnsiString;
    DropDataFile: AnsiString;
    NPCGenFile: AnsiString;
    PrecinctFile: AnsiString;
    RegionFile: AnsiString;
    PathFile: AnsiString;
    MallDataFile: AnsiString;
    Mall2DataFile: AnsiString;
    LuaDataFile: AnsiString;
    CollisionFile: AnsiString;
    CollisionElementFile: AnsiString;

    worldServers :  TRawDataString_128;
    instanceServers : TRawDataString_128;





    /// <remarks>
    /// Territory War land count.
    /// </remarks>
    pwTWLandCount: Cardinal;

    /// <remarks>
    /// Maximum bid
    /// </remarks>
    pwTWMaxBid: Cardinal;

    /// <remarks>
    /// Bonus item ID awarded to winner.
    /// </remarks>
    pwTWBonusItemID: Cardinal;

    pwTWBonusCount1: Cardinal;
    pwTWBonusCount2: Cardinal;
    pwTWBonusCount3: Cardinal;

    // general, global
    /// <remarks>
    /// maximum number of clients (connections) supported.
    /// </remarks>
    maxClients: NativeUInt;
    /// <remarks>
    /// maximum length of internal queue system.
    /// </remarks>
    maxQueue: integer;
    /// <remarks>
    /// maximum number of accept() backlogs (2. parameter).
    /// <c>Recommendation : 25</c>
    /// </remarks>
    maxBacklog: integer;
    /// <remarks>
    /// maximum size of the recv buffer.
    /// <c>recommendation : 16000 </c>
    /// </remarks>
    recvBuffer: integer;
  end;

type
  TFDSets = packed record
    readFD: TFDSet;
    writeFD: TFDSet;
    errorFD: TFDSet;
    totalNumber: Cardinal; // used for checking select() result.
  end;

type
  TSocketState = ( Started, Connected, Disconnected );

implementation

end.
