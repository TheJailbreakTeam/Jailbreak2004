// ============================================================================
// JBTagObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagObjective.uc,v 1.7 2003/02/26 20:01:30 mychaeel Exp $
//
// Stores and replicates information about an objective.
// ============================================================================


class JBTagObjective extends JBTag
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    nPlayersReleasable;
  }


// ============================================================================
// Variables
// ============================================================================

var float ScaleDot;                   // used for pulsing compass dot

var private int nPlayersReleasable;   // number of releasable players
var private float TimeCountPlayersReleasable;  // time of last count

var transient int nPlayersCurrent;    // used by deployment functions
var transient int nPlayersDeployed;   // used by deployment functions


// ============================================================================
// Internal
// ============================================================================

var JBTagObjective nextTag;

static function JBTagObjective FindFor(GameObjective Keeper) {
  return JBTagObjective(InternalFindFor(Keeper)); }
static function JBTagObjective SpawnFor(GameObjective Keeper) {
  return JBTagObjective(InternalSpawnFor(Keeper)); }

protected simulated function JBTag InternalGetFirst() {
  return JBGameReplicationInfo(GetGameReplicationInfo()).firstTagObjective; }
protected simulated function InternalSetFirst(JBTag TagFirst) {
  JBGameReplicationInfo(GetGameReplicationInfo()).firstTagObjective = JBTagObjective(TagFirst); }
protected simulated function JBTag InternalGetNext() {
  return nextTag; }
protected simulated function InternalSetNext(JBTag TagNext) {
  nextTag = JBTagObjective(TagNext); }


// ============================================================================
// Register
//
// Replicates a reference to the objective and starts the timer.
// ============================================================================

function Register() {

  Super.Register();

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

  local JBInfoJail JailPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local TeamInfo TeamPlayer;
  
  if (Role < ROLE_Authority || bCached || TimeCountPlayersReleasable == Level.TimeSeconds)
    return nPlayersReleasable;
  
  nPlayersReleasable = 0;

  firstTagPlayer = JBGameReplicationInfo(GetGameReplicationInfo()).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    TeamPlayer = thisTagPlayer.GetTeam();

    if (TeamPlayer.TeamIndex != GetObjective().DefenderTeamIndex) {
      JailPlayer = thisTagPlayer.GetJail();

      if (JailPlayer != None &&
          JailPlayer.Tag == GetObjective().Event &&
          JailPlayer.CanReleaseTeam(TeamPlayer))
        nPlayersReleasable += 1;
      }
    }

  TimeCountPlayersReleasable = Level.TimeSeconds;
  return nPlayersReleasable;
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function GameObjective GetObjective() {
  return GameObjective(Keeper); }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  RemoteRole = ROLE_SimulatedProxy;
  }