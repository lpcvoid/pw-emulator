program pwEmu;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  swooshMPPC in 'common\swooshMPPC.pas',
  swooshDBTypes in 'common\swooshDBTypes.pas',
  swooshCompressionImports in 'common\swooshCompressionImports.pas',
  swooshCompression in 'common\swooshCompression.pas',
  swooshInternalPacketQueue in 'common\swooshInternalPacketQueue.pas',
  swooshWinsockImports in 'common\swooshWinsockImports.pas',
  swooshSocketConnection in 'common\swooshSocketConnection.pas',
  swooshSocketBase in 'common\swooshSocketBase.pas',
  swooshQueue in 'common\swooshQueue.pas',
  swooshPacketQueue in 'common\swooshPacketQueue.pas',
  swooshPacket in 'common\swooshPacket.pas',
  swooshLogInterface in 'common\swooshLogInterface.pas',
  swooshListener in 'common\swooshListener.pas',
  swooshFileSearcher in 'common\swooshFileSearcher.pas',
  SwooshCUInt in 'common\SwooshCUInt.pas',
  swooshConsoleManager in 'common\swooshConsoleManager.pas',
  swooshConnectionQueue in 'common\swooshConnectionQueue.pas',
  swooshConnectionBundleHandler in 'common\swooshConnectionBundleHandler.pas',
  swooshConfigHandler in 'common\swooshConfigHandler.pas',
  swooshClient in 'common\swooshClient.pas',
  serverDecl in 'common\serverDecl.pas',
  pwEmuMain in 'units\pwEmu\pwEmuMain.pas',
  pwEmuLoginProtocolHandler in 'units\pwEmu\pwEmuLoginProtocolHandler.pas',
  swooshRC4 in 'common\swooshRC4.pas',
  swooshHMACMD5 in 'common\swooshHMACMD5.pas',
  pwEmuPacketTypes in 'units\pwEmu\pwEmuPacketTypes.pas',
  pwEmuCryptoManager in 'units\pwEmu\pwEmuCryptoManager.pas',
  pwEmuCharacterSelectionProtocolHandler in 'units\pwEmu\pwEmuCharacterSelectionProtocolHandler.pas',
  swooshDBDaemonInterface in 'common\swooshDBDaemonInterface.pas',
  swooshFileBuffer in 'common\swooshFileBuffer.pas',
  pwEmuDataTypes in 'units\pwEmu\pwEmuDataTypes.pas',
  swooshRectangle in 'common\swooshRectangle.pas',
  pwEmuCoordinateConverter in 'commonPW\pwEmuCoordinateConverter.pas',
  pwEmuPlayerCharacterBase in 'units\pwEmu\pwEmuPlayerCharacterBase.pas',
  pwEmuPlayerCharacterInventory in 'units\pwEmu\pwEmuPlayerCharacterInventory.pas',
  pwEmuItemBase in 'units\pwEmu\pwEmuItemBase.pas',
  pwEmuPlayerCharacterInventoryManager in 'units\pwEmu\pwEmuPlayerCharacterInventoryManager.pas',
  pwEmuTasksReader in 'commonPW\pwEmuTasksReader.pas',
  pwEmuSingleTask in 'commonPW\pwEmuSingleTask.pas',
  pwEmuTasksDecl in 'commonPW\pwEmuTasksDecl.pas',
  uCompressRipRaw in 'common\uCompressRipRaw.pas',
  GNET.Compress in 'common\GNET.Compress.pas',
  pwEmuConnectionBundleHandler in 'units\pwEmu\pwEmuConnectionBundleHandler.pas',
  pwEmuServerConnectionManager in 'units\pwEmu\pwEmuServerConnectionManager.pas',
  swooshBundleCommandQueue in 'common\swooshBundleCommandQueue.pas',
  pwEmuMiscProtocolHandler in 'units\pwEmu\pwEmuMiscProtocolHandler.pas',
  pwEmuCompressionManager in 'units\pwEmu\pwEmuCompressionManager.pas',
  pwEmuWorldManager in 'units\pwEmu\pwEmuWorldManager.pas',
  pwEmuPlayerCharacterBaseDataManager in 'units\pwEmu\pwEmuPlayerCharacterBaseDataManager.pas',
  pwEmuWorldManagerDataExchangeClasses in 'units\pwEmu\pwEmuWorldManagerDataExchangeClasses.pas',
  swooshDatabaseHive in 'common\swooshDatabaseHive.pas',
  pwEmuDatabaseHive in 'units\pwEmu\pwEmuDatabaseHive.pas',
  pwEmuAccountManager in 'units\pwEmu\pwEmuAccountManager.pas',
  swooshOctetConverter in 'common\swooshOctetConverter.pas',
  swooshMemoryBuffer in 'common\swooshMemoryBuffer.pas',
  pwEmuPlayerCharacterEquipment in 'units\pwEmu\pwEmuPlayerCharacterEquipment.pas',
  pwEmuS00ContainerBuilder in 'units\pwEmu\pwEmuS00ContainerBuilder.pas',
  pwEmuTerritoryManager in 'units\pwEmu\pwEmuTerritoryManager.pas',
  pwEmuFriendList in 'units\pwEmu\pwEmuFriendList.pas',
  pwEmuFriendListManager in 'units\pwEmu\pwEmuFriendListManager.pas',
  pwEmuServerConfigManager in 'units\pwEmu\pwEmuServerConfigManager.pas',
  pwEmuMapManager in 'units\pwEmu\pwEmuMapManager.pas',
  pwEmuTerrainMapSector in 'units\pwEmu\pwEmuTerrainMapSector.pas',
  pwEmuNPCBase in 'units\pwEmu\pwEmuNPCBase.pas',
  pwEmuNpcgenReader in 'commonPW\pwEmuNpcgenReader.pas',
  pwEmuNpcgenDataTypes in 'commonPW\pwEmuNpcgenDataTypes.pas',
  pwEmuTerrainManager in 'units\pwEmu\pwEmuTerrainManager.pas';

var
  configReader: TswooshIniHandler;
  // config
  config: TbigServerConfig;

  console: TswooshConsoleManager;

  // main
  mainPWEmu: TmainpwEmu;

begin
  System.SysUtils.FormatSettings.DecimalSeparator := '.'; // fucking german ,

  console := TswooshConsoleManager.Create( 160, 80 );

  configReader := TswooshIniHandler.Create( './configs/pwEmu.ini' );

  config.listenEndpoint.ip := configReader.readString( 'connection', 'listen_ip' );
  config.listenEndpoint.port := configReader.readInt( 'connection', 'listen_port' );
  config.listenEndpoint.name := 'pwEmu';

  config.maxQueue := configReader.readInt( 'connection', 'max_queue' );
  config.maxBacklog := configReader.readInt( 'connection', 'max_backlog' );
  config.recvBuffer := configReader.readInt( 'connection', 'recv_buffer' );

  config.pwVersion := configReader.readOctets( 'general', 'version' );
  config.pwChallengeKey := configReader.readOctets( 'general', 'challengekey' );
  config.pwCrcHash := configReader.readOctets( 'general', 'crchash' );
  config.rareItems := configReader.readIntArray( 'general', 'rare_items' );
  config.rootDirectory := configReader.readString( 'general', 'root_directory' );

  // files

  config.itemDataFile := configReader.readString( 'files', 'itemDataFile' );
  config.QuestsFile := configReader.readString( 'files', 'QuestFile' );
  config.DynamicQuestsFile := configReader.readString( 'files', 'DynamicQuestsFile' );
  config.GlobalDataFile := configReader.readString( 'files', 'GlobalDataFile' );
  config.PolicyDataFile := configReader.readString( 'files', 'PolicyDataFile' );
  config.DropDataFile := configReader.readString( 'files', 'DropDataFile' );
  config.NPCGenFile := configReader.readString( 'files', 'NPCGenFile' );
  config.PrecinctFile := configReader.readString( 'files', 'PrecinctFile' );
  config.RegionFile := configReader.readString( 'files', 'RegionFile' );
  config.PathFile := configReader.readString( 'files', 'PathFile' );
  config.MallDataFile := configReader.readString( 'files', 'MallDataFile' );
  config.Mall2DataFile := configReader.readString( 'files', 'Mall2DataFile' );
  config.LuaDataFile := configReader.readString( 'files', 'LuaDataFile' );
  config.CollisionFile := configReader.readString( 'files', 'CollisionFile' );
  config.CollisionElementFile := configReader.readString( 'files', 'CollisionElementFile' );

  // database
  config.db := configReader.readString( 'pwemu', 'database' );
  config.dbSaveIntervall := configReader.readInt( 'pwemu', 'database_save_intervall' );

  // TW
  config.pwTWLandCount := configReader.readInt( 'TWconfig', 'land_count' );
  config.pwTWMaxBid := configReader.readInt( 'TWconfig', 'max_bid' );
  config.pwTWBonusItemID := configReader.readInt( 'TWconfig', 'bonus_id' );
  config.pwTWBonusCount1 := configReader.readInt( 'TWconfig', 'bonus_count1' );
  config.pwTWBonusCount2 := configReader.readInt( 'TWconfig', 'bonus_count2' );
  config.pwTWBonusCount3 := configReader.readInt( 'TWconfig', 'bonus_count3' );

  // log daemon interface client
  config.remote_logDaemonEndpoint.ip := configReader.readString( 'connection', 'logserver_ip' );
  config.remote_logDaemonEndpoint.port := configReader.readInt( 'connection', 'logserver_port' );
  config.remote_logDaemonEndpoint.name := 'logDaemon';

  // dbDaemon
  config.remote_dbDaemonEndpoint.ip := configReader.readString( 'connection', 'dbserver_ip' );
  config.remote_dbDaemonEndpoint.port := configReader.readInt( 'connection', 'dbserver_port' );
  config.remote_dbDaemonEndpoint.name := 'dbServer';

  Writeln( 'listen_ip=' + config.listenEndpoint.ip + ' ,listen_port=' + intToStr( config.listenEndpoint.port ));

  mainPWEmu := TmainpwEmu.Create( config, 7, 8 );

  sleep( 1000 );

  while mainPWEmu.active do
  begin
    Writeln( mainPWEmu.getServerStatus );
    sleep( 15000 );
  end;

  Writeln( 'Server shutting down in 5 seconds' );
  sleep( 5000 );

  // so, dann wollen wir mal nen emu schreiben, ne?
  // emu.start;
end.
