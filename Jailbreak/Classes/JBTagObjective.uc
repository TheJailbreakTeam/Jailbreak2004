// ============================================================================
// JBTagObjective
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
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
    Objective, nPlayersReleasable;
  }


// ============================================================================
// Variables
// ============================================================================

var float ScaleDot;  // used to pulse dot in compass

var private GameObjective Objective;  // replicated associated objective

var private float TimeCountPlayersReleasable;  // time of last update
var private int nPlayersReleasable;            // number of releasable players


// ============================================================================
// Internal
// ============================================================================

var JBTagObjective nextTag;

static function JBTagObjective FindFor(GameObjective Keeper) {
  return JBTagObjective(InternalFindFor(Keeper)); }
static function JBTagObjective SpawnFor(GameObjective Keeper) {
  return JBTagObjective(InternalSpawnFor(Keeper)); }

protected simulated function JBTag InternalGetFirst() {
  return JBReplicationInfoGame(GetGameReplicationInfo()).firstTagObjective; }
protected simulated function InternalSetFirst(JBTag TagFirst) {
  JBReplicationInfoGame(GetGameReplicationInfo()).firstTagObjective = JBTagObjective(TagFirst); }
protected simulated function JBTag InternalGetNext() {
  return nextTag; }
protected simulated function InternalSetNext(JBTag TagNext) {
  nextTag = JBTagObjective(TagNext); }


// ============================================================================
// PostBeginPlay
//
// Replicates a reference to the objective and starts the timer.
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

  local JBInfoJail JailPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local TeamInfo TeamPlayer;
  
  if (Role < ROLE_Authority || bCached || TimeCountPlayersReleasable == Level.TimeSeconds)
    return nPlayersReleasable;
  
  nPlayersReleasable = 0;

  firstTagPlayer = JBReplicationInfoGame(GetGameReplicationInfo()).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    TeamPlayer = thisTagPlayer.GetTeam();

    if (TeamPlayer.TeamIndex != GetObjective().DefenderTeamIndex) {
      JailPlayer = thisTagPlayer.GetJail();

      if (JailPlayer != None &&
          JailPlayer.Tag == GetObjective().Event &&
          JailPlayer.CanRelease(TeamPlayer))
        nPlayersReleasable++;
      }
    }

  TimeCountPlayersReleasable = Level.TimeSeconds;
  return nPlayersReleasable;
  }


// ============================================================================
// GetObjective
//
// Returns a reference to the objective associated with this item.
// ============================================================================

simulated function GameObjective GetObjective() {

  return Objective;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  RemoteRole = ROLE_SimulatedProxy;
  }