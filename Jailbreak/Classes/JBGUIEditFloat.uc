//=============================================================================
// JBGUIEditFloat
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIEditFloat.uc,v 1.1 2004/03/09 15:39:12 wormbo Exp $
//
// User interface component: Combines a JBGUIComponentEdit with a label and allowes
// float values in the specified range.
//=============================================================================


class JBGUIEditFloat extends GUIMenuOption;


//=============================================================================
// Variables
//=============================================================================

var JBGUIComponentEdit MyEditBox;

var(Menu) bool bReadOnly;
var(Menu) float MinValue;
var(Menu) float MaxValue;
var(Menu) bool bPositiveOnly;
var(Menu) bool bSpinButtons;


//=============================================================================
// InitComponent
//
// Initializes the component and sets up the editbox.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);
  
  MyEditBox = JBGUIComponentEdit(MyComponent);
  MyEditBox.SetFloatEdit(MinValue >= 0 && MaxValue >= 0);
  MyEditBox.SetNumericRange(MinValue, MaxValue);
  MyEditBox.SetSpinButtons(bSpinButtons);
  MyEditBox.SetReadOnly(bReadOnly);
  MyEditBox.OnEnterPressed = InternalOnEnterPressed;
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
// GetValue
//
// Returns the editbox' value.
//=============================================================================

function float GetValue()
{
  return MyEditBox.GetFloatValue();
}


//=============================================================================
// SetValue
//
// Sets the editbox' value.
//=============================================================================

function SetValue(float NewValue)
{
  MyEditBox.SetValue(NewValue);
}


//=============================================================================
// ReadOnly
//
// Change the editbox' read-only status.
//=============================================================================

function ReadOnly(bool b)
{
  MyEditBox.SetReadOnly(b);
}


//=============================================================================
// NumericRange
//
// Change the editbox' numeric range.
//=============================================================================

function NumericRange(float Min, float Max)
{
  MinValue = Min;
  MaxValue = Max;
  MyEditBox.SetNumericRange(Min, Max);
  if ( Min != Max ) {
    bPositiveOnly = Min >= 0 && Max >= 0;
    MyEditBox.bPositiveOnly = bPositiveOnly;
  }
}


//=============================================================================
// PositiveOnly
//
// Change the editbox' positive-only status.
//=============================================================================

function PositiveOnly(bool b)
{
  bPositiveOnly = b;
  MyEditBox.SetFloatEdit(b);
  if ( bPositiveOnly && MinValue != MaxValue )
    NumericRange(Max(MinValue, 0), Max(MaxValue, 0));
}


//=============================================================================
// SpinButtons
//
// Change the editbox' positive-only status.
//=============================================================================

function SpinButtons(bool b)
{
  bSpinButtons = b;
  MyEditBox.SetSpinButtons(b);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  ComponentClassName="Jailbreak.JBGUIComponentEdit"
  bSpinButtons=True
  bHeightFromComponent=False
}
