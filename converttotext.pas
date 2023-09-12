unit ConvertToText;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, DateUtils, Utils;

procedure ConvertToTextProc();

implementation

uses Main;

procedure ConvertToTextProc();
var
  sDefaultExt ,
  s,sincl           : string;
  FS          : TextFile;
  aUserFreqs  : array[0..3, 0..9] of Integer;
  aFreqs2     : array[0..3] of Integer;
  i, M        ,
  iOffset     ,
  iPrevPercent: Integer;
  d           : Double;
  Flag        : Boolean;
  sInt        : SmallInt;
  w           : Word;
  ADecodedRec : TCurrentRecord;
  ui          : UInt64;
  i64         : Int64;
  shint       : ShortInt;
  Infob       : TBytes;
  smi         : SmallInt;
  b           : Byte;

begin
  App.SaveDialog.Filter:= 'Текстовый файл|*.txt';
  sDefaultExt:= '.txt';
  SetLength(Infob, 100);

  s:= ExtractFileExt(App.SaveDialog.FileName);                                      {проверяем текущее расширение файла в диалоге                                   }
  if (LowerCase(s) <> sDefaultExt)                                              {если текущее расширение файла не соотв-ет sDefaultExt                          }
    then App.SaveDialog.FileName:= ChangeFileExt(App.SaveDialog.FileName, sDefaultExt); {изменяем расширение на нужное                                                  }

  if App.SaveDialog.Execute then
  begin
    s:= ExtractFileExt(App.SaveDialog.FileName);                                    {проверяем текущее расширение файла в диалоге                                   }
    if (LowerCase(s) <> sDefaultExt) then                                       {если текущее расширение файла не соотв-ет sDefaultExt                          }
      App.SaveDialog.FileName:= ChangeFileExt(App.SaveDialog.FileName, sDefaultExt); {изменяем расширение на нужное                                                }

    AssignFile(FS, App.SaveDialog.FileName);

    try
      Rewrite(FS);
    except
      ShowMessage('File error');
      Exit;
    end;                                                            {разбор журнала начинаем с самого его начала (с нулевого адреса)                }

    try
      repeat
        Flag:= False;                                                           {следующую запись в журнале пока не нашли                                       }
        b:= 0;
        while (b <> $C0) And (Not EndOfFile) do b:= GetCurrentByte;                                              {запись всегда начинается с $C0 (протокол Wake)                                 }

        if b = $C0 then                                           {если не вышли за границу массива и нашли $C0                                   }
               Flag:= True;

        if Flag then
        begin
          ADecodedRec:= GetCurrentRecord;
          RecordOffset:= 0;
          if  ADecodedRec.N > 0 then begin
              if(ADecodedRec.Cmd = 22) or (ADecodedRec.Cmd = 101)  or (ADecodedRec.Cmd = 102) or (ADecodedRec.Cmd = 103) or (ADecodedRec.Cmd = 104)
                 or (ADecodedRec.Cmd = 105) or (ADecodedRec.Cmd = 106) or (ADecodedRec.Cmd = 107) or (ADecodedRec.Cmd = 108) or (ADecodedRec.Cmd = 109)
                 or (ADecodedRec.Cmd = 110) or (ADecodedRec.Cmd = 111) or (ADecodedRec.Cmd = 112) or (ADecodedRec.Cmd = 113) or (ADecodedRec.Cmd = 114)
              then
              begin
                    //  s:= EmptyStr;
              end
              else
              begin
               Writeln(FS, emptystr);
               s:=       IntToHex(aDecodedRec.Data[2], 2) + DateSeparator + IntToHex(aDecodedRec.Data[1], 2) + DateSeparator + IntToHex(aDecodedRec.Data[0], 2) + ' ' +
                        IntToHex(aDecodedRec.Data[3], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[4], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[5], 2);
               Write(FS, s + #09);                                                   {пишем в файл дату и время записи журнала и добавляем табулятор                 }
              end;

              s:= EmptyStr;
              case ADecodedRec.Cmd of
                01: {$REGION ' запись при выключении питания '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[27]: данные. }
                      Writeln(FS, 'Выключение питания');                        {строку с описанием кода записи делаем строкой-заголовком                       }

                      {Buf[06]..Buf[08]: время в секундах работы от включения до выключения питания. }
                      i:= 0;
                      Move(ADecodedRec.Data[6], i, 3);
                      s:= #09#09#09#09 + IntToStr(i) + #09+ 'время в секундах работы от включения до выключения питания';
                      Writeln(FS, s);

                      {Buf[09]..Buf[11]: время в секундах работы в данном рейсе. }
                      i:= 0;
                      Move(ADecodedRec.Data[9], i, 3);
                      s:= #09#09#09#09 + IntToStr(i) + #09+ 'время в секундах работы в данном рейсе';
                      Writeln(FS, s);

                      {Buf[12]..Buf[15]: время в секундах общей работы. }
                      Move(ADecodedRec.Data[12], i, 4);
                      s:= #09#09#09#09 + IntToStr(i) + #09+ 'время в секундах общей работы';
                      Writeln(FS, s);

                      {Buf[16]..Buf[18]: общее количество ударов. }
                      i:= 0;
                      Move(ADecodedRec.Data[16], i, 3);
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'общее количество ударов';
                      Writeln(FS, s);

                      {Buf[19]..Buf[22]: оставшееся количество ампер часов силовой батареи. }
                      Move(ADecodedRec.Data[19], i, 4);
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'оставшееся количество ампер-часов силовой батареи';
                      Writeln(FS, s);

                      {Buf[23]: номер используемого набора пакетов. }
                      i:= ADecodedRec.Data[23];
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'номер используемого набора пакетов';
                      Writeln(FS, s);

                      {Buf[24]: тип модуляции. }
                      i:= ADecodedRec.Data[24];
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'тип модуляции';
                      Writeln(FS, s);

                      {Buf[25]: индекс таблицы частота/скорость передачи. }
                      i:= ADecodedRec.Data[25];
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'индекс таблицы частота/скорость передачи';
                      Writeln(FS, s);

                      {Buf[26]..Buf[27]: код завершения работы. }
                      i:= 0;
                      Move(ADecodedRec.Data[26], i, 2);
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + 'код завершения работы';
                      Writeln(FS, s);

                      {Buf[28]: напряжение холостого хода аккумуляторной батареи*50. }
                      s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[28] / 50]) + #09#09 + 'напряжение холостого хода аккумуляторной батареи*50';
                      Writeln(FS, s);

                      {Buf[29]: напряжение аккумуляторной батареи под нагрузкой*50. }
                      s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[29] / 50]) + #09#09 + 'напряжение аккумуляторной батареи под нагрузкой*50';
                    end;
                    {$ENDREGION}

                02: {$REGION ' запись статического замера '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[21]: данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Статический замер');

                      {Buf[06]..Buf[07]: показания акселерометра AX. }
                      Move(ADecodedRec.Data[6], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AX';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: показания акселерометра AY. }
                      Move(ADecodedRec.Data[8], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AY';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: показания акселерометра AZ. }
                      Move(ADecodedRec.Data[10], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AZ';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: показания магнитометра BX. }
                      Move(ADecodedRec.Data[12], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BX';
                      Writeln(FS, s);

                      {Buf[14]..Buf[15]: показания магнитометра BY. }
                      Move(ADecodedRec.Data[14], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BY';
                      Writeln(FS, s);

                      {Buf[16]..Buf[17]: показания магнитометра BZ. }
                      Move(ADecodedRec.Data[16], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BZ';
                      Writeln(FS, s);

                      {Buf[18]..Buf[19]: приращение отклонителя. }
                      Move(ADecodedRec.Data[18], sInt, 2);
                      s:= #09#09#09#09 + IntToStr(sInt) + #09#09 + 'приращение отклонителя';
                      Writeln(FS, s);

                      {Buf[20]..Buf[21]: максимум пульсаций акселерометров. }
                      Move(ADecodedRec.Data[20], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'максимум пульсаций акселерометров';
                    end;
                    {$ENDREGION}

                03: {$REGION ' запись динамического замера '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[19]: данные. }
                      Writeln(FS, 'Динамический замер');

                      {Buf[06]..Buf[07]: показания акселерометра AX. }
                      Move(ADecodedRec.Data[6], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AX';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: показания акселерометра AY. }
                      Move(ADecodedRec.Data[8], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AY';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: показания акселерометра AZ. }
                      Move(ADecodedRec.Data[10], sInt, 2);
                      s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AZ';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: показания магнитометра BX. }
                      Move(ADecodedRec.Data[12], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BX';
                      Writeln(FS, s);

                      {Buf[14]..Buf[15]: показания магнитометра BY. }
                      Move(ADecodedRec.Data[14], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BY';
                      Writeln(FS, s);

                      {Buf[16]..Buf[17]: показания магнитометра BZ. }
                      Move(ADecodedRec.Data[16], sInt, 2);
                      i64:= sInt;
                      s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BZ';
                      Writeln(FS, s);

                      {Buf[18]: скорость вращения буровой колонны, об/мин. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]) + #09#09 + 'скорость вращения буровой колонны, об/мин';
                      Writeln(FS, s);

                      {Buf[19]: температура модуля инклинометра. }
                       //s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + #09#09 + 'температура модуля инклинометра';
                       Move(ADecodedRec.Data[19], shint, 1);
                       s:= #09#09#09#09 + IntToStr(shint) + #09#09 + 'температура модуля инклинометра';
                    end;
                    {$ENDREGION}

                04: {$REGION ' запись смещения отклонителя '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Смещение отклонителя');

                      {Buf[06]..Buf[07]: смещение отклонителя. }
                      Move(ADecodedRec.Data[6], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'смещение отклонителя';
                    end;
                    {$ENDREGION}

                06: {$REGION ' запись параметров передачи силового модуля '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[26]: данные. }
                      Writeln(FS, 'Параметры передачи силового модуля');

                      {Buf[06]..Buf[07]: ток инвертора. }
                      Move(ADecodedRec.Data[6], w, 2);
                      s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09#09 + 'ток инвертора';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: максимум входного напряжения. }
                      Move(ADecodedRec.Data[8], w, 2);
                      s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09#09 + 'максимум входного напряжения';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: минимум входного напряжения. }
                      Move(ADecodedRec.Data[10], w, 2);
                      s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09#09 + 'минимум входного напряжения';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: обороты генератора. }
                      Move(ADecodedRec.Data[12], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'обороты генератора';
                      Writeln(FS, s);

                      {Buf[14]..Buf[15]: сопротивление нагрузки. }
                      Move(ADecodedRec.Data[14], w, 2);
                      s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09#09 + 'сопротивление нагрузки';
                      Writeln(FS, s);

                      {Buf[16]..Buf[17]: приращение ампер-часов силовой батареи. }
                      Move(ADecodedRec.Data[16], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'приращение ампер-часов силовой батареи';
                      Writeln(FS, s);

                      {Buf[18]..Buf[19]: количество ударов. }
                      Move(ADecodedRec.Data[18], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'количество ударов';
                      Writeln(FS, s);

                      {Buf[20]..Buf[21]: максимум по оси Х. }
                      Move(ADecodedRec.Data[20], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'максимум по оси Х';
                      Writeln(FS, s);

                      {Buf[22]..Buf[23]: максимум по оси Y. }
                      Move(ADecodedRec.Data[22], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'максимум по оси Y';
                      Writeln(FS, s);

                      {Buf[24]..Buf[25]: максимум по оси Z. }
                      Move(ADecodedRec.Data[24], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'максимум по оси Z';
                      Writeln(FS, s);

                      {Buf[26]: максимум количества ударов в секунду. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]) + #09#09 + 'максимум количества ударов в секунду';
                      Writeln(FS, s);

                      {Buf[27]: степень залипания колонны. }
                      Move(ADecodedRec.Data[27], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'степень залипания колонны';
                    end;
                    {$ENDREGION}

                07: {$REGION ' запись количества слов синхронизирующей преамбулы '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : данные. }
                      Writeln(FS, 'Слова синхронизирующей преамбулы');

                      {Buf[06]: количество слов синхронизирующей преамбулы. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + #09#09 + 'количество слов синхронизирующей преамбулы';
                    end;
                    {$ENDREGION}

                08: {$REGION ' запись типа модуляции '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Тип модуляции');

                      {Buf[06]: тип модуляции. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + #09 + 'тип модуляции';
                      Writeln(FS, s);

                      {Buf[07]: источник изменения (0..2). }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09 + 'источник изменения';
                    end;
                    {$ENDREGION}

                09: {$REGION ' запись индекса таблицы частота/скорость '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Несущая частота (скорость)');

                      {Buf[06]: индекс таблицы. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + #09#09 + 'индекс таблицы';
                      Writeln(FS, s);

                      {Buf[07]: источник изменения (0..2). }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09#09 + 'источник изменения (0..2)';
                    end;
                    {$ENDREGION}

                10: {$REGION ' запись разрешения/запрета ответа при изменении режимов работы '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : данные. }
                      Writeln(FS, 'Ответ при смене режима работы');

                      {Buf[06]: код разрешения/запрета ответа при изменении режимов работы. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + #09#09 + 'код разрешения/запрета ответа при изменении режимов работы';
                    end;
                    {$ENDREGION}

                11: {$REGION ' запись разрешения/запрета изменения режимов работы '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : данные. }
                      Writeln(FS, 'Смена режима работы');

                      {Buf[06]: код разрешения/запрета изменения режимов работы. }
                      s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + #09#09 + 'код разрешения/запрета изменения режимов работы';
                    end;
                    {$ENDREGION}

                24: {$REGION ' запись тока статики '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[17]: данные. }
                      Writeln(FS, 'Ток статики');

                      {Buf[06]..Buf[07]: ток статики при частоте 10 Гц. }
                      Move(ADecodedRec.Data[06], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 10 Гц, А';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: ток статики при частоте 5 Гц. }
                      Move(ADecodedRec.Data[08], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 5 Гц, А';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: ток статики при частоте 2.5 Гц. }
                      Move(ADecodedRec.Data[10], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 2.5 Гц, А';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: ток статики при частоте 1.25 Гц. }
                      Move(ADecodedRec.Data[12], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 1.25 Гц, А';
                      Writeln(FS, s);

                      {Buf[14]..Buf[15]: ток статики при частоте 0.625 Гц. }
                      Move(ADecodedRec.Data[14], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 0.625 Гц, А';
                      Writeln(FS, s);

                      {Buf[16]..Buf[17]: ток статики при частоте 0.3125 Гц. }
                      Move(ADecodedRec.Data[16], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 0.3125 Гц, А';
                    end;
                    {$ENDREGION}

                25: {$REGION ' запись тока динамики '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[17]: данные. }
                      Writeln(FS, 'Ток динамики');

                      {Buf[06]..Buf[07]: ток динамики при частоте 10 Гц. }
                      Move(ADecodedRec.Data[06], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 10 Гц, А';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: ток динамики при частоте 5 Гц. }
                      Move(ADecodedRec.Data[08], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 5 Гц, А';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: ток динамики при частоте 2.5 Гц. }
                      Move(ADecodedRec.Data[10], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 2.5 Гц, А';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: ток динамики при частоте 1.25 Гц. }
                      Move(ADecodedRec.Data[12], w, 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 1.25 Гц, А';
                      Writeln(FS, s);

                      {Buf[14]..Buf[15]: ток динамики при частоте 0.625 Гц. }
                      Move(ADecodedRec.Data[14], w , 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 0.625 Гц, А';
                      Writeln(FS, s);

                      {Buf[16]..Buf[17]: ток динамики при частоте 0.3125 Гц. }
                      Move(ADecodedRec.Data[16], w , 2);
                      d:= w / 10;
                      s:= #09#09#09#09 + FormatFloat('#0.0', d) + #09#09 + 'при частоте 0.3125 Гц, А';
                    end;
                    {$ENDREGION}

                26: {$REGION ' запись интервалов времени манипуляции давлением '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[13]: данные. }
                      Writeln(FS, 'Интервалы манипуляции давлением');

                      {Buf[06]..Buf[07]: интервал времени Т0. }
                      Move(ADecodedRec.Data[06], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'интервал времени Т0, с';
                      Writeln(FS, s);

                      {Buf[08]..Buf[09]: интервал времени Т1. }
                      Move(ADecodedRec.Data[08], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'интервал времени Т1, с';
                      Writeln(FS, s);

                      {Buf[10]..Buf[11]: интервал времени Т2. }
                      Move(ADecodedRec.Data[10], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'интервал времени Т2, с';
                      Writeln(FS, s);

                      {Buf[12]..Buf[13]: интервал времени Т3. }
                      Move(ADecodedRec.Data[12], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + #09#09 + 'интервал времени Т3, с';
                    end;
                    {$ENDREGION}



                33: {$REGION ' запись широты местности '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : данные. }
                      Writeln(FS, 'Широта местности');

                      {Buf[06]: широта местности. }
                     // s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[06]) + '°';

                      // w:= MakeWord(ADecodedRec.Data[07],ADecodedRec.Data[06]);
                     //// Move(ADecodedRec.Data[06], w, 2);
                      // s:= #09#09#09#09 + Format('%.2f', [w / 100]) + '°';

                        smi:= FillWord(ADecodedRec.Data[07],ADecodedRec.Data[06]);
                         s:= #09#09#09#09 + Format('%.2f', [smi / 100]) + '°';

                    end;
                    {$ENDREGION}

                34: {$REGION ' запись модуля вектора магнитного поля местности '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[09]: данные. }
                      Writeln(FS, 'Модуль вектора магнитного поля местности');

                      {Buf[06]..Buf[09]: модуль вектора магнитного поля местности. }
                      Move(ADecodedRec.Data[06], i, 4);
                      s:= #09#09#09#09 + IntToStr(i) + #09#09 + ', нТл';
                    end;
                    {$ENDREGION}

                35: {$REGION ' запись магнитного наклонения местности '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Наклонение вектора магн. поля местности(DIP)');

                      {Buf[06]..Buf[07]: магнитное наклонение местности. }
                     // Move(ADecodedRec.Data[06], w, 2);
                     // d:= w / 100;
                      Move(ADecodedRec.Data[06], smi, 2);
                      d:= smi / 100;
                      s:= #09#09#09#09 + FormatFloat('#0.00°', d);
                    end;
                    {$ENDREGION}

                36: {$REGION ' запись высоты местности '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Высота местности');

                      {Buf[06]..Buf[07]: высота местности. }
                      Move(ADecodedRec.Data[06], w, 2);
                      s:= #09#09#09#09 + IntToStr(w) + ' м';
                    end;
                    {$ENDREGION}

                37: {$REGION ' обороты колонны*100 [об/мин], выше которых включаются роторные пакеты '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Верхний порог оборотов колонны');

                      {Buf[06]..Buf[07]: 'Верхний порог оборотов колонны' }
                      Move(ADecodedRec.Data[06], w, 2);
                      d:= w / 100;
                      s:= #09#09#09#09 + FormatFloat('#0.00', d) + ' об/мин';
                    end;
                    {$ENDREGION}

                38: {$REGION ' обороты колонны*100 [об/мин], ниже которых включаются роторные пакеты '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]..Buf[07]: данные. }
                      Writeln(FS, 'Нижний порог оборотов колонны');

                      {Buf[06]..Buf[07]: 'Нижний порог оборотов колонны'. }
                      Move(ADecodedRec.Data[06], w, 2);
                      d:= w / 100;
                      s:= #09#09#09#09 + FormatFloat('#0.00', d) + ' об/мин';
                    end;
                    {$ENDREGION}

                39: {$REGION ' разрешение =1 запрет =0 режима автоматического переключения роторных пакетов '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : данные. }
                      Writeln(FS, 'Работа с роторным набором пакетов');

                      {Buf[06]: 'Работа с роторным набором пакетов' }
                      case ADecodedRec.Data[06] of
                        0 : s:= #09#09#09#09 + 'запрещено';
                        1 : s:= #09#09#09#09 + 'разрешено';
                        else
                            s:= #09#09#09#09 + 'error!';
                      end;
                    end;
                    {$ENDREGION}

                40: {$REGION ' запись при выключении питания - другой формат ударов (бывш. 01) '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 40.
                       Buf[07]..Buf[50]: данные.                 }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Выключение питания (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                 {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]: средняя величина удара превышающего 50G (в G) по X. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'средняя величина удара превышающего 50G (в G) по X';
                              Writeln(FS, s);

                              {Buf[18]..Buf[25]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[18], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по X';
                              Writeln(FS, s);

                              {Buf[26]: средняя величина удара превышающего 50G (в G) по Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]) + #09+ 'средняя величина удара превышающего 50G (в G) по Y';
                              Writeln(FS, s);

                              {Buf[27]..Buf[34]: время длит. среднего удара превышающего 50G (*25мкс) по Y. }
                              Move(ADecodedRec.Data[27], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Y';
                              Writeln(FS, s);

                              {Buf[35]: средняя величина удара превышающего 50G (в G) по Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[35]) + #09+ 'средняя величина удара превышающего 50G (в G) по Z';
                              Writeln(FS, s);

                              {Buf[36]..Buf[43]: время длит. среднего удара превышающего 50G (*25мкс) по Z. }
                              Move(ADecodedRec.Data[36], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Z';
                              Writeln(FS, s);

                              {Buf[44]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[44]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);

                              {Buf[46]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[46]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[47]..Buf[48]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 47, бит 0.}
                                if ((ADecodedRec.Data[47] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 1.}
                                if ((ADecodedRec.Data[47] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 2.}
                                if ((ADecodedRec.Data[47] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 3.}
                                if ((ADecodedRec.Data[47] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 4.}
                                if ((ADecodedRec.Data[47] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 5.}
                                if ((ADecodedRec.Data[47] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 6.}
                                if ((ADecodedRec.Data[47] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 7 и биты 0..3 байта 48 здесь не используются. }

                                {байт 48, бит 4.}
                                if ((ADecodedRec.Data[48] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 5.}
                                if ((ADecodedRec.Data[48] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 48, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[48] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[48] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[49]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[49] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[50]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[50] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                            end;
                            {$ENDREGION}

                        01: {$REGION ' версия №01 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]: средняя величина удара превышающего 50G (в G) по X. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'средняя величина удара превышающего 50G (в G) по X';
                              Writeln(FS, s);

                              {Buf[18]..Buf[25]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[18], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по X';
                              Writeln(FS, s);

                              {Buf[26]: средняя величина удара превышающего 50G (в G) по Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]) + #09+ 'средняя величина удара превышающего 50G (в G) по Y';
                              Writeln(FS, s);

                              {Buf[27]..Buf[34]: время длит. среднего удара превышающего 50G (*25мкс) по Y. }
                              Move(ADecodedRec.Data[27], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Y';
                              Writeln(FS, s);

                              {Buf[35]: средняя величина удара превышающего 50G (в G) по Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[35]) + #09+ 'средняя величина удара превышающего 50G (в G) по Z';
                              Writeln(FS, s);

                              {Buf[36]..Buf[43]: время длит. среднего удара превышающего 50G (*25мкс) по Z. }
                              Move(ADecodedRec.Data[36], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Z';
                              Writeln(FS, s);

                              {Buf[44]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[44]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);

                              {Buf[46]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[46]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[47]..Buf[48]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 47, бит 0.}
                                if ((ADecodedRec.Data[47] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 1.}
                                if ((ADecodedRec.Data[47] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 2.}
                                if ((ADecodedRec.Data[47] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 3.}
                                if ((ADecodedRec.Data[47] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 4.}
                                if ((ADecodedRec.Data[47] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 5.}
                                if ((ADecodedRec.Data[47] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 6.}
                                if ((ADecodedRec.Data[47] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 7 и биты 0..3 байта 48 здесь не используются. }

                                {байт 48, бит 4.}
                                if ((ADecodedRec.Data[48] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 5.}
                                if ((ADecodedRec.Data[48] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 48, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[48] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[48] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[49]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[49] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[50]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[50] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[51]..Buf[52]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[51], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                            end;
                            {$ENDREGION}

                        02: {$REGION ' версия №02 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]: средняя величина удара превышающего 50G (в G) по X. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'средняя величина удара превышающего 50G (в G) по X';
                              Writeln(FS, s);

                              {Buf[18]..Buf[25]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[18], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по X';
                              Writeln(FS, s);

                              {Buf[26]: средняя величина удара превышающего 50G (в G) по Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]) + #09+ 'средняя величина удара превышающего 50G (в G) по Y';
                              Writeln(FS, s);

                              {Buf[27]..Buf[34]: время длит. среднего удара превышающего 50G (*25мкс) по Y. }
                              Move(ADecodedRec.Data[27], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Y';
                              Writeln(FS, s);

                              {Buf[35]: средняя величина удара превышающего 50G (в G) по Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[35]) + #09+ 'средняя величина удара превышающего 50G (в G) по Z';
                              Writeln(FS, s);

                              {Buf[36]..Buf[43]: время длит. среднего удара превышающего 50G (*25мкс) по Z. }
                              Move(ADecodedRec.Data[36], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс) по Z';
                              Writeln(FS, s);

                              {Buf[44]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[44]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);


                              {Buf[46]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[46]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[47]..Buf[48]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 47, бит 0.}
                                if ((ADecodedRec.Data[47] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 1.}
                                if ((ADecodedRec.Data[47] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 2.}
                                if ((ADecodedRec.Data[47] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 3.}
                                if ((ADecodedRec.Data[47] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 4.}
                                if ((ADecodedRec.Data[47] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 5.}
                                if ((ADecodedRec.Data[47] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 6.}
                                if ((ADecodedRec.Data[47] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 47, бит 7.}
                                if ((ADecodedRec.Data[47] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 48, бит 1.}
                                if ((ADecodedRec.Data[48] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 2.}
                                if ((ADecodedRec.Data[48] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 3.}
                                if ((ADecodedRec.Data[48] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 4.}
                                if ((ADecodedRec.Data[48] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 48, бит 5.}
                                if ((ADecodedRec.Data[48] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 48, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[48] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[48] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[49]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[49] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[50]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[50] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[51]..Buf[52]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[51], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[53]..Buf[55]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[53], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                            end;
                            {$ENDREGION}

                        03: {$REGION ' версия №03 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);


                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                            end;
                            {$ENDREGION}

                        04: {$REGION ' версия №04 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);
    ;

                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);

                            end;
                            {$ENDREGION}

                        05:  {$REGION ' версия №05 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);

                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);


                            end;
                            {$ENDREGION}

                        06:  {$REGION ' версия №06 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);


                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);


                               {Buf[39]..Buf[46]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[39], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[47]..Buf[54]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[47], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';

                            end;
                            {$ENDREGION}

                        07:  {$REGION ' версия №07 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);

                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);


                               {Buf[39]..Buf[46]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[39], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[47]..Buf[54]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[47], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                              {Buf[55]: темепратура  }
                              Move(ADecodedRec.Data[55], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + #09+ 'температура инклинометра';

                            end;
                            {$ENDREGION}

                        08:  {$REGION ' версия №08 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);

                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);


                               {Buf[39]..Buf[46]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[39], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[47]..Buf[54]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[47], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                              {Buf[55]: темепратура  }
                              Move(ADecodedRec.Data[55], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + #09+ 'температура инклинометра';
                               Writeln(FS, s);

                             //s:=  #09#09#09#09 + IntToHex(aDecodedRec.Data[58], 2) + DateSeparator + IntToHex(aDecodedRec.Data[57], 2) + DateSeparator + IntToHex(aDecodedRec.Data[56], 2) + ' ' +
                             //     IntToHex(aDecodedRec.Data[59], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[60], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[61], 2) +
                              //    #09 + 'время прихода команды на отключение передачи';

                                 {Buf[56-57]: оставшиеся время в минутах до включения передачи }
                              Move(ADecodedRec.Data[56], w, 2);
                              s:= #09#09#09#09  + IntToStr(w)  + ' мин.' + #09 + 'оставшиеся время до включения передачи';

                            end;
                            {$ENDREGION}

                        09:  {$REGION ' версия №09 '}
                            begin
                              {Buf[07]..Buf[09]: время в секундах работы от включения до выключения питания. }
                              i:= 0;
                              Move(ADecodedRec.Data[07], i, 3);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время работы от включения до выключения питания';
                              Writeln(FS, s);

                              {Buf[10]..Buf[12]: время в секундах работы в данном рейсе. }
                              i:= 0;
                              Move(ADecodedRec.Data[10], i, 3);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время работы в данном рейсе';
                              Writeln(FS, s);

                              {Buf[13]..Buf[16]: время в секундах общей работы. }
                              Move(ADecodedRec.Data[13], i, 4);
                              s:= #09#09#09#09 + FormatSeconds(i) + #09+ 'время общей работы';
                              Writeln(FS, s);

                              {Buf[17]..Buf[24]: время длит. среднего удара превышающего 50G (*25мкс) по X. }
                              Move(ADecodedRec.Data[17], ui, 8);
                              s:= #09#09#09#09 + IntToStr(ui) + #09+ 'время длит. среднего удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[25]: номер используемого набора пакетов. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]) + #09+ 'номер используемого набора пакетов';
                              Writeln(FS, s);


                              {Buf[27]: индекс таблицы частота/скорость передачи. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'индекс таблицы частота/скорость передачи';
                              Writeln(FS, s);

                              {Buf[28]..Buf[29]: код завершения работы. }
                              s:= #09#09#09#09 + 'код завершения работы';
                              Writeln(FS, s);

                                {байт 28, бит 0.}
                                if ((ADecodedRec.Data[28] and 1) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 1.}
                                if ((ADecodedRec.Data[28] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 2.}
                                if ((ADecodedRec.Data[28] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 3.}
                                if ((ADecodedRec.Data[28] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 4.}
                                if ((ADecodedRec.Data[28] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 5.}
                                if ((ADecodedRec.Data[28] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 6.}
                                if ((ADecodedRec.Data[28] and 64) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 28, бит 7.}
                                if ((ADecodedRec.Data[28] and 128) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 0.}
                                //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                                {байт 29, бит 1.}
                                if ((ADecodedRec.Data[29] and 2) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора не пригоден для записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 2.}
                                if ((ADecodedRec.Data[29] and 4) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 3.}
                                if ((ADecodedRec.Data[29] and 8) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 4.}
                                if ((ADecodedRec.Data[29] and 16) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                  Writeln(FS, s);
                                end;

                                {байт 29, бит 5.}
                                if ((ADecodedRec.Data[29] and 32) <> 0) then begin
                                  s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                  Writeln(FS, s);
                                end;

                                {байт 29, биты 6 и 7.}
                                w:= 0;
                                if ((ADecodedRec.Data[29] and  64) <> 0) then w:= w + 1;
                                if ((ADecodedRec.Data[29] and 128) <> 0) then w:= w + 2;
                                case w of
                                  0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                  1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                  2,
                                  3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                                end;
                                Writeln(FS, s);


                              {Buf[30]: напряжение холостого хода аккумуляторной батареи*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[30] / 50]) + #09+ 'напряжение холостого хода аккумуляторной батареи*50';
                              Writeln(FS, s);

                              {Buf[31]: напряжение аккумуляторной батареи под нагрузкой*50. }
                              s:= #09#09#09#09 + Format('%.2f', [ADecodedRec.Data[31] / 50]) + #09+ 'напряжение аккумуляторной батареи под нагрузкой*50';
                              Writeln(FS, s);

                              {Buf[32]..Buf[33]: ограничение мощности [Вт]. }
                              Move(ADecodedRec.Data[32], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + ' Вт'#09+ 'ограничение мощности';
                              Writeln(FS, s);

                              {Buf[34]..Buf[36]: энергия цикла заряда аккумулятора [мА*мин]. }
                              i:= 0;
                              Move(ADecodedRec.Data[34], i, 3);
                              d:= i / 496200;                                       {переводим из мА*мин в А*час                                                    }
                              s:= #09#09#09#09 + FormatFloat('#0.000000', d) + #09 + 'энергия цикла заряда аккумулятора, А*час';
                              Writeln(FS, s);


                               {Buf[39]..Buf[46]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[39], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[47]..Buf[54]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[47], i64, 8);
                              s:= #09#09#09#09 + IntToStr(i64) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                              {Buf[55]: темепратура  }
                              Move(ADecodedRec.Data[55], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + #09+ 'температура инклинометра';
                               Writeln(FS, s);

                             //s:=  #09#09#09#09 + IntToHex(aDecodedRec.Data[58], 2) + DateSeparator + IntToHex(aDecodedRec.Data[57], 2) + DateSeparator + IntToHex(aDecodedRec.Data[56], 2) + ' ' +
                             //     IntToHex(aDecodedRec.Data[59], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[60], 2) + TimeSeparator + IntToHex(aDecodedRec.Data[61], 2) +
                              //    #09 + 'время прихода команды на отключение передачи';

                                 {Buf[56-57]: оставшиеся время в минутах до включения передачи }
                              Move(ADecodedRec.Data[56], w, 2);
                              s:= #09#09#09#09  + IntToStr(w)  + ' мин.' + #09 + 'оставшиеся время до включения передачи';
                               Writeln(FS, s);

                               {Buf[58-59]: нуль датчика ударов по оси Х }
                              Move(ADecodedRec.Data[58], w, 2);
                              s:= #09#09#09#09  + IntToStr(w)  +  #09 + 'нуль датчика ударов по оси Х';
                               Writeln(FS, s);

                               {Buf[60-61]: нуль датчика ударов по оси Y }
                              Move(ADecodedRec.Data[60], w, 2);
                              s:= #09#09#09#09  + IntToStr(w)  +  #09 + 'нуль датчика ударов по оси Y';
                               Writeln(FS, s);

                              {Buf[62-63]: нуль датчика ударов по оси Z }
                              Move(ADecodedRec.Data[62], w, 2);
                              s:= #09#09#09#09  + IntToStr(w)  +  #09 + 'нуль датчика ударов по оси Z';

                            end;
                            {$ENDREGION}

                        { ВНИМАНИЕ! ПРИ ПОЯВЛЕНИИ НОВЫХ ВЕРСИЙ ПАКЕТА [40]
                          НУЖНО ВНЕСТИ ИЗМЕНЕНИЯ В XLS-ОТЧЁТ "РЕГИСТРАЦИЯ РАБОТЫ"! }
                      end;
                    end;
                    {$ENDREGION}

                41: {$REGION ' запись параметров передачи силового модуля - новый формат ударов (бывш. 06) '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 41.
                       Buf[07]..Buf[35]: данные.                 }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Параметры передатчика (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }

                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]..Buf[08]: ток инвертора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'ток инвертора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: максимум входного напряжения. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'максимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: минимум входного напряжения. }
                              Move(ADecodedRec.Data[11], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'минимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: обороты генератора. }
                              Move(ADecodedRec.Data[13], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: сопротивление нагрузки. }
                              Move(ADecodedRec.Data[15], w, 2);
                              s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09+ 'сопротивление нагрузки';
                              Writeln(FS, s);

                              {Buf[17]: средняя величина удара превышающего 50G (в G) по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'средняя величина  удара превышающего  50G (в G) по оси Х';
                              Writeln(FS, s);

                              {Buf[18]..Buf[21]: время длит. сред. удара превышающего 50G (*25мкс) по оси Х. }
                              Move(ADecodedRec.Data[18], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Х';
                              Writeln(FS, s);

                              {Buf[22]: средняя величина удара превышающего 50G (в G) по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]) + #09+ 'средняя величина удара превышающего 50G (в G) по оси Y';
                              Writeln(FS, s);

                              {Buf[23]..Buf[26]: время длит. сред. удара превышающего 50G (*25мкс) по оси Y. }
                              Move(ADecodedRec.Data[23], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Y';
                              Writeln(FS, s);

                              {Buf[27]: средняя величина удара превышающего 50G (в G) по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'средняя величина удара превышающего 50G (в G) по оси Z';
                              Writeln(FS, s);

                              {Buf[28]..Buf[31]: время длит. сред. удара превышающего 50G (*25мкс) по оси Z. }
                              Move(ADecodedRec.Data[28], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Z';
                              Writeln(FS, s);

                              {Buf[32]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[32]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[33]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[33]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[34]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[34]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[35]: степень залипания колонны. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[35]) + #09+ 'степень залипания колонны';
                              Writeln(FS, s);

                              {Buf[36]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[36]) + #09+ 'температура силового модуля';
                            end;
                            {$ENDREGION}

                        01: {$REGION ' версия №01 '}
                            begin
                              {Buf[07]..Buf[08]: ток инвертора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'ток инвертора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: максимум входного напряжения. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'максимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: минимум входного напряжения. }
                              Move(ADecodedRec.Data[11], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'минимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: обороты генератора. }
                              Move(ADecodedRec.Data[13], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: сопротивление нагрузки. }
                              Move(ADecodedRec.Data[15], w, 2);
                              s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09+ 'сопротивление нагрузки';
                              Writeln(FS, s);

                              {Buf[17]: средняя величина удара превышающего 50G (в G) по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'средняя величина  удара превышающего  50G (в G) по оси Х';
                              Writeln(FS, s);

                              {Buf[18]..Buf[21]: время длит. сред. удара превышающего 50G (*25мкс) по оси Х. }
                              Move(ADecodedRec.Data[18], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Х';
                              Writeln(FS, s);

                              {Buf[22]: средняя величина удара превышающего 50G (в G) по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]) + #09+ 'средняя величина удара превышающего 50G (в G) по оси Y';
                              Writeln(FS, s);

                              {Buf[23]..Buf[26]: время длит. сред. удара превышающего 50G (*25мкс) по оси Y. }
                              Move(ADecodedRec.Data[23], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Y';
                              Writeln(FS, s);

                              {Buf[27]: средняя величина удара превышающего 50G (в G) по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'средняя величина удара превышающего 50G (в G) по оси Z';
                              Writeln(FS, s);

                              {Buf[28]..Buf[31]: время длит. сред. удара превышающего 50G (*25мкс) по оси Z. }
                              Move(ADecodedRec.Data[28], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Z';
                              Writeln(FS, s);

                              {Buf[32]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[32]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[33]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[33]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[34]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[34]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[35]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[35]) + '°'#09+ 'температура силового модуля';
                            end;
                            {$ENDREGION}

                        02: {$REGION ' версия №02 '}
                            begin
                              {Buf[07]..Buf[08]: ток инвертора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'ток инвертора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: максимум входного напряжения. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'максимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: минимум входного напряжения. }
                              Move(ADecodedRec.Data[11], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'минимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: обороты генератора. }
                              Move(ADecodedRec.Data[13], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: сопротивление нагрузки. }
                              Move(ADecodedRec.Data[15], w, 2);
                              s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09+ 'сопротивление нагрузки';
                              Writeln(FS, s);

                              {Buf[17]..Buf[20]: время длит. сред. удара превышающего 50G (*25мкс) по оси Х. }
                              Move(ADecodedRec.Data[17], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс) по оси Х';
                              Writeln(FS, s);

                              {Buf[21]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[22]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[23]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[24]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + '°'#09+ 'температура силового модуля';
                            end;
                            {$ENDREGION}

                        03: {$REGION ' версия №03 '}
                            begin
                              {Buf[07]..Buf[08]: код телеметрии пульсатора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'код телеметрии пульсатора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: обороты генератора. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[11]..Buf[14]: время длит. сред. удара превышающего 50G (*25мкс). }
                              Move(ADecodedRec.Data[11], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара, превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[15]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[15]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[16]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[16]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[17]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[18]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]) + '°'#09+ 'температура силового модуля';
                            end;
                            {$ENDREGION}

                        04: {$REGION ' версия №04 '}                 {Konovalov 11/01/2018}
                             begin
                              {Buf[07]: min_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09+ 'минимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[08]: max_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[08]) + #09+ 'максимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[09]: min_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[09]) + #09+ 'минимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[10]: max_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[10]) + #09+ 'максимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[11]: min_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[11]) + #09+ 'минимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[12]: max_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[12]) + #09+ 'максимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[13]: min_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[13]) + #09+ 'минимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[14]: max_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[14]) + #09+ 'максимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[15]: min_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[15]) + #09+ 'минимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[16]: max_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[16]) + #09+ 'максимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[17]: min_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]*5) + #09+ 'минимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[18]: max_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]*5) + #09+ 'максимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[19]: min_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + #09+ 'минимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[20]: max_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + #09+ 'максимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[21]: min_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]*5) + #09+ 'минимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[22]: max_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]*5) + #09+ 'максимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[23]: min_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'минимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[24]: max_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + #09+ 'максимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[25]: min_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]*5) + #09+ 'минимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[26]: max_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]*5) + #09+ 'максимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[27]: min_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'минимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[28]: max_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[28]) + #09+ 'максимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[29]: ct_flip_flop   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[29]) + #09+ 'количество ошибок пульсатора';
                              Writeln(FS, s);

                              {Buf[30]..Buf[31]: обороты генератора. }
                              Move(ADecodedRec.Data[30], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора (об/мин.)';
                              Writeln(FS, s);

                              {Buf[32]..Buf[35]: время длит.  сред. удара превышающего  50G (мкс). }
                              Move(ADecodedRec.Data[32], i, 4);
                              s:= #09#09#09#09 + IntToStr(i*25) + #09+ 'время длит.  сред. удара превышающего 50G (мкс)';
                              Writeln(FS, s);

                              {Buf[36]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[37]) + #09+ 'максимум по оси Х (g)';         //поменяли местами ХУ т.к. перепутали на плате 14.04.20 Коновалов
                              Writeln(FS, s);

                              {Buf[37]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[36]) + #09+ 'максимум по оси Y (g)';
                              Writeln(FS, s);

                              {Buf[38]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[38]) + #09+ 'максимум по оси Z (g)';
                              Writeln(FS, s);

                              {Buf[39]..Buf[40]: код телеметрии. }
                              Move(ADecodedRec.Data[39], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'код телеметрии';
                        end;

                            {$ENDREGION}

                        05: {$REGION ' версия №05 '}
                            begin
                              {Buf[07]..Buf[08]: ток инвертора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'ток инвертора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: максимум входного напряжения. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'максимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: минимум входного напряжения. }
                              Move(ADecodedRec.Data[11], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'минимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: обороты генератора. }
                              Move(ADecodedRec.Data[13], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: сопротивление нагрузки. }
                              Move(ADecodedRec.Data[15], w, 2);
                              s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09+ 'сопротивление нагрузки';
                              Writeln(FS, s);

                              {Buf[17]..Buf[20]: время длит. сред. удара превышающего 50G (*25мкс) по оси Х. }
                              Move(ADecodedRec.Data[17], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[21]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[22]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[23]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[24]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + '°'#09+ 'температура силового модуля';
                               Writeln(FS, s);

                              {Buf[25]..Buf[28]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[25], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[29]..Buf[32]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[29], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                              Writeln(FS, s);

                               {Buf[33]..Buf[34]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[33], i, 2);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'максимальное количество ударов в секунду в течении минуты';



                            end;
                            {$ENDREGION}

                        06: {$REGION ' версия №06 '}                 {Konovalov 11/01/2018}
                             begin

                              {Buf[07]: min_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09+ 'минимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[08]: max_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[08]) + #09+ 'максимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[09]: min_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[09]) + #09+ 'минимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[10]: max_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[10]) + #09+ 'максимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[11]: min_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[11]) + #09+ 'минимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[12]: max_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[12]) + #09+ 'максимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[13]: min_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[13]) + #09+ 'минимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[14]: max_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[14]) + #09+ 'максимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[15]: min_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[15]) + #09+ 'минимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[16]: max_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[16]) + #09+ 'максимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[17]: min_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]*5) + #09+ 'минимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[18]: max_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]*5) + #09+ 'максимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[19]: min_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + #09+ 'минимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[20]: max_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + #09+ 'максимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[21]: min_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]*5) + #09+ 'минимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[22]: max_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]*5) + #09+ 'максимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[23]: min_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'минимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[24]: max_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + #09+ 'максимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[25]: min_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]*5) + #09+ 'минимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[26]: max_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]*5) + #09+ 'максимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[27]: min_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'минимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[28]: max_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[28]) + #09+ 'максимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[29]: ct_flip_flop   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[29]) + #09+ 'количество ошибок пульсатора';
                              Writeln(FS, s);

                              {Buf[30]..Buf[31]: обороты генератора. }
                              Move(ADecodedRec.Data[30], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора (об/мин.)';
                              Writeln(FS, s);

                              {Buf[32]..Buf[35]: время длит.  сред. удара превышающего  50G (мкс). }
                              Move(ADecodedRec.Data[32], i, 4);
                              s:= #09#09#09#09 + IntToStr(i*25) + #09+ 'время длит.  сред. удара превышающего 50G (мкс)';
                              Writeln(FS, s);

                              {Buf[36]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[37]) + #09+ 'максимум по оси Х (g)';         //поменяли местами ХУ т.к. перепутали на плате 14.04.20 Коновалов
                              Writeln(FS, s);

                              {Buf[37]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[36]) + #09+ 'максимум по оси Y (g)';
                              Writeln(FS, s);

                              {Buf[38]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[38]) + #09+ 'максимум по оси Z (g)';
                              Writeln(FS, s);

                              {Buf[39]..Buf[40]: код телеметрии. }
                              Move(ADecodedRec.Data[39], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'код телеметрии';

                              {Buf[41]..Buf[44]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[41], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[45]..Buf[48]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[45], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                               {Buf[45]..Buf[48]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[49], i, 2);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'максимальное количество ударов в секунду в течении минуты';

                        end;
                           {$ENDREGION}

                        07: {$REGION ' версия №07 МС '}
                            begin
                              {Buf[07]..Buf[08]: ток инвертора. }
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'ток инвертора';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: максимум входного напряжения. }
                              Move(ADecodedRec.Data[09], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'максимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: минимум входного напряжения. }
                              Move(ADecodedRec.Data[11], w, 2);
                              s:= #09#09#09#09 + Format('%.1f', [w / 10]) + #09+ 'минимум входного напряжения';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: обороты генератора. }
                              Move(ADecodedRec.Data[13], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: сопротивление нагрузки. }
                              Move(ADecodedRec.Data[15], w, 2);
                             // s:= #09#09#09#09 + Format('%.3f', [w / 1000]) + #09+ 'сопротивление нагрузки';
                              s:= #09#09#09#09 + Format('%.3f', [w / 100]) + #09+ 'сопротивление нагрузки';
                              Writeln(FS, s);

                              {Buf[17]..Buf[20]: время длит. сред. удара превышающего 50G (*25мкс) по оси Х. }
                              Move(ADecodedRec.Data[17], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 50G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[21]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'максимум по оси Х';
                              Writeln(FS, s);

                              {Buf[22]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]) + #09+ 'максимум по оси Y';
                              Writeln(FS, s);

                              {Buf[23]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'максимум по оси Z';
                              Writeln(FS, s);

                              {Buf[24]: температура силового модуля. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + '°'#09+ 'температура силового модуля';
                               Writeln(FS, s);

                              {Buf[25]..Buf[28]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[25], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[29]..Buf[32]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[29], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                              Writeln(FS, s);

                               {Buf[33]..Buf[34]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[33], i, 2);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'максимальное количество ударов в секунду в течении минуты';
                                Writeln(FS, s);

                               {Buf[35]..Buf[36]: осевая вибрация по оси Х  }
                              Move(ADecodedRec.Data[35], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.25])+ #09+ 'осевая вибрация по оси Х';
                                  Writeln(FS, s);

                               {Buf[37]..Buf[38]: осевая вибрация по осям Y,Z  }
                              Move(ADecodedRec.Data[37], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.5])+ #09+ 'боковая вибрация по осям Y,Z';
                            end;
                             {$ENDREGION}

                        08: {$REGION ' версия №08 MUP '}                 {Konovalov 11/01/2018}
                             begin
                              {Buf[07]: min_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09+ 'минимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[08]: max_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[08]) + #09+ 'максимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[09]: min_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[09]) + #09+ 'минимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[10]: max_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[10]) + #09+ 'максимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[11]: min_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[11]) + #09+ 'минимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[12]: max_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[12]) + #09+ 'максимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[13]: min_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[13]) + #09+ 'минимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[14]: max_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[14]) + #09+ 'максимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[15]: min_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[15]) + #09+ 'минимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[16]: max_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[16]) + #09+ 'максимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[17]: min_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]*5) + #09+ 'минимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[18]: max_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]*5) + #09+ 'максимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[19]: min_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + #09+ 'минимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[20]: max_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + #09+ 'максимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[21]: min_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]*5) + #09+ 'минимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[22]: max_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]*5) + #09+ 'максимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[23]: min_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'минимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[24]: max_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + #09+ 'максимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[25]: min_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]*5) + #09+ 'минимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[26]: max_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]*5) + #09+ 'максимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[27]: min_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'минимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[28]: max_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[28]) + #09+ 'максимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[29]: ct_flip_flop   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[29]) + #09+ 'количество ошибок пульсатора';
                              Writeln(FS, s);

                              {Buf[30]..Buf[31]: обороты генератора. }
                              Move(ADecodedRec.Data[30], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора (об/мин.)';
                              Writeln(FS, s);

                              {Buf[32]..Buf[35]: время длит.  сред. удара превышающего  50G (мкс). }
                              Move(ADecodedRec.Data[32], i, 4);
                              s:= #09#09#09#09 + IntToStr(i*25) + #09+ 'время длит.  сред. удара превышающего 50G (мкс)';
                              Writeln(FS, s);

                              {Buf[36]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[37]) + #09+ 'максимум по оси Х (g)';         //поменяли местами ХУ т.к. перепутали на плате 14.04.20 Коновалов
                              Writeln(FS, s);

                              {Buf[37]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[36]) + #09+ 'максимум по оси Y (g)';
                              Writeln(FS, s);

                              {Buf[38]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[38]) + #09+ 'максимум по оси Z (g)';
                              Writeln(FS, s);

                              {Buf[39]..Buf[40]: код телеметрии. }
                              Move(ADecodedRec.Data[39], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'код телеметрии';

                              {Buf[41]..Buf[44]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[41], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[45]..Buf[48]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[45], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                               {Buf[49]..Buf[50]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[49], i, 2);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'максимальное количество ударов в секунду в течении минуты';
                                Writeln(FS, s);

                                {Buf[51]..Buf[52]: осевая вибрация по оси Х  }
                              Move(ADecodedRec.Data[51], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.25])+ #09+ 'осевая вибрация по оси Х';
                                Writeln(FS, s);

                               {Buf[53]..Buf[54]: осевая вибрация по осям Y,Z  }
                              Move(ADecodedRec.Data[53], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.5])+ #09+ 'боковая вибрация по осям Y,Z';

                        end;
                             {$ENDREGION}

                        10: {$REGION ' версия №08 MUP '}                 {Konovalov 06/06/2022}
                             begin
                              {Buf[07]: min_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09+ 'минимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[08]: max_Uc_min. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[08]) + #09+ 'максимальное напряжение на конденсаторе в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[09]: min_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[09]) + #09+ 'минимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[10]: max_Uc_max. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[10]) + #09+ 'максимальное напряжение на конденсаторе в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[11]: min_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[11]) + #09+ 'минимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[12]: max_Uvh_min . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[12]) + #09+ 'максимальное входное напряжение в минимуме (В)';
                              Writeln(FS, s);

                              {Buf[13]: min_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[13]) + #09+ 'минимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[14]: max_Uvh_max . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[14]) + #09+ 'максимальное входное напряжение в максимуме (В)';
                              Writeln(FS, s);

                              {Buf[15]: min_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[15]) + #09+ 'минимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[16]: max_vremy_1_go_pika  . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[16]) + #09+ 'максимальное время 1-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[17]: min_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[17]*5) + #09+ 'минимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[18]: max_ampl_1_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[18]*5) + #09+ 'максимальная амплитуда 1-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[19]: min_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + #09+ 'минимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[20]: max_vremy_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + #09+ 'максимальное время начала 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[21]: min_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]*5) + #09+ 'минимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[22]: max_ampl_nach_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[22]*5) + #09+ 'максимальная амплитуда начала 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[23]: min_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[23]) + #09+ 'минимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[24]: max_vremy_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[24]) + #09+ 'максимальное время 2-го пика (мс)';
                              Writeln(FS, s);

                              {Buf[25]: min_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[25]*5) + #09+ 'минимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[26]: max_ampl_2_go_pika   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]*5) + #09+ 'максимальная амплитуда 2-го пика (мА)';
                              Writeln(FS, s);

                              {Buf[27]: min_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + #09+ 'минимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[28]: max_vremy_nach_uderj   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[28]) + #09+ 'максимальное время начала удержания (мс)';
                              Writeln(FS, s);

                              {Buf[29]: ct_flip_flop   . }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[29]) + #09+ 'количество ошибок пульсатора';
                              Writeln(FS, s);

                              {Buf[30]..Buf[31]: обороты генератора. }
                              Move(ADecodedRec.Data[30], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'обороты генератора (об/мин.)';
                              Writeln(FS, s);

                              {Buf[32]..Buf[35]: время длит.  сред. удара превышающего  50G (мкс). }
                              Move(ADecodedRec.Data[32], i, 4);
                              s:= #09#09#09#09 + IntToStr(i*25) + #09+ 'время длит.  сред. удара превышающего 50G (мкс)';
                              Writeln(FS, s);

                              {Buf[36]: максимум по оси Х. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[37]) + #09+ 'максимум по оси Х (g)';         //поменяли местами ХУ т.к. перепутали на плате 14.04.20 Коновалов
                              Writeln(FS, s);

                              {Buf[37]: максимум по оси Y. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[36]) + #09+ 'максимум по оси Y (g)';
                              Writeln(FS, s);

                              {Buf[38]: максимум по оси Z. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[38]) + #09+ 'максимум по оси Z (g)';
                              Writeln(FS, s);

                              {Buf[39]..Buf[40]: код телеметрии. }
                              Move(ADecodedRec.Data[39], w, 2);
                              s:= #09#09#09#09 + IntToStr(w) + #09+ 'код телеметрии';

                              {Buf[41]..Buf[44]: время длит. сред. удара превышающего 100G (*25мкс)  }
                              Move(ADecodedRec.Data[41], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 100G (*25мкс)';
                              Writeln(FS, s);

                              {Buf[45]..Buf[48]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[45], i, 4);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'время длит. сред. удара превышающего 150G (*25мкс)';
                               Writeln(FS, s);

                               {Buf[49]..Buf[50]: время длит. сред. удара превышающего 150G (*25мкс)  }
                              Move(ADecodedRec.Data[49], i, 2);
                              s:= #09#09#09#09 + IntToStr(i) + #09+ 'максимальное количество ударов в секунду в течении минуты';
                                Writeln(FS, s);

                                {Buf[51]..Buf[52]: осевая вибрация по оси Х  }
                              Move(ADecodedRec.Data[51], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.25])+ #09+ 'осевая вибрация по оси Х';
                                Writeln(FS, s);

                               {Buf[53]..Buf[54]: осевая вибрация по осям Y,Z  }
                              Move(ADecodedRec.Data[53], w, 2);
                               s:= #09#09#09#09 + Format('%.1f', [w * 0.5])+ #09+ 'боковая вибрация по осям Y,Z';
                                 Writeln(FS, s);

                               {Buf[55]: температура МУП. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[55]) + '°'#09 + 'температура МУП';

                        end;
                             {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                      {$ENDREGION}

                42: {$REGION ' запись динамического замера '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 42.
                       Buf[07]..Buf[21]: данные.                 }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Динамический замер (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]..Buf[08]: показания акселерометра AX. }
                              Move(ADecodedRec.Data[07], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AX';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: показания акселерометра AY. }
                              Move(ADecodedRec.Data[09], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AY';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: показания акселерометра AZ. }
                              Move(ADecodedRec.Data[11], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AZ';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: показания магнитометра BX. }
                              Move(ADecodedRec.Data[13], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BX';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: показания магнитометра BY. }
                              Move(ADecodedRec.Data[15], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BY';
                              Writeln(FS, s);

                              {Buf[17]..Buf[18]: показания магнитометра BZ. }
                              Move(ADecodedRec.Data[17], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BZ';
                              Writeln(FS, s);

                              {Buf[19]: скорость буровой колонны об/мин. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + ' об/мин'#09+ 'скорость буровой колонны';
                              Writeln(FS, s);

                              {Buf[20]: температура модуля инклинометра. }
                             // s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + '°'#09+ 'температура модуля инклинометра';
                              Move(ADecodedRec.Data[20], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + #09 + 'температура модуля инклинометра';
                              Writeln(FS, s);

                              {Buf[21]: неравномерность вращения. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'неравномерность вращения';

                            end;
                            {$ENDREGION}

                        01: {$REGION ' версия №01 '}
                            begin
                              {Buf[07]..Buf[08]: показания акселерометра AX. }
                              Move(ADecodedRec.Data[07], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AX';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: показания акселерометра AY. }
                              Move(ADecodedRec.Data[09], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AY';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: показания акселерометра AZ. }
                              Move(ADecodedRec.Data[11], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AZ';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: показания магнитометра BX. }
                              Move(ADecodedRec.Data[13], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BX';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: показания магнитометра BY. }
                              Move(ADecodedRec.Data[15], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BY';
                              Writeln(FS, s);

                              {Buf[17]..Buf[18]: показания магнитометра BZ. }
                              Move(ADecodedRec.Data[17], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BZ';
                              Writeln(FS, s);

                              {Buf[19]: скорость буровой колонны об/мин. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + ' об/мин'#09+ 'скорость буровой колонны';
                              Writeln(FS, s);

                              {Buf[20]: температура модуля инклинометра. }
                             // s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + '°'#09+ 'температура модуля инклинометра';
                             Move(ADecodedRec.Data[20], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + '°'#09+ 'температура модуля инклинометра';
                              Writeln(FS, s);

                              {Buf[21]: неравномерность вращения. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'неравномерность вращения';
                               Writeln(FS, s);

                               //Konovalov 7.08.2019

                               {Buf[22]: время удара >50G }
                              Move(ADecodedRec.Data[22], i, 4);
                              s:= #09#09#09#09 + IntToStr(i*100) + ' мкс'#09+ 'время удара >50G';
                              Writeln(FS, s);

                              {Buf[26]: максимальный удар по оси Х }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[27]) + ' G'#09+ 'максимальный удар по оси Х';          //поменяли местами ХУ т.к. перепутали на плате 14.04.20 Коновалов
                              Writeln(FS, s);

                               {Buf[27]: максимальный удар по оси Y }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[26]) + ' G'#09+ 'максимальный удар по оси Y';
                              Writeln(FS, s);

                              {Buf[28]: максимальный удар по оси Z }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[28]) + ' G'#09+ 'максимальный удар по оси Z';

                            end;
                            {$ENDREGION}

                        02: {$REGION ' версия №02 '}
                            begin
                              {Buf[07]..Buf[08]: показания акселерометра AX. }
                              Move(ADecodedRec.Data[07], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AX';
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: показания акселерометра AY. }
                              Move(ADecodedRec.Data[09], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AY';
                              Writeln(FS, s);

                              {Buf[11]..Buf[12]: показания акселерометра AZ. }
                              Move(ADecodedRec.Data[11], sInt, 2);
                              s:= #09#09#09#09 + FormatFloat('#0.0000', sInt * 1.2 / $7FFF) + #09 + 'показания акселерометра AZ';
                              Writeln(FS, s);

                              {Buf[13]..Buf[14]: показания магнитометра BX. }
                              Move(ADecodedRec.Data[13], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BX';
                              Writeln(FS, s);

                              {Buf[15]..Buf[16]: показания магнитометра BY. }
                              Move(ADecodedRec.Data[15], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BY';
                              Writeln(FS, s);

                              {Buf[17]..Buf[18]: показания магнитометра BZ. }
                              Move(ADecodedRec.Data[17], sInt, 2);
                              i64:= sInt;
                              s:= #09#09#09#09 + FormatFloat('#0.00', i64 * 120000 / $7FFF) + #09 + 'показания магнитометра BZ';
                              Writeln(FS, s);

                              {Buf[19]: скорость буровой колонны об/мин. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[19]) + ' об/мин'#09+ 'скорость буровой колонны';
                              Writeln(FS, s);

                              {Buf[20]: температура модуля инклинометра. }
                             // s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[20]) + '°'#09+ 'температура модуля инклинометра';
                              Move(ADecodedRec.Data[20], shint, 1);
                              s:= #09#09#09#09 + IntToStr(shint) + '°'#09+ 'температура модуля инклинометра';
                              Writeln(FS, s);

                              {Buf[21]: неравномерность вращения. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[21]) + #09+ 'неравномерность вращения';

                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                43: {$REGION ' разрешение =1 запрет =0 режима работы с силовым аккумуляторным модулем '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 43.
                       Buf[07]         : данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Работа от силового аккумулятора (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      if (ADecodedRec.N = 7) then                                   {при длине 7 ещё не ввели версию записи                                         }
                      case ADecodedRec.Data[06] of
                        0 : s:= #09#09#09#09 + 'запрещено';
                        1 : s:= #09#09#09#09 + 'разрешено';
                        else
                            s:= #09#09#09#09 + 'error!';
                      end
                      else
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            case ADecodedRec.Data[07] of
                              0 : s:= #09#09#09#09 + 'запрещено';
                              1 : s:= #09#09#09#09 + 'разрешено';
                              else
                                  s:= #09#09#09#09 + 'error!';
                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}


                45: {$REGION ' переключение пакетов с магнитных на гравитационные: 1 - по роторному/динамическому зениту; 0 - по статическому зениту '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 45.
                       Buf[07]         : данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Переключение пакетов с магнитных на гравитационные (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            case ADecodedRec.Data[07] of
                              0 : s:= #09#09#09#09 + 'по статическому зениту';
                              1 : s:= #09#09#09#09 + 'по роторному/динамическому зениту';
                              else
                                  s:= #09#09#09#09 + 'error!';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                46: {$REGION ' переключение типа модуляций манипуляцией давлением: разрешение = 1; запрет = 0 '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 46.
                       Buf[07]         : данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Переключение типа модуляций манипуляцией давлением (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            case ADecodedRec.Data[07] of
                              0 : s:= #09#09#09#09 + 'запрещено';
                              1 : s:= #09#09#09#09 + 'разрешено';
                              else
                                  s:= #09#09#09#09 + 'error!';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                47: {$REGION ' оценка состояния энергонезависимой памяти и журнала '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 47.
                       Buf[07]..Buf[08]: код начала работы.
                       Buf[09]..Buf[10]: номер сбойного сектора флэш. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Оценка состояния энергонезависимой памяти и журнала (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]..Buf[08]: код начала работы. }
                              s:= #09#09#09#09 + 'код начала работы';
                              Writeln(FS, s);

                              {байт 07, бит 0.}
                              if ((ADecodedRec.Data[07] and 1) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FE000) основных параметров последовательной флэш';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 1.}
                              if ((ADecodedRec.Data[07] and 2) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: состояние массива(0x1FF000) основных параметров последовательной флэш';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 2.}
                              if ((ADecodedRec.Data[07] and 4) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка CRC в записи журнала';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 3.}
                              if ((ADecodedRec.Data[07] and 8) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: состояние часов 8586';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 4.}
                              if ((ADecodedRec.Data[07] and 16) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: наличие часов 8565';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 5.}
                              if ((ADecodedRec.Data[07] and 32) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКАП памяти';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 6.}
                              if ((ADecodedRec.Data[07] and 64) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКАП при выключении';
                                Writeln(FS, s);
                              end;

                              {байт 07, бит 7.}
                              if ((ADecodedRec.Data[07] and 128) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: последняя запись отличается от "Выключение питания"';
                                Writeln(FS, s);
                              end;

                              {байт 08, бит 0.}
                              //Writeln(FS, #09#09#09#09 + 'не используется'); - не выводим специально!

                              {байт 08, бит 1.}
                              if ((ADecodedRec.Data[08] and 2) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: остаток текущего сектора непригоден для записи';
                                Writeln(FS, s);
                              end;

                              {байт 08, бит 2.}
                              if ((ADecodedRec.Data[08] and 4) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: не найдено начало последней записи';
                                Writeln(FS, s);
                              end;

                              {байт 08, бит 3.}
                              if ((ADecodedRec.Data[08] and 8) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка выключения питания - более 2-х минут на аккумуляторе';
                                Writeln(FS, s);
                              end;

                              {байт 08, бит 4.}
                              if ((ADecodedRec.Data[08] and 16) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка контрольного кода БЭКОЗУ';
                                Writeln(FS, s);
                              end;

                              {байт 08, бит 5.}
                              if ((ADecodedRec.Data[08] and 32) <> 0) then begin
                                s:= #09#09#09#09#09 + '- ошибка: ошибка записи в БЭКОЗУ при выключении';
                                Writeln(FS, s);
                              end;

                              {байт 08, биты 6 и 7.}
                              w:= 0;
                              if ((ADecodedRec.Data[08] and  64) <> 0) then w:= w + 1;
                              if ((ADecodedRec.Data[08] and 128) <> 0) then w:= w + 2;
                              case w of
                                0 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой U >= 3.6 В';
                                1 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.6V > U >= 3.4 В';
                                2,
                                3 : s:= #09#09#09#09#09 + '- напряжение аккумулятора под нагрузкой 3.4V > U';
                              end;
                              Writeln(FS, s);

                              {Buf[09]..Buf[10]: номер сбойного сектора флэш. }
                             // Move(ADecodedRec.Data[09], w, 2);
                             // s:= #09#09#09#09 + IntToStr(w) + #09+ 'номер сбойного сектора флэш';
                                Move(ADecodedRec.Data[09], w, 2);

                                w:= (w and $fff) ;
                                s:= #09#09#09#09 + IntToStr(w) + #09+ 'номер сбойного сектора флэш';
                                 Writeln(FS, s);

                                Move(ADecodedRec.Data[09], w, 2);
                                w:= w shr 12;
                                s:= #09#09#09#09 + IntToStr(w) + #09+ 'номер ошибки';

                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                48: {$REGION ' команда даунлинк режима переключения пакетов '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 48.
                       Buf[07]         : данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Команда даунлинк режима переключения пакетов (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            case ADecodedRec.Data[07] of
                              0 : s:= #09#09#09#09 + 'в конце циклической последовательности';
                              1 : s:= #09#09#09#09 + 'в конце пакета';
                              else
                                  s:= #09#09#09#09 + 'error!';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                49: {$REGION ' нарушение условий измерения статики '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 49.
                       Buf[07]         : данные. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Нарушение условий измерения статики (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]: неравномерность вращения. }
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + ' c'#09+ 'количество секунд с момента начала 30-ти секундной паузы';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}


                51: {$REGION ' изменены настройки LTB '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 51.
                       Buf[07]         : кол-во параметров LTB. }
                      Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Изменены настройки LTB (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        0 : {$REGION ' версия №00 '}
                            begin
                              {Buf[07]: . кол-во параметров LTB}
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09 + 'количество параметров LTB';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                52: {$REGION ' перезапсиь настроек МИ из LTB-модема '}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 52. }

                      {интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        0 : {$REGION ' версия №00 '}
                            begin
                              s:= 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Перезапись настроек МИ из LTB модема (  вер. ' + IntToStr(ADecodedRec.Data[6]) + ')';
                            end;
                            {$ENDREGION}

                      end;
                    end;
                    {$ENDREGION}

                53: {$REGION ' запись о параметрах старта программы'}
                    begin
                      {Buf[00]..Buf[05]: дата и время в формате BCD.
                       Buf[06]         : № версии для записи 53. }

                     //Writeln(FS, 'Запись о параметрах старта программы (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      s:= 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Запись о параметрах старта программы (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')' + ':    ';

                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        0 : {$REGION ' версия №00 '}
                            begin

                              Move(ADecodedRec.Data[09], w, 2);
                              s:= s +  Format('%-.4x', [w]);
                              Move(ADecodedRec.Data[07], w, 2);
                              s:= s+ Format('%-.4x', [w]) + 'h';

                            end;


                       // 1 : {$REGION ' версия №00 '}
                        //    begin
                        //      Move(ADecodedRec.Data[09], w, 2);
                         //     s:= s +  Format('%-.4x', [w]);
                         //     Move(ADecodedRec.Data[07], w, 2);
                         //     s:= s+ Format('%-.4x', [w]) + 'h  ';
                          //    Move(ADecodedRec.Data[12], w, 2);
                          //    s:= s +  Format('%-.4x', [w]);
                          //    Move(ADecodedRec.Data[10], w, 2);
                          //    s:= s+ Format('%-.4x', [w]) + 'h  ';
                          //     Move(ADecodedRec.Data[15], w, 2);
                          //    s:= s +  Format('%-.4x', [w]);
                          //    Move(ADecodedRec.Data[13], w, 2);
                          //    s:= s+ Format('%-.4x', [w]) + 'h  ';

                          //  end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                54: {$REGION ' - запись об исправлении времени ударов'}
                    begin

                       Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Запись об исправлении времени ударов (вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');

                      {далее интерпретируем содержимое записи в зав. от номера её версии. }
                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              {Buf[07]: . кол-во параметров LTB}
                              s:= #09#09#09#09 + IntToStr(ADecodedRec.Data[07]) + #09 + 'код исправленного времени';

                            end;
                      end;
                    {$ENDREGION}
                    end;
                     {$ENDREGION}




                100: {$REGION ' - запись Вводная информация - месторождение'}
                    begin

                    Writeln(FS, 'Cmd: ' + IntToStr(ADecodedRec.Cmd) + '  Вводная информация(вер. ' + IntToStr(ADecodedRec.Data[6]) + ')');
                    // Move(00, Infob[00], Length(Infob));

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Месторождение: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;

                    end;
                    {$ENDREGION}

                101: {$REGION ' - запись Вводная информация - куст'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of                                   {в новом формате записей в байте [6] всегда лежит № версии                      }
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Куст: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                 {$ENDREGION}

                102: {$REGION ' - запись Вводная информация - Скважина'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Скважина: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;

                    end;
                    {$ENDREGION}

                103: {$REGION ' - запись Вводная информация - Локация'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Локация: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;

                    end;
                    {$ENDREGION}

                104: {$REGION ' - запись Вводная информация - Заказчик'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Заказчик: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;

                    end;
                   {$ENDREGION}

                105: {$REGION ' - запись Вводная информация - Инженер'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Инженер: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;

                    end;
                    {$ENDREGION}

                106: {$REGION ' - запись Вводная информация - Модуль инклинометра'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Модуль инклинометра: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                  {$ENDREGION}

                107: {$REGION ' - запись Вводная информация - Модуль передатчика'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Модуль передатчика: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                108: {$REGION ' - запись Вводная информация - Модуль гамма'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Модуль гамма: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                   {$ENDREGION}

                109: {$REGION ' - запись Вводная информация - Модуль батарей'}
                    begin

                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Модуль батарей: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                110: {$REGION ' - запись Вводная информация - Модуль LTB\MSP'}
                    begin
                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Модуль LTB\MSP: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                111: {$REGION ' - запись Вводная информация - Номера механических модулей'}
                    begin
                                 SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Номера механических модулей: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                    {$ENDREGION}

                112: {$REGION ' - запись Вводная информация - Номера литиевых батарей'}
                    begin
                              SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Номера литиевых батарей: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                     {$ENDREGION}

                113: {$REGION ' - запись Вводная информация - Номера корпусных элементов'}
                    begin
                                     SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Номера корпусных элементов: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                     {$ENDREGION}

                114: {$REGION ' - запись Вводная информация - Комментарии'}
                    begin
                        SetLength(Infob, ADecodedRec.N);
                        FillChar (Infob[00], ADecodedRec.N, $00);

                      case ADecodedRec.Data[6] of
                        00: {$REGION ' версия №00 '}
                            begin
                              Move(ADecodedRec.Data[7], Infob[00], ADecodedRec.N);
                              s:= #09#09#09#09 + 'Комментарии: '+ StringOf(Infob) + #09 ;
                            end;
                            {$ENDREGION}
                      end;
                    end;
                      {$ENDREGION}

              end;
              Writeln(FS, s);                                                       {пишем в файл }
          end;
       end;

      until EndOfFile;

    finally
      CloseFile(FS);
    end;
  end;
end;

end.

