// ============================================================================
// JBCamControllerArena
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamControllerArena.uc,v 1.3 2004/05/28 17:09:56 mychaeel Exp $
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

  if (CameraArena.TagPlayerFollowed != None)
    PawnPlayerFollowed = CameraArena.TagPlayerFollowed.GetPawn();
  if (PawnPlayerFollowed != None && CameraArena.TagPlayerFollowed.IsInArena())
    if (TimeDelta == 0.0)
           LocationPawnFollowed  =  PawnPlayerFollowed.Location;
      else LocationPawnFollowed += (PawnPlayerFollowed.Location - LocationPawnFollowed) * Alpha;
  
  if (CameraArena.TagPlayerOpponent != None)
    PawnPlayerOpponent = CameraArena.TagPlayerOpponent.GetPawn();
  if (PawnPlayerOpponent != None && CameraArena.TagPlayerOpponent.IsInArena())
    if (TimeDelta == 0.0)
           LocationPawnOpponent  =  PawnPlayerOpponent.Location;
      else LocationPawnOpponent += (PawnPlayerOpponent.Location - LocationPawnOpponent) * Alpha;

  if (TimeDelta == 0.0)
         Distance  =  DistanceMax;
    else Distance += (DistanceMax - Distance) * Alpha;

  if (Camera.FastTrace(LocationPawnFollowed, LocationPawnOpponent))
         TimeTrack =      3.0;
    else TimeTrack = FMax(0.0, TimeTrack - TimeDelta);

  if (TimeTrack > 0.0 ||
      CameraArena.TagPlayerFollowed == None ||
     !CameraArena.TagPlayerFollowed.IsInArena()) {
    Rotation = rotator(LocationPawnOpponent - LocationPawnFollowed);
  }
  else if (PawnPlayerFollowed == None) {
    Rotation = Camera.Rotation;
  }
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