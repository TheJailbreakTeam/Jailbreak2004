// ============================================================================
// JBReplicationInfoTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoTeam.uc,v 1.6 2002/12/23 00:40:45 mychaeel Exp $
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
    nPlayers, nPlayersFree, nPlayersJailed, bTacticsAuto, Tactics;
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

var private float TimeCountPlayers;  // time of last CountPlayers call
var private int nPlayers;            // replicated total number of players
var private int nPlayersFree;        // number of free players
var private int nPlayersJailed;      // number of jailed players

var private bool bTacticsAuto;  // automatically select appropriate tactics
var private ETactics Tactics;   // currently selected team tactics


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
// Updates the number of jailed and free players in this team for replication.
// ============================================================================

event Timer() {

  CountPlayers();
  }


// ============================================================================
// CountPlayers
//
// Counts free and jailed players in this team and updates the corresponding
// variables. Updated only once per tick.
// ============================================================================

private function CountPlayers() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (TimeCountPlayers == Level.TimeSeconds)
    return;
  
  nPlayers = Size;
  nPlayersFree   = 0;
  nPlayersJailed = 0;
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Self)
      if (thisTagPlayer.IsInJail())
        nPlayersJailed++;
      else if (thisTagPlayer.IsFree())
        nPlayersFree++;

  TimeCountPlayers = Level.TimeSeconds;
  }
  


// ============================================================================
// CountPlayersFree
//
// Returns the number of free players in this team, server-side by counting
// them, client-side by reading the replicated value.
// ============================================================================

simulated function int CountPlayersFree(optional bool bCached) {

  if (Role == ROLE_Authority && !bCached)
    CountPlayers();
  
  return nPlayersFree;
  }


// ============================================================================
// CountPlayersJailed
//
// Returns the number of jailed players in this team, server-side by counting
// them, client-side by reading the replicated value.
// ============================================================================

simulated function int CountPlayersJailed(optional bool bCached) {

  if (Role == ROLE_Authority && !bCached)
    CountPlayers();

  return nPlayersJailed;
  }


// ============================================================================
// CountPlayersTotal
//
// Returns the total number of players in this team client- and server-side.
// ============================================================================

simulated function int CountPlayersTotal() {

  if (Role == ROLE_Authority)
    return Size;
  else
    return nPlayers;  // replicated value
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
  return Tactics; }
simulated function bool GetTacticsAuto() {
  return bTacticsAuto; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bTacticsAuto = True;
  }