// ============================================================================
// JBTagPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Replicated information for a single player.
// ============================================================================


class JBTagPlayer extends JBTag
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    PlayerReplicationInfo, Arena, ArenaPending, Jail;
  }


// ============================================================================
// Types
// ============================================================================

enum ERestart {

  Restart_Jail,
  Restart_Freedom,
  Restart_Arena,
  };


// ============================================================================
// Variables
// ============================================================================

var private PlayerReplicationInfo PlayerReplicationInfo;

var private ERestart Restart;          // restart location for this player

var private JBInfoArena Arena;         // arena the player is currently in
var private JBInfoArena ArenaRestart;  // arena the player will be restarted in
var private JBInfoArena ArenaPending;  // arena the player is scheduled for
var private JBInfoArena ArenaRequest;  // arena the player has requested
var private float TimeArenaRequest;    // time of the arena request

var private JBInfoJail Jail;           // jail the player is currently in
var private float TimeRelease;         // time of last release from jail

var private float TimeObjectiveGuessed;          // time of last guess
var private Pawn PawnObjectiveGuessed;           // pawn used at last guess
var private GameObjective ObjectiveGuessed;      // last guessed objective
var private array<float> ListDistanceObjective;  // distances to all objectives


// ============================================================================
// Internal
// ============================================================================

var JBTagPlayer nextTag;

static function JBTagPlayer FindFor(PlayerReplicationInfo Keeper) {
  return JBTagPlayer(InternalFindFor(Keeper)); }
static function JBTagPlayer SpawnFor(PlayerReplicationInfo Keeper) {
  return JBTagPlayer(InternalSpawnFor(Keeper)); }

protected simulated function JBTag InternalGetFirst() {
  return JBReplicationInfoGame(GetGameReplicationInfo()).firstTagPlayer; }
protected simulated function InternalSetFirst(JBTag TagFirst) {
  JBReplicationInfoGame(GetGameReplicationInfo()).firstTagPlayer = JBTagPlayer(TagFirst); }
protected simulated function JBTag InternalGetNext() {
  return nextTag; }
protected simulated function InternalSetNext(JBTag TagNext) {
  nextTag = JBTagPlayer(TagNext); }


// ============================================================================
// PostBeginPlay
//
// Sets the PlayerReplicationInfo and starts the timer in a short interval.
// ============================================================================

event PostBeginPlay() {

  PlayerReplicationInfo = PlayerReplicationInfo(Owner);
  SetTimer(0.2, True);
  }


// ============================================================================
// Timer
//
// Updates the Jail property periodically. If the player left jail, awards
// points to the release instigator. If the player entered jail while the
// release is active, prepares the player for release.
// ============================================================================

event Timer() {

  local JBInfoJail firstJail;
  local JBInfoJail JailPrev;

  JailPrev = Jail;
  Jail = None;

  if (Arena == None) {
    firstJail = JBReplicationInfoGame(GetGameReplicationInfo()).firstJail;
    for (Jail = firstJail; Jail != None; Jail = Jail.nextJail)    
      if (Jail.ContainsActor(GetController().Pawn))
        break;
    
         if (JailPrev == None && Jail != None) JailEntered();
    else if (JailPrev != None && Jail == None) JailLeft(JailPrev);
    }
  }


// ============================================================================
// IsFree
//
// Returns whether this player is in freedom at the moment.
// ============================================================================

simulated function bool IsFree() {

  return (Arena == None &&
          Jail  == None);
  }


// ============================================================================
// IsInArena
//
// Returns whether this player is fighting in an arena at the moment.
// ============================================================================

simulated function bool IsInArena() {

  return (Arena != None);
  }


// ============================================================================
// IsInJail
//
// Returns whether this player is in jail at the moment.
// ============================================================================

simulated function bool IsInJail() {

  return (Jail != None);
  }


// ============================================================================
// JailEntered
//
// Automatically called when the player entered the jail. If the jail release
// is open, prepares the player for release. Puts bots on the jail squad.
// ============================================================================

function JailEntered() {

  if (Bot(GetController()) != None)
    JBBotTeam(UnrealTeamInfo(PlayerReplicationInfo.Team).AI).PutOnSquadJail(Bot(GetController()));

  if (Jail.IsReleaseActive(PlayerReplicationInfo.Team))
    JailOpened();
  }


// ============================================================================
// JailLeft
//
// Automatically called when the player left the jail. Resets all arena-related
// information and scores points for the releaser if necessary.
// ============================================================================

function JailLeft(JBInfoJail JailPrev) {

  local Controller ControllerInstigator;
  local JBInfoArena firstArena;
  local JBInfoArena thisArena;

  if (ArenaPending != None)
    ArenaPending.MatchCancel();
  ArenaRequest = None;
  
  firstArena = JBReplicationInfoGame(GetGameReplicationInfo()).firstArena;
  for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
    thisArena.ExcludeRemove(GetController());

  if (JailPrev.GetReleaseTime(PlayerReplicationInfo.Team) != TimeRelease) {
    ControllerInstigator = JailPrev.GetReleaseInstigator(PlayerReplicationInfo.Team);
    if (ControllerInstigator != None)
      Jailbreak(Level.Game).ScorePlayer(ControllerInstigator, 'Release');

    TimeRelease = JailPrev.GetReleaseTime(PlayerReplicationInfo.Team);
    }

  if (Bot(GetController()) != None && JBBotSquadJail(Bot(GetController()).Squad) != None)
    UnrealTeamInfo(PlayerReplicationInfo.Team).AI.SetBotOrders(Bot(GetController()), None);
  }


// ============================================================================
// JailOpened
//
// Automatically called when the jail opens while this player is in jail.
// Gives bots new orders to make them leave the jail.
// ============================================================================

function JailOpened() {

  if (Bot(GetController()) != None)
    UnrealTeamInfo(PlayerReplicationInfo.Team).AI.SetBotOrders(Bot(GetController()), None);
  }


// ============================================================================
// JailClosed
//
// Automatically called when the jail closes while this player is in jail.
// Sets bots back on the jail squad.
// ============================================================================

function JailClosed() {

  if (Bot(GetController()) != None)
    JBBotTeam(UnrealTeamInfo(PlayerReplicationInfo.Team).AI).PutOnSquadJail(Bot(GetController()));
  }


// ============================================================================
// RestartPlayer
//
// Restarts the player, making sure everything is properly cleaned up before
// doing so.
// ============================================================================

private function RestartPlayer() {

  if (GetController().Pawn != None)
    GetController().Pawn.Destroy();
  
  Level.Game.RestartPlayer(GetController());
  }


// ============================================================================
// RestartFreedom
//
// Restarts this player in freedom.
// ============================================================================

function RestartFreedom() {

  Restart = Restart_Freedom;
  
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();

  Restart = Restart_Jail;
  }


// ============================================================================
// RestartJail
//
// Restarts this player in jail.
// ============================================================================

function RestartJail() {

  Restart = Restart_Jail;
  
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();
  }


// ============================================================================
// RestartArena
//
// Restarts this player in the given arena (at once, not delayed).
// ============================================================================

function RestartArena(JBInfoArena NewArenaRestart) {

  Restart = Restart_Arena;
  
  ArenaRestart = NewArenaRestart;
  ArenaPending = None;
  ArenaRequest = None;
  
  RestartPlayer();
  
  Arena = ArenaRestart;
  ArenaRestart = None;
  
  Restart = Restart_Jail;
  }


// ============================================================================
// SetArenaPending
//
// Sets ArenaPending if the player can actually fight in the given arena.
// ============================================================================

function SetArenaPending(JBInfoArena NewArenaPending) {

  if (NewArenaPending == None ||
      NewArenaPending.CanFight(GetController()))
    ArenaPending = NewArenaPending;
  }


// ============================================================================
// SetArenaRequest
//
// Sets ArenaRequest and TimeArenaRequest if the player can actually fight in
// the given arena.
// ============================================================================

function SetArenaRequest(JBInfoArena NewArenaRequest) {

  if (NewArenaRequest != None) {
    if (ArenaPending != None)
      return;
    if (!NewArenaRequest.CanFight(GetController()))
      return;
    }

  ArenaRequest = NewArenaRequest;
  TimeArenaRequest = Level.TimeSeconds;
  }


// ============================================================================
// GuessObjective
//
// Takes a guess which objective this player is currently attacking or
// defending based on the players location and recent movement in relation to
// the available objectives. All calls within a three-second interval will
// yield the same result; then the function evaluates its guess again.
// ============================================================================

function GameObjective GuessObjective() {

  local int iObjective;
  local float Distance;
  local float DistanceApproached;
  local float DistanceApproachedMax;
  local float DistanceClosest;
  local float DistanceTravelledMax;
  local GameObjective thisObjective;
  local GameObjective ObjectiveApproachedMax;
  local GameObjective ObjectiveClosest;

  if (GetController().Pawn == None)
    return None;

  if (TimeObjectiveGuessed + 3.0 > Level.TimeSeconds &&
      GetController().Pawn == PawnObjectiveGuessed)
    return ObjectiveGuessed;
  
  if (GetController().Pawn != PawnObjectiveGuessed)
    ListDistanceObjective.Length = 0;  // clear list after respawn
  PawnObjectiveGuessed = GetController().Pawn;

  for (thisObjective = UnrealTeamInfo(PlayerReplicationInfo.Team).AI.Objectives;
       thisObjective != None;
       thisObjective = thisObjective.NextObjective) {

    Distance = Class'JBBotTeam'.Static.CalcDistance(GetController(), thisObjective);
    
    if (ObjectiveClosest == None || Distance < DistanceClosest) {
      ObjectiveClosest = thisObjective;
      DistanceClosest = Distance;
      }
    
    // assumes that number and order of objectives never change
    
    if (iObjective < ListDistanceObjective.Length) {
      DistanceApproached = ListDistanceObjective[iObjective] - Distance;
      if (ObjectiveApproachedMax == None || DistanceApproached > DistanceApproachedMax) {
        ObjectiveApproachedMax = thisObjective;
        DistanceApproachedMax = DistanceApproached;
        }
      }
    
    ListDistanceObjective[iObjective] = Distance;
    iObjective++;
    }
  
  DistanceTravelledMax = GetController().Pawn.GroundSpeed * (Level.TimeSeconds - TimeObjectiveGuessed);
  
  if (DistanceApproachedMax > DistanceTravelledMax * 0.3)
    ObjectiveGuessed = ObjectiveApproachedMax;  // moving towards objective
  else
    ObjectiveGuessed = ObjectiveClosest;  // located in vicinity of objective
  
  TimeObjectiveGuessed = Level.TimeSeconds;
  return ObjectiveGuessed;  
  }


// ============================================================================
// Accessors
// ============================================================================

simulated function PlayerReplicationInfo GetPlayerReplicationInfo() {
  return PlayerReplicationInfo; }
simulated function Controller GetController() {
  return Controller(PlayerReplicationInfo.Owner); }
simulated function TeamInfo GetTeam() {
  return PlayerReplicationInfo.Team; }

function ERestart GetRestart() {
  return Restart; }
function JBInfoArena GetArenaRestart() {
  return ArenaRestart; }

simulated function JBInfoJail GetJail() {
  return Jail; }
simulated function JBInfoArena GetArena() {
  return Arena; }

simulated function JBInfoArena GetArenaPending() {
  return ArenaPending; }

function JBInfoArena GetArenaRequest() {
  return ArenaRequest; }
function float GetArenaRequestTime() {
  return TimeArenaRequest; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  Restart = Restart_Jail;

  RemoteRole = ROLE_SimulatedProxy;
  }
