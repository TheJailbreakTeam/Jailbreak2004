// ============================================================================
// JBGameRulesDebug
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Implements game rules for Jailbreak for debugging purposes.
// ============================================================================


class JBGameRulesDebug extends JBGameRules
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var array<Controller> ListControllerDisabledJail;
var byte bIsReleaseEnabledByTeam[2];


// ============================================================================
// ExecSetSwitch
//
// Enables or disables a team's release switches.
// ============================================================================

function ExecSetSwitch(int iTeam, bool bIsReleaseEnabled) {

  bIsReleaseEnabledByTeam[iTeam] = int(bIsReleaseEnabled);
  
  if (bIsReleaseEnabled)
    Log("Jailbreak Debugging: Enabled release switch for team" @ iTeam);
  else
    Log("Jailbreak Debugging: Disabled release switch for team" @ iTeam);
  }


// ============================================================================
// ExecCanBeJailed
//
// Records whether a given player can be jailed or not. If no player name is
// given, all players are affected.
// ============================================================================

function ExecCanBeJailed(string TextName, bool bCanBeJailed) {

  local int iController;
  local Controller thisController;

  if (TextName == "") {
    ListControllerDisabledJail.Length = 0;
    
    if (bCanBeJailed) {
      Log("Jailbreak Debugging: All players can be jailed");
      }
    
    else {
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.bIsPlayer)
          ListControllerDisabledJail[ListControllerDisabledJail.Length] = thisController;
    
      Log("Jailbreak Debugging: No players can be jailed");
      }
    }
  
  else {
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (thisController.PlayerReplicationInfo != None &&
          thisController.PlayerReplicationInfo.PlayerName ~= TextName)
        break;
    
    if (thisController == None) {
      Log("Jailbreak Debugging: Unable to find player named '" $ TextName $ "'");
      }
    
    else {
      for (iController = 0; iController < ListControllerDisabledJail.Length; iController++)
        if (ListControllerDisabledJail[iController] == thisController)
          break;
      
      if (bCanBeJailed) {
        Log("Jailbreak Debugging: Player '" $ TextName $ "' can be jailed");
        if (iController < ListControllerDisabledJail.Length)
          ListControllerDisabledJail.Remove(iController, 1);
        }
      
      else {
        Log("Jailbreak Debugging: Player '" $ TextName $ "' can not be jailed");
        if (iController >= ListControllerDisabledJail.Length)
          ListControllerDisabledJail[ListControllerDisabledJail.Length] = thisController;
        }
      }
    }
  }


// ============================================================================
// CanSendToJail
//
// Takes the list of jail-disabled players into account before allowing to
// send a player to jail.
// ============================================================================

function bool CanSendToJail(JBTagPlayer TagPlayer) {

  local int iController;
  
  for (iController = 0; iController < ListControllerDisabledJail.Length; iController++)
    if (ListControllerDisabledJail[iController] == TagPlayer.GetController())
      return False;
  
  return Super.CanSendToJail(TagPlayer);
  }


// ============================================================================
// CanRelease
//
// Only allows a release if it has not been explicitly disabled.
// ============================================================================

function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective) {

  if (bIsReleaseEnabledByTeam[Team.TeamIndex] == 0)
    return False;

  return Super.CanRelease(Team, PawnInstigator, Objective);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bIsReleaseEnabledByTeam[0] = 1;
  bIsReleaseEnabledByTeam[1] = 1;
  }