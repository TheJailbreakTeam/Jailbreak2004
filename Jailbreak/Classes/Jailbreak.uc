// ============================================================================
// Jailbreak
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: Jailbreak.uc,v 1.21 2003/01/19 19:11:19 mychaeel Exp $
//
// Jailbreak game type.
// ============================================================================


class Jailbreak extends TeamGame
  notplaceable;


// ============================================================================
// Configuration
// ============================================================================

var config bool bEnableJailFights;


// ============================================================================
// Variables
// ============================================================================

var class<LocalMessage> ClassLocalMessage;

var private JBCamera CameraExecution;      // camera for execution sequence

var private float TimeExecution;           // time when execution starts
var private float TimeRestart;             // time when next round starts

var private array<name> ListEventFired;    // events fired in this tick
var private float TimeEventFired;          // update time of event list


// ============================================================================
// InitGame
//
// Initializes the game.
// ============================================================================

event InitGame(string Options, out string Error) {

  Super.InitGame(Options, Error);
  
  bForceRespawn = True;
  MaxLives = 0;
  }


// ============================================================================
// Login
//
// Gives every player new JBTagPlayer and JBTagClient actors.
// ============================================================================

event PlayerController Login(string Portal, string Options, out string Error) {

  local PlayerController PlayerLogin;
  
  PlayerLogin = Super.Login(Portal, Options, Error);
  
  if (PlayerLogin                            != None &&
      PlayerLogin.PlayerReplicationInfo      != None &&
      PlayerLogin.PlayerReplicationInfo.Team != None)
    Class'JBTagPlayer'.Static.SpawnFor(PlayerLogin.PlayerReplicationInfo);
  
  Class'JBTagClient'.Static.SpawnFor(PlayerLogin);
  
  return PlayerLogin;
  }


// ============================================================================
// SpawnBot
//
// Gives every new bot a JBTagPlayer actor.
// ============================================================================

function Bot SpawnBot(optional string NameBot) {

  local Bot BotSpawned;
  
  BotSpawned = Super.SpawnBot(NameBot);
  if (BotSpawned != None)
    Class'JBTagPlayer'.Static.SpawnFor(BotSpawned.PlayerReplicationInfo);
  
  return BotSpawned;
  }


// ============================================================================
// Logout
//
// Destroys the JBTagPlayer and JBTagClient actors for the given player or bot
// if one exists.
// ============================================================================

function Logout(Controller ControllerExiting) {

  Class'JBTagPlayer'.Static.DestroyFor(ControllerExiting.PlayerReplicationInfo);

  if (PlayerController(ControllerExiting) != None)
    Class'JBTagClient'.Static.DestroyFor(PlayerController(ControllerExiting));

  Super.Logout(ControllerExiting);
  }


// ============================================================================
// RatePlayerStart
//
// Returns a negative value for all starts that are inappropriate for the
// given player's scheduled respawn area.
// ============================================================================

function float RatePlayerStart(NavigationPoint NavigationPoint, byte iTeam, Controller Controller) {

  local name Restart;
  local JBInfoArena Arena;
  local JBTagPlayer TagPlayer;

  if (Controller != None)
    TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);

  if (TagPlayer == None)
    Restart = 'Restart_Freedom';  // initial spawn point in offline games
  else
    Restart = TagPlayer.GetRestart();
  
  switch (Restart) {
    case 'Restart_Freedom':
      if (ContainsActorJail (NavigationPoint) ||
          ContainsActorArena(NavigationPoint))
        return -20000000;
      break;

    case 'Restart_Jail':
      if (!ContainsActorJail(NavigationPoint))
        return -20000000;
      break;
    
    case 'Restart_Arena':
      if (!ContainsActorArena(NavigationPoint, Arena) || Arena != TagPlayer.GetArenaRestart())
        return -20000000;
      break;
    }

  return Super.RatePlayerStart(NavigationPoint, iTeam, Controller);
  }


// ============================================================================
// ScoreKill
//
// Translates kills into ScorePlayer calls according to Jailbreak rules.
// ============================================================================

function ScoreKill(Controller ControllerKiller, Controller ControllerVictim) {

  local float DistanceRelease;
  local float DistanceReleaseMin;
  local JBTagObjective firstTagObjective;
  local JBTagObjective thisTagObjective;
  local JBTagPlayer TagPlayerVictim;

  if (GameRulesModifiers != None)
    GameRulesModifiers.ScoreKill(ControllerKiller, ControllerVictim);

  ScoreKillAdjust(ControllerKiller, ControllerVictim);
  ScoreKillTaunt (ControllerKiller, ControllerVictim);

  TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);
  if (TagPlayerVictim != None &&
      TagPlayerVictim.IsInJail())
    return;

  if (ControllerKiller == None ||
      ControllerKiller == ControllerVictim)
    ScorePlayer(ControllerVictim, 'Suicide');
  
  else if (SameTeam(ControllerKiller, ControllerVictim))
    ScorePlayer(ControllerKiller, 'Teamkill');

  else {
    DistanceReleaseMin = -1.0;
  
    firstTagObjective = JBReplicationInfoGame(GameReplicationInfo).firstTagObjective;
    for (thisTagObjective = firstTagObjective; thisTagObjective != None; thisTagObjective = thisTagObjective.nextTag) {
      DistanceRelease = VSize(thisTagObjective.GetObjective().Location - ControllerVictim.Pawn.Location);
      if (DistanceReleaseMin < 0.0 ||
          DistanceReleaseMin > DistanceRelease)
        DistanceReleaseMin = DistanceRelease;
      }
  
    if (DistanceRelease < 1024.0)
      ScorePlayer(ControllerKiller, 'Defense');
    else
      ScorePlayer(ControllerKiller, 'Attack');
    
    ControllerKiller.PlayerReplicationInfo.Kills  += 1;
    ControllerVictim.PlayerReplicationInfo.Deaths += 1;
    }
  }


// ============================================================================
// ScoreKillAdjust
//
// Performs bot skill adjustments as implemented in ScoreKill in DeathMatch.
// ============================================================================

function ScoreKillAdjust(Controller ControllerKiller, Controller ControllerVictim) {

  if (bAdjustSkill) {
    if (AIController(ControllerKiller) != None && PlayerController(ControllerVictim) != None)
      AdjustSkill(AIController(ControllerKiller), PlayerController(ControllerVictim), True);
    if (AIController(ControllerVictim) != None && PlayerController(ControllerKiller) != None)
      AdjustSkill(AIController(ControllerVictim), PlayerController(ControllerKiller), False);
    }
  }


// ============================================================================
// ScoreKillTaunt
//
// Performs auto-taunts as implemented in ScoreKill in DeathMatch.
// ============================================================================

function ScoreKillTaunt(Controller ControllerKiller, Controller ControllerVictim) {

  local bool bNoHumanOnly;

  if (bAllowTaunts &&
      ControllerKiller != None &&
      ControllerKiller != ControllerVictim &&
      ControllerKiller.AutoTaunt() && 
      ControllerKiller.PlayerReplicationInfo.VoiceType != None) {

    bNoHumanOnly = PlayerController(ControllerKiller) == None;

    ControllerKiller.SendMessage(
      ControllerVictim.PlayerReplicationInfo, 'AutoTaunt',
      ControllerKiller.PlayerReplicationInfo.VoiceType.Static.PickRandomTauntFor(ControllerKiller, False, bNoHumanOnly),
      10, 'Global');
    }
  }


// ============================================================================
// ScorePlayer
//
// Adds points to the given player's score according to the given game event.
// ============================================================================

function ScorePlayer(Controller Controller, name Event) {

  switch (Event) {
    case 'Suicide':   ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Teamkill':  ScoreObjective(Controller.PlayerReplicationInfo, -1);  break;
    case 'Attack':    ScoreObjective(Controller.PlayerReplicationInfo, +1);  break;
    case 'Defense':   ScoreObjective(Controller.PlayerReplicationInfo, +2);  break;
    case 'Release':   ScoreObjective(Controller.PlayerReplicationInfo, +1);  break;
    case 'Capture':   ScoreObjective(Controller.PlayerReplicationInfo, +1);  break;
    }

  switch (Event) {
    case 'Defense':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'Release':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    case 'Capture':   Controller.AwardAdrenaline(ADR_MinorBonus);  break;
    }
  }


// ============================================================================
// BroadcastDeathMessage
//
// Broadcasts death messages concerning suicides or kills in jail only to all
// jailed players of that team.
// ============================================================================

function BroadcastDeathMessage(Controller ControllerKiller, Controller ControllerVictim, Class<DamageType> DamageType) {

  local int SwitchMessage;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer TagPlayerKiller;
  local JBTagPlayer TagPlayerVictim;
  local PlayerReplicationInfo PlayerReplicationInfoKiller;
  local PlayerReplicationInfo PlayerReplicationInfoVictim;

  if (ControllerKiller != None)
    TagPlayerKiller = Class'JBTagPlayer'.Static.FindFor(ControllerKiller.PlayerReplicationInfo);
  TagPlayerVictim = Class'JBTagPlayer'.Static.FindFor(ControllerVictim.PlayerReplicationInfo);

  if (TagPlayerVictim.IsInJail() &&
      (TagPlayerKiller == None ||
       TagPlayerKiller.IsInJail())) {

    if (ControllerKiller != None)
      PlayerReplicationInfoKiller = ControllerKiller.PlayerReplicationInfo;
    PlayerReplicationInfoVictim = ControllerVictim.PlayerReplicationInfo;

    if (ControllerKiller == None ||
        ControllerKiller == ControllerVictim)
      SwitchMessage = 1;  // suicide
    else
      SwitchMessage = 0;  // homicide

    firstTagPlayer = JBReplicationInfoGame(GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetJail() == TagPlayerVictim.GetJail() &&
          PlayerController(thisTagPlayer.GetController()) != None)
        BroadcastHandler.BroadcastLocalized(
          Self,
          PlayerController(thisTagPlayer.GetController()),
          DeathMessageClass,
          SwitchMessage,
          PlayerReplicationInfoKiller,
          PlayerReplicationInfoVictim,
          DamageType);
    }
  
  else {
    Super.BroadcastDeathMessage(ControllerKiller, ControllerVictim, DamageType);
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

  local JBInfoJail firstJail;

  firstJail = JBReplicationInfoGame(GameReplicationInfo).firstJail;
  for (Jail = firstJail; Jail != None; Jail = Jail.nextJail)
    if (Jail.ContainsActor(Actor))
      return True;

  return False;
  }


// ============================================================================
// ContainsActorArena
//
// Iterates over all arenas and returns whether one of them contains the given
// actor (and optionally which of them).
// ============================================================================

function bool ContainsActorArena(Actor Actor, optional out JBInfoArena Arena) {

  local JBInfoArena firstArena;
  
  firstArena = JBReplicationInfoGame(GameReplicationInfo).firstArena;
  for (Arena = firstArena; Arena != None; Arena = Arena.nextArena)
    if (Arena.ContainsActor(Actor))
      return True;

  return False;
  }


// ============================================================================
// CountPlayersJailed
//
// Forwarded to CountPlayersJailed in JBReplicationInfoTeam.
// ============================================================================

function int CountPlayersJailed(TeamInfo Team) {

  return JBReplicationInfoTeam(Team).CountPlayersJailed();
  }


// ============================================================================
// CountPlayersTotal
//
// Forwarded to CountPlayersTotal in JBReplicationInfoTeam.
// ============================================================================

function int CountPlayersTotal(TeamInfo Team) {

  return JBReplicationInfoTeam(Team).CountPlayersTotal();
  }


// ============================================================================
// IsCaptured
//
// Returns whether the given team has been captured.
// ============================================================================

function bool IsCaptured(TeamInfo Team) {

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

  local int nPlayersJailed;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  
  firstJail = JBReplicationInfoGame(GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail.Event == CameraExecution.Tag)
      nPlayersJailed += thisJail.CountPlayersTotal();
  
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

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBReplicationInfoGame(GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    thisTagPlayer.RestartFreedom();
  }


// ============================================================================
// RestartTeam
//
// Restarts all players of the given team in freedom.
// ============================================================================

function RestartTeam(TeamInfo Team) {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBReplicationInfoGame(GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.RestartFreedom();
  }


// ============================================================================
// IsReleaseActive
//
// Checks whether a release is active for the given team.
// ============================================================================

function bool IsReleaseActive(TeamInfo Team) {

  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  
  firstJail = JBReplicationInfoGame(GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail.IsReleaseActive(Team))
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

  local bool bFoundCaptured;
  local int iTeam;
  local int iTeamCaptured;
  
  if (IsInState('MatchInProgress')) {
    for (iTeam = 0; iTeam < ArrayCount(Teams); iTeam++)
      if (IsCaptured(Teams[iTeam])) {
        if (bFoundCaptured) {
          RestartAll();
          BroadcastLocalizedMessage(ClassLocalMessage, 300);
          return False;
          }
      
        bFoundCaptured = True;
        iTeamCaptured = iTeam;
        }
  
    if (!bFoundCaptured || IsReleaseActive(Teams[iTeamCaptured]))
      return False;
  
    ExecutionCommit(Teams[iTeamCaptured]);
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

function ExecutionCommit(TeamInfo TeamExecuted) {

  local Controller thisController;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local TeamInfo TeamCapturer;

  if (IsInState('MatchInProgress')) {
    GotoState('Executing');
    BroadcastLocalizedMessage(ClassLocalMessage, 100, , , TeamExecuted);
    
    TeamCapturer = OtherTeam(TeamExecuted);
    TeamCapturer.Score += 1;
    RestartTeam(TeamCapturer);
  
    for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
      if (thisController.PlayerReplicationInfo      != None &&
          thisController.PlayerReplicationInfo.Team != TeamExecuted)
        ScorePlayer(thisController, 'Capture');
  
    CameraExecution = FindCameraExecution();
    if (CameraExecution == None)
      Log("Warning: No execution camera found");
  
    firstJail = JBReplicationInfoGame(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionInit();
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

  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  if (IsInState('Executing')) {
    firstJail = JBReplicationInfoGame(GameReplicationInfo).firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      thisJail.ExecutionEnd();
  
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
  // first time. Resets the orders all bots.
  // ================================================================

  event BeginState() {
  
    if (bWaitingToStartMatch)
      Super.BeginState();
    
    JBBotTeam(Teams[0].AI).ResetOrders();
    JBBotTeam(Teams[1].AI).ResetOrders();
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
        if (IsCaptured(Teams[iTeam]))
          TimeExecution = Level.TimeSeconds + 1.0;
      }
    
    else if (Level.TimeSeconds > TimeExecution) {
      TimeExecution = 0.0;
      ExecutionInit();
      }
  
    Super.Timer();
    }


  // ================================================================
  // RestartPlayer
  //
  // Records the player's current potential locations.
  // ================================================================

  function RestartPlayer(Controller Controller) {
  
    Super.RestartPlayer(Controller);

    JBBotTeam(Teams[0].AI).NotifySpawn(Controller);
    JBBotTeam(Teams[1].AI).NotifySpawn(Controller);
    }

  } // state MatchInProgress


// ============================================================================
// state Executing
//
// The game is currently executing a team. During that time, players cannot
// spawn in the game.
// ============================================================================

state Executing {

  ignores BroadcastDeathMessage;  // no death messages during execution


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
        nPlayersJailed += CountPlayersJailed(Teams[iTeam]);
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

  bEnableJailFights = True;

  MapPrefix  = "JB";
  BeaconName = "JB";
  GameName   = "Jailbreak";
 
  HUDType                  = "Jailbreak.JBInterfaceHud";
  ScoreBoardType           = "Jailbreak.JBInterfaceScores";
  DefaultEnemyRosterClass  = "Jailbreak.JBReplicationInfoTeam";
  
  ClassLocalMessage        = Class'JBLocalMessage';
  GameReplicationInfoClass = Class'JBReplicationInfoGame';
  DeathMessageClass        = Class'xDeathMessage';

  TeamAIType[0] = Class'JBBotTeam';
  TeamAIType[1] = Class'JBBotTeam';
  
  bSpawnInTeamArea = True;
  bScoreTeamKills = False;
  }