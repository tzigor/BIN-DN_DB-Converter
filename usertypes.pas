unit UserTypes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

Const
  NewLine = #13#10;
  Tab = #09;
  MIN_FILE_LENGTH = 100;
  //NoDateTimeCmd: TBytes = (22, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 112, 114);
  DateSeparator = '-';
  TimeSeparator = ':';
  ConfigSeparator = ';';
  ConfigParamSeparator = '=';
  TFF_V20 = 2;
  TFF_V30 = 3;
  TFF_V40 = 4;

type
  String32 = String[32];
  String24 = String[24];
  String20 = String[20];
  String16 = String[16];
  String10 = String[10];
  String8 = String[8];
  String4 = String[4];
  String2 = String[2];

type
  TTFFDataChannel = record
    DLIS        : String16;
    Units       : String4;
    RepCode     : String2;
    Samples     : String10;
    AbsentValue : String20;
  end;

  TTFFDataChannels = array of TTFFDataChannel;

  TCurrentParameter = record
    ParamType: String2;
    I1: ShortInt;
    U1: Byte;
    I2: SmallInt;
    U2: Word;
    I4: LongInt;
    U4: LongWord;
    U8: QWord;
    F4: Single;
    F8: Double;
    Str: String;
  end;

  TCurrentRecord = record
    Addr: Byte;
    Cmd: Byte;
    N: Byte;
    Data: TBytes;
    Crc: Byte;
  end;

  TConfigParam = record
    Param: String32;
    Value: String8;
  end;

  TConfigData = record
    Name: String32;
    DataType: String2;
    Size: Byte;
  end;

  TConfig = record
    Addr: Byte;
    Cmd: Byte;
    hasDateTime: Boolean;
    hasVersion: Boolean;
    Version: Byte;
    Data: array of TConfigData;
  end;

  TFrameRecord = record
    DateTime: TDateTime;
    Data: TBytes;
  end;

  TDataConfiguration = array of TConfig;

implementation

end.

