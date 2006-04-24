// ============================================================================
// JBGameRulesTally
// Copyright 2006 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Adds jail fight kills to the score tally.
// ============================================================================


class JBGameRulesTally extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var JBAddonTally Addon;


// ============================================================================
// ScoreKill
//
// If both participants are in jail, adds the kill to the jail fight score
// tally maintained by the add-on class instance.
// ============================================================================

function ScoreKill(Controller ControllerKiller, Controller ControllerVictim)
{
  local JBTagPlayer TagPlayerKiller;
  local JBTagPlayer TagPlayerVictim;
  
  Super.ScoreKill(ControllerKiller, ControllerVictim);
  
  if (ControllerKiller == None ||
      ControllerVictim == None ||
      ControllerKiller == ControllerVictim)
    return;
  
  TagPlayerKiller = Class'JBTagPlayer'.Static.FindFor(ControllerKiller.PlayerReplicationInfo);
  TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);

  if (TagPlayerKiller != None && TagPlayerKiller.IsInJail() &&
      TagPlayerVictim != None && TagPlayerVictim.IsInJail())
    Addon.AddToTally(TagPlayerKiller, TagPlayerVictim);
}