//=============================================================================
// JBGUIEditSlider
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIEditSlider.uc,v 1.1 2004/03/09 15:39:13 wormbo Exp $
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
  
  MyLabel.Caption   = Caption;
  MyLabel.TextFont  = LabelFont;
  MyLabel.TextColor = LabelColor;
  MyLabel.WinWidth  = CaptionWidth;
  if ( CaptionWidth == -1 && SliderWidth == -1 && EditboxWidth == -1 )
    MyLabel.WinWidth = 0.3;
  else if ( CaptionWidth == -1 && EditBoxWidth != -1 )
    MyLabel.WinWidth = 1 - SliderWidth - EditBoxWidth;
  else if ( CaptionWidth == -1 && EditBoxWidth == -1 )
    MyLabel.WinWidth = 0.5 * (1 - SliderWidth);
  else
    MyLabel.WinWidth = CaptionWidth;
  
  MySlider.OnChange          = InternalOnChange;
  MySlider.OnValueChanged    = InternalOnValueChanged;
  MySlider.Hint              = Hint;
  MySlider.FriendlyLabels[0] = MyLabel;
  MySlider.SetSliderRange(MinValue, MaxValue);
  MySlider.SetIntSlider(bIntegerOnly);
  MySlider.SetValue(Value, True);
  MySlider.WinLeft = CaptionWidth;
  if ( CaptionWidth == -1 && SliderWidth == -1 && EditboxWidth == -1 )
    MySlider.WinWidth = 0.4;
  else if ( SliderWidth == -1 && EditBoxWidth != -1 )
    MySlider.WinWidth = 1 - CaptionWidth - EditBoxWidth;
  else if ( SliderWidth == -1 && EditBoxWidth == -1 )
    MySlider.WinWidth = 0.5 * (1 - CaptionWidth);
  else
    MySlider.WinWidth = SliderWidth;
  
  if ( bIntegerOnly )
    MyEditBox.SetIntEdit(MinValue >= 0 && MaxValue >= 0);
  else
    MyEditBox.SetFloatEdit(MinValue >= 0 && MaxValue >= 0);
  MyEditBox.SetNumericRange(MinValue, MaxValue);
  MyEditBox.SetSpinButtons(bSpinButtons);
  MyEditBox.SetValue(Value);
  if ( CaptionWidth == -1 && SliderWidth == -1 && EditboxWidth == -1 )
    MyEditBox.WinWidth = 0.3;
  else if ( SliderWidth != -1 && EditBoxWidth == -1 )
    MyEditBox.WinWidth = 1 - CaptionWidth - SliderWidth;
  else if ( SliderWidth == -1 && EditBoxWidth == -1 )
    MyEditBox.WinWidth = 0.5 * (1 - CaptionWidth);
  else
    MyEditBox.WinWidth = EditBoxWidth;
  MyEditBox.WinLeft = 1 - MyEditBox.WinWidth;
  MyEditBox.OnChange          = InternalOnChange;
  MyEditBox.Hint              = Hint;
  MyEditBox.FriendlyLabels[0] = MyLabel;
  MyEditBox.OnEnterPressed    = InternalOnEnterPressed;
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