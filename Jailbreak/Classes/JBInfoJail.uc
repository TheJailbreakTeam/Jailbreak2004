// ============================================================================
// JBInfoJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoJail.uc,v 1.17 2003/01/27 18:17:19 mychaeel Exp $
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

  var bool bIsActive;                   // release has been activated
  var bool bIsOpening;                  // release doors are opening
  var float TimeActivation;             // time of release activation
  var float TimeReset;                  // time of release switch reset
  var Controller ControllerInstigator;  // player activating the release
  var array<Mover> ListMover;           // movers opening for this release
  };


// ============================================================================
// Variables
// ============================================================================

var JBInfoJail nextJail;  // next jail in linked list

var private TInfoRelease ListInfoReleaseByTeam[2];  // state of jail releases

var private array<Volume> ListVolume;  // attached volumes
var private array<NavigationPoint> ListNavigationPointExit;


// ============================================================================
// PostBeginPlay
//
// Initializes the ListVolume array with references to all volumes attached to
// this jail, and the ListMover arrays with references to all movers that are
// opened by release events.
// ============================================================================

event PostBeginPlay() {

  local Volume thisVolume;

  if (TagAttachVolumes != '' &&
      TagAttachVolumes != 'None')
    foreach AllActors(Class'Volume', thisVolume, TagAttachVolumes)
      ListVolume[ListVolume.Length] = thisVolume;

  FindReleases(EventReleaseRed,  ListInfoReleaseByTeam[0].ListMover);
  FindReleases(EventReleaseBlue, ListInfoReleaseByTeam[1].ListMover);
  }


// ============================================================================
// FindReleases
//
// Adds movers triggered by the given tag to the given array unless they are
// present there already. Then recursively finds other movers triggered by the
// found mover's OpeningEvent and adds them too.
// ============================================================================

function FindReleases(name TagMover, out array<Mover> ListMover) {

  local int iMover;
  local Mover thisMover;

  if (TagMover == '' ||
      TagMover == 'None')
    return;

  foreach DynamicActors(Class'Mover', thisMover, TagMover) {
    for (iMover = 0; iMover < ListMover.Length; iMover++)
      if (ListMover[iMover] == thisMover)
        break;

    if (iMover < ListMover.Length)
      continue;  // mover already listed

    ListMover[iMover] = thisMover;
    FindReleases(thisMover.OpeningEvent, ListMover);
    }
  }


// ============================================================================
// FindExits
//
// Finds and returns a list of NavigationPoint actors outside jail that are
// directly connected to NavigationPoint actors in this jail. If multiple
// paths lead from a point in jail to one outside, this exit will be listed
// multiple times.
// ============================================================================

function array<NavigationPoint> FindExits() {

  local int iReachSpec;
  local NavigationPoint thisNavigationPoint;

  if (ListNavigationPointExit.Length == 0)
    for (thisNavigationPoint = Level.NavigationPointList;
         thisNavigationPoint != None;
         thisNavigationPoint = thisNavigationPoint.nextNavigationPoint)
      if (ContainsActor(thisNavigationPoint))
        for (iReachSpec = 0; iReachSpec < thisNavigationPoint.PathList.Length; iReachSpec++)
          if (!Jailbreak(Level.Game).ContainsActorArena(thisNavigationPoint.PathList[iReachSpec].End) &&
              !Jailbreak(Level.Game).ContainsActorJail (thisNavigationPoint.PathList[iReachSpec].End))
            ListNavigationPointExit[ListNavigationPointExit.Length] = thisNavigationPoint.PathList[iReachSpec].End;
  
  return ListNavigationPointExit;
  }


// ============================================================================
// CanRelease
//
// Checks whether this jail can release players of the given team.
// ============================================================================

function bool CanRelease(TeamInfo Team) {

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

function name GetEventRelease(TeamInfo Team) {

  switch (Team.TeamIndex) {
    case 0:  return EventReleaseRed;
    case 1:  return EventReleaseBlue;
    }
  }


// ============================================================================
// IsReleaseOpen
//
// Checks and returns whether any release movers of this jail for the given
// team are currently fully open.
// ============================================================================

function bool IsReleaseOpen(TeamInfo Team) {

  local int iMover;
  local TInfoRelease InfoRelease;
  
  InfoRelease = ListInfoReleaseByTeam[Team.TeamIndex];
  
  for (iMover = 0; iMover < InfoRelease.ListMover.Length; iMover++)
    if (!InfoRelease.ListMover[iMover].bClosed &&
        !InfoRelease.ListMover[iMover].bInterpolating)
      return True;  // neither closed nor interpolating, thus open

  return False;
  }


// ============================================================================
// IsReleaseClosed
//
// Checks and returns whether all release movers of this jail for the given
// team are fully closed.
// ============================================================================

function bool IsReleaseClosed(TeamInfo Team) {

  local int iMover;
  local TInfoRelease InfoRelease;
  
  InfoRelease = ListInfoReleaseByTeam[Team.TeamIndex];
  
  for (iMover = 0; iMover < InfoRelease.ListMover.Length; iMover++)
    if (!InfoRelease.ListMover[iMover].bClosed)
      return False;
  
  return True;
  }


// ============================================================================
// ContainsActor
//
// Returns whether this jail (including attached zones and volumes) contains
// the given actor. Note that this is a physical relationship, not a logical
// one; a player who's physically located in jail isn't necessarily a prisoner.
// Use the IsInJail function in JBTagPlayer to check the latter.
// ============================================================================

function bool ContainsActor(Actor Actor) {

  local int iVolume;

  if (Actor == None)
    return False;
  
  if (TagAttachZones == 'Auto') {
    if (Actor.Region.ZoneNumber == Region.ZoneNumber)
      return True;
    }
  else {
    if (Actor.Region.Zone.Tag == TagAttachZones)
      return True;
    }

  for (iVolume = 0; iVolume < ListVolume.Length; iVolume++)
    if (ListVolume[iVolume].Encompasses(Actor))
      return True;
  
  return False;
  }


// ============================================================================
// CountPlayers
//
// Counts the number of players of the given team that are in this jail.
// ============================================================================

function int CountPlayers(TeamInfo Team) {

  local int nPlayersJailed;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetTeam() == Team &&
        thisTagPlayer.GetJail() == Self)
      nPlayersJailed++;
  
  return nPlayersJailed;
  }


// ============================================================================
// CountPlayersTotal
//
// Counts the total number of players that are in this jail.
// ============================================================================

function int CountPlayersTotal() {

  local int nPlayersJailed;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Self)
      nPlayersJailed++;
  
  return nPlayersJailed;
  }


// ============================================================================
// Release
//
// Releases the given team unless the release is already active. Can be called
// only in state Waiting and logs a warning otherwise.
// ============================================================================

function Release(TeamInfo Team, optional Controller ControllerInstigator) {

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
        if (Jailbreak(Level.Game).CanFireEvent(Tag, True)) {
          if (ControllerInstigator != None)
            BroadcastLocalizedMessage(MessageClass, 200, ControllerInstigator.PlayerReplicationInfo, , Team);
          JBBotTeam(TeamGame(Level.Game).Teams[0].AI).NotifyReleaseTeam(Tag, Team, ControllerInstigator);
          JBBotTeam(TeamGame(Level.Game).Teams[1].AI).NotifyReleaseTeam(Tag, Team, ControllerInstigator);
          }

        TriggerEvent(GetEventRelease(Team), Self, ControllerInstigator.Pawn);
        }
      
      ListInfoReleaseByTeam[Team.TeamIndex].bIsActive      = True;
      ListInfoReleaseByTeam[Team.TeamIndex].bIsOpening     = True;
      ListInfoReleaseByTeam[Team.TeamIndex].TimeActivation = Level.TimeSeconds;
      ListInfoReleaseByTeam[Team.TeamIndex].TimeReset      = 0.0;  // disabled
      ListInfoReleaseByTeam[Team.TeamIndex].ControllerInstigator = ControllerInstigator;
      
      NotifyJailOpening(Team);
      }

    else {
      CancelRelease(Team);
      }
    }
  
  else {
    Log("Warning: Release for" @ Self @ "should not be called in state" @ GetStateName());
    }
  }


// ============================================================================
// CancelRelease
//
// Cancels a release that has been initiated. Doesn't open the jail doors, but
// marks the release as active and schedules a reset shortly.
// ============================================================================

function CancelRelease(TeamInfo Team) {

  ListInfoReleaseByTeam[Team.TeamIndex].bIsActive      = True;
  ListInfoReleaseByTeam[Team.TeamIndex].bIsOpening     = False;
  ListInfoReleaseByTeam[Team.TeamIndex].TimeActivation = Level.TimeSeconds;
  ListInfoReleaseByTeam[Team.TeamIndex].TimeReset      = Level.TimeSeconds + 2.0;
  ListInfoReleaseByTeam[Team.TeamIndex].ControllerInstigator = None;

// ============================================================================
// NotifyJailOpening
//
// Called when the doors to this jail start opening before NotifyJailOpened is
// called. Disables all GameObjectives that can be used to trigger this jail's
// release and communicates the event to all inmates.
// ============================================================================

function NotifyJailOpening(TeamInfo Team) {

  local GameObjective firstObjective;
  local GameObjective thisObjective;
  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;

  firstObjective = UnrealTeamInfo(Team).AI.Objectives;
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (thisObjective.Event == Tag &&
        thisObjective.DefenderTeamIndex != Team.TeamIndex)
      thisObjective.bDisabled = True;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailOpening();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
  if (Jailbreak(Level.Game).firstJBGameRules != None)
    Jailbreak(Level.Game).firstJBGameRules.NotifyJailOpening(Self);

// ============================================================================
// NotifyJailOpened
//
// Called when the doors to this jail have fully opened. Communicates that
// event to all inmates.
// ============================================================================

function NotifyJailOpened(TeamInfo Team) {

  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailOpened();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
  if (Jailbreak(Level.Game).firstJBGameRules != None)
    Jailbreak(Level.Game).firstJBGameRules.NotifyJailOpened(Self);

// ============================================================================
// NotifyJailEntered
//
// Called when a player enters this jail from an arena or from freedom. If the
// jail doors are currently open, notifies the player about it.
// ============================================================================

function NotifyJailEntered(JBTagPlayer TagPlayer) {

  local int iTeam;
  local JBGameRules firstJBGameRules;
  
  
  if (InfoReleaseByTeam[iTeam].bIsActive &&
      InfoReleaseByTeam[iTeam].TimeReset == 0.0) {
  if (ListInfoReleaseByTeam[iTeam].bIsActive) {
    if (!InfoReleaseByTeam[iTeam].bIsOpening)
      TagPlayer.NotifyJailOpened();
    if (!ListInfoReleaseByTeam[iTeam].bIsOpening)

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
  if (Jailbreak(Level.Game).firstJBGameRules != None)
    Jailbreak(Level.Game).firstJBGameRules.NotifyPlayerJailed(TagPlayer);

// ============================================================================
// NotifyJailLeft
//
// Called when a player left this jail for an arena or for freedom.
// ============================================================================

function NotifyJailLeft(JBTagPlayer TagPlayer) {

  local JBGameRules firstJBGameRules;

  if (Jailbreak(Level.Game).firstJBGameRules != None)
    Jailbreak(Level.Game).firstJBGameRules.NotifyPlayerReleased(TagPlayer, Self);

// ============================================================================
// NotifyJailClosed
//
// Called when this jail is closed. Communicates that event to all inmates.
// ============================================================================

function NotifyJailClosed(TeamInfo Team) {

  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
  firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailClosed();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
  if (Jailbreak(Level.Game).firstJBGameRules != None)
    Jailbreak(Level.Game).firstJBGameRules.NotifyJailClosed(Self);

// ============================================================================
// ResetObjectives
//
// Resets all objectives associated with this jail for the given team unless
// the release for another jail listening to the same event is still active.
// Resets all objectives associated with this jail for the given team.
function ResetObjectives(TeamInfo Team) {

  local GameObjective firstObjective;
  local GameObjective thisObjective;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (thisObjective.Event == Tag &&
        thisObjective.DefenderTeamIndex != Team.TeamIndex &&
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

  if (IsInState('ExecutionRunning') ||
      IsInState('ExecutionFallback')) {

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
        ExecutePlayer(thisTagPlayer.GetController());
    
        thisTagPlayer.GetController().Pawn.GibbedBy(None);
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
  // triggered by a defender. Otherwise releases the triggering
  // player's team.
  // ================================================================

  event Trigger(Actor ActorOther, Pawn PawnInstigator) {

    local Controller ControllerInstigator;
    local GameObjective firstObjective;
    local GameObjective thisObjective;
    local GameObjective ObjectiveRelease;
    local TeamInfo TeamRelease;
    local JBGameRules firstJBGameRules;


    if (ObjectiveRelease != None)
      TeamRelease = TeamGame(Level.Game).OtherTeam(TeamGame(Level.Game).Teams[ObjectiveRelease.DefenderTeamIndex]);
    else if (PawnInstigator != None)
      TeamRelease = PawnInstigator.GetTeam();
    
    if (TeamRelease != None) {
      if (Trigger(ActorOther) != None) {
    if (TeamRelease == None)
      return;
    
    if (Trigger(ActorOther) != None) {
      firstObjective = UnrealTeamInfo(TeamRelease).AI.Objectives;
      for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
        if (thisObjective.DefenderTeamIndex != TeamRelease.TeamIndex &&
            JBGameObjective(thisObjective) != None &&
            JBGameObjective(thisObjective).TriggerRelease == ActorOther)
          ObjectiveRelease = thisObjective;
      }

    if (Jailbreak(Level.Game).firstJBGameRules == None ||
        Jailbreak(Level.Game).firstJBGameRules.CanRelease(TeamRelease, PawnInstigator, ObjectiveRelease)) {
  
      firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
      Release(TeamRelease, ControllerInstigator);
    CancelRelease(TeamRelease);
    }
    else {
      CancelRelease(TeamRelease);
      }

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
    
    for (iTeam = 0; iTeam < ArrayCount(InfoReleaseByTeam); iTeam++) {
      Team = TeamGame(Level.Game).Teams[iTeam];
    for (iTeam = 0; iTeam < ArrayCount(ListInfoReleaseByTeam); iTeam++) {
      if (!InfoReleaseByTeam[iTeam].bIsActive)
        continue;
      if (!ListInfoReleaseByTeam[iTeam].bIsActive)
      if (InfoReleaseByTeam[iTeam].bIsOpening) {
        if (IsReleaseOpen(Team)) {
      if (ListInfoReleaseByTeam[iTeam].bIsOpening) {
          NotifyJailOpened(Team);
          ListInfoReleaseByTeam[iTeam].bIsOpening = False;
        }
      
      else if (IsReleaseClosed(Team)) {
        if (InfoReleaseByTeam[iTeam].TimeReset == 0.0) {
          InfoReleaseByTeam[iTeam].TimeReset = Level.TimeSeconds + 0.5;
        if (ListInfoReleaseByTeam[iTeam].TimeReset == 0.0) {
          ListInfoReleaseByTeam[iTeam].TimeReset = Level.TimeSeconds + 0.5;

        else if (InfoReleaseByTeam[iTeam].TimeReset < Level.TimeSeconds) {
          InfoReleaseByTeam[iTeam].bIsActive  = False;
        else if (ListInfoReleaseByTeam[iTeam].TimeReset < Level.TimeSeconds) {
          ListInfoReleaseByTeam[iTeam].bIsActive  = False;
          ListInfoReleaseByTeam[iTeam].bIsOpening = False;
          ListInfoReleaseByTeam[iTeam].TimeActivation = 0.0;
          ListInfoReleaseByTeam[iTeam].TimeReset      = 0.0;
          ListInfoReleaseByTeam[iTeam].ControllerInstigator = None;
        }
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
  
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    firstTagPlayer = JBReplicationInfoGame(Level.Game.GameReplicationInfo).firstTagPlayer;
        ExecutePlayer(thisTagPlayer.GetController());
      if (thisTagPlayer.IsInJail() &&
          thisTagPlayer.GetController().Pawn != None)
        thisTagPlayer.GetController().Pawn.GibbedBy(None);

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

  return ListInfoReleaseByTeam[Team.TeamIndex].bIsActive; }
  return InfoReleaseByTeam[Team.TeamIndex].ControllerInstigator; }
function float GetReleaseTime(TeamInfo Team) {
  return ListInfoReleaseByTeam[Team.TeamIndex].ControllerInstigator; }

  return ListInfoReleaseByTeam[Team.TeamIndex].TimeActivation; }
// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  MessageClass = Class'JBLocalMessage';

  ExecutionDelayCommit   = 1.0;
  ExecutionDelayFallback = 2.0;
  ExecutionDelayCommit   = 2.0;
  ExecutionDelayFallback = 4.0;
  TagAttachVolumes = None;
  
  Texture = Texture'JBInfoJail';
  bAlwaysRelevant = True;
  RemoteRole = ROLE_SimulatedProxy;
  }