// ============================================================================
// JBInfoJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoJail.uc,v 1.1.1.1 2002/11/16 20:35:10 mychaeel Exp $
//
// Holds information about a generic jail.
// ============================================================================


class JBInfoJail extends Info
  placeable;


// ============================================================================
// Properties
// ============================================================================

var(Events) name EventExecutionInit;
var(Events) name EventExecutionCommit;
var(Events) name EventExecutionEnd;
var(Events) name EventReleaseRed;
var(Events) name EventReleaseBlue;

var() float ExecutionDelayCommit;
var() float ExecutionDelayFallback;

var() name TagAttachVolumes;
var() name TagAttachZones;


// ============================================================================
// Types
// ============================================================================

struct TInfoRelease {

  var bool bIsActive;
  var float Time;
  var Controller ControllerInstigator;
  };


// ============================================================================
// Variables
// ============================================================================

var private TInfoRelease ListInfoReleaseByTeam[2];


// ============================================================================
// PostNetBeginPlay
//
// Registers this actor with the game.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(Level.GRI);
  InfoGame.ListInfoJail[InfoGame.ListInfoJail.Length] = Self;
  }


// ============================================================================
// Destroyed
//
// Unregisters this actor.
// ============================================================================

simulated event Destroyed() {

  local int iInfoJail;
  local JBReplicationInfoGame InfoGame;

  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoJail = InfoGame.ListInfoJail.Length - 1; iInfoJail >= 0; iInfoJail--)
    if (InfoGame.ListInfoJail[iInfoJail] == Self)
      InfoGame.ListInfoJail.Remove(iInfoJail, 1);
  }


// ============================================================================
// CanRelease
//
// Checks whether this jail can release players of the given team.
// ============================================================================

function bool CanRelease(byte Team) {

  local Actor thisActor;
  
  if (GetEventRelease(Team) == '')
    return False;
  
  foreach DynamicActors(Class'Actor', thisActor, GetEventRelease(Team))
    return True;
  
  return False;
  }


// ============================================================================
// GetEventRelease
//
// Returns the value of EventReleaseRed or EventReleaseBlue depending on the
// given team index.
// ============================================================================

function name GetEventRelease(byte Team) {

  switch (Team) {
    case 0:  return EventReleaseRed;
    case 1:  return EventReleaseBlue;
    }
  }


// ============================================================================
// IsMoverClosed
//
// Returns whether the given mover is currently in its default, closed state.
// Also returns True if the mover has no clear closed state.
// ============================================================================

function bool IsMoverClosed(Mover Mover) {

  if (Mover.InitialState == 'TriggerPound'  ||
      Mover.InitialState == 'ConstantLoop'  ||
      Mover.InitialState == 'RotatingMover')
    return True;

  if (Mover.KeyNum > 0 ||
      Mover.bInterpolating)
    return False;
  
  return True;
  }


// ============================================================================
// ContainsActor
//
// Returns whether this jail (including attached zones and volumes) contains
// the given actor. Note that this is a physical relationship, not a logical
// one; a player who's physically located in jail isn't necessarily a prisoner.
// Use the IsInJail function in JBReplicationInfoPlayer to check the latter.
// ============================================================================

function bool ContainsActor(Actor Actor) {

  local Volume thisVolume;

  if (Actor == None)
    return False;
  
  if (TagAttachZones == 'Auto') {
    if (Actor.Region.ZoneNumber == Region.ZoneNumber)
      return True;
    }
  else {
    if (Actor.Tag == TagAttachZones)
      return True;
    }

  if (TagAttachVolumes != '' &&
      TagAttachVolumes != 'None')
    foreach TouchingActors(Class'Volume', thisVolume)
      if (thisVolume.Tag == TagAttachVolumes)
        return True;
  
  return False;
  }


// ============================================================================
// CountPlayers
//
// Counts the number of players of the given team that are in this jail.
// ============================================================================

function int CountPlayers(byte Team) {

  local int iInfoPlayer;
  local int nInfoPlayerJailed;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    if (InfoGame.ListInfoPlayer[iInfoPlayer].GetPlayerReplicationInfo().Team.TeamIndex == Team &&
        InfoGame.ListInfoPlayer[iInfoPlayer].GetJail() == Self)
      nInfoPlayerJailed++;
  
  return nInfoPlayerJailed;
  }


// ============================================================================
// CountPlayersTotal
//
// Counts the total number of players that are in this jail.
// ============================================================================

function int CountPlayersTotal() {

  local int iInfoPlayer;
  local int nInfoPlayerJailed;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    if (InfoGame.ListInfoPlayer[iInfoPlayer].GetJail() == Self)
      nInfoPlayerJailed++;
  
  return nInfoPlayerJailed;
  }


// ============================================================================
// Release
//
// Releases the given team unless the release is already active. Can be called
// only in state Waiting and logs a warning otherwise.
// ============================================================================

function Release(byte Team, optional Controller ControllerInstigator) {

  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;

  if (IsInState('Waiting')) {
    if (ListInfoReleaseByTeam[Team].bIsActive)
      return;
    
    if (ControllerInstigator != None &&
        ControllerInstigator.PlayerReplicationInfo.Team.TeamIndex != Team) {

      Log("Warning:" @ ControllerInstigator.PlayerReplicationInfo.PlayerName @ "on team" @
          ControllerInstigator.PlayerReplicationInfo.Team.TeamIndex @ "attempted to release team" @ Team);
      return;
      }
    
    TriggerEvent(GetEventRelease(Team), Self, ControllerInstigator.Pawn);
    
    ListInfoReleaseByTeam[Team].bIsActive = True;
    ListInfoReleaseByTeam[Team].Time = Level.TimeSeconds;
    ListInfoReleaseByTeam[Team].ControllerInstigator = ControllerInstigator;
    
    InfoGame = JBReplicationInfoGame(Level.GRI);
    
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
      if (InfoGame.ListInfoPlayer[iInfoPlayer].GetJail() == Self)
        InfoGame.ListInfoPlayer[iInfoPlayer].ReleasePrepare();
    }
  
  else {
    Log("Warning: Called Release for" @ Self @ "in state" @ GetStateName());
    }
  }


// ============================================================================
// Initiates the execution sequence. Can be called only in state Waiting and
// logs a warning otherwise.
// ============================================================================

function ExecutionInit() {

  if (IsInState('Waiting'))
    GotoState('ExecutionStarting');
  else
    Log("Warning: Called ExecutionInit for" @ Self @ "in state" @ GetStateName());
  }


// ============================================================================
// ExecutionEnd
//
// ExecutionDone
// and going back to state Waiting. Can be called only in states
// ExecutionRunning and ExecutionFallback.
// ============================================================================

function ExecutionEnd() {

function ExecutionDone() {
  local JBTagPlayer thisTagPlayer;
  local int iInfoPlayer;
  local JBReplicationInfoGame InfoGame;
      IsInState('ExecutionFallback')) {

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    InfoGame = JBReplicationInfoGame(Level.GRI);
    
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
      if (InfoGame.ListInfoPlayer[iInfoPlayer].GetJail() == Self)
        Controller(InfoGame.ListInfoPlayer[iInfoPlayer].Owner).Pawn.GibbedBy(None);
      TriggerEvent(EventExecutionEnd, Self, None);
  
  else {
    Log("Warning: Called ExecutionEnd for" @ Self @ "in state" @ GetStateName());
    }
    Log("Warning: Called ExecutionDone for" @ Self @ "in state" @ GetStateName());


// ============================================================================
// state Waiting
//
// Jail waits for a release to be triggered or an execution to be started.
// ============================================================================

auto state Waiting {

  // ================================================================
  // BeginState
  //
  // Starts the timer.
  // ================================================================

  event BeginState() {
  
    SetTimer(0.2, True);
    }


  // ================================================================
  // Trigger
  //
  // If triggered from a GameObjective, releases players from the
  // team that can attack that objective even if the release was
  // When triggered, initiates the release of the instigator's team.
  event Trigger(Actor ActorOther, Pawn PawnInstigator) {

    local Controller ControllerInstigator;
    local GameObjective firstObjective;
    if (PawnInstigator.GetTeam() != None)
      Release(PawnInstigator.GetTeam().TeamIndex, PawnInstigator.Controller);

  // ================================================================
  // Timer
  //
  // For each team whose release is active, checks whether the jail
  // doors have been closed already and, if so, resets that team's
  // release information.
  // ================================================================

  event Timer() {
  
    local int iTeam;
    local TeamInfo Team;
    
    local Mover thisMover;
      Team = TeamGame(Level.Game).Teams[iTeam];
    for (iTeam = 0; iTeam < ArrayCount(ListInfoReleaseByTeam); iTeam++)
      if (ListInfoReleaseByTeam[iTeam].bIsActive) {
        ListInfoReleaseByTeam[iTeam].bIsActive = False;

        foreach DynamicActors(Class'Mover', thisMover, GetEventRelease(iTeam))
          if (!IsMoverClosed(thisMover)) {
            ListInfoReleaseByTeam[iTeam].bIsActive = True;
            break;
            }

        if (!ListInfoReleaseByTeam[iTeam].bIsActive) {
          ListInfoReleaseByTeam[iTeam].Time = 0.0;
          ListInfoReleaseByTeam[iTeam].ControllerInstigator = None;
          }
    }

  // ================================================================
  // EndState
  //
  // Cancels all ongoing releases and stops the timer.
  // ================================================================
  // Stops the timer.
  event EndState() {
  
    local int iTeam;
  

  } // state Waiting


// ============================================================================
// state ExecutionStarting
//
// Execution has been initiated, but has not started yet. Automatically goes
// to state ExecutionRunning after the specified delay.
// ============================================================================

state ExecutionStarting {

  Begin:
    if (Jailbreak(Level.Game).CanFireEvent(EventExecutionInit, True))
      TriggerEvent(EventExecutionInit, Self, None);

  } // state ExecutionStarting


// ============================================================================
// state ExecutionRunning
//
// Remains in this state until either fallback gibbing kicks in or explicitely
// reset by calling ExecutionEnd. The Jailbreak game class takes care of that.
// ============================================================================
// reset by calling ExecutionDone. The Jailbreak game class takes care of that.
state ExecutionRunning {

  Begin:
    if (Jailbreak(Level.Game).CanFireEvent(EventExecutionCommit, True))
      TriggerEvent(EventExecutionCommit, Self, None);
  
  } // state ExecutionRunning


// ============================================================================
// state ExecutionFallback
//
// Performs fallback execution sequence by killing all players in jail.
// ============================================================================

state ExecutionFallback {

  // ================================================================
  // BeginState
  //
  // Starts the timer.
  // ================================================================
  
  event BeginState() {
  
    SetTimer(1.0, True);
    }


  // ================================================================
  // Timer
  //
  // Periodically checks for players remaining in jail and gibs any
  // it finds.
  // ================================================================

  event Timer() {
  
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local int iInfoPlayer;
    local JBReplicationInfoGame InfoGame;
  
    InfoGame = JBReplicationInfoGame(Level.GRI);
  
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
      if (InfoGame.ListInfoPlayer[iInfoPlayer].IsInJail())
        Controller(InfoGame.ListInfoPlayer[iInfoPlayer].Owner).Pawn.GibbedBy(None);

  // ================================================================
  // EndState
  //
  // Stops the timer.
  // ================================================================

  event EndState() {
  
    SetTimer(0.0, False);
    }

  } // state ExecutionFallback


// ============================================================================
// Accessors
// ============================================================================

function bool IsReleaseActive(TeamInfo Team) {
  return InfoReleaseByTeam[Team.TeamIndex].bIsActive; }
function bool IsReleaseActive(byte Team) {
  return ListInfoReleaseByTeam[Team].bIsActive;
  }
  return InfoReleaseByTeam[Team.TeamIndex].ControllerInstigator; }
function Controller GetReleaseInstigator(byte Team) {
  return ListInfoReleaseByTeam[Team].ControllerInstigator;
  }

function float GetReleaseTime(byte Team) {
  return ListInfoReleaseByTeam[Team].Time;
  }
// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  MessageClass = Class'JBLocalMessage';
  ExecutionDelayFallback = 2.0;
  ExecutionDelayCommit   = 2.0;
  ExecutionDelayFallback = 4.0;
  TagAttachVolumes = None;
  TagAttachZones   = 'Auto';
  TagAttachVolumes = 'None';
  bAlwaysRelevant = True;
  }