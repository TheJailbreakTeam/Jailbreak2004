//=============================================================================
// JBGUIComponentEditBox
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// User interface component: An editbox which supports partial selections via
// mouse and keyboard, supports limitation of the allowed range of characters,
// can display content replaced by a mask char or only allows integer or float
// values.
//=============================================================================


class JBGUIComponentEditBox extends JBGUIComponent;


//=============================================================================
// Variables
//=============================================================================

var(Menu) protected string TextStr;     // holds the currently displayed string
var(Menu) protected float Value;        // if bNumericOnly, holds the current value
var(Menu) string AllowedCharSet;        // only these characters may be used in the string
var(Menu) bool bConvertDisallowedChars; // disallowed characters will be converted to underscores
var(Menu) string MaskChar;              // if set, text will be masked with the first char from this string
var(Menu) bool bNumericEdit;            // whether this control only allows numeric input
var(Menu) bool bIntegerOnly;            // if bNumericOnly, whether only integers are allowed
var(Menu) bool bPositiveOnly;           // if bNumericOnly, whether only positive numbers are allowed
var(Menu) bool bSpinButtons;            // in bNumericEdit, show spinner buttons
var(Menu) range NumericRange;           // if bNumericOnly, the range of values allowed
var(Menu) bool bReadOnly;               // whether the value may be modified
var(Menu) Material CaretMaterial;
var(Menu) Material SelectionMaterial;
var(Menu) string SpinnerButtonStyleName;
var(Menu) Material PlusImage;
var(Menu) Material MinusImage;


var GUIStyles SpinnerButtonStyle;
var bool bInsert;
var protected int SelStart;             // selection start (always ends at CaretPos)
var protected int CaretPos;             // where is the cursor within the string
var protected int FirstVis;             // position of the first visible character
var protected transient int NumVis;     // number of visible characters

var protected transient bool bMouseDown;      // for capturing mouse selections
var protected transient bool bSpinnerClicked; // for capturing spinner button clicks
var protected transient bool bSpinnerPlusClicked; // whether plus or minus was clicked
var protected transient bool bMouseMoveText;  // whether the mouse selection may change FirstVis in this frame
var protected transient bool bPrevMouseDown;  // whether the mouse button was pressed last frame already
var protected transient int MouseX;     // horizontal mouse cursor location in this control while pressing a button
var protected transient int MouseY;     // vertical mouse cursor location in this control while pressing a button


//-----------------------------------------------------------------------------
// Public functions
//-----------------------------------------------------------------------------

//=============================================================================
// delegate OnEnterPressed
//
// Called when the Enter key is pressed while this editbox is focused.
//=============================================================================

delegate OnEnterPressed(GUIComponent Sender);


//=============================================================================
// SetValue
//
// Sets a string value.
//=============================================================================

function SetValue(coerce string NewValue, optional bool bInternalChange)
{
  TextStr = ConvertIllegalChars(NewValue);
  if ( bIntegerOnly )
    Value = int(TextStr);
  else
    Value = float(TextStr);
  
  CaretPos = 0;
  SelectNone();
  if ( !bInternalChange )
    OnChange(Self);
}


//=============================================================================
// GetValue
//
// Returns the editbox' value.
//=============================================================================

function string GetValue()
{
  return TextStr;
}


//=============================================================================
// GetIntValue
//
// Returns the editbox' value as integer.
//=============================================================================

function int GetIntValue()
{
  return int(TextStr);
}


//=============================================================================
// GetFloatValue
//
// Returns the editbox' value as float.
//=============================================================================

function float GetFloatValue()
{
  return float(TextStr);
}


//=============================================================================
// SetReadOnly
//
// Sets the read-only status.
//=============================================================================

function SetReadOnly(bool bNewReadOnly)
{
  bReadOnly = bNewReadOnly;
}


//=============================================================================
// SetNumericRange
//
// Sets the editbox' numeric range.
//=============================================================================

function SetNumericRange(float Min, float Max)
{
  bNumericEdit = True;
  AllowedCharSet = "0123456789";
  if ( Min != int(Min) || Max != int(Max) )
    bIntegerOnly = False;
  NumericRange.Min = FMin(Min, Max);
  NumericRange.Max = FMax(Min, Max);
  TextStr = ConvertIllegalChars(TextStr);
  Value = FClamp(Value, NumericRange.Min, NumericRange.Max);
  CaretPos = 0;
  SelectNone();
}


//=============================================================================
// SetSpinButtons
//
// Enables or disables the spin buttons for numeric editboxes.
//=============================================================================

function SetSpinButtons(bool bShowSpinButtons)
{
  bSpinButtons = bShowSpinButtons;
}


//=============================================================================
// SetFloatEdit
//
// Makes the control a float editbox.
//=============================================================================

function SetFloatEdit(optional bool bPositive)
{
  bNumericEdit = True;
  AllowedCharSet = "0123456789";
  bIntegerOnly = False;
  bPositiveOnly = bPositive;
  TextStr = ConvertIllegalChars(TextStr);
  Value = float(TextStr);
  CaretPos = 0;
  SelectNone();
}


//=============================================================================
// SetIntEdit
//
// Makes the control an integer editbox.
//=============================================================================

function SetIntEdit(optional bool bPositive)
{
  bNumericEdit = True;
  AllowedCharSet = "0123456789";
  bIntegerOnly = True;
  bPositiveOnly = bPositive;
  TextStr = ConvertIllegalChars(TextStr);
  Value = int(TextStr);
  CaretPos = 0;
  SelectNone();
}


//=============================================================================
// SetTextEdit
//
// Makes the control a text editbox.
//=============================================================================

function SetTextEdit()
{
  if ( bNumericEdit )
    AllowedCharSet = "";
  bNumericEdit = False;
  TextStr = ConvertIllegalChars(TextStr);
  CaretPos = 0;
  SelectNone();
}


//=============================================================================
// SetMaskedTextEdit
//
// Makes the control a text editbox.
//=============================================================================

function SetMaskedTextEdit(string NewMaskChar)
{
  SetTextEdit();
  MaskChar = Left(NewMaskChar, 1);
}


//=============================================================================
// SetConvertDisallowedChars
//
// Sets the editbox' numeric range.
//=============================================================================

function SetConvertDisallowedChars(bool bConvert)
{
  SetTextEdit();
  bConvertDisallowedChars = bConvert;
}


//=============================================================================
// GetSelectedText
//
// Returns the selected part of the text.
//=============================================================================

function string GetSelectedText()
{
  return Mid(TextStr, GetSelStart(), GetSelLength());
}


//-----------------------------------------------------------------------------
// Internal functions
//-----------------------------------------------------------------------------

//=============================================================================
// InitComponent
//
// Initializes the component and registers several delegates.
//=============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  Super.InitComponent(GUIController, GUIComponentOwner);
  SpinnerButtonStyle = Controller.GetStyle(SpinnerButtonStyleName);
  
  if ( bNumericEdit )
    AllowedCharSet = "0123456789";
  
  TextStr = ConvertIllegalChars(TextStr);
  if ( bIntegerOnly )
    Value = int(TextStr);
  else
    Value = float(TextStr);
  
  // key events
  OnKeyEvent = KeyEvent;
  OnKeyType  = KeyType;
  
  // mouse events
  OnMousePressed      = MousePressed;
  OnMouseRelease      = MouseRelease;
  OnCapturedMouseMove = CapturedMouseMove;
  OnDblClick          = DoubleClick;
}


//=============================================================================
// GetSelStart
//
// Returns the start of the selection. (left side)
//=============================================================================

function int GetSelStart()
{
  return Min(CaretPos, SelStart);
}


//=============================================================================
// GetSelEnd
//
// Returns the end of the selection. (right side)
//=============================================================================

function int GetSelEnd()
{
  return Max(CaretPos, SelStart);
}


//=============================================================================
// GetSelLength
//
// Returns the length of the selection.
//=============================================================================

function int GetSelLength()
{
  return Abs(CaretPos - SelStart);
}


//=============================================================================
// CopyToClipboard
//
// Copies the selected part of the text to the clipboard.
//=============================================================================

function CopyToClipboard()
{
  PlayerOwner().CopyToClipboard(GetSelectedText());
}


//=============================================================================
// CutToClipboard
//
// Copies the selection to the clipboard and deletes the selection.
//=============================================================================

function CutToClipboard()
{
  CopyToClipboard();
  DeleteSelected();
}


//=============================================================================
// PasteFromClipboard
//
// Copies the selection to the clipboard and deletes the selection.
//=============================================================================

function PasteFromClipboard()
{
  local string PasteText;
  
  PasteText = PlayerOwner().PasteFromClipboard();
  if ( bReadOnly || PasteText == "" )
    return;
  
  TextStr = ConvertIllegalChars(Left(TextStr, GetSelStart()) $ PasteText $ Mid(TextStr, GetSelEnd()));
  if ( bIntegerOnly )
    Value = int(TextStr);
  else
    Value = float(TextStr);
  CaretPos = GetSelStart() + Len(PasteText);
  SelectNone();
  
  OnChange(Self);
}


//=============================================================================
// DeleteSelected
//
// Deletes the selected part of the text.
//=============================================================================

function DeleteSelected()
{
  if ( bReadOnly || GetSelLength() == 0 )
    return;
  
  TextStr = ConvertIllegalChars(Left(TextStr, GetSelStart()) $ Mid(TextStr, GetSelEnd()));
  if ( bIntegerOnly )
    Value = int(TextStr);
  else
    Value = float(TextStr);
  CaretPos = GetSelStart();
  SelectNone();
  
  OnChange(Self);
}


//=============================================================================
// SelectAll
//
// Selects the whole text.
//=============================================================================

function SelectAll()
{
  CaretPos = Len(TextStr);
  SelStart = 0;
}


//=============================================================================
// SelectNone
//
// Selects nothing.
//=============================================================================

function SelectNone()
{
  SelStart = CaretPos;
}


//=============================================================================
// MoveLeft
//
// Move caret to the left and possibly modify the selection.
//=============================================================================

function MoveLeft(optional bool bSelect, optional bool bWholeWord)
{
  if ( bWholeWord ) {
    while(CaretPos > 0 && Mid(TextStr, CaretPos - 1, 1) != " ")
      CaretPos--;
    while(CaretPos > 0 && Mid(TextStr, CaretPos - 1, 1) == " ")
      CaretPos--;
  }
  else if ( CaretPos > 0 )
    CaretPos--;
  
  if ( !bSelect )
    SelectNone();
}


//=============================================================================
// MoveRight
//
// Move caret to the right and possibly modify the selection.
//=============================================================================

function MoveRight(optional bool bSelect, optional bool bWholeWord)
{
  if ( bWholeWord ) {
    while(CaretPos < Len(TextStr) && Mid(TextStr, CaretPos, 1) != " ")
      CaretPos++;
    while(CaretPos < Len(TextStr) && Mid(TextStr, CaretPos, 1) == " ")
      CaretPos++;
  }
  else if ( CaretPos < Len(TextStr) )
    CaretPos++;
  
  if ( !bSelect )
    SelectNone();
}


//=============================================================================
// MoveHome
//
// Move caret to the start of the string and possibly modify the selection.
//=============================================================================

function MoveHome(optional bool bSelect)
{
  CaretPos = 0;
  
  if ( !bSelect )
    SelectNone();
}


//=============================================================================
// MoveEnd
//
// Move caret to the end of the string and possibly modify the selection.
//=============================================================================

function MoveEnd(optional bool bSelect)
{
  CaretPos = Len(TextStr);
  
  if ( !bSelect )
    SelectNone();
}


//=============================================================================
// BackspacePressed
//
// Delete character to the left or selection.
//=============================================================================

function BackspacePressed()
{
  if ( CaretPos == 0 && GetSelLength() == 0 )
    return;
  
  if ( GetSelLength() == 0 )
    MoveLeft(True);
  DeleteSelected();
}


//=============================================================================
// DeletePressed
//
// Delete character to the right or selection.
//=============================================================================

function DeletePressed()
{
  if ( CaretPos == Len(TextStr) && GetSelLength() == 0 )
    return;
  
  if ( GetSelLength() == 0 )
    MoveRight(True);
  DeleteSelected();
}


//=============================================================================
// ConvertIllegalChars
//
// Converts or removes illegal characters in the string and clamps numeric
// values to the specified range.
//=============================================================================

function string ConvertIllegalChars(coerce string Input)
{
  local string CurrentChar;
  local string Result;
  local bool bHasSign;
  local bool bHasFloatPoint;
  local float FResult;
  
  // first pass: remove or convert illegal characters
  while (Input != "") {
    CurrentChar = Left(Input, 1);
    Input = Mid(Input, 1);
    
    if ( bNumericEdit && !bPositiveOnly && !bHasSign && CurrentChar == "-" && Result == "" ) {
      Result = CurrentChar;
      bHasSign = True;
    }
    else if ( bNumericEdit && (CurrentChar == "." || CurrentChar == ",") ) {
      if ( !bIntegerOnly && !bHasFloatPoint ) {
        if ( Result != "" && Result != "-" ) {
          Result = Result $ ".";
          bHasFloatPoint = True;
        }
        else if ( Result == "" || Result == "-" ) {
          Result = Result $ "0.";
          bHasFloatPoint = True;
        }
      }
      else
        break;  // discard any characters after the decimal point
    }
    else if ( AllowedCharSet == "" || InStr(AllowedCharSet, CurrentChar) >= 0 )
      Result = Result $ CurrentChar;
    else if ( !bNumericEdit && bConvertDisallowedChars )
      Result = Result $ "_";
  }
  
  // second pass for numeric editboxes: remove all but one leading zeroes and clamp value to given limits
  if ( bNumericEdit ) {
    FResult = float(Result);
    if ( NumericRange.Min != NumericRange.Max )
      FResult = FClamp(FResult, NumericRange.Min, NumericRange.Max);
    
    if ( bIntegerOnly )
      Result = string(int(FResult));
    else
      Result = string(FResult);
    if ( bHasSign && FResult == 0 )
      Result = "-" $ Result;
  }
  
  return Result;
}


//=============================================================================
// KeyType
//
// Handle keys types and Ctrl+Char combinations.
//=============================================================================

function bool KeyType(out byte Key, optional string Unicode)
{
  local string InputString;
  
  if ( Controller.CtrlPressed && !Controller.AltPressed && !Controller.ShiftPressed ) {
    switch (Key) {
      case 1: // Ctrl-A
        SelectAll();
        return true;
      case 3: // Ctrl-C
        CopyToClipboard();
        return true;
      case 22: // Ctrl-V
        PasteFromClipboard();
        return true;
      case 24: // Ctrl-X
        CutToClipboard();
        return true;
    }
  }
  
  if ( bReadOnly || Controller.CtrlPressed || Controller.AltPressed || Key < 32 )
    return false;
  
  if ( UniCode != "" )
    InputString = Unicode;
  else
    InputString = Chr(Key);
  
  if ( InputString != "" ) {
    if ( GetSelLength() == 0 && !bInsert )
      MoveRight(True);
    DeleteSelected();
    TextStr = ConvertIllegalChars(Left(TextStr, CaretPos) $ InputString $ Mid(TextStr, CaretPos));
    if ( bIntegerOnly )
      Value = int(TextStr);
    else
      Value = float(TextStr);
    MoveRight();
    OnChange(Self);
  }
  
  return false;
}


//=============================================================================
// KeyEvent
//
// Handle special keys.
//=============================================================================

function bool KeyEvent(out byte Key, out byte State, float delta)
{
  if ( State == 1 ) {
    switch (Key) {
      Case 0x08:  // Backspace
        BackspacePressed();
        return true;
      Case 0x0D:  // Enter
        OnEnterPressed(Self);
        return true;
      Case 0x2E:  // Del
        if ( Controller.ShiftPressed )
          CutToClipboard();
        else if ( !Controller.CtrlPressed )
          DeletePressed();
        else
          return false;
        return true;
      Case 0x2D:  // Ins
        if ( Controller.ShiftPressed && !Controller.CtrlPressed )
          PasteFromClipboard();
        else if ( Controller.CtrlPressed && !Controller.ShiftPressed )
          CopyToClipboard();
        else if ( !Controller.CtrlPressed && !Controller.ShiftPressed )
          bInsert = !bInsert && bReadOnly;
        else
          return false;
        return true;
      Case 0x25:  // Left Arrow
        MoveLeft(Controller.ShiftPressed, Controller.CtrlPressed);
        return true;
      Case 0x26:  // Up Arrow
        return SpinnerPlusClick();
      Case 0x27:  // Right Arrow
        MoveRight(Controller.ShiftPressed, Controller.CtrlPressed);
        return true;
      Case 0x28:  // Down Arrow
        return SpinnerMinusClick();
      Case 0x24:  // Home
        MoveHome(Controller.ShiftPressed);
        return true;
      Case 0x23:  // End
        MoveEnd(Controller.ShiftPressed);
        return true;
    }
  }
  return false;
}


//=============================================================================
// MousePressed
//
// Capture mouse selection.
//=============================================================================

function MousePressed(GUIComponent Sender, bool RepeatClick)
{
  if ( MenuState == MSAT_Disabled )
    return;
  
  CapturedMouseMove(0, 0);
  
  if ( !bMouseDown && (!RepeatClick ^^ bSpinnerClicked) && bNumericEdit && bSpinButtons && !bReadOnly
      && (bSpinnerClicked || MouseX > ActualWidth() - ActualHeight() * 0.5) ) {
    if ( !RepeatClick )
      bSpinnerPlusClicked = MouseY < ActualHeight() * 0.5;
    
    if ( bSpinnerPlusClicked )
      SpinnerPlusClick();
    else
      SpinnerMinusClick();
    
    bSpinnerClicked = True;
    return;
  }
  
  bSpinnerClicked = False;
  bMouseDown = True;
  Timer();
  SetTimer(0.05, True);
}


//=============================================================================
// MouseRelease
//
// Capture mouse selection.
//=============================================================================

function MouseRelease(GUIComponent Sender)
{
  bMouseDown = False;
  bSpinnerClicked = False;
  KillTimer();
}


//=============================================================================
// DoubleClick
//
// Select all text.
//=============================================================================

function bool DoubleClick(GUIComponent Sender)
{
  SelectAll();
  
  return True;
}


//=============================================================================
// CapturedMouseMove
//
// Capture mouse selection.
//=============================================================================

function bool CapturedMouseMove(float DeltaX, float DeltaY)
{
	MouseX = Clamp(Controller.MouseX - ActualLeft(), 0, ActualWidth());
	MouseY = Clamp(Controller.MouseY - ActualTop(), 0, ActualHeight());
	
	return true;
}


//=============================================================================
// SpinnerPlusClick
//
// Increase the editbox value.
//=============================================================================

function bool SpinnerPlusClick()
{
  if ( !bNumericEdit )
    return false;
  
  if ( bIntegerOnly && Controller.CtrlPressed )
    Value += 10;
  else if ( bIntegerOnly )
    Value += 1;
  else if ( Controller.CtrlPressed )
    Value += 0.1;
  else
    Value += 0.01;
  
  if ( NumericRange.Min != NumericRange.Max && Value > NumericRange.Max )
    Value = NumericRange.Max;
  
  if ( bIntegerOnly )
    TextStr = string(int(Value));
  else
    TextStr = string(Value);
  
  OnChange(Self);
  SelectNone();
  return true;
}


//=============================================================================
// SpinnerMinusClick
//
// Decrease the editbox value.
//=============================================================================

function bool SpinnerMinusClick()
{
  if ( !bNumericEdit )
    return false;
  
  if ( bIntegerOnly && Controller.CtrlPressed )
    Value -= 10;
  else if ( bIntegerOnly )
    Value -= 1;
  else if ( Controller.CtrlPressed )
    Value -= 0.1;
  else
    Value -= 0.01;
  
  if ( NumericRange.Min != NumericRange.Max && Value < NumericRange.Min )
    Value = NumericRange.Min;
  if ( bPositiveOnly && Value < 0 )
    Value = 0;
  
  if ( bIntegerOnly )
    TextStr = string(int(Value));
  else
    TextStr = string(Value);
  
  OnChange(Self);
  SelectNone();
  return true;
}


//=============================================================================
// Timer
//
// Allow the FirstVis variable to be updated when the mouse selected a caret
// position outside the visible area.
//=============================================================================

event Timer()
{
  bMouseMoveText = True;
}


//=============================================================================
// Draw
//
// Draws the editbox.
//=============================================================================

function bool Draw(Canvas C)
{
  local int X, Y, W, H, ButtonW;
  local int SelBoxStart, SelBoxLength;
  local float SelStartX, CaretX, XL, YL;
  local int NewCaretPos;
  local string DisplayString;
  local int i;
  local eMenuState EditboxState;
  local eMenuState ButtonPlusState;
  local eMenuState ButtonMinusState;
  local float ColorFade;
  
  ColorFade = Abs((PlayerOwner().Level.Second % 2) * 1000 + PlayerOwner().Level.Millisecond - 1000) / 1000;
  ConstantColor(CaretMaterial).Color.R = Lerp(ColorFade ** 0.9,   0, 255, True);
  ConstantColor(CaretMaterial).Color.G = Lerp(ColorFade ** 0.9,   0, 255, True);
  ConstantColor(CaretMaterial).Color.B = Lerp(ColorFade ** 0.9,   0, 255, True);
  ConstantColor(CaretMaterial).Color.A = Lerp(ColorFade ** 0.9, 128, 192, True);
  ConstantColor(FinalBlend(SelectionMaterial).Material).Color.R = Lerp(ColorFade, 128, 192, True);
  ConstantColor(FinalBlend(SelectionMaterial).Material).Color.G = Lerp(ColorFade, 128, 192, True);
  ConstantColor(FinalBlend(SelectionMaterial).Material).Color.B = Lerp(ColorFade, 128, 192, True);
  ConstantColor(FinalBlend(SelectionMaterial).Material).Color.A = Lerp(ColorFade,  64, 128, True);
  
  X = ActualLeft();
  Y = ActualTop();
  W = ActualWidth();
  H = ActualHeight();
  EditboxState = MenuState;
  if ( bNumericEdit && bSpinButtons ) {
    ButtonW = FMin(H * 0.5, W * 0.5);
    W -= ButtonW;
    
    // find button states
    ButtonPlusState = MenuState;
    ButtonMinusState = MenuState;
    if ( MenuState == MSAT_Disabled ) {
      // button states ok
    }
    else if ( bSpinnerClicked || Controller.MouseX > X + W && Controller.MouseX < X + W + ButtonW ) {
      if ( MenuState != MSAT_Blurry ) {
        if ( MenuState == MSAT_Watched || MenuState == MSAT_Focused || !bSpinnerClicked ) {
          if ( Controller.MouseY > Y && Controller.MouseY < Y + H * 0.5 ) {
            ButtonPlusState  = MSAT_Watched;
            ButtonMinusState = MSAT_Blurry;
          }
          else if ( Controller.MouseY > Y + H * 0.5 && Controller.MouseY < Y + H ) {
            ButtonPlusState  = MSAT_Blurry;
            ButtonMinusState = MSAT_Watched;
          }
          else {
            ButtonPlusState  = MSAT_Blurry;
            ButtonMinusState = MSAT_Blurry;
          }
        }
        else {
          if ( bSpinnerPlusClicked )
            ButtonMinusState = MSAT_Blurry;
          else
            ButtonPlusState = MSAT_Blurry;
        }
      }
      if ( EditBoxState == MSAT_Pressed || EditBoxState == MSAT_Focused )
        EditBoxState = MSAT_Focused;
      else
        EditBoxState = MSAT_Blurry;
    }
    else {
      ButtonPlusState = MSAT_Blurry;
      ButtonMinusState = MSAT_Blurry;
      bSpinnerClicked = False;
    }
    if ( bReadOnly || NumericRange.Max != NumericRange.Min && Value >= NumericRange.Max )
      ButtonPlusState = MSAT_Disabled;
    if ( bReadOnly || NumericRange.Max != NumericRange.Min && Value <= NumericRange.Min || bPositiveOnly && Value <= 0 )
      ButtonMinusState = MSAT_Disabled;
    
    // draw plus button
    C.Style = SpinnerButtonStyle.RStyles[ButtonPlusState];
    C.DrawColor = SpinnerButtonStyle.ImgColors[ButtonPlusState];
    C.SetPos(X + W, Y);
    C.DrawTile(SpinnerButtonStyle.Images[ButtonPlusState],
        ButtonW, H * 0.5, 0, 0,
        SpinnerButtonStyle.Images[ButtonPlusState].MaterialUSize(),
        SpinnerButtonStyle.Images[ButtonPlusState].MaterialVSize()
    );
    C.DrawColor = SpinnerButtonStyle.FontColors[ButtonPlusState];
    C.SetPos(X + W, Y);
    C.DrawTile(Texture'NumButPlus',
        ButtonW, H * 0.5, 0, 0,
        Texture'NumButPlus'.MaterialUSize(),
        Texture'NumButPlus'.MaterialVSize()
    );
    
    // draw minus button
    C.Style = SpinnerButtonStyle.RStyles[ButtonMinusState];
    C.DrawColor = SpinnerButtonStyle.ImgColors[ButtonMinusState];
    C.SetPos(X + W, Y + H * 0.5);
    C.DrawTile(SpinnerButtonStyle.Images[ButtonMinusState],
        ButtonW, H * 0.5, 0, 0,
        SpinnerButtonStyle.Images[ButtonMinusState].MaterialUSize(),
        SpinnerButtonStyle.Images[ButtonMinusState].MaterialVSize()
    );
    C.DrawColor = SpinnerButtonStyle.FontColors[ButtonMinusState];
    C.SetPos(X + W, Y + H * 0.5);
    C.DrawTile(Texture'NumButMinus',
        ButtonW, H * 0.5, 0, 0,
        Texture'NumButMinus'.MaterialUSize(),
        Texture'NumButMinus'.MaterialVSize()
    );
  }
  if ( EditboxState == MSAT_Pressed )
    EditboxState = MSAT_Focused;
  Style.Draw(C, EditBoxState, X, Y, W, H);
  
  X += Style.BorderOffsets[0];
  Y += 0.5 * Style.BorderOffsets[1];
  W -= Style.BorderOffsets[0] + Style.BorderOffsets[2];
  H -= 0.5 * (Style.BorderOffsets[1] + Style.BorderOffsets[3]);
  
  if ( !bNumericEdit && MaskChar != "" ) {
    for (i = 0; i < Len(TextStr); i++)
      DisplayString = DisplayString $ Left(MaskChar, 1);
  }
  else
    DisplayString = TextStr;
  
  C.Font = Style.Fonts[EditBoxState].GetFont(C.SizeX);
  C.TextSize(Mid(DisplayString, FirstVis), XL, YL);
  if ( XL < W && FirstVis > 0 ) {
    do {
      FirstVis--;
      C.TextSize(Mid(DisplayString, FirstVis), XL, YL);
    } until (XL > W || FirstVis == -1 );
    FirstVis++;
    NumVis = Len(DisplayString) - FirstVis;
  }
  else if ( XL > W ) {
    NumVis = 0;
    do {
      NumVis++;
      C.TextSize(Mid(DisplayString, FirstVis, NumVis), XL, YL);
    } until (XL > W);
    NumVis--;
  }
  else
    NumVis = Len(DisplayString) - FirstVis;
  
  if ( bMouseDown ) {
    // find new caret position
    if ( MouseX < Style.BorderOffsets[0] ) {
      NewCaretPos = Max(FirstVis - 1, 0);
    }
    else {
      NewCaretPos = 0;
      do {
        C.TextSize(Mid(DisplayString, FirstVis, NewCaretPos), XL, YL);
        NewCaretPos++;
      } until (MouseX - 3 < Style.BorderOffsets[0] + XL || NewCaretPos > NumVis + 1);
      NewCaretPos += FirstVis - 1;
    }
    if ( bMouseMoveText ) {
      CaretPos = Clamp(NewCaretPos, FirstVis - 1, FirstVis + NumVis + 1);
      bMouseMoveText = False;
    }
    else {
      CaretPos = Clamp(NewCaretPos, FirstVis, FirstVis + NumVis);
    }
    if ( !bPrevMouseDown )
      SelectNone();
  }
  bPrevMouseDown = bMouseDown;
  
  CaretPos = Clamp(CaretPos, 0, Len(DisplayString));
  SelStart = Clamp(SelStart, 0, Len(DisplayString));
  if ( CaretPos < FirstVis ) {
    FirstVis = CaretPos;
    CaretX = 0;
  }
  else {
    C.TextSize(Mid(DisplayString, FirstVis, CaretPos - FirstVis), XL, YL);
    while (XL > W) {
      FirstVis++;
      C.TextSize(Mid(DisplayString, FirstVis, CaretPos - FirstVis), XL, YL);
    }
    CaretX = XL;
  }
  
  if ( !bInsert && GetSelLength() == 0 && EditBoxState == MSAT_Focused ) {
    if ( CaretPos < Len(DisplayString) )
      C.TextSize(Mid(DisplayString, CaretPos, 1), XL, YL);
    else
      C.TextSize(" ", XL, YL);
    C.SetPos(X + CaretX, Y);
    C.DrawTile(CaretMaterial, XL + 1, H, 0,0,1,1);
  }
  
  if ( GetSelLength() > 0 && EditBoxState != MSAT_Disabled && EditBoxState != MSAT_Blurry ) {
    SelBoxStart = Max(GetSelStart() - FirstVis, 0);
    if ( GetSelStart() >= FirstVis )
      SelBoxLength = GetSelLength();
    else
      SelBoxLength = Clamp(GetSelEnd() - FirstVis, 0, GetSelLength());
    
    C.TextSize(Mid(DisplayString, FirstVis + SelBoxStart, SelBoxLength), XL, YL);
    if ( SelBoxStart > 0 )
      C.TextSize(Mid(DisplayString, FirstVis, SelBoxStart), SelStartX, YL);
    C.DrawColor = Style.ImgColors[EditBoxState];
    C.Style = 5;  // STY_Alpha
    C.SetPos(X + SelStartX, Y);
    C.DrawTile(SelectionMaterial, FMin(XL, W - SelStartX), H, 0,0,1,1);
  }
  Style.DrawText(C, EditBoxState, X, Y, W, H, TXTA_Left, Mid(DisplayString, FirstVis));
  
  if ( (bInsert || GetSelLength() != 0) && EditBoxState == MSAT_Focused ) {
    C.DrawColor = Style.ImgColors[EditBoxState];
    C.Style = 5;  // STY_Alpha
    C.SetPos(X + CaretX - 1, Y);
    C.DrawTile(CaretMaterial, 2, H, 0,0,1,1);
  }
  
  return False;
}


//=============================================================================
// FloatToString
//
// Converts a float to a string representation.
// (see http://wiki.beyondunreal.com/WUtils)
//=============================================================================

static final function string FloatToString(float Value, optional int Precision)
{
  local int IntPart;
  local float FloatPart;
  local string IntString, FloatString;
  
  Precision = Max(Precision, 1);  // otherwise a simple int cast should be used
  
  if ( Value < 0 ) {
    IntString = "-";
    Value *= -1;
  }
  IntPart = int(Value);
  FloatPart = Value - IntPart;
  IntString = IntString $ string(IntPart);
  FloatString = string(int(FloatPart * 10 ** Precision));
  while (Len(FloatString) < Precision)
    FloatString = "0" $ FloatString;
  
  return IntString$"."$FloatString;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=ConstantColor Name=SelectionFade
    Outer=Jailbreak
  End Object
  Begin Object Class=FinalBlend Name=SelectionFinal
    Material=SelectionFade
    FrameBufferBlending=FB_AlphaBlend
    Outer=Jailbreak
  End Object
  Begin Object Class=ConstantColor Name=CaretFade
    Outer=Jailbreak
  End Object
  SelectionMaterial=SelectionFinal
  CaretMaterial=CaretFade
  
  WinHeight=0.06
  StyleName="SquareButton"
  SpinnerButtonStyleName="RoundButton"
  bAcceptsInput=True
  bTabStop=True
  bCaptureMouse=True
  bInsert=True
  bSpinButtons=True
}