// ============================================================================
// JBLoginMenu
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Jailbreak's login menu - the menu you see when you hit escape ingame.
// ============================================================================


class JBLoginMenu extends UT2K4PlayerLoginMenu;


// ============================================================================
// Variables
// ============================================================================

var GUITabItem JBHelpPanel;


// ============================================================================
// AddPanels
//
// Adds our JBMidGamePanelHelp to the ingame login menu on the very left.
// ============================================================================

function AddPanels()
{
  Panels.Insert(0,1);
  Panels[0] = JBHelpPanel;

  Super.AddPanels();
}


// ============================================================================
// HandleParameters
//
// Pops up the ingame login menu. If specified, the first tab you see is our
// JBMidGamePanelHelp, else it'll be the usual Game tab.
// ============================================================================

function HandleParameters(string Param1, string Param2)
{
  if (Param1 ~= "JBTutorial") {
    c_Main.ActivateTabByName(JBHelpPanel.Caption, True);
    return;
  }

  c_Main.ActivateTabByName(Panels[1].Caption, True);
}


// ============================================================================
// Default properties.
// ============================================================================

defaultproperties
{
  JBHelpPanel = (ClassName="Jailbreak.JBMidGamePanelHelp",Caption="Jailbreak Tutorial",Hint="How to play Jailbreak")
}
