// ============================================================================
// JBInfoJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoJail.uc,v 1.9 2002/12/20 20:54:30 mychaeel Exp $
//
// Holds information about a generic jail.
// ============================================================================


class JBInfoJail extends Info
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBInfoJail.pcx mips=off masked=on


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
  var bool bIsOpen;
  var float Time;
  var Controller ControllerInstigator;
  };


// ============================================================================
// Variables
// ============================================================================

var class<LocalMessage> ClassLocalMessage;

var private TInfoRelease ListInfoReleaseByTeam[2];

var private array<Door> ListDoor;
var private array<NavigationPoint> ListNavigationPointExit;


// ============================================================================
// PostBeginPlay
//
// Fills the ListDoor array with a list of Door actors that mark releases of
// this jail.
// ============================================================================

event PostBeginPlay() {

  local Door thisDoor;
  
  foreach AllActors(Class'Door', thisDoor)
    if (thisDoor.DoorTag == EventReleaseRed ||
        thisDoor.DoorTag == EventReleaseBlue)
      ListDoor[ListDoor.Length] = thisDoor;
  }


// ============================================================================
// CanRelease
//
// Checks whether this jail can release players of the given team.
// ============================================================================

function bool CanRelease(UnrealTeamInfo Team) {

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

function name GetEventRelease(UnrealTeamInfo Team) {

  switch (Team.TeamIndex) {
    case 0:  return EventReleaseRed;
    case 1:  return EventReleaseBlue;
    }
  }


// ============================================================================
// IsDoorOpen
//
// Checks and returns whether any doors to this jail for the given team are
// currently open.
// ============================================================================

function bool IsDoorOpen(UnrealTeamInfo Team) {

  local int iDoor;
  
  for (iDoor = 0; iDoor < ListDoor.Length; iDoor++)
    if (ListDoor[iDoor].DoorTag == GetEventRelease(Team) &&
        ListDoor[iDoor].bDoorOpen)
      return True;
  
  return False;
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
  local int nPlayersJailed;
  local JBReplicationInfoGame InfoGame;
  
  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
    if (InfoGame.ListInfoPlayer[iInfoPlayer].GetJail() == Self)
      nPlayersJailed++;
  
  return nPlayersJailed;
  }


// ============================================================================
// Release
//
// Releases the given team unless the release is already active. Can be called
// only in state Waiting and logs a warning otherwise.
// ============================================================================

function Release(UnrealTeamInfo Team, optional Controller ControllerInstigator) {

  if (IsInState('Waiting')) {
    if (ListInfoReleaseByTeam[Team.TeamIndex].bIsActive)
      return;
    
    if (ControllerInstigator != None &&
        ControllerInstigator.PlayerReplicationInfo.Team != Team) {

      Log("Warning:" @ ControllerInstigator.PlayerReplicationInfo.PlayerName @ "on team" @
          ControllerInstigator.PlayerReplicationInfo.Team.TeamIndex @ "attempted to release team" @ Team.TeamIndex);
      return;
      }

    if (CanRelease(Team)) {
      if (Jailbreak(Level.Game).CanFireEvent(GetEventRelease(Team), True)) {
        if (Jailbreak(Level.Game).CanFireEvent(Tag, True))
          BroadcastLocalizedMessage(ClassLocalMessage, 200, ControllerInstigator.PlayerReplicationInfo, ,
                                                            ControllerInstigator.PlayerReplicationInfo.Team);
        TriggerEvent(GetEventRelease(Team), Self, ControllerInstigator.Pawn);
        }
      
      ListInfoReleaseByTeam[Team.TeamIndex].bIsActive = True;
      ListInfoReleaseByTeam[Team.TeamIndex].bIsOpen = False;
      ListInfoReleaseByTeam[Team.TeamIndex].Time = Level.TimeSeconds;
      ListInfoReleaseByTeam[Team.TeamIndex].ControllerInstigator = ControllerInstigator;
      }
    }
  
  else {
    Log("Warning: Called Release for" @ Self @ "in state" @ GetStateName());
    }
  }


// ============================================================================
// JailOpened
// called. Disables all GameObjectives that can be used to trigger this jail's
// Called when this jail is opened. Temporarily disables all objectives that
// can be used to open this jail and communicates that event to all inmates.
function NotifyJailOpening(TeamInfo Team) {

function JailOpened(UnrealTeamInfo Team, optional Controller ControllerInstigator) {
  local GameObjective thisObjective;
  local int iInfoPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBReplicationInfoGame InfoGame;
  local JBReplicationInfoPlayer InfoPlayer;
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (thisObjective = Team.AI.Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
      thisObjective.bDisabled = True;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++) {
    InfoPlayer = InfoGame.ListInfoPlayer[iInfoPlayer];
    if (InfoPlayer.GetJail() == Self &&
        InfoPlayer.GetPlayerReplicationInfo().Team == Team)
      InfoPlayer.JailOpened();
    }

// ============================================================================
// NotifyJailClosed
//
// JailClosed
// ============================================================================
// Called when this jail is closed. Communicates that event to all inmates and
// enables all objectives that can be used to open this jail.
function NotifyJailClosed(TeamInfo Team) {

function JailClosed(UnrealTeamInfo Team) {
  local JBTagPlayer firstTagPlayer;
  local int iInfoPlayer;
  local GameObjective thisObjective;
  local JBReplicationInfoGame InfoGame;
  local JBReplicationInfoPlayer InfoPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
  InfoGame = JBReplicationInfoGame(Level.GRI);
  
  for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++) {
    InfoPlayer = InfoGame.ListInfoPlayer[iInfoPlayer];
    if (InfoPlayer.GetJail() == Self &&
        InfoPlayer.GetPlayerReplicationInfo().Team == Team)
      InfoPlayer.JailClosed();
    }
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
  for (thisObjective = Team.AI.Objectives; thisObjective != None; thisObjective = thisObjective.NextObjective)
        thisObjective.bDisabled)
      thisObjective.Reset();
  }


// ============================================================================
// ExecutePlayer
//
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
// Finishes up an ongoing execution by gibbing all players remaining in jail
// and going back to state Waiting. Can be called only in states
// ExecutionRunning and ExecutionFallback.
// ============================================================================

function ExecutionEnd() {

  local JBTagPlayer firstTagPlayer;
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
    
    GotoState('Waiting');
    }
  
  else {
    Log("Warning: Called ExecutionEnd for" @ Self @ "in state" @ GetStateName());
    }
  }


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
    local UnrealTeamInfo TeamInstigator;

    TeamInstigator = UnrealTeamInfo(PawnInstigator.GetTeam());
    if (TeamInstigator != None)
      Release(TeamInstigator, PawnInstigator.Controller);

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
    
    local UnrealTeamInfo Team;
      Team = TeamGame(Level.Game).Teams[iTeam];
    for (iTeam = 0; iTeam < ArrayCount(ListInfoReleaseByTeam); iTeam++) {
      if (!InfoReleaseByTeam[iTeam].bIsActive)
        continue;
      if (!ListInfoReleaseByTeam[iTeam].bIsActive ||
           ListInfoReleaseByTeam[iTeam].bIsOpen == IsDoorOpen(Team))
      if (InfoReleaseByTeam[iTeam].bIsOpening) {

      if (ListInfoReleaseByTeam[iTeam].bIsOpen) {
        ListInfoReleaseByTeam[iTeam].bIsActive = False;
        ListInfoReleaseByTeam[iTeam].bIsOpen = False;
        ListInfoReleaseByTeam[iTeam].Time = 0.0;
        ListInfoReleaseByTeam[iTeam].ControllerInstigator = None;
        JailClosed(Team);
        }
    
      else {
        ListInfoReleaseByTeam[iTeam].bIsOpen = True;
        JailOpened(Team);
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
  
    Sleep(ExecutionDelayCommit);
    GotoState('ExecutionRunning');

  } // state ExecutionStarting


// ============================================================================
// state ExecutionRunning
//
// Remains in this state until either fallback gibbing kicks in or explicitely
// reset by calling ExecutionEnd. The Jailbreak game class takes care of that.
// ============================================================================

state ExecutionRunning {

  Begin:
    if (Jailbreak(Level.Game).CanFireEvent(EventExecutionCommit, True))
      TriggerEvent(EventExecutionCommit, Self, None);
  
    Sleep(ExecutionDelayFallback);
    GotoState('ExecutionFallback');
  
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
    local Pawn PawnPlayer;
    local JBReplicationInfoGame InfoGame;
  
    InfoGame = JBReplicationInfoGame(Level.GRI);
  
    for (iInfoPlayer = 0; iInfoPlayer < InfoGame.ListInfoPlayer.Length; iInfoPlayer++)
      if (InfoGame.ListInfoPlayer[iInfoPlayer].IsInJail()) {
        PawnPlayer = Controller(InfoGame.ListInfoPlayer[iInfoPlayer].Owner).Pawn;
        if (PawnPlayer != None)
          PawnPlayer.GibbedBy(None);
        }

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

  ClassLocalMessage = Class'JBLocalMessage';
  ExecutionDelayFallback = 2.0;
  ExecutionDelayCommit   = 2.0;
  ExecutionDelayFallback = 4.0;
  TagAttachVolumes = None;
  TagAttachZones   = 'Auto';
  TagAttachVolumes = 'None';
  bAlwaysRelevant = True;
  RemoteRole = ROLE_SimulatedProxy;
  }