// ============================================================================
// JBCamera
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamera.uc,v 1.35 2004/08/17 16:52:23 mychaeel Exp $
//
// General-purpose camera for Jailbreak.
// ============================================================================


class JBCamera extends Keypoint
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBCamera.pcx mips=off masked=on


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    Caption, Overlay, Switching, bWidescreen, FieldOfView, MotionBlur; 

  reliable if (Role == ROLE_Authority)
    bHasCamManager;
}


// ============================================================================
// Types
// ============================================================================

enum EOverlayStyle
{
  OverlayStyle_ScaleDistort,        // stretch to screen dimensions
  OverlayStyle_ScaleProportional,   // scale proportionally to fill screen
  OverlayStyle_Tile,                // keep dimensions and tile on screen
};


struct TInfoCaption
{
  var() bool bBlinking;             // caption pulses
  var() Color Color;                // caption color and transparency
  var() string Font;                // caption font name
  var() string Text;                // caption text
  var() float Position;             // relative vertical position

  var Font FontObject;              // loaded Font object
};


struct TInfoOverlay
{
  var() Material Material;          // material overlaid on screen
  var() Color Color;                // material color and transparency
  var() EOverlayStyle Style;        // material arrangement style

  var Actor Actor;                  // if present, has RenderOverlays called
};


struct TInfoSwitching
{
  var() bool bAllowAuto;            // auto-switching based on view rating
  var() bool bAllowManual;          // manual switching by Prev/NextWeapon
  var() bool bAllowTriggered;       // another camera triggered by TagSwitch
  var() bool bAllowTimed;           // auto-switching when view time runs out
  
  var() int CamOrder;               // camera order for manual switching
  var() float Time;                 // viewing time for timed switching
  var() editconst string Tag;       // dummy pointing to the TagSwitch property
};


struct TInfoViewer
{
  var PlayerController Controller;  // player viewing this camera
  var bool bManual;                 // player is switching manually

  var bool bBehindViewPrev;         // previous behind-view setting
  var float FieldOfViewPrev;        // previous field of view
  var Actor ViewTargetPrev;         // previous view target

  var float TimeToSwitch;           // time to next camera switch
};


// ============================================================================
// Properties
// ============================================================================

var(Events) name TagSwitch;                      // switch to this camera

var() editinline JBCamController CamController;  // movement controller

var() TInfoCaption Caption;                      // camera caption text
var() TInfoOverlay Overlay;                      // camera material overlay
var() TInfoSwitching Switching;                  // switching in camera array

var() bool bWidescreen;                          // display widescreen bars
var() float FieldOfView;                         // field of view for zooming
var() byte MotionBlur;                           // amount of motion blur


// ============================================================================
// Variables
// ============================================================================

var Class<JBCamController> ClassCamController;   // default camera controller

var private JBCamManager CamManager;             // camera array manager actor
var private bool bHasCamManager;                 // replicated flag for clients
var private float TimeUpdateMovement;            // last movement update

var private bool bIsActiveLocal;                 // local player using camera
var private array<TInfoViewer> ListInfoViewer;   // all players using camera

var private MotionBlur CameraEffectMotionBlur;   // MotionBlur object in use


// ============================================================================
// PostBeginPlay
//
// Initializes the camera array, if any.
// ============================================================================

simulated event PostBeginPlay()
{
  if (CamController == None)
    CamController = new ClassCamController;

  CamController.Camera = Self;
  CamController.Init();

  InitCameraArray();
}


// ============================================================================
// InitCameraArray
//
// Initializes everything required for a camera array and camera switching if
// necessary. Executes server-side only.
// ============================================================================

function InitCameraArray()
{
  local JBProbeEvent ProbeEventSwitch;

  CamManager = Class'JBCamManager'.Static.SpawnFor(Self);
  if (CamManager == None)
    return;

  if (TagSwitch != '' &&
      TagSwitch != 'None') {
    ProbeEventSwitch = Spawn(Class'JBProbeEvent', Self, TagSwitch);
    ProbeEventSwitch.OnTrigger = TriggerSwitch;
  }

  bHasCamManager = True;
}


// ============================================================================
// SetInitialState
//
// Disables the Tick event server-side. It must remain enabled client-side to
// pick up when a player starts viewing from this camera, and ActivateFor will
// reactivate it server-side.
// ============================================================================

simulated event SetInitialState()
{
  Super.SetInitialState();
  
  if (Role == ROLE_Authority)
    Disable('Tick');
}


// ============================================================================
// Trigger
//
// Activates this camera for the instigator; for a camera which is part of a
// camera array, activates this camera only if it is the first one.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator)
{
  TriggerForController(ActorOther, PawnInstigator.Controller);
}


// ============================================================================
// TriggerForController
//
// Like Trigger, but takes a controller reference as the instigator. Can be
// used to trigger the camera when players have no pawns. Ignores any attempt
// to be triggered by a Trigger when the match is not running or if the
// instigator is currently jail-fighting.
// ============================================================================

function TriggerForController(Actor ActorOther, Controller ControllerInstigator)
{
  local JBCamera CameraActivate;
  local JBTagPlayer TagPlayerInstigator;

  if (Trigger(ActorOther) != None) {
    if (!Level.Game.IsInState('MatchInProgress'))
      return;

    TagPlayerInstigator = Class'JBTagPlayer'.Static.FindFor(ControllerInstigator.PlayerReplicationInfo);
    if (TagPlayerInstigator == None ||
       (TagPlayerInstigator.IsInJail() && Class'JBBotSquadJail'.Static.IsPlayerFighting(ControllerInstigator)))
     return;
  }

  if (CamManager == None) {
    CameraActivate = Self;
  }
  
  else if (CamManager.FindCameraFirst() == Self) {
    if (Switching.bAllowAuto)
      CameraActivate = CamManager.FindCameraBest();
    if (CameraActivate == None)
      CameraActivate = Self;
  }

  if (CameraActivate != None)
    CameraActivate.ActivateFor(ControllerInstigator);
}


// ============================================================================
// UnTrigger
//
// Deactivates this camera for the instigator.
// ============================================================================

event UnTrigger(Actor ActorOther, Pawn PawnInstigator)
{
  DeactivateFor(PawnInstigator.Controller);
}


// ============================================================================
// TriggerSwitch
//
// Called when all viewers of in this camera array should switch to this
// camera.
// ============================================================================

function TriggerSwitch(Actor ActorOther, Pawn PawnInstigator)
{
  local JBCamera thisCamera;
  
  foreach DynamicActors(Class'JBCamera', thisCamera, Tag)
    if (thisCamera != Self &&
        thisCamera.Switching.bAllowTriggered)
      thisCamera.SwitchTo(Self);
}


// ============================================================================
// SwitchTo
//
// Switches all viewers of this camera to the given other camera. Ignores
// viewers who are currently set on manual switching unless bOverrideManual is
// set to True.
// ============================================================================

function SwitchTo(JBCamera Camera, optional bool bOverrideManual)
{
  local int iInfoViewer;
  
  for (iInfoViewer = ListInfoViewer.Length - 1; iInfoViewer >= 0; iInfoViewer--)
    if (bOverrideManual || !ListInfoViewer[iInfoViewer].bManual)
      Camera.ActivateFor(ListInfoViewer[iInfoViewer].Controller);
}


// ============================================================================
// SwitchToPrev
//
// Called by a viewing player's JBInventoryCamera inventory when PrevWeapon
// is called. Switches the player to the previous camera in the array.
// ============================================================================

function SwitchToPrev(Controller Controller, optional bool bManual)
{
  local JBCamera CameraPrev;

  if (CamManager == None)
    return;

  CameraPrev = CamManager.FindCameraPrev(Self);
  CameraPrev.ActivateFor(Controller, bManual);
}


// ============================================================================
// SwitchToNext
//
// Called by a viewing player's JBInventoryCamera inventory when NextWeapon
// is called. Switches the player to the next camera in the array.
// ============================================================================

function SwitchToNext(Controller Controller, optional bool bManual)
{
  local JBCamera CameraNext;
  
  if (CamManager == None)
    return;
  
  CameraNext = CamManager.FindCameraNext(Self);
  CameraNext.ActivateFor(Controller, bManual);
}


// ============================================================================
// AutoSwitchTimed
//
// Decrements the timers of all viewers and switches them to the next camera
// if appropriate. Assumes a camera array. Executed only on the server.
// ============================================================================

function AutoSwitchTimed(float TimeDelta)
{
  local int iInfoViewer;

  if (!Switching.bAllowTimed)
    return;

  for (iInfoViewer = ListInfoViewer.Length - 1; iInfoViewer >= 0; iInfoViewer--) {
    ListInfoViewer[iInfoViewer].TimeToSwitch -= TimeDelta;
    if (ListInfoViewer[iInfoViewer].TimeToSwitch <= 0.0 &&
       !ListInfoViewer[iInfoViewer].bManual)
      SwitchToNext(ListInfoViewer[iInfoViewer].Controller);
  }
}


// ============================================================================
// AutoSwitchBest
//
// Finds the most suitable camera and switches all viewers to it. Assumes a
// camera array. Executed only on the server.
// ============================================================================

function AutoSwitchBest()
{
  local JBCamera CameraBest;

  if (!Switching.bAllowAuto || ListInfoViewer.Length == 0)
    return;

  CameraBest = CamManager.FindCameraBest();

  if (CameraBest != None &&
      CameraBest != Self)
    SwitchTo(CameraBest);
}


// ============================================================================
// RateCurrentView
//
// Rates the view a player would have from this camera based on the rating
// returned by its JBCamController. The higher the return value, the better
// the view from this camera. Used to automatically switch cameras.
// ============================================================================

function float RateCurrentView()
{
  if (CamController == None)
    return 0.0;

  return CamController.RateCurrentView();
}


// ============================================================================
// HasViewers
//
// Checks and returns whether this camera has viewers.
// ============================================================================

function bool HasViewers()
{
  return ListInfoViewer.Length > 0;
}


// ============================================================================
// IsViewer
//
// Checks and returns whether the given player is currently viewing from this
// camera.
// ============================================================================

function bool IsViewer(Controller Controller)
{
  local int iInfoViewer;

  if (PlayerController(Controller) == None)
    return False;

  for (iInfoViewer = 0; iInfoViewer < ListInfoViewer.Length; iInfoViewer++)
    if (ListInfoViewer[iInfoViewer].Controller == Controller)
      return True;

  return False;
}


// ============================================================================
// IsViewerAllowed
//
// Checks and returns whether the given player is allowed to view from this
// camera.
// ============================================================================

function bool IsViewerAllowed(Controller Controller)
{
  if (PlayerController(Controller) == None)
    return False;
  
  return True;
}


// ============================================================================
// ActivateFor
//
// Activates this camera for the given player and adds the player to the
// ListControllerViewer array. Deactivation is handled by the camera
// automatically, but you can also explicitely call DeactivateFor. Enables the
// Tick event.
// ============================================================================

function ActivateFor(Controller Controller, optional bool bManual)
{
  local int iInfoViewer;
  local Actor ViewTargetPrev;
  local PlayerController ControllerPlayer;

  if (!IsViewerAllowed(Controller) || IsViewer(Controller))
    return;

  ControllerPlayer = PlayerController(Controller);
  if (JBCamera(ControllerPlayer.ViewTarget) != None)
    JBCamera(ControllerPlayer.ViewTarget).DeactivateFor(Controller);

  if (!IsViewer(Controller)) {
    ViewTargetPrev = ControllerPlayer.ViewTarget;
    if (     ViewTargetPrev != Controller.Pawn &&
        Pawn(ViewTargetPrev)            != None &&
        Pawn(ViewTargetPrev).Controller != None)
      ViewTargetPrev = Pawn(ViewTargetPrev).Controller;

    iInfoViewer = ListInfoViewer.Length;
    ListInfoViewer.Insert(iInfoViewer, 1);

    ListInfoViewer[iInfoViewer].Controller = ControllerPlayer;
    ListInfoViewer[iInfoViewer].bManual    = bManual;
    
    ListInfoViewer[iInfoViewer].bBehindViewPrev = ControllerPlayer.bBehindView;
    ListInfoViewer[iInfoViewer].FieldOfViewPrev = ControllerPlayer.FOVAngle;
    ListInfoViewer[iInfoViewer].ViewTargetPrev  = ViewTargetPrev;

    ListInfoViewer[iInfoViewer].TimeToSwitch = Switching.Time;

    if (CamManager != None && Switching.bAllowManual)
      CamManager.AddInventoryCamera(Controller, Self);
  }

  if (ControllerPlayer.ViewTarget != Self) {
    ControllerPlayer.      SetViewTarget(Self);
    ControllerPlayer.ClientSetViewTarget(Self);
  }

  if (ControllerPlayer == Level.GetLocalPlayerController() && !bIsActiveLocal)
    ActivateForLocal();

  Enable('Tick');
  UpdateMovement();
}


// ============================================================================
// DeactivateFor
//
// Deactivates this camera for the given player and removes the player from
// the ListControllerViewer array. Disables the Tick event if no viewer is
// left for this camera.
// ============================================================================

function DeactivateFor(Controller Controller)
{
  local int iInfoViewer;
  local Actor ViewTargetPrev;
  local PlayerController ControllerPlayer;

  ControllerPlayer = PlayerController(Controller);
  if (ControllerPlayer == None)
    return;

  for (iInfoViewer = 0; iInfoViewer < ListInfoViewer.Length; iInfoViewer++)
    if (ListInfoViewer[iInfoViewer].Controller == Controller)
      break;

  if (iInfoViewer >= ListInfoViewer.Length)
    return;

  if (ControllerPlayer.ViewTarget == Self) {
    ViewTargetPrev = Controller;
    if (JBCamera(ListInfoViewer[iInfoViewer].ViewTargetPrev) == None &&
                 ListInfoViewer[iInfoViewer].ViewTargetPrev  != None)
      ViewTargetPrev = ListInfoViewer[iInfoViewer].ViewTargetPrev;

    ControllerPlayer.SetViewTarget(ViewTargetPrev);
    ControllerPlayer.SetFOVAngle  (ListInfoViewer[iInfoViewer].FieldOfViewPrev);
    ControllerPlayer.bBehindView = ListInfoViewer[iInfoViewer].bBehindViewPrev;
    
    ControllerPlayer.ClientSetViewTarget(ControllerPlayer.ViewTarget);
    ControllerPlayer.ClientSetBehindView(ControllerPlayer.bBehindView);
  }

  if (CamManager != None)
    CamManager.RemoveInventoryCamera(Controller);

  ListInfoViewer.Remove(iInfoViewer, 1);

  if (ListInfoViewer.Length == 0) {
    if (bIsActiveLocal)
      DeactivateForLocal();
    Disable('Tick');
  }
}


// ============================================================================
// DeactivateForAll
//
// Deactivates this camera for all of its viewers.
// ============================================================================

function DeactivateForAll()
{
  while (ListInfoViewer.Length > 0)
    DeactivateFor(ListInfoViewer[0].Controller);
}


// ============================================================================
// ActivateForLocal
//
// Called client-side when the camera is activated for the local player. Don't
// call this function directly from outside.
// ============================================================================

protected simulated function ActivateForLocal()
{
  local JBCamera thisCamera;
  local PlayerController ControllerPlayer;

  foreach DynamicActors(Class'JBCamera', thisCamera)
    if (thisCamera.bIsActiveLocal)
      thisCamera.DeactivateForLocal();

  ControllerPlayer = Level.GetLocalPlayerController();

  if (JBInterfaceHud(ControllerPlayer.myHUD) != None)
    JBInterfaceHud(ControllerPlayer.myHUD).bWidescreen = bWidescreen;

  if (MotionBlur > 0) {
    CameraEffectMotionBlur = MotionBlur(FindCameraEffect(Class'MotionBlur'));
    CameraEffectMotionBlur.BlurAlpha = 255 - MotionBlur;
    ControllerPlayer.AddCameraEffect(CameraEffectMotionBlur);
  }

  if (bHasCamManager && Switching.bAllowManual)
    ControllerPlayer.ReceiveLocalizedMessage(Class'JBLocalMessageScreen', 510);

  bIsActiveLocal = True;
  UpdateLocal();
}


// ============================================================================
// DeactivateForLocal
//
// Called client-side when the camera is deactivated for the local player.
// Don't call this function directly from outside.
// ============================================================================

protected simulated function DeactivateForLocal()
{
  local PlayerController ControllerPlayer;
  local JBInterfaceHud JBInterfaceHud;

  ControllerPlayer = Level.GetLocalPlayerController();

  JBInterfaceHud = JBInterfaceHud(ControllerPlayer.myHUD);
  if (JBInterfaceHud != None)
    JBInterfaceHud.bWidescreen = False;

  if (CameraEffectMotionBlur != None) {
    RemoveCameraEffect(CameraEffectMotionBlur);
    CameraEffectMotionBlur = None;
  }

  if (JBInterfaceHud != None)
    JBInterfaceHud.ClearMessageByClass(Class'JBLocalMessageScreen', 510);

  bIsActiveLocal = False;
}


// ============================================================================
// UpdateLocal
//
// Called client-side every tick as long as this camera is activated for the
// local player.
// ============================================================================

protected simulated function UpdateLocal()
{
  local PlayerController ControllerPlayer;

  ControllerPlayer = Level.GetLocalPlayerController();
  ControllerPlayer.bBehindView = False;
  ControllerPlayer.FOVAngle = FieldOfView;
}


// ============================================================================
// UpdateMovement
//
// Called both server-side and client-side once a tick as long as this camera
// is being used by at least once player. Executed only once a tick.
// ============================================================================

simulated function UpdateMovement()
{
  local float TimeDelta;
  
  if (CamController == None || TimeUpdateMovement == Level.TimeSeconds)
    return;
    
  if (TimeUpdateMovement > 0.0)
    TimeDelta = Level.TimeSeconds - TimeUpdateMovement;
  TimeUpdateMovement = Level.TimeSeconds;
  
  CamController.UpdateMovement(TimeDelta);
}


// ============================================================================
// Tick
//
// Checks whether all viewers listed in ListControllerViewer are actually
// viewing from this camera and calls DeactivateFor for those who do not.
// Also checks whether players should be auto-switched to a different camera.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  local bool bIsActiveLocalNew;
  local int iInfoViewer;
  local PlayerController ControllerPlayer;

  if (Role == ROLE_Authority)
    for (iInfoViewer = ListInfoViewer.Length - 1; iInfoViewer >= 0; iInfoViewer--) {
      ControllerPlayer = ListInfoViewer[iInfoViewer].Controller;
      if (ControllerPlayer == None)
        ListInfoViewer.Remove(iInfoViewer, 1);
      else if (ControllerPlayer.ViewTarget != Self)
        DeactivateFor(ControllerPlayer);
      else
        ControllerPlayer.bBehindView = False;
    }

  if (Level.NetMode != NM_DedicatedServer) {
    bIsActiveLocalNew = (Level.GetLocalPlayerController().ViewTarget == Self);
  
    if (bIsActiveLocalNew != bIsActiveLocal)
      if (bIsActiveLocalNew)
        ActivateForLocal();
      else
        DeactivateForLocal();
  
    if (bIsActiveLocal)
      UpdateLocal();
  }

  if (Role == ROLE_Authority || bIsActiveLocal)
    UpdateMovement();

  if (CamManager != None) {
    AutoSwitchTimed(TimeDelta);
    AutoSwitchBest();
  }
}


// ============================================================================
// RenderOverlayMaterial
//
// Renders the material overlay on the given Canvas.
// ============================================================================

simulated function RenderOverlayMaterial(Canvas Canvas)
{
  local float RatioStretchTotal;
  local vector RatioStretch;
  local vector SizeOverlay;

  if (Overlay.Material == None)
    return;

  if (Texture(Overlay.Material) != None)
    Texture(Overlay.Material).LODSet = LODSET_Interface;

  Canvas.DrawColor = Overlay.Color;

  switch (Overlay.Style) {
    case OverlayStyle_ScaleDistort:
      Canvas.SetPos(0, 0);
      Canvas.DrawTile(Overlay.Material, Canvas.ClipX, Canvas.ClipY, 0, 0,
        Overlay.Material.MaterialUSize(),
        Overlay.Material.MaterialVSize());  // DrawTileStretched is buggy
      break;

    case OverlayStyle_ScaleProportional:
      SizeOverlay.X = Overlay.Material.MaterialUSize();
      SizeOverlay.Y = Overlay.Material.MaterialVSize();

      RatioStretch.X = Canvas.ClipX / SizeOverlay.X;
      RatioStretch.Y = Canvas.ClipY / SizeOverlay.Y;
      RatioStretchTotal = FMax(RatioStretch.X, RatioStretch.Y);

      SizeOverlay *= RatioStretchTotal;
      Canvas.SetPos((Canvas.ClipX - SizeOverlay.X) / 2.0,
                    (Canvas.ClipY - SizeOverlay.Y) / 2.0);
      Canvas.DrawTileScaled(Overlay.Material, RatioStretchTotal, RatioStretchTotal);
      break;

    case OverlayStyle_Tile:
      Canvas.SetPos(0, 0);
      Canvas.DrawTile(Overlay.Material, Canvas.ClipX, Canvas.ClipY, 0, 0, Canvas.ClipX, Canvas.ClipY);
      break;
  }
}


// ============================================================================
// RenderOverlayCaption
//
// Renders the caption text on the given Canvas.
// ============================================================================

simulated function RenderOverlayCaption(Canvas Canvas)
{
  local vector SizeCaption;
  local vector LocationCaption;

  if (Caption.Text == "")
    return;

  if (Caption.FontObject == None) {
    Caption.FontObject = Font(DynamicLoadObject(Caption.Font, Class'Font'));
    if (Caption.FontObject == None)
      Caption.FontObject = Font'DefaultFont';
  }

  Canvas.Font = Caption.FontObject;
  Canvas.TextSize(Caption.Text, SizeCaption.X, SizeCaption.Y);

  LocationCaption.X = (Canvas.ClipX - SizeCaption.X) / 2.0;
  LocationCaption.Y = Canvas.ClipY * Caption.Position - SizeCaption.Y / 2.0;

  Canvas.DrawColor = Caption.Color;
  if (Caption.bBlinking)
    Canvas.DrawColor.A -= Canvas.DrawColor.A * (Level.TimeSeconds % 0.7) / 1.4;

  Canvas.SetPos(LocationCaption.X, LocationCaption.Y);
  Canvas.DrawText(Caption.Text);
}


// ============================================================================
// RenderOverlays
//
// Calls RenderOverlays for the overlay actor if one is present. Then renders
// the overlay material and the caption on the screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas)
{
  if (Overlay.Actor != None)
    Overlay.Actor.RenderOverlays(Canvas);

  RenderOverlayMaterial(Canvas);
  RenderOverlayCaption(Canvas);
}


// ============================================================================
// Destroyed
//
// Deactivates this camera for all viewers before it is destroyed. Since
// cameras of this class have bNoDelete set and cannot be destroyed, this only
// applies to subclasses.
// ============================================================================

event Destroyed()
{
  DeactivateForAll();
}


// ============================================================================
// FindCameraEffect
//
// Returns a reference to an object of the given CameraEffect class. First
// tries to find one in the local PlayerController's CameraEffects array. If
// none exists there, gets one from the ObjectPool.
//
// When used in conjunction with PlayerController.AddCameraEffect and the
// RemoveCameraEffect below, ensures that all code adhering to this convention
// gracefully works along with each other. It may happen that the same
// CameraEffect object appears multiple times in the PlayerController's
// CameraEffects array, but that does not seem to be a problem.
// ============================================================================

simulated function CameraEffect FindCameraEffect(Class<CameraEffect> ClassCameraEffect)
{
  local int iCameraEffect;
  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (PlayerControllerLocal == None)
    return None;

  for (iCameraEffect = 0; iCameraEffect < PlayerControllerLocal.CameraEffects.Length; iCameraEffect++)
    if (PlayerControllerLocal.CameraEffects[iCameraEffect] != None &&
        PlayerControllerLocal.CameraEffects[iCameraEffect].Class == ClassCameraEffect)
      return PlayerControllerLocal.CameraEffects[iCameraEffect];

  return CameraEffect(Level.ObjectPool.AllocateObject(ClassCameraEffect));
}


// ============================================================================
// RemoveCameraEffect
//
// Removes exactly one reference to the given CameraEffect object from the
// local PlayerController's CameraEffects array. Frees the object into the
// ObjectPool only if no further references exist in the CameraEffects array.
// ============================================================================

simulated function RemoveCameraEffect(CameraEffect CameraEffect)
{
  local int iCameraEffect;
  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (PlayerControllerLocal == None)
    return;

  PlayerControllerLocal.RemoveCameraEffect(CameraEffect);
  
  for (iCameraEffect = 0; iCameraEffect < PlayerControllerLocal.CameraEffects.Length; iCameraEffect++)
    if (PlayerControllerLocal.CameraEffects[iCameraEffect] == CameraEffect)
      return;
  
  Level.ObjectPool.FreeObject(CameraEffect);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  ClassCamController = Class'JBCamController';

  bWidescreen = False;
  MotionBlur  = 0;
  FieldOfView = 85.0;

  Caption   = (bBlinking=True,Color=(R=255,G=255,B=255,A=255),Font="UT2003Fonts.FontEurostile12",Position=0.8);
  Overlay   = (Color=(R=255,G=255,B=255,A=255),Style=OverlayStyle_ScaleProportional);
  Switching = (bAllowManual=True,bAllowTriggered=True,Time=5.0,Tag="(set TagSwitch under Events instead)");

  Texture      = Texture'JBCamera';
  RemoteRole   = ROLE_SimulatedProxy;
  bNoDelete    = True;
  bStatic      = False;
  bDirectional = True;
  Velocity     = (X=1.0);  // hack fix for undesired scoreboard auto display
}