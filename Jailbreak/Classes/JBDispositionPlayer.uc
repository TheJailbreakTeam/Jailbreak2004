// ============================================================================
// JBDispositionPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionPlayer.uc,v 1.5 2003/02/23 12:33:05 mychaeel Exp $
//
// Encapsulates a single player icon on the heads-up display.
// ============================================================================


class JBDispositionPlayer extends Object;


// ============================================================================
// Types
// ============================================================================

struct SpriteWidget {

  var Material WidgetTexture;
  var IntBox TextureCoords;
  var float TextureScale;
  var Color Tints[2];
  };


// ============================================================================
// Properties
// ============================================================================

var SpriteWidget SpriteWidgetPlayer;


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

  local int WidthIconTexture;
  local int HeightIconTexture;
  local float WidthIcon;
  local float HeightIcon;
  local float ScaleIconTexture;

  WidthIconTexture  = SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1;
  HeightIconTexture = SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1;

  ScaleIconTexture = SpriteWidgetPlayer.TextureScale * Scale * ScaleGlobal;

  WidthIcon  = Abs(WidthIconTexture)  * Canvas.ClipX / 512.0 * ScaleIconTexture;
  HeightIcon = Abs(HeightIconTexture) * Canvas.ClipY / 384.0 * ScaleIconTexture;

  Canvas.SetPos(Canvas.ClipX * (Location.X * ScaleGlobal + 0.5) - WidthIcon  / 2.0,
                Canvas.ClipY *  Location.Y * ScaleGlobal        - HeightIcon / 2.0);

  Canvas.Style = 5;  // ERenderStyle.STY_Alpha
  Canvas.DrawColor = SpriteWidgetPlayer.Tints[DispositionTeam.Team.TeamIndex];

  Canvas.DrawTile(SpriteWidgetPlayer.WidgetTexture,
    WidthIcon,
    HeightIcon,
    SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y1,
    WidthIconTexture,
    HeightIconTexture);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  SpriteWidgetPlayer = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=16,Y1=352,X2=50,Y2=418),TextureScale=0.17,Tints[0]=(R=255,G=0,B=0,A=255),Tints[1]=(R=0,G=0,B=255,A=255));
  bInitial = True;
  }