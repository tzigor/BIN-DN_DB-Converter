unit Main;

{$mode objfpc}{$H+}
//{$RANGECHECKS ON}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, DateUtils,
  Utils;

type

  { TApp }

  TApp = class(TForm)
    LoagConfig: TButton;
    Memo: TMemo;
    OpenBin: TButton;
    CloseApp: TButton;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    MainPage: TTabSheet;
    procedure CloseAppClick(Sender: TObject);
    procedure LoagConfigClick(Sender: TObject);
    procedure OpenBinClick(Sender: TObject);
  private

  public

  end;

Const
  NewLine = #13#10;
  Tab = #09;
  MIN_FILE_LENGTH = 100;
  NoDateTimeCmd: TBytes = (22, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 112, 114);
  DateSeparator = '-';
  TimeSeparator = ':';
  ConfigSeparator = ';';
  ConfigParamSeparator = '=';

type
  String32 = String[32];
  String8 = String[8];
  String2 = String[2];

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
  end;

  TConfig = record
    Addr: Byte;
    Cmd: Byte;
    N: Byte;
    hasDateTime: Boolean;
    hasVersion: Boolean;
    Version: Byte;
    Data: array of TConfigData;
  end;

  TDataConfiguration = array of TConfig;

var
  App: TApp;
  ConfigList: TStringList;
  Bytes: TBytes;
  BinDbData: TBytes;
  currentFileSize: LongWord;
  EndOfFile: Boolean;
  Offset: LongWord;
  DataConfiguration: TDataConfiguration;
  RecordOffset: Word;

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
    if (Not InArray(Cmd, NoDateTimeCmd)) And (N > 0) then
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

function ReadParameter(ConfigData: TConfigData; CurrentRecord: TCurrentRecord): String;
var wStr: String;
begin
  with CurrentRecord do begin
     case ConfigData.DataType of
       'i1', 'u1': wStr:= IntToStr(ReadByte(CurrentRecord));
       'i2': begin
               wStr:= IntToStr(FillInteger(Data[RecordOffset + 1], Data[RecordOffset]));
               Inc(RecordOffset, 2);
             end;
       'u2': begin
               wStr:= IntToStr(FillWord(Data[RecordOffset + 1], Data[RecordOffset]));
               Inc(RecordOffset, 2);
             end;
       'i4': begin
               wStr:= IntToStr(FillLongInt(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset]));
               Inc(RecordOffset, 4);
             end;
       'u4': begin
               wStr:= IntToStr(FillLongWord(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset]));
               Inc(RecordOffset, 4);
             end;
       'f4': begin
               wStr:= FloatToStrF(FillSingle(Data[RecordOffset + 3], Data[RecordOffset + 2], Data[RecordOffset + 1], Data[RecordOffset]), ffFixed, 10, 3);
               Inc(RecordOffset, 4);
             end;
     end;
     Result:= ConfigData.Name + '=' + wStr;
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
begin
  TimeStr:= '';
  if LoadBinFile then begin
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
             if ConfigIndex < 65536 then begin
                ConfigDataLen:= Length(DataConfiguration[ConfigIndex].Data);
                for i:=0 to ConfigDataLen - 1 do begin
                   //pStr:= pStr + ReadParameter(DataConfiguration[ConfigIndex].Data[i], CurrentRecord) + '; ';
                   ReadParameter(DataConfiguration[ConfigIndex].Data[i], CurrentRecord)
                end;
             end;

             DateTimeToString(TimeStr, 'd-mmm-yy hh:nn:ss', RecDateTime);
             //wStr:= wStr + TimeStr + '     Cmd: ' + IntToStr(CurrentRecord.Cmd) + '    Ver: ' + IntToStr(Version) + ' Index: ' + IntToStr(ConfigDataLen) + NewLine;
             wStr:= wStr + TimeStr + '   ' + pStr + NewLine;
          end;
       end;
     until EndOfFile;
     App.Memo.Text:= wStr;
     //ShowMessage('Done');
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
             'addr': Config.Addr:= StrToInt(ConfigParam.Value);
             'cmd': Config.Cmd:= StrToInt(ConfigParam.Value);
             'len': Config.N:= StrToInt(ConfigParam.Value);
             'datetime': Config.hasDateTime:= StrToBool(ConfigParam.Value);
             'ver': begin
                      Config.hasVersion:= True;
                      Config.Version:= StrToInt(ConfigParam.Value);
                    end;
           else
             if ConfigParam.Param <> '' then begin
                ConfigData.Name:= ConfigParam.Param;
                ConfigData.DataType:= ConfigParam.Value;
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
     wStr:= wStr + IntToStr(DataConfiguration[i].N) + NewLine;
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

end.

