// ============================================================================
// JBGameObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameObjective.uc,v 1.1 2002/12/20 20:54:30 mychaeel Exp $
//
// Dummy game objective automatically spawned by the game to mark release
// switches that are simple triggers.
// ============================================================================


class JBGameObjective extends GameObjective
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    RepDefenderTeamIndex;
  }


// ============================================================================
// Variables
// ============================================================================

var Trigger TriggerRelease;

var private int RepDefenderTeamIndex;  // replicated value


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
  
  Class'JBInventoryObjective'.Static.SpawnFor(Self);
  
  Super.PostBeginPlay();
  }


// ============================================================================
// Tick
//
// Replicates the value of DefenderTeamIndex.
// ============================================================================

event Tick(float TimeDelta) {

  RepDefenderTeamIndex = DefenderTeamIndex;
  Disable('Tick');
  }


// ============================================================================
// PostNetBeginPlay
//
// Sets the DefenderTeamIndex variable to the replicated server-side value.
// Only required because this actor is dynamically spawned instead of
// statically placed in the map by level designers.
// ============================================================================

simulated event PostNetBeginPlay() {

  if (Role < ROLE_Authority)
    DefenderTeamIndex = RepDefenderTeamIndex;
  }


// ============================================================================
// TellBotHowToDisable
//
// Directs the given bot to the trigger associated with thie objective.
// ============================================================================

function bool TellBotHowToDisable(Bot Bot) {

  if (TriggerRelease != None)
    return Bot.Squad.FindPathToObjective(Bot, TriggerRelease);

  Log("Warning: Objective" @ Self @ "has no associated release trigger");
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bStatic         = False;
  bNoDelete       = False;
  bAlwaysRelevant = True;
  }