// ============================================================================
// JBCamControllerArena
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamControllerArena.uc,v 1.5 2004/05/31 18:29:45 mychaeel Exp $
//
// Camera trailing a given player and focusing on another player when that
// player is visible.
// ============================================================================


class JBCamControllerArena extends JBCamController
  noteditinlinenew;


// ============================================================================
// Variables
// ============================================================================

var private float Distance;               // current following distance
var private float DistanceMax;            // maximum following distance
var private vector Offset;                // offset from followed player

var private vector LocationPawnFollowed;  // location of followed pawn in arena
var private vector LocationPawnOpponent;  // location of opponent pawn in arena

var private float TimeTrack;              // time to track invisible opponent
var private bool bHasSeenFollowed;        // followed pawn has been seen
var private bool bHasSeenOpponent;        // opponent pawn has been seen


// ============================================================================
// UpdateMovement
//
// Keeps the camera behind the player and tracks the other player.
// ============================================================================

function UpdateMovement(float TimeDelta)
{
  local float Alpha;
  local rotator Rotation;
  local vector Location;
  local vector LocationTraceHit;
  local vector LocationTraceEnd;
  local vector VectorRotation;
  local vector VectorNormal;
  local Pawn PawnPlayerFollowed;
  local Pawn PawnPlayerOpponent;
  local JBCameraArena CameraArena;

  CameraArena = JBCameraArena(Camera);
  if (CameraArena == None)
    return;

  Alpha = FMin(1.0, TimeDelta * 3.0);

  if (CameraArena.TagPlayerFollowed != None &&
      CameraArena.TagPlayerFollowed.IsInArena())
    PawnPlayerFollowed = CameraArena.TagPlayerFollowed.GetPawn();
  if (CameraArena.TagPlayerOpponent != None &&
      CameraArena.TagPlayerOpponent.IsInArena())
    PawnPlayerOpponent = CameraArena.TagPlayerOpponent.GetPawn();

  if (!bHasSeenFollowed)
    TimeDelta = 0.0;

  if (PawnPlayerFollowed != None) bHasSeenFollowed = True;
  if (PawnPlayerOpponent != None) bHasSeenOpponent = True;

  if (PawnPlayerFollowed != None) {
    if (TimeDelta == 0.0)
           LocationPawnFollowed  =  PawnPlayerFollowed.Location;
      else LocationPawnFollowed += (PawnPlayerFollowed.Location - LocationPawnFollowed) * Alpha;

    if (Vehicle(PawnPlayerFollowed) != None) {
      DistanceMax = Vehicle(PawnPlayerFollowed).Default.TPCamDistance;
      Offset      = Vehicle(PawnPlayerFollowed).Default.TPCamWorldOffset;
    }
    else {
      DistanceMax = Default.DistanceMax;
      Offset      = Default.Offset;
    }
  }
  
  if (PawnPlayerOpponent != None)
    if (TimeDelta == 0.0)
           LocationPawnOpponent  =  PawnPlayerOpponent.Location;
      else LocationPawnOpponent += (PawnPlayerOpponent.Location - LocationPawnOpponent) * Alpha;

  if (TimeDelta == 0.0)
         Distance  =  DistanceMax;
    else Distance += (DistanceMax - Distance) * Alpha;

  if (bHasSeenFollowed && bHasSeenOpponent)
    if (Camera.FastTrace(LocationPawnFollowed, LocationPawnOpponent))
           TimeTrack =      3.0;
      else TimeTrack = FMax(0.0, TimeTrack - TimeDelta);

  if (TimeTrack > 0.0)
    Rotation = rotator(LocationPawnOpponent - LocationPawnFollowed);
  else if (PawnPlayerFollowed == None)
    Rotation = Camera.Rotation;
  else {
    VectorRotation = vector(PawnPlayerFollowed.Rotation);
    VectorRotation.Z = 0;
    Rotation = rotator(VectorRotation);
  }

  if (TimeDelta > 0.0)
    Rotation = Camera.Rotation + Normalize(Rotation - Camera.Rotation) * Alpha;
  Rotation.Roll = 0;
  
  Location = LocationPawnFollowed + Offset;

  VectorRotation = vect(1,0,0) >> Rotation;
  LocationTraceEnd = Location - (Distance + 30.0) * vector(Rotation);

  if (Camera.Trace(LocationTraceHit, VectorNormal, LocationTraceEnd, Location) != None)
    Distance = FMin(Distance, (Location - LocationTraceHit) dot VectorRotation);

  Location -= (Distance - 30.0) * VectorRotation;

  Camera.SetRotation(Rotation);
  Camera.SetLocation(Location);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  DistanceMax = 240.0;
  Offset = (Z=60.0);
}