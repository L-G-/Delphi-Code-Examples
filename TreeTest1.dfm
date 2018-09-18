object Form1: TForm1
  Left = 1512
  Top = 132
  Width = 401
  Height = 567
  Caption = 'DumbTreeView Test/Demo'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = [fsBold]
  OldCreateOrder = False
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object UpperPanel: TPanel
    Left = 0
    Top = 0
    Width = 393
    Height = 105
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      393
      105)
    object RowHeightLabel: TLabel
      Left = 8
      Top = 28
      Width = 71
      Height = 13
      Caption = 'Row Height:'
    end
    object IndentLabel: TLabel
      Left = 216
      Top = 28
      Width = 41
      Height = 13
      Caption = 'Indent:'
    end
    object FontSizeLabel: TLabel
      Left = 112
      Top = 28
      Width = 58
      Height = 13
      Caption = 'Font Size:'
    end
    object RowHeightTrackBar: TTrackBar
      Left = 4
      Top = 43
      Width = 97
      Height = 18
      LineSize = 10
      Max = 40
      Min = 10
      PageSize = 10
      Position = 16
      TabOrder = 0
      ThumbLength = 15
      TickStyle = tsNone
      OnChange = RowHeightTrackBarChange
    end
    object IndentTrackBar: TTrackBar
      Left = 209
      Top = 43
      Width = 81
      Height = 18
      LineSize = 10
      Max = 60
      Min = 10
      PageSize = 10
      Position = 18
      TabOrder = 1
      ThumbLength = 15
      TickStyle = tsNone
      OnChange = IndentTrackBarChange
    end
    object FontSizeTrackBar: TTrackBar
      Left = 105
      Top = 43
      Width = 97
      Height = 18
      LineSize = 10
      Max = 24
      Min = 4
      PageSize = 10
      Position = 10
      TabOrder = 2
      ThumbLength = 15
      TickStyle = tsNone
      OnChange = FontSizeTrackBarChange
    end
    object BoldFontCheckBox: TCheckBox
      Left = 304
      Top = 64
      Width = 77
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Bold Font'
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = BoldFontCheckBoxClick
    end
    object FontNameComboBox: TComboBox
      Left = 304
      Top = 36
      Width = 81
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akBottom]
      ItemHeight = 13
      TabOrder = 4
      OnChange = FontNameComboBoxChange
      Items.Strings = (
        'MS Shell Dlg'
        'MS Shell Dlg 2'
        'Arial'
        'Tahoma'
        'Verdana'
        'Microsoft Sans Serif'
        'MS Sans Serif'
        'System'
        'Fixedsys')
    end
    object RootLinesCheckBox: TCheckBox
      Left = 152
      Top = 64
      Width = 101
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Lines at Root'
      Checked = True
      State = cbChecked
      TabOrder = 5
      OnClick = RootLinesCheckBoxClick
    end
    object MultiSelectCheckBox: TCheckBox
      Left = 304
      Top = 84
      Width = 89
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'MultiSelect'
      TabOrder = 6
      OnClick = MultiSelectCheckBoxClick
    end
    object CloseButton: TButton
      Left = 373
      Top = 0
      Width = 21
      Height = 22
      Anchors = [akTop, akRight]
      Caption = 'X'
      TabOrder = 7
      OnClick = CloseButtonClick
    end
    object CaptionPanel: TPanel
      Left = 0
      Top = 0
      Width = 372
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      Caption = 'DumbTreeView Test/Demo'
      Color = 15257760
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnDblClick = CaptionPanelDblClick
      OnMouseDown = CaptionPanelMouseDown
    end
    object LinesCheckBox: TCheckBox
      Left = 84
      Top = 64
      Width = 53
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Lines'
      Checked = True
      State = cbChecked
      TabOrder = 9
      OnClick = LinesCheckBoxClick
    end
    object ButtonsCheckBox: TCheckBox
      Left = 8
      Top = 64
      Width = 65
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Buttons'
      Checked = True
      State = cbChecked
      TabOrder = 10
      OnClick = ButtonsCheckBoxClick
    end
    object FullRowSelectCheckBox: TCheckBox
      Left = 184
      Top = 84
      Width = 113
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Full Row Select'
      TabOrder = 11
      OnClick = FullRowSelectCheckBoxClick
    end
    object CheckBoxesCheckBox: TCheckBox
      Left = 84
      Top = 84
      Width = 89
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'CheckBoxes'
      Checked = True
      State = cbChecked
      TabOrder = 12
      OnClick = CheckBoxesCheckBoxClick
    end
    object UseBitmapsCheckBox: TCheckBox
      Left = 8
      Top = 84
      Width = 69
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Bitmaps'
      Checked = True
      State = cbChecked
      TabOrder = 13
      OnClick = UseBitmapsCheckBoxClick
    end
    object Button1: TButton
      Left = 264
      Top = 64
      Width = 29
      Height = 17
      Caption = 'Button1'
      TabOrder = 14
      OnClick = Button1Click
    end
  end
  object LowerPanel: TPanel
    Left = 0
    Top = 468
    Width = 393
    Height = 72
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object AddRndButton: TButton
      Left = 8
      Top = 4
      Width = 125
      Height = 17
      Caption = 'Add random nodes:'
      TabOrder = 0
      OnClick = AddRndButtonClick
    end
    object DirCButton: TButton
      Left = 144
      Top = 9
      Width = 141
      Height = 32
      Caption = 'Add subfolders of  C:\'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = DirCButtonClick
    end
    object NumEdit: TEdit
      Left = 8
      Top = 23
      Width = 61
      Height = 21
      BiDiMode = bdLeftToRight
      ParentBiDiMode = False
      TabOrder = 2
      Text = '100000'
    end
    object ClearButton: TButton
      Left = 336
      Top = 9
      Width = 49
      Height = 32
      Caption = 'Clear'
      TabOrder = 3
      OnClick = ClearButtonClick
    end
    object DelButton: TButton
      Left = 292
      Top = 9
      Width = 37
      Height = 32
      Caption = 'Del'
      TabOrder = 4
      OnClick = DelButtonClick
    end
    object SiblingCheckBox: TCheckBox
      Left = 76
      Top = 26
      Width = 61
      Height = 17
      Caption = 'Sibling'
      TabOrder = 5
    end
    object SortButton: TButton
      Left = 144
      Top = 48
      Width = 81
      Height = 17
      Caption = 'sort childs'
      TabOrder = 6
      OnClick = SortButtonClick
    end
  end
end
