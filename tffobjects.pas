unit TffObjects;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, DateUtils,
  Utils, UserTypes;

type
  TTffStructure = object
  private
     DataChannelSize: Word;
     NumberOfChannels: Word;
     TFFDataChannels: TTFFDataChannels;
  public
     constructor Init;
     destructor Done;
     function GetDataChannelSize: Word;
     function GetNumberOfChannels: Word;
     function GetTFFDataChannels: TTFFDataChannels;
     function TFFDataChannelComposer(DLIS, Units, RepCode, Samples: String; TFFVersion: Byte): TTFFDataChannel;
     procedure AddChannel(TFFDataChannel: TTFFDataChannel);
     function GetChannel(Index: Word): TTFFDataChannel;
  end;

  TTffFrames = object
  private
     FrameRecords: array of TFrameRecord;
     NumberOfRecords: longWord;
     DataOffset: Word;
  public
     constructor Init;
     destructor Done;
     function GetCurrentFrameRecord: TFrameRecord;
     procedure AddRecord(DateTime: TDateTime; Size: Word; TFFDataChannels: TTFFDataChannels);
     procedure AddData(Data: ShortInt);
     procedure AddData(Data: Byte);
     procedure AddData(Data: SmallInt);
     procedure AddData(Data: Word);
     procedure AddData(Data: LongInt);
     procedure AddData(Data: LongWord);
     procedure AddData(Data: Single);
     procedure AddData(Data: Double);
  end;

implementation

constructor TTffStructure.Init;
  begin
     DataChannelSize:= 0;
     NumberOfChannels:= 0;
     SetLength(TffDataChannels, 0);
  end;

  destructor TTffStructure.Done;
  begin
     SetLength(TffDataChannels, 0);
  end;

  function TTffStructure.GetDataChannelSize: Word;
  begin
     Result:= DataChannelSize;
  end;

  function TTffStructure.GetNumberOfChannels: Word;
  begin
     Result:= NumberOfChannels;
  end;

  function TTffStructure.GetTFFDataChannels: TTFFDataChannels;
  begin
     Result:= TFFDataChannels;
  end;

  function TTffStructure.TffDataChannelComposer(DLIS, Units, RepCode, Samples: String; TffVersion: Byte): TTffDataChannel;
  var TffDataChannel: TTffDataChannel;
      wStr: String;
  begin
    wStr:= DLIS;
    if TffVersion = Tff_V40 then SetLength(wStr, 16)
    else SetLength(wStr, 10);
    TffDataChannel.DLIS:= wStr;
    wStr:= Samples;
    if TffVersion = Tff_V20 then SetLength(wStr, 4)
    else SetLength(wStr, 10);
    TffDataChannel.Samples:= wStr;

    TffDataChannel.Units:= Units;
    TffDataChannel.RepCode:= RepCode;
    case LowerCase(RepCode) of
       'f4', 'f8': TffDataChannel.AbsentValue:= '-999.25';
       'i1': TffDataChannel.AbsentValue:= '127';
       'u1': TffDataChannel.AbsentValue:= '255';
       'i2': TffDataChannel.AbsentValue:= '32767';
       'u2': TffDataChannel.AbsentValue:= '65535';
       'u4': TffDataChannel.AbsentValue:= '4294967295';
       'i4': TffDataChannel.AbsentValue:= '2147483647';
    end;
    DataChannelSize:= DataChannelSize + StrToInt(Copy(RepCode, 2, 1));
    Result:= TffDataChannel;
  end;

  procedure TTffStructure.AddChannel(TffDataChannel: TTffDataChannel);
  begin
    Insert(TffDataChannel, TffDataChannels, NumberOfChannels + 1);
    Inc(NumberOfChannels);
  end;

  function TTffStructure.GetChannel(Index: Word): TTffDataChannel;
  begin
    if Index < NumberOfChannels then Result:= TffDataChannels[Index];
  end;


 // TTffFrames ////////////////////////////////////////////////////////////////

  constructor TTffFrames.Init();
  begin
     NumberOfRecords:= 0;
     DataOffset:= 0;
     SetLength(FrameRecords, 0);
  end;

  destructor TTffFrames.Done;
  begin
    SetLength(FrameRecords, 0);
  end;

  function TTffFrames.GetCurrentFrameRecord: TFrameRecord;
  begin
    Result:= FrameRecords[NumberOfRecords - 1];
  end;

  procedure TTffFrames.AddData(Data: ShortInt);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 1);
     Inc(DataOffset);
  end;

  procedure TTffFrames.AddData(Data: Byte);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 1);
     Inc(DataOffset);
  end;

  procedure TTffFrames.AddData(Data: SmallInt);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 2);
     Inc(DataOffset, 2);
  end;

  procedure TTffFrames.AddData(Data: Word);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 2);
     Inc(DataOffset, 2);
  end;

  procedure TTffFrames.AddData(Data: LongInt);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 4);
     Inc(DataOffset, 4);
  end;

  procedure TTffFrames.AddData(Data: LongWord);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 4);
     Inc(DataOffset, 4);
  end;

  procedure TTffFrames.AddData(Data: Single);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 4);
     Inc(DataOffset, 4);
  end;

  procedure TTffFrames.AddData(Data: Double);
  begin
     Move(Data, FrameRecords[NumberOfRecords - 1].Data[DataOffset], 8);
     Inc(DataOffset, 8);
  end;

  procedure TTffFrames.AddRecord(DateTime: TDateTime; Size: Word; TFFDataChannels: TTFFDataChannels);
  var FrameRecord: TFrameRecord;
      NumOfChannels, i: Word;
  begin
    FrameRecord.DateTime:= DateTime;
    SetLength(FrameRecord.Data, Size);
    Insert(FrameRecord, FrameRecords, NumberOfRecords + 1);
    Inc(NumberOfRecords);
    DataOffset:= 0;
    NumOfChannels:= Length(TFFDataChannels);
    for i:=0 to NumOfChannels - 1 do begin
       case LowerCase(TFFDataChannels[i].RepCode) of
          'i1': AddData(127);
          'u1': AddData(255);
          'i2': AddData(32767);
          'u2': AddData(65535);
          'u4': AddData(4294967295);
          'i4': AddData(2147483647);
          'f4', 'f8': AddData(-999.25);
       end;
    end;
  end;

end.

