{ This simple TreeView component is inherited from TCustomControl }
{ it does not uses Windows TreeView control from comctl32.dll     }
{ (c) L_G, last modification: Jan 2014                            }

// To use your custom-modified TUserDumbTreeNode in separate UserDumbTreeNode.pas,
// uncomment define in the next line
//{$DEFINE USES_USERDUMBTREENODE_PAS}

unit DumbTreeView;

interface

uses Windows, Messages, Classes, Forms, Controls, Graphics
{$IFDEF USES_USERDUMBTREENODE_PAS}
   , UserDumbTreeNode; // better to define your class in separate .pas file!
{$ELSE};               // but it can be defined just here:
type
  TUserDumbTreeNode = class // in the lightest case, the class is totally empty
                               // for example, here you may insert:
    //Id, ParentId: integer;   // for database-stored trees
    //Bmp: TBitmap;            // 'icon' bitmap
    //Obj: TObject;            // anything else you need
  end;

  TDumbTreeNodeFlag = (nfFocused, nfSelected, nfCollapsed, // these 3 is used in TDumbTreeView
                       nfChecked, nfIndeterminate,         // these 2 - in TDumbCheckBoxTreeView
                       nfDisabled, nfExpandabilityUnknown);  // these are not used
                       //nfGrayed, nfDefault, nfHot, nfMarked);  // ???
{$ENDIF}

const DefSelectedNodeColor = clHighlight;
      DefSelectedNodeTextColor = clHighlightText;
      FDefRootIndent = 4;
      FVertOffset = 2;
      FCaptionSpace = 2;

type
  TDumbFlag = nfFocused..nfExpandabilityUnknown;  // these are not used
                       //nfGrayed, nfDefault, nfHot, nfMarked);  // ???
  TDumbTreeNodeFlags = set of TDumbTreeNodeFlag;

  TDumbTreeNode = class(TUserDumbTreeNode) // inherits FROM class with USER-DEFINED fields/properties!
  private
    FParent,
    FChild,                  // _1st_ of node's child nodes
    FSibling: TDumbTreeNode; // _NEXT_ sibling
    ////PrevSibling: TDumbTreeNode; // thinked it may be useful, but it is not!
    FName: string;
    FFlags: TDumbTreeNodeFlags;
    // Wonder how many bytes each tree node takes?
    // This record size is 5 fields * 4 bytes = 16 bytes + 4 for TObject = 20 bytes
    // Plus even the shortest 1-3 characrer string for Name takes 8+4=12 bytes (but 0 for empty)
    // 8..11 character Name takes 8+12=20 bytes, so total = 16+4+20 = 40 bytes
    function GetLevel: integer;
  protected
    property Parent: TDumbTreeNode read FParent write FParent;
    //property {1st}Child: TDumbTreeNode read FChild write FChild;
    property {Next}Sibling: TDumbTreeNode read FSibling write FSibling;
    property Flags: TDumbTreeNodeFlags read FFlags write FFlags;
  public
    property {1st}Child: TDumbTreeNode read FChild write FChild;
    property Name: string read FName write FName;
    property Level: integer read GetLevel;
    constructor Create(AName: string);
    function AddSibling(AName: string): TDumbTreeNode;
    function AddChild(AName: string): TDumbTreeNode;
  end;

  TDumbTreeView = class;

  TDumbTreeCustomDrawRowEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode; const ARect: TRect;
    var DefaultDraw: Boolean) of object;

  TDumbTreeCustomDrawCaptionEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode; const ARect: TRect;
    var DefaultDraw: Boolean) of object;

  TDumbTreeMeasureCaptionWidthEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode; var Width: integer) of object;

  TDumbTreeNodeEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode) of object;

  TDumbTreeNodeClickEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode; AButton: TMouseButton;
    Shift: TShiftState; X, Y: integer) of object;

  TDumbTreeNodeAllowEvent = procedure
    (Sender: TDumbTreeView; ANode: TDumbTreeNode; var Allow: Boolean) of object;

  TDumbTreeCompareNodes = function
    (Sender: TDumbTreeView; N1, N2: TDumbTreeNode): integer of object;

  TDumbTreeView = class(TCustomControl)
  private
    //FNodeCount: integer;
    FRootNode: TDumbTreeNode; // root can have siblings, not only children!
    FBorderStyle: TBorderStyle;
    FRowHeight: integer; // pixels
    FIndent: integer;    // child node offset to right from parent; pixels
    FExpandButtonHalfSize: integer;
    FCaptionOffset: Integer; //pixels between
    FWindowRows: integer;  // count of rows that fits in ClientHeight
    FFirstRow: integer;
    FHorzPos: integer;              // scrollbar positions
    FVertPos: integer;
    FHorzRange: integer;            // scrollbar ranges
    FVertRange: integer;
    FVisibleNodes: integer;  // = total node count minus hidden (by collapsing) childs
    FUpdateCount: integer;
    FScrollInfo: TScrollInfo;
    FSelectedNodeColor, FSelectedNodeTextColor: TColor;
    FActiveNode: TDumbTreeNode; // active means focused
    FMultiSelect: boolean;
    FShowExpandButtons: boolean;
    FShowLines: boolean;
    FShowRootLines: boolean;
    FFullRowSelect: boolean;
    FRootIndent: integer; // = FShowRootLines ? FDefRootIndent : FIndent
    FLevel, FRow: integer; // 'outer' variables for recursive iterations: current level and row
    FMaxRowWidth: integer; // updated on each Paint; TODO: needs to be resetted somewhere!!!
    //FExpandBmp, FCollapseBmp, FCheckedBmp, FUncheckedBmp: TBitmap;
    FDefExpandBmp, FDefCollapseBmp: TBitmap;
    FExpandBmp, FCollapseBmp: TBitmap;
    FUseButtonBitmaps: boolean;

    FOnCustomDrawRow: TDumbTreeCustomDrawRowEvent;
    FOnCustomDrawCaption: TDumbTreeCustomDrawCaptionEvent;
    FOnMeasureCaptionWidth: TDumbTreeMeasureCaptionWidthEvent;
    FOnNodeClick: TDumbTreeNodeClickEvent;
    FOnNodeDblClick: TDumbTreeNodeEvent;
    FOnCompareNodes: TDumbTreeCompareNodes;
    FBeforeNodeExpandCollapse: TDumbTreeNodeAllowEvent;
    FBeforeNodeSelect: TDumbTreeNodeAllowEvent;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure SetBorderStyle(Value: TBorderStyle);
    procedure SetHorzPos(Value: integer);
    procedure SetVertPos(Value: integer);
    procedure SetIndent(Value: integer);
    procedure SetExpandButtonSize(Value: integer);
    function  GetExpandButtonSize: integer;
    procedure SetShowExpandButtons(Value: boolean);
    procedure SetShowLines(Value: boolean);
    procedure SetShowRootLines(Value: boolean);
    procedure SetFullRowSelect(Value: boolean);
    procedure SetSelectedNodeColor(Value: TColor);
    procedure SetSelectedNodeTextColor(Value: TColor);
    procedure SetCollapseBmp(const Value: TBitmap);
    procedure SetExpandBmp(const Value: TBitmap);
    procedure SetUseButtonBitmaps(const Value: boolean);
    function  InternalSortSiblings(const ANode: TDumbTreeNode): TDumbTreeNode;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure DeleteSiblingNodes(ANode: TDumbTreeNode);
    procedure DeleteNodeChilds(ANode: TDumbTreeNode);
    procedure DrawSiblingNodes(ANode: TDumbTreeNode);
    function  GetCaptionOffset: integer; virtual;
    procedure SetCaptionOffset(Value: integer); virtual;
    procedure SetRowHeight(Value: integer); virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure SetEnabled(Value: Boolean); override;
    procedure AdjustScrollBars; virtual;
    procedure SetActiveNode(ANode: TDumbTreeNode); virtual;
    procedure DrawNodeRow(ANode: TDumbTreeNode; ALevel, ARow: integer); virtual;
    procedure DrawNodeCaption(ANode: TDumbTreeNode; ALevel, ARow: integer); virtual;
    procedure AdjustCaptionWidth(ANode: TDumbTreeNode; var AWidth: integer); virtual;
    procedure DoNodeClick(ANode: TDumbTreeNode; AButton: TMouseButton;
                          Shift: TShiftState; X, Y: Integer); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Refresh; virtual;
    procedure RefreshNode(ANode: TDumbTreeNode); virtual;
    function GetNodeAtXY(X, Y: integer): TDumbTreeNode;
    function GetNodeAtRow(ARow: integer): TDumbTreeNode;
    function GetNodeRow(ANode: TDumbTreeNode): integer;
    function GetPrevNode(ANode: TDumbTreeNode; IncludeHidden: boolean = False): TDumbTreeNode;
    function GetNextNode(ANode: TDumbTreeNode; IncludeHidden: boolean = False): TDumbTreeNode;
    function AddSibling(ANode: TDumbTreeNode; AName: string): TDumbTreeNode;
    function AddChild(ANode: TDumbTreeNode; AName: string): TDumbTreeNode;
    procedure ExpandOrCollapseNode(ANode: TDumbTreeNode); virtual;
    procedure ExpandNode(ANode: TDumbTreeNode); virtual;
    procedure CollapseNode(ANode: TDumbTreeNode); virtual;
    procedure ToggleNodeSelection(ANode: TDumbTreeNode);
    procedure ClearSelectionInSiblings(ANode: TDumbTreeNode);
    procedure ClearSelection; virtual;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure DeleteNodeWithChilds(ANode: TDumbTreeNode);
    procedure Clear; virtual;
    function  CompareNodes(n1, n2: TDumbTreeNode): integer;
    procedure SortChilds(const ANode: TDumbTreeNode);
    procedure SortSiblings(const ANode: TDumbTreeNode);

    property RootNode: TDumbTreeNode read FRootNode write FRootNode;
    property ActiveNode: TDumbTreeNode read FActiveNode write SetActiveNode;
    property HorzPos: integer read FHorzPos write SetHorzPos;
    property VertPos: integer read FVertPos write SetVertPos;
    //property NodeCount: integer read FNodeCount write FNodeCount; ////// not used
    property Canvas; ///?!?!
    property UpdateCount: integer read FUpdateCount write FUpdateCount;
  published
    property BorderStyle: TBorderStyle
      read FBorderStyle write SetBorderStyle default bsSingle;
    property RowHeight: integer read FRowHeight write SetRowHeight default 16;
    property Indent: integer read FIndent write SetIndent default 18;
    property CaptionOffset: integer read GetCaptionOffset write SetCaptionOffset  default 0;
    property ExpandButtonSize: integer
      read GetExpandButtonSize write SetExpandButtonSize default 8;
    property OnCustomDrawItem: TDumbTreeCustomDrawRowEvent
      read FOnCustomDrawRow write FOnCustomDrawRow;
    property OnCustomDrawCaption: TDumbTreeCustomDrawCaptionEvent
      read FOnCustomDrawCaption write FOnCustomDrawCaption;
    property OnNodeClick: TDumbTreeNodeClickEvent read FOnNodeClick write FOnNodeClick;
    property OnNodeDblClick: TDumbTreeNodeEvent
      read FOnNodeDblClick write FOnNodeDblClick;
    // OnCompareNodes event can be used to change default sorting criterium (Name, alphabetically, ascending)
    // should return -1 when then first node parameter is LESS then the second, 0 if they are equal, and 1 in other case
    property OnCompareNodes: TDumbTreeCompareNodes read FOnCompareNodes write FOnCompareNodes;
    property BeforeNodeExpandCollapse: TDumbTreeNodeAllowEvent
      read FBeforeNodeExpandCollapse write FBeforeNodeExpandCollapse;
    property BeforeNodeSelect: TDumbTreeNodeAllowEvent
      read FBeforeNodeSelect write FBeforeNodeSelect;
    property SelectedNodeColor: TColor read FSelectedNodeColor
      write SetSelectedNodeColor default DefSelectedNodeColor;
    property SelectedNodeTextColor: TColor read FSelectedNodeTextColor
      write SetSelectedNodeTextColor default DefSelectedNodeTextColor;
    property MultiSelect: boolean read FMultiSelect write FMultiSelect default False;
    property ShowButtons: boolean read FShowExpandButtons write SetShowExpandButtons default True;
    property ShowLines: boolean read FShowLines write SetShowLines default True;
    property ShowRoot{Lines}: boolean read FShowRootLines write SetShowRootLines default True;
    property FullRowSelect: boolean read FFullRowSelect write SetFullRowSelect default False;
    property UseButtonBitmaps: boolean read FUseButtonBitmaps write SetUseButtonBitmaps default True;
    property ExpandBmp: TBitmap read FExpandBmp write SetExpandBmp;
    property CollapseBmp: TBitmap read FCollapseBmp write SetCollapseBmp;

    property Anchors;
    property Align;
    property BevelInner;
    property BevelEdges;
    property BevelKind;
    property BevelOuter;
    property BevelWidth;
    property Color default clWindow;
    property Font;
    property ParentColor default False;
    property Hint;
    property ShowHint;
    property ParentShowHint;
    property Enabled;
    property PopupMenu;
    property Ctl3D;
    property ParentCtl3D;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnCanResize;
    property OnConstrainedResize;
    property OnResize;
  end;

/// TODO: maybe, turn this constants into fields/properties?
const FMouseWheelScrollRows = 3;
      FLineColor = $989898;
      FExpandButtonFaceColor = clWhite;
      FExpandButtonBorderColor = FLineColor;
      FExpandButtonSignColor = clBlack;

type
  TDumbCheckboxTreeView = class(TDumbTreeView)
  private
    FCheckBoxes: Boolean;
    FUserCaptionOffset: Integer;
    FDefCheckedBmp, FDefUncheckedBmp: TBitmap;
    FUncheckedBmp, FCheckedBmp: TBitmap;
    procedure SetCheckBoxes(Value: boolean);
    procedure SetCheckedBmp(const Value: TBitmap);
    procedure SetUncheckedBmp(const Value: TBitmap);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function  GetCaptionOffset: integer; override;
    procedure SetCaptionOffset(Value: integer); override;
    procedure SetRowHeight(Value: integer); override;
    procedure DrawNodeCaption(ANode: TDumbTreeNode; ALevel, ARow: integer); override;
    //procedure AdjustCaptionWidth(ANode: TDumbTreeNode; var AWidth: integer); override;
    procedure DoNodeClick(ANode: TDumbTreeNode; AButton: TMouseButton;
                          Shift: TShiftState; X, Y: Integer); override;
  published
    property CheckBoxes: Boolean read FCheckBoxes write SetCheckBoxes default False;
    property CheckedBmp: TBitmap read FCheckedBmp write SetCheckedBmp;
    property UncheckedBmp: TBitmap read FUncheckedBmp write SetUncheckedBmp;
  end;

procedure Register;

implementation

{$R *.res}

uses SysUtils;

procedure TDumbTreeView.WndProc(var Message: TMessage);
var p: ^TComponentState;
begin
  if (csDesigning in ComponentState) then
  begin
    p := @ComponentState;
    p^ := p^ - [csDesigning];
    inherited;
    p^ := p^ + [csDesigning];
  end
  else
    inherited;
end;

procedure Register;
begin
  RegisterComponents('Samples', [TDumbTreeView, TDumbCheckBoxTreeView]);
end;

{ TDumbTreeNode }

constructor TDumbTreeNode.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TDumbTreeNode.AddSibling(AName: string): TDumbTreeNode;
begin
  Result := TDumbTreeNode.Create(AName);
  Result.FParent := Self.FParent;
  //if FSibling <> nil then
    Result.FSibling := FSibling;
  FSibling := Result;
end;

function TDumbTreeNode.AddChild(AName: string): TDumbTreeNode;
begin
  Result := TDumbTreeNode.Create(AName);
  Result.FParent := Self;
  //if FChild <> nil then
    Result.FSibling := FChild;
  FChild := Result;
end;

function TDumbTreeNode.GetLevel: integer;
var node: TDumbTreeNode;
begin
  Result := 0;
  node := Self.FParent;
  while node <> nil do
  begin
    node := node.FParent;
    inc(Result);
  end;
end;

{ TDumbTreeView }

constructor TDumbTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Height := 150; Width := 150;
  TabStop := True;
  FScrollInfo.cbSize := SizeOf(FScrollInfo);
  ControlStyle := ControlStyle + [csDesignInteractive, csOpaque{, csFramed}];
  FBorderStyle := bsSingle;
  FSelectedNodeColor := DefSelectedNodeColor;
  FSelectedNodeTextColor := DefSelectedNodeTextColor;
  FRowHeight := 16;
  FIndent := 18;
  FRootIndent := FIndent;
  FShowLines := True;
  FShowRootLines := True;
  FShowExpandButtons := True;
  FExpandButtonHalfSize := 4;
  ParentColor := False;
  Color := clWindow;
  //FNodeCount := 1;
  FDefExpandBmp := TBitmap.Create;
  FDefExpandBmp.LoadFromResourceName(HInstance, 'EXPAND');
  FDefCollapseBmp := TBitmap.Create;
  FDefCollapseBmp.LoadFromResourceName(HInstance, 'COLLAPSE');
  FExpandBmp := TBitmap.Create;
  FCollapseBmp := TBitmap.Create;
  FUseButtonBitmaps := True;
  if csDesigning in ComponentState then
  begin
    FRootNode := TDumbTreeNode.Create('RootNode');
    FRootNode.AddSibling('RootSibling1').AddSibling('RootSibling2');
    FRootNode.AddChild('RootChild').AddChild('RootChildChild');
    FActiveNode := FRootNode;
  end;
end;

destructor TDumbTreeView.Destroy;
begin
  if csDesigning in ComponentState then
    Clear;
  FRootNode.Free;
  FDefExpandBmp.Free; FDefCollapseBmp.Free;
  FExpandBmp.Free; FCollapseBmp.Free;
  inherited;
end;

procedure TDumbTreeView.CreateParams(var Params: TCreateParams);
Const
  BorderStyles: array[TBorderStyle] of cardinal = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_HSCROLL or WS_VSCROLL or BorderStyles[FBorderStyle];  //or WS_VISIBLE -??
  Params.ExStyle := Params.ExStyle or WS_EX_COMPOSITED; // suppress blinking on form resizing

  if Ctl3D and NewStyleControls and (FBorderStyle = bsSingle) then
  begin
    Params.Style := Params.Style and not WS_BORDER;
    Params.ExStyle := Params.ExStyle or WS_EX_CLIENTEDGE;
  end;
  //Params.WindowClass.Style := Params.WindowClass.style and not (CS_HREDRAW or CS_VREDRAW); // saw no effect
end;

procedure TDumbTreeView.WMHScroll(var Msg: TWMHScroll);
begin
  case Msg.ScrollCode of
    sb_LineUp        : HorzPos := HorzPos - 1;
    sb_LineDown      : HorzPos := HorzPos + 1;
    sb_PageUp        : HorzPos := HorzPos - ClientWidth;
    sb_PageDown      : HorzPos := HorzPos + ClientWidth;
    sb_Top           : HorzPos := 0;
    sb_Bottom        : HorzPos := FHorzRange;
    sb_ThumbTrack,
    sb_ThumbPosition : HorzPos := word(Msg.Pos);
  end;
end;

procedure TDumbTreeView.WMVScroll(var Msg: TWMVScroll);
begin
  case Msg.ScrollCode of
    sb_LineUp        : VertPos := VertPos - 1;
    sb_LineDown      : VertPos := VertPos + 1;
    sb_PageUp        : VertPos := VertPos - FWindowRows;
    sb_PageDown      : VertPos := VertPos + FWindowRows;
    sb_Top           : VertPos := 0;
    sb_Bottom        : VertPos := FVertRange;
    sb_ThumbTrack,
    sb_ThumbPosition :
    begin // Msg.Pos gives only 16 low bits, so -
      FScrollInfo.fMask := SIF_TRACKPOS;
      GetScrollInfo(Handle, SB_VERT, FScrollInfo);
      VertPos := FScrollInfo.nTrackPos; // = nPos, so works for sb_ThumbPosition too
      ////Application.MainForm.Caption:=Format('%d %d', [FScrollInfo.nPos, FScrollInfo.nTrackPos]);
    end;
  end;
end;

procedure TDumbTreeView.WMMouseWheel(var Message: TWMMouseWheel);
begin
  inherited;
  if Message.WheelDelta < 0 then
    VertPos := VertPos + FMouseWheelScrollRows
  else if Message.WheelDelta > 0 then
    VertPos := VertPos - FMouseWheelScrollRows;
end;

procedure TDumbTreeView.DoNodeClick(ANode: TDumbTreeNode; AButton: TMouseButton;
                                    Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FOnNodeClick) then
    FOnNodeClick(Self, ANode, AButton, Shift, X, Y);
end;

procedure TDumbTreeView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var node: TDumbTreeNode;
    cx, cy: integer;
begin
  inherited;
  Self.SetFocus;
  node := GetNodeAtXY(X, Y);

  if node <> nil then
  begin
    cx := FIndent * node.Level + FRootIndent - FIndent div 2 - FHorzPos;
    cy := (Y - FVertOffset) div FRowHeight * FRowHeight + FRowHeight div 2 + FVertOffset - 1;
    if    (X >= cx - FExpandButtonHalfSize) and (X <= cx + FExpandButtonHalfSize)
      and (Y >= cy - FExpandButtonHalfSize) and (Y <= cy + FExpandButtonHalfSize)
    then
      ExpandOrCollapseNode(node);

    ActiveNode := node;
    if ActiveNode = node then
      if FMultiSelect then
      begin
        if not (ssCtrl in Shift) then
          ClearSelection;
        node.FFlags := node.FFlags + [nfFocused];
        ToggleNodeSelection(node);
      end;

    DoNodeClick(node, Button, Shift, X - cx - FIndent + FIndent div 2, Y - cy + FRowHeight div 2);
  end;
end;

procedure TDumbTreeView.CNKeyDown(var Message: TWMKeyDown);
var node: TDumbTreeNode; //i: integer;
begin
  node := nil;
  case Message.CharCode of
    VK_UP:
      node := GetPrevNode(ActiveNode);
      //TODO: scroll when active node gets out of sight
    VK_DOWN:
      node := GetNextNode(ActiveNode);
    VK_PRIOR:
      begin   //TODO: move focus (active node) on pair with scrolling 
        {node := ActiveNode;
        for i:= 2 to FWindowRows do
          node := GetPrevNode(node);
        ActiveNode := node;}
        VertPos := VertPos - FWindowRows;
        //Refresh;
      end;
    VK_NEXT:
      begin
        {node := ActiveNode;
        for i:= 2 to FWindowRows do
          node := GetNextNode(node);
        ActiveNode := node;}
        VertPos := VertPos + FWindowRows;
        //Refresh;
      end;
    VK_SPACE:
      ExpandOrCollapseNode(ActiveNode);
    VK_RETURN:
      ToggleNodeSelection(ActiveNode);
    else
      inherited;
  end;
  if node <> nil then
    ActiveNode := node;
end;

procedure TDumbTreeView.WMLButtonDblClk(var Message: TWMLButtonDblClk);
begin
  inherited;
  if ActiveNode = nil then Exit;
  if Assigned (FOnNodeDblClick) then
    FOnNodeDblClick(Self, ActiveNode);

  ExpandOrCollapseNode(ActiveNode); ////???
end;

procedure TDumbTreeView.SetHorzPos(Value: integer);
begin
  if Value < 0 then
    Value := 0
  else if Value > FHorzRange - ClientWidth+4  then
    Value := FHorzRange - ClientWidth+4;

  if (FHorzPos <> Value) then
  begin
    FHorzPos := Value;
    FScrollInfo.fMask := SIF_POS;
    FScrollInfo.nPos := FHorzPos;
    SetScrollInfo(Handle, SB_HORZ, FScrollInfo, True);
    Refresh;
  end;
end;

procedure TDumbTreeView.SetVertPos(Value: integer);
begin
  if Value < 0 then
    Value:=0
  else if Value > FVertRange - FWindowRows + 1 then
    Value := FVertRange - FWindowRows + 1;

  if (FVertPos <> Value) then
  begin
    FVertPos := Value;
    FScrollInfo.fMask := SIF_POS;
    FScrollInfo.nPos := FVertPos;
    SetScrollInfo(Handle, SB_VERT, FScrollInfo, True);
    FFirstRow := FVertPos;
    Refresh;
  end;
end;

function TDumbTreeView.GetNodeAtXY(X, Y: integer): TDumbTreeNode;
begin
  Result := GetNodeAtRow((Y - FVertOffset) div FRowHeight + FFirstRow);
end;

function TDumbTreeView.GetNodeAtRow(ARow: integer): TDumbTreeNode;
var row: integer;

  function CheckSiblingNodes(node: TDumbTreeNode): TDumbTreeNode;
  var n: TDumbTreeNode;
  begin
    //Result := nil;
    repeat
      if row = ARow then Break;
      inc(row);
      n := node;
      if not (nfCollapsed in node.FFlags) and (node.FChild <> nil) then
      begin
        node := CheckSiblingNodes(node.FChild);
        if node <> nil then Break;
      end;
      node := n.FSibling;
    until node = nil;
    Result := node;
  end;

begin
  row := 0;
  if RootNode <> nil then
    Result := CheckSiblingNodes(RootNode)
  else
    Result := nil;
end;

function TDumbTreeView.GetNodeRow(ANode: TDumbTreeNode): integer;
var row: integer;

  function CheckSiblingNodesRow(node: TDumbTreeNode): integer;
  var r: integer;
  begin
    repeat
      if node = ANode then Break;
      inc(row);
      if not (nfCollapsed in node.FFlags) and (node.FChild <> nil) then
      begin
        r := CheckSiblingNodesRow(node.FChild);
        if r <> -1 then begin row := r; Break; end;
      end;
      node := node.FSibling;
    until node = nil;
    if node = nil then
      Result := -1
    else
      Result := row;
  end;

begin
  row := 0;
  Result := CheckSiblingNodesRow(RootNode);
end;

function TDumbTreeView.GetPrevNode(ANode: TDumbTreeNode; IncludeHidden: boolean = False): TDumbTreeNode;
var node: TDumbTreeNode;
begin
  Assert(Assigned(ANode));
  //Result := GetNodeAtRow(GetNodeRow(ANode)-1); //simple but slow 1-line version
  //Exit;
  if ANode = FRootNode then
    Result := nil
  else if (ANode.FParent <> nil) and (ANode.FParent.FChild = ANode) then
    Result := ANode.FParent
  else begin // find previous sibling
    if ANode.FParent = nil then
      node := FRootNode
    else
      node := ANode.FParent.FChild;
    while node.FSibling <> ANode do
    begin
      node := node.FSibling;
      Assert(Assigned(node));
    end;
    while (node.FChild <> nil) and (IncludeHidden or not (nfCollapsed in node.FFlags)) do
      begin // find last child of last child etc...
        node:= node.FChild;
        while node.FSibling <> nil do
          node := node.FSibling;
      end;
    Result:= node;
  end;
end;

function TDumbTreeView.GetNextNode(ANode: TDumbTreeNode; IncludeHidden: boolean = False): TDumbTreeNode;
var node: TDumbTreeNode;
begin
  Assert(Assigned(ANode));
  //Result := GetNodeAtRow(GetNodeRow(ANode)+1); //simple but slow 1-line version
  //Exit;
  if IncludeHidden or not (nfCollapsed in ANode.FFlags) then
  begin
    Result := ANode.FChild;
    if Result <> nil then Exit; // first child is candidate #1 for NextNode
  end;
  Result := ANode.FSibling;
  if Result <> nil then Exit;   // when there's no children, NextNode is {Next}Sibling

  Result := ANode;
  node := nil;
  repeat
    if node = nil then
      Result := Result.FParent;  // otherwise, it will be our Parent's {Next}Sibling
    if Result = nil then Exit;  // or Sibling of first node in ancestors' line that have Sibling
    node := Result.FSibling;
  until node <> nil;

  Result := node;
{
  //Result := ANode.Parent;
  //if Result = nil then Exit;
  repeat
    node := Result.Sibling;
    if node = nil then
      Result := Result.Parent;
    if Result = nil then Exit;
  until node <> nil;
}
end;

procedure TDumbTreeView.DeleteSiblingNodes(ANode: TDumbTreeNode);
var n: TDumbTreeNode;
begin
  repeat
    if ANode.FChild <> nil then
      DeleteSiblingNodes(ANode.FChild);
    n := ANode;
    ANode := ANode.FSibling;
    n.Free;
    //dec(FNodeCount);
  until ANode = nil;
end;

procedure TDumbTreeView.Clear;
begin
  if FRootNode = nil then Exit;
  DeleteSiblingNodes(FRootNode);
  FRootNode := nil;
  FActiveNode := nil;
  Refresh;
end;

procedure TDumbTreeView.DeleteNodeChilds(ANode: TDumbTreeNode);
begin
  Assert(Assigned(ANode));
  if ANode.FChild <> nil then
    DeleteSiblingNodes(ANode.FChild);
  ANode.FChild := nil;
  FActiveNode := nil;
end;

procedure TDumbTreeView.DeleteNodeWithChilds(ANode: TDumbTreeNode);
var node: TDumbTreeNode;
begin
  if ANode = nil then Exit;
  DeleteNodeChilds(ANode);
  if ANode = FRootNode then
    FRootNode := ANode.FSibling
  else if (ANode.FParent <> nil) and (ANode.FParent.FChild = ANode) then
    ANode.FParent.FChild := ANode.FSibling // clear reference to our node
  else begin // find previous sibling
    if ANode.FParent = nil then
      node := FRootNode
    else
      node := ANode.FParent.FChild;
    while node.FSibling <> ANode do
    begin
      node := node.FSibling;
      Assert(Assigned(node));
    end;
    node.FSibling := ANode.FSibling; // clear reference to our node
  end;
  ANode.Free;
  //dec(FNodeCount);
  FActiveNode := nil;
end;

procedure DottedLineTo(ACanvas: TCanvas; X, Y: Integer);
var i: Integer;
begin
  if ACanvas.PenPos.X = X then
  begin
    for i := ACanvas.PenPos.Y+1 to Y do
    if i and 1 <> 0 then
      ACanvas.MoveTo(X, i)
    else
      ACanvas.LineTo(X, i)
  end
  else if ACanvas.PenPos.Y = Y then
  begin
    for i := ACanvas.PenPos.X+1 to X do
    if i and 1 <> 0 then
      ACanvas.MoveTo(i, Y)
    else
      ACanvas.LineTo(i, Y);
  end
  else
    ACanvas.MoveTo(X, Y);
end;

procedure TDumbTreeView.DrawNodeRow(ANode: TDumbTreeNode; ALevel, ARow: integer);
var cx, cy, i: integer; node: TDumbTreeNode;
begin
  if (ARow < FFirstRow) or (ARow > FFirstRow + FWindowRows) then
    Exit;
  Assert(Assigned(ANode));

  if FFullRowSelect and (nfSelected in ANode.FFlags) and Enabled then
  begin
    Canvas.Brush.Color := FSelectedNodeColor;
    cy := FRowHeight*(ARow-FFirstRow)+FVertOffset;
    Canvas.FillRect(Rect(0, cy, ClientWidth, cy + FRowHeight));
  end;

  if FShowRootLines or (Alevel > 0) then
  begin
    cx := FIndent*ALevel+FRootIndent-(FIndent div 2)-FHorzPos;
    cy := FRowHeight*(ARow-FFirstRow)+(FRowHeight div 2)+FVertOffset-1;
    if FShowLines then
    // Lines
    begin
      Canvas.Pen.Color := FLineColor;
      // draw straight vert. lines from overlying nodes down to their chidlren
      // (only their fragments, bounded by current row)
      node := ANode;
      for i := 1 to ALevel+Ord(FShowRootLines) do
      begin
        if node.FParent <> nil then
        begin
          if node.FParent.FSibling <> nil then
          begin
            Canvas.MoveTo(cx-i*FIndent, FRowHeight*(ARow-FFirstRow)+FVertOffset-1);
            DottedLineTo(Canvas, cx-i*FIndent, FRowHeight*(ARow-FFirstRow+1)+FVertOffset-1);
          end;
          node := node.FParent;
        end;
      end;
      // draw L-shaped line fragment to current node from its parent
      if ANode = FRootNode then
        Canvas.MoveTo(cx, cy)
      else begin
        Canvas.MoveTo(cx, FRowHeight*(ARow-FFirstRow)+FVertOffset-1);
        DottedLineTo(Canvas, cx, cy);
      end;
      DottedLineTo(Canvas, FIndent*ALevel+FRootIndent-FHorzPos, cy);
      if (ANode.FSibling <> nil) then
      begin
        // continue L-shape downward to next sibling (so shape is T, rotated 90 deg. CCW)
        Canvas.MoveTo(cx, cy);
        DottedLineTo(Canvas, cx, FRowHeight*(ARow-FFirstRow+1)+FVertOffset-1);
      end;
    end;

    // Expand/Collapse Buttons
    if FShowExpandButtons and (ANode.FChild <> nil) then
    begin
      if FUseButtonBitmaps then
      begin
        if nfCollapsed in ANode.FFlags then
          if FExpandBmp.HandleAllocated then
            Canvas.Draw(cx-4, cy-4, FExpandBmp)
          else
            Canvas.Draw(cx-4, cy-4, FDefExpandBmp)
        else
          if FCollapseBmp.HandleAllocated then
            Canvas.Draw(cx-4, cy-4, FCollapseBmp)
          else
            Canvas.Draw(cx-4, cy-4, FDefCollapseBmp);
      end
      else begin
        Canvas.Brush.Color := FExpandButtonFaceColor;
        Canvas.Pen.Color := FExpandButtonBorderColor;
        Canvas.Rectangle(cx-FExpandButtonHalfSize, cy-FExpandButtonHalfSize,
                         cx+FExpandButtonHalfSize+1, cy+FExpandButtonHalfSize+1);
        Canvas.Pen.Color := FExpandButtonSignColor;
        Canvas.MoveTo(cx-FExpandButtonHalfSize+2, cy);
        Canvas.LineTo(cx+FExpandButtonHalfSize-1, cy);
        if nfCollapsed in ANode.FFlags then
        begin
          Canvas.MoveTo(cx, cy-FExpandButtonHalfSize+2);
          Canvas.LineTo(cx, cy+FExpandButtonHalfSize-1);
        end;
      end;
    end;
  end;

  // Caption (text)
  DrawNodeCaption(ANode, ALevel, ARow);
end;

procedure TDumbTreeView.AdjustCaptionWidth(ANode: TDumbTreeNode; var AWidth: integer);
begin
  if Assigned(FOnMeasureCaptionWidth) then
    FOnMeasureCaptionWidth(Self, ANode, AWidth);
end;

procedure TDumbTreeView.DrawNodeCaption(ANode: TDumbTreeNode; ALevel, ARow: integer);
var x, y, wdt: integer;
    rct: TRect;
    def: boolean;
begin
  Assert(Assigned(ANode));
  x := FCaptionOffset + FRootIndent + FIndent * ALevel - FHorzPos;
  y := FRowHeight * (ARow - FFirstRow) + FVertOffset;
  wdt := Canvas.TextWidth(ANode.FName) + FCaptionSpace*2;
  rct := Rect(x, y, x + wdt, y + FRowHeight);
  if Assigned(FOnCustomDrawCaption) then
  begin
    def := false;
    FOnCustomDrawCaption(Self, ANode, rct, def);
    if not def then Exit;
  end;
  Canvas.Font.Assign(Font);
  if not Enabled then
    Canvas.Font.Color  := clGrayText
  else if nfSelected in ANode.FFlags then
  begin
    Canvas.Brush.Color := FSelectedNodeColor;
    Canvas.Font.Color  := FSelectedNodeTextColor;
  end
  else
    Canvas.Brush.Color := Color;
  Canvas.FillRect(rct);
  Canvas.TextRect(rct, x+FCaptionSpace, y, ANode.FName);// + Format('  %p  %p  %p', [Pointer(ANode.Parent), Pointer(ANode.Sibling), Pointer(ANode.Child)]));
  if nfFocused in ANode.FFlags then
    Canvas.DrawFocusRect(rct);

  AdjustCaptionWidth(ANode, wdt);
  wdt := wdt + FRootIndent + FCaptionOffset + Alevel*FIndent;
  if wdt > FMaxRowWidth then
    FMaxRowWidth := wdt;
end;

procedure TDumbTreeView.RefreshNode(ANode: TDumbTreeNode);
begin
  Assert(Assigned(ANode));
  //DrawNodeCaption(ANode, ANode.Level, GetNodeRow(ANode));
  DrawNodeRow(ANode, ANode.Level, GetNodeRow(ANode));
end;

procedure TDumbTreeView.DrawSiblingNodes(ANode: TDumbTreeNode);
var node: TDumbTreeNode;
begin
  Assert(Assigned(ANode));
  //if (FUpdateCount > 0) or not HandleAllocated then Exit;

  inc(FLevel);
  node := ANode;
  repeat
    if (FRow >= FFirstRow) and (FRow <= FFirstRow + FWindowRows) then
      DrawNodeRow(node, FLevel, FRow);
    inc(FRow);
    if not (nfCollapsed in node.FFlags) and (node.FChild <> nil) then
      DrawSiblingNodes(node.FChild);
    node := node.FSibling;
  until node = nil;
  dec(FLevel);
end;

procedure TDumbTreeView.ClearSelection;
begin
  ClearSelectionInSiblings(RootNode); // Stack Overflow error is possible here!
  Refresh;                            // (in case of too many nested levels)
end;

procedure TDumbTreeView.ClearSelectionInSiblings(ANode: TDumbTreeNode);
var node: TDumbTreeNode;
begin
  Assert(Assigned(ANode));
  node := ANode;
  repeat
    node.FFlags := node.FFlags - [nfFocused, nfSelected];
    if node.FChild <> nil then
      ClearSelectionInSiblings(node.FChild);
    node := node.FSibling;
  until node = nil;
end;

procedure TDumbTreeView.AdjustScrollbars;
begin
  FVertRange := FVisibleNodes;
  FHorzRange := FMaxRowWidth;

  FScrollInfo.fMask := SIF_PAGE or SIF_POS or SIF_RANGE;
  FScrollInfo.nMin := 0;
  FScrollInfo.nMax := FHorzRange;
  FScrollInfo.nPos := FHorzPos;
  FScrollInfo.nPage := ClientWidth;
  SetScrollInfo(Handle, SB_HORZ, FScrollInfo, True);
  FScrollInfo.nMax := FVertRange;
  FScrollInfo.nPos := FVertPos;
  FScrollInfo.nPage := FWindowRows;
  SetScrollInfo(Handle, SB_VERT, FScrollInfo, True);
end;

procedure TDumbTreeView.Paint;
var s1, s2: cardinal;
begin
  if (FUpdateCount > 0) or not HandleAllocated then Exit;
  FWindowRows := ClientHeight div FRowHeight;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  ////FMaxRowWidth := 0; // TODO: commented-out here, so need to be resetted to 0 somewhere!!!
  FLevel := -1;
  FRow := 0;

  if RootNode <> nil then
    DrawSiblingNodes(RootNode);

  FVisibleNodes := FRow - 1;
  AdjustScrollBars;
  if (FHorzRange > ClientWidth) and (FHorzPos > FHorzRange - ClientWidth) then
    FHorzPos := FHorzRange - ClientWidth;
end;

procedure TDumbTreeView.Refresh;
begin
  if FUpdateCount > 0 then Exit;
  Repaint;
end;

procedure TDumbTreeView.SetEnabled(Value: Boolean);
begin
  inherited;
  Refresh;
end;

procedure TDumbTreeView.BeginUpdate;
begin
  inc(FUpdateCount);
end;

procedure TDumbTreeView.EndUpdate;
begin
  dec(FUpdateCount);
end;

procedure TDumbTreeView.SetActiveNode(ANode: TDumbTreeNode);
var allow: boolean;
begin
  if Assigned(FBeforeNodeSelect) then
  begin
    allow := true;
    FBeforeNodeSelect(Self, ANode, allow);
    if not allow then Exit;
  end;

  if ANode <> FActiveNode then
  begin
    if FActiveNode <> nil then
    begin
      if FMultiSelect then
        FActiveNode.FFlags := FActiveNode.FFlags - [nfFocused]
      else
        FActiveNode.FFlags := FActiveNode.FFlags - [nfFocused, nfSelected];
      RefreshNode(FActiveNode);
    end;
    FActiveNode := ANode;
    if FActiveNode <> nil then
    begin
      if FMultiSelect then
        FActiveNode.FFlags := FActiveNode.FFlags + [nfFocused]
      else
        FActiveNode.FFlags := FActiveNode.FFlags + [nfFocused, nfSelected];
      RefreshNode(FActiveNode);
    end;
  end;
end;

procedure TDumbTreeView.ToggleNodeSelection(ANode: TDumbTreeNode);
begin
  Assert(Assigned(ANode));
  if nfSelected in ANode.FFlags then
    ANode.FFlags := ANode.FFlags - [nfSelected]
  else
    ANode.FFlags := ANode.FFlags + [nfSelected];
  // one-liner for 4-line operation above, but looks like ugly sort of hack:
  //ANode.FFlags := TDumbTreeNodeFlags(byte(ANode.FFlags) xor byte(nfsetSelected));
  // and needs definition of const nfsetSelected: TDumbTreeNodeFlags = [nfSelected];
  RefreshNode(ANode);
end;

procedure TDumbTreeView.ExpandOrCollapseNode(ANode: TDumbTreeNode);
var allow: boolean;
begin
  Assert(Assigned(ANode));
  if Assigned(FBeforeNodeExpandCollapse) then
  begin
    allow := true;
    FBeforeNodeExpandCollapse(Self, ANode, allow);
    if not allow then Exit;
  end;

  if nfCollapsed in ANode.FFlags then
    ANode.FFlags := ANode.FFlags - [nfCollapsed]
  else
    ANode.FFlags := ANode.FFlags + [nfCollapsed];
  Refresh;
end;

function TDumbTreeView.AddSibling(ANode: TDumbTreeNode; AName: string): TDumbTreeNode;
begin
  if ANode = nil then
    if FRootNode = nil then
    begin
      Result:= TDumbTreeNode.Create(AName);
      FRootNode := Result;
    end
    else
      Result:= FRootNode.AddSibling(AName)
  else
    Result := ANode.AddSibling(AName);
  //inc(FNodeCount);
  Refresh;
end;

function TDumbTreeView.AddChild(ANode: TDumbTreeNode; AName: string): TDumbTreeNode;
begin
  if ANode = nil then
    if FRootNode = nil then
    begin
      Result:= TDumbTreeNode.Create(AName);
      FRootNode := Result;
    end
    else
      Result:= FRootNode.AddChild(AName)
  else
    Result := ANode.AddChild(AName);
  //inc(FNodeCount);
  Refresh;
end;

function TDumbTreeView.CompareNodes(N1, N2: TDumbTreeNode): integer;
begin
  if Assigned(FOnCompareNodes) then
    Result := FOnCompareNodes(Self, N1, N2)
  else
    if n1.Name = n2.Name then Result := 0 else
      if n1.Name < n2.Name then Result := -1 else
        Result := 1;
end;

procedure TDumbTreeView.SortChilds(const ANode: TDumbTreeNode);
begin
  if ANode.Child <> nil then
    ANode.Child := InternalSortSiblings(ANode.Child);
end;

procedure TDumbTreeView.SortSiblings(const ANode: TDumbTreeNode);
begin
  if ANode = RootNode then
    RootNode := InternalSortSiblings(ANode)
  else if ANode.Parent.Child = ANode then
    ANode.Parent.Child := InternalSortSiblings(ANode)
  else raise Exception.Create('TDumbTreeView.SortSiblings called with not the first sibling of its chain in ANode parameter!');
end;

function TDumbTreeView.InternalSortSiblings(const ANode: TDumbTreeNode): TDumbTreeNode;
// slightly adapted code from http://ru.wikipedia.org/wiki/Сортировка_связного_списка

  function IntersectSorted(const ANode1, ANode2: TDumbTreeNode): TDumbTreeNode;
  var node, n1, n2: TDumbTreeNode;
  begin
    n1 := ANode1;
    n2 := ANode2;
    if CompareNodes(n1, n2) <= 0 then
    begin
      node := n1;
      n1 := n1.Sibling;
    end
    else begin
      node := n2;
      n2 := n2.Sibling;
    end;
    Result := node;
    while (n1 <> nil) and (n2 <> nil) do
    begin
      if CompareNodes(n1, n2) <= 0 then
      begin
        node.Sibling := n1;
        node := n1;
        n1 := n1.Sibling;
      end
      else begin
        node.Sibling := n2;
        node := n2;
        n2 := n2.Sibling;
      end;
    end;
    if n1 <> nil then
      node.Sibling := n1
    else
      node.Sibling := n2;
  end;

type
  TSortStackItem = record
    Level: Integer;
    Node: TDumbTreeNode;
  end;
var
  Stack: Array[0..31] of TSortStackItem; // enough to sort 2^32 nodes
  StackPos: Integer;
  node: TDumbTreeNode;
begin
  StackPos := 0;
  node := ANode;
  Result := node;
  while node <> nil do
  begin
    Stack[StackPos].Level := 1;
    Stack[StackPos].Node := node;
    node := node.Sibling;
    Stack[StackPos].Node.Sibling := nil;
    Inc(StackPos);
    while (StackPos > 1) and (Stack[StackPos - 1].Level = Stack[StackPos - 2].Level) do
    begin
      Stack[StackPos - 2].Node := IntersectSorted(Stack[StackPos - 2].Node, Stack[StackPos - 1].Node);
      Inc(Stack[StackPos - 2].Level);
      Dec(StackPos);
    end;
  end;
  while StackPos > 1 do
  begin
    Stack[StackPos - 2].Node := IntersectSorted(Stack[StackPos - 2].Node, Stack[StackPos - 1].Node);
    Inc(Stack[StackPos - 2].Level);
    Dec(StackPos);
  end;
  if StackPos > 0 then
    Result := Stack[0].Node;
end;

procedure TDumbTreeView.ExpandNode(ANode: TDumbTreeNode);
begin
  Assert(Assigned(ANode));
  ANode.FFlags := ANode.FFlags - [nfCollapsed];
  Refresh;
end;

procedure TDumbTreeView.CollapseNode(ANode: TDumbTreeNode);
begin
  Assert(Assigned(ANode));
  ANode.FFlags := ANode.FFlags + [nfCollapsed];
  Refresh;
end;

procedure TDumbTreeView.SetBorderStyle(Value: TBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TDumbTreeView.SetRowHeight(Value: integer);
begin
  if Value <> FRowHeight then
  begin
    FRowHeight := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetIndent(Value: integer);
begin
  if Value <> FIndent then
  begin
    FIndent := Value;
    if FShowRootLines then
      FRootIndent := FIndent;
    Refresh;
  end;
end;

function TDumbTreeView.GetCaptionOffset: integer;
begin
  Result := FCaptionOffset;
end;

procedure TDumbTreeView.SetCaptionOffset(Value: integer);
begin
  if Value <> FCaptionOffset then
  begin
    FCaptionOffset := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetExpandButtonSize(Value: integer);
begin
  if Value div 2 <> FExpandButtonHalfSize then
  begin
    FExpandButtonHalfSize := Value div 2;
    Refresh;
  end;
end;

function TDumbTreeView.GetExpandButtonSize: integer;
begin
  Result:= FExpandButtonHalfSize * 2;
end;

procedure TDumbTreeView.SetSelectedNodeColor(Value: TColor);
begin
  if Value <> FSelectedNodeColor then
  begin
    FSelectedNodeColor := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetSelectedNodeTextColor(Value: TColor);
begin
  if Value <> FSelectedNodeTextColor then
  begin
    FSelectedNodeTextColor := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetShowExpandButtons(Value: boolean);
begin
  if Value <> FShowExpandButtons then
  begin
    FShowExpandButtons := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetShowLines(Value: boolean);
begin
  if Value <> FShowLines then
  begin
    FShowLines := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetShowRootLines(Value: boolean);
begin
  if Value <> FShowRootLines then
  begin
    FShowRootLines := Value;
    if FShowRootLines then
      FRootIndent := FIndent
    else
      FRootIndent := FDefRootIndent;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetFullRowSelect(Value: boolean);
begin
  if Value <> FFullRowSelect then
  begin
    FFullRowSelect := Value;
    Refresh;
  end;
end;

procedure TDumbTreeView.SetCollapseBmp(const Value: TBitmap);
begin
  FCollapseBmp.Assign(Value);
  Refresh;
end;

procedure TDumbTreeView.SetExpandBmp(const Value: TBitmap);
begin
  FExpandBmp.Assign(Value);
  Refresh;
end;

procedure TDumbTreeView.SetUseButtonBitmaps(const Value: boolean);
begin
  if Value <> FUseButtonBitmaps then
  begin
    FUseButtonBitmaps := Value;
    Refresh;
  end;
end;

{ TDumbCheckBoxTreeView }

const FCheckMarkColor = clGreen; //$707070;

constructor TDumbCheckBoxTreeView.Create(AOwner: TComponent);
begin
  inherited;
  FUserCaptionOffset := FCaptionOffset;
  //Inc(FCaptionOffset, FRowHeight);
  FDefCheckedBmp := TBitmap.Create;
  FDefCheckedBmp.LoadFromResourceName(HInstance, 'CHECKED');
  FDefUncheckedBmp := TBitmap.Create;
  FDefUncheckedBmp.LoadFromResourceName(HInstance, 'UNCHECKED');
  FCheckedBmp := TBitmap.Create;
  FUncheckedBmp := TBitmap.Create;
end;

destructor TDumbCheckBoxTreeView.Destroy;
begin
  FDefCheckedBmp.Free; FDefUncheckedBmp.Free;
  FCheckedBmp.Free; FUncheckedBmp.Free;
  inherited;
end;

procedure TDumbCheckBoxTreeView.SetCheckBoxes(Value: boolean);
begin
  if Value <> FCheckBoxes then
  begin
    FCheckBoxes := Value;
    FCaptionOffset := FUserCaptionOffset;
    if FCheckBoxes then inc(FCaptionOffset, FRowHeight);
    Refresh;
  end;
end;

function TDumbCheckBoxTreeView.GetCaptionOffset: integer;
begin
  Result := FUserCaptionOffset;
end;

procedure TDumbCheckBoxTreeView.SetCaptionOffset(Value: integer);
begin
  FUserCaptionOffset := Value;
  if FCheckBoxes then Inc(Value, FRowHeight);
  inherited SetCaptionOffset(Value);
end;

procedure TDumbCheckBoxTreeView.SetRowHeight(Value: integer);
begin
  if FCheckBoxes then
    FCaptionOffset := FUserCaptionOffset + Value;
  inherited;
end;

procedure TDumbCheckBoxTreeView.DrawNodeCaption(ANode: TDumbTreeNode; ALevel, ARow: integer);
var rct: TRect;
    d: Integer;
begin
  inherited;
  if not FCheckBoxes then Exit;
  if (FRowHeight >= 15) and (FRowHeight <= 19) then
  begin
    rct.Left := FRootIndent + FIndent * ALevel - FHorzPos + 1;
    rct.Top := FRowHeight * (ARow - FFirstRow) + FVertOffset + FRowHeight div 18 + 1;
    rct.Right := rct.Left + 13;
    rct.Bottom := rct.Top + 13;
  end
  else begin
    rct.Left := FRootIndent + FIndent * ALevel - FHorzPos + 2;
    rct.Top := FRowHeight * (ARow - FFirstRow) + FVertOffset + 2;
    rct.Right := rct.Left + FRowHeight - 4;
    rct.Bottom := rct.Top + FRowHeight - 4;
  end;

  if FUseButtonBitmaps then
  begin
    if nfChecked in ANode.Flags then
      if FCheckedBmp.HandleAllocated then
        Canvas.StretchDraw(rct, FCheckedBmp)
      else
        Canvas.StretchDraw(rct, FDefCheckedBmp)
    else
      if FUncheckedBmp.HandleAllocated then
        Canvas.StretchDraw(rct, FUncheckedBmp)
      else
        Canvas.StretchDraw(rct, FDefUncheckedBmp);
  end
  else begin
    {} // version with windows-drawn checkmark
    Canvas.Brush.Color := Color;
    if nfChecked in ANode.Flags then
    begin
    {
      inc(rct.Right); Dec(rct.Top);
      DrawFrameControl(Canvas.Handle, rct, DFC_MENU, DFCS_MENUCHECK);
      dec(rct.Right); inc(rct.Top);
      Canvas.Brush.Style := bsClear;
    }
      d:= FRowHeight div 5;
      Canvas.Brush.Color := FCheckMarkColor;
      Canvas.Pen.Style := psClear;
      //Canvas.Pen.Color := clGreen;
      Canvas.Polygon([Point(rct.Left+d,   rct.Bottom-d*3),
                      Point(rct.Left+d,   rct.Bottom-d*2),
                      Point(rct.Left+d*2-1, rct.Bottom-d),
                      Point(rct.Right-d, rct.Top+d*2-2),
                      Point(rct.Right-d, rct.Top+d-2),
                      Point(rct.Left+d*2-1, rct.Bottom-d*2)
                     ]);
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Style := psSolid;
    end else
      Canvas.Brush.Style := bsSolid;
    if FRowHeight > 18 then Canvas.Pen.Width := 2;
    Canvas.Pen.Color := clBlack;
    Canvas.Rectangle(rct);
    Canvas.Pen.Width := 1;
    { // fully-drawn-by-lines version
    Canvas.Brush.Color := clWhite;
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Width := FRowHeight div 11;
    Canvas.Rectangle(rct);
    if nfChecked in ANode.Flags then
    begin
      d:= FRowHeight div 6 + 1;
      Canvas.Pen.Color := FCheckMarkColor;
      Canvas.Pen.Width := FRowHeight div 6;
      Canvas.MoveTo(rct.Left+d, (rct.Top+Rct.Bottom) div 2);
      Canvas.LineTo((rct.Left+rct.Right) div 2, rct.Bottom-d);
      Canvas.LineTo(rct.Right-d, rct.Top+d);
    end;
    Canvas.Pen.Width := 1;
    }
  end;
end;

procedure TDumbCheckBoxTreeView.DoNodeClick(ANode: TDumbTreeNode; AButton: TMouseButton;
                                            Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  ////Application.MainForm.Caption:=Format('%d %d', [X, Y]);
  if (x > 0) and (x < FRowHeight) then
  begin
    if nfChecked in ANode.Flags then
      ANode.Flags := ANode.Flags - [nfChecked]
    else
      ANode.Flags := ANode.Flags + [nfChecked];
    RefreshNode(ANode);
  end;
end;

procedure TDumbCheckboxTreeView.SetCheckedBmp(const Value: TBitmap);
begin
  FCheckedBmp.Assign(Value);
  Refresh;
end;

procedure TDumbCheckboxTreeView.SetUncheckedBmp(const Value: TBitmap);
begin
  FUncheckedBmp.Assign(Value);
  Refresh;
end;

end.
