// ============================================================================
// JBReplicationInfoTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoTeam.uc,v 1.4 2002/11/24 20:30:05 mychaeel Exp $
//
// Replicated information for one team.
// ============================================================================


class JBReplicationInfoTeam extends xTeamRoster
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    nPlayersFree, nPlayersJailed, bTacticsAuto, Tactics;
  }


// ============================================================================
// Types
// ============================================================================

enum ETactics {

  Tactics_Evasive,
  Tactics_Defensive,
  Tactics_Normal,
  Tactics_Aggressive,
  Tactics_Suicidal,
  };


// ============================================================================
// Variables
// ============================================================================

var private int nPlayersFree;    // number of free players
var private int nPlayersJailed;  // number of jailed players

var private bool bTacticsAuto;   // automatically select appropriate tactics
var private ETactics Tactics;    // currently selected team tactics


// ============================================================================
// PostBeginPlay
//
// Starts the timer.
// ============================================================================

event PostBeginPlay() {

  SetTimer(0.2, True);
  }


// ============================================================================
// Timer
//
// Updates the number of jailed players in this team for replication.
// ============================================================================

event Timer() {

  CountPlayersFree();
  CountPlayersJailed();
  }


// ============================================================================
// CountPlayersFree
//
// Returns the number of free players in this team, server-side by counting
// them, client-side by reading the replicated value.
// ============================================================================

simulated function int CountPlayersFree() {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;
  local JBReplicationInfoPlayer InfoPlayer;

  if (Role == ROLE_Authority) {
    InfoGame = JBReplicationInfoGame(Level.GRI);
    nPlayersFree = 0;
    
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++) {
      InfoPlayer = InfoGame.ListInfoPlayer[iInfoPlayer];
      if (InfoPlayer.IsFree() && InfoPlayer.GetPlayerReplicationInfo().Team == Self)
        nPlayersFree++;
      }
    }
  
  return nPlayersFree;
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
  local JBReplicationInfoPlayer InfoPlayer;

  if (Role == ROLE_Authority) {
    InfoGame = JBReplicationInfoGame(Level.GRI);
    nPlayersJailed = 0;
    
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++) {
      InfoPlayer = InfoGame.ListInfoPlayer[iInfoPlayer];
      if (InfoPlayer.GetPlayerReplicationInfo().Team == Self &&
          InfoPlayer.IsInJail())
        nPlayersJailed++;
      }
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


// ============================================================================
// SetTactics
//
// Sets the current team tactics.
// ============================================================================

function SetTactics(coerce ETactics NewTactics, optional bool bNewTacticsAuto) {

  Tactics = NewTactics;
  bTacticsAuto = bNewTacticsAuto;
  
  switch (Tactics) {
    case Tactics_Evasive:     AI.GotoState('TacticsEvasive');     break;
    case Tactics_Defensive:   AI.GotoState('TacticsDefensive');   break;
    case Tactics_Normal:      AI.GotoState('TacticsNormal');      break;
    case Tactics_Aggressive:  AI.GotoState('TacticsAggressive');  break;
    case Tactics_Suicidal:    AI.GotoState('TacticsSuicidal');    break;
    }
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function ETactics GetTactics() {
  return Tactics;
  }

simulated function bool GetTacticsAuto() {
  return bTacticsAuto;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bTacticsAuto = True;
  }