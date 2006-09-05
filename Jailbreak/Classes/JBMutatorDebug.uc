// ============================================================================
// JBMutatorDebug
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBMutatorDebug.uc,v 1.12 2006-09-02 03:03:27 mdavis Exp $
//
// Provides helper functions for debugging Jailbreak maps and code.
// ============================================================================


class JBMutatorDebug extends Mutator
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var JBGameRulesDebug JBGameRulesDebug;


// ============================================================================
// MutatorIsAllowed
//
// Allows using this mutator only with Jailbreak games.
// ============================================================================

function bool MutatorIsAllowed()
{
  return (Jailbreak(Level.Game) != None);
}


// ============================================================================
// PostBeginPlay
//
// Registers a JBGameRules actor with the game.
// ============================================================================

event PostBeginPlay()
{
  Log("Jailbreak Debugging: Debugging functions are available");

  JBGameRulesDebug = Spawn(Class'JBGameRulesDebug');

  if (Level.Game.GameRulesModifiers == None)
         Level.Game.GameRulesModifiers            = JBGameRulesDebug;
    else Level.Game.GameRulesModifiers.AddGameRules(JBGameRulesDebug);
}


// ============================================================================
// Mutate
//
// Provides commands to influence Jailbreak gameplay. Commands and their
// switches are not case-sensitive.
//
//   CauseEvent <event>            Works like the CauseEvent console command
//                                 available in standalone games, but works in
//                                 online games too.
//
//   SetSwitch On|Off [Red|Blue]   Enables or disables the release switches
//                                 for the given team. If no team is specified,
//                                 affects both teams.
//
//   Jam Red|Blue                  Jams the jails of the given team.
//
//   UnJam Red|Blue                UnJams the jails of the given team.
//
//   CanBeJailed On|Off [<name>|Me]
//                                 Sets whether the given player will be sent
//                                 to jail after being killed or not. If no
//                                 name is specified, affects all players.
//
//   Release Red|Blue|<jailtag>|<releaseevent>
//                                 Causes a release of the given team, the
//                                 given jail (for both teams if applicable) or
//                                 the given switch event, respectively.
//
//   ForceRelease Red|Blue|<jailtag>|<releaseevent>
//                                 Causes a forcerelease of the given team, the
//                                 given jail (for both teams if applicable) or
//                                 the given switch event, respectively.
//
//   KillPlayer Red|Blue|Each|<name>
//                                 Kills the given player. Splat.
//
//   ArenaMatch                    Starts an Arena match in the first Arena
//                                 it finds.
//
// ============================================================================

function Mutate(string TextMutate, PlayerController Sender)
{
  local string TextCommand;
  local string TextFlag;
  local string TextName;
  local string TextTeam;
  local Actor thisActor;
  local JBInfoArena thisArena;
  local JBInfoJail thisJail;
  local Controller ControllerKilled;

  Super.Mutate(TextMutate, Sender);

  TextCommand = GetParam(TextMutate);

  if (TextCommand ~= "CauseEvent") {
    foreach DynamicActors(Class'Actor', thisActor)
      if (string(thisActor.Tag) ~= TextMutate)
        thisActor.Trigger(Sender.Pawn, Sender.Pawn);
  }

  else if (TextCommand ~= "DestroyActor") {
    foreach DynamicActors(Class'Actor', thisActor)
      if (string(thisActor.Name) ~= TextMutate) {
        Log("Jailbreak Debugging: Destroying actor" @ thisActor @ "at" @ thisActor.Location);
        thisActor.Destroy();
      }
  }

  else if (TextCommand ~= "SetSwitch") {
    TextFlag = GetParam(TextMutate);
    TextTeam = GetParam(TextMutate);

    if (TextTeam ~= "Red"  || TextTeam == "") JBGameRulesDebug.ExecSetSwitch(0, TextFlag ~= "On");
    if (TextTeam ~= "Blue" || TextTeam == "") JBGameRulesDebug.ExecSetSwitch(1, TextFlag ~= "On");
  }

  else if (TextCommand ~= "Jam") {
    TextTeam = GetParam(TextMutate);

    Log("Jailbreak Debugging: Jamming all jails of team" @ TextTeam);

    for (thisJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail; thisJail != none; thisJail = thisJail.nextJail) {
      if (TextTeam ~= "Red"  || TextTeam == "") thisJail.Jam(0);
      if (TextTeam ~= "Blue" || TextTeam == "") thisJail.Jam(1);
    }
  }

  else if (TextCommand ~= "UnJam") {
    TextTeam = GetParam(TextMutate);

    Log("Jailbreak Debugging: Unjamming all jails of team" @ TextTeam);

    for (thisJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail; thisJail != none; thisJail = thisJail.nextJail) {
      if (TextTeam ~= "Red"  || TextTeam == "") thisJail.UnJam(0);
      if (TextTeam ~= "Blue" || TextTeam == "") thisJail.UnJam(1);
    }
  }

  else if (TextCommand ~= "CanBeJailed") {
    TextFlag = GetParam(TextMutate);
    TextName = GetParam(TextMutate);

    if( TextName ~= "Me" )
      TextName = Sender.PlayerReplicationInfo.PlayerName;

    JBGameRulesDebug.ExecCanBeJailed(TextName, TextFlag ~= "On");
  }

  else if (TextCommand ~= "Release") {
    JBGameRulesDebug.ExecRelease(TextMutate);
  }

  else if (TextCommand ~= "ForceRelease") {
    JBGameRulesDebug.ExecForceRelease(TextMutate);
  }

  else if (TextCommand ~= "KillPlayer") {
    TextName = GetParam(TextMutate);

    if( TextName ~= "Each" ) {
      ControllerKilled = JBGameRulesDebug.FindPlayer("Red");
      if (ControllerKilled != None)
        ControllerKilled.Pawn.GibbedBy(Sender);
      ControllerKilled = JBGameRulesDebug.FindPlayer("Blue");
      if (ControllerKilled != None)
        ControllerKilled.Pawn.GibbedBy(Sender);
    }
    else {
      ControllerKilled = JBGameRulesDebug.FindPlayer(TextName);
      if (ControllerKilled != None)
        ControllerKilled.Pawn.GibbedBy(Sender);
    }
  }

  else if (TextCommand ~= "ArenaMatch") {
    foreach AllActors(class'JBInfoArena',thisArena)
      break;
    if ( thisArena != None ) {
      thisArena.Trigger(Self, None);
    }
  }

  else if (TextCommand ~= "ToggleShowLocation") {
    JBGameRulesDebug.ShowLocation(Sender);
  }
}


// ============================================================================
// GetParam
//
// Extracts and returns the first whitespace-delimited parameter from the
// given string.
// ============================================================================

function string GetParam(out string TextParam)
{
  local int iCharSeparator;
  local string TextResult;

  iCharSeparator = InStr(TextParam, " ");
  if (iCharSeparator < 0)
    iCharSeparator = Len(TextParam);

  TextResult = Left(TextParam, iCharSeparator);
  TextParam  = Mid (TextParam, iCharSeparator);

  while (Left(TextParam, 1) == " ")
    TextParam = Mid(TextParam, 1);

  return TextResult;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  FriendlyName = "Jailbreak Debug";
  Description  = "Provides helper functions for debugging Jailbreak maps and code.";
}
