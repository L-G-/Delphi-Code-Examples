// Simple utility that periodically checks E-mail POP3 servers for undelivered messages
// and shows blinking envelope icon in system notification area of Windows tray
// by L_G, last modification: Dec 2013
// Delphi 7, not tested on other Delphi versions

{$DEFINE USE_THREADS} // comment-out this line to build version without threads

{$R TrayMailCheck.res} // icons resource

program TrayMailCheck;

uses
  Windows, Messages, SysUtils, StrUtils,
  WinSock, ShellApi;

type
  TNotifyIconData50 = record // new version with balloon info
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array[0..MAXCHAR] of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..MAXBYTE] of AnsiChar;
    uTimeout: UINT; // union with uVersion: UINT;
    szInfoTitle: array[0..63] of AnsiChar;
    dwInfoFlags: DWORD;
  end{record};

  TMailboxState = (mbsNotChecked, mbsProcessing, mbsChecked);

  TMailboxRecord = record                     // data structure for mailbox info
                     url, user, pass: string; // mailbox access requisites
                     port: integer;           // port number
                     mess_count: integer;     // count of new/unread messages (-1 means error)
                     err_msg: string;         // error message when check failed
                     state: TMailboxState;
                   end;
  TMailboxes = array of TMailboxRecord;      // data structure for all mailboxes info

const
  NIF_INFO = $00000010;

  AppName = 'TrayMailChecker';
  WM_ICON_CALLBACK  = WM_USER + $1001;
  WM_MAILCHECK_DONE = WM_USER + $1002;
  CMD_CHECK = 1;
  CMD_EXEC  = 2;
  CMD_EDIT  = 3;
  CMD_ABOUT = 4;
  CMD_EXIT  = 5;
  MENU_ITEM_COUNT = 5;

  ConnectionTimeOut =    2000; // msec
  DefaultCheckPeriod =     60; // sec
  DefaultFailCheckPeriod = 10; // sec

var
  Mailboxes: TMailboxes;    // data structure for all mailboxes info

  NetworkDown: boolean;     // all server connections failed (so use another check period)
  CheckPeriod: integer;     // pause between checks, seconds
  FailCheckPeriod: integer; // pause between checks in case when network is down
  TimerTicks: integer;      // ticks (500ms) since last check finished
  ChecksCount: integer;     // times check launched
  StillChecking: boolean;   // flag for Question Mark Envelope icon
  WereErrors: boolean;      // flag for Pink Envelope icon
  BlinkMode: boolean;       // (there's some messages) flag for Black Envelope icon
                            // to apper each 1/2 second in turn with another icon
  Ini: THandle;
  IniName: string;    // path to configuration file
  IniBuf: string;     // all configuration file loaded into memory
  MailerApp: string;  // path to application to call via corresponding menu item
  RunOnResumeSuspend: string; // path to application to call when system wakes up from sleep mode (bonus function)
  CloseWindowOnResumeSuspend: string; // name of the window to close shortly after system wakes up

  MsgWnd: HWND;
  MsgWndClass: WNDCLASS;
  TheMenu: HMENU;
  TheMessage: MSG;
  IconData: TNotifyIconData50;
  OkIcon, BrightIcon, InverseIcon, WorkIcon, ErrorIcon: HICON;  // appears in tray notif. area

function CheckMailbox(const addr, user, pass: string; const port: integer;
                      out er_msg: string; out mess_count: integer): boolean;
var
  SckWSAData: WSAData;
  Sck: TSocket;
  SckAddr: TSockAddr;
  SckHostEnt: PHostEnt;
  RecvStr: string;
  //Timeout: integer;

  procedure SckError(const msg: string; close: boolean = false; er_code: integer = 0);
  var er_desc: string;
  begin
    mess_count := -1; // means error
    if er_code = 0 then
      er_code := WSAGetLastError;
    case er_code of
      WSAETIMEDOUT: er_desc    := 'Timed out';
      WSAECONNREFUSED: er_desc := 'Refused';
      WSAEHOSTDOWN: er_desc    := 'Host down';
      WSAEHOSTUNREACH: er_desc := 'Host unreachable';
      WSAHOST_NOT_FOUND: er_desc := 'Host not found';
      else er_desc:= inttostr(er_code) +' '+ SysErrorMessage(er_code);
    end;
    er_msg := msg +': '''+ addr +''' ('+ er_desc +')';
    if close then
      closesocket(Sck);
    WSACleanup;
  end;

  function SckSend(const msg: string): boolean;
  begin
    Result:= send(Sck, (@msg[1])^, Length(msg), 0) <> SOCKET_ERROR;
    if not Result then
      SckError('Socket SEND failed', True);
  end;

  function SckRecv(var msg: string; const check_text: string = ''; must_recv: boolean = True): boolean;
  var recv_n: integer;
  begin
    SetLength(msg, 128);
    recv_n := recv(Sck, msg[1], Length(msg), 0);
    Result := recv_n <> SOCKET_ERROR;
    if not Result then begin SckError('Receive failed', True); Exit end;
    SetLength(msg, recv_n);
    if must_recv then
    begin
      Result := recv_n > 0;
      if not Result then begin SckError('Connection terminated by server', True); Exit end;
    end;
    if (check_text <> '') and (msg <> '') then
    begin
      Result := pos(check_text, msg) > 0;
      if not Result then begin SckError('Wrong server answer: '''+msg+'''', True); Exit end;
    end;
    //MessageBox(MsgWnd, PChar('Server answered '''+RecvStr+''''), 'RECV log', 0);
  end;

  function SckConnect: boolean;
  var mode, er_code: integer;
      FDSet: TFDSet;
      TimeVal: TTimeVal;
  const NONBLOCKING = 1; BLOCKING = 0;
  begin
    // next 3 lines does connect with default timeout (on my system, 3 retrys * 3 sec, doubled each time = 3+6+12 = 21 s)
    //Result := connect(Sck, SckAddr, sizeof(SckAddr)) = 0;
    //if not Result then SckError('Connection failed', True);
    //Exit;
    // next code is switches socket into non-blocking mode (and back) and use 'select' to check for connection
    Result := false;
    mode := NONBLOCKING;
    ioctlsocket(Sck, FIONBIO, mode);
    if {WinSock.}connect(Sck, SckAddr, sizeof(SckAddr)) <> 0 then
    begin
      er_code := WSAGetLastError;
      if er_code <> WSAEWOULDBLOCK then begin SckError('Connection failed', True, er_code); Exit end;

      FDSet.fd_count := 1; FDSet.fd_array[0] := Sck; // same as FD_ZERO(FDSet); FD_SET(Sck, FDSet);
      TimeVal.tv_sec := ConnectionTimeOut div 1000;
      TimeVal.tv_usec := (ConnectionTimeOut mod 1000) * 1000;
      select(0, nil, @FDSet, nil, @TimeVal);
      if not FD_ISSET(Sck, FDSet) then begin SckError('Connection failed', True, WSAETIMEDOUT); Exit end;
    end;
    mode := BLOCKING;
    ioctlsocket(Sck, FIONBIO, mode);
    Result := True;
  end;

begin
  Result:= false;

  if WSAStartup($101, SckWSAData) <> 0 then begin er_msg := 'Sockets startup failed'; Exit end;
  SckAddr.sin_family := AF_INET;
  SckHostEnt := GetHostByName(Pchar(addr));
  if SckHostEnt = nil then begin SckError('DNS lookup failed'); Exit end;
  SckAddr.sin_addr := PInAddr(SckHostEnt^.h_addr_list^)^;
  if SckAddr.sin_addr.S_addr = INADDR_NONE then begin SckError('Address error'); Exit end;
  Sck := socket(AF_INET, SOCK_STREAM, 0);
  if Sck = INVALID_SOCKET then begin SckError('Socket creation failed'); Exit end;
  SckAddr.sin_port := htons(port);

  if not SckConnect then Exit;

  //Timeout := 500;
  //setsockopt(Sck, SOL_SOCKET, SO_RCVTIMEO, @Timeout, SizeOf(Integer));
  //setsockopt(Sck, SOL_SOCKET, SO_SNDTIMEO, @Timeout, SizeOf(Integer));

  if not SckRecv(RecvStr, '+OK') then Exit;

  if not SckSend('USER '+ user +#13#10) then Exit;
  if not SckRecv(RecvStr, '+OK') then Exit;

  if not SckSend('PASS '+ pass +#13#10) then Exit;
  if not SckRecv(RecvStr, '+OK') then Exit;

  if not SckSend('STAT' +#13#10) then Exit;
  if not SckRecv(RecvStr, '+OK') then Exit;
  mess_count := StrToIntDef(copy(RecvStr, 5, PosEx(' ', RecvStr, 5)-5), 0);
  Result := True;

  if not SckSend('QUIT' +#13#10) then Exit;

  closesocket(Sck);
  WSACleanup;
end;

procedure CheckMailboxThread(var Mailbox: TMailboxRecord); stdcall; // for threaded version
//function CheckMailboxThread(var Mailbox: TMailboxRecord): DWORD; stdcall; // for threaded version
begin
  //Result := cardinal(-1);
  with Mailbox do
  begin
    if state <> mbsNotChecked then Exit;
    state := mbsProcessing;
    if CheckMailbox(url, user, pass, port, err_msg, mess_count) then
      NetworkDown := False;
    //Result:= DWORD(mess_count); // not used
    state := mbsChecked;
    PostMessage(MsgWnd, WM_MAILCHECK_DONE, 0, 0);
  end;
end;

{function CheckMailboxThread(var Mailboxes: TMailboxes): DWORD; stdcall; // for threaded version
//function CheckMailboxThread(var UnusedParam): DWORD; stdcall; // works too: Mailboxes is global var
var i: integer;
begin
  i := 0;
  Result := cardinal(-1);
  while i < Length(Mailboxes) do
    if Mailboxes[i].state <> mbsNotChecked then inc(i) else Break;
  if i < Length(Mailboxes) then
    with Mailboxes[i] do
    begin
      state := mbsProcessing;
      CheckMailbox(url, user, pass, port, err_msg, mess_count);
      //Result:= DWORD(mess_count); // not used
      state := mbsChecked;
      PostMessage(MsgWnd, WM_MAILCHECK_DONE, i, mess_count);
    end;
end;
}
procedure ModifyIcon;
begin
  if not Shell_NotifyIcon(NIM_MODIFY, @IconData) then
    // probably Explorer crashed or killed
    if GetLastError <> ERROR_FILE_NOT_FOUND then // if Explorer is already restarted
      Shell_NotifyIcon(NIM_ADD, @IconData); // reinstall our tray icon (quietly, no err.msg)
end;

procedure CheckAllMailboxes; // for not-threaded version
var i: integer; tips: string;
begin
  TimerTicks := 0;
  WereErrors := False;
  NetworkDown := True;
  inc(ChecksCount);
  IconData.hIcon := WorkIcon;
  IconData.szTip := 'Checking mailboxes...'#13;
  ModifyIcon;
  BlinkMode := false; tips := '';

  for i := 0 to High(Mailboxes) do
    with Mailboxes[i] do
    if state <> mbsProcessing then
    begin
      state := mbsProcessing;
      if CheckMailbox(url, user, pass, port, err_msg, mess_count) then
      begin
        tips := tips + user + ': ' +inttostr(mess_count) + #13#10;
        NetworkDown := False;
        if mess_count > 0 then
          BlinkMode := True;
      end
      else begin
        WereErrors := True;
        tips := tips + err_msg + #13#10;
      end;
      state := mbsChecked;
    end;

  tips := tips + '[' + inttostr(ChecksCount) + ']';
  if WereErrors then
    IconData.hIcon := ErrorIcon
  else
    IconData.hIcon := OkIcon;
  if Length(tips) > SizeOf(IconData.szTip)-1 then SetLength(tips, SizeOf(IconData.szTip)-1);
  StrPCopy(IconData.szTip, tips);
  ModifyIcon;
end;

procedure UpdateMailboxesInfo; // for threaded version
var i: integer; tips: string;
begin
  StillChecking := False;
  WereErrors := False;
  tips := '';
  for i := 0 to High(Mailboxes) do
    with Mailboxes[i] do
      case state of
        mbsNotChecked, mbsProcessing:
          begin
            StillChecking := True;
            tips := tips + user + ': Checking ' + url + #13#10;
          end;
        mbsChecked:
          if mess_count >= 0 then
          begin
            tips := tips + user + ': ' +inttostr(mess_count) + #13#10;
            if mess_count > 0 then
              BlinkMode := True;
          end
          else begin
            WereErrors := True;
            tips := tips + err_msg + #13#10;
          end;
      end;

  tips := tips + '[' + inttostr(ChecksCount) + ']';
  if WereErrors then
    IconData.hIcon := ErrorIcon
  else if StillChecking then
    IconData.hIcon := WorkIcon
  else
    IconData.hIcon := OkIcon;
  if Length(tips) > SizeOf(IconData.szTip)-1 then SetLength(tips, SizeOf(IconData.szTip)-1);
  StrPCopy(IconData.szTip, tips);
  ModifyIcon;

  TimerTicks := 0;
end;

procedure StartCheckingMailboxes; // for threaded version
var i: integer; ti: cardinal;
begin
  inc(ChecksCount);
  BlinkMode := false;
  NetworkDown := True;

  for i := 0 to High(Mailboxes) do
  if Mailboxes[i].state <> mbsProcessing then
  begin
    Mailboxes[i].state := mbsNotChecked;
    //CloseHandle(CreateThread(nil, 0, @CheckMailboxThread, @Mailboxes, 0, ti));
    CloseHandle(CreateThread(nil, 0, @CheckMailboxThread, @Mailboxes[i], 0, ti));
    UpdateMailboxesInfo;
  end;
end;

const
  TicksPerSecond = 2; // 1 tick = icon blink period (500ms)
  PopupMenuTimeout      =  3; // in seconds
  WaitForWindow_ms = 3000; // milliseconds
var
  DelayAfterMailerCall: integer = 10; // in seconds
  DelayAfterResumeSuspend: integer = 10; // in seconds
  PopupMenuTicks: integer = -1;

procedure CheckAfter(delay: integer);
begin
  TimerTicks := (CheckPeriod - delay) * TicksPerSecond;
end;

procedure ExecuteMailerApp;
begin
  ShellExecute(MsgWnd, 'open', PChar(MailerApp), '', '', SW_SHOW);
  // Mailer supposed to receive all messages and make mailbox empty on its start,
  // so next check should be done shortly after starting mailer
  CheckAfter(DelayAfterMailerCall);
end;

procedure CheckClosePopupMenu;
var i: integer;
begin
  for i:=0 to MENU_ITEM_COUNT-1 do
    // is any item highlighted?
    if GetMenuState(TheMenu, i, MF_BYPOSITION) and MF_HILITE > 0 then
    begin // mouse is inside menu, so reset timeout and do not close
      PopupMenuTicks := PopupMenuTimeout * TicksPerSecond;
      Exit;
    end;
  //EndMenu; // next line works better
  SendMessage(MsgWnd, WM_CANCELMODE, 0, 0);
end;

function MainWndProc(Wnd: HWND; uMsg: UINT; WPrm: WPARAM; LPrm: LPARAM): LRESULT; stdcall;
var CursorPos: TPoint; s: string; i: integer; hw: HWND;
begin
  Result := 0;
  case uMsg of
    WM_CLOSE:
      DestroyWindow(Wnd);
    WM_DESTROY:
      PostQuitMessage(0);
    WM_TIMER:
      begin
        inc(TimerTicks);
        // in seconds
        if NetworkDown and (TimerTicks >= FailCheckPeriod * TicksPerSecond)
          or not NetworkDown and (TimerTicks >= CheckPeriod * TicksPerSecond)
        then
        {$IFDEF USE_THREADS}
          StartCheckingMailboxes;     // threaded version
        {$ELSE}
          CheckAllMailboxes;          // not-threaded version
        {$ENDIF}
        if PopupMenuTicks >= 0 then
          dec(PopupMenuTicks);
        if PopupMenuTicks = 0 then
          CheckClosePopupMenu;
        if BlinkMode then
        begin
          if (TimerTicks and 1) = 1 then
            IconData.hIcon := InverseIcon
          else if WereErrors then
            IconData.hIcon := ErrorIcon
          else if StillChecking then
            IconData.hIcon := WorkIcon
          else
            IconData.hIcon := BrightIcon;
          ModifyIcon;
        end;
      end;
    WM_MENUSELECT:
      if LongWord(WPrm) <> $ffff0000 then // if menu not closed
        PopupMenuTicks := PopupMenuTimeout * TicksPerSecond;
    {$IFDEF USE_THREADS}
    WM_MAILCHECK_DONE:
       UpdateMailboxesInfo;    // for threaded version
    {$ENDIF}
    WM_ICON_CALLBACK:
      case lPrm of
        WM_LBUTTONDOWN, WM_RBUTTONDOWN:
          begin
            PopupMenuTicks := PopupMenuTimeout * TicksPerSecond;
            GetCursorPos(CursorPos);
            TrackPopupMenu(TheMenu, 0, CursorPos.X-4, CursorPos.Y-4, 0, MsgWnd, nil);
          end;
        WM_LBUTTONDBLCLK:
          begin
            CheckClosePopupMenu;
            ExecuteMailerApp;
          end;
        WM_RBUTTONDBLCLK:
          CheckClosePopupMenu;
      end;
    WM_COMMAND:
      case wPrm of
        CMD_CHECK:
          CheckAfter(0);
        CMD_EXEC:
          ExecuteMailerApp;
        CMD_EDIT:
          ShellExecute(MsgWnd, 'open', PChar(IniName), '', '', SW_SHOW);
        CMD_ABOUT:
          begin
            s := 'This utility periodically checks E-mail POP3 servers'#13#10
               + 'for new (undelivered) messages'#13#10#13#10
               + '(c) 2013, L_G'#13#10#13#10
               + 'Configuration file contains access attributes'#13#10
               + 'for the next mailboxes:'#13#10#13#10;
            for i := 0 to High(Mailboxes) do
              with Mailboxes[i] do
                s := s + user + ' <' +url +'>' + #13#10;
            s := s + #13#10'{Check} Period = ' + inttostr(CheckPeriod) +' {seconds}' + #13#10
                         + 'Mailer {to run} = ' + MailerApp;
            MessageBox(MsgWnd, PChar(s), AppName, MB_OK or MB_TOPMOST or MB_ICONINFORMATION);
          end;
        CMD_EXIT:
          PostQuitMessage(0);
      end;
    WM_POWERBROADCAST:
      if wPrm = 18 {PBT_APMRESUMEAUTOMATIC} then
      begin
        //messagebox(0,'Suspend resumed.','PBT_APMRESUMEAUTOMATIC',0);
        CheckAfter(DelayAfterResumeSuspend);

        if RunOnResumeSuspend <> '' then
          //WinExec('C:\Program Files\QuickGamma\QuickGamma.exe', SW_SHOW);
          ShellExecute(MsgWnd, 'open', PChar(RunOnResumeSuspend), '', '', SW_SHOW);

        if CloseWindowOnResumeSuspend <> '' then
        begin
          for i:= 1 to WaitForWindow_ms div 15 do // default is 300 ms
          begin
            sleep(30);
            //hw:= FindWindow(nil, 'QuickGamma');
            hw:= FindWindow(nil, PChar(CloseWindowOnResumeSuspend));
            if hw <> 0 then break;
          end;
          if hw <> 0 then SendMessage(hw, WM_CLOSE, 0, 0);
        end;
      end;
  else
    Result := DefWindowProc(Wnd, uMsg, WPrm, LPrm)
  end;
end;

procedure CreateMsgWindow;
begin
  OkIcon      := LoadIcon(HInstance, 'ENV_GRAY');
  BrightIcon  := LoadIcon(HInstance, 'ENV_WHITE');
  InverseIcon := LoadIcon(HInstance, 'ENV_BLACK');
  ErrorIcon   := LoadIcon(HInstance, 'ENV_RED');
  WorkIcon    := LoadIcon(HInstance, 'ENV_QUESTION');

  FillChar(MsgWndClass, SizeOf(MsgWndClass), 0);
  MsgWndClass.lpfnWndProc := @MainWndProc;
  MsgWndClass.hInstance := HInstance;
  MsgWndClass.hIcon := OkIcon;
  MsgWndClass.hCursor := LoadCursor(0, IDC_ARROW);
  MsgWndClass.lpszClassName := AppName;
  if Windows.RegisterClass(MsgWndClass) = 0 then
    begin MessageBox(0, 'RegisterClass failed!', nil, MB_OK); Exit end;

  //MsgWnd := CreateWindow(AppName, AppName, 0, 0, 0, 0, 0, HWND(HWND_MESSAGE), 0, HInstance, nil);
  // window with HWND_MESSAGE parent does not reseive WM_POWERBROADCAST message!
  MsgWnd := CreateWindow(AppName, AppName, 0, 0, 0, 0, 0, 0, 0, HInstance, nil);
  if MsgWnd = 0 then
    begin MessageBox(0, 'CreateWindow failed!', nil, MB_OK); Exit end;
end;

procedure CreateTrayIcon;
begin
  FillChar(IconData, SizeOf(IconData), 0);
  IconData.cbSize := SizeOf(IconData);
  IconData.Wnd := MsgWnd;
  IconData.hIcon := OkIcon;
  IconData.uCallbackMessage := WM_ICON_CALLBACK;
  IconData.uFlags := Nif_Icon or Nif_Message or Nif_Tip;
  //IconData.uFlags := Nif_Icon or Nif_Message or Nif_Tip or Nif_Info;
  //IconData.szTip := AppName;
  //IconData.uTimeout := 20000;
  //IconData.dwInfoFlags := 1 {NIIF_NONE=0 NIIF_INFO=1 NIIF_WARNING=2 NIIF_ERROR=3};
  //StrPCopy(IconData.szInfoTitle, 'Balloon Title');
  //StrPCopy(IconData.szInfo, SysErrorMessage(10093));
  if not Shell_NotifyIcon(NIM_ADD, @IconData) then
    MessageBox(0, 'Adding Notify Icon failed!', '', 0);
end;

procedure CreateTheMenu;
begin
  TheMenu := CreatePopupMenu;
  AppendMenu(TheMenu, MF_STRING, CMD_CHECK, 'Check Now!');
  if MailerApp <> '' then
    AppendMenu(TheMenu, MF_STRING, CMD_EXEC,  PChar('Run Mailer (Icon double-click)'));
  AppendMenu(TheMenu, MF_STRING, CMD_EDIT,  'Edit configuration file');
  AppendMenu(TheMenu, MF_STRING, CMD_ABOUT, 'About');
  AppendMenu(TheMenu, MF_STRING, CMD_EXIT,  'Exit');
end;

procedure TryDecypher(var s: string);
var i: integer;
begin
  if Copy(s, 1, 4) = '%~,-' then
  begin
    for i:=1 to Length(s) div 2 - 2  do
      s[i] := chr((ord(s[i*2+3]) and $f) shl 4 + ord(s[i*2+4]) and $f);
    SetLength(s, Length(s) div 2 - 2);
  end;
end;

procedure LoadConfig;
const
  DefaultPop3Port = 110;
var
  line, value: string;
  i, eoln_pos, eq_pos, col_pos: integer;
  rd: DWORD;

  function CheckKey(const key: string; var value: string): boolean;
  begin
    Result:= (pos(key, AnsiLowercase(line)) = 1) and (eq_pos > Length(key));
    if Result then
      value := Trim(copy(line, eq_pos+1, MaxInt));
  end;

begin
  CheckPeriod := DefaultCheckPeriod;
  FailCheckPeriod := DefaultFailCheckPeriod;

  IniName := ChangeFileExt(ParamStr(0), '.ini');
  Ini := CreateFile(PChar(IniName), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Ini = INVALID_HANDLE_VALUE then
  begin
    MessageBox(0, PChar('Can''t open configuration file '''+IniName+''''#13#13+AppName+' will not launch!'), AppName, MB_ICONERROR);
    halt;
  end;
  SetLength(IniBuf, GetFileSize(Ini, nil));
  ReadFile(Ini, IniBuf[1], Length(IniBuf), rd, nil);
  SetLength(IniBuf, rd);
  FileClose(Ini);
  i := 1;
  while i <= Length(IniBuf) do
  begin
    eoln_pos := PosEx(#13, IniBuf, i);
    if eoln_pos = 0 then eoln_pos:= MaxInt;
    line := Copy(IniBuf, i,  eoln_pos - i);
    inc(i, Length(line)+1);
    line := Trim(line);
    eq_pos := PosEx('=', line);

    CheckKey('mailer', MailerApp);
    if CheckKey('period', value) then
      CheckPeriod := StrToIntDef(value, CheckPeriod);
    if CheckKey('period_minutes', value) then
      CheckPeriod := StrToIntDef(value, CheckPeriod div 60) * 60;
    if CheckKey('fail_period', value) then
      FailCheckPeriod := StrToIntDef(value, FailCheckPeriod);

    if CheckKey('delayaftermailercall', value) then
      DelayAfterMailerCall := StrToIntDef(value, DelayAfterMailerCall);
    if CheckKey('delayafterresumesuspend', value) then
      DelayAfterResumeSuspend := StrToIntDef(value, DelayAfterResumeSuspend);

    CheckKey('runonresumesuspend', RunOnResumeSuspend); // bonus function
    CheckKey('closewindowonresumesuspend', CloseWindowOnResumeSuspend); // bonus function
    if CheckKey('url', value) then
    begin
      SetLength(Mailboxes, Length(Mailboxes)+1);
      col_pos := Pos(':', value);
      if col_pos > 0 then
      begin
        Mailboxes[High(Mailboxes)].url  := Trim(Copy(value, 1, col_pos-1));
        Mailboxes[High(Mailboxes)].port := StrToIntDef(Trim(Copy(value, col_pos+1, MaxInt)), DefaultPop3Port);
      end else begin
        Mailboxes[High(Mailboxes)].url  := value;
        Mailboxes[High(Mailboxes)].port := DefaultPop3Port;
      end;
    end;
    CheckKey('user', Mailboxes[High(Mailboxes)].user);
    if CheckKey('pass', Mailboxes[High(Mailboxes)].pass) then
      TryDecypher(Mailboxes[High(Mailboxes)].pass);
  end;
  CheckAfter(0);
end;

(***************************************
Example for configuration file contents:

period = 120
fail_period = 20
mailer = "C:\Program Files\The Bat!\thebat.exe"

url  = mail.site.dom
user = user@site.dom
pass = mysecretpass

url  = pop3.mailserver.dom
user = user.name@mailserver.dom
pass = vEryS3cRe7

***************************************)

begin
  if OpenMutex(MUTEX_ALL_ACCESS, false, AppName) <> 0 then
    halt; // one instance is already running, so quit
  CreateMutex(nil, false, AppName);

  LoadConfig;
  CreateMsgWindow;
  CreateTrayIcon;
  CreateTheMenu;
  SetTimer(MsgWnd, 1, 1000 div TicksPerSecond, nil);

  while GetMessage(TheMessage, 0, 0, 0) do
  begin
    TranslateMessage(TheMessage);
    DispatchMessage(TheMessage)
  end;

  Shell_NotifyIcon(NIM_DELETE, @IconData);
  // all below anyway clears on process exit
  //KillTimer(MsgWnd, 1);
  //WSACleanup;
  //closehandle(Mutex);
  //DestroyWindow(MsgWnd);
  //UnregisterClass(MsgWndClass.lpszClassName, HInstance);
  //ExitProcess(0);
end.


