// ============================================================================
// JBGUIUserKeyBinding
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUIUserKeyBinding.uc,v 1.2 2004/02/16 17:17:02 mychaeel Exp $
//
// Adds Jailbreak-specific key bindings to the standard key binder dialog.
// ============================================================================


class JBGUIUserKeyBinding extends GUIUserKeyBinding
  notplaceable;


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  KeyData[0] = (KeyLabel="Jailbreak",bIsSection=True);
  KeyData[1] = (KeyLabel="Auto Team Tactics",Alias="TeamTactics Auto");
  KeyData[2] = (KeyLabel="Make Bots More Aggressive",Alias="TeamTactics Up");
  KeyData[3] = (KeyLabel="Make Bots More Defensive",Alias="TeamTactics Down");
  KeyData[4] = (KeyLabel="Toggle Arena Cam",Alias="ArenaCam");
}