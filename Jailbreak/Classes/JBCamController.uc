// ============================================================================
// JBCamController
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Controls movement of a camera actor.
// ============================================================================


class JBCamController extends Object
  hidecategories (Object)
  editinlinenew;


// ============================================================================
// Properties
// ============================================================================

var() bool bIgnoreOutsideCollision;  // ignore players outside collision

var() bool bIgnorePlayersFree;       // ignore free players
var() bool bIgnorePlayersInArena;    // ignore players in arena
var() bool bIgnorePlayersInJail;     // ignore players in jail

var() bool bIgnoreTeamRed;           // ignore players on red team
var() bool bIgnoreTeamBlue;          // ignore players on blue team

var() float RatingFactor;            // factor to bias camera rating


// ============================================================================
// Variables
// ============================================================================

var JBCamera Camera;                 // camera controlled by this object


// ============================================================================
// Init
//
// Called both server-side and client-side at game start for initialization.
// ============================================================================

function Init();


// ============================================================================
// UpdateMovement
//
// Called both server-side and client-side once a tick as long as the camera
// is being used by at least one player. The given delta time reflects the
// time since the last movement update; the very first update is passed zero.
// ============================================================================

function UpdateMovement(float TimeDelta);


// ============================================================================
// IsPlayerIgnored
//
// Checks and returns whether the given player should be ignored by this
// camera. This does not affect which players are actually displayed, just
// which ones are rated and possibly tracked by it.
// ============================================================================

function bool IsPlayerIgnored(JBTagPlayer TagPlayer)
{
  local int iTeam;
  local Pawn PawnPlayer;

  if (TagPlayer == None)
    return True;

  PawnPlayer = TagPlayer.GetPawn();
  if (PawnPlayer == None)
    return True;
  
  if (bIgnoreOutsideCollision && !Camera.TouchingActor(PawnPlayer))
    return True;

  if (bIgnorePlayersFree    && TagPlayer.IsFree())    return True;
  if (bIgnorePlayersInArena && TagPlayer.IsInArena()) return True;
  if (bIgnorePlayersInJail  && TagPlayer.IsInJail())  return True;

  iTeam = TagPlayer.GetTeam().TeamIndex;
  if (bIgnoreTeamRed  && iTeam == 0) return True;
  if (bIgnoreTeamBlue && iTeam == 1) return True;
  
  return False;
}


// ============================================================================
// RateCurrentView
//
// Returns a cumulated rating of the view this camera has on players at its
// current location and rotation. Assumes a 4:3 screen aspect ratio.
// ============================================================================

function float RateCurrentView()
{
  local float Rating;
  local float Limit;
  local vector LocationPlayer;
  local vector LocationTransformed;
  local Coords CoordsCamera;
  local Pawn PawnPlayer;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  GetAxes(Camera.Rotation,
    CoordsCamera.XAxis,
    CoordsCamera.YAxis,
    CoordsCamera.ZAxis);
  
  Limit = Sin(Camera.FieldOfView * Pi / 360.0);
  
  firstTagPlayer = JBGameReplicationInfo(Camera.Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
    if (IsPlayerIgnored(thisTagPlayer))
      continue;
  
    PawnPlayer = thisTagPlayer.GetPawn();
    if (PawnPlayer == None)
      continue;
    
    LocationPlayer = Normal(PawnPlayer.Location - Camera.Location);
    
    LocationTransformed.X = LocationPlayer dot CoordsCamera.YAxis;
    LocationTransformed.Y = LocationPlayer dot CoordsCamera.ZAxis;
    LocationTransformed.Z = LocationPlayer dot CoordsCamera.XAxis;
    
    if (LocationTransformed.Z <= 0.0)
      continue;  // directly on or behind camera
    
    LocationTransformed /= Limit;
    
    if (Abs(LocationTransformed.X) <= 1.00 &&
        Abs(LocationTransformed.Y) <= 0.75)
      Rating += thisTagPlayer.RateViewOnPlayer(Camera.Location);
  }
  
  // correct rating for camera zoom
  Rating /= Square(Limit);

  return Rating * RatingFactor;
}


// ============================================================================
// InterpolateRotation
//
// Smoothly rotates the camera to the given desired rotation.
// ============================================================================

function InterpolateRotation(rotator Rotation, float TimeDelta)
{
  if (TimeDelta == 0.0)
         Camera.SetRotation(Rotation);
    else Camera.SetRotation(Camera.Rotation + Normalize(Rotation - Camera.Rotation) * FMin(1.0, TimeDelta * 2.0));
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  RatingFactor = 1.0;
}