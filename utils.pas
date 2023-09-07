unit Utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function LoadByteArray(const AFileName: string): TBytes;
procedure SaveByteArray(AByteArray: TBytes; const AFileName: string);
function InArray(Value: Byte; Arr: TBytes): Boolean;

implementation

function LoadByteArray(const AFileName: string): TBytes;
var
  AStream: TStream;
  ADataLeft: Integer;
begin
  SetLength(result, 0);
  AStream:= TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    try
      AStream.Position:= 0;
      ADataLeft:= AStream.Size;
      SetLength(Result, ADataLeft div SizeOf(Byte));
      AStream.Read(PByte(Result)^, ADataLeft);
    except
      on Exception : EStreamError do
         Result:= Null;
      end;
  finally
    AStream.Free;
  end;
end;

procedure SaveByteArray(AByteArray: TBytes; const AFileName: string);
var
  AStream: TStream;
begin
  if FileExists(AFileName) then DeleteFile(AFileName);
  AStream := TFileStream.Create(AFileName, fmCreate);
  try
     AStream.WriteBuffer(Pointer(AByteArray)^, Length(AByteArray));
  finally
     AStream.Free;
  end;
end;

function InArray(Value: Byte; Arr: TBytes): Boolean;
var i, Len: Word;
begin
  Len:= Length(Arr);
  for i:=0 to Len - 1 do
    if Value = Arr[i] then begin
       Result:= True;
       Exit;
    end;
  Result:= False;
end;

end.

