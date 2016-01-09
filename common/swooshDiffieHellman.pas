unit swooshDiffieHellman;


{

references :

http://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange

}

interface

uses
  windows,
  swooshMaths,System.math,system.sysutils;

type
  TSwooshDiffieHellman = class
    public
      constructor Create(p,b,s : Uint64);
      function getPublicNumber : Uint64;
      function generateSecretKey(publicNumber : Uint64) : Uint64;
      function testSelf : Uint64;
    private
      p,b : Uint64; //p = prime number and g = base number agreed upon
      secretInt  : Uint64;
      sharedSecretkey : Uint64;
      swooshMaths : TSwooshMaths;
  end;

implementation

constructor TSwooshDiffieHellman.Create(p,b,s : Uint64);
begin
  randomize;
  self.swooshMaths := TSwooshMaths.Create;
  self.b := b;
  self.p := p;
  self.secretInt := s;//Random(8);
end;


//This is sent to the other guy
function TSwooshDiffieHellman.getPublicNumber : Uint64;
begin
  result := trunc(Power(b,self.secretInt)) mod self.p;
end;

//this step is done with the getPublicNumber() result from other guy!

function TSwooshDiffieHellman.generateSecretKey(publicNumber : Uint64) : Uint64;
begin
  self.sharedSecretkey := Trunc(Power(publicNumber,self.secretInt)) mod self.p;
  result := self.sharedSecretkey;
end;


//just some tests

function TSwooshDiffieHellman.testSelf : Uint64;
var
  prime : int64;
  testDH1 : TSwooshDiffieHellman;
  testDH2 : TSwooshDiffieHellman;
  publicNumber1 : int64;
  publicNumber2 : int64;
  secretKey1 : int64;
  secretKey2 : int64;
  match : boolean;
begin

  prime := self.swooshMaths.supplyPrimeNumber;

  testDH1 := TSwooshDiffieHellman.Create(23,5,24);
  testDH2 := TSwooshDiffieHellman.Create(23,5,65);

  publicNumber1 := testDH1.getPublicNumber();
  publicNumber2 := testDH2.getPublicNumber();

  secretKey1 := testDH1.generateSecretKey(publicNumber2);
  secretKey2 := testDH2.generateSecretKey(publicNumber1);

  match := secretKey1 = secretKey2;

  if match then
    result := secretKey1
    else
    result := 0;

  testDH1.Free;
  testDH2.Free;



end;


end.
