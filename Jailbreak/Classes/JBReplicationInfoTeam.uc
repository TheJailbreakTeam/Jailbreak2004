// ============================================================================
// JBReplicationInfoTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoTeam.uc,v 1.9 2003/01/19 19:11:19 mychaeel Exp $
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
    Tactics, bTacticsAuto, nPlayers, nPlayersFree, nPlayersJailed;
  }


// ============================================================================
// Variables
// ============================================================================

var private name Tactics;            // currently selected team tactics
var private bool bTacticsAuto;       // tactics selected automatically

var private float TimeCountPlayers;  // time of last CountPlayers call
var private int nPlayers;            // replicated total number of players
var private int nPlayersFree;        // number of free players
var private int nPlayersJailed;      // number of jailed players

var private array<PlayerStart> ListPlayerStart;  // spawn points for this team


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
// Updates the currently selected team tactics and counts jailed and free
// players for replication.
// ============================================================================

event Timer() {

  Tactics      = JBBotTeam(AI).GetTactics();
  bTacticsAuto = JBBotTeam(AI).GetTacticsAuto();
  
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
// FindPlayerStarts
//
// Returns a list of PlayerStart actors used to spawn players of this team in
// freedom.
// ============================================================================

function array<PlayerStart> FindPlayerStarts() {

  local NavigationPoint thisNavigationPoint;

  if (ListPlayerStart.Length == 0)
    for (thisNavigationPoint = Level.NavigationPointList;
         thisNavigationPoint != None;
         thisNavigationPoint = thisNavigationPoint.nextNavigationPoint)
      if (PlayerStart(thisNavigationPoint) != None &&
          PlayerStart(thisNavigationPoint).TeamNumber == TeamIndex &&
          !Jailbreak(Level.Game).ContainsActorArena(thisNavigationPoint) &&
          !Jailbreak(Level.Game).ContainsActorJail (thisNavigationPoint))
        ListPlayerStart[ListPlayerStart.Length] = PlayerStart(thisNavigationPoint);

  return ListPlayerStart;
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function name GetTactics() {
  return Tactics; }
simulated function bool GetTacticsAuto() {
  return bTacticsAuto; }
