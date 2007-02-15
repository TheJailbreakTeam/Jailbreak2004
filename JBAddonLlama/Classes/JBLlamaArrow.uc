//=============================================================================
// JBLlamaArrow
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaArrow.uc,v 1.6 2004/05/31 11:14:57 wormbo Exp $
//
// A spinning arrow hovering above a llama's head.
//=============================================================================


class JBLlamaArrow extends Effects notplaceable;


//=============================================================================
// Imports
//=============================================================================

// contains the arrow static mesh and the neccessary textures
#exec obj load file=StaticMeshes\LlamaArrow.usx package=JBAddonLlama.LlamaArrow


//=============================================================================
// Variables
//=============================================================================

var private float SlideInTime;
var private float SlideOutTime;
var private float SlideOutDistance;
var private float HoverBobTime;
var private float HoverBobDistance;

var         JBLlamaTag LlamaTag;                // JBLlamaTag of the Llama marked by this arrow
var private float      LlamaArrowSlidePosition; // 0.0 = out of the screen, 1.0 = right above the head
var private float      LlamaArrowHoverPosition;
var private bool       bDisplayArrow;           // arrow slides down if true and slides up when false
var private vector     LastKnownLlamaLocation;
var private bool       bLlamaDied;


//=============================================================================
// PostNetBeginPlay
//
// Initializes dds this arrow to the list in JBAddonLlama.
//=============================================================================

simulated event PostNetBeginPlay()
{
  LlamaTag = JBLlamaTag(Owner);
  if ( LlamaTag != None && LlamaTag.HUDOverlay != None ) {
    LlamaTag.HUDOverlay.AddArrow(Self);
  }
}


//=============================================================================
// LlamaDied
//
// Called by the JBLlamaTag when the llama died.
//=============================================================================

simulated function LlamaDied()
{
  bLlamaDied = True;
}


//=============================================================================
// GetArrowOwner
//
// Returns the Llama for this arrow if that player is relevant and not dead.
//=============================================================================

simulated function Pawn GetArrowOwner()
{
  if ( LlamaTag != None && LlamaTag.TagPlayer != None )
    return LlamaTag.TagPlayer.GetPawn();
  else if ( LlamaTag != None && Pawn(LlamaTag.Owner) != None )
    return Pawn(LlamaTag.Owner);
  else
    return None;
}


//=============================================================================
// DrawArrow
//
// Draws the arrow for the specified player location or for the last known
// location if no player location was specified.
//=============================================================================

simulated function DrawArrow(Canvas C, optional vector PlayerLocation)
{
  if ( PlayerLocation == vect(0,0,0) || bLlamaDied ) {
    bDisplayArrow = False;
  }
  else {
    LastKnownLlamaLocation = PlayerLocation;
    bDisplayArrow = True;
  }
  
  if ( !IsVisible() )
    return; // nothing to draw
  
  SetLocation(CalculateArrowLocation(C));
  AmbientGlow = Default.AmbientGlow * LlamaArrowSlidePosition;
  
  C.DrawActor(Self, False, True);
}


//=============================================================================
// IsVisible
//
// Returns whether the arrow should actually be drawn.
//=============================================================================

protected simulated function bool IsVisible()
{
  return LlamaArrowSlidePosition > 0.0;
}


//=============================================================================
// CalculateArrowLocation
//
// Returns the arrow's world location based on the local player's FOV, the last
// known location of the llama and the arrow's slide position.
//=============================================================================

protected simulated function vector CalculateArrowLocation(Canvas C)
{
  local vector CameraLocation;
  local rotator CameraRotation;
  local vector X, Y, Z;
  local vector CalculatedLocation;
  local vector DirectionToArrow;
  local float DistanceToArrow;
  
  C.GetCameraLocation(CameraLocation, CameraRotation);
  GetAxes(CameraRotation, X, Y, Z);
  
  // calculate the location
  CalculatedLocation = LastKnownLlamaLocation + LlamaArrowHoverPosition * vect(0,0,1)
      + Smerp(LlamaArrowSlidePosition, 1.0, 0.0) * SlideOutDistance * vect(0,0,1);
  
  DirectionToArrow = Normal(CalculatedLocation - CameraLocation);
  DistanceToArrow = VSize(CalculatedLocation - CameraLocation);
  CalculatedLocation = CameraLocation + DirectionToArrow * 20;
  SetDrawScale(LlamaArrowSlidePosition * Default.DrawScale * 20 / DistanceToArrow);
  
  return CalculatedLocation;
}


//=============================================================================
// Tick
//
// Updates the arrow's relative position.
//=============================================================================

simulated event Tick(float DeltaTime)
{
  if ( bDisplayArrow ) {
    if ( LlamaArrowSlidePosition < 1.0 ) {
      LlamaArrowSlidePosition += DeltaTime / SlideInTime;
      if ( LlamaArrowSlidePosition > 1.0 )
        LlamaArrowSlidePosition = 1.0;
    }
  }
  else {
    if ( LlamaArrowSlidePosition > 0.0 ) {
      LlamaArrowSlidePosition -= DeltaTime / SlideOutTime;
      if ( LlamaArrowSlidePosition < 0.0 )
        LlamaArrowSlidePosition = 0.0;
    }
  }
  
  LlamaArrowHoverPosition = LlamaArrowSlidePosition * HoverBobDistance * (0.5 + 0.5 * Sin(Level.TimeSeconds * 2 * Pi / HoverBobTime));
  
  if ( bLlamaDied && !IsVisible() )
    Destroy();
}


//=============================================================================
// FellOutOfWorld
//
// The arrow should never fall out of the world.
//=============================================================================

simulated event FellOutOfWorld(eKillZType KillType)
{
  log(Self@"fell out of the world.");
}	


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  SlideInTime=1.0
  SlideOutTime=1.0
  SlideOutDistance=500
  HoverBobTime=0.7
  HoverBobDistance=20.0
  
  DrawScale=0.1
  bFixedRotationDir=True
  RotationRate=(Yaw=45000)
  AmbientGlow=254
  bUnlit=True
  Physics=PHYS_Rotating
  Style=STY_Additive
  bHidden=True
  bAlwaysTick=True
  DrawType=DT_StaticMesh
  StaticMesh=StaticMesh'JBAddonLlama.LlamaArrow.LlamaArrow'
}