// ============================================================================
// JBTagClient
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Attached to every PlayerController and used for exec function replication.
// Only accessible via a given PlayerController object; not chained and not
// replicated to anyone else than the owning player.
// ============================================================================


class JBTagClient extends JBTag
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role < ROLE_Authority)
    ExecTeamTactics,
    ExecArenaCam,
    ExecViewTeam,
    ExecViewSelf,
    ServerSynchronizeTime,
    ServerSwitchToPrevCamera,
    ServerSwitchToNextCamera;

  reliable if (Role == ROLE_Authority)
    ClientSynchronizeTime;
}


// ============================================================================
// Variables
// ============================================================================

var private bool bTimeSynchronized;     // server replied to sync request
var private float TimeSynchronization;  // client time at sync request
var private float TimeOffsetServer;     // offset from client to server time

var private float TimeDeltaAccu;        // accumulated time difference
var private float TimeLevelPrev;        // previous level time
var private float TimeWorldPrev;        // previous world time


// ============================================================================
// Internal
// ============================================================================

static function JBTagClient FindFor(PlayerController Keeper) {
  return JBTagClient(InternalFindFor(Keeper)); }
static function JBTagClient SpawnFor(PlayerController Keeper) {
  return JBTagClient(InternalSpawnFor(Keeper)); }


// ============================================================================
// PostBeginPlay
//
// Starts the timer which is used to resynchronize client to server time
// whenever a tick took longer in real time than in level time.
// ============================================================================

simulated event PostBeginPlay()
{
  if (Role < ROLE_Authority)
    SetTimer(2.0, True);
}


// ============================================================================
// SetInitialState
//
// Disables the Tick event server-side.
// ============================================================================

simulated event SetInitialState()
{
  Super.SetInitialState();

  if (Level.NetMode == NM_DedicatedServer)
    Disable('Tick');
}


// ============================================================================
// Tick
//
// Adds the JBInteractionKeys interaction client-side as soon as the keeper
// PlayerController has a valid Player reference.
// ============================================================================

simulated function Tick(float TimeDelta)
{
  local PlayerController PlayerControllerLocal;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (PlayerControllerLocal        == None ||
      PlayerControllerLocal.Player == None)
    return;

  if (PlayerControllerLocal == Keeper)
    PlayerControllerLocal.Player.InteractionMaster.AddInteraction("Jailbreak.JBInteractionKeys", PlayerControllerLocal.Player);

  Disable('Tick');
}


// ============================================================================
// Timer
//
// Checks whether considerably more time passed in real time than in level
// time since the last check. If so, resynchronizes client to server time.
// ============================================================================

simulated event Timer()
{
  local float TimeLevelDelta;
  local float TimeWorld;
  local float TimeWorldDelta;

  if (!bTimeSynchronized)
    return;

  TimeWorld = Level.Hour * 60.0 * 60.0
            + Level.Minute      * 60.0
            + Level.Second
            + Level.Millisecond / 1000.0;

  if (TimeLevelPrev > 0.0) {
    TimeLevelDelta = (Level.TimeSeconds - TimeLevelPrev) / Level.TimeDilation;
    TimeWorldDelta = TimeWorld - TimeWorldPrev;
    if (TimeWorldDelta < 0.0)
      TimeWorldDelta += 24.0 * 60.0 * 60.0;

    TimeDeltaAccu += TimeWorldDelta - TimeLevelDelta;
    if (TimeDeltaAccu > 0.2)
      SynchronizeTime();
  }

  TimeLevelPrev = Level.TimeSeconds;
  TimeWorldPrev = TimeWorld;
}


// ============================================================================
// ExecTeamTactics
//
// Sets team tactics. If no team is specified, sets tactics for this player's
// team; otherwise for the given team. Only administrators can change tactics
// for the enemy team.
// ============================================================================

function ExecTeamTactics(name Tactics, optional TeamInfo Team)
{
  if (Team == None)
    Team = GetPlayerReplicationInfo().Team;

  if (Team != None &&
      (GetPlayerReplicationInfo().bAdmin ||
       GetPlayerReplicationInfo().Team == Team))
    JBBotTeam(UnrealTeamInfo(Team).AI).SetTactics(Tactics);
}


// ============================================================================
// ExecArenaCam
//
// Activates the next viable arena cam, or deactivates arena cams for this
// player if the player was viewing the last available one already.
// ============================================================================

function ExecArenaCam()
{
  local bool bFoundArenaCurrent;
  local JBCamera CameraCurrent;
  local JBInfoArena ArenaCurrent;
  local JBInfoArena firstArena;
  local JBInfoArena thisArena;
  local JBTagPlayer TagPlayerOwner;

  TagPlayerOwner = Class'JBTagPlayer'.Static.FindFor(PlayerController(Owner).PlayerReplicationInfo);
  if (TagPlayerOwner            != None &&
      TagPlayerOwner.GetArena() != None)
    return;

  firstArena = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstArena;

  CameraCurrent = JBCamera(PlayerController(Keeper).ViewTarget);
  if (CameraCurrent != None)
    for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
      if (thisArena.ContainsActor(CameraCurrent))
        ArenaCurrent = thisArena;

  if (ArenaCurrent == None)
    bFoundArenaCurrent = True;

  for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
    if (thisArena == ArenaCurrent)
      bFoundArenaCurrent = True;
    else if (thisArena.IsInState('MatchRunning') && bFoundArenaCurrent)
      break;

  if (thisArena != None)
    thisArena.ActivateCameraFor(PlayerController(Keeper));
  else if (CameraCurrent != None && ArenaCurrent != None)
    CameraCurrent.DeactivateFor(PlayerController(Keeper));
}


// ============================================================================
// ExecViewTeam
//
// Switches to the next teammate's viewpoint (or through all players for
// admins and spectators), optionally choosing only from the given subset of
// players (jailed, free or all).
// ============================================================================

function ExecViewTeam(optional name Whom)
{
  local Pawn PawnViewTarget;
  local TeamInfo Team;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  if (!Level.Game.IsInState('MatchInProgress'))
    return;

  PawnViewTarget = Pawn(PlayerController(Keeper).ViewTarget);
  if (PawnViewTarget == None ||
      PawnViewTarget == Controller(Keeper).Pawn ||
      PawnViewTarget.PlayerReplicationInfo == None)
         firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    else firstTagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnViewTarget.PlayerReplicationInfo).nextTag;

  if (!Controller(Keeper).PlayerReplicationInfo.bAdmin)
    Team = Controller(Keeper).PlayerReplicationInfo.Team;

  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetPawn()       != None &&
        thisTagPlayer.GetController() != Keeper)
      if (Whom == 'Any'                                 ||
         (Whom == 'Jailed' && thisTagPlayer.IsInJail()) ||
         (Whom == 'Free'   && thisTagPlayer.IsFree()))
        if (Team == None ||
            Team == thisTagPlayer.GetTeam())
          break;

  if (thisTagPlayer == None) {
    Jailbreak(Level.Game).ResetViewTarget(PlayerController(Keeper));
  }
  else {
    PlayerController(Keeper).SetViewTarget(thisTagPlayer.GetPawn());
    PlayerController(Keeper).bBehindView = True;
    PlayerController(Keeper).ViewTarget.BecomeViewTarget();
    
    PlayerController(Keeper).ClientSetViewTarget(PlayerController(Keeper).ViewTarget);
    PlayerController(Keeper).ClientSetBehindView(PlayerController(Keeper).bBehindView);
  }
}


// ============================================================================
// ExecViewSelf
//
// Resets the player's view point to normal first-person view. Disabled when
// viewing an execution sequence.
// ============================================================================

function ExecViewSelf()
{
  if (Level.Game.IsInState('MatchInProgress') || JBCamera(PlayerController(Keeper).ViewTarget) == None)
    Jailbreak(Level.Game).ResetViewTarget(PlayerController(Keeper));
}


// ============================================================================
// ServerSwitchToPrevCamera
// ServerSwitchToNextCamera
//
// Switches the player to the previous or next camera. Used for replication.
// ============================================================================

function ServerSwitchToPrevCamera(JBCamera Camera, optional bool bManual) { Camera.SwitchToPrev(PlayerController(Keeper), bManual); }
function ServerSwitchToNextCamera(JBCamera Camera, optional bool bManual) { Camera.SwitchToNext(PlayerController(Keeper), bManual); }


// ============================================================================
// SynchronizeTime
//
// Synchronizes the client with the server's idea of the current game time.
// The synchronization happens asynchronously; use the IsTimeSynchronized
// function to find out whether it has happened already.
// ============================================================================

simulated function SynchronizeTime()
{
  if (TimeSynchronization != 0.0)
    return;

  TimeSynchronization = Level.TimeSeconds;
  bTimeSynchronized = False;

  ServerSynchronizeTime();
}


// ============================================================================
// IsTimeSynchronized
//
// Returns whether the client time has already been synchronized with the
// server time.
// ============================================================================

simulated function bool IsTimeSynchronized()
{
  return bTimeSynchronized;
}


// ============================================================================
// ServerSynchronizeTime
//
// Called client-side and replicated to the server when a client requests time
// synchronization. Replies by calling ClientSynchronizeTime with the server's
// current notion of the game time.
// ============================================================================

private function ServerSynchronizeTime()
{
  ClientSynchronizeTime(Level.TimeSeconds);
}


// ============================================================================
// ClientSynchronizeTime
//
// Called server-side and replicated to the client in reply to a time
// synchronization request. Calculates a time offset between client and server
// and stores it for further requests by calling GetServerTime.
// ============================================================================

private simulated function ClientSynchronizeTime(float TimeServer)
{
  local float TimeRoundTrip;

  TimeRoundTrip = Level.TimeSeconds - TimeSynchronization;
  TimeOffsetServer = TimeServer - Level.TimeSeconds + TimeRoundTrip / 2;

  TimeSynchronization = 0.0;
  bTimeSynchronized = True;

  Log("Synchronized time with server:"
      @ "Local="     @ Level.TimeSeconds           $  "s"
      @ "Offset="    @ TimeOffsetServer            $  "s"
      @ "RoundTrip=" @ int(TimeRoundTrip * 1000.0) $ "ms");

  TimeDeltaAccu = 0.0;
}


// ============================================================================
// GetServerTime
//
// After the client's time has been synchronized with the server, returns the
// clients idea of the server's current time in game.
// ============================================================================

simulated function float GetServerTime()
{
  return Level.TimeSeconds + TimeOffsetServer;
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

defaultproperties
{
  RemoteRole = ROLE_SimulatedProxy;
  bAlwaysRelevant = False;
  bOnlyRelevantToOwner = True;
}