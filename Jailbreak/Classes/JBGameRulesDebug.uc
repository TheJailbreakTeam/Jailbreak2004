// ============================================================================
// JBGameRulesDebug
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameRulesDebug.uc,v 1.2 2003/03/22 10:21:11 mychaeel Exp $
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
// FindPlayer
//
// Finds and returns a player given his or her name.
// ============================================================================

function Controller FindPlayer(string TextName)
{
  local Controller thisController;
  local int iTeam;

  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (thisController.Pawn                  != None &&
        thisController.PlayerReplicationInfo != None &&
        thisController.PlayerReplicationInfo.PlayerName ~= TextName)
      return thisController;

       if (TextName ~= "Red")  iTeam = 0;
  else if (TextName ~= "Blue") iTeam = 1;
  else return None;

  for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
    if (thisController.Pawn                       != None &&
        thisController.PlayerReplicationInfo      != None &&
        thisController.PlayerReplicationInfo.Team != None &&
        thisController.PlayerReplicationInfo.Team.TeamIndex == iTeam)
      return thisController;

  return None;
}


// ============================================================================
// ExecSetSwitch
//
// Enables or disables a team's release switches.
// ============================================================================

function ExecSetSwitch(int iTeam, bool bIsReleaseEnabled)
{
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

function ExecCanBeJailed(string TextName, bool bCanBeJailed)
{
  local int iController;
  local Controller thisController;
  local Controller ControllerPlayer;

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
    ControllerPlayer = FindPlayer(TextName);

    if (ControllerPlayer == None) {
      Log("Jailbreak Debugging: Unable to find player named '" $ TextName $ "'");
    }

    else {
      for (iController = 0; iController < ListControllerDisabledJail.Length; iController++)
        if (ListControllerDisabledJail[iController] == ControllerPlayer)
          break;

      if (bCanBeJailed) {
        Log("Jailbreak Debugging: Player '" $ ControllerPlayer.PlayerReplicationInfo.PlayerName $ "' can be jailed");
        if (iController < ListControllerDisabledJail.Length)
          ListControllerDisabledJail.Remove(iController, 1);
      }

      else {
        Log("Jailbreak Debugging: Player '" $ ControllerPlayer.PlayerReplicationInfo.PlayerName $ "' cannot be jailed");
        if (iController >= ListControllerDisabledJail.Length)
          ListControllerDisabledJail[ListControllerDisabledJail.Length] = ControllerPlayer;
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

function bool CanSendToJail(JBTagPlayer TagPlayer)
{
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

function bool CanRelease(TeamInfo Team, Pawn PawnInstigator, GameObjective Objective)
{
  if (bIsReleaseEnabledByTeam[Team.TeamIndex] == 0)
    return False;

  return Super.CanRelease(Team, PawnInstigator, Objective);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsReleaseEnabledByTeam[0] = 1;
  bIsReleaseEnabledByTeam[1] = 1;
}