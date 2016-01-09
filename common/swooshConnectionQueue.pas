unit swooshConnectionQueue;

interface

uses windows, swooshQueue, winsock, swooshSocketConnection;

type
  TSwooshConnectionQueue = class( TSwooshQueue )
    constructor Create( maxQueueSize: integer ); override;
    Function getConnection: TSwooshSocketConnection;
    procedure addConnection( theSocket: TSwooshSocketConnection );
  end;

implementation

constructor TSwooshConnectionQueue.Create( maxQueueSize: integer );
begin
  inherited Create( maxQueueSize );
end;

procedure TSwooshConnectionQueue.addConnection ( theSocket: TSwooshSocketConnection );
begin
  self.addItem( theSocket );
end;

Function TSwooshConnectionQueue.getConnection: TSwooshSocketConnection;
begin
  result := TSwooshSocketConnection( self.getItem );

end;

end.
