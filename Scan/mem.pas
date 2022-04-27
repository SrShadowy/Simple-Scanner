unit mem;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses
  SysUtils,
  Classes,
  Variants,
  Windows,
  jwatlhelp32,
  jwapsapi,
  Generics.Collections;

type
   TScan = (OneByte, TwoByte, FourByte, EightByte, TEXT, AOB );

type memory_state = record
public
  var mbi     : MEMORY_BASIC_INFORMATION;
  var pmemory : POINTER;
  var canFree : boolean;
end;

type Scanner = class

public
var memory : Tlist<uint64>;


function init_me(): Scanner;
function init_scan(hProc: NativeUInt; memory_Write : Boolean; type_Scan: TScan; value : pointer ; szT : size_t): Boolean;
function next_scan(hProc: NativeUInt; memory_Write: Boolean; type_Scan: TScan; value: Pointer; szT: NativeUInt): Boolean;
private
var aob  : array of byte;
var mask : array of byte;
function transform_String_toAOB(const pstr : string): boolean;

protected

end;

implementation




function Scanner.init_me(): Scanner;
begin

  result.memory := Tlist<uint64>.create();

end;



function Scanner.init_scan(hProc: NativeUInt; memory_Write : Boolean; type_Scan: TScan; value : pointer ; szT : size_t): Boolean;
var
  ADDRESS, ReadData : NativeUint;
  I,X,Y   : nativeuint;
  T       : memory_state;
  p,s     : byte;
  vstr    : string;
begin

 memory.clear();
 ADDRESS := 0;

 vstr := '';
 if (type_Scan = TScan.AOB) or (type_Scan = TScan.TEXT) then
 begin

  for x := 0 to szT do
  begin
     vstr := vStr + pchar(value)[x];;
  end;
  x := 0;

 end;

 if type_scan = TSCan.AOB then
 begin
     transform_String_toAOB(vstr);
 end;




 repeat
    Y := VirtualQueryEx(hProc, Pointer(ADDRESS), T.mbi, sizeof(Memory_basic_information));
    if y = 0 then
       writeln('VQE error ', getlasterror);

    ADDRESS := NativeUint(t.mbi.BaseAddress) +  t.mbi.RegionSize;

    if (T.mbi.Protect = PAGE_NOACCESS) OR (T.mbi.Protect = PAGE_NOCACHE) OR (T.mbi.Protect = PAGE_GUARD) then
    begin
      writeln('Page Protect has ', T.mbi.Protect);
      continue;
    end;


    GetMem( t.pmemory, t.mbi.RegionSize);

    if t.pmemory = nil then
    begin
     writeln('VA error ', getlasterror);
     continue;
    end;

    if ReadProcessMemory(hproc, t.mbi.BaseAddress, t.pmemory, t.mbi.RegionSize, ReadData) then
    begin
      X := 0;
      for I := 0 to t.mbi.RegionSize do
      begin

         if x = szT then
         begin
            memory.add( NativeUint(t.mbi.BaseAddress) + I-szT);
            x := 0;
            writeln('Found address: ', NativeUint(t.mbi.BaseAddress) + I-szT);
         end;

         case type_Scan of
           TScan.OneByte .. TScan.EightByte: begin

              p := pByte( NativeUint(t.pmemory) + I )^;
              s := pByte( NativeUint(value) + X)^;

              if p = s then
              begin
                inc(X);
              end else begin
                x := 0;
              end;

           end;
           TScan.TEXT : begin
              p := pByte( NativeUint(t.pmemory) + I )^;
              s := ord(vstr[x+1]);

              if p = s then
              begin
                inc(X);
              end else begin
                x := 0;
              end;

           end;
            TScan.AOB : begin

            p := pByte( NativeUint(t.pmemory) + I )^;

            if (mask[x] = 1) or ( p = aob[x]) then
            begin
              inc(x);
            end else begin
                x := 0;
            end;

           end;

         end;



      end;

     FreeMem( t.pmemory, t.mbi.RegionSize );

    end;
 until y = 0;

 writeln('founds -> ', memory.count);

end;


function Scanner.next_scan(hProc: NativeUInt; memory_Write: Boolean; type_Scan: TScan; value: Pointer; szT: NativeUInt): Boolean;
var
  I, R, X  : integer;
  buffer   : pointer;
  ReadData : nativeuint;
  NAddr    : Tlist<uint64>;
  p, s     : byte;
  vstr     : string;

begin

  GetMem(buffer, szt);
  NAddr := Tlist<uint64>.create();
  X := 0;
  vstr := '';
   if (type_Scan = TScan.AOB) or (type_Scan = TScan.TEXT) then
   begin

    for x := 0 to szT do
    begin
       vstr := vStr + pchar(value)[x];;
    end;
    x := 0;
   end;

   if type_scan = TSCan.AOB then
   begin
       transform_String_toAOB(vstr);
   end;


  for I := 0 to memory.count-1 do
  begin

    if ReadProcessMemory(hproc, pointer(memory[i]), buffer, szT, ReadData ) then
    begin

     {[COMPARE BUFFER]}
     for R := 0 to szt do
     begin
            {[HAVE SAME DATA BUFFER]}
            if x = szT then
            begin
              NAddr.add( memory[I] );
              x := 0;
            end;

       case type_scan of
         OneByte .. EightByte: begin

            P := pbyte( nativeuint(buffer) + R)^;
            S := pbyte( nativeUint(value) + R)^;

            if (p = s) then
              inc(x);


         end;
         TEXT: begin

            P := pbyte( nativeuint(buffer) + R)^;
            S := byte( vstr[R+1] );

            if (p = s) then
              inc(x);
         end;
         TScan.AOB: begin
            P := pbyte( nativeuint(buffer) + R)^;
            if (MASK[R] = 1) or (p = AOB[R]) then
              inc(x);
         end;
       end;
     end;
    end else begin
      //writeln('RPM error ', GetLastError);
    end;

  end;


  memory.clear();
  memory.AddRange(NAddr);

  NAddr.clear();
  NAddr.free();


end;

function Scanner.transform_String_toAOB(const pstr: string): Boolean;
var
  list_string : TStrings;
  index: integer;
  cases: string;
  bcheck: boolean;
  vle   : integer;
begin

  list_string := TStringList.create;
  list_string.Delimiter := ' ';
  list_string.DelimitedText := pstr;
  SetLength(aob, list_string.Count);
  SetLength(mask, list_string.Count);

  for index := 0 to list_string.Count-1 do
  begin
    cases := LowerCase(list_string[index]);
    bcheck := (cases.CompareTo('xx') = 0) or (cases.CompareTo('x') = 0) or
        (cases.CompareTo('??') = 0) or (cases.CompareTo('?') = 0);

    if bcheck then
    begin
      mask[index] := 01;
      aob[index] := 0;
    end else begin
      if TryStrToInt( '$' + cases, vle) then
      begin
       aob[index] := vle;
      end;
      mask[index] := 00;
    end;
  end;

  list_string.clear;
  finalize(cases);

  result := true;
end;


end.
