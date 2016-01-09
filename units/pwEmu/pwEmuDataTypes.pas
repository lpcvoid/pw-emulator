unit pwEmuDataTypes;

interface

uses windows, serverDecl;

type
  TOctets = packed record
    octetLen: Cardinal;
    octets: TRawData;
  end;

  // This is used for splitpacket help.
type
  TCUINTDetailResult = packed record
    /// <remarks>
    /// The number of bytes actually read this call.
    /// </remarks>
    bytes: byte;
    /// <remarks>
    /// The CUINT decoded value.
    /// </remarks>
    value: integer;
  end;

type
  TBounds = record
    Max: Cardinal;
    Min: Cardinal;
  end;

type
  TRoleInfoUpdate_s2c_26 = packed record
    // little endian
    level: DWORD;
    hpCurrent: DWORD;
    hpMax: DWORD;
    mpCurrent: DWORD;
    mpMax: DWORD;
    Exp: DWORD;
    Spirit: DWORD;
    Chi: DWORD;
    ChiMax: DWORD;
  end;

type
  TRoleList_c2s_52 = packed record
    accountID: Cardinal;
    unknown: Cardinal;
    slot: Cardinal;
  end;

type
  TServerConfigInfo = packed record
    world_tag: Cardinal;
    region_time: Cardinal;
    precinct_time: Cardinal;
    mall_timestamp: Cardinal;
    mall2_timestamp: Cardinal;
  end;

type
  TpwEmuWorldConfig = class
    worldTag: word;
    minHeight: Single;
    maxHeight: Single;
    nSectors: Cardinal;
    nColumns: Cardinal;
    nRows: Cardinal;
    subSectionWidth: Cardinal;
    subSectionHeight: Cardinal;
    worldFilePath: string;

  end;

  // nothrow, clear-ap, use-save-point, allow-root, commondata
type
  worldConfig_Limit = ( noDiscard, clearChi, savePoint, allowEnter, commonData );

  {0: General Items
   1: Weapon
   2: Helmet
   4: Necklace
   8: Cape
   16: Shirt
   32: Belt
   64: Leggings
   128: Footwear
   256: Wristguard
   1536: Ring
   2048: Arrows
   4096: Wings
   8192: Fashion top
   16384: Fashion legs
   32768: Fashion footwear
   65536: Fashion arms
   131072: Atk/Mag Atk Charms
   262144 = Heaven Book/Tome
   524288: Smilies
   1048576: Guardian Charm
   2097152: Spirit Charm
  }

type
  TpwEmuEquipmentIndex = ( Weapon, Helmet, Necklace, Cape, Shirt, Belt, Pants, Boots, Wrist, RingL, RingR, Arrows, FlyMount, Fashion_top, Fashion_legs,
      Fashion_footwear, Fashion_arms, UtilityCharm, Tome, SmilieSet, Guardian_Charm, Spirit_Charm );

implementation

end.
