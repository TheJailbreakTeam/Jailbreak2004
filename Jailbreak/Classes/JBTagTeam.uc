// ============================================================================
// JBTagTeam
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagTeam.uc,v 1.12 2003/02/26 20:01:31 mychaeel Exp $
//
// Replicated information for one team.
// ============================================================================


class JBTagTeam extends JBTag
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
// Internal
// ============================================================================

static function JBTagTeam FindFor(TeamInfo Keeper) {
  return JBTagTeam(InternalFindFor(Keeper)); }
static function JBTagTeam SpawnFor(TeamInfo Keeper) {
  return JBTagTeam(InternalSpawnFor(Keeper)); }


// ============================================================================
// Register
//
// Starts the timer.
// ============================================================================

function Register() {

  Super.Register();

  SetTimer(0.2, True);
  }


// ============================================================================
// Timer
//
// Updates the currently selected team tactics and counts jailed and free
// players for replication.
// ============================================================================

event Timer() {

  Tactics      = JBBotTeam(UnrealTeamInfo(Keeper).AI).GetTactics();
  bTacticsAuto = JBBotTeam(UnrealTeamInfo(Keeper).AI).GetTacticsAuto();
  
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
  
  nPlayers = TeamInfo(Keeper).Size;
  nPlayersFree   = 0;
  nPlayersJailed = 0;
  
  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Keeper)
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
    return TeamInfo(Keeper).Size;
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
          PlayerStart(thisNavigationPoint).TeamNumber == TeamInfo(Keeper).TeamIndex &&
          !Jailbreak(Level.Game).ContainsActorArena(thisNavigationPoint) &&
          !Jailbreak(Level.Game).ContainsActorJail (thisNavigationPoint))
        ListPlayerStart[ListPlayerStart.Length] = PlayerStart(thisNavigationPoint);

  return ListPlayerStart;
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function TeamInfo GetTeam() {
  return TeamInfo(Keeper); }
simulated function name GetTactics() {
  return Tactics; }
simulated function bool GetTacticsAuto() {
  return bTacticsAuto; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  RemoteRole = ROLE_SimulatedProxy;
  }