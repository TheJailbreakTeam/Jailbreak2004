//=============================================================================
// JBGUIComponentSlider
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// User interface component: A simple slider control without any captions.
//=============================================================================


class JBGUIComponentSlider extends JBGUIComponent;


//=============================================================================
// Variables
//=============================================================================

var(Menu) protected float MinValue;
var(Menu) protected float MaxValue;
var(Menu) string SliderStyleName;

var GUIStyles SliderStyle;
var protected float Value;
var protected bool bIntSlider;


//=============================================================================
// delegate OnValueChanged
//
// Similar to the OnChangeDelegate, but called every time the slider value
// changes for whatever reason. Useful for updating a label.
//=============================================================================

delegate OnValueChanged(JBGUIComponentSlider Sender);


//=============================================================================
// InitComponent
//
// Initializes the component and registers several delegates.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.Initcomponent(MyController, MyOwner);
  SliderStyle = Controller.GetStyle(SliderStyleName);
  
  OnCapturedMouseMove = InternalCapturedMouseMove;
  OnKeyEvent          = InternalOnKeyEvent;
  OnClick             = InternalOnClick;
  OnMousePressed      = InternalOnMousePressed;
}


//=============================================================================
// SetSliderRange
//
// Sets the slider's min and max values.
//=============================================================================

function SetSliderRange(float NewMin, float NewMax)
{
  local float OldValue;
  
  OldValue = Value;
  
  MinValue = FMin(NewMin, NewMax);
  MaxValue = FMax(NewMin, NewMax);
  if ( bIntSlider ) {
    MinValue = Round(MinValue);
    MaxValue = Round(MaxValue);
  }
  else {
    MinValue = Round(100 * MinValue) * 0.01;
    MaxValue = Round(100 * MaxValue) * 0.01;
  }
  
  Value = FClamp(Value, MinValue, MaxValue);
  
  if ( Value != OldValue )
    OnValueChanged(Self);
}


//=============================================================================
// SetIntSlider
//
// Sets the slider's value.
//=============================================================================

function SetIntSlider(bool bIntegerOnly)
{
  local float OldValue;
  
  OldValue = Value;
  
  bIntSlider = bIntegerOnly;
  if ( bIntSlider )
    Value = Round(Value);
  
  if ( Value != OldValue )
    OnValueChanged(Self);
}


//=============================================================================
// SetValue
//
// Sets the slider's value.
//=============================================================================

function SetValue(float NewValue, optional bool bInternalChange)
{
  Value = FClamp(NewValue, MinValue, MaxValue);
  if ( bIntSlider )
    Value = Round(Value);
  else
    Value = Round(100 * Value) * 0.01;
  
  OnValueChanged(Self);
  if ( !bInternalChange ) {
    OnChange(Self);
  }
}


//=============================================================================
// GetValue
//
// Returns the slider's value.
//=============================================================================

function float GetValue()
{
  return Value;
}


//=============================================================================
// GetValue
//
// Returns the slider's value.
//=============================================================================

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
  if ( State == 1 ) {
    if ( Key == 0x28 || Key == 0x62 || Key == 0x25 || Key == 0x64 ) { // Down or Left
      if ( bIntSlider && Controller.CtrlPressed )
        Adjust(-10);
      else if ( bIntSlider )
        Adjust(-1);
      else if ( Controller.CtrlPressed )
        Adjust(-0.1);
      else
        Adjust(-0.01);  
      return true;
    }
    else if ( Key==0x26 || Key==0x68 || Key==0x27 || Key==0x66 ) {  // Up or Right
      if ( bIntSlider && Controller.CtrlPressed )
        Adjust(10);
      else if ( bIntSlider )
        Adjust(1);
      else if ( Controller.CtrlPressed )
        Adjust(0.1);
      else
        Adjust(0.01);  
      return true;
    }
  }
  
  return false;
}


//=============================================================================
// Adjust
//
// Adjusts the slider's value by the specified amount.
//=============================================================================

function Adjust(float Amount)
{
  local float OldValue;
  
  OldValue = Value;
  Value = FClamp(Value + Amount, MinValue, MaxValue);
  if ( bIntSlider )
    Value = Round(Value);
  else
    Value = Round(100 * Value) * 0.01;
  
  if ( Value != OldValue )
    OnValueChanged(Self);
  OnChange(Self);
}


//=============================================================================
// InternalCapturedMouseMove
//
// Captures the mouse movement while the button is held down.
//=============================================================================

function bool InternalCapturedMouseMove(float DeltaX, float DeltaY)
{
  local float OldValue;
  local float Left, Width, MouseX;
  
  OldValue = Value;
  Left = ActualLeft() + Style.BorderOffsets[0];
  Width = ActualWidth() - (Style.BorderOffsets[0] + Style.BorderOffsets[2]);
  MouseX = (Controller.MouseX - Left) / Width;
  
  Value = FClamp(Lerp(MouseX, MinValue, MaxValue), MinValue, MaxValue);
  if ( bIntSlider )
    Value = Round(Value);
  else
    Value = Round(100 * Value) * 0.01;
  
  if ( Value != OldValue )
    OnValueChanged(Self);
  return true;
}


//=============================================================================
// InternalOnClick
//
// Called when the mouse button is released.
//=============================================================================

function bool InternalOnClick(GUIComponent Sender)
{
  OnChange(Self);
  return true;
}


//=============================================================================
// InternalOnMousePressed
//
// Called when the mouse button is pressed.
//=============================================================================

function InternalOnMousePressed(GUIComponent Sender, bool RepeatClick)
{
  InternalCapturedMouseMove(0, 0);
}


//=============================================================================
// Draw
//
// Draws the slider.
//=============================================================================

function bool Draw(Canvas C)
{
  local int X, Y, W, H;
  local float SliderX;
  
  X = ActualLeft();
  Y = ActualTop();
  W = ActualWidth() - Style.BorderOffsets[0] - Style.BorderOffsets[2];
  H = ActualHeight();
  
  Style.Draw(C, MenuState, X + Style.BorderOffsets[0], Y + (H - Style.BorderOffsets[1]) * 0.5,
    W, (Style.BorderOffsets[1] + Style.BorderOffsets[3]) * 0.5);
  SliderX = (Value - MinValue) / (MaxValue - MinValue);
  
  SliderStyle.Draw(C, MenuState, X + W * SliderX, Y,
      SliderStyle.BorderOffsets[0] + SliderStyle.BorderOffsets[2], H);
  
  return False;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  StyleName="SquareButton"
  SliderStyleName="RoundButton"
  bAcceptsInput=True
  bCaptureMouse=True
  WinHeight=0.05
  bRequireReleaseClick=True
  OnClickSound=CS_Click
}