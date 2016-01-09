{


 Extends the swooshConnectionBundleHandler class and provides pw specific functions.
 Builds packets and handles packets.
 Handles maximum logic of 64 clients.


}

unit pwEmuConnectionBundleHandler;

interface

uses windows, classes, types, swooshConnectionBundleHandler, serverDecl, System.SysUtils, swooshInternalPacketQueue,
  pwEmuLoginProtocolHandler, pwEmuCharacterSelectionProtocolHandler, pwEmuMiscProtocolHandler, pwEmuWorldManagerDataExchangeClasses,
  pwEmuCryptoManager, pwEmuCompressionManager, swooshBundleCommandQueue, swooshPacket, pwEmuDataTypes, pwEmuWorldManager, pwEmuS00ContainerBuilder;

type
  TpwEmuConnectionBundleHandler = class( TThread )
  public
    // The actual TswooshConnectionBundleHandler.
    bundleHandler: TswooshConnectionBundleHandler;
    constructor Create( _bundleID: integer; maxSockets: cardinal; config: TbigServerConfig; worldMan: TpwEmuWorldManager );

  private

    // packet type handlers
    loginPacketHandler        : TpwEmuLoginProtocolHandler;
    charSelectionPacketHandler: TpwEmuCharacterSelectionProtocolHandler;
    miscPacketHandler         : TpwEmuMiscProtocolHandler;

    // helpers
    cryptoManager      : TpwEmuCryptoManager;
    mppcCompressor     : TpwEmuCompressionManager;
    s00ContainerBuilder: TpwEmuS00ContainerBuilder;

    // main world manager. Heavily CS'ed.
    _worldMan: TpwEmuWorldManager;

    // helper queue for the getNextQueuedPacket function. It contains 100% valid, unsplit PW packets, unlike the real queue. For info, read the remark.
    _realPacketQueue: TSwooshInternalPacketQueue;

    // checks parent bundlehandler command queue for any new events or commands.
    procedure processBundlerHandlerCommandEvents;
    procedure sendPWPacket ( packet: TInternalSwooshPacket; encrypt: boolean = true; compress: boolean = true );
    function getNextQueuedPacket: TInternalSwooshPacket;

  protected
    procedure Execute; override;

  end;

implementation

constructor TpwEmuConnectionBundleHandler.Create ( _bundleID: integer; maxSockets: cardinal; config: TbigServerConfig; worldMan: TpwEmuWorldManager );
begin
  inherited Create( true );

  writeln( 'Trace : TpwEmuConnectionBundleHandler.Create()' );

  self._worldMan := worldMan;

  self.charSelectionPacketHandler := TpwEmuCharacterSelectionProtocolHandler.Create;
  self.loginPacketHandler := TpwEmuLoginProtocolHandler.Create( config, self._worldMan );
  self.miscPacketHandler := TpwEmuMiscProtocolHandler.Create;

  self.cryptoManager := TpwEmuCryptoManager.Create;
  self.mppcCompressor := TpwEmuCompressionManager.Create;

  self.s00ContainerBuilder := TpwEmuS00ContainerBuilder.Create;

  self._realPacketQueue := TSwooshInternalPacketQueue.Create( 500 );

  // Created at last.

  self.bundleHandler := TswooshConnectionBundleHandler.Create( _bundleID, maxSockets );

  self.Resume;

end;

procedure TpwEmuConnectionBundleHandler.processBundlerHandlerCommandEvents;
var
  event: TSocketEvent;
begin
  if ( self.bundleHandler.commandEventQueue.hasEvent )
  then
  begin
    // We have an event or a command from the bundle handler in here!!!!oneoneone
    event := self.bundleHandler.commandEventQueue.getCommand;
    case event.eventID of

      2:
        begin
          // Disconnect
          // remove crypto handler for this connection
          try

            self.cryptoManager.deleteEncryptor( event.socketID ); // 2. command = socket ID
            writeln( 'TpwEmuCryptoManager.deleteEncryptor, cid=' + IntToStr( event.socketID ));

            self.cryptoManager.deleteDecryptor( event.socketID ); // 2. command = socket ID
            writeln( 'TpwEmuCryptoManager.deleteDecryptor, cid=' + IntToStr( event.socketID ));

            // compressor
            self.mppcCompressor.removeCompressor( event.socketID );
            writeln( 'TpwEmuCompressionManager.removeCompressor, cid=' + IntToStr( event.socketID ));
          except
            writeln( 'TpwEmuCryptoManager.Delete Enc/DeCryptors Error! , cid=' + IntToStr( event.socketID ));
          end;

        end;

      1:
        begin
          // connected
          writeln( 'TpwEmuConnectionBundleHandler -> Got event notification of client connect! cid=' + IntToStr( event.socketID ));

          // send welcome packet to the bitch.
          self.bundleHandler.sendPacketQueue.addInternalPacket( self.loginPacketHandler.build_s2c_01_ChallengePacket( event.socketID,
              self.bundleHandler.bundleID ));

        end;

    end;

  end;

end;

procedure TpwEmuConnectionBundleHandler.sendPWPacket ( packet: TInternalSwooshPacket; encrypt: boolean = true; compress: boolean = true );
begin

  if self.mppcCompressor.needsCompression( packet.connectionID )
  then
    packet := self.mppcCompressor.compressPacket( packet.connectionID, packet );

  if self.cryptoManager.needsEncrypt( packet.connectionID )
  then
    self.cryptoManager.encryptPacket( packet );

  self.bundleHandler.sendPacketQueue.addInternalPacket( packet );

end;

/// <remarks>
/// This method garantees to get a SINGLE packet from queue, even if queued data is a concated packet.
/// TCP protocol is a stream protocol, hence we cannot rely on recv returning single packets.
/// </remarks>

function TpwEmuConnectionBundleHandler.getNextQueuedPacket: TInternalSwooshPacket;
var
  tempPacket          : TInternalSwooshPacket;
  pOpcode             : TCUINTDetailResult;
  pLen                : TCUINTDetailResult;
  actualPacketLen     : cardinal;
  actualPacketPosition: cardinal;
begin

  result := nil;
  // Is there a packet which was previously splitted by this function? if so, give that instead of getting new from queue.
  if ( self._realPacketQueue.itemInQueue )
  then
  begin
    result := self._realPacketQueue.getInternalPacket;
    exit;
  end;

  // We can assume that the caller checked for queued packet.
  // This function is only called in that case.
  tempPacket := self.bundleHandler.readPacketQueue.getInternalPacket;

  // Needs decrypt?
  if self.cryptoManager.needsDecrypt( tempPacket.connectionID )
  then
    self.cryptoManager.decryptPacket( tempPacket );

  // Now, this packet may be concated. We need to check.
  // In PW, all packets have CUINT Opcode, CUINT Length as start. So, we check length.

  pOpcode := tempPacket.ReadCUIntDetail;
  pLen := tempPacket.ReadCUIntDetail;

  // Is the length + (header) = packetlength? If so, it's a single packet.
  if ( pLen.value + pOpcode.bytes + pLen.bytes = tempPacket.GetpacketLength )
  then
  begin
    tempPacket.Rewind; // reset internal bufferpos for reading data.
    result := tempPacket;
    exit;
  end
  else
  begin
    // There's more then one packet. Let's stuff them all to queue. At end, we return one.
    tempPacket.Rewind;
    actualPacketPosition := 0; // We are at first byte.
    while actualPacketPosition < tempPacket.GetpacketLength do
    begin
      pOpcode := tempPacket.ReadCUIntDetail;
      pLen := tempPacket.ReadCUIntDetail;

      actualPacketLen := pLen.value + pOpcode.bytes + pLen.bytes;
      // Create new packet in queue containing this info.
      self._realPacketQueue.addInternalPacket( TInternalSwooshPacket.Create( @tempPacket.buffer[ actualPacketPosition ], actualPacketLen,
          tempPacket.connectionID ));
      // Increment actualPacketPosition to reflect the position in temoPacket.
      inc( actualPacketPosition, actualPacketLen );
      // increment the temppacket position so the CUINT reading will suceed next round.
      tempPacket.skipBytes( actualPacketLen - ( pOpcode.bytes + pLen.bytes ) );

    end;

    // We don't need the temppacket anymore. All its data was splitted into real packets.
    tempPacket.Free;

    // return one of the newly splitted packets.
    result := self._realPacketQueue.getInternalPacket;

  end;

end;

procedure TpwEmuConnectionBundleHandler.Execute;
var
  tempInternalPacket: TInternalSwooshPacket;
  // used to check login success.
  loginResult: integer;
  // used for processing RoleList requests.
  roleList_c2s_52: TRoleList_c2s_52;
  roleList_re    : TRolelist_re_53;
  roleid         : cardinal;
  mar            : TMarshallResult;
  roleInfo       : TRoleInfo;
  // used for C22 container parsing.
  C22subLen   : cardinal;
  C22subOpcode: word;
begin
  try
    writeln( 'TpwEmuConnectionBundleHandler.Execute() -> Start new logicHandler!' );
    while ( NOT self.Terminated ) do
    begin

      // process bundleevents.
      self.processBundlerHandlerCommandEvents;
      // Process packets.
      // main query responder and processor

      if ( self.bundleHandler.readPacketQueue.itemInQueue ) or ( self._realPacketQueue.itemInQueue )
      then
      begin
        // new packet in this bundle!

        // garantees to get one proper PW packet, no conactted junk. Fucking tcp. Also decrypts if needed.
        tempInternalPacket := self.getNextQueuedPacket;

        // writeln('New packet! bid=' + inttoStr(tempInternalPacket.bundleID) + ' ,connection=' + inttoStr(tempInternalPacket.connectionID));

        // writeln(tempInternalPacket.packet2String);
        if tempInternalPacket <> nil
        then
          case tempInternalPacket.getPacketType of

            $03:
              begin
                loginResult := self.loginPacketHandler.parse_c2s_03_UserLoginAnnouncePacket( tempInternalPacket );
                if loginResult = 0 // generates c2s key.
                then
                begin
                  writeln( 'Login succeeded.' );

                  self.bundleHandler.sendPacketQueue.addInternalPacket( self.loginPacketHandler.build_s2c_02_KeyExchangePacket( tempInternalPacket ));

                  // from now on, every packet is encrypted!
                  self.cryptoManager.addDecryptor( tempInternalPacket.connectionID, self.loginPacketHandler.c2sKey );

                  // also, all packets send from now on need to be compressed. Fucking mppc.

                end
                else
                begin
                  self.sendPWPacket( self.loginPacketHandler.build_s2c_05_Errorpacket( tempInternalPacket, loginResult, 'Nope nigga!!' ), false, false );
                  writeln( 'Login Failed!' );
                end;

              end;

            $02:
              begin
                self.loginPacketHandler.parse_c2s_02_KeyExchangePacket( tempInternalPacket ); // generates s2c key.

                self.cryptoManager.addEncryptor( tempInternalPacket.connectionID, self.loginPacketHandler.s2CKey );

                self.mppcCompressor.addCompressor( tempInternalPacket.connectionID );

                // Can also return an 05 error packet.
                tempInternalPacket := self.loginPacketHandler.build_s2c_04_OnlineAnnounce( tempInternalPacket );

                self.sendPWPacket( tempInternalPacket );

              end;

            $52:
              begin
                // rolelist request

                // First, server sends $FFFFFFFF.
                // Then we send character. if no char present, send empty roleList_re.
                // Each character sent contains the next slot.
                // On last avaliable character, send $FFFFFFFF again.

                // So, first, we parse the incoming packet, and get the requested account ID and slot.
                roleList_c2s_52 := self.charSelectionPacketHandler.parse_c2s_52_RoleList( tempInternalPacket ); // Done

                // afterwards, we ask worldmanager to pass us the character info for this guy, so we can conastruct listRole_re packet and send to client.
                roleid := self._worldMan.getRoleIDFromSlot( roleList_c2s_52.accountID, roleList_c2s_52.slot );

                // Hmkay, we have the ID. Let's request info for this char from Worldmanager.

                // Check slot shit...
                if ( roleid = 0 ) or ( roleid = $FFFFFFFF )
                then
                begin
                  roleList_re := self._worldMan.getRoleList_Re_FF;
                  roleList_re.nextSlot := $FFFFFFFF;
                end
                else
                begin
                  roleList_re := self._worldMan.getRoleList_Re( roleid );
                  roleList_re.nextSlot := roleList_c2s_52.slot + 1;
                end;


                // Now that we have the data, let's construct the actual packet. Easily done.

                tempInternalPacket.Flush;
                tempInternalPacket.WriteCUInt( roleList_re._packetType );

                mar := roleList_re.marshall;

                tempInternalPacket.WriteCUInt( mar.size );
                tempInternalPacket.WriteRawData( mar.data, mar.size );

                roleList_re.Free;



                // tempInternalPacket := self.charSelectionPacketHandler.build_s2c_53_RoleList_Re_Demo( roleList_c2s_52.accountID, tempInternalPacket );

                // Now, send packet.

                self.sendPWPacket( tempInternalPacket );
              end;

            $54:
              begin
                // Rolecreate request
                writeln( 'CreateRole request! cid=' + IntToStr( tempInternalPacket.connectionID ));

                roleInfo := self.charSelectionPacketHandler.parse_c2s_54_CreateRole_Request( tempInternalPacket );

                writeln( 'Name=' + roleInfo.name + ' cid=' + IntToStr( tempInternalPacket.connectionID ));

                // Check if name is already used.

              end;

            $5A:
              begin
                // keepalive, simply pong.

                writeln( 'PONG! cid=' + IntToStr( tempInternalPacket.connectionID ));

                tempInternalPacket := self.miscPacketHandler.build_s2c_5A_KeepalivePong( tempInternalPacket );

                self.sendPWPacket( tempInternalPacket );
              end;

            $46:
              begin
                // Selectrole recieved
                writeln( 'SelectRole_Re! cid=' + IntToStr( tempInternalPacket.connectionID ));
                tempInternalPacket := self.charSelectionPacketHandler.build_s2c_47_SelectRole_Re( tempInternalPacket );

                self.sendPWPacket( tempInternalPacket );
              end;

            $48:
              begin
                // Client sends us Enterworld...

                // get role ID.
                roleid := self.charSelectionPacketHandler.parse_c2s_48_Enterworld( tempInternalPacket );

                // Now fun starts... construct S00 container packet containing essential infos.
                self.s00ContainerBuilder.resetContainer;

                mar := self._worldMan.getSimpleRoleUpdateInfo( roleid ).marshall;
                self.s00ContainerBuilder.addSubPacket( mar );

                mar := self._worldMan.getUnknownRoleInfo( roleid ).marshall;
                self.s00ContainerBuilder.addSubPacket( mar );

                mar := self._worldMan.getServerConfigInfo_CE;
                self.s00ContainerBuilder.addSubPacket( mar );

                mar := self.s00ContainerBuilder.finalizeContainer;
                tempInternalPacket.Flush;
                tempInternalPacket.WriteRawData( mar.data, mar.size );

                self.sendPWPacket( tempInternalPacket );

                writeln( 'EnterWorld S00 response container sent!! cid=' + IntToStr( tempInternalPacket.connectionID ));
              end;

            $22:
              begin
                // client container. Handle accordingly.

                tempInternalPacket.ReadCUInt; // len, not needed.

                while tempInternalPacket.EOF = false do
                begin
                  tempInternalPacket.ReadCUInt; // Stupid len +1
                  C22subLen := tempInternalPacket.ReadCUInt;

                  C22subOpcode := tempInternalPacket.ReadWord;

                  case C22subOpcode of

                    $27:
                      begin
                        // GSGetInventory
                        writeln( 'C22Sub::GSGetInventory' );
                      end;

                    $88:
                      begin
                        // GSGetInventory
                        writeln( 'C22Sub::AnnounceChallengeAlgo!' );
                      end;

                  else
                    begin
                      // unhandled C22 container subpacket.
                      writeln( 'unhandled C22 container subpacket! opcode=' + IntToHex( C22subOpcode, 4 ) );
                      // skip the length of the packet.
                      tempInternalPacket.skipBytes( C22subLen );
                    end;

                  end

                end;

              end;

            $352:
              begin
                // TW Map request
                writeln( 'TW map request processed. cid=' + IntToStr( tempInternalPacket.connectionID ));

                mar := self._worldMan.getTWMapResponse_353;

                tempInternalPacket.Flush;

                tempInternalPacket.WriteCUInt( $353 );
                tempInternalPacket.WriteCUInt( mar.size );
                tempInternalPacket.WriteRawData( mar.data, mar.size );

                self.sendPWPacket( tempInternalPacket );
              end;

            $CE:
              begin
                // FriendlistRequest
                writeln( 'Friendlist request processed. cid=' + IntToStr( tempInternalPacket.connectionID ));
                tempInternalPacket.Flush;
                tempInternalPacket.WriteCUInt( $CF );

                mar := self._worldMan.getMarshalledFriendList( 1024 );

                tempInternalPacket.WriteCUInt(mar.size);
                tempInternalPacket.WriteRawData( mar.data, mar.size );

                self.sendPWPacket( tempInternalPacket );
              end;

            $D9:
              begin
                // get saved messages
                writeln( 'Saved message request processed. cid=' + IntToStr( tempInternalPacket.connectionID ));
                tempInternalPacket.Flush;
                tempInternalPacket.WriteCUInt( $DA );
                tempInternalPacket.WriteCUInt( 10 );
                tempInternalPacket.WriteWord( 0 );
                tempInternalPacket.WriteDWORD_BE( 1024 );
                tempInternalPacket.WriteDWORD_BE( 0 );
                self.sendPWPacket( tempInternalPacket );
              end;

          else
            begin
              writeln( 'Unhandled opcode! ' );
              writeln( tempInternalPacket.packet2String );
            end;

          end;

      end
      else
        sleep( 1 ); // big factor!

    end;

  except
    writeln( 'TpwEmuConnectionBundleHandler.Execute -> Exception!' );
  end;
end;

end.
