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
    Memo: TMemo;
    OpenBin: TButton;
    CloseApp: TButton;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    MainPage: TTabSheet;
    procedure CloseAppClick(Sender: TObject);
    procedure OpenBinClick(Sender: TObject);
  private

  public

  end;

Const NewLine = #13#10;
      Tab = #09;
      MIN_FILE_LENGTH = 100;
      NoDateTimeCmd: TBytes = (22, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 112, 114);
      DateSeparator = '-';
      TimeSeparator = ':';

type TCurrentRecord = record
       Addr: Byte;
       Cmd: Byte;
       N: Byte;
       Data: TBytes;
       Crc: Byte;
     end;

var
  App: TApp;
  Bytes: TBytes;
  BinDbData: TBytes;
  currentFileSize: LongWord;
  EndOfFile: Boolean;
  Offset: LongWord;

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



function GetDateTimeStr(CurrentRecord: TCurrentRecord): TDateTime;
begin
  with CurrentRecord do begin
    if (Not InArray(Cmd, NoDateTimeCmd)) And (N > 0) then
       Result:= EncodeDateTime(StrToInt(IntToHex(Data[0])), StrToInt(IntToHex(Data[1])), StrToInt(IntToHex(Data[2])),
                      StrToInt(IntToHex(Data[3])), StrToInt(IntToHex(Data[4])), StrToInt(IntToHex(Data[5])), 0);
  end;
  IntToHex(Data[3], 2) + TimeSeparator + IntToHex(Data[4], 2) + TimeSeparator + IntToHex(Data[5], 2);
end;

procedure PraseBin();
var b: Byte;
    CurrentRecord: TCurrentRecord;
    wStr, TimeStr: String;
begin
  TimeStr:= '';
  if LoadBinFile then begin
     repeat
       b:= 0;
       while (b <> $C0) And (Not EndOfFile) do
             b:= GetCurrentByte;
       if b = $C0 then begin
          CurrentRecord:= GetCurrentRecord;
          DateTimeToString(TimeStr, 'd-mmm-yy hh:nn:ss', GetDateTimeStr(CurrentRecord));
          wStr:= wStr + TimeStr + '     Cmd: ' + IntToStr(CurrentRecord.Cmd) + '    N: ' + IntToStr(CurrentRecord.N) + NewLine;
       end;
     until EndOfFile;
     App.Memo.Text:= wStr;
     //ShowMessage('Done');
  end;
end;

procedure TApp.CloseAppClick(Sender: TObject);
begin
  App.Close
end;

procedure TApp.OpenBinClick(Sender: TObject);
begin
  App.Memo.Text:= '';
  PraseBin;
end;

end.

