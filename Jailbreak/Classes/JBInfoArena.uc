// ============================================================================
// JBInfoArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoArena.uc,v 1.11 2003/02/17 21:18:20 mychaeel Exp $
//
// Holds information about an arena. Some design inconsistencies in here: Part
// of the code could do well enough with any number of teams, other parts need
// to limit it to red and blue due to restrictions of the underlying game.
// ============================================================================


class JBInfoArena extends Info
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBInfoArena.pcx mips=off masked=on


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    TimeCountdownStart, TimeCountdownTie;
  }


// ============================================================================
// Properties
// ============================================================================

var(Events) name TagRequest;
var(Events) name TagExclude;

var(Events) name EventStart;
var(Events) name EventTied;
var(Events) name EventWonRed;
var(Events) name EventWonBlue;
var(Events) name EventWaiting;

var() float MaxCombatTime;

var() name TagAttachStarts;
var() name TagAttachPickups;


// ============================================================================
// Variables
// ============================================================================

var JBInfoArena nextArena;                   // next arena in chain

var private JBProbeEvent ProbeEventRequest;  // event probe for match requests
var private JBProbeEvent ProbeEventExclude;  // event probe for exclusions

var private array<Controller> ListControllerExclude;  // excluded players

var private float TimeCountdownStart;        // countdown until match starts
var private float TimeCountdownTie;          // countdown until match is tied

var private PlayerReplicationInfo PlayerReplicationInfoRed;   // for messages
var private PlayerReplicationInfo PlayerReplicationInfoBlue;  // for messages


// ============================================================================
// PostBeginPlay
//
// Spawns and sets up event probes for TagRequest and TagExclude.
// ============================================================================

event PostBeginPlay() {

  if (TagRequest != '' &&
      TagRequest != 'None') {
    ProbeEventRequest = Spawn(Class'JBProbeEvent', Self, TagRequest);
    ProbeEventRequest.OnTrigger   = TriggerRequest;
    ProbeEventRequest.OnUnTrigger = UnTriggerRequest;
    }
  
  if (TagExclude != '' &&
      TagExclude != 'None') {
    ProbeEventExclude = Spawn(Class'JBProbeEvent', Self, TagExclude);
    ProbeEventExclude.OnTrigger   = TriggerExclude;
    ProbeEventExclude.OnUnTrigger = UnTriggerExclude;
    }
  }


// ============================================================================
// Destroyed
//
// Destroys the event probes if they're present.
// ============================================================================

event Destroyed() {

  if (ProbeEventRequest != None) ProbeEventRequest.Destroy();
  if (ProbeEventExclude != None) ProbeEventExclude.Destroy();
  }


// ============================================================================
// ContainsActor
//
// Checks whether the given actor is part of the arena. For Pawn and Controller
// actors, checks whether the associated player is fighting in that arena at
// the moment; for pickups and PlayerStarts, checks whether they're attached to
// this arena by means of the TagAttachPickups and TagAttachStarts properties.
// ============================================================================

function bool ContainsActor(Actor Actor) {

  if (Pickup(Actor) != None)
    if (TagAttachPickups == 'Auto')
      return Actor.Region.ZoneNumber == Region.ZoneNumber;
    else
      return Actor.Tag == TagAttachPickups;
  
  if (NavigationPoint(Actor) != None)
    if (TagAttachStarts == 'Auto')
      return Actor.Region.ZoneNumber == Region.ZoneNumber;
    else
      return Actor.Tag == TagAttachStarts;
  
  if (Controller(Actor) != None &&
      Controller(Actor).PlayerReplicationInfo != None)
    return Class'JBTagPlayer'.Static.FindFor(Controller(Actor).PlayerReplicationInfo).GetArena() == Self;

  if (Pawn(Actor) != None &&
      Pawn(Actor).PlayerReplicationInfo != None)
    return Class'JBTagPlayer'.Static.FindFor(Pawn(Actor).PlayerReplicationInfo).GetArena() == Self;
  
  return False;
  }


// ============================================================================
// CanFight
//
// Checks whether the given player is available for an arena match in this
// arena. Explicit requests or exclusions aren't checked here.
// ============================================================================

function bool CanFight(Controller ControllerCandidate) {

  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(ControllerCandidate.PlayerReplicationInfo);
  if (TagPlayer == None)
    return False;

  if (!TagPlayer.IsInJail() ||
       TagPlayer.IsInArena())
    return False;
  
  if (TagPlayer.GetArenaPending() != None &&
      TagPlayer.GetArenaPending() != Self)
    return False;
  
  if (Jailbreak(Level.Game).firstJBGameRules == None ||
      Jailbreak(Level.Game).firstJBGameRules.CanSendToArena(TagPlayer, Self))
    return True;
  
  return False;
  }


// ============================================================================
// CanStart
//
// Checks whether at least two players have a match pending in this arena, that
// they are ready to fight and in opposing teams.
// ============================================================================

function bool CanStart() {

  local byte bFoundCandidate[2];
  local int nCandidates;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local TeamInfo TeamPlayer;
  
  if (!Level.Game.IsInState('MatchInProgress'))
    return False;
  
  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetArenaPending() == Self && CanFight(thisTagPlayer.GetController())) {
      TeamPlayer = thisTagPlayer.GetTeam();
      if (bFoundCandidate[TeamPlayer.TeamIndex] != 0)
        return False;
      bFoundCandidate[TeamPlayer.TeamIndex] = 1;
      nCandidates++;
      }

  if (nCandidates < 2)
    return False;
  
  return True;
  }


// ============================================================================
// IsExcluded
//
// Checks whether the given player is excluded from arena matches.
// ============================================================================

function bool IsExcluded(Controller ControllerCandidate) {

  local int iController;
  
  for (iController = 0; iController < ListControllerExclude.Length; iController++)
    if (ListControllerExclude[iController] == ControllerCandidate)
      return True;
  
  return False;
  }


// ============================================================================
// ExcludeAdd
//
// Adds the given player to the exclusion list. If a match in this arena is
// currently pending for this player, cancels it.
// ============================================================================

function ExcludeAdd(Controller ControllerCandidate) {

  local JBTagPlayer TagPlayerCandidate;

  if (IsExcluded(ControllerCandidate))
    return;
  
  TagPlayerCandidate = Class'JBTagPlayer'.Static.FindFor(ControllerCandidate.PlayerReplicationInfo);

  if (TagPlayerCandidate.GetArenaRequest() == Self)  
    TagPlayerCandidate.SetArenaRequest(None);
  
  if (TagPlayerCandidate.GetArenaPending() == Self)
    MatchCancel();

  ListControllerExclude[ListControllerExclude.Length] = ControllerCandidate;
  }


// ============================================================================
// ExcludeRemove
//
// Removes the given player from the exclusion list.
// ============================================================================

function ExcludeRemove(Controller ControllerCandidate) {

  local int iController;
  
  for (iController = ListControllerExclude.Length - 1; iController >= 0; iController--)
    if (ListControllerExclude[iController] == ControllerCandidate)
      ListControllerExclude.Remove(iController, 1);
  }


// ============================================================================
// TriggerExclude
//
// Called when an actor triggers this arena by its TagExclude tag. Adds the
// instigator to the exclusion list.
// ============================================================================

function TriggerExclude(Actor ActorOther, Pawn PawnInstigator) {

  if (PawnInstigator.Controller != None)
    ExcludeAdd(PawnInstigator.Controller);
  }


// ============================================================================
// UnTriggerExclude
//
// Called when an actor untriggers this arena by its TagExclude tag. Removes
// the instigator from the exclusion list.
// ============================================================================

function UnTriggerExclude(Actor ActorOther, Pawn PawnInstigator) {

  if (PawnInstigator.Controller != None)
    ExcludeRemove(PawnInstigator.Controller);
  }


// ============================================================================
// TriggerRequest
//
// Called when an actor triggers this arena by its TagRequest tag. Adds an
// arena request for the instigator, provided he or she isn't excluded already.
// ============================================================================

function TriggerRequest(Actor ActorOther, Pawn PawnInstigator) {

  local JBTagPlayer TagPlayer;

  if (PawnInstigator.Controller == None)
    return;

  if (IsExcluded(PawnInstigator.Controller)) {
    Log("Warning:" @ PawnInstigator.PlayerReplicationInfo.PlayerName @ "requests an arena match," @
        "but has been excluded from matches in" @ Self @ "before.");
    return;
    }

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnInstigator.PlayerReplicationInfo);
  TagPlayer.SetArenaRequest(Self);
  }


// ============================================================================
// UnTriggerRequest
//
// Called when an actor untriggers this arena by its TagRequest tag. Removes
// the instigator's arena request for this arena.
// ============================================================================

function UnTriggerRequest(Actor ActorOther, Pawn PawnInstigator) {

  local JBTagPlayer TagPlayer;

  if (PawnInstigator.Controller == None)
    return;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnInstigator.PlayerReplicationInfo);
  if (TagPlayer.GetArenaRequest() == Self)
    TagPlayer.SetArenaRequest(None);
  }


// ============================================================================
// MatchInit
//
// If no other match is in progress or pending, initiates a match countdown
// for the two given combatants. The match will automatically be started after
// a few seconds. Returns whether a match has been initiated or not. Can be
// called only in state Waiting.
// ============================================================================

function bool MatchInit(Controller ControllerCombatantRed, Controller ControllerCombatantBlue) {

  local bool bCanFightRed;
  local bool bCanFightBlue;

  if (IsInState('Waiting')) {
    if (ControllerCombatantRed.PlayerReplicationInfo.Team ==
        ControllerCombatantBlue.PlayerReplicationInfo.Team) {
      Log("Warning: Can't start match in" @ Self @ "because" @
          ControllerCombatantRed.PlayerReplicationInfo.PlayerName @ "and" @
          ControllerCombatantBlue.PlayerReplicationInfo.PlayerName @ "are in the same team");
      return False;
      }
  
    bCanFightRed  = CanFight(ControllerCombatantRed);
    bCanFightBlue = CanFight(ControllerCombatantBlue);
  
    if (!bCanFightRed || !bCanFightBlue) {
      if (!bCanFightRed)
        Log("Warning:" @ ControllerCombatantRed.PlayerReplicationInfo.PlayerName @ "(red) can't fight in" @ Self);
      if (!bCanFightBlue);
        Log("Warning:" @ ControllerCombatantBlue.PlayerReplicationInfo.PlayerName @ "(blue) can't fight in" @ Self);
      return False;
      }
    
    PlayerReplicationInfoRed  = ControllerCombatantRed.PlayerReplicationInfo;
    PlayerReplicationInfoBlue = ControllerCombatantBlue.PlayerReplicationInfo;
    
    Class'JBTagPlayer'.Static.FindFor(PlayerReplicationInfoRed ).SetArenaPending(Self);
    Class'JBTagPlayer'.Static.FindFor(PlayerReplicationInfoBlue).SetArenaPending(Self);
    
    GotoState('MatchCountdown');
    return True;
    }

  else {
    Log("Warning: Can't start match in" @ Self @ "because arena is in state" @ GetStateName());
    return False;
    }
  }


// ============================================================================
// MatchCancel
//
// Cancels a pending match and notifies both candidates of it. Can be called
// only in state MatchCountdown.
// ============================================================================

function MatchCancel() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchCountdown')) {
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArenaPending() == Self)
        thisTagPlayer.SetArenaPending(None);

    TriggerEvent(EventTied, Self, None);
    BroadcastLocalizedMessage(MessageClass, 410, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
    GotoState('Waiting');
    }
  
  else {
    Log("Warning: Can't cancel match in" @ Self @ "because arena is in state" @ GetStateName());
    }
  }


// ============================================================================
// MatchStart
//
// Starts a pending match or cancels it if it cannot be started. Returns
// whether the match was started. Can be called only in state MatchCountdown.
// ============================================================================

function bool MatchStart() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchCountdown')) {
    if (CanStart()) {
      firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
      for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
        if (thisTagPlayer.GetArenaPending() == Self)
          thisTagPlayer.RestartArena(Self);

      Prepare();
  
      TriggerEvent(EventStart, Self, None);
      BroadcastLocalizedMessage(MessageClass, 400, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
      GotoState('MatchRunning');
      
      return True;
      }
    }
  
  else {
    Log("Warning: Can't start match in" @ Self @ "because arena is in state" @ GetStateName());
    return False;
    }
  }


// ============================================================================
// Prepare
//
// Prepares the arena for the upcoming match. Can be overwritten in subclasses
// that need to do additional preparation. The default implementation respawns
// all pickups associated to this arena.
// ============================================================================

function Prepare() {

  local Pickup thisPickup;

  foreach DynamicActors(Class'Pickup', thisPickup)
    if (ContainsActor(thisPickup)) {
      if (thisPickup.PickupBase != None)
        thisPickup.PickupBase.TurnOn();
      thisPickup.GotoState('Pickup');
      }
  }


// ============================================================================
// MatchTie
//
// Cancels an ongoing arena match, notifies both players about it and sends
// them back to jail. Can only be called in state MatchRunning.
// ============================================================================

function MatchTie() {

  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchRunning')) {
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self)
        thisTagPlayer.RestartJail();

    if (Jailbreak(Level.Game).firstJBGameRules != None)
      Jailbreak(Level.Game).firstJBGameRules.NotifyArenaEnd(Self, None);

    TriggerEvent(EventTied, Self, None);
    BroadcastLocalizedMessage(MessageClass, 420, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
    GotoState('Waiting');
    }
  
  else {
    Log("Warning: Can't tie match in" @ Self @ "because arena is in state" @ GetStateName());
    }
  }


// ============================================================================
// MatchFinish
//
// Finishes a match by respawning the winner in freedom and sending all other
// players left in the arena back to jail. Can only be called in state
// MatchFinished.
// ============================================================================

function MatchFinish() {

  local Controller ControllerWinner;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  local JBTagPlayer TagPlayerWinner;

  if (IsInState('MatchFinished')) {
    ControllerWinner = FindWinner();
  
    if (ControllerWinner != None) {
      switch (ControllerWinner.PlayerReplicationInfo.Team.TeamIndex) {
        case 0:
          TriggerEvent(EventWonRed, Self, ControllerWinner.Pawn);
          BroadcastLocalizedMessage(MessageClass, 430, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
          break;

        case 1:
          TriggerEvent(EventWonBlue, Self, ControllerWinner.Pawn);
          BroadcastLocalizedMessage(MessageClass, 430, PlayerReplicationInfoBlue, PlayerReplicationInfoRed, Self);
          break;
        }

      TagPlayerWinner = Class'JBTagPlayer'.Static.FindFor(ControllerWinner.PlayerReplicationInfo);
      TagPlayerWinner.RestartFreedom();
      }
    
    else {
      TriggerEvent(EventTied, Self, None);
      BroadcastLocalizedMessage(MessageClass, 420, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
      }
    
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self)
        thisTagPlayer.RestartJail();

    if (Jailbreak(Level.Game).firstJBGameRules != None)
      Jailbreak(Level.Game).firstJBGameRules.NotifyArenaEnd(Self, TagPlayerWinner);

    GotoState('Waiting');
    }
  
  else {
    Log("Warning: Can't clean up after match in" @ Self @ "because arena is in state" @ GetStateName());
    }
  }


// ============================================================================
// FindWinner
//
// Looks for a winner in the arena. Can be overwritten in subclasses that
// implement their own notion of an arena winner. The default implementation
// selects the last player present in the arena.
// ============================================================================

function Controller FindWinner() {

  local Controller ControllerWinner;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchRunning') ||
      IsInState('MatchFinished')) {
    
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self)
        if (ControllerWinner == None)
          ControllerWinner = thisTagPlayer.GetController();
        else
          return None;

    return ControllerWinner;
    }
  
  else {
    Log("Warning: Can't find winner in" @ Self @ "because arena is in state" @ GetStateName());
    return None;
    }
  }


// ============================================================================
// state Waiting
//
// Arena waits for a match to be triggered.
// ============================================================================

auto state Waiting {

  // ================================================================
  // BeginState
  //
  // Fires the EventWaiting event.
  // ================================================================

  event BeginState() {
  
    TriggerEvent(EventWaiting, Self, None);
    }


  // ================================================================
  // Trigger
  //
  // Selects two players from opposing teams and initiates a match.
  // ================================================================
  
  event Trigger(Actor ActorOther, Pawn PawnInstigator) {
  
    local bool bStarted;
  
    if (Tag == TagRequest) TriggerRequest(ActorOther, PawnInstigator);
    if (Tag == TagExclude) TriggerExclude(ActorOther, PawnInstigator);
  
    if (TagRequest == ''     ||
        TagRequest == 'Auto' ||
        TagRequest == 'None')
      bStarted = MatchInitRandom();
    else
      bStarted = MatchInitRequested();
    
    if (!bStarted)
      TriggerEvent(EventWaiting, Self, None);
    }


  // ================================================================
  // MatchInitRandom
  //
  // Selects random candidates from opposing teams and initiates an
  // arena match for them. Returns whether a match was started.
  // ================================================================

  function bool MatchInitRandom() {
  
    local int iTagPlayer;
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local JBTagPlayer TagPlayerCandidate;
    local JBTagPlayer TagPlayerCandidateByTeam[2];
    local array<JBTagPlayer> ListTagPlayerCandidate;
    local TeamInfo TeamCandidate;

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (CanFight(thisTagPlayer.GetController()) && !IsExcluded(thisTagPlayer.GetController()))
        ListTagPlayerCandidate[ListTagPlayerCandidate.Length] = thisTagPlayer;

    while (ListTagPlayerCandidate.Length > 0) {
      TagPlayerCandidate = ListTagPlayerCandidate[Rand(ListTagPlayerCandidate.Length)];

      TeamCandidate = TagPlayerCandidate.GetTeam();
      TagPlayerCandidateByTeam[TeamCandidate.TeamIndex] = TagPlayerCandidate;
      
      for (iTagPlayer = ListTagPlayerCandidate.Length - 1; iTagPlayer >= 0; iTagPlayer--)
        if (ListTagPlayerCandidate[iTagPlayer].GetTeam() == TeamCandidate)
          ListTagPlayerCandidate.Remove(iTagPlayer, 1);
      }

    if (TagPlayerCandidateByTeam[0] != None &&
        TagPlayerCandidateByTeam[1] != None)
      return MatchInit(TagPlayerCandidateByTeam[0].GetController(),
                       TagPlayerCandidateByTeam[1].GetController());

    return False;
    }
  

  // ================================================================
  // MatchInitRequested
  //
  // Selects candidates from every team that requested a match in
  // this arena, giving those players who issued their request first
  // precedence over others. Returns whether a match was started.
  // ================================================================

  function bool MatchInitRequested() {
  
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local JBTagPlayer TagPlayerCandidateByTeam[2];
    local TeamInfo TeamPlayer;
    
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
      TeamPlayer = thisTagPlayer.GetTeam();

      if (thisTagPlayer.GetArenaRequest() == Self && CanFight(thisTagPlayer.GetController()))
        if (TagPlayerCandidateByTeam[TeamPlayer.TeamIndex] == None ||
            TagPlayerCandidateByTeam[TeamPlayer.TeamIndex].GetArenaRequestTime() > thisTagPlayer.GetArenaRequestTime())
          TagPlayerCandidateByTeam[TeamPlayer.TeamIndex] = thisTagPlayer;
      }

    if (TagPlayerCandidateByTeam[0] != None &&
        TagPlayerCandidateByTeam[1] != None)
      return MatchInit(TagPlayerCandidateByTeam[0].GetController(),
                       TagPlayerCandidateByTeam[1].GetController());

    return False;
    }

  } // state Waiting


// ============================================================================
// state MatchCountdown
//
// Waits for a few seconds while a countdown is displayed, then starts the
// match.
// ============================================================================

state MatchCountdown {

  // ================================================================
  // BroadcastCountdown
  //
  // Notifies all players scheduled for a match in this arena about
  // the countdown.
  // ================================================================

  private function BroadcastCountdown(int nSeconds) {
  
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArenaPending() == Self &&
          PlayerController(thisTagPlayer.GetController()) != None)
        Level.Game.BroadcastHandler.BroadcastLocalized(
          Self,
          PlayerController(thisTagPlayer.GetController()),
          MessageClass,
          Clamp(nSeconds, 1, 3) + 400,
          PlayerReplicationInfoRed,
          PlayerReplicationInfoBlue,
          Self);
    }


  // ================================================================
  // BeginState
  //
  // Starts the timer with an interval of one second and initializes
  // the countdown.
  // ================================================================

  event BeginState() {
  
    TimeCountdownStart = 3.0;
    BroadcastCountdown(TimeCountdownStart + 0.5);
    
    SetTimer(1.0, True);
    }


  // ================================================================
  // Timer
  //
  // Decreases the countdown time. Checks whether both players are
  // still ready to fight and cancels the match otherwise. When the
  // countdown has finished, starts the match.
  // ================================================================

  event Timer() {
  
    TimeCountdownStart -= 1.0;
    
    if (TimeCountdownStart <= 0.0)
      MatchStart();
    else if (CanStart())
      BroadcastCountdown(TimeCountdownStart + 0.5);
    else
      MatchCancel();
    }


  // ================================================================
  // EndState
  //
  // Stops the timer.
  // ================================================================

  event EndState() {
  
    SetTimer(0.0, False);
    }

  } // state MatchCountdown


// ============================================================================
// state MatchRunning
//
// Waits until the maximum combat time has run out, then ties the match. If
// a player wins before that happens, ends the match with that winner.
// ============================================================================

state MatchRunning {

  // ================================================================
  // BeginState
  //
  // Sets the timer with an interval of one second and initializes
  // the countdown.
  // ================================================================

  event BeginState() {
  
    if (Jailbreak(Level.Game).firstJBGameRules != None)
      Jailbreak(Level.Game).firstJBGameRules.NotifyArenaStart(Self);

    TimeCountdownTie = MaxCombatTime;
    SetTimer(1.0, True);
    }


  // ================================================================
  // Timer
  //
  // Periodically checks for a winner and goes to state MatchFinished
  // if one is found. Also decrements the countdown and ties the
  // match when it reaches zero.
  // ================================================================

  event Timer() {
  
    TimeCountdownTie -= 1.0;
    
    if (FindWinner() != None)
      GotoState('MatchFinished');
    else if (TimeCountdownTie <= 0.0)
      MatchTie();
    }

  
  // ================================================================
  // EndState
  //
  // Stops the timer.
  // ================================================================

  event EndState() {
  
    SetTimer(0.0, False);
    }

  } // state MatchRunning


// ============================================================================
// state MatchFinished
//
// Waits briefly, then calls MatchFinish.
// ============================================================================

state MatchFinished {

  Begin:
    Sleep(1.0);
    MatchFinish();

  } // state MatchFinished


// ============================================================================
// Accessors
// ============================================================================

simulated function float GetCountdownStart() {
  return TimeCountdownStart; }

simulated function float GetCountdownTie() {
  return TimeCountdownTie; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  MessageClass = Class'JBLocalMessage';

  EventStart   = ArenaStart;
  EventTied    = ArenaTied;
  EventWonRed  = ArenaWonRed;
  EventWonBlue = ArenaWonBlue;
  EventWaiting = ArenaWaiting;
  
  MaxCombatTime = 60.0;
  
  TagAttachStarts  = Auto;
  TagAttachPickups = Auto;
  
  Texture = Texture'JBInfoArena';
  RemoteRole = ROLE_SimulatedProxy;
  bAlwaysRelevant = True;
  }