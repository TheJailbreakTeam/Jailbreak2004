// ============================================================================
// JBCamera
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// General-purpose camera for Jailbreak.
// ============================================================================


class JBCamera extends Keypoint;


// ============================================================================
// Properties
// ============================================================================

var() Material OverlayMaterial;  // overlay drawn on user's screen
var() bool bOverlayDistort;      // overlay may be distorted to fit screen 


// ============================================================================
// Variables
// ============================================================================

var private array<PlayerController> ListControllerViewer;


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

  if (PlayerController(Controller) == None)
    return;

  PlayerController(Controller).SetViewTarget(Self);

  if (!IsViewer(Controller))
    ListControllerViewer[ListControllerViewer.Length] = PlayerController(Controller);

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

  if (PlayerController(Controller) == None)
    return;

  PlayerController(Controller).SetViewTarget(Controller.Pawn);
  
  for (iController = ListControllerViewer.Length - 1; iController >= 0; iController--)
    if (ListControllerViewer[iController] == Controller)
      ListControllerViewer.Remove(iController, 1);
  
  if (ListControllerViewer.Length == 0)
    Disable('Tick');
  }


// ============================================================================
// Tick
//
// Checks whether all viewers listed in ListControllerViewer are actually
// viewing from this camera and calls DeactivateFor for those that don't.
// ============================================================================

event Tick(float TimeDelta) {

  local int iController;
  
  for (iController = ListControllerViewer.Length - 1; iController >= 0; iController--)
    if (ListControllerViewer[iController].ViewTarget != Self)
      DeactivateFor(ListControllerViewer[iController]);
  }


// ============================================================================
// RenderOverlays
//
// Renders the overlay material on the user's screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas) {

  local float RatioStretchTotal;
  local vector RatioStretch;
  local vector SizeOverlay;

  if (OverlayMaterial != None) {
    if (bOverlayDistort) {
      Canvas.SetPos(0, 0);
      Canvas.DrawTileStretched(OverlayMaterial, Canvas.ClipX, Canvas.ClipY);
      }
    
    else {
      RatioStretch.X = Canvas.ClipX / OverlayMaterial.MaterialUSize();
      RatioStretch.Y = Canvas.ClipY / OverlayMaterial.MaterialVSize();
      RatioStretchTotal = FMax(RatioStretch.X, RatioStretch.Y);

      SizeOverlay.X = Canvas.ClipX * RatioStretchTotal;
      SizeOverlay.Y = Canvas.ClipY * RatioStretchTotal;
      
      Canvas.SetPos((Canvas.ClipX - SizeOverlay.X) / 2,
                    (Canvas.ClipY - SizeOverlay.Y) / 2);
      Canvas.DrawTileScaled(OverlayMaterial, RatioStretchTotal, RatioStretchTotal);
      }
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bOverlayDistort = False;

  RemoteRole = ROLE_SimulatedProxy;
  bNoDelete = True;
  bStatic = False;
  }