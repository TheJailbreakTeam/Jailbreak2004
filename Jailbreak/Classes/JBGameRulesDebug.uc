// ============================================================================
// JBGameRulesDebug
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameRulesDebug.uc,v 1.6 2006-09-02 03:03:27 mdavis Exp $
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

function ExecCanBeJailed(string TextName, bool bCanBeJailed, optional string TextTeam)
{
  local int iController;
  local int TeamIndex;
  local Controller thisController;
  local Controller ControllerPlayer;

  if (TextName == "") {
    ListControllerDisabledJail.Length = 0;

    if (bCanBeJailed)
      Log("Jailbreak Debugging: All players can be jailed");
    else {
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.bIsPlayer)
          ListControllerDisabledJail[ListControllerDisabledJail.Length] = thisController;

      Log("Jailbreak Debugging: No players can be jailed");
    }

    return;
  }

  if (TextName ~= "Team" && (TextTeam ~= "Red" || TextTeam ~= "Blue")) {
    if (TextTeam ~= "Red")  TeamIndex = 0;
    if (TextTeam ~= "Blue") TeamIndex = 1;

    if (bCanBeJailed) {
      for (iController = 0; iController < ListControllerDisabledJail.Length; iController++)
        if (ListControllerDisabledJail[iController] != None &&
            ListControllerDisabledJail[iController].GetTeamNum() == TeamIndex)
          ListControllerDisabledJail.Remove(iController, 1);

      Log("Jailbreak Debugging: Team '" $ TextTeam $ "' can be jailed");
    } else {
      for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (thisController.GetTeamNum() == TeamIndex)
          ListControllerDisabledJail[ListControllerDisabledJail.Length] = thisController;

      Log("Jailbreak Debugging: Team '" $ TextTeam $ "' cannot be jailed");
    }

    return;
  } else
    ControllerPlayer = FindPlayer(TextName);

  if (ControllerPlayer == None) {
    Log("Jailbreak Debugging: Unable to find player named '" $ TextName $ "'");

    return;
  }


  for (iController = 0; iController < ListControllerDisabledJail.Length; iController++)
    if (ListControllerDisabledJail[iController] == ControllerPlayer)
      break;

  if (bCanBeJailed) {
    Log("Jailbreak Debugging: Player '" $ ControllerPlayer.PlayerReplicationInfo.PlayerName $ "' can be jailed");

    if (iController < ListControllerDisabledJail.Length)
      ListControllerDisabledJail.Remove(iController, 1);

    return;
  }

  Log("Jailbreak Debugging: Player '" $ ControllerPlayer.PlayerReplicationInfo.PlayerName $ "' cannot be jailed");

  if (iController >= ListControllerDisabledJail.Length)
    ListControllerDisabledJail[ListControllerDisabledJail.Length] = ControllerPlayer;

}


// ============================================================================
// ExecRelease
//
// Releases either the red or blue team from all jails, or all jailed players
// from the jail with the given Tag, or causes the given release event.
// ============================================================================

function ExecRelease(string Whom)
{
  local TeamInfo TeamWhom;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  Log("Jailbreak Debugging: Releasing '" $ Whom $ "'");

       if (Whom ~= "Red")  TeamWhom = TeamGame(Level.Game).Teams[0];
  else if (Whom ~= "Blue") TeamWhom = TeamGame(Level.Game).Teams[1];

  if (TeamWhom != None) {
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.Release(TeamWhom);
  }

  else {
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
      if (string(thisJail.Tag) ~= Whom) {
        thisJail.Release(TeamGame(Level.Game).Teams[0]);
        thisJail.Release(TeamGame(Level.Game).Teams[1]);
      }

      if (string(thisJail.EventReleaseRed)  ~= Whom) thisJail.Release(TeamGame(Level.Game).Teams[0]);
      if (string(thisJail.EventReleaseBlue) ~= Whom) thisJail.Release(TeamGame(Level.Game).Teams[1]);
    }
  }
}


// ============================================================================
// ExecForceRelease
//
// ForceReleases either the red or blue team from all jails, or all jailed
// players from the jail with the given Tag, or causes the given release event.
// ============================================================================

function ExecForceRelease(string Whom)
{
  local TeamInfo TeamWhom;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  Log("Jailbreak Debugging: ForceReleasing '" $ Whom $ "'");

       if (Whom ~= "Red")  TeamWhom = TeamGame(Level.Game).Teams[0];
  else if (Whom ~= "Blue") TeamWhom = TeamGame(Level.Game).Teams[1];

  if (TeamWhom != None) {
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ForceRelease(TeamWhom);
  }

  else {
    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
      if (string(thisJail.Tag) ~= Whom) {
        thisJail.ForceRelease(TeamGame(Level.Game).Teams[0]);
        thisJail.ForceRelease(TeamGame(Level.Game).Teams[1]);
      }

      if (string(thisJail.EventReleaseRed)  ~= Whom) thisJail.ForceRelease(TeamGame(Level.Game).Teams[0]);
      if (string(thisJail.EventReleaseBlue) ~= Whom) thisJail.ForceRelease(TeamGame(Level.Game).Teams[1]);
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
// ShowLocation
//
// Will show the players current location on the map. Used to debug.
// ============================================================================

function ShowLocation(PlayerController Sender)
{
  local bool bShowingLoc;

  bShowingLoc = JBInterfaceHud(Sender.myHUD).GetDebugShowLoc();

  // Determine if we are already showing the location, so we can toggle
  // it on or off.
  if(bShowingLoc)
    JBInterfaceHud(Sender.myHUD).SetDebugShowLoc(false);
  else
    JBInterfaceHud(Sender.myHUD).SetDebugShowLoc(true);
}

// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bIsReleaseEnabledByTeam[0] = 1;
  bIsReleaseEnabledByTeam[1] = 1;
}
