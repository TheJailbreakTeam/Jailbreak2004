// ============================================================================
// JBCamera
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamera.uc,v 1.21 2004/02/16 17:17:02 mychaeel Exp $
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
};


struct TInfoViewer
{
  var PlayerController Controller;  // player viewing this camera
  var bool bBehindViewPrev;         // previous behind-view setting
  var Actor ViewTargetPrev;         // previous view target
};


// ============================================================================
// Properties
// ============================================================================

var() bool bWidescreen;      // display camera widescreen bars

var() TInfoCaption Caption;  // camera caption text
var() TInfoOverlay Overlay;  // camera material overlay

var() byte MotionBlur;       // amount of camera motion blur


// ============================================================================
// Variables
// ============================================================================

var private bool bIsActiveLocal;                // local player using camera
var private array<TInfoViewer> ListInfoViewer;  // all players using camera

var private MotionBlur CameraEffectMotionBlur;  // MotionBlur object in use


// ============================================================================
// PostBeginPlay
//
// Disables the Tick event server-side. ActivateFor will enable it again as
// soon as a player starts viewing through this camera. On clients, loads the
// caption font object.
// ============================================================================

simulated event PostBeginPlay()
{
  if (Role == ROLE_Authority)
    Disable('Tick');

  if (Level.NetMode != NM_DedicatedServer)
    Caption.FontObject = Font(DynamicLoadObject(Caption.Font, Class'Font'));
}


// ============================================================================
// Trigger
//
// Activates this camera for the instigator.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator)
{
  ActivateFor(PawnInstigator.Controller);
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
// ActivateFor
//
// Activates this camera for the given player and adds the player to the
// ListControllerViewer array. Deactivation is handled by the camera
// automatically, but you can also explicitely call DeactivateFor. Enables the
// Tick event.
// ============================================================================

function ActivateFor(Controller Controller)
{
  local int iInfoViewer;
  local Actor ViewTargetPrev;
  local PlayerController ControllerPlayer;

  ControllerPlayer = PlayerController(Controller);
  if (IsViewer(Controller) || ControllerPlayer == None)
    return;

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
    ListInfoViewer[iInfoViewer].Controller      = ControllerPlayer;
    ListInfoViewer[iInfoViewer].bBehindViewPrev = ControllerPlayer.bBehindView;
    ListInfoViewer[iInfoViewer].ViewTargetPrev  = ViewTargetPrev;
  }

  if (ControllerPlayer.ViewTarget != Self) {
    ControllerPlayer.SetViewTarget      (Self);
    ControllerPlayer.ClientSetViewTarget(Self);
  }

  if (ControllerPlayer == Level.GetLocalPlayerController() && !bIsActiveLocal)
    ActivateForLocal();

  Enable('Tick');
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

    ControllerPlayer.SetViewTarget      (ViewTargetPrev);
    ControllerPlayer.ClientSetViewTarget(ViewTargetPrev);
    ControllerPlayer.bBehindView =       ListInfoViewer[iInfoViewer].bBehindViewPrev;
    ControllerPlayer.ClientSetBehindView(ListInfoViewer[iInfoViewer].bBehindViewPrev);
  }

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

  ControllerPlayer = Level.GetLocalPlayerController();

  if (JBInterfaceHud(ControllerPlayer.myHUD) != None)
    JBInterfaceHud(ControllerPlayer.myHUD).bWidescreen = False;

  if (CameraEffectMotionBlur != None) {
    RemoveCameraEffect(CameraEffectMotionBlur);
    CameraEffectMotionBlur = None;
  }

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
  Level.GetLocalPlayerController().bBehindView = False;
}


// ============================================================================
// Tick
//
// Checks whether all viewers listed in ListControllerViewer are actually
// viewing from this camera and calls DeactivateFor for those that don't.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  local bool bIsActiveLocalNew;
  local int iInfoViewer;

  if (Role == ROLE_Authority)
    for (iInfoViewer = ListInfoViewer.Length - 1; iInfoViewer >= 0; iInfoViewer--)
      if (ListInfoViewer[iInfoViewer].Controller == None)
        ListInfoViewer.Remove(iInfoViewer, 1);
      else if (ListInfoViewer[iInfoViewer].Controller.ViewTarget != Self)
        DeactivateFor(ListInfoViewer[iInfoViewer].Controller);

  if (Level.NetMode == NM_DedicatedServer)
    return;

  bIsActiveLocalNew = (Level.GetLocalPlayerController().ViewTarget == Self);

  if (bIsActiveLocalNew != bIsActiveLocal)
    if (bIsActiveLocalNew)
      ActivateForLocal();
    else
      DeactivateForLocal();

  if (bIsActiveLocal)
    UpdateLocal();
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

  if (Caption.Text == "" ||
      Caption.FontObject == None)
    return;

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
// Renders the overlay material on the user's screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas)
{
  RenderOverlayMaterial(Canvas);
  RenderOverlayCaption(Canvas);
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
  Caption = (bBlinking=True,Color=(R=255,G=255,B=255,A=255),Font="UT2003Fonts.FontEurostile12",Position=0.8);
  Overlay = (Color=(R=255,G=255,B=255,A=255),Style=OverlayStyle_ScaleProportional);

  Texture = Texture'JBCamera';
  RemoteRole = ROLE_SimulatedProxy;
  bNoDelete = True;
  bStatic = False;
  bDirectional = True;
  Velocity = (X=1.0);  // hack fix for undesired automatic scoreboard display
}