//=============================================================================
// JBGUIRadioButton
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// A radio button. To be used by a JBGUIOptionGroup
//=============================================================================


class JBGUIRadioButton extends GUICheckBoxButton;

  
// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\RadioButtonMark.dds alpha=on mips=off


// ============================================================================
// Variables
// ============================================================================

var int IndexInParent; // the index of this button in the parent's array

  
// ============================================================================
// InternalOnClick
// Do nothing if the button is already checked.
// Otherwise, alert the parent OptionGroup
// ============================================================================

function bool InternalOnClick(GUIComponent Sender)
{
  if( bChecked )
    return False; // clicking a checked button has no effect

  Super.InternalOnClick(Sender);
  if( JBGUIOptionGroup(MenuOwner) != None )
    JBGUIOptionGroup(MenuOwner).SetIndex(IndexInParent);
  log("*** JB GUI: friendly label of" @ IndexInParent @ "is:" @ FriendlyLabel.Caption);
} 


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  Graphic = Texture'RadioButtonMark'
}

