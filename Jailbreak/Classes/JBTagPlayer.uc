// ============================================================================
// JBTagPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagPlayer.uc,v 1.16 2003/01/26 13:44:20 mychaeel Exp $
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


struct TInfoLocation {
  
  var NavigationPoint NavigationPoint;
  var float Probability;
  };


// ============================================================================
// Variables
// ============================================================================

var name OrderNameFixed;               // bot should stick to these orders

var private PlayerReplicationInfo PlayerReplicationInfo;

var private ERestart Restart;          // restart location for this player

var private JBInfoArena Arena;         // arena the player is currently in
var private JBInfoArena ArenaRestart;  // arena the player will be restarted in
var private JBInfoArena ArenaPending;  // arena the player is scheduled for
var private JBInfoArena ArenaRequest;  // arena the player has requested
var private float TimeArenaRequest;    // time of the arena request

var private JBInfoJail Jail;           // jail the player is currently in
var private float TimeRelease;         // time of last release from jail

var private float TimeInfoLocation;                 // last known location time
var private array<TInfoLocation> ListInfoLocation;  // location probabilities

var private float TimeObjectiveGuessed;             // time of last guess
var private Pawn PawnObjectiveGuessed;              // pawn used at last guess
var private GameObjective ObjectiveGuessed;         // last guessed objective
var private array<float> ListDistanceObjective;     // distances to objectives


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

  if (Arena == None && GetController().Pawn != None) {
    firstJail = JBReplicationInfoGame(GetGameReplicationInfo()).firstJail;
    for (Jail = firstJail; Jail != None; Jail = Jail.nextJail)    
      if (Jail.ContainsActor(GetController().Pawn))
        break;
    }
    
       if (JailPrev == None && Jail != None) NotifyJailEntered();
  else if (JailPrev != None && Jail == None) NotifyJailLeft(JailPrev);
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
// NotifyJailEntered
//
// Automatically called when the player entered the jail from an arena or from
// freedom. Notifies the jail of that. Puts bots on the jail squad.
// ============================================================================

function NotifyJailEntered() {

  if (Bot(GetController()) != None)
    JBBotTeam(UnrealTeamInfo(PlayerReplicationInfo.Team).AI).PutOnSquadJail(Bot(GetController()));

  Jail.NotifyJailEntered(Self);
  }


// ============================================================================
// NotifyJailLeft
//
// Called when the player left the jail for an arena or for freedom. Resets
// all arena-related information and scores points for the releaser.
// ============================================================================

function NotifyJailLeft(JBInfoJail JailPrev) {

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

  JailPrev.NotifyJailLeft(Self);

  JBBotTeam(TeamGame(Level.Game).Teams[0].AI).NotifyReleasePlayer(JailPrev.Tag, GetController());
  JBBotTeam(TeamGame(Level.Game).Teams[1].AI).NotifyReleasePlayer(JailPrev.Tag, GetController());
  }


// ============================================================================
// NotifyJailOpening
//
// Called when the doors of the jail this player is in start opening.
// ============================================================================

function NotifyJailOpening() {

  // this space is intentionally left blank
  }


// ============================================================================
// NotifyJailOpened
//
// Called when the doors of the jail this player is in have fully opened.
// Gives bots new orders to make them leave the jail.
// ============================================================================

function NotifyJailOpened() {

  if (Bot(GetController()) != None)
    JBBotTeam(UnrealTeamInfo(PlayerReplicationInfo.Team).AI).ResumeBotOrders(Bot(GetController()));
  }


// ============================================================================
// NotifyJailClosed
//
// Called when the jail closes while this player is in jail. Sets bots back on
// the jail squad.
// ============================================================================

function NotifyJailClosed() {

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

  local xPawn PawnPlayer;

  PawnPlayer = xPawn(GetController().Pawn);

  if (PawnPlayer != None) {
    if (PawnPlayer.CurrentCombo != None) {
      PawnPlayer.CurrentCombo.Destroy();
      PawnPlayer.Controller.Adrenaline = 0;
      }

    if (PawnPlayer.UDamageTimer != None) {
      PawnPlayer.UDamageTimer.Destroy();
      PawnPlayer.DisableUDamage();
      }

    PawnPlayer.Destroy();
    }
  
  Level.Game.RestartPlayer(GetController());
  }


// ============================================================================
// RestartFreedom
//
// Restarts this player in freedom.
// ============================================================================

function RestartFreedom() {

  local JBInfoJail JailPrev;

  Restart = Restart_Freedom;
  
  ArenaRestart = None;
  ArenaPending = None;
  ArenaRequest = None;
  
  JailPrev = Jail;       // would be picked up automatically by Timer too,
  Jail = None;           // but not before the player gets a new Pawn,
  if (JailPrev != None)  // so handle the release from jail here already
    NotifyJailLeft(JailPrev);
  
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
// RecordLocation
//
// Records a known location of this player. Later calls of GuessLocation will
// use this location as the player's assumed starting point.
// ============================================================================

function RecordLocation(optional NavigationPoint NavigationPoint) {

  if (NavigationPoint == None) {
    ListInfoLocation.Length = 0;
    }
  
  else {
    ListInfoLocation.Length = 1;
    ListInfoLocation[0].NavigationPoint = NavigationPoint;
    ListInfoLocation[0].Probability = 1.0;
    }
  
  TimeInfoLocation = Level.TimeSeconds;
  }


// ============================================================================
// RecordLocationList
//
// Records a list of possible location this player could be at with equal
// probabilities. If no argument is given, resets the list.
// ============================================================================

function RecordLocationList(optional array<NavigationPoint> ListNavigationPoint) {

  local int iNavigationPoint;

  ListInfoLocation.Length = ListNavigationPoint.Length;
  for (iNavigationPoint = 0; iNavigationPoint < ListNavigationPoint.Length; iNavigationPoint++) {
    ListInfoLocation[iNavigationPoint].NavigationPoint = ListNavigationPoint[iNavigationPoint];
    ListInfoLocation[iNavigationPoint].Probability = 1.0 / ListNavigationPoint.Length;
    }

  TimeInfoLocation = Level.TimeSeconds;
  }


// ============================================================================
// GuessLocation
//
// Takes a guess which location of a given set of possible location this
// player is currently at. Takes into account the previously recorded possible
// locations of this player and their respective probabilities. Updates the
// list of possible locations.
// ============================================================================

function NavigationPoint GuessLocation(array<NavigationPoint> ListNavigationPoint) {

  local int iNavigationPointStart;
  local int iNavigationPointTarget;
  local float Distance;
  local float DistanceMax;
  local float ProbabilityPath;
  local float ProbabilitySelected;
  local float ProbabilityTotal;
  local array<TInfoLocation> ListInfoLocationTarget;

  if (GetController().Pawn == None)
    return None;
  
  if (TimeInfoLocation != Level.TimeSeconds) {
    DistanceMax = GetController().Pawn.GroundSpeed * (Level.TimeSeconds - TimeInfoLocation) * 1.1;
    
    for (iNavigationPointTarget = 0; iNavigationPointTarget < ListNavigationPoint.Length; iNavigationPointTarget++) {
      ListInfoLocationTarget.Insert(iNavigationPointTarget, 1);
      ListInfoLocationTarget[iNavigationPointTarget].NavigationPoint = ListNavigationPoint[iNavigationPointTarget];
      
      for (iNavigationPointStart = 0; iNavigationPointStart < ListInfoLocation.Length; iNavigationPointStart++) {
        Distance = Class'JBTagNavigation'.Static.CalcDistance(
          ListInfoLocation[iNavigationPointStart].NavigationPoint,
          ListNavigationPoint[iNavigationPointTarget]);
        ProbabilityPath = Exp(-Square(2.0 * (Distance / DistanceMax - 1.0))) * (1.0 - Distance / DistanceMax);
        if (ProbabilityPath > 0.0)
          ListInfoLocationTarget[iNavigationPointTarget].Probability +=
            ProbabilityPath * ListInfoLocation[iNavigationPointStart].Probability;
        }
  
      ProbabilityTotal += ListInfoLocationTarget[iNavigationPointTarget].Probability;
      }
    
    if (ProbabilityTotal > 0.0) {
      for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++)
        ListInfoLocationTarget[iNavigationPointTarget].Probability /= ProbabilityTotal;  // normalize
      
      ListInfoLocation.Length = ListInfoLocationTarget.Length;
      for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++)
        ListInfoLocation[iNavigationPointTarget] = ListInfoLocationTarget[iNavigationPointTarget];

      TimeInfoLocation = Level.TimeSeconds;
      }
    
    else {
      RecordLocationList(ListNavigationPoint);  // unknown, could be anywhere
      }
    }

  ProbabilitySelected = FRand();

  for (iNavigationPointTarget = 0; iNavigationPointTarget < ListInfoLocationTarget.Length; iNavigationPointTarget++) {
    ProbabilitySelected -= ListInfoLocation[iNavigationPointTarget].Probability;
    if (ProbabilitySelected < 0.0)
      return ListInfoLocation[iNavigationPointTarget].NavigationPoint;
    }
  
  return None;  // should never happen
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
  local float DistanceClosestPrev;
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
      DistanceClosestPrev = DistanceClosest;
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
  
  if (DistanceApproachedMax > DistanceTravelledMax * 0.8)
    ObjectiveGuessed = ObjectiveApproachedMax;  // moving towards objective
  else
    if (DistanceClosestPrev == 0.0 ||
        DistanceClosestPrev > DistanceClosest * 2.0)
      ObjectiveGuessed = ObjectiveClosest;  // located in vicinity of objective
    else
      ObjectiveGuessed = None;  // located between objectives, freelancing
  
  TimeObjectiveGuessed = Level.TimeSeconds;
  return ObjectiveGuessed;  
  }


// ============================================================================
// GetRestart
//
// Returns where this player ought to be restarted next. The following names
// can be returned:
//
//   Restart_Freedom   Restart player in their own base in freedom.
//   Restart_Jail      Restart player in jail.
//   Restart_Arena     Restart player in the arena specified in ArenaRestart.
//
// ============================================================================

function name GetRestart() {

  if (GetController().PreviousPawnClass == None)
    return 'Restart_Freedom';  // first-time world spawn

  return GetEnum(Enum'ERestart', Restart);
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
