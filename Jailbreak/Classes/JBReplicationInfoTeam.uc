// ============================================================================
// JBReplicationInfoTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Replicated information for one team.
// ============================================================================


class JBReplicationInfoTeam extends UnrealTeamInfo
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    nPlayersJailed;
  }


// ============================================================================
// Variables
// ============================================================================

var private int nPlayersJailed;         // number of jailed players
var private array<JBRelease> Releases;  // releases this team will attack


// ============================================================================
// PostNetBeginPlay
//
// Initializes the Releases array, spawns JBRelease actors where necessary and
// sets the timer.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBInfoJail thisJail;
  local JBRelease thisRelease;
  local Trigger thisTrigger;
  
  foreach DynamicActors(Class'JBRelease', thisRelease)
    if (thisRelease.Team == TeamIndex)
      Releases[Releases.Length] = thisRelease;
  
  if (Role < ROLE_Authority)
    return;

  if (Releases.Length == 0)
    foreach DynamicActors(Class'Trigger', thisTrigger)
      foreach DynamicActors(Class'JBInfoJail', thisJail, thisTrigger.Event)
        if (thisJail.CanRelease(TeamIndex)) {
          Releases[Releases.Length] = Spawn(Class'JBRelease', thisTrigger, , thisTrigger.Location);
          break;
          }

  SetTimer(0.1, True);
  }


// ============================================================================
// Timer
//
// Updates the number of jailed players in this team for replication.
// ============================================================================

event Timer() {

  CountPlayersJailed();
  }


// ============================================================================
// CountPlayersJailed
//
// Returns the number of jailed players in this team, server-side by counting
// them, client-side by reading the replicated value.
// ============================================================================

simulated function int CountPlayersJailed() {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;

  if (Role == ROLE_Authority) {
    InfoGame = JBReplicationInfoGame(Level.GRI);
    nPlayersJailed = 0;
    
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
      if (InfoGame.ListInfoPlayer[iInfoPlayer].IsInJail())
        nPlayersJailed++;
    }
  
  return nPlayersJailed;
  }


// ============================================================================
// CountPlayersTotal
//
// Returns the total number of players in this team. Kinda redundant, agreed.
// ============================================================================

simulated function int CountPlayersTotal() {

  return Size;
  }