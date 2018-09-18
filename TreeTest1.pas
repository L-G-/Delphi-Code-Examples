unit TreeTest1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, //XPMan,
  DumbTreeView;

type
  TForm1 = class(TForm)
    UpperPanel: TPanel;
    LowerPanel: TPanel;
    AddRndButton: TButton;
    RowHeightTrackBar: TTrackBar;
    IndentTrackBar: TTrackBar;
    RowHeightLabel: TLabel;
    IndentLabel: TLabel;
    FontSizeLabel: TLabel;
    FontSizeTrackBar: TTrackBar;
    BoldFontCheckBox: TCheckBox;
    FontNameComboBox: TComboBox;
    DirCButton: TButton;
    NumEdit: TEdit;
    ClearButton: TButton;
    RootLinesCheckBox: TCheckBox;
    MultiSelectCheckBox: TCheckBox;
    DelButton: TButton;
    CloseButton: TButton;
    CaptionPanel: TPanel;
    LinesCheckBox: TCheckBox;
    ButtonsCheckBox: TCheckBox;
    FullRowSelectCheckBox: TCheckBox;
    CheckBoxesCheckBox: TCheckBox;
    UseBitmapsCheckBox: TCheckBox;
    SiblingCheckBox: TCheckBox;
    Button1: TButton;
    SortButton: TButton;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure FormCreate(Sender: TObject);
    procedure AddRndButtonClick(Sender: TObject);
    procedure RowHeightTrackBarChange(Sender: TObject);
    procedure IndentTrackBarChange(Sender: TObject);
    procedure FontSizeTrackBarChange(Sender: TObject);
    procedure BoldFontCheckBoxClick(Sender: TObject);
    procedure FontNameComboBoxChange(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure DirCButtonClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure RootLinesCheckBoxClick(Sender: TObject);
    procedure MultiSelectCheckBoxClick(Sender: TObject);
    procedure DelButtonClick(Sender: TObject);

    procedure ExpandCollase(Sender: TDumbTreeView; ANode: TDumbTreeNode; x, y: integer);
    procedure CustomDrawCaption(Sender: TDumbTreeView; ANode: TDumbTreeNode;
                                   const ARect: TRect; var DefaultDraw: Boolean);
    procedure CloseButtonClick(Sender: TObject);
    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CaptionPanelDblClick(Sender: TObject);
    procedure TreeView1CustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure LinesCheckBoxClick(Sender: TObject);
    procedure ButtonsCheckBoxClick(Sender: TObject);
    procedure FullRowSelectCheckBoxClick(Sender: TObject);
    procedure CheckBoxesCheckBoxClick(Sender: TObject);
    procedure UseBitmapsCheckBoxClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SortButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

var
  tv: TDumbCheckBoxTreeView;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited;
  //Params.Style:=Params.Style or WS_HSCROLL or WS_visible or WS_VSCROLL;
  // non-windows caption made from panel
  Params.Style := WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_POPUP or WS_SIZEBOX;
  //Params.ExStyle := Params.ExStyle or WS_EX_COMPOSITED; // suppress blinking on form resizing
end;

procedure TForm1.FormCreate(Sender: TObject);
var t0: cardinal;
  //ChkBmp: TBitmap;
begin
  tv := TDumbCheckBoxTreeView.Create(Self);
  //tv.SetBounds(4,4,300,300);
  //tv.BorderStyle := bsNone;
  tv.Align := alClient;
  tv.Color := clWhite;
  tv.Font.Name := 'Arial';
  tv.Font.Size := 10;
  tv.Font.Style := [fsBold];
  tv.CheckBoxes := True;
  //tv.CaptionOffset := 30;
  //ChkBmp := TBitmap.Create;
  //ChkBmp.LoadFromResourceName(HInstance, 'INDETERMINE');
  //tv.CheckedBmp := ChkBmp;
  tv.Parent := Self;
  tv.TabOrder := 0;
  //tv.OnNodeExpandCollapseClick:=ExpandCollase;
  tv.OnCustomDrawCaption:=CustomDrawCaption;
  tv.OnMouseDown:=CaptionPanelMouseDown; // just for fun
  Exit;

  t0:=GetTickCount;
  AddRndButtonClick(nil);
  CaptionPanel.Caption:=CaptionPanel.Caption+' '+inttostr(GetTickCount-t0)+'ms';
end;

procedure TForm1.CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const SC_DRAGMOVE = $F012;
begin
  if WindowState = wsMaximized then Exit;
  // dragging this panel/other control, user will move entire form window
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
end;

procedure TForm1.CustomDrawCaption(Sender: TDumbTreeView; ANode: TDumbTreeNode;
                                   const ARect: TRect; var DefaultDraw: Boolean);
begin
  //Sender.Canvas.TextRect(ARect, ARect.Left, ARect.Top, '@'+ANode.Name);
  //Sender.Canvas.TextOut(ARect.Left, ARect.Top, ANode.Name+'@');
  DefaultDraw := True;
end;

procedure TForm1.ExpandCollase(Sender: TDumbTreeView; ANode: TDumbTreeNode; x, y: integer);
begin
  showmessage(ANode.Name);
end;

const attr = faAnyFile and faDirectory;
//const attr = 0;

var iter: integer;

procedure IterateFolderTree(path: string; node: TDumbTreeNode);
var sr: TSearchRec;
    newnode: TDumbTreeNode;
    res: integer;
begin
  //node.Name := path;
  newnode := nil;
  res := FindFirst(path+'*.*', attr, sr);
  //if (res = 0) and ((sr.attr and faDirectory) = 0) then res := 101;
  if res = 0 then
  begin
    if sr.Name[1]<>'.' then
      newnode := tv.AddChild(node, sr.Name);
    repeat
      if ((sr.Attr and faDirectory) <> 0) and (sr.Name[1]<>'.') and (newnode <> nil) then
        IterateFolderTree(path+sr.Name+'\', newnode);
      res := FindNext(sr);
      //if (res = 0) and ((sr.attr and faDirectory) = 0) then res := 101;
      if (res = 0) and ((sr.attr and faDirectory) <> 0) then
      begin
        if sr.Name[1]<>'.' then
          if newnode = nil then
            newnode := tv.AddChild(node, sr.Name)
          else
            newnode := tv.AddSibling(newnode, sr.Name);
      end;
      inc(iter);
      if iter mod 1000 = 0 then
      begin
        tv.EndUpdate;
        tv.Refresh;
        tv.BeginUpdate;
      end;
    until res <> 0;
  end;
end;

procedure TForm1.DirCButtonClick(Sender: TObject);
begin
  tv.BeginUpdate;
  if tv.ActiveNode = nil then
    tv.ActiveNode := tv.RootNode;
  tv.ActiveNode := tv.AddChild(tv.ActiveNode, 'C:\');
  Screen.Cursor := crHourglass;
  IterateFolderTree('c:\', tv.ActiveNode);
  Screen.Cursor := crDefault;
  tv.UpdateCount:=0;
  tv.Refresh;
  tv.SetFocus;
end;

var pp: array[0..99] of TDumbTreeNode;

procedure TForm1.AddRndButtonClick(Sender: TObject);
var n, m: TDumbTreeNode; i, mem0: integer; t0, t1: cardinal;
begin
  mem0 := AllocMemSize;
  Randomize;
  if tv.ActiveNode = nil then
    tv.ActiveNode := tv.RootNode;
  n := tv.ActiveNode;
  tv.BeginUpdate;
  Screen.Cursor := crHourglass;
  t0 := GetTickCount;
  if SiblingCheckBox.Checked then
    for i:=0 to StrToIntDef(NumEdit.Text, 100)-1 do
      //tv.addsibling(n, 'node_'+inttostr(random(1000000))) //i
      tv.addsibling(n, 'node_'+format('%9.9d',[random(1000000)])) //i
  else
    for i:=0 to StrToIntDef(NumEdit.Text, 100)-1 do
    begin
      if i < 100 then pp[i] := n
      else if random(100) = 0 then n := pp[random(98)+2];
      if random(2) = 0 then
        //m := n.addsibling('nd_'+inttostr(i))
        //m := tv.addsibling(n, 'node_'+inttostr(i))
        m := tv.addsibling(n, 'node_'+inttostr(random(1000000)))
      else
        //m := n.addchild('nd_'+inttostr(i));
        //m := tv.addchild(n, 'node_'+inttostr(i));
        m := tv.addchild(n, 'node_'+inttostr(random(1000000)));
      if random(2) = 0 then n := m;
      if random(150) = 0 then tv.CollapseNode(m);
    end;
  t1 := GetTickCount;
  tv.UpdateCount:=0;
  tv.Refresh;
  tv.SetFocus;
  Screen.Cursor := crDefault;
  CaptionPanel.Caption:=inttostr(TDumbTreeNode.InstanceSize)+' * '+NumEdit.Text
           +' = '+inttostr(AllocMemSize-mem0)+'bytes '
           +inttostr(t1-t0)+'ms';
end;

procedure TForm1.RowHeightTrackBarChange(Sender: TObject);
begin
  tv.Font.Size := RowHeightTrackBar.Position * 2 div 3;
  tv.RowHeight := RowHeightTrackBar.Position;
  FontSizeTrackBar.Position := tv.Font.Size;
  RowHeightLabel.Caption := 'Row Height=' +inttostr(RowHeightTrackBar.Position);
  FontSizeLabel.Caption := 'Font Size=' +inttostr(FontSizeTrackBar.Position);
end;

procedure TForm1.IndentTrackBarChange(Sender: TObject);
begin
  tv.Indent := IndentTrackBar.Position;
  IndentLabel.Caption := 'Indent=' +inttostr(IndentTrackBar.Position);
end;

procedure TForm1.FontSizeTrackBarChange(Sender: TObject);
begin
  tv.Font.Size := FontSizeTrackBar.Position;
  tv.Refresh;
  FontSizeLabel.Caption := 'Font Size=' +inttostr(FontSizeTrackBar.Position);
end;

procedure TForm1.BoldFontCheckBoxClick(Sender: TObject);
begin
  if BoldFontCheckBox.Checked then
    tv.Font.Style := tv.Font.Style + [fsBold]
  else
    tv.Font.Style := tv.Font.Style - [fsBold];
  tv.Refresh;
end;

procedure TForm1.FontNameComboBoxChange(Sender: TObject);
begin
  tv.Font.Name := FontNameComboBox.Text;
  tv.Refresh;
end;

procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  tv.Refresh;
end;

procedure TForm1.FormShow(Sender: TObject);
//var s1, s2: cardinal;
begin
  //tv.SetFocus;
  {//s1:=GetWindowLong(TreeView1.Handle, GWL_STYLE);
  s2:=GetWindowLong(tv.Handle, GWL_STYLE);
  //s1:=GetWindowLong(TreeView1.Handle, GWL_EXSTYLE);
  s2:=GetWindowLong(tv.Handle, GWL_EXSTYLE);
  Caption := Format('api=%x my=%x', [s1, s2]);}
end;

procedure TForm1.ClearButtonClick(Sender: TObject);
begin
  //tv.ActiveNode := nil;
  tv.Clear;
  //tv.Refresh;
end;

procedure TForm1.DelButtonClick(Sender: TObject);
begin
  if tv.ActiveNode = nil then Exit;
  tv.DeleteNodeWithChilds(tv.ActiveNode);
  tv.ActiveNode := nil;
  tv.Refresh;
end;

procedure TForm1.ButtonsCheckBoxClick(Sender: TObject);
begin
  tv.ShowButtons := ButtonsCheckBox.Checked;
end;

procedure TForm1.LinesCheckBoxClick(Sender: TObject);
begin
  tv.ShowLines := LinesCheckBox.Checked;
end;

procedure TForm1.RootLinesCheckBoxClick(Sender: TObject);
begin
  tv.ShowRoot := RootLinesCheckBox.Checked;
end;

procedure TForm1.MultiSelectCheckBoxClick(Sender: TObject);
begin
  tv.Multiselect := MultiselectCheckBox.Checked;
end;

procedure TForm1.FullRowSelectCheckBoxClick(Sender: TObject);
begin
  tv.FullRowSelect := FullRowSelectCheckBox.Checked;
end;

procedure TForm1.CheckBoxesCheckBoxClick(Sender: TObject);
begin
  tv.CheckBoxes := CheckBoxesCheckBox.Checked;
end;

procedure TForm1.UseBitmapsCheckBoxClick(Sender: TObject);
begin
  tv.UseButtonBitmaps := UseBitmapsCheckBox.Checked;
end;

procedure TForm1.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.CaptionPanelDblClick(Sender: TObject);
begin
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else
    WindowState := wsMaximized;
end;

procedure TForm1.TreeView1CustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  NodeRect: TRect;
begin
  NodeRect := Node.DisplayRect(True);
  //Sender.Canvas.Font.Color := clBlack;
  //Sender.Canvas.Brush.Color := clYellow;
  Sender.Canvas.TextOut(200, NodeRect.Top, Node.Text);
  //DefaultDraw := False;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
//TreeView1.Enabled := not TreeView1.Enabled;
  tv.Enabled := not tv.Enabled;
 {if tv.BevelKind = High(tv.BevelKind) then
   tv.BevelKind := Low(tv.BevelKind)
 else
   tv.BevelKind := Succ(tv.BevelKind);}
end;

procedure TForm1.SortButtonClick(Sender: TObject);
begin
  if tv.ActiveNode = nil then
    tv.SortSiblings(tv.RootNode)
  else
    tv.SortChilds(tv.ActiveNode);
  tv.Refresh;
end;

end.
