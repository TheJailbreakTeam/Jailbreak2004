//=============================================================================
// JBGUITextEdit
// Copyright 2003-2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// User interface component: Combines a JBGUIComponentEditBox with a label and allowes
// any type of text input.
//=============================================================================


class JBGUITextEdit extends GUIMenuOption;


//=============================================================================
// Variables
//=============================================================================

var JBGUIComponentEditBox MyEditBox;

var(Menu) bool bReadOnly;
var(Menu) bool bMasked;
var(Menu) bool bConvertIllegalChars;
var(Menu) string AllowedCharSet;


//=============================================================================
// InitComponent
//
// Initializes the component and sets up the editbox.
//=============================================================================

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
  Super.InitComponent(MyController, MyOwner);
  
  MyEditBox = JBGUIComponentEditBox(MyComponent);
  ReadOnly(bReadOnly);
  MaskText(bMasked);
  SetAllowedCharSet(AllowedCharSet, bConvertIllegalChars);
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
// GetText
//
// Returns the editbox' value.
//=============================================================================

function string GetText()
{
  return MyEditBox.GetValue();
}


//=============================================================================
// SetText
//
// Sets the editbox' value.
//=============================================================================

function SetText(string NewText)
{
  MyEditBox.SetValue(NewText);
}


//=============================================================================
// ReadOnly
//
// Change the editbox' read-only status.
//=============================================================================

function ReadOnly(bool b)
{
  bReadOnly = b;
  MyEditBox.SetReadOnly(b);
}


//=============================================================================
// MaskText
//
// Change the editbox' mask char.
//=============================================================================

function MaskText(bool b)
{
  bMasked = b;
  if ( b )
    MyEditBox.SetMaskedTextEdit("#");
  else
    MyEditBox.SetMaskedTextEdit("");
}


//=============================================================================
// SetAllowedCharSet
//
// Change the editbox' mask char.
//=============================================================================

function SetAllowedCharSet(string CharSet, optional bool bConvertIllegal)
{
  MyEditBox.AllowedCharSet = CharSet;
  MyEditBox.SetConvertDisallowedChars(bConvertIllegal);
  MyLabel.Hint = Hint;
  MyLabel.FocusInstead = MyEditBox;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  ComponentClassName="Jailbreak.JBGUIComponentEditBox"
  bHeightFromComponent=False
}
