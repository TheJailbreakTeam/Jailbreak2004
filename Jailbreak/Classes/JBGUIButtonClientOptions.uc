// ============================================================================
// JBGUIButtonClientOptions
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Button which is added to the mid-game menu. Opens the "Jailbreak Client
// Options" dialog when clicked.
// ============================================================================


class JBGUIButtonClientOptions extends GUIButton;


// ============================================================================
// InitComponent
//
// Sets the delegate which is called when the button is clicked. For some
// reason it is not possible to just set it in the defaultproperties section.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  Super.InitComponent(GUIController, GUIComponentOwner);
  OnClick = InternalOnClick;
}


// ============================================================================
// InternalOnClick
//
// Closes the mid-game menu and opens the "Jailbreak Client Options" dialog.
// ============================================================================

function bool InternalOnClick(GUIComponent GUIComponentSender)
{
  PlayerOwner().ClientOpenMenu("Jailbreak.JBGUIPageClientOptions");

  return True;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Caption   = "JAILBREAK OPTIONS";
  StyleName = "MidGameButton";
}