//=============================================================================
// JBGUIEditSlider
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIEditSlider.uc,v 1.2 2004/03/26 20:42:16 tarquin Exp $
//
// User interface component: Combines a slider and an editbox with a label.
//=============================================================================


class JBGUIEditSlider extends GUIMultiComponent;


//=============================================================================
// Variables
//=============================================================================

var GUILabel MyLabel;
var GUISlider MySlider;
var GUIComponent MyEditBox;

var(Menu) protected float MinValue;
var(Menu) protected float MaxValue;
var(Menu) protected float Value;
var(Menu) protected bool bIntegerOnly;
var(Menu) protected bool bSpinButtons;  // ignored in UT2004

var(Menu) localized string Caption;     // Caption for the label
var(Menu) string LabelFont;             // Name of the Font for the label
var(Menu) color LabelColor;             // Color for the label  
var(Menu) float CaptionWidth;
var(Menu) float EditBoxWidth;
var(Menu) float SliderWidth;
var(Menu) float LeftIndent; // left indent of label, relative to parent


//=============================================================================
// InitComponent
//
// Initializes the component and sets up the editbox.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);
  
  if ( bIntegerOnly )
         RemoveComponent(Controls[3]);
    else RemoveComponent(Controls[2]);
  
  MyLabel   = GUILabel (Controls[0]);
  MySlider  = GUISlider(Controls[1]);
  MyEditBox =           Controls[2];

  OnPreDraw = InternalOnPreDraw;
  
  // label
  MyLabel.Caption   = Caption;
  MyLabel.TextFont  = LabelFont;
  MyLabel.TextColor = LabelColor;

  // slider
  MySlider.OnChange            = InternalOnChange;
  MySlider.OnCapturedMouseMove = InternalCapturedMouseMove;
  MySlider.FriendlyLabel       = MyLabel;
  MySlider.MinValue            = MinValue;
  MySlider.MaxValue            = MaxValue;
  MySlider.bIntSlider          = bIntegerOnly;
  MySlider.SetHint(Hint);
  MySlider.SetValue(Value);
  
  // editbox
  if ( GUINumericEdit(MyEditBox) != None ) {
    GUINumericEdit(MyEditBox).MinValue = MinValue;
    GUINumericEdit(MyEditBox).MaxValue = MaxValue;
    GUINumericEdit(MyEditBox).SetValue(Value);
  }
  else if ( GUIFloatEdit(MyEditBox) != None ) {
    GUIFloatEdit(MyEditBox).MinValue = MinValue;
    GUIFloatEdit(MyEditBox).MaxValue = MaxValue;
    GUIFloatEdit(MyEditBox).SetValue(Value);
  }
  
  MyEditBox.OnChange      = InternalOnChange;
  MyEditBox.FriendlyLabel = MyLabel;
  MyEditBox.SetHint(Hint);
  
  // layout
  MyLabel  .WinWidth = CaptionWidth;
  MySlider .WinWidth = SliderWidth;
  MyEditBox.WinWidth = EditboxWidth;
  
  switch (
    int( CaptionWidth == -1 ) +
    int( SliderWidth  == -1 ) +
    int( EditboxWidth == -1 ) ) {
    case 3:
      // all defaults
      MyLabel.WinWidth    = 0.3;
      MySlider.WinWidth   = 0.4;
      MyEditBox.WinWidth  = 0.3;
      break;
    case 2:
      // two defaults, one measurement
      if( CaptionWidth != -1 ) {
        MySlider.WinWidth  = 0.5 * ( 1 - CaptionWidth);
        MyEditBox.WinWidth = 0.5 * ( 1 - CaptionWidth);
      }
      if( SliderWidth != -1 ) {
        MyLabel.WinWidth   = 0.5 * ( 1 - SliderWidth);
        MyEditBox.WinWidth = 0.5 * ( 1 - SliderWidth);
      }
      if( EditboxWidth != -1 ) {
        MyLabel.WinWidth   = 0.5 * ( 1 - EditboxWidth);
        MySlider.WinWidth  = 0.5 * ( 1 - EditboxWidth);
      }
      break;
    case 1:
      // one default, two measurements
      if( CaptionWidth == -1 ) {
        MyLabel.WinWidth   = 1 - SliderWidth - EditboxWidth;
      }
      if( SliderWidth == -1 ) {
        MySlider.WinWidth  = 1 - CaptionWidth - EditboxWidth;
      }
      if( EditboxWidth == -1 ) {
        MyEditBox.WinWidth = 1 - CaptionWidth - SliderWidth;
      }
    break;
    // case 0: covered before switch statement
  }
  MySlider.WinLeft  = MyLabel.WinWidth;
  MyEditBox.WinLeft = 1 - MyEditBox.WinWidth;
  
  // shorten slider a bit for a small gap
  MySlider.WinWidth *= 0.9;
  
  // tweak for indent
  MyLabel.WinLeft   = LeftIndent / WinWidth;
  MyLabel.WinWidth -= LeftIndent / WinWidth;
}


//=============================================================================
// InternalOnPreDraw
//
// Handle friendly label MenuState.
//=============================================================================

function bool InternalOnPreDraw(Canvas C)
{
  if ( MySlider.MenuState > MyEditBox.MenuState )
    MyLabel.MenuState = MySlider.MenuState;
  else
    MyLabel.MenuState = MyEditBox.MenuState;
  
  return false;
}


//=============================================================================
// GetValue
//
// Returns the editbox' value.
//=============================================================================

function float GetValue()
{
  return Value;
}


//=============================================================================
// SetValue
//
// Sets the editbox' value.
//=============================================================================

function SetValue(float NewValue)
{
  Value = NewValue;

  if ( bIntegerOnly )
       Value = Round(Value);
  else Value = Round(Value * 100) * 0.01;

       if ( GUINumericEdit(MyEditBox) != None ) GUINumericEdit(MyEditBox).SetValue(Value);
  else if ( GUIFloatEdit  (MyEditBox) != None ) GUIFloatEdit  (MyEditBox).SetValue(Value);

  MySlider.SetValue(Value);
}


//=============================================================================
// IntegerOnly
//
// Change the editbox' read-only status.
//=============================================================================

function IntegerOnly(bool bIntOnly)
{
  bIntegerOnly = bIntOnly;
  Log("Warning:" @ Self @ "bIntegerOnly change ignored");
}


//=============================================================================
// NumericRange
//
// Change the editbox' numeric range.
//=============================================================================

function NumericRange(float NewMin, float NewMax)
{
  MinValue = FMin(NewMin, NewMax);
  MaxValue = FMax(NewMin, NewMax);

  if ( bIntegerOnly ) {
    MinValue = Round(MinValue);
    MaxValue = Round(MaxValue);
  }

  Value = FClamp(Value, MinValue, MaxValue);

  if ( GUINumericEdit(MyEditBox) != None ) {
    GUINumericEdit(MyEditBox).MinValue = MinValue;
    GUINumericEdit(MyEditBox).MaxValue = MaxValue;
  }
  else if ( GUIFloatEdit(MyEditBox) != None ) {
    GUIFloatEdit(MyEditBox).MinValue = MinValue;
    GUIFloatEdit(MyEditBox).MaxValue = MaxValue;
  }

  MySlider.MinValue = MinValue;
  MySlider.MaxValue = MaxValue;
}


//=============================================================================
// SpinButtons
//
// Change the editbox' positive-only status.
//=============================================================================

function SpinButtons(bool bShow)
{
  bSpinButtons = bShow;
  Log("Warning:" @ Self @ "bSpinButtons change ignored");
}


//=============================================================================
// InternalOnChange
//
// Called when the value of one component changed. Syncronizes the values.
//=============================================================================

singular function InternalOnChange(GUIComponent Sender)
{
  local float NewValue;

  if ( Sender == MyEditBox ) {
         if ( GUINumericEdit(MyEditBox) != None ) NewValue = int  (GUINumericEdit(MyEditBox).Value);
    else if ( GUIFloatEdit  (MyEditBox) != None ) NewValue = float(GUIFloatEdit  (MyEditBox).Value);
    MySlider.SetValue(NewValue);
  }
  else if ( Sender == MySlider ) {
    NewValue = MySlider.Value;
         if ( GUINumericEdit(MyEditBox) != None ) GUINumericEdit(MyEditBox).SetValue(NewValue);
    else if ( GUIFloatEdit  (MyEditBox) != None ) GUIFloatEdit  (MyEditBox).SetValue(NewValue);
  }
  
  Value = NewValue;
  OnChange(self);
}


//=============================================================================
// InternalCapturedMouseMove
//
// Called by the slider when the slider button is moved. Updates the edit box
// without calling the global OnChange event.
//=============================================================================

function bool InternalCapturedMouseMove(float deltaX, float deltaY)
{
  local bool bResult;
  
  bResult = MySlider.InternalCapturedMouseMove(deltaX, deltaY);
  
       if ( GUINumericEdit(MyEditBox) != None ) GUINumericEdit(MyEditBox).SetValue(MySlider.Value);
  else if ( GUIFloatEdit  (MyEditBox) != None ) GUIFloatEdit  (MyEditBox).SetValue(MySlider.Value);

  return bResult;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Begin Object Class=GUILabel Name=Label
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0
    WinHeight=1
    WinWidth=0.3
    StyleName="TextLabel"
  End Object
  Controls(0)=GUILabel'Label'
  
  Begin Object Class=GUISlider Name=Slider
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.3
    WinHeight=1
    WinWidth=0.4
  End Object
  Controls(1)=GUISlider'Slider'
  
  Begin Object Class=GUINumericEdit Name=EditBoxInt
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.7
    WinHeight=1
    WinWidth=0.3
  End Object
  Controls(2)=GUINumericEdit'EditBoxInt'

  Begin Object Class=GUIFloatEdit Name=EditBoxFloat
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.7
    WinHeight=1
    WinWidth=0.3
  End Object
  Controls(3)=GUIFloatEdit'EditBoxFloat'
  
  WinWidth=0.5
  WinHeight=0.06
  bSpinButtons=True
  CaptionWidth=0.3
  SliderWidth=-1
  EditBoxWidth=0.3
  LabelFont="UT2MenuFont"
  LabelColor=(R=255,G=255,B=255,A=255)
}