//=============================================================================
// JBGUIRadioButton
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBGUIRadioButton.uc,v 1.2 2004/03/28 16:12:46 tarquin Exp $
//
// A radio button. To be used by a JBGUIOptionGroup
//=============================================================================


class JBGUIRadioButton extends GUICheckBoxButton;

  
// ============================================================================
// Variables
// ============================================================================

var int IndexInParent; // the index of this button in the parent's array

  
// ============================================================================
// InternalOnClick
//
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
} 


//=============================================================================
// Defaults
//=============================================================================

defaultproperties
{
  CheckedOverlay[0] = Texture'2K4Menus.checkBoxBall_b';
  CheckedOverlay[1] = Texture'2K4Menus.checkBoxBall_w';
  CheckedOverlay[2] = Texture'2K4Menus.checkBoxBall_f';
  CheckedOverlay[3] = Texture'2K4Menus.checkBoxBall_p';
  CheckedOverlay[4] = Texture'2K4Menus.checkBoxBall_d';
}

