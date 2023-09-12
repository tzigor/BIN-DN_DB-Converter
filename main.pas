unit Main;

{$mode objfpc}{$H+}
//{$RANGECHECKS ON}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, DateUtils,
  Utils, ConvertToText;

type

  { TApp }

  TApp = class(TForm)
    Button1: TButton;
    ConvertToTxt: TButton;
    LoagConfig: TButton;
    Memo: TMemo;
    OpenBin: TButton;
    CloseApp: TButton;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    MainPage: TTabSheet;
    SaveDialog: TSaveDialog;
    procedure Button1Click(Sender: TObject);
    procedure CloseAppClick(Sender: TObject);
    procedure ConvertToTxtClick(Sender: TObject);
    procedure LoagConfigClick(Sender: TObject);
    procedure OpenBinClick(Sender: TObject);
  private

  public

  end;

Const
  NewLine = #13#10;
  Tab = #09;
  MIN_FILE_LENGTH = 100;
  //NoDateTimeCmd: TBytes = (22, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 112, 114);
  DateSeparator = '-';
  TimeSeparator = ':';
  ConfigSeparator = ';';
  ConfigParamSeparator = '=';

type
  String32 = String[32];
  String24 = String[24];
  String8 = String[8];
  String2 = String[2];

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

  TDataConfiguration = array of TConfig;

var
  App: TApp;
  ConfigList: TStringList;
  ResultList: TStringList;
  Bytes: TBytes;
  BinDbData: TBytes;
  currentFileSize: LongWord;
  EndOfFile: Boolean;
  Offset: LongWord;
  DataConfiguration: TDataConfiguration;
  RecordOffset: Word;
  CurrentParameter: TCurrentParameter;

  function LoadBinFile(): Boolean;
  function GetCurrentByte(): Byte;
  function GetCurrentRecord(): TCurrentRecord;

implementation

{$R *.lfm}

{ TApp }

function LoadBinFile(): Boolean; // Load bin file to the Bytes array
begin
  Result:= False;
  App.OpenDialog.Filter:= '*.bin|*.bin';
  App.OpenDialog.DefaultExt:= '.bin';
  if App.OpenDialog.Execute then begin
     Bytes:= LoadByteArray(App.OpenDialog.FileName);
     if Bytes <> Null then begin
        currentFileSize:= length(Bytes);
        Offset:= 0;
        if currentFileSize >= MIN_FILE_LENGTH then begin
           EndOfFile:= False;
           Result:= True;
        end;
     end;
  end;
end;

function isEndOfFile(): Boolean;
begin
  if Offset = currentFileSize then begin
     EndOfFile:= True;
     Result:= True;
  end
  else Result:= False;
end;

function GetCurrentByte(): Byte;
var b: Byte;
begin
  b:= Bytes[Offset];
  Inc(Offset);
  if isEndOfFile then Exit;
  if b = $DB then begin
     b:= Bytes[Offset];
     if b = $DC then Result:= $C0
     else if b = $DD then Result:= $DB
          else Result:= 0;
     Inc(Offset);
     if isEndOfFile then Exit;
  end
  else Result:= b;
end;

procedure DoCrc(data:byte; var crc:byte);
var i:integer;
begin
  for i:= 0 to 7 do begin
    if (((data xor crc) and 1) <> 0) then crc:= ((crc xor $18) shr 1) or $80
    else crc:= (crc shr 1) and not $80;
    data:= data shr 1;
  end;
end;

function GetCurrentRecord(): TCurrentRecord; // Offset points to ADDR of current record
var CurrentRecord: TCurrentRecord;
    i: Byte;
begin
  if (Bytes[Offset] and $01) > 0 then begin
     CurrentRecord.Addr:= GetCurrentByte;
     CurrentRecord.Cmd:= GetCurrentByte;
  end
  else begin
    CurrentRecord.Addr:= 0;
    CurrentRecord.Cmd:= GetCurrentByte;
  end;
  CurrentRecord.N:= GetCurrentByte;
  SetLength(CurrentRecord.Data, CurrentRecord.N);
  if CurrentRecord.N > 0 then
     for i:=0 to CurrentRecord.N - 1 do CurrentRecord.Data[i]:= GetCurrentByte;
  CurrentRecord.Crc:= GetCurrentByte;
  Result:= CurrentRecord;
end;

function ReadDateTime(CurrentRecord: TCurrentRecord): TDateTime;
begin
  with CurrentRecord do begin
    if N > 0 then
       Result:= EncodeDateTime(StrToInt(IntToHex(Data[0])), StrToInt(IntToHex(Data[1])), StrToInt(IntToHex(Data[2])),
                      StrToInt(IntToHex(Data[3])), StrToInt(IntToHex(Data[4])), StrToInt(IntToHex(Data[5])), 0);
  end;
  Inc(RecordOffset, 6);
end;

function ReadVersion(CurrentRecord: TCurrentRecord): Byte;
begin
  Result:= CurrentRecord.Data[RecordOffset];
  Inc(RecordOffset);
end;

function ReadByte(CurrentRecord: TCurrentRecord): Byte;
begin
  Result:= CurrentRecord.Data[RecordOffset];
  Inc(RecordOffset);
end;

function CommandExist(Cmd: Byte): Boolean;
var ConfigLen, i: Word;
begin
  ConfigLen:= Length(DataConfiguration);
  for i:=0 to ConfigLen - 1 do
     if Cmd = DataConfiguration[i].Cmd then begin
        Result:= True;
        Exit;
     end;
  Result:= False;
end;

function RecordWithDateTme(Cmd: Byte): Boolean;
var ConfigLen, i: Word;
begin
  ConfigLen:= Length(DataConfiguration);
  for i:=0 to ConfigLen - 1 do
     if (Cmd = DataConfiguration[i].Cmd) And (DataConfiguration[i].hasDateTime) then begin
        Result:= True;
        Exit;
     end;
  Result:= False;
end;

function RecordWithVersion(Cmd: Byte): Boolean;
var ConfigLen, i: Word;
begin
  ConfigLen:= Length(DataConfiguration);
  for i:=0 to ConfigLen - 1 do
     if (Cmd = DataConfiguration[i].Cmd) And (DataConfiguration[i].hasVersion) then begin
        Result:= True;
        Exit;
     end;
  Result:= False;
end;

function FindConfiguration(Cmd, Ver: Byte; WVersion: Boolean): Word;
var ConfigLen, i: Word;
begin
  ConfigLen:= Length(DataConfiguration);
  for i:=0 to ConfigLen - 1 do
       if (Cmd = DataConfiguration[i].Cmd) And ((Ver = DataConfiguration[i].Version) Or Not WVersion) then begin
          Result:= i;
          Exit;
       end;
  Result:= 65535;
end;

function ReadParameter(ConfigData: TConfigData; CurrentRecord: TCurrentRecord): TCurrentParameter;
var
    CurrentParameter: TCurrentParameter;
    b1, b2: Byte;
begin
  CurrentParameter.ParamType:= '';
  CurrentParameter.I1:= 0;
  CurrentParameter.U1:= 0;
  CurrentParameter.I2:= 0;
  CurrentParameter.U2:= 0;
  CurrentParameter.I4:= 0;
  CurrentParameter.U4:= 0;
  CurrentParameter.U8:= 0;
  CurrentParameter.F4:= 0;
  CurrentParameter.F8:= 0;
  CurrentParameter.Str:= '';
  with CurrentRecord do begin
     case ConfigData.DataType of
       'i1': begin
                  CurrentParameter.ParamType:= 'I1';
                  CurrentParameter.I1:= ReadByte(CurrentRecord);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.I1);
             end;
       'u1': begin
                  CurrentParameter.ParamType:= 'U1';
                  CurrentParameter.U1:= ReadByte(CurrentRecord);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.U1);
             end;
       'i2': begin
                  CurrentParameter.ParamType:= 'I2';
                  //CurrentParameter.I2:= FillInteger(Data[RecordOffset + 1], Data[RecordOffset]);
                  Move(Data[RecordOffset], CurrentParameter.I2, 2);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.I2);
                  Inc(RecordOffset, 2);
             end;
       'u2': begin
                  CurrentParameter.ParamType:= 'U2';
                  //CurrentParameter.U2:= FillWord(Data[RecordOffset + 1], Data[RecordOffset]);
                  Move(Data[RecordOffset], CurrentParameter.U2, 2);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.U2);
                  Inc(RecordOffset, 2);
             end;
       'i4': begin
                  CurrentParameter.ParamType:= 'I4';
                  //CurrentParameter.I4:= FillLongInt(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset], ConfigData.Size);
                  Move(Data[RecordOffset], CurrentParameter.I4, 4);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.I4);
                  Inc(RecordOffset, ConfigData.Size);
             end;
       'u4': begin
                  CurrentParameter.ParamType:= 'U4';
                  CurrentParameter.U4:= FillLongWord(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset], ConfigData.Size);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.U4);
                  Inc(RecordOffset, ConfigData.Size);
             end;
       'u8': begin
                  CurrentParameter.ParamType:= 'U8';
                  CurrentParameter.U8:= FillQWord(Data[RecordOffset + 7], Data[RecordOffset + 6], Data[RecordOffset + 5], Data[RecordOffset + 4],
                                                  Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset], ConfigData.Size);
                  CurrentParameter.Str:= IntToStr(CurrentParameter.U8);
                  Inc(RecordOffset, ConfigData.Size);
             end;
       'f4': begin
                  CurrentParameter.ParamType:= 'F4';
                  CurrentParameter.F4:= FillSingle(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset]);
                  CurrentParameter.Str:= FloatToStr(CurrentParameter.F4);
                  Inc(RecordOffset, ConfigData.Size);
             end;
       'ba': begin
                  CurrentParameter.ParamType:= 'BA';
                  CurrentParameter.Str:= 'Array';
             end;
     end;
     Result:= CurrentParameter;
  end;
end;

procedure PraseBin();
var b: Byte;
    CurrentRecord: TCurrentRecord;
    wStr, pStr, TimeStr: String;
    Version: Byte;
    ConfigIndex, ConfigDataLen, i: Word;
    RecDateTime: TDateTime;
    WithVersion: Boolean;
    FS: TextFile;
begin
  TimeStr:= '';
  if LoadBinFile then begin
     AssignFile(FS, 'Result.txt');
     try
       Rewrite(FS);
     except
       ShowMessage('File error');
      Exit;
     end;
     pStr:= '';
     if ResultList is TStringList then FreeAndNil(ResultList);
     ResultList:= TStringList.Create;
     repeat
       b:= 0;
       while (b <> $C0) And (Not EndOfFile) do b:= GetCurrentByte;
       if b = $C0 then begin
          CurrentRecord:= GetCurrentRecord;
          RecordOffset:= 0;
          if CommandExist(CurrentRecord.Cmd) then begin
             if RecordWithDateTme(CurrentRecord.Cmd) then RecDateTime:= ReadDateTime(CurrentRecord);
             WithVersion:= RecordWithVersion(CurrentRecord.Cmd);
             if WithVersion then Version:= ReadVersion(CurrentRecord);
             ConfigIndex:= FindConfiguration(CurrentRecord.Cmd, Version, WithVersion);
             if ConfigIndex < 65535 then begin
                //wStr:= IntToStr(CurrentRecord.Cmd);

                if (CurrentRecord.Cmd = 42) And (Version = 2) then begin
                    DateTimeToString(wStr, 'd-mmm-yy hh:nn:ss', RecDateTime);
                    wStr:= wStr + ' - ';
                    ConfigDataLen:= Length(DataConfiguration[ConfigIndex].Data);
                    for i:=0 to ConfigDataLen - 1 do begin
                       wStr:= wStr + DataConfiguration[ConfigIndex].Data[i].Name + '=';
                       CurrentParameter:= ReadParameter(DataConfiguration[ConfigIndex].Data[i], CurrentRecord);
                       if Copy(DataConfiguration[ConfigIndex].Data[i].Name, 1, 3) = 'd_g' then
                           pStr:= FloatToStrF(CurrentParameter.I2  * 1.2 / $7FFF, ffFixed, 10, 4)
                       else if Copy(DataConfiguration[ConfigIndex].Data[i].Name, 1, 3) = 'd_h' then
                                pStr:= FloatToStrF(CurrentParameter.I2  * 120000 / $7FFF, ffFixed, 10, 4)
                            else pStr:= CurrentParameter.Str;
                       wStr:= wStr + pStr + '; ';
                    end;
                end;

             end;
             //ResultList.Add(wStr);
             Writeln(FS, wStr);
             wStr:= '';
          end;
       end;
     until EndOfFile;
     //App.Memo.Text:= wStr;
     //ShowMessage('Done');
     CloseFile(FS);
     //ResultList.SaveToFile('Result.txt');
     ResultList.Free;
  end;
end;

function GetConfigParam(Param: String): TConfigParam;
var ParamLen, i: Byte;
    wStr: String;
begin
  ParamLen:= Length(Param);
  for i:= 1 to ParamLen do begin
    if Param[i] = ConfigParamSeparator then begin
      GetConfigParam.Param:= LowerCase(Trim(wStr));
      wStr:= '';
    end
    else wStr:= wStr + Param[i];
  end;
  GetConfigParam.Value:= LowerCase(Trim(wStr));
end;

procedure ParseConfig();
var i, j, LineLen, ConfigCounter: Word;
    wStr, tStr: String;
    Config: TConfig;
    ConfigParam: TConfigParam;
    ConfigData: TConfigData;
begin
  SetLength(DataConfiguration, 0);
  for i:=0 to ConfigList.Count - 1 do begin
     SetLength(Config.Data, 0);
     LineLen:= Length(ConfigList[i]);
     ConfigCounter:= 0;
     for j:=1 to LineLen do begin
        if (ConfigList[i][j] = ConfigSeparator) Or (j = LineLen) then begin
           ConfigParam:= GetConfigParam(wStr);
           Inc(ConfigCounter);
           case ConfigParam.Param of
             'description':;
             'addr': Config.Addr:= StrToInt(ConfigParam.Value);
             'cmd': Config.Cmd:= StrToInt(ConfigParam.Value);
             'datetime': Config.hasDateTime:= StrToBool(ConfigParam.Value);
             'ver': begin
                      Config.hasVersion:= True;
                      Config.Version:= StrToInt(ConfigParam.Value);
                    end;
           else
             if ConfigParam.Param <> '' then begin
                ConfigData.Name:= ConfigParam.Param;
                ConfigData.DataType:= Copy(ConfigParam.Value, 1, 2);
                ConfigData.Size:= StrToInt(Copy(ConfigParam.Value, 4, 1));
                Insert(ConfigData, Config.Data, ConfigCounter);
             end;
           end;
           wStr:= '';
        end
        else wStr:= wStr + ConfigList[i][j];
     end;
     Insert(Config, DataConfiguration, i + 1);
  end;
end;

function ConfigToStr(const DataConfiguration: TDataConfiguration): String;
var ConfigLen, DataLen, i, j: Word;
    wStr: String;
begin
  ConfigLen:= Length(DataConfiguration);
  for i:=0 to ConfigLen - 1 do begin
     wStr:= wStr + IntToStr(DataConfiguration[i].Addr) + NewLine;
     wStr:= wStr + IntToStr(DataConfiguration[i].Cmd) + NewLine;
     wStr:= wStr + IntToStr(DataConfiguration[i].Version) + NewLine;
     DataLen:= Length(DataConfiguration[i].Data);
     for j:=0 to DataLen - 1 do begin
        wStr:= wStr + DataConfiguration[i].Data[j].Name + ': ' + DataConfiguration[i].Data[j].DataType + NewLine;
     end;
  end;
  Result:= wStr;
end;

procedure LoadConfiguration();
begin
  if ConfigList is TStringList then FreeAndNil(ConfigList);
  ConfigList:= TStringList.Create;
  ConfigList.LoadFromFile('Config.dat');
  ParseConfig;
end;

procedure TApp.LoagConfigClick(Sender: TObject);
begin
  App.OpenDialog.Filter:= '*.dat|*.dat';
  App.OpenDialog.DefaultExt:= '.dat';
  if App.OpenDialog.Execute then begin
     if ConfigList is TStringList then FreeAndNil(ConfigList);
     ConfigList:= TStringList.Create;
     ConfigList.LoadFromFile(OpenDialog.FileName);
     ParseConfig;
     Memo.Text:= ConfigToStr(DataConfiguration);
  end;
end;

procedure TApp.OpenBinClick(Sender: TObject);
begin
  App.Memo.Text:= '';
  LoadConfiguration;
  PraseBin;
end;

procedure TApp.CloseAppClick(Sender: TObject);
begin
  App.Close
end;

procedure TApp.ConvertToTxtClick(Sender: TObject);
begin
  LoadBinFile;
  ConvertToTextProc;
end;

procedure TApp.Button1Click(Sender: TObject);
var i: Byte;
    wStr: String;
begin
  wStr:= '';
  for i:=8 downto 8 + 1 do wStr:= wStr + IntToStr(i) + '; ';
  ShowMessage(wStr);
end;

end.

