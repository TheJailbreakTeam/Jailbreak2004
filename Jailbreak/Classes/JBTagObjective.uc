// ============================================================================
// JBInventoryObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Stores and replicates information about an objective.
// ============================================================================


class JBInventoryObjective extends JBInventory
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    Objective, nPlayersReleasable;
  }


// ============================================================================
// Variables
// ============================================================================

var float ScaleDot;  // used to pulse dot in compass

var private GameObjective Objective;  // associated objective

var private float TimeCountPlayersReleasable;  // time of last update
var private int nPlayersReleasable;            // number of releasable players


// ============================================================================
// PreBeginPlay
//
// Destroys this actor if it wasn't spawned for a GameObjective.
// ============================================================================

event PreBeginPlay() {

  if (GameObjective(Owner) == None)
    Destroy();
  }


// ============================================================================
// PostBeginPlay
//
// Replicates the objective reference and starts the timer.
// ============================================================================

event PostBeginPlay() {

  Objective = GameObjective(Owner);
  SetTimer(0.1, True);
  }


// ============================================================================
// Timer
//
// Counts the players of both teams that can be released by attacking this
// objective and stores the values in nPlayersReleasable.
// ============================================================================

event Timer() {

  CountPlayersReleasable();
  }


// ============================================================================
// CountPlayersReleasable
//
// Returns the number of players that can be released by attacking this
// objective. Server-side, counts them; client-side, returns the replicated
// value.
// ============================================================================

simulated function int CountPlayersReleasable(optional bool bCached) {

  local int iInfoPlayer;
  local JBInfoJail JailPlayer;
  local JBReplicationInfoGame InfoGame;
  local JBReplicationInfoPlayer InfoPlayer;
  local UnrealTeamInfo TeamPlayer;
  
  if (Role == ROLE_Authority && !bCached && TimeCountPlayersReleasable != Level.TimeSeconds) {
    nPlayersReleasable = 0;
    InfoGame = JBReplicationInfoGame(Level.GRI);

    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++) {
      InfoPlayer = InfoGame.ListInfoPlayer[iInfoPlayer];
      TeamPlayer = UnrealTeamInfo(InfoPlayer.GetPlayerReplicationInfo().Team);
  
      if (TeamPlayer.TeamIndex != GameObjective(Owner).DefenderTeamIndex) {
        JailPlayer = InfoPlayer.GetJail();
        if (JailPlayer != None &&
            JailPlayer.Tag == GameObjective(Owner).Event &&
            JailPlayer.CanRelease(TeamPlayer))
          nPlayersReleasable++;
        }
      }
    }

  TimeCountPlayersReleasable = Level.TimeSeconds;
  return nPlayersReleasable;
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function GameObjective GetObjective() {
  return Objective;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bAlwaysRelevant = True;
  }