unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,windows,mem;

type

  { TForm1 }

  TForm1 = class(TForm)
    btn_new: TButton;
    btn_next: TButton;
    btn_ulist: TButton;
    btn_atc: TButton;
    cb_type: TComboBox;
    edt_pid: TEdit;
    edt_value: TEdit;
    Label1: TLabel;
    lbl_list: TLabel;
    ListBox1: TListBox;
    procedure btn_atcClick(Sender: TObject);
    procedure btn_newClick(Sender: TObject);
    procedure btn_nextClick(Sender: TObject);
    procedure btn_ulistClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

  hProc : THANDLE;
  Scanv : Scanner;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btn_atcClick(Sender: TObject);
var
  PID : integer;
begin
   if( TryStrToInt(edt_pid.Text, PID) )then
 begin
  hProc := OpenProcess(PROCESS_ALL_ACCESS, false, PID);

  if (hProc <> INVALID_HANDLE_VALUE) and (hProc <> 0) then
  begin
    showMessage('é sucesso patroa');
  end;


 end;
end;

procedure TForm1.btn_newClick(Sender: TObject);
var
  bla : Nativeint;
  sz  : NativeUint;
begin
  bla := 0;
  sz  := 0;
  case cb_type.ItemIndex of
  0: sz := 1 ;
  1: sz := 2 ;
  2: sz := 4 ;
  3: sz := 8 ;
  end;


  case cb_type.ItemIndex of
  0 .. 3:
  begin
       if tryStrToInt64(edt_value.Text, bla) then
       begin
          Scanv.init_scan(hproc, true, TScan(cb_type.ItemIndex), pointer(@bla), sz);
       end;
  end;
  4 .. 5:
  begin
    Scanv.init_scan(hproc, true, TScan(cb_type.ItemIndex), pointer(edt_value.Text), length(edt_value.Text));
  end;

  end;

end;

procedure TForm1.btn_nextClick(Sender: TObject);
var
  bla : Nativeint;
  sz  : NativeUint;
begin
  bla := 0;
  case cb_type.ItemIndex of
  0: sz := 1 ;
  1: sz := 2 ;
  3: sz := 4 ;
  4: sz := 8 ;
  end;


  case cb_type.ItemIndex of
  0 .. 3:
  begin
       if tryStrToInt64(edt_value.Text, bla) then
       begin
         Scanv.next_scan(hproc, true, TScan(cb_type.ItemIndex), pointer(@bla), sz);
       end;
  end;
  4 .. 5:
  begin
    Scanv.next_scan(hproc, true, TScan(cb_type.ItemIndex), pointer(edt_value.Text), length(edt_value.Text));
  end;

  end;

end;

procedure TForm1.btn_ulistClick(Sender: TObject);
var
 i : integer;
begin
  Listbox1.items.clear();
 for I := 0 to Scanv.memory.Count-1 do
 begin
  if (I > 50) then
    break;

  Listbox1.items.add(Scanv.memory[I].ToHexString);
 end;

 lbl_list.Caption := 'Found: ' + Scanv.memory.Count.ToString;

end;

procedure TForm1.FormShow(Sender: TObject);
begin
  AllocConsole();
  IsConsole:= true;
  SysInitStdIO;

  Scanv := Scanner.create();
  Scanv := Scanv.init_me();
end;

end.

