// ============================================================================
// JBGUIUserKeyBinding
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Adds Jailbreak-specific key bindings to the standard key binder dialog.
// ============================================================================


class JBGUIUserKeyBinding extends GUIUserKeyBinding
  notplaceable;


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  KeyData[0] = (KeyLabel="Jailbreak",bIsSection=True);
  KeyData[1] = (KeyLabel="Auto Team Tactics",Alias="TeamTactics Auto");
  KeyData[2] = (KeyLabel="Make Bots More Aggressive",Alias="TeamTactics Up");
  KeyData[3] = (KeyLabel="Make Bots More Defensive",Alias="TeamTactics Down");
  }