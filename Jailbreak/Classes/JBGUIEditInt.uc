//=============================================================================
// JBGUIEditInt
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGUIEditInt.uc,v 1.1 2004/03/09 15:39:13 wormbo Exp $
//
// User interface component: Combines a JBGUIComponentEdit with a label and allowes
// integer values in the specified range.
//=============================================================================


class JBGUIEditInt extends GUIMenuOption;


//=============================================================================
// Variables
//=============================================================================

var JBGUIComponentEdit MyEditBox;

var(Menu) bool bReadOnly;
var(Menu) int MinValue;
var(Menu) int MaxValue;
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
  MyEditBox.SetIntEdit(MinValue >= 0 && MaxValue >= 0);
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

function int GetValue()
{
  return MyEditBox.GetIntValue();
}


//=============================================================================
// SetValue
//
// Sets the editbox' value.
//=============================================================================

function SetValue(int NewValue)
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

function NumericRange(int Min, int Max)
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
  MyEditBox.SetIntEdit(b);
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
