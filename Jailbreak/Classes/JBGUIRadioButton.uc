//=============================================================================
// JBGUIRadioButton
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBGUIRadioButton.uc,v 1.2 2004/03/28 16:12:46 tarquin Exp $
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
  if( JBGUIComponentOptions(MenuOwner) != None )
    JBGUIComponentOptions(MenuOwner).SetIndex(IndexInParent);
} 


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  Graphic = Texture'RadioButtonMark'
}

