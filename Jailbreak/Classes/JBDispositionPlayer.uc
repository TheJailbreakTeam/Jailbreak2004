// ============================================================================
// JBDispositionPlayer
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionPlayer.uc,v 1.9 2004/02/16 17:17:02 mychaeel Exp $
//
// Encapsulates a single player icon on the heads-up display.
// ============================================================================


class JBDispositionPlayer extends Object;


// ============================================================================
// Types
// ============================================================================

struct SpriteWidget
{
  var Material WidgetTexture;
  var IntBox TextureCoords;
  var float TextureScale;
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

function SetTarget(vector NewLocationTarget, float NewScaleTarget)
{
  LocationTarget = NewLocationTarget;
  ScaleTarget = NewScaleTarget;
}


// ============================================================================
// Move
//
// Accelerates and moves the icon towards its current target location. Scales
// the icon along the line of movement if applicable or by time otherwise.
// ============================================================================

function Move(float TimeDelta)
{
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

function bool Fadeout(float TimeDelta)
{
  Scale = FMax(0.0, Scale - 2.0 * TimeDelta);

  return (Scale == 0.0);
}


// ============================================================================
// Draw
//
// Renders the icon at its current location and scale on the given canvas.
// Takes the rendering color from the team symbols displayed on the screen.
// ============================================================================

function Draw(Canvas Canvas)
{
  local float ScaleCanvas;
  local float ScaleWidget;
  local float ScaleIconTexture;
  local vector LocationIcon;
  local vector SizeIcon;
  local vector SizeIconTexture;
  local HudCTeamDeathMatch HudCTeamDeathMatch;

  HudCTeamDeathMatch = HudCTeamDeathMatch(Canvas.Viewport.Actor.myHUD);

  ScaleCanvas = HudCTeamDeathMatch.HudCanvasScale;
  ScaleWidget = HudCTeamDeathMatch.HudScale;

  SizeIconTexture.X = SpriteWidgetPlayer.TextureCoords.X2 - SpriteWidgetPlayer.TextureCoords.X1;
  SizeIconTexture.Y = SpriteWidgetPlayer.TextureCoords.Y2 - SpriteWidgetPlayer.TextureCoords.Y1;

  ScaleIconTexture = SpriteWidgetPlayer.TextureScale * Scale * ScaleWidget;

  SizeIcon.X = Abs(SizeIconTexture.X) * Canvas.ClipX / 640.0 * ScaleIconTexture;
  SizeIcon.Y = Abs(SizeIconTexture.Y) * Canvas.ClipY / 480.0 * ScaleIconTexture;

  LocationIcon.X = (Location.X * ScaleWidget + 0.5) - SizeIcon.X / 2.0 / Canvas.ClipX;
  LocationIcon.Y =  Location.Y * ScaleWidget        - SizeIcon.Y / 2.0 / Canvas.ClipY;

  Canvas.Style = 5;  // ERenderStyle.STY_Alpha
  Canvas.DrawColor = HudCTeamDeathMatch.TeamSymbols[DispositionTeam.Team.TeamIndex].Tints[HudCTeamDeathMatch.TeamIndex];

  Canvas.SetPos(
    Canvas.ClipX * (ScaleCanvas * (LocationIcon.X - 0.5) + 0.5),
    Canvas.ClipY * (ScaleCanvas * (LocationIcon.Y - 0.5) + 0.5));
  Canvas.DrawTile(SpriteWidgetPlayer.WidgetTexture,
    SizeIcon.X * ScaleCanvas,
    SizeIcon.Y * ScaleCanvas,
    SpriteWidgetPlayer.TextureCoords.X1,
    SpriteWidgetPlayer.TextureCoords.Y1,
    SizeIconTexture.X,
    SizeIconTexture.Y);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  SpriteWidgetPlayer = (WidgetTexture=Material'SpriteWidgetHud',TextureCoords=(X1=16,Y1=352,X2=50,Y2=418),TextureScale=0.21);
  bInitial = True;
}