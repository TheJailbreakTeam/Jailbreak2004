// ============================================================================
// JBCamera
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamera.uc,v 1.10 2003/01/06 11:18:36 mychaeel Exp $
//
// General-purpose camera for Jailbreak.
// ============================================================================


class JBCamera extends Keypoint;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBCamera.pcx mips=off masked=on


// ============================================================================
// Types
// ============================================================================

enum EOverlayStyle {

  OverlayStyle_ScaleDistort,
  OverlayStyle_ScaleProportional,
  OverlayStyle_Tile,
  };


struct TInfoCaption {

  var() bool bBlinking;       // caption pulses
  var() Color Color;          // caption color and transparency
  var() string Font;          // caption font name
  var() string Text;          // caption text
  var() float Position;       // relative vertical position
  
  var Font FontObject;        // loaded Font object
  };


struct TInfoOverlay {

  var() Material Material;    // material overlaid on screen
  var() Color Color;          // material color and transparency
  var() EOverlayStyle Style;  // material arrangement style
  };


// ============================================================================
// Properties
// ============================================================================

var() bool bWidescreen;            // draw widescreen bars

var() TInfoCaption Caption;
var() TInfoOverlay Overlay;

var() byte MotionBlur;             // amount of motion blur


// ============================================================================
// Variables
// ============================================================================

var private bool bIsActiveLocal;   // camera is active for the local player
var private array<PlayerController> ListControllerViewer;

var Font FontCaption;              // font object used for caption
var private MotionBlur CameraEffectMotionBlur;  // motion blur object


// ============================================================================
// PostBeginPlay
//
// Disables the Tick event server-side. ActivateFor will enable it again as
// soon as a player starts viewing through this camera. On clients, loads the
// caption font object.
// ============================================================================

simulated event PostBeginPlay() {

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

event Trigger(Actor ActorOther, Pawn PawnInstigator) {

  ActivateFor(PawnInstigator.Controller);
  }


// ============================================================================
// UnTrigger
//
// Deactivates this camera for the instigator.
// ============================================================================

event UnTrigger(Actor ActorOther, Pawn PawnInstigator) {

  DeactivateFor(PawnInstigator.Controller);
  }


// ============================================================================
// IsViewer
//
// Checks and returns whether the given player is currently viewing from this
// camera.
// ============================================================================

function bool IsViewer(Controller Controller) {

  local int iController;

  if (PlayerController(Controller) == None)
    return False;
  
  for (iController = 0; iController < ListControllerViewer.Length; iController++)
    if (ListControllerViewer[iController] == Controller)
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

function ActivateFor(Controller Controller) {

  local PlayerController ControllerPlayer;

  ControllerPlayer = PlayerController(Controller);
  if (ControllerPlayer == None)
    return;

  if (JBCamera(ControllerPlayer.ViewTarget) != None)
    JBCamera(ControllerPlayer.ViewTarget).DeactivateFor(Controller);

  if (ControllerPlayer.ViewTarget != Self) {
    ControllerPlayer.SetViewTarget(Self);
    ControllerPlayer.ClientSetViewTarget(Self);
    }

  if (!IsViewer(Controller))
    ListControllerViewer[ListControllerViewer.Length] = ControllerPlayer;

  Enable('Tick');
  }


// ============================================================================
// DeactivateFor
//
// Deactivates this camera for the given player and removes the player from
// the ListControllerViewer array. Disables the Tick event if no viewer is
// left for this camera.
// ============================================================================

function DeactivateFor(Controller Controller) {

  local int iController;
  local PlayerController ControllerPlayer;

  ControllerPlayer = PlayerController(Controller);
  if (ControllerPlayer == None)
    return;

  if (ControllerPlayer.ViewTarget == Self) {
    ControllerPlayer.SetViewTarget(Controller.Pawn);
    ControllerPlayer.ClientSetViewTarget(Controller.Pawn);
    }
  
  for (iController = ListControllerViewer.Length - 1; iController >= 0; iController--)
    if (ListControllerViewer[iController] == Controller)
      ListControllerViewer.Remove(iController, 1);
  
  if (ListControllerViewer.Length == 0) {
    if (bIsActiveLocal)
      DeactivateForLocal();
    Disable('Tick');
    }
  }


// ============================================================================
// ActivateForLocal
//
// Called client-side when the camera is activated for the local player. Don't
// call this function directly from outside.
// ============================================================================

protected simulated function ActivateForLocal() {

  local JBCamera thisCamera;
  local PlayerController ControllerPlayer;
  
  foreach DynamicActors(Class'JBCamera', thisCamera)
    if (thisCamera.bIsActiveLocal)
      thisCamera.DeactivateForLocal();

  ControllerPlayer = Level.GetLocalPlayerController();

  if (JBInterfaceHud(ControllerPlayer.myHUD) != None)
    JBInterfaceHud(ControllerPlayer.myHUD).bWidescreen = bWidescreen;

  if (MotionBlur > 0) {
    if (CameraEffectMotionBlur == None)
      foreach DynamicActors(Class'JBCamera', thisCamera)
        if (thisCamera.CameraEffectMotionBlur != None)
          CameraEffectMotionBlur = thisCamera.CameraEffectMotionBlur;
  
    if (CameraEffectMotionBlur == None)
      CameraEffectMotionBlur = new Class'MotionBlur';

    CameraEffectMotionBlur.BlurAlpha = 255 - MotionBlur;

    ControllerPlayer.CameraEffects.Length = 0;
    ControllerPlayer.AddCameraEffect(CameraEffectMotionBlur);
    }

  bIsActiveLocal = True;
  }


// ============================================================================
// DeactivateForLocal
//
// Called client-side when the camera is deactivated for the local player.
// Don't call this function directly from outside.
// ============================================================================

protected simulated function DeactivateForLocal() {

  local PlayerController ControllerPlayer;

  ControllerPlayer = Level.GetLocalPlayerController();

  if (JBInterfaceHud(ControllerPlayer.myHUD) != None)
    JBInterfaceHud(ControllerPlayer.myHUD).bWidescreen = False;

  ControllerPlayer.CameraEffects.Length = 0;
  
  bIsActiveLocal = False;
  }


// ============================================================================
// UpdateLocal
//
// Called client-side every tick as long as this camera is activated for the
// local player. 
// ============================================================================

protected simulated function UpdateLocal() {

  Level.GetLocalPlayerController().bBehindView = False;
  }


// ============================================================================
// Tick
//
// Checks whether all viewers listed in ListControllerViewer are actually
// viewing from this camera and calls DeactivateFor for those that don't.
// ============================================================================

simulated event Tick(float TimeDelta) {

  local bool bIsActiveLocalNew;
  local int iController;
  
  if (Role == ROLE_Authority)
    for (iController = ListControllerViewer.Length - 1; iController >= 0; iController--)
      if (ListControllerViewer[iController] == None)
        ListControllerViewer.Remove(iController, 1);
      else if (ListControllerViewer[iController].ViewTarget != Self)
        DeactivateFor(ListControllerViewer[iController]);

  if (Level.NetMode == NM_DedicatedServer)
    return;

  bIsActiveLocalNew = Level.GetLocalPlayerController().ViewTarget == Self;

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

simulated function RenderOverlayMaterial(Canvas Canvas) {

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

simulated function RenderOverlayCaption(Canvas Canvas) {

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

simulated function RenderOverlays(Canvas Canvas) {

  RenderOverlayMaterial(Canvas);
  RenderOverlayCaption(Canvas);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  Caption = (bBlinking=True,Color=(R=255,G=255,B=255,A=255),Font="UT2003Fonts.FontEurostile12",Position=0.8);
  Overlay = (Color=(R=255,G=255,B=255,A=255),Style=OverlayStyle_ScaleProportional);

  Texture = Texture'JBCamera';
  RemoteRole = ROLE_SimulatedProxy;
  bNoDelete = True;
  bStatic = False;
  bDirectional = True;
  }