// ============================================================================
// JBDispositionPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionPlayer.uc,v 1.3 2003/01/19 21:55:50 mychaeel Exp $
//
// Encapsulates a single player icon on the heads-up display.
// ============================================================================


class JBDispositionPlayer extends Object;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\IconPlayer.tga mips=on alpha=on


// ============================================================================
// Properties
// ============================================================================

var() Texture TextureIcon[2];
var() Color ColorIcon[2];


// ============================================================================
// Variables
// ============================================================================

var JBDispositionTeam DispositionTeam;

var private vector Location;
var private float Velocity;
var private float Scale;

var private vector LocationTarget;
var private float ScaleTarget;

var private bool bInitial;


// ============================================================================
// SetTarget
//
// Sets the target location and scale.
// ============================================================================

function SetTarget(vector NewLocationTarget, float NewScaleTarget) {

  LocationTarget = NewLocationTarget;
locationtarget.y=0.2;
  ScaleTarget = NewScaleTarget;
  }


// ============================================================================
// Move
//
// Accelerates and moves the icon towards its current target location. Scales
// the icon along the line of movement if applicable or by time otherwise.
// ============================================================================

function Move(float TimeDelta) {

  local float DistanceTotal;
  local float DistanceDelta;
  local float ScaleDelta;
  local vector LocationDelta;

  if (bInitial) {
    bInitial = False;
    Location = LocationTarget;
    }

  else {
    DistanceTotal = Sqrt(Square(LocationTarget.X - Location.X) +
                         Square(LocationTarget.Y - Location.Y));
  
    if (DistanceTotal > 0.0) {
      Velocity += 1.0 * TimeDelta;
      DistanceDelta = Velocity * TimeDelta;
  
      LocationDelta = LocationTarget - Location;
      if (DistanceDelta < DistanceTotal)
        LocationDelta *= DistanceDelta / DistanceTotal;
  
      Location += LocationDelta;
      if (Location == LocationTarget)
        Velocity = 0.0;
      }
  
    if (Scale != ScaleTarget) {
      if (DistanceTotal > 0.0)
        ScaleDelta = Abs(ScaleTarget - Scale) * DistanceDelta / DistanceTotal;
      else
        ScaleDelta = 2.0 * TimeDelta;
      
      if (Scale < ScaleTarget)
        Scale = FMin(ScaleTarget, Scale + ScaleDelta);
      else
        Scale = FMax(ScaleTarget, Scale - ScaleDelta);
      }
    }
  }


// ============================================================================
// Fadeout
//
// Gradually fades the icon out. Returns whether the icon has been completely
// faded out already. When it has, it can be removed.
// ============================================================================

function bool Fadeout(float TimeDelta) {

  Scale = FMax(0.0, Scale - 2.0 * TimeDelta);

  return (Scale == 0.0);
  }


// ============================================================================
// Draw
//
// Renders the icon at its current location and scale on the given canvas.
// ============================================================================

function Draw(Canvas Canvas, float ScaleGlobal) {

  local float WidthIcon;
  local float HeightIcon;

  WidthIcon  = 32.0 / 1600.0 * Canvas.ClipX * Scale * ScaleGlobal;
  HeightIcon = 64.0 / 1200.0 * Canvas.ClipY * Scale * ScaleGlobal;

  Canvas.SetPos(Canvas.ClipX * (Location.X * ScaleGlobal + 0.5) - WidthIcon  / 2.0,
                Canvas.ClipY *  Location.Y * ScaleGlobal        - HeightIcon / 2.0);

  Canvas.DrawColor = ColorIcon[DispositionTeam.Team.TeamIndex];
  Canvas.DrawRect(TextureIcon[DispositionTeam.Team.TeamIndex], WidthIcon, HeightIcon);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextureIcon[0] = Texture'IconPlayer';
  TextureIcon[1] = Texture'IconPlayer';
  ColorIcon[0] = (R=255,G=0,B=0,A=255);
  ColorIcon[1] = (R=0,G=0,B=255,A=255);

  bInitial = True;
  }