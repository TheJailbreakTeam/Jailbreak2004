// ============================================================================
// Jailbreak
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: Jailbreak.uc,v 1.11 2002/11/24 20:54:28 mychaeel Exp $
//
// Jailbreak game type.
// ============================================================================


class Jailbreak extends TeamGame
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var class<LocalMessage> ClassLocalMessage;

var private JBCamera CameraExecution;    // camera for execution sequence

var private float TimeExecution;         // time when execution starts
var private float TimeRestart;           // time when next round starts

var private array<name> ListEventFired;  // events fired in this tick
var private float TimeEventFired;        // update time of event list


// ============================================================================
// InitGame
//
// Initializes the game.
// ============================================================================

event InitGame(string Options, out string Error) {

  Super.InitGame(Options, Error);
  
  bForceRespawn = True;
  }


// ============================================================================
// Login
//
// Gives every player a JBReplicationInfoPlayer actor.
// ============================================================================

event PlayerController Login(string Portal, string Options, out string Error) {

  local PlayerController PlayerLogin;
  
  PlayerLogin = Super.Login(Portal, Options, Error);
  if (PlayerLogin != None)
    Spawn(Class'JBReplicationInfoPlayer', PlayerLogin);
  
  return PlayerLogin;
  }


// ============================================================================
// SpawnBot
//
// Gives every new bot a JBReplicationInfoPlayer actor.
// ============================================================================

function Bot SpawnBot(optional string NameBot) {

  local Bot BotSpawned;
  
  BotSpawned = Super.SpawnBot(NameBot);
  if (BotSpawned != None)
    Spawn(Class'JBReplicationInfoPlayer', BotSpawned);
  
  return BotSpawned;
  }


// ============================================================================
// Logout
//
// Destroys the JBReplicationInfoPlayer actor for the given player or bot if
// one exists.
// ============================================================================

function Logout(Controller ControllerExiting) {

  local JBReplicationInfoPlayer InfoPlayer;
  
  InfoPlayer = Class'JBReplicationInfoPlayer'.Static.FindFor(ControllerExiting.PlayerReplicationInfo);
  if (InfoPlayer != None)
    InfoPlayer.Destroy();

  Super.Logout(ControllerExiting);
  }


// ============================================================================
// RatePlayerStart
//
// Returns a negative value for all starts that are inappropriate for the
// given player's scheduled respawn area.
// ============================================================================

function float RatePlayerStart(NavigationPoint NavigationPoint, byte Team, Controller Controller) {

  local byte Restart;
  local JBInfoArena Arena;
  local JBReplicationInfoPlayer InfoPlayer;

  if (Controller != None && Controller.PreviousPawnClass != None)  // not first spawn
    InfoPlayer = Class'JBReplicationInfoPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);

  if (InfoPlayer == None)
    Restart = 1;  // ERestart.Restart_Freedom
  else
    Restart = int(InfoPlayer.GetRestart());  // cannot cast to byte
  
  switch (Restart) {
    case 0:  // ERestart.Restart_Jail
      if (!ContainsActorJail(NavigationPoint))
        return -20000000;
      break;
    
    case 1:  // ERestart.Restart_Freedom
      if (ContainsActorJail (NavigationPoint) ||
          ContainsActorArena(NavigationPoint))
        return -20000000;
      break;

    case 2:  // ERestart.Restart_Arena
      InfoPlayer = Class'JBReplicationInfoPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
      if (!ContainsActorArena(NavigationPoint, Arena) || Arena != InfoPlayer.GetArenaRestart())
        return -20000000;
      break;
    }

  return Super.RatePlayerStart(NavigationPoint, Team, Controller);
  }


// ============================================================================
// ScoreKill
//
// Translates kills into ScoreEvent calls according to Jailbreak rules.
// ============================================================================

function ScoreKill(Controller ControllerKiller, Controller ControllerVictim) {

  local int iRelease;
  local float DistanceRelease;
  local float DistanceReleaseMin;
  local JBReplicationInfoPlayer InfoPlayerVictim;
  local JBReplicationInfoTeam InfoTeamVictim;

  InfoPlayerVictim = Class'JBReplicationInfoPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);
  if (InfoPlayerVictim != None && InfoPlayerVictim.IsInJail())
    return;

  if (ControllerKiller == None ||
      ControllerKiller == ControllerVictim)
    ScoreEvent(ControllerVictim, 'Suicide');
  
  else if (SameTeam(ControllerKiller, ControllerVictim))
    ScoreEvent(ControllerKiller, 'Teamkill');

  else {
    DistanceReleaseMin = -1.0;
    InfoTeamVictim = JBReplicationInfoTeam(ControllerVictim.PlayerReplicationInfo.Team);
  
    for (iRelease = 0; iRelease < InfoTeamVictim.ListRelease.Length; iRelease++) {
      DistanceRelease = VSize(InfoTeamVictim.ListRelease[iRelease].Location - ControllerVictim.Pawn.Location);
      if (DistanceReleaseMin < 0.0 ||
          DistanceReleaseMin > DistanceRelease)
        DistanceReleaseMin = DistanceRelease;
      }
  
    if (DistanceRelease < 1024.0)
      ScoreEvent(ControllerKiller, 'Defense');
    else
      ScoreEvent(ControllerKiller, 'Attack');
    }
  }


// ============================================================================
// ScoreEvent
//
// Adds points to the given player's score according to the given game event.
// ============================================================================

function ScoreEvent(Controller Controller, name Event) {

  switch (Event) {
    case 'Suicide':   Controller.PlayerReplicationInfo.Score -= 1;  break;
    case 'Teamkill':  Controller.PlayerReplicationInfo.Score -= 1;  break;
    case 'Attack':    Controller.PlayerReplicationInfo.Score += 1;  break;
    case 'Defense':   Controller.PlayerReplicationInfo.Score += 2;  break;
    case 'Release':   Controller.PlayerReplicationInfo.Score += 1;  break;
    case 'Capture':   Controller.PlayerReplicationInfo.Score += 1;  break;
    }
  }


// ============================================================================
// CanFireEvent
//
// Checks whether the given event has been fired already within this tick and
// returns True if not, False otherwise. Thus makes sure that certain events
// are only fired once per tick.
// ============================================================================

function bool CanFireEvent(name EventFire, optional bool bFire) {

  local int iEventFired;
  
  if (TimeEventFired < Level.TimeSeconds)
    ListEventFired.Length = 0;
  
  for (iEventFired = 0; iEventFired < ListEventFired.Length; iEventFired++)
    if (ListEventFired[iEventFired] == EventFire)
      return False;
  
  if (bFire) {
    ListEventFired[ListEventFired.Length] = EventFire;
    TimeEventFired = Level.TimeSeconds;
    }
  
  return True;
  }


// ============================================================================
// ContainsActorJail
//
// Iterates over all jails and returns whether one of them contains the given
// actor (and optionally which of them).
// ============================================================================

function bool ContainsActorJail(Actor Actor, optional out JBInfoJail Jail) {

  local int iInfoJail;
  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(GameReplicationInfo);
  
  for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++) {
    Jail = InfoGame.ListInfoJail[iInfoJail];
    if (Jail.ContainsActor(Actor))
      return True;
    }

  Jail = None;
  return False;
  }


// ============================================================================
// ContainsActorArena
//
// Iterates over all arenas and returns whether one of them contains the given
// actor (and optionally which of them).
// ============================================================================

function bool ContainsActorArena(Actor Actor, optional out JBInfoArena Arena) {

  local int iInfoArena;
  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(GameReplicationInfo);
  
  for (iInfoArena = 0; iInfoArena < InfoGame.ListInfoArena.Length; iInfoArena++) {
    Arena = InfoGame.ListInfoArena[iInfoArena];
    if (Arena.ContainsActor(Actor))
      return True;
    }

  Arena = None;
  return False;
  }


// ============================================================================
// CountPlayersJailed
//
// Forwarded to CountPlayersJailed in JBReplicationInfoTeam.
// ============================================================================

function int CountPlayersJailed(byte Team) {

  return JBReplicationInfoTeam(Teams[Team]).CountPlayersJailed();
  }


// ============================================================================
// CountPlayersTotal
//
// Forwarded to CountPlayersTotal in JBReplicationInfoTeam.
// ============================================================================

function int CountPlayersTotal(byte Team) {

  return JBReplicationInfoTeam(Teams[Team]).CountPlayersTotal();
  }


// ============================================================================
// IsCaptured
//
// Returns whether the given team has been captured.
// ============================================================================

function bool IsCaptured(byte Team) {

  if (CountPlayersTotal(Team) == 0)
    return False;

  return CountPlayersJailed(Team) == CountPlayersTotal(Team);
  }


// ============================================================================
// RateCameraExecution
//
// Rates the given camera in terms of a good view on an execution sequence.
// The higher the returned value, the better.
// ============================================================================

function int RateCameraExecution(JBCamera CameraExecution) {

  local int iInfoJail;
  local int nPlayersJailed;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(GameReplicationInfo);
  
  for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
    if (InfoGame.ListInfoJail[iInfoJail].Event == CameraExecution.Tag)
      nPlayersJailed += InfoGame.ListInfoJail[iInfoJail].CountPlayersTotal();
  
  return nPlayersJailed;
  }


// ============================================================================
// FindCameraExecution
//
// Finds the execution camera with the best view on the execution sequence.
// ============================================================================

function JBCamera FindCameraExecution() {

  local int RatingCamera;
  local int RatingCameraSelected;
  local int RatingCameraTotal;
  local array<int> ListRatingCamera;
  local JBCamera thisCamera;

  foreach DynamicActors(Class'JBCamera', thisCamera) {
    RatingCamera = RateCameraExecution(thisCamera);
    RatingCameraTotal += RatingCamera;
    ListRatingCamera[ListRatingCamera.Length] = RatingCamera;
    }
  
  if (RatingCameraTotal == 0)
    return None;
  
  RatingCameraSelected = Rand(RatingCameraTotal);
  RatingCameraTotal = 0;
  
  foreach DynamicActors(Class'JBCamera', thisCamera) {
    RatingCameraTotal += ListRatingCamera[0];
    if (RatingCameraSelected < RatingCameraTotal)
      return thisCamera;
    ListRatingCamera.Remove(0, 1);
    }
  
  return None;
  }


// ============================================================================
// RestartAll
//
// Restarts all players in freedom.
// ============================================================================

function RestartAll() {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(GameReplicationInfo);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    InfoGame.ListInfoPlayer[iInfoPlayer].RestartFreedom();
  }


// ============================================================================
// RestartTeam
//
// Restarts all players of the given team in freedom.
// ============================================================================

function RestartTeam(byte Team) {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(GameReplicationInfo);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    if (InfoGame.ListInfoPlayer[iInfoPlayer].GetPlayerReplicationInfo().Team.TeamIndex == Team)
      InfoGame.ListInfoPlayer[iInfoPlayer].RestartFreedom();
  }


// ============================================================================
// IsReleaseActive
//
// Checks whether a release is active for the given team.
// ============================================================================

function bool IsReleaseActive(byte Team) {

  local int iInfoJail;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(GameReplicationInfo);

  for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
    if (InfoGame.ListInfoJail[iInfoJail].IsReleaseActive(Team))
      return True;
  
  return False;
  }


// ============================================================================
// ExecutionInit
//
// Checks how many teams are captured. If none, fails. If more than one,
// announces a tie and starts a new round. If exactly one, respawns all other
// players in freedom, selects an execution camera and initiates execution.
// Can only be called in the default state.
// ============================================================================

function bool ExecutionInit() {

  local int iTeam;
  local int TeamCaptured;
  
  if (IsInState('MatchInProgress')) {
    TeamCaptured = -1;
    
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (IsCaptured(iTeam))
        if (TeamCaptured < 0) {
          TeamCaptured = iTeam;
          }

        else {
          RestartAll();
          BroadcastLocalizedMessage(ClassLocalMessage, 300);
          return False;
          }
  
    if (TeamCaptured < 0 || IsReleaseActive(TeamCaptured))
      return False;
  
    ExecutionCommit(TeamCaptured);
    return True;
    }
  
  else {
    Log("Warning: Cannot initiate execution while in state" @ GetStateName());
    return False;
    }
  }


// ============================================================================
// ExecutionCommit
//
// Prepares and commits a team's execution. Respawns all other players, scores
// and announces the capture.
// ============================================================================

function ExecutionCommit(byte TeamExecuted) {

  local int iInfoJail;
  local int iTeam;
  local Controller thisController;
  local JBReplicationInfoGame InfoGame;

  if (IsInState('MatchInProgress')) {
    GotoState('Executing');
    
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (iTeam != TeamExecuted && Teams[iTeam] != None) {
        Teams[iTeam].Score += 1;
        RestartTeam(iTeam);
        }
  
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (thisController.PlayerReplicationInfo      != None &&
          thisController.PlayerReplicationInfo.Team != None &&
          thisController.PlayerReplicationInfo.Team.TeamIndex != TeamExecuted)
        ScoreEvent(thisController, 'Capture');
  
    CameraExecution = FindCameraExecution();
    if (CameraExecution == None)
      Log("Warning: No execution camera found");
  
    InfoGame = JBReplicationInfoGame(GameReplicationInfo);
    for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
      InfoGame.ListInfoJail[iInfoJail].ExecutionInit();
    
    BroadcastLocalizedMessage(ClassLocalMessage, 100, , , Teams[TeamExecuted]);
    }
  
  else {
    Log("Warning: Cannot commit execution while in state" @ GetStateName());
    }
  }


// ============================================================================
// ExecutionEnd
//
// Goes to the default state and restarts all players in the game in freedom.
// Can only be called in state Executing.
// ============================================================================

function ExecutionEnd() {

  local int iInfoJail;
  local JBReplicationInfoGame InfoGame;

  if (IsInState('Executing')) {
    InfoGame = JBReplicationInfoGame(GameReplicationInfo);
    for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
      InfoGame.ListInfoJail[iInfoJail].ExecutionEnd();
  
    GotoState('MatchInProgress');
    RestartAll();
    }
  
  else {
    Log("Warning: Cannot end execution while in state" @ GetStateName());
    }
  }


// ============================================================================
// state MatchInProgress
//
// Normal gameplay in progress.
// ============================================================================

state MatchInProgress {

  // ================================================================
  // BeginState
  //
  // Only calls the superclass function if this state is entered the
  // first time.
  // ================================================================

  event BeginState() {
  
    if (bWaitingToStartMatch)
      Super.BeginState();
    }


  // ================================================================
  // Timer
  //
  // Periodically checks whether at least one team is completely
  // jailed and sets TimeExecution if so. If TimeExecution is set
  // and has passed, resets it and calls the ExecutionInit function.
  // ================================================================
  
  event Timer() {
  
    local int iTeam;
    
    if (TimeExecution == 0.0) {
      for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
        if (IsCaptured(iTeam))
          TimeExecution = Level.TimeSeconds + 1.0;
      }
    
    else if (Level.TimeSeconds > TimeExecution) {
      TimeExecution = 0.0;
      ExecutionInit();
      }
  
    Super.Timer();
    }

  } // state MatchInProgress


// ============================================================================
// state Executing
//
// The game is currently executing a team. During that time, players cannot
// spawn in the game.
// ============================================================================

state Executing {

  // ================================================================
  // Timer
  //
  // Checks whether there are still players alive in jail. If not,
  // sets TimeRestart for a brief delay. If TimeRestart is set and
  // has passed, resets TimeRestart and calls ExecutionEnd.
  // ================================================================

  event Timer() {
  
    local int iTeam;
    local int nPlayersJailed;
    local Controller thisController;
    
    if (TimeRestart == 0.0) {
      for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
        nPlayersJailed += CountPlayersJailed(iTeam);
      if (nPlayersJailed == 0)
        TimeRestart = Level.TimeSeconds + 3.0;
      }

    else if (Level.TimeSeconds > TimeRestart) {
      TimeRestart = 0.0;
      ExecutionEnd();
      }

    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
        if (PlayerController(thisController) != None &&
           !thisController.PlayerReplicationInfo.bOnlySpectator &&
            thisController.Pawn == None)
          PlayerController(thisController).ServerReStartPlayer();
    }


  // ================================================================
  // RestartPlayer
  //
  // Puts the given player in spectator mode and sets his or her
  // ViewTarget to the currently selected execution camera.
  // ================================================================

  function RestartPlayer(Controller Controller) {
  
    if (CameraExecution != None)
      CameraExecution.ActivateFor(Controller);
    }

  } // state Executing


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  ClassLocalMessage = Class'JBLocalMessage';

  MapPrefix  = "JB";
  BeaconName = "JB";
  GameName   = "Jailbreak";

  GameReplicationInfoClass = Class'JBReplicationInfoGame';
  DefaultEnemyRosterClass = "Jailbreak.JBReplicationInfoTeam";
  
  bSpawnInTeamArea = True;
  bScoreTeamKills = False;
  }