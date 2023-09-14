unit BIN_DB_Converter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, DateUtils,
  Utils, UserTypes, TffObjects;

type
  TBinDbConverter = object
  private
     BinDbData : TBytes;
     DataOffset    : longWord;
  public
     constructor Init;
     destructor Done;
     procedure AddLength(Len: LongWord);
     procedure ParametersComposer(ParametersList: TStringList);
  end;

implementation

constructor TBinDbConverter.Init;
begin
  SetLength(BinDbData, 0);
  DataOffset:= 0;
end;

destructor TBinDbConverter.Done;
begin
  SetLength(BinDbData, 0);
end;

procedure TBinDbConverter.AddLength(Len: LongWord);
begin
  if Len < 65536 then begin
     Insert(Len And $00FF, BinDbData, 4294967295);
     Insert(Len >> 8, BinDbData, 4294967295);
  end
  else begin
     Insert(Len And $000000FF, BinDbData, 4294967295);
     Insert((Len >> 8) And $0000FF, BinDbData, 4294967295);
     Insert(Ord('L'), BinDbData, 4294967295);
     Insert((Len >> 16) And $00FF, BinDbData, 4294967295);
     Insert(Len >> 24, BinDbData, 4294967295);
  end;
end;

procedure TBinDbConverter.ParametersComposer(ParametersList: TStringList);
var i, NumOfParameters, ParamSize: Word;
    j: Byte;

begin
   NumOfParameters:= ParametersList.Count;
   for i:=0 to NumOfParameters - 1 do begin
      ParamSize:= Length(ParametersList[i]) + 2;
      AddLength(ParamSize);
      Insert(Ord('P'), BinDbData, 4294967295);
      for j:=1 to ParamSize - 2 do begin
         Insert(Ord(ParametersList[i][j]), BinDbData, 4294967295);
      end;
      Insert(0, BinDbData, 4294967295);
   end;
   SaveByteArray(BinDbData, 'test.bin_db');
end;

end.

