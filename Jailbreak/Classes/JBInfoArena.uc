// ============================================================================
// JBInfoArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoArena.uc,v 1.27.2.12 2004/05/25 14:21:59 mychaeel Exp $
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

replication
{
  reliable if (Role == ROLE_Authority)
    TimeStart,
    TimeCountdownStart,
    TimeCountdownTie,
    PlayerReplicationInfoRed,
    PlayerReplicationInfoBlue;
}


// ============================================================================
// Types
// ============================================================================

struct TDisplayPlayer
{
  var protected PlayerReplicationInfo PlayerReplicationInfo;
  var protected PlayerReplicationInfo PlayerReplicationInfoPrev;
  var protected JBTagPlayer TagPlayer;

  var protected float TimeStart;
  var protected float TimeUpdate;
  var protected float Health;
  var protected float HealthDisplayed;
  var protected string PlayerNameDisplayed;
  var protected string PlayerNameOriginal;

  var Color ColorName;
  var vector LocationName;
  var EDrawPivot DrawPivotName;

  var HudBase.SpriteWidget SpriteWidgetNameFill;
  var HudBase.SpriteWidget SpriteWidgetNameTint;
  var HudBase.SpriteWidget SpriteWidgetNameFrame;
  var HudBase.SpriteWidget SpriteWidgetSymbol;
  var HudBase.SpriteWidget SpriteWidgetHealthFill;
  var HudBase.SpriteWidget SpriteWidgetHealthTint;
  var HudBase.SpriteWidget SpriteWidgetHealthFrame;
};


// ============================================================================
// Properties
// ============================================================================

var(Events) name TagCamera;
var(Events) name TagRequest;
var(Events) name TagExclude;

var(Events) name EventStart;
var(Events) name EventTied;
var(Events) name EventWonRed;
var(Events) name EventWonBlue;
var(Events) name EventWaiting;

var() float MaxCombatTime;

var() name TagAttachCameras;
var() name TagAttachStarts;
var() name TagAttachStartsWinner;
var() name TagAttachPickups;


// ============================================================================
// Variables
// ============================================================================

var JBInfoArena nextArena;                         // next arena in chain

var private float TimeStart;                       // time of match start
var private float TimeCountdownStart;              // countdown to match start
var private float TimeCountdownTie;                // countdown to match tie

var private JBProbeEvent ProbeEventRequest;        // probe for TagRequest
var private JBProbeEvent ProbeEventExclude;        // probe for TagExclude
var private JBProbeEvent ProbeEventCamera;         // probe for TagCamera
var private array<Controller> ListControllerExclude;  // excluded players

var private PlayerReplicationInfo PlayerReplicationInfoRed;   // for display
var private PlayerReplicationInfo PlayerReplicationInfoBlue;  // and broadcasts

var HudBase.SpriteWidget SpriteWidgetCountdown;    // circle around countdown
var HudBase.NumericWidget NumericWidgetCountdown;  // countdown number

var string FontNames;                              // font for player names
var float ScaleFontNames;                          // relative font scale
var TDisplayPlayer DisplayPlayerLeft;              // player info left
var TDisplayPlayer DisplayPlayerRight;             // player info right

var private Font FontObjectNames;                  // loaded font object


// ============================================================================
// PostBeginPlay
//
// Spawns and sets up event probes for TagRequest and TagExclude. Initializes
// all attached cameras.
// ============================================================================

event PostBeginPlay()
{
  local JBCamera thisCamera;

  if (TagCamera != '' &&
      TagCamera != 'None') {
    ProbeEventCamera = Spawn(Class'JBProbeEvent', Self, TagCamera);
    ProbeEventCamera.OnTrigger   =   TriggerCamera;
    ProbeEventCamera.OnUnTrigger = UnTriggerCamera;
  }

  if (TagRequest != '' &&
      TagRequest != 'None') {
    ProbeEventRequest = Spawn(Class'JBProbeEvent', Self, TagRequest);
    ProbeEventRequest.OnTrigger   =   TriggerRequest;
    ProbeEventRequest.OnUnTrigger = UnTriggerRequest;
  }

  if (TagExclude != '' &&
      TagExclude != 'None') {
    ProbeEventExclude = Spawn(Class'JBProbeEvent', Self, TagExclude);
    ProbeEventExclude.OnTrigger   =   TriggerExclude;
    ProbeEventExclude.OnUnTrigger = UnTriggerExclude;
  }

  foreach DynamicActors(Class'JBCamera', thisCamera)
    if (ContainsActor(thisCamera))
      thisCamera.Overlay.Actor = Self;
}


// ============================================================================
// Tick
//
// If this JBInfoArena actor is not yet registered in the global JBInfoArena
// linked list client-side yet, adds it to it.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  local JBInfoArena firstArena;
  local JBInfoArena thisArena;
  local JBGameReplicationInfo InfoGame;

  if (Role < ROLE_Authority) {
    InfoGame = JBGameReplicationInfo(Level.GetLocalPlayerController().GameReplicationInfo);
    if (InfoGame == None)
      return;

    firstArena = InfoGame.firstArena;
    for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
      if (thisArena == Self)
        return;

    nextArena = InfoGame.firstArena;
    InfoGame.firstArena = Self;
  }

  Disable('Tick');
}


// ============================================================================
// Destroyed
//
// Destroys the event probes if they're present.
// ============================================================================

event Destroyed()
{
  if (ProbeEventCamera  != None) ProbeEventCamera .Destroy();
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

function bool ContainsActor(Actor Actor)
{
  if (Pickup(Actor) != None)
    if (TagAttachPickups == 'Auto')
           return Actor.Region.ZoneNumber == Region.ZoneNumber;
      else return Actor.Tag == TagAttachPickups;

  if (NavigationPoint(Actor) != None)
    if (TagAttachStarts == 'Auto')
           return Actor.Region.ZoneNumber == Region.ZoneNumber;
      else return Actor.Tag == TagAttachStarts;

  if (JBCameraArena(Actor) != None)
    return JBCameraArena(Actor).Arena == Self;

  if (JBCamera(Actor) != None)
    if (TagAttachCameras == 'Auto')
           return Actor.Region.ZoneNumber == Region.ZoneNumber;
      else return Actor.Tag == TagAttachCameras;

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

function bool CanFight(Controller ControllerCandidate)
{
  local byte bForceSendToArena;
  local JBGameRules firstJBGameRules;
  local JBTagPlayer TagPlayer;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(ControllerCandidate.PlayerReplicationInfo);
  if (TagPlayer == None)
    return False;

  firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
  if (firstJBGameRules != None &&
     !firstJBGameRules.CanSendToArena(TagPlayer, Self, bForceSendToArena))
    return False;

  if ( TagPlayer.IsInArena() ||
     (!TagPlayer.IsInJail() && !bool(bForceSendToArena)))
    return False;

  if (TagPlayer.GetArenaPending() != None &&
      TagPlayer.GetArenaPending() != Self)
    return False;

  return True;
}


// ============================================================================
// CanStart
//
// Checks whether at least two players have a match pending in this arena, that
// they are ready to fight and in opposing teams.
// ============================================================================

function bool CanStart()
{
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

function bool IsExcluded(Controller ControllerCandidate)
{
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

function ExcludeAdd(Controller ControllerCandidate)
{
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

function ExcludeRemove(Controller ControllerCandidate)
{
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

function TriggerExclude(Actor ActorOther, Pawn PawnInstigator)
{
  if (PawnInstigator.Controller != None)
    ExcludeAdd(PawnInstigator.Controller);
}


// ============================================================================
// UnTriggerExclude
//
// Called when an actor untriggers this arena by its TagExclude tag. Removes
// the instigator from the exclusion list.
// ============================================================================

function UnTriggerExclude(Actor ActorOther, Pawn PawnInstigator)
{
  if (PawnInstigator.Controller != None)
    ExcludeRemove(PawnInstigator.Controller);
}


// ============================================================================
// TriggerRequest
//
// Called when an actor triggers this arena by its TagRequest tag. Adds an
// arena request for the instigator, provided he or she isn't excluded already.
// ============================================================================

function TriggerRequest(Actor ActorOther, Pawn PawnInstigator)
{
  local JBTagPlayer TagPlayer;

  if (PlayerController(PawnInstigator.Controller) == None)
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

function UnTriggerRequest(Actor ActorOther, Pawn PawnInstigator)
{
  local JBTagPlayer TagPlayer;

  if (PlayerController(PawnInstigator.Controller) == None)
    return;

  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnInstigator.PlayerReplicationInfo);
  if (TagPlayer.GetArenaRequest() == Self)
    TagPlayer.SetArenaRequest(None);
}


// ============================================================================
// CountPlayers
//
// Returns the number of living players currently fighting in this arena.
// ============================================================================

simulated function int CountPlayers()
{
  local int nPlayers;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (Level.Game != None)
         firstTagPlayer = JBGameReplicationInfo(Level.Game                      .GameReplicationInfo).firstTagPlayer;
    else firstTagPlayer = JBGameReplicationInfo(Level.GetLocalPlayerController().GameReplicationInfo).firstTagPlayer;

  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetArena() == Self &&
        thisTagPlayer.GetHealth() > 0)
      nPlayers += 1;

  return nPlayers;
}


// ============================================================================
// MatchInit
//
// If no other match is in progress or pending, initiates a match countdown
// for the two given combatants. The match will automatically be started after
// a few seconds. Returns whether a match has been initiated or not. Can be
// called only in state Waiting.
// ============================================================================

function bool MatchInit(Controller ControllerCombatantRed, Controller ControllerCombatantBlue)
{
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

function MatchCancel()
{
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchCountdown')) {
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArenaPending() == Self)
        thisTagPlayer.SetArenaPending(None);

    TriggerEvent(EventTied, Self, None);

    if (Level.Game.IsInState('MatchInProgress'))
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

function bool MatchStart()
{
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchCountdown')) {
    if (CanStart()) {
      firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
      for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
        if (thisTagPlayer.GetArenaPending() == Self)
          thisTagPlayer.RestartInArena(Self);

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

function Prepare()
{
  local Pickup thisPickup;

  foreach DynamicActors(Class'Pickup', thisPickup)
    if (!thisPickup.IsInState('Pickup') && ContainsActor(thisPickup)) {
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

function MatchTie()
{
  local JBGameRules firstJBGameRules;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchRunning')) {
    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self)
        thisTagPlayer.RestartInJail();

    firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyArenaEnd(Self, None);

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

function MatchFinish()
{
  local Controller ControllerWinner;
  local JBGameRules firstJBGameRules;
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
      if (TagAttachStartsWinner != ''     &&
          TagAttachStartsWinner != 'None' &&
          TagAttachStartsWinner != 'Auto')
             TagPlayerWinner.RestartInFreedom(TagAttachStartsWinner);
        else TagPlayerWinner.RestartInFreedom();

      Jailbreak(Level.Game).ScorePlayer(ControllerWinner, 'ArenaVictory');
    }
    else {
      TriggerEvent(EventTied, Self, None);
      BroadcastLocalizedMessage(MessageClass, 420, PlayerReplicationInfoRed, PlayerReplicationInfoBlue, Self);
    }

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self &&
          thisTagPlayer.GetPawn() != None)
        thisTagPlayer.RestartInJail();

    firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyArenaEnd(Self, TagPlayerWinner);

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

function Controller FindWinner()
{
  local Controller ControllerWinner;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;

  if (IsInState('MatchRunning') ||
      IsInState('MatchFinished')) {

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
      if (thisTagPlayer.GetArena() == Self &&
          thisTagPlayer.GetPawn() != None)
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
// TriggerCamera
//
// If an arena fight is in progress, activates the arena cam for the given
// player.
// ============================================================================

function TriggerCamera(Actor ActorOther, Pawn PawnInstigator)
{
  if (IsInState('MatchRunning') && PawnInstigator.Controller != None)
    ActivateCameraFor(PawnInstigator.Controller);
}


// ============================================================================
// UnTriggerCamera
//
// Deactivates the arena cam for the given player.
// ============================================================================

function UnTriggerCamera(Actor ActorOther, Pawn PawnInstigator)
{
  local PlayerController PlayerController;
  local JBCamera CameraCurrent;

  PlayerController = PlayerController(PawnInstigator.Controller);
  if (PlayerController == None)
    return;
  
  CameraCurrent = JBCamera(PlayerController.ViewTarget);
  if (CameraCurrent != None && ContainsActor(CameraCurrent))
    CameraCurrent.DeactivateFor(PlayerController);
}


// ============================================================================
// ActivateCameraFor
//
// Finds or spawns a suitable camera for the given watching player and
// activates it.
// ============================================================================

function ActivateCameraFor(Controller Controller)
{ 
  local bool bFoundCamera;
  local JBCamera thisCamera;
  local JBCameraArena CameraArena;
  local JBTagPlayer TagPlayerCombatantByTeam[2];
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  if (IsInState('MatchRunning')) {
    if (PlayerController(Controller)     == None ||
        Controller.PlayerReplicationInfo == None)
      return;
  
    foreach DynamicActors(Class'JBCamera', thisCamera)
      if (JBCameraArena(thisCamera) == None && ContainsActor(thisCamera)) {
        bFoundCamera = True;
        thisCamera.Trigger(Self, Controller.Pawn);
      }
  
    if (bFoundCamera)
      return;
  
    foreach DynamicActors(Class'JBCameraArena', CameraArena)
      if (CameraArena.Owner == Self && CameraArena.IsViewerAllowed(Controller))
        break;
    
    if (CameraArena == None) {
      CameraArena = Spawn(Class'JBCameraArena', Self);
      
      CameraArena.Arena         = Self;
      CameraArena.Overlay.Actor = Self;
      
      firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
      for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
        if (thisTagPlayer.GetArena() == Self)
          TagPlayerCombatantByTeam[thisTagPlayer.GetTeam().TeamIndex] = thisTagPlayer;
      
      if (Controller.PlayerReplicationInfo.Team == None ||
          Controller.PlayerReplicationInfo.Team == TagPlayerCombatantByTeam[0].GetTeam()) {
        CameraArena.TagPlayerFollowed = TagPlayerCombatantByTeam[0];
        CameraArena.TagPlayerOpponent = TagPlayerCombatantByTeam[1];
      } else {
        CameraArena.TagPlayerFollowed = TagPlayerCombatantByTeam[1];
        CameraArena.TagPlayerOpponent = TagPlayerCombatantByTeam[0];
      }
    }
    
    CameraArena.ActivateFor(Controller);  
  }

  else {
    Log("Warning: Can't activate arena camera in" @ Self @ "because arena is in state" @ GetStateName());
  }  
}


// ============================================================================
// RenderOverlays
//
// Draws an arena time countdown on the screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas)
{
  local HudBase HudBase;

  HudBase = HudBase(Level.GetLocalPlayerController().myHUD);
  if (HudBase.bShowScoreBoard)
    return;

  DisplayPlayerLeft .PlayerReplicationInfo = PlayerReplicationInfoRed;
  DisplayPlayerRight.PlayerReplicationInfo = PlayerReplicationInfoBlue;

  ShowPlayer(Canvas, HudBase, DisplayPlayerLeft);
  ShowPlayer(Canvas, HudBase, DisplayPlayerRight);

  ShowCountdown(Canvas, HudBase);
}


// ============================================================================
// ShowCountdown
//
// Draws the arena tie countdown on the screen.
// ============================================================================

simulated function ShowCountdown(Canvas Canvas, HudBase HudBase)
{
  NumericWidgetCountdown.Value = TimeCountdownTie;

  if (NumericWidgetCountdown.Value > 99)
    NumericWidgetCountdown.TextureScale = Default.NumericWidgetCountdown.TextureScale * 2/3;
  else
    NumericWidgetCountdown.TextureScale = Default.NumericWidgetCountdown.TextureScale;

  HudBase.DrawSpriteWidget(Canvas, SpriteWidgetCountdown);
  HudBase.DrawNumericWidget(Canvas, NumericWidgetCountdown, HudBDeathMatch(HudBase).DigitsBig);
}


// ============================================================================
// ShowPlayer
//
// Draws player name and health status of one player on the screen.
// ============================================================================

simulated function ShowPlayer(Canvas Canvas, HudBase HudBase, out TDisplayPlayer DisplayPlayer)
{
  if (DisplayPlayer.PlayerReplicationInfo !=
      DisplayPlayer.PlayerReplicationInfoPrev) {
    DisplayPlayer.PlayerReplicationInfoPrev = DisplayPlayer.PlayerReplicationInfo;
    DisplayPlayer.TagPlayer = Class'JBTagPlayer'.Static.FindFor(DisplayPlayer.PlayerReplicationInfo);
  }

  if (DisplayPlayer.TimeStart != TimeStart) {
    DisplayPlayer.TimeStart = TimeStart;
    DisplayPlayer.TimeUpdate = Level.TimeSeconds;

    DisplayPlayer.HealthDisplayed = 0.0;
  }

  ShowPlayerName  (Canvas, HudBase, DisplayPlayer);
  ShowPlayerHealth(Canvas, HudBase, DisplayPlayer);

  DisplayPlayer.TimeUpdate = Level.TimeSeconds;
}


// ============================================================================
// ShowPlayerName
//
// Displays the name of one player on the screen, including its background.
// ============================================================================

simulated function ShowPlayerName(Canvas Canvas, HudBase HudBase, out TDisplayPlayer DisplayPlayer)
{
  local int nCharTotal;
  local int nCharRemoved;
  local vector SizeText;
  local vector SizeTextMax;

  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetNameFill);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetNameTint);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetNameFrame);

  if (FontObjectNames == None)
    FontObjectNames = Font(DynamicLoadObject(FontNames, Class'Font'));

  Canvas.Font = FontObjectNames;
  Canvas.FontScaleX = ScaleFontNames * HudBase.HudScale * HudBase.HudCanvasScale * Canvas.ClipX / 640;
  Canvas.FontScaleY = ScaleFontNames * HudBase.HudScale * HudBase.HudCanvasScale * Canvas.ClipY / 480;

  if (DisplayPlayer.PlayerReplicationInfo != None &&
      DisplayPlayer.PlayerReplicationInfo.PlayerName != DisplayPlayer.PlayerNameOriginal) {

    DisplayPlayer.PlayerNameOriginal  = DisplayPlayer.PlayerReplicationInfo.PlayerName;
    DisplayPlayer.PlayerNameDisplayed = DisplayPlayer.PlayerReplicationInfo.PlayerName;

    SizeTextMax.X = Abs(DisplayPlayer.LocationName.X) - 0.040;
    SizeTextMax.X *= HudBase.HudScale * HudBase.HudCanvasScale * Canvas.ClipX;

    nCharTotal = Len(DisplayPlayer.PlayerNameOriginal);

    while (nCharRemoved < nCharTotal) {
      Canvas.TextSize(DisplayPlayer.PlayerNameDisplayed, SizeText.X, SizeText.Y);
      if (SizeTextMax.X >= SizeText.X)
        break;

      nCharRemoved += 1;
      DisplayPlayer.PlayerNameDisplayed =
        Left(DisplayPlayer.PlayerNameOriginal, (nCharTotal - nCharRemoved + 1) / 2) $ "..." $
        Mid (DisplayPlayer.PlayerNameOriginal, (nCharTotal - nCharRemoved + 1) / 2 + nCharRemoved);
    }
  }

  Canvas.DrawColor = DisplayPlayer.ColorName;
  Canvas.DrawScreenText(
    DisplayPlayer.PlayerNameDisplayed,
    HudBase.HudCanvasScale * (DisplayPlayer.LocationName.X * HudBase.HudScale)       + 0.5,
    HudBase.HudCanvasScale * (DisplayPlayer.LocationName.Y * HudBase.HudScale - 0.5) + 0.5,
    DisplayPlayer.DrawPivotName);

  Canvas.FontScaleX = Canvas.Default.FontScaleX;
  Canvas.FontScaleY = Canvas.Default.FontScaleY;
}


// ============================================================================
// ShowPlayerSymbol
//
// Shows the team symbol for one player.
// ============================================================================

simulated function ShowPlayerSymbol(Canvas Canvas, HudBase HudBase, out TDisplayPlayer DisplayPlayer)
{
  local int iTeam;

  iTeam = DisplayPlayer.PlayerReplicationInfo.Team.TeamIndex;

  DisplayPlayer.SpriteWidgetSymbol.WidgetTexture = HudBTeamDeathMatch(HudBase).TeamSymbols[iTeam].WidgetTexture;
  DisplayPlayer.SpriteWidgetSymbol.TextureCoords = HudBTeamDeathMatch(HudBase).TeamSymbols[iTeam].TextureCoords;
  DisplayPlayer.SpriteWidgetSymbol.Tints[0]      = HudBTeamDeathMatch(HudBase).TeamSymbols[iTeam].Tints[0];
  DisplayPlayer.SpriteWidgetSymbol.Tints[1]      = HudBTeamDeathMatch(HudBase).TeamSymbols[iTeam].Tints[1];

  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetSymbol);
}


// ============================================================================
// ShowPlayerHealth
//
// Displays the health bar of one player on the screen.
// ============================================================================

simulated function ShowPlayerHealth(Canvas Canvas, HudBase HudBase, out TDisplayPlayer DisplayPlayer)
{
  local float HealthDelta;
  local float TimeDelta;

  TimeDelta = Level.TimeSeconds - DisplayPlayer.TimeUpdate;

  if (DisplayPlayer.TagPlayer != None &&
      DisplayPlayer.TagPlayer.GetArena() == Self)
    DisplayPlayer.Health = DisplayPlayer.TagPlayer.GetHealth(True);

  HealthDelta = DisplayPlayer.Health - DisplayPlayer.HealthDisplayed;

  DisplayPlayer.HealthDisplayed += HealthDelta * FMin(1.0, TimeDelta * 2.0);
  DisplayPlayer.SpriteWidgetHealthFill.Scale = FClamp(DisplayPlayer.HealthDisplayed, 0.0, 100.0) / 100.0;

  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetHealthFill);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetHealthTint);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetHealthFrame);
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

  event BeginState()
  {
    TriggerEvent(EventWaiting, Self, None);
  }


  // ================================================================
  // Trigger
  //
  // Selects two players from opposing teams and initiates a match.
  // ================================================================

  event Trigger(Actor ActorOther, Pawn PawnInstigator)
  {
    local bool bStarted;

    if (!Level.Game.IsInState('MatchInProgress'))
      return;

    if (Tag == TagRequest) TriggerRequest(ActorOther, PawnInstigator);
    if (Tag == TagExclude) TriggerExclude(ActorOther, PawnInstigator);

    if (TagRequest == ''     ||
        TagRequest == 'Auto' ||
        TagRequest == 'None')
           bStarted = MatchInitRandom();
      else bStarted = MatchInitRequested();

    if (!bStarted)
      TriggerEvent(EventWaiting, Self, None);
  }


  // ================================================================
  // MatchInitRandom
  //
  // Selects random candidates from opposing teams and initiates an
  // arena match for them. Returns whether a match was started.
  // ================================================================

  function bool MatchInitRandom()
  {
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

  function bool MatchInitRequested()
  {
    local byte bFoundHumanByTeam[2];
    local int iTeam;
    local Controller ControllerCandidateByTeam[2];
    local JBTagPlayer firstTagPlayer;
    local JBTagPlayer thisTagPlayer;
    local JBTagPlayer TagPlayerCandidateByTeam[2];

    firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
    for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
      iTeam = thisTagPlayer.GetTeam().TeamIndex;

      if (PlayerController(thisTagPlayer.GetController()) != None)
        bFoundHumanByTeam[iTeam] = byte(True);

      if (thisTagPlayer.GetArenaRequest() == Self && CanFight(thisTagPlayer.GetController()))
        if (TagPlayerCandidateByTeam[iTeam] == None ||
            TagPlayerCandidateByTeam[iTeam].GetArenaRequestTime() > thisTagPlayer.GetArenaRequestTime())
          TagPlayerCandidateByTeam[iTeam] = thisTagPlayer;
    }

    for (iTeam = 0; iTeam < ArrayCount(ControllerCandidateByTeam); iTeam++)
      if (TagPlayerCandidateByTeam[iTeam] != None)
        ControllerCandidateByTeam[iTeam] = TagPlayerCandidateByTeam[iTeam].GetController();

    if (ControllerCandidateByTeam[0] == None &&
        ControllerCandidateByTeam[1] == None)
      return False;

    for (iTeam = 0; iTeam < ArrayCount(ControllerCandidateByTeam); iTeam++)
      if (ControllerCandidateByTeam[iTeam] == None) {
        if (bool(bFoundHumanByTeam[iTeam]))
          return False;
        ControllerCandidateByTeam[iTeam] =
          JBBotTeam(TeamGame(Level.Game).Teams[iTeam].AI).FindBotForArena(Self, ControllerCandidateByTeam[1 - iTeam]);
        if (ControllerCandidateByTeam[iTeam] == None)
          return False;
      } 

    return MatchInit(ControllerCandidateByTeam[0],
                     ControllerCandidateByTeam[1]);
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

  private function BroadcastCountdown(int nSeconds)
  {
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

  event BeginState()
  {
    TimeStart = Level.TimeSeconds + 3.0;

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

  event Timer()
  {
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

  event EndState()
  {
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

  event BeginState()
  {
    local JBGameRules firstJBGameRules;

    firstJBGameRules = Jailbreak(Level.Game).GetFirstJBGameRules();
    if (firstJBGameRules != None)
      firstJBGameRules.NotifyArenaStart(Self);

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

  event Timer()
  {
    TimeCountdownTie -= 1.0;

    if (FindWinner() != None)
      GotoState('MatchFinished');

    else if (CountPlayers() == 0 || TimeCountdownTie <= 0.0)
      MatchTie();
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

} // state MatchRunning


// ============================================================================
// state MatchFinished
//
// Waits briefly, then calls MatchFinish.
// ============================================================================

state MatchFinished {

  Begin:
    Sleep(3.0);
    MatchFinish();

} // state MatchFinished


// ============================================================================
// Accessors
// ============================================================================

simulated function float GetTimeStart() {
  return TimeStart; }

simulated function float GetCountdownStart() {
  return TimeCountdownStart; }

simulated function float GetCountdownTie() {
  return TimeCountdownTie; }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  MessageClass = Class'JBLocalMessage';

  EventStart   = ArenaStart;
  EventTied    = ArenaTied;
  EventWonRed  = ArenaWonRed;
  EventWonBlue = ArenaWonBlue;
  EventWaiting = ArenaWaiting;

  MaxCombatTime = 60.0;

  TagAttachCameras      = Auto;
  TagAttachStarts       = Auto;
  TagAttachStartsWinner = Auto;
  TagAttachPickups      = Auto;

  SpriteWidgetCountdown = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.3,DrawPivot=DP_UpperMiddle,PosX=0.5,PosY=0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  NumericWidgetCountdown = (TextureScale=0.15,DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0,OffsetX=0,OffsetY=140,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))

  FontNames = "UT2003Fonts.jFontMedium";
  ScaleFontNames = 0.56;
  DisplayPlayerLeft  = (ColorName=(R=255,G=255,B=255,A=255),LocationName=(X=-0.169,Y=0.037),DrawPivotName=DP_MiddleLeft,SpriteWidgetNameFill=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X2=016,Y1=016,X1=382,Y2=109),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=200),Tints[1]=(R=048,G=075,B=120,A=200)),SpriteWidgetNameTint=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X2=016,Y1=128,X1=382,Y2=211),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=100),Tints[1]=(R=037,G=066,B=102,A=150)),SpriteWidgetNameFrame=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X2=016,Y1=240,X1=382,Y2=333),TextureScale=0.3,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)),SpriteWidgetSymbol=(TextureScale=0.065,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-405,OffsetY=150,RenderStyle=STY_Alpha),SpriteWidgetHealthFill=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=450,Y1=454,X2=836,Y2=490),TextureScale=0.24,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-60,OffsetY=135,ScaleMode=SM_Left,Scale=0.7,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255)),SpriteWidgetHealthTint=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=450,Y1=454,X2=836,Y2=490),TextureScale=0.24,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-60,OffsetY=135,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150)),SpriteWidgetHealthFrame=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X1=450,Y1=415,X2=836,Y2=453),TextureScale=0.24,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-60,OffsetY=135,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)));
  DisplayPlayerRight = (ColorName=(R=255,G=255,B=255,A=255),LocationName=(X=0.169,Y=0.037),DrawPivotName=DP_MiddleRight,SpriteWidgetNameFill=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=016,X2=382,Y2=109),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=200),Tints[1]=(R=048,G=075,B=120,A=200)),SpriteWidgetNameTint=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=128,X2=382,Y2=211),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=000,B=000,A=100),Tints[1]=(R=037,G=066,B=102,A=150)),SpriteWidgetNameFrame=(WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=016,Y1=240,X2=382,Y2=333),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=30,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)),SpriteWidgetSymbol=(TextureScale=0.065,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=405,OffsetY=150,RenderStyle=STY_Alpha),SpriteWidgetHealthFill=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=454,X1=836,Y2=490),TextureScale=0.24,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=60,OffsetY=135,ScaleMode=SM_Right,Scale=0.7,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255)),SpriteWidgetHealthTint=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=454,X1=836,Y2=490),TextureScale=0.24,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=60,OffsetY=135,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150)),SpriteWidgetHealthFrame=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=415,X1=836,Y2=453),TextureScale=0.24,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=60,OffsetY=135,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)));

  Texture = Texture'JBInfoArena';
  RemoteRole = ROLE_SimulatedProxy;
  bAlwaysRelevant = True;
}