// ============================================================================
// JBTagClient
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Attached to every PlayerController and used for exec function replication.
// Only accessible via a given PlayerController object; not chained.
// ============================================================================


class JBTagClient extends JBTag
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role < ROLE_Authority)
    ExecTeamTactics;
  }


// ============================================================================
// Internal
// ============================================================================

static function JBTagClient FindFor(PlayerController Keeper) {
  return JBTagClient(InternalFindFor(Keeper)); }
static function JBTagClient SpawnFor(PlayerController Keeper) {
  return JBTagClient(InternalSpawnFor(Keeper)); }


// ============================================================================
// ExecTeamTactics
//
// Sets team tactics. If no team is specified, sets tactics for this player's
// team; otherwise for the given team. Only administrators can change tactics
// for the enemy team.
// ============================================================================

function ExecTeamTactics(name Tactics, optional TeamInfo Team) {

  if (Team == None)
    Team = GetPlayerReplicationInfo().Team;
  
  if (Team != None &&
      (GetPlayerReplicationInfo().bAdmin ||
       GetPlayerReplicationInfo().Team == Team))
    JBBotTeam(UnrealTeamInfo(Team).AI).SetTactics(Tactics);
  }


// ============================================================================
// Accessors
// ============================================================================

function PlayerController GetPlayerController() {
  return PlayerController(Owner); }
function PlayerReplicationInfo GetPlayerReplicationInfo() {
  return PlayerController(Owner).PlayerReplicationInfo; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  RemoteRole = ROLE_SimulatedProxy;
  }