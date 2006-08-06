// ============================================================================
// JBInfoJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoJail.uc,v 1.43 2006-07-13 20:55:02 jrubzjeknf Exp $
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

var(Events) name EventExecutionInit;    // event fired when camera activated
var(Events) name EventExecutionCommit;  // event fired when execution starts
var(Events) name EventExecutionEnd;     // event fired when execution finished
var(Events) name EventReleaseRed;       // event fired to release red team
var(Events) name EventReleaseBlue;      // event fired to release blue team

var() float ExecutionDelayCommit;       // delay between camera and execution
var() float ExecutionDelayFallback;     // delay between execution and gibbing

var() name TagAttachVolumes;            // tag of attached volumes
var() name TagAttachZones;              // tag of attached zones


// ============================================================================
// Types
// ============================================================================

struct TInfoRelease
{
  var bool bIsOpening;                  // release doors are opening
  var float TimeActivation;             // time of release activation
  var float TimeReset;                  // time of release switch reset
  var Controller ControllerInstigator;  // player activating the release
  var array<Mover> ListMover;           // movers opening for this event
};


// ============================================================================
// Variables
// ============================================================================

var JBInfoJail nextJail;

var private TInfoRelease InfoReleaseByTeam[2];  // release state for each team
var private array<Volume> ListVolume;           // volumes attached to jail
var private array<NavigationPoint> ListNavigationPointExit;  // exit points

var private bool bIsRedActive;
var private bool bIsBlueActive;
var private bool bRedJammed;                   // red can't be released
var private bool bBlueJammed;                  // blue can't be released
var private bool bForcedReleaseRed;            // red can be released even if it's jammed
var private bool bForcedReleaseBlue;           // blue can be released even if it's jammed


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if(Role == ROLE_Authority)
    bIsRedActive, bIsBlueActive;
}


// ============================================================================
// PostBeginPlay
//
// Initializes the ListVolume array with references to all volumes attached to
// this jail, and the ListMover arrays with references to all movers that are
// opened by release events.
// ============================================================================

event PostBeginPlay()
{
  local Volume thisVolume;

  if (TagAttachVolumes != '' &&
      TagAttachVolumes != 'None')
    foreach AllActors(Class'Volume', thisVolume, TagAttachVolumes)
      ListVolume[ListVolume.Length] = thisVolume;

  FindReleases(EventReleaseRed,  InfoReleaseByTeam[0].ListMover);
  FindReleases(EventReleaseBlue, InfoReleaseByTeam[1].ListMover);
}


// ============================================================================
// Tick
//
// If this JBInfoJail actor is not yet registered in the global JBInfoJail
// linked list client-side yet, adds it to it.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local JBGameReplicationInfo InfoGame;

  if (Role < ROLE_Authority) {
    InfoGame = JBGameReplicationInfo(Level.GetLocalPlayerController().GameReplicationInfo);
    if (InfoGame == None)
      return;

    firstJail = InfoGame.firstJail;
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
      if (thisJail == Self)
        return;

    nextJail = InfoGame.firstJail;
    InfoGame.firstJail = Self;
  }

  Disable('Tick');
}


// ============================================================================
// FindReleases
//
// Adds movers triggered by the given tag to the given array unless they are
// present there already. Then recursively finds other movers triggered by the
// found mover's OpeningEvent and adds them too.
// ============================================================================

function FindReleases(name TagMover, out array<Mover> ListMover)
{
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

    FindReleases(thisMover.Event,        ListMover);
    FindReleases(thisMover.OpeningEvent, ListMover);
    FindReleases(thisMover.OpenedEvent,  ListMover);
    FindReleases(thisMover.ClosingEvent, ListMover);
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

function array<NavigationPoint> FindExits()
{
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
// CanReleaseTeam
//
// Checks whether this jail can release players of the given team.
// ============================================================================

function bool CanReleaseTeam(TeamInfo Team)
{
  local Actor thisActor;

  if (GetEventRelease(Team) == '')
    return False;

  foreach DynamicActors(Class'Actor', thisActor, GetEventRelease(Team))
    return True;

  return False;
}


// ============================================================================
// CanReleaseBy
//
// Checks and returns whether the given player can trigger a release for the
// given team.
// ============================================================================

function bool CanReleaseBy(Controller Controller, TeamInfo Team)
{
  local JBTagPlayer TagPlayer;

  if (Controller                       == None ||
      Controller.PlayerReplicationInfo == None)
    return False;

  if (      Controller.Pawn  == None ||
      xPawn(Controller.Pawn) == None)
    return False;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(Controller.PlayerReplicationInfo);
  return (TagPlayer != None &&
          TagPlayer.IsFree() &&
         !IsJammed(Team.TeamIndex));
}


// ============================================================================
// GetEventRelease
//
// Returns the value of EventReleaseRed or EventReleaseBlue depending on the
// given team index.
// ============================================================================

function name GetEventRelease(TeamInfo Team)
{
  switch (Team.TeamIndex) {
    case 0:  return EventReleaseRed;
    case 1:  return EventReleaseBlue;
  }
}


// ============================================================================
// IsReleaseMoverOpen
//
// Checks and returns whether any release movers of this jail for the given
// team are currently fully open.
// ============================================================================

function bool IsReleaseMoverOpen(TeamInfo Team)
{
  local int iMover;
  local TInfoRelease InfoRelease;

  InfoRelease = InfoReleaseByTeam[Team.TeamIndex];

  for (iMover = 0; iMover < InfoRelease.ListMover.Length; iMover++)
    if (!InfoRelease.ListMover[iMover].bClosed &&
        !InfoRelease.ListMover[iMover].bInterpolating)
      return True;  // neither closed nor interpolating, thus open

  return False;
}


// ============================================================================
// IsReleaseMoverClosed
//
// Checks and returns whether all release movers of this jail for the given
// team are fully closed.
// ============================================================================

function bool IsReleaseMoverClosed(TeamInfo Team)
{
  local int iMover;
  local TInfoRelease InfoRelease;

  InfoRelease = InfoReleaseByTeam[Team.TeamIndex];

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

function bool ContainsActor(Actor Actor)
{
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

function int CountPlayers(TeamInfo Team)
{
  local int nPlayersJailed;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
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

function int CountPlayersTotal()
{
  local int nPlayersJailed;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Self)
      nPlayersJailed++;

  return nPlayersJailed;
}


// ============================================================================
// Release
//
// Releases the given team unless the release is already active or has been
// jammed. Can be called only in state Waiting and logs a warning otherwise.
// ============================================================================

function Release(TeamInfo Team, optional Controller ControllerInstigator)
{
  local Controller thisController;
  local PlayerReplicationInfo PlayerReplicationInfoInstigator;
  local JBTagPlayer TagPlayer;

  if (IsInState('Waiting')) {
    if (GetReleaseActive(Team.TeamIndex) ||
        (IsJammed(Team.TeamIndex) &&
        !IsForcedRelease(Team.TeamIndex)))
      return;

    if (ControllerInstigator != None &&
        ControllerInstigator.PlayerReplicationInfo.Team != Team) {
      Log("Warning:" @ ControllerInstigator.PlayerReplicationInfo.PlayerName @ "on team" @
          ControllerInstigator.PlayerReplicationInfo.Team.TeamIndex @ "attempted to release team" @ Team.TeamIndex);
      return;
    }

    if (CanReleaseTeam(Team)) {
      if (Jailbreak(Level.Game).CanFireEvent(GetEventRelease(Team), True)) {
        if (Jailbreak(Level.Game).CanFireEvent(Tag, True)) {
          if (ControllerInstigator != None)
            PlayerReplicationInfoInstigator = ControllerInstigator.PlayerReplicationInfo;

          if (CountPlayers(Team) > 0)
            for (thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
              if (PlayerController(thisController) != None) {
                TagPlayer = Class'JBTagPlayer'.Static.FindFor(thisController.PlayerReplicationInfo);
                if (TagPlayer           == None ||
                    TagPlayer.GetTeam() != Team ||
                    TagPlayer.GetJail() == None ||
                    TagPlayer.GetJail() == Self)
                  Level.Game.BroadcastHandler.BroadcastLocalized(
                    Self, PlayerController(thisController), MessageClass, 200, PlayerReplicationInfoInstigator, , Team);
              }

          JBBotTeam(TeamGame(Level.Game).Teams[0].AI).NotifyReleaseTeam(Tag, Team, ControllerInstigator);
          JBBotTeam(TeamGame(Level.Game).Teams[1].AI).NotifyReleaseTeam(Tag, Team, ControllerInstigator);
        }

        if (ControllerInstigator != None)
               TriggerEventRelease(GetEventRelease(Team), Self, ControllerInstigator.Pawn);
          else TriggerEventRelease(GetEventRelease(Team), Self, None);
      }

      SetReleaseActive(Team.TeamIndex, True);
      InfoReleaseByTeam[Team.TeamIndex].bIsOpening     = True;
      InfoReleaseByTeam[Team.TeamIndex].TimeActivation = Level.TimeSeconds;
      InfoReleaseByTeam[Team.TeamIndex].TimeReset      = 0.0;  // disabled
      InfoReleaseByTeam[Team.TeamIndex].ControllerInstigator = ControllerInstigator;

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
// TriggerEventRelease
//
// Works like TriggerEvent, but hides the instigator from movers to avoid
// getting team kills when a jail door crushes a teammate.
// ============================================================================

function TriggerEventRelease(name Event, Actor ActorSender, Pawn PawnInstigator)
{
  local Actor thisActor;
  local NavigationPoint thisNavigationPoint;

  if (Event == '')
    return;

  foreach DynamicActors(Class'Actor', thisActor, Event)
    if (Mover(thisActor) == None)
           thisActor.Trigger(ActorSender, PawnInstigator);
      else thisActor.Trigger(ActorSender, None);  // hide instigator from mover

  for (thisNavigationPoint = Level.NavigationPointList;
       thisNavigationPoint != None;
       thisNavigationPoint = thisNavigationPoint.NextNavigationPoint)
    if (thisNavigationPoint.bStatic &&
        thisNavigationPoint.Tag == Event)
      thisNavigationPoint.Trigger(ActorSender, PawnInstigator);
}


// ============================================================================
// CancelRelease
//
// Cancels a release that has been initiated. If the release did not start yet,
// doesn't open the jail doors, but marks the release as active and schedules
// a reset shortly; otherwise just resets the internal release state and fires
// the remaining notification events in the correct order as if the jail doors
// had closed.
// ============================================================================

function CancelRelease(TeamInfo Team)
{
  if (GetReleaseActive(Team.TeamIndex)) {
    if (InfoReleaseByTeam[Team.TeamIndex].bIsOpening)
      NotifyJailOpened(Team);

    SetReleaseActive(Team.TeamIndex, False);
    InfoReleaseByTeam[Team.TeamIndex].bIsOpening = False;
    InfoReleaseByTeam[Team.TeamIndex].TimeReset  = 0.0;  // disable

    NotifyJailClosed(Team);
    ResetObjectives(Team);
  }

  else {
    SetReleaseActive(Team.TeamIndex, True);
    InfoReleaseByTeam[Team.TeamIndex].bIsOpening     = False;
    InfoReleaseByTeam[Team.TeamIndex].TimeActivation = Level.TimeSeconds;
    InfoReleaseByTeam[Team.TeamIndex].TimeReset      = Level.TimeSeconds + 2.0;
  }

  InfoReleaseByTeam[Team.TeamIndex].ControllerInstigator = None;
}


// ============================================================================
// NotifyJailOpening
//
// Called when the doors to this jail start opening before NotifyJailOpened is
// called. Disables all GameObjectives that can be used to trigger this jail's
// release and communicates the event to all inmates.
// ============================================================================

function NotifyJailOpening(TeamInfo Team)
{
  local GameObjective firstObjective;
  local GameObjective thisObjective;
  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (!IsJammed(Team.TeamIndex)) //dont play animation if the jail is jammed.
  {
    firstObjective = UnrealTeamInfo(Team).AI.Objectives;
    for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
      if (thisObjective.Event == Tag &&
          thisObjective.DefenderTeamIndex != Team.TeamIndex)
        thisObjective.bDisabled = True;
  }

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Self &&
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailOpening();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    firstJBGameRules.NotifyJailOpening(Self, Team);
}


// ============================================================================
// NotifyJailOpened
//
// Called when the doors to this jail have fully opened. Communicates that
// event to all inmates.
// ============================================================================

function NotifyJailOpened(TeamInfo Team)
{
  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Self &&
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailOpened();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    firstJBGameRules.NotifyJailOpened(Self, Team);
}


// ============================================================================
// NotifyJailEntered
//
// Called when a player enters this jail from an arena or from freedom. If the
// jail doors are currently open, notifies the player about it.
// ============================================================================

function NotifyJailEntered(JBTagPlayer TagPlayer)
{
  local int iTeam;
  local JBGameRules firstJBGameRules;

  iTeam = TagPlayer.GetTeam().TeamIndex;

  if (GetReleaseActive(iTeam) &&
      InfoReleaseByTeam[iTeam].TimeReset == 0.0) {

    TagPlayer.NotifyJailOpening();

    if (!InfoReleaseByTeam[iTeam].bIsOpening)
      TagPlayer.NotifyJailOpened();
  }

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    firstJBGameRules.NotifyPlayerJailed(TagPlayer);
}


// ============================================================================
// NotifyJailLeft
//
// Called when a player left this jail for an arena or for freedom.
// ============================================================================

function NotifyJailLeft(JBTagPlayer TagPlayer)
{
  local JBGameRules firstJBGameRules;

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    firstJBGameRules.NotifyPlayerReleased(TagPlayer, Self);
}


// ============================================================================
// NotifyJailClosed
//
// Called when this jail is closed. Communicates that event to all inmates.
// ============================================================================

function NotifyJailClosed(TeamInfo Team)
{
  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Self &&
        thisTagPlayer.GetTeam() == Team)
      thisTagPlayer.NotifyJailClosed();

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    firstJBGameRules.NotifyJailClosed(Self, Team);
}


// ============================================================================
// ResetObjectives
//
// Resets all objectives associated with this jail for the given team unless
// the release for another jail listening to the same event is still active.
// ============================================================================

function ResetObjectives(TeamInfo Team)
{
  local GameObjective firstObjective;
  local GameObjective thisObjective;
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;

  firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (thisJail != Self &&
        thisJail.Tag == Tag &&
        thisJail.IsReleaseActive(Team))
      return;

  firstObjective = UnrealTeamInfo(Team).AI.Objectives;
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (thisObjective.Event == Tag &&
        thisObjective.DefenderTeamIndex != Team.TeamIndex &&
        thisObjective.bDisabled)
      thisObjective.Reset();
}


// ============================================================================
// ActivateCameraFor
//
// Activates the attached camera or camera array for the given player.
// ============================================================================

function ActivateCameraFor(Controller Controller)
{
  local JBCamera thisCamera;

  if (PlayerController(Controller) != None)
    foreach DynamicActors(Class'JBCamera', thisCamera, Event)
      thisCamera.TriggerForController(Self, Controller);
}


// ============================================================================
// ExecutePlayer
//
// Executes the given player. Used for fallback execution.
// ============================================================================

function ExecutePlayer(Controller Controller)
{
  if (Controller.Pawn != None)
    Controller.Pawn.Died(None, Class'Suicided', Controller.Pawn.Location);
}


// ============================================================================
// ExecutionInit
//
// Initiates the execution sequence. Can be called only in state Waiting and
// logs a warning otherwise.
// ============================================================================

function ExecutionInit()
{
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

function ExecutionEnd()
{
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('ExecutionRunning') ||
      IsInState('ExecutionFallback')) {

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetJail() == Self)
        ExecutePlayer(thisTagPlayer.GetController());

    if (Jailbreak(Level.Game).CanFireEvent(EventExecutionEnd, True))
      TriggerEvent(EventExecutionEnd, Self, None);

    GotoState('Waiting');
  }

  else {
    Log("Warning: Called ExecutionEnd for" @ Self @ "in state" @ GetStateName());
  }
}


// ============================================================================
// GetReleaseActive
//
// Returns whether or not the specified team is currently being released.
// ============================================================================

simulated function bool GetReleaseActive(int TeamIndex)
{
  switch (TeamIndex) {
    case 0: return bIsRedActive;
    case 1: return bIsBlueActive;
    default: return false;
  }
}

// ============================================================================
// SetReleaseActive
// ============================================================================

simulated protected function SetReleaseActive(int TeamIndex, bool Value)
{
  switch (TeamIndex) {
    case 0: bIsRedActive = Value; break;
    case 1: bIsBlueActive = Value; break;
  }
}


// ============================================================================
// Jam
//
// Jams the jail for the given team. A regular release isn't possible any more.
// ============================================================================

function Jam(int TeamIndex)
{
  if (GetReleaseActive(TeamIndex))
    CancelRelease(Jailbreak(Level.Game).Teams[TeamIndex]); // Cancel any ongoing release

  switch (TeamIndex) {
    case 0: bRedJammed = True; break;
    case 1: bBlueJammed = True; break;
  }

  JamResetObjectives(TeamIndex);
}


// ============================================================================
// UnJam
//
// UnJams the jail for the given team. A regular release is possible again.
// ============================================================================

function UnJam(int TeamIndex)
{
  switch (TeamIndex) {
    case 0: bRedJammed = False; break;
    case 1: bBlueJammed = False; break;
  }

  JamResetObjectives(TeamIndex);
}


// ============================================================================
// JamResetObjectives
//
// Resets the GameObjectives that trigger this JBInfoJail.
// ============================================================================

protected function JamResetObjectives(int TeamIndex)
{
  local GameObjective firstObjective;
  local GameObjective thisObjective;

  firstObjective = Jailbreak(Level.Game).Teams[TeamIndex].AI.Objectives;

  // Find all objectives that trigger this JBInfoJail, then reset them
  for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
    if (thisObjective.Event == Tag &&
        thisObjective.DefenderTeamIndex != TeamIndex)
      thisObjective.Reset();
}


// ============================================================================
// IsJammed
//
// Returns if this jail is jammed for the given team.
// ============================================================================

function bool IsJammed(int TeamIndex)
{
  switch (TeamIndex) {
    case 0: return bRedJammed;
    case 1: return bBlueJammed;
    default: return False;
  }
}


// ============================================================================
// IsForcedRelease
//
// Returns if the release was forced for the given team.
// ============================================================================

function bool IsForcedRelease(int TeamIndex)
{
  switch (TeamIndex) {
    case 0: return bForcedReleaseRed;
    case 1: return bForcedReleaseBlue;
    default: return False;
  }
}


// ============================================================================
// ForceRelease
//
// Releases even though the jails are jammed. JBGameRules is first consulted
// before actually releasing. Returns if the team was actually released.
// ============================================================================

function bool ForceRelease(TeamInfo Team, optional Controller ControllerInstigator)
{
  local JBGameRules firstJBGameRules;
  local bool        bAllowForcedRelease;

  if (!IsInState('Waiting') ||
       GetReleaseActive(Team.TeamIndex))
    return False;

  if(!IsJammed(Team.TeamIndex)) {
    Release(Team, ControllerInstigator);
    return True;
  }

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None)
    bAllowForcedRelease = firstJBGameRules.AllowForcedRelease(Self, Team, ControllerInstigator);

  if (bAllowForcedRelease) {
    switch (Team.TeamIndex) {
      case 0: bForcedReleaseRed  = True; Release(Team, ControllerInstigator); bForcedReleaseRed  = False; break;
      case 1: bForcedReleaseBlue = True; Release(Team, ControllerInstigator); bForcedReleaseBlue = False; break;
    }
  }

  return bAllowForcedRelease;
}


// ============================================================================
// ObjectiveIsJammed
//
// Checks if all the JBInfoJails, that can be triggered by the given
// GameObjective, are jammed. If so, the GameObjective cannot be used and
// is therefore ignored.
// ============================================================================

static function bool ObjectiveIsJammed(GameObjective GameObjective, int TeamIndex)
{
  local JBInfoJail firstJail;
  local JBInfoJail thisJail;
  local bool       bConnected; // At least one jail can be triggered by the GameObjective.

  if (GameObjective != None &&
      JBGameReplicationInfo(GameObjective.Level.Game.GameReplicationInfo) != None)
    firstJail = JBGameReplicationInfo(GameObjective.Level.Game.GameReplicationInfo).firstJail;

  for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail)
    if (GameObjective.Event == thisJail.Tag) {
      bConnected = True;
      if (!thisJail.IsJammed(TeamIndex))
        return False;
    }

  return bConnected;
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

  event BeginState()
  {
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

  event Trigger(Actor ActorOther, Pawn PawnInstigator)
  {
    local Controller ControllerInstigator;
    local GameObjective firstObjective;
    local GameObjective thisObjective;
    local GameObjective ObjectiveRelease;
    local TeamInfo TeamRelease;
    local JBGameRules firstJBGameRules;

    ObjectiveRelease = GameObjective(ActorOther);

    if (ObjectiveRelease != None)
      TeamRelease = TeamGame(Level.Game).OtherTeam(TeamGame(Level.Game).Teams[ObjectiveRelease.DefenderTeamIndex]);
    else if (PawnInstigator != None)
      TeamRelease = PawnInstigator.GetTeam();

    if (TeamRelease != None) {
      if (Trigger(ActorOther) != None) {
        firstObjective = UnrealTeamInfo(TeamRelease).AI.Objectives;
        for (thisObjective = firstObjective; thisObjective != None; thisObjective = thisObjective.NextObjective)
          if (thisObjective.DefenderTeamIndex != TeamRelease.TeamIndex &&
              JBGameObjective(thisObjective) != None &&
              JBGameObjective(thisObjective).TriggerRelease == ActorOther)
            ObjectiveRelease = thisObjective;
      }

      if (PawnInstigator != None)
        ControllerInstigator = PawnInstigator.Controller;

      firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
      if (Level.Game.IsInState('MatchInProgress') &&
          CanReleaseBy(ControllerInstigator, TeamRelease) &&
          (firstJBGameRules == None ||
           firstJBGameRules.CanRelease(TeamRelease, PawnInstigator, ObjectiveRelease))) {
        Release(TeamRelease, ControllerInstigator);
        return;
      }
    }

    CancelRelease(TeamRelease);
  }


  // ================================================================
  // Timer
  //
  // For each team whose release is active, checks whether the jail
  // doors have been closed already and, if so, resets that team's
  // release information.
  // ================================================================

  event Timer()
  {
    local int iTeam;
    local TeamInfo Team;

    for (iTeam = 0; iTeam < ArrayCount(InfoReleaseByTeam); iTeam++) {
      Team = TeamGame(Level.Game).Teams[iTeam];

      if (!GetReleaseActive(iTeam))
        continue;

      if (InfoReleaseByTeam[iTeam].bIsOpening) {
        if (IsReleaseMoverOpen(Team)) {
          InfoReleaseByTeam[iTeam].bIsOpening = False;
          NotifyJailOpened(Team);
        }
      }

      else if (IsReleaseMoverClosed(Team)) {
        if (InfoReleaseByTeam[iTeam].TimeReset == 0.0) {
          InfoReleaseByTeam[iTeam].TimeReset = Level.TimeSeconds + 0.5;
          NotifyJailClosed(Team);
        }

        else if (InfoReleaseByTeam[iTeam].TimeReset < Level.TimeSeconds) {
          SetReleaseActive(Team.TeamIndex, False);
          InfoReleaseByTeam[iTeam].bIsOpening = False;
          InfoReleaseByTeam[iTeam].TimeActivation = 0.0;
          InfoReleaseByTeam[iTeam].TimeReset      = 0.0;
          InfoReleaseByTeam[iTeam].ControllerInstigator = None;
          ResetObjectives(Team);
        }
      }
    }
  }


  // ================================================================
  // EndState
  //
  // Cancels all ongoing releases and stops the timer.
  // ================================================================

  event EndState()
  {
    local int iTeam;

    for (iTeam = 0; iTeam < ArrayCount(InfoReleaseByTeam); iTeam++)
      if (GetReleaseActive(iTeam))
        CancelRelease(TeamGame(Level.Game).Teams[iTeam]);

    SetTimer(0.0, False);
  }

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

  event BeginState()
  {
    SetTimer(1.0, True);
  }


  // ================================================================
  // Timer
  //
  // Periodically checks for players remaining in jail and gibs any
  // it finds.
  // ================================================================

  event Timer()
  {
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.IsInJail())
        ExecutePlayer(thisTagPlayer.GetController());
  }


  // ================================================================
  // EndState
  //
  // Stops the timer.
  // ================================================================

  event EndState()
  {
    SetTimer(0.0, False);
  }

} // state ExecutionFallback


// ============================================================================
// Accessors
// ============================================================================

simulated function bool IsReleaseActive(TeamInfo Team) {
  return GetReleaseActive(Team.TeamIndex); }

function bool IsReleaseOpening(TeamInfo Team) {
  return GetReleaseActive(Team.TeamIndex) &&
         InfoReleaseByTeam[Team.TeamIndex].bIsOpening; }
function bool IsReleaseOpen(TeamInfo Team) {
  return GetReleaseActive(Team.TeamIndex) &&
        !InfoReleaseByTeam[Team.TeamIndex].bIsOpening &&
         InfoReleaseByTeam[Team.TeamIndex].TimeReset == 0.0; }

function Controller GetReleaseInstigator(TeamInfo Team) {
  return InfoReleaseByTeam[Team.TeamIndex].ControllerInstigator; }
function float GetReleaseTime(TeamInfo Team) {
  return InfoReleaseByTeam[Team.TeamIndex].TimeActivation; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  MessageClass = Class'JBLocalMessage';

  ExecutionDelayCommit   = 1.0;
  ExecutionDelayFallback = 2.0;

  TagAttachZones   = Auto;
  TagAttachVolumes = None;

  Texture = Texture'JBInfoJail';
  bAlwaysRelevant = True;
  RemoteRole = ROLE_SimulatedProxy;
}
