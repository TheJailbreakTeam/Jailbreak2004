// ============================================================================
// JBGameRulesJailFightTally
// Copyright 2006 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameRulesTally.uc,v 1.2 2006-12-10 18:08:15 jrubzjeknf Exp $
//
// Adds jail fight kills to the score tally.
// ============================================================================


class JBGameRulesJailFightTally extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var JBAddonJailFightTally Addon;


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
