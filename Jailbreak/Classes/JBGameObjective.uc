// ============================================================================
// JBGameObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Dummy game objective automatically spawned by the game to mark release
// switches that are simple triggers.
// ============================================================================


class JBGameObjective extends GameObjective
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var Trigger Trigger;


// ============================================================================
// PostBeginPlay
//
// Looks for the first objective in the objective chain and adds itself to the
// end of that chain. The default mechanism for chaining doesn't work for
// dynamically spawned objectives.
// ============================================================================

event PostBeginPlay() {

  local GameObjective thisObjective;
  
  foreach AllActors(Class'GameObjective', thisObjective)
    if (thisObjective.bFirstObjective)
      break;

  if (thisObjective != Self) {
    bFirstObjective = False;
    while (thisObjective.NextObjective != None)
      thisObjective = thisObjective.NextObjective;
    if (thisObjective != Self)
      thisObjective.NextObjective = Self;
    }
  
  Super.PostBeginPlay();
  }


// ============================================================================
// TellBotHowToDisable
//
// Directs the given bot to the trigger associated with thie objective.
// ============================================================================

function bool TellBotHowToDisable(Bot Bot) {

  if (Trigger != None)
    return Bot.Squad.FindPathToObjective(Bot, Trigger);

  Log("Warning: Objective" @ Self @ "has no associated release trigger");
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bStatic   = False;
  bNoDelete = False;
  }