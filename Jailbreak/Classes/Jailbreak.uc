// ============================================================================
// Jailbreak
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: Jailbreak.uc,v 1.1.1.1 2002/11/16 20:35:10 mychaeel Exp $
//
// Jailbreak game type.
// ============================================================================


class Jailbreak extends TeamGame
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var private JBCamera CameraExecution;  // Camera for execution sequence

var private float TimeExecution;       // Time when execution starts
var private float TimeRestart;         // Time when next round starts


// ============================================================================
// RatePlayerStart
//
// Returns a negative value for all starts that are inappropriate for the
// given player's scheduled respawn area.
// ============================================================================

function float RatePlayerStart(NavigationPoint NavigationPoint, byte Team, Controller Controller) {

  local JBInfoArena Arena;
  local JBReplicationInfoPlayer InfoPlayer;
  
  switch (int(InfoPlayer.GetRestart())) {
    case 0:  // ERestart.Restart_Jail
      if (!ContainsActorJail(NavigationPoint))
        return -20000000;
      break;
    
    case 1:  // ERestart.Restart_Arena
      InfoPlayer = Class'JBReplicationInfoPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
      if (!ContainsActorArena(NavigationPoint, Arena) || Arena != InfoPlayer.GetArenaRestart())
        return -20000000;
      break;
    
    case 2:  // ERestart.Restart_Freedom
      if (ContainsActorJail (NavigationPoint) ||
          ContainsActorArena(NavigationPoint))
        return -20000000;
      break;
    }

  return Super.RatePlayerStart(NavigationPoint, Team, Controller);
  }


// ============================================================================
// Timer
//
// Periodically checks whether at least one team is completely jailed and sets
// TimeExecution if so. If TimeExecution is set and has passed, resets it and
// calls the ExecutionInit function.
// ============================================================================

event Timer() {

  local int iTeam;
  
  if (TimeExecution == 0.0) {
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (CountPlayersJailed(iTeam) == CountPlayersTotal(iTeam)) {
        TimeExecution = Level.TimeSeconds + 1.0;
        break;
        }
    }
  
  else if (Level.TimeSeconds > TimeExecution) {
    TimeExecution = 0.0;
    ExecutionInit();
    }

  Super.Timer();
  }


// ============================================================================
// ScoreEvent
//
// Adds points to the given player's score according to the given game event.
// ============================================================================

function ScoreEvent(Controller Controller, name Event) {

  // TODO: implement
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
// FindCameraExecution
//
// Finds the execution camera with the best view on the execution sequence.
// ============================================================================

function JBCamera FindCameraExecution() {

  local JBCamera thisCamera;
  local JBInfoJail Jail;

  // TODO: implement properly
  
  foreach DynamicActors(Class'JBCamera', thisCamera)
    if (ContainsActorJail(thisCamera, Jail) && Jail.CountPlayersTotal() > 0)
      return thisCamera;
  
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

  local int iInfoJail;
  local int iTeam;
  local int TeamCaptured;
  local JBReplicationInfoGame InfoGame;
  
  if (IsInState('')) {
    TeamCaptured = -1;
    
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (CountPlayersJailed(iTeam) == CountPlayersTotal(iTeam))
        if (TeamCaptured < 0)
          TeamCaptured = iTeam;
        else {
          // TODO: announce tie
          RestartAll();
          return False;
          }
  
    if (TeamCaptured < 0 || IsReleaseActive(TeamCaptured))
      return False;
  
    GotoState('Executing');
    
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (iTeam != TeamCaptured)
        RestartTeam(iTeam);

    CameraExecution = FindCameraExecution();
  
    InfoGame = JBReplicationInfoGame(GameReplicationInfo);
    for (iInfoJail = 0; iInfoJail < InfoGame.ListInfoJail.Length; iInfoJail++)
      InfoGame.ListInfoJail[iInfoJail].ExecutionInit();
    
    return True;
    }
  
  else {
    Log("Warning: Cannot initiate execution while in state" @ GetStateName());
    return False;
    }
  }


// ============================================================================
// ExecutionEnd
//
// Goes to the default state and restarts all players in the game in freedom.
// Can only be called in state Executing.
// ============================================================================

function ExecutionEnd() {

  if (IsInState('Executing')) {
    GotoState('');
    RestartAll();
    }
  
  else {
    Log("Warning: Cannot end execution while in state" @ GetStateName());
    }
  }


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
    
    if (TimeRestart == 0.0) {
      for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
        nPlayersJailed += CountPlayersJailed(iTeam);
      if (nPlayersJailed == 0)
        TimeRestart = Level.TimeSeconds + 1.0;
      }

    else if (Level.TimeSeconds > TimeRestart) {
      TimeRestart = 0.0;
      ExecutionEnd();
      }
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

  GameReplicationInfoClass = Class'JBReplicationInfoGame';
  DefaultEnemyRosterClass = "Jailbreak.JBReplicationInfoTeam";
  }