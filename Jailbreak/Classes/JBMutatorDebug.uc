// ============================================================================
// JBMutatorDebug
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBMutatorDebug.uc,v 1.4 2003/07/19 22:02:25 mychaeel Exp $
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

function bool MutatorIsAllowed() {

  return (Jailbreak(Level.Game) != None);
  }


// ============================================================================
// PostBeginPlay
//
// Registers a JBGameRules actor with the game.
// ============================================================================

event PostBeginPlay() {

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
//   SetSwitch On|Off [Red|Blue]   Enables or disables the release switches
//                                 for the given team. If no team is specified,
//                                 affects both teams.
//
//   CanBeJailed On|Off [<name>]   Sets whether the given player will be sent
//                                 to jail after being killed or not. If no
//                                 name is specified, affects all players.
//
// ============================================================================

function Mutate(string TextMutate, PlayerController Sender) {

  local string TextCommand;
  local string TextFlag;
  local string TextName;
  local string TextTeam;
  local Controller ControllerKilled;
    
  Super.Mutate(TextMutate, Sender);
  
  TextCommand = GetParam(TextMutate);
  
  if (TextCommand ~= "SetSwitch") {
    TextFlag = GetParam(TextMutate);
    TextTeam = GetParam(TextMutate);
    
    if (TextTeam ~= "Red"  || TextTeam == "") JBGameRulesDebug.ExecSetSwitch(0, TextFlag ~= "On");
    if (TextTeam ~= "Blue" || TextTeam == "") JBGameRulesDebug.ExecSetSwitch(1, TextFlag ~= "On");
    }

  else if (TextCommand ~= "CanBeJailed") {
    TextFlag = GetParam(TextMutate);
    TextName = GetParam(TextMutate);

    JBGameRulesDebug.ExecCanBeJailed(TextName, TextFlag ~= "On");
    }

  else if (TextCommand ~= "KillPlayer") {
    TextName = GetParam(TextMutate);

    ControllerKilled = JBGameRulesDebug.FindPlayer(TextName);
    if (ControllerKilled != None)
      ControllerKilled.Pawn.GibbedBy(Sender);
    }
  }


// ============================================================================
// GetParam
//
// Extracts and returns the first whitespace-delimited parameter from the
// given string.
// ============================================================================

function string GetParam(out string TextParam) {

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

defaultproperties {

  FriendlyName = "Jailbreak Debug";
  Description  = "Provides helper functions for debugging Jailbreak maps and code.";
  }