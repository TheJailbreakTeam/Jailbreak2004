// ============================================================================
// JBGUIUserKeyBinding
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUIUserKeyBinding.uc,v 1.3 2004/03/29 01:02:15 mychaeel Exp $
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
  KeyData[4] = (KeyLabel="View Arena Live Feed",Alias="ArenaCam");
  KeyData[5] = (KeyLabel="View Teammate",Alias="ViewTeamFree");
}