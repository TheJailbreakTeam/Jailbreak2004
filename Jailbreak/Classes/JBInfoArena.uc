// ============================================================================
// JBInfoArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInfoArena.uc,v 1.36 2004/05/04 15:15:38 mychaeel Exp $
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
  var protected string PlayerName;

  var Color ColorName;
  var vector LocationName;
  var EDrawPivot DrawPivotName;

  var HudBase.SpriteWidget SpriteWidgetNameBack;
  var HudBase.SpriteWidget SpriteWidgetTeamCircle;
  var HudBase.SpriteWidget SpriteWidgetTeamSymbol;
  var HudBase.SpriteWidget SpriteWidgetHealthBack;
  var HudBase.SpriteWidget SpriteWidgetHealthBar;
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
var vector SizeFontNames;                          // relative font scale
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
    else
      return Actor.Tag == TagAttachPickups;

  if (NavigationPoint(Actor) != None)
    if (TagAttachStarts == 'Auto')
      return Actor.Region.ZoneNumber == Region.ZoneNumber;
    else
      return Actor.Tag == TagAttachStarts;

  if (JBCamera(Actor) != None)
    if (TagAttachCameras == 'Auto')
      return Actor.Region.ZoneNumber == Region.ZoneNumber;
    else
      return Actor.Tag == TagAttachCameras;

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
        thisTagPlayer.GetPawn() != None)
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

  DisplayPlayerLeft .PlayerReplicationInfo = PlayerReplicationInfoRed;
  DisplayPlayerRight.PlayerReplicationInfo = PlayerReplicationInfoBlue;

  HudBase = HudBase(Level.GetLocalPlayerController().myHUD);

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
    else NumericWidgetCountdown.TextureScale = Default.NumericWidgetCountdown.TextureScale;

  HudBase.DrawSpriteWidget(Canvas, SpriteWidgetCountdown);

  if (NumericWidgetCountdown.Value > 10)
         HudBase.DrawNumericWidget(Canvas, NumericWidgetCountdown, HudCDeathMatch(HudBase).DigitsBig);
    else HudBase.DrawNumericWidget(Canvas, NumericWidgetCountdown, HudCDeathMatch(HudBase).DigitsBigPulse);
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
  ShowPlayerSymbol(Canvas, HudBase, DisplayPlayer);
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
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetNameBack);

  if (FontObjectNames == None)
    FontObjectNames = Font(DynamicLoadObject(FontNames, Class'Font'));

  Canvas.Font = FontObjectNames;
  Canvas.FontScaleX = SizeFontNames.X * HudBase.HudScale * HudBase.HudCanvasScale * Canvas.ClipX / 640;
  Canvas.FontScaleY = SizeFontNames.Y * HudBase.HudScale * HudBase.HudCanvasScale * Canvas.ClipY / 480;

  if (DisplayPlayer.PlayerReplicationInfo != None)
    DisplayPlayer.PlayerName = DisplayPlayer.PlayerReplicationInfo.PlayerName;

  Canvas.DrawColor = DisplayPlayer.ColorName;
  Canvas.DrawScreenText(
    DisplayPlayer.PlayerName,
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

  DisplayPlayer.SpriteWidgetTeamSymbol.WidgetTexture = HudCTeamDeathMatch(HudBase).TeamSymbols[iTeam].WidgetTexture;
  DisplayPlayer.SpriteWidgetTeamSymbol.Tints[0]      = HudCTeamDeathMatch(HudBase).TeamSymbols[iTeam].Tints[0];
  DisplayPlayer.SpriteWidgetTeamSymbol.Tints[1]      = HudCTeamDeathMatch(HudBase).TeamSymbols[iTeam].Tints[1];

  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetTeamCircle);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetTeamSymbol);
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
  DisplayPlayer.SpriteWidgetHealthBar.Scale = FClamp(DisplayPlayer.HealthDisplayed, 0.0, 100.0) / 100.0;

  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetHealthBack);
  HudBase.DrawSpriteWidget(Canvas, DisplayPlayer.SpriteWidgetHealthBar);
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

  SpriteWidgetCountdown = (WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.7,DrawPivot=DP_UpperMiddle,PosX=0.5,PosY=0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  NumericWidgetCountdown = (TextureScale=0.36,DrawPivot=DP_MiddleMiddle,PosX=0.5,PosY=0,OffsetX=0,OffsetY=54,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))

  FontNames = "2K4Fonts.Verdana20";
  SizeFontNames = (X=0.400,Y=0.450);
  DisplayPlayerLeft  = (ColorName=(R=176,G=176,B=176,A=255),LocationName=(X=-0.080,Y=0.036),DrawPivotName=DP_MiddleRight,SpriteWidgetNameBack=(WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.53,DrawPivot=DP_UpperRight,PosX=0.5,OffsetX=-50,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=0,G=0,B=0,A=150),Tints[1]=(R=0,G=0,B=0,A=150)),SpriteWidgetTeamCircle=(WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.53,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-35,OffsetY=5,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)),SpriteWidgetTeamSymbol=(TextureCoords=(X1=0,Y1=0,X2=256,Y2=256),TextureScale=0.1,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-200,OffsetY=45,RenderStyle=STY_Alpha),SpriteWidgetHealthBack=(WidgetTexture=Texture'SpriteWidgetHud',TextureCoords=(X1=16,Y1=32,X2=187,Y2=64),TextureScale=0.4,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-40,OffsetY=90,RenderStyle=STY_Alpha,Tints[0]=(R=0,G=0,B=0,A=150),Tints[1]=(R=0,G=0,B=0,A=150)),SpriteWidgetHealthBar=(WidgetTexture=Texture'SpriteWidgetHud',TextureCoords=(X1=187,Y1=80,X2=16,Y2=112),TextureScale=0.4,DrawPivot=DP_UpperRight,PosX=0.5,PosY=0,OffsetX=-40,OffsetY=90,ScaleMode=SM_Left,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=220),Tints[1]=(R=255,G=255,B=255,A=220)));
  DisplayPlayerRight = (ColorName=(R=176,G=176,B=176,A=255),LocationName=(X=0.080,Y=0.036),DrawPivotName=DP_MiddleLeft,SpriteWidgetNameBack=(WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.53,DrawPivot=DP_UpperLeft,PosX=0.5,OffsetX=50,OffsetY=10,RenderStyle=STY_Alpha,Tints[0]=(R=0,G=0,B=0,A=150),Tints[1]=(R=0,G=0,B=0,A=150)),SpriteWidgetTeamCircle=(WidgetTexture=Texture'HUDContent.Generic.HUD',TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.53,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=35,OffsetY=5,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255)),SpriteWidgetTeamSymbol=(TextureCoords=(X1=0,Y1=0,X2=256,Y2=256),TextureScale=0.1,PosX=0.5,PosY=0,OffsetX=200,OffsetY=45,RenderStyle=STY_Alpha),SpriteWidgetHealthBack=(WidgetTexture=Texture'SpriteWidgetHud',TextureCoords=(X1=16,Y1=32,X2=187,Y2=64),TextureScale=0.4,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=40,OffsetY=90,RenderStyle=STY_Alpha,Tints[0]=(R=0,G=0,B=0,A=150),Tints[1]=(R=0,G=0,B=0,A=150)),SpriteWidgetHealthBar=(WidgetTexture=Texture'SpriteWidgetHud',TextureCoords=(X1=16,Y1=80,X2=187,Y2=112),TextureScale=0.4,DrawPivot=DP_UpperLeft,PosX=0.5,PosY=0,OffsetX=40,OffsetY=90,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=220),Tints[1]=(R=255,G=255,B=255,A=220)));

  Texture = Texture'JBInfoArena';
  RemoteRole = ROLE_SimulatedProxy;
  bAlwaysRelevant = True;
}