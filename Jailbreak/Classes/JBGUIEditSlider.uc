//=============================================================================
// JBGUIEditSlider
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIEditSlider.uc,v 1.1 2004/03/09 18:55:04 wormbo Exp $
//
// User interface component: Combines a slider and an editbox with a label.
//=============================================================================


class JBGUIEditSlider extends GUIMultiComponent;


//=============================================================================
// Variables
//=============================================================================

var GUILabel MyLabel;
var JBGUIComponentSlider MySlider;
var JBGUIComponentEdit MyEditBox;

var(Menu) protected float MinValue;
var(Menu) protected float MaxValue;
var(Menu) protected float Value;
var(Menu) protected bool bIntegerOnly;
var(Menu) protected bool bSpinButtons;

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
  
  MyLabel   = GUILabel(Controls[0]);
  MySlider  = JBGUIComponentSlider(Controls[1]);
  MyEditBox = JBGUIComponentEdit(Controls[2]);
  OnPreDraw = InternalOnPreDraw;
  
  // label
  MyLabel.Caption   = Caption;
  MyLabel.TextFont  = LabelFont;
  MyLabel.TextColor = LabelColor;

  // slider
  MySlider.OnChange          = InternalOnChange;
  MySlider.OnValueChanged    = InternalOnValueChanged;
  MySlider.Hint              = Hint;
  MySlider.FriendlyLabels[0] = MyLabel;
  MySlider.SetSliderRange(MinValue, MaxValue);
  MySlider.SetIntSlider(bIntegerOnly);
  MySlider.SetValue(Value, True);
  
  // editbox
  if ( bIntegerOnly )
    MyEditBox.SetIntEdit(MinValue >= 0 && MaxValue >= 0);
  else
    MyEditBox.SetFloatEdit(MinValue >= 0 && MaxValue >= 0);
  MyEditBox.SetNumericRange(MinValue, MaxValue);
  MyEditBox.SetSpinButtons(bSpinButtons);
  MyEditBox.SetValue(Value);
  MyEditBox.OnChange          = InternalOnChange;
  MyEditBox.Hint              = Hint;
  MyEditBox.FriendlyLabels[0] = MyLabel;
  MyEditBox.OnEnterPressed    = InternalOnEnterPressed;
  
  // layout
  MyLabel.WinWidth    = CaptionWidth;
  MySlider.WinWidth   = SliderWidth;
  MyEditBox.WinWidth  = EditboxWidth;
  
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
        MySlider.WinWidth   = 0.5 * ( 1 - CaptionWidth);
        MyEditBox.WinWidth  = 0.5 * ( 1 - CaptionWidth);
      }
      if( SliderWidth != -1 ) {
        MyLabel.WinWidth   = 0.5 * ( 1 - SliderWidth);
        MyEditBox.WinWidth  = 0.5 * ( 1 - SliderWidth);
      }
      if( EditboxWidth != -1 ) {
        MyLabel.WinWidth   = 0.5 * ( 1 - EditboxWidth);
        MySlider.WinWidth   = 0.5 * ( 1 - EditboxWidth);
      }
      break;
    case 1:
      // one default, two measurements
      if( CaptionWidth == -1 ) {
        MyLabel.WinWidth   = 1 - SliderWidth - EditboxWidth;
      }
      if( SliderWidth == -1 ) {
        MySlider.WinWidth   = 1 - CaptionWidth - EditboxWidth;
      }
      if( EditboxWidth == -1 ) {
        MyEditBox.WinWidth  = 1 - CaptionWidth - SliderWidth;
      }
    break;
    // case 0: covered before switch statement
  }
  MySlider.WinLeft  = MyLabel.WinWidth;
  MyEditBox.WinLeft = 1 - MyEditBox.WinWidth;
  
  // tweak for indent
  MyLabel.WinLeft   = LeftIndent / WinWidth;
  MyLabel.WinWidth  -= LeftIndent / WinWidth;
}


//=============================================================================
// InternalOnEnterPressed
//
// Called when the Enter key is pressed while the editbox is focused.
//=============================================================================

function InternalOnEnterPressed(GUIComponent Sender)
{
  OnEnterPressed(Self);
}


//=============================================================================
// delegate OnEnterPressed
//
// Called when the Enter key is pressed while this editbox is focused.
//=============================================================================

delegate OnEnterPressed(GUIComponent Sender);


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
  else
    Value = Round(Value * 100) * 0.01;
  MyEditBox.SetValue(Value);
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
  MySlider.SetIntSlider(bIntOnly);
  if ( bIntOnly ) {
    MyEditBox.SetIntEdit(MinValue >= 0 && MaxValue >= 0);
    Value = Round(Value);
  }
  else
    MyEditBox.SetFloatEdit(MinValue >= 0 && MaxValue >= 0);
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
  MyEditBox.SetNumericRange(MinValue, MaxValue);
  MySlider.SetSliderRange(MinValue, MaxValue);
  MyEditBox.bPositiveOnly = MinValue >= 0 && MaxValue >= 0;
}


//=============================================================================
// SpinButtons
//
// Change the editbox' positive-only status.
//=============================================================================

function SpinButtons(bool bShow)
{
  bSpinButtons = bShow;
  MyEditBox.SetSpinButtons(bShow);
}


//=============================================================================
// InternalOnChange
//
// Called when the value of one component changed. Syncronizes the values.
//=============================================================================

singular function InternalOnChange(GUIComponent Sender)
{
  if ( Sender == MyEditBox ) {
    MySlider.SetValue(MyEditBox.GetFloatValue());
    Value = MyEditBox.GetFloatValue();
  }
  else if ( Sender == MySlider ) {
    MyEditBox.SetValue(MySlider.GetValue(), True);
    Value = MyEditBox.GetFloatValue();
  }
  
  OnChange(self);
}


//=============================================================================
// InternalOnDrawCaption
//
// Called when the slider wants to draw its caption.
//=============================================================================

function InternalOnValueChanged(JBGUIComponentSlider Sender)
{
  MyEditBox.SetValue(MySlider.GetValue(), True);
  Value = MyEditBox.GetFloatValue();
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
  
  Begin Object Class=JBGUIComponentSlider Name=Slider
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.3
    WinHeight=1
    WinWidth=0.4
  End Object
  Controls(1)=JBGUIComponentSlider'Slider'
  
  Begin Object Class=JBGUIComponentEdit Name=EditBox
    bScaleToParent=True
    bBoundToParent=True
    WinTop=0
    WinLeft=0.7
    WinHeight=1
    WinWidth=0.3
    bNumericEdit=True
  End Object
  Controls(2)=JBGUIComponentEdit'EditBox'
  
  WinWidth=0.5
  WinHeight=0.06
  bSpinButtons=True
  CaptionWidth=0.3
  SliderWidth=-1
  EditBoxWidth=0.3
  LabelFont="UT2MenuFont"
  LabelColor=(R=255,G=255,B=255,A=255)
}