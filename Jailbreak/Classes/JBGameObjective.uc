// ============================================================================
// JBGameObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameObjective.uc,v 1.3 2003/01/01 22:11:17 mychaeel Exp $
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

var Trigger TriggerRelease;            // trigger associated to this objective

var private int RepDefenderTeamIndex;  // replicated value for compass


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
  
  Class'JBTagObjective'.Static.SpawnFor(Self);
  
  Super.PostBeginPlay();
  }


// ============================================================================
// FindDefenseScripts
//
// Finds defense scripts with the given tag.
// ============================================================================

function FindDefenseScripts(name TagDefenseScripts) {

  local UnrealScriptedSequence thisScript;

  foreach AllActors(Class'UnrealScriptedSequence', DefenseScripts, TagDefenseScripts)
    if (DefenseScripts.bFirstScript)
      break;
  
  for (thisScript = DefenseScripts; thisScript != None; thisScript = thisScript.NextScript)
    thisScript.bFreelance = False;
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
// SpecialHandling
//
// Directs bots to the associated trigger instead of the objective itself.
// ============================================================================

event Actor SpecialHandling(Pawn Pawn) {

  if (TriggerRelease != None)
    return TriggerRelease;

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