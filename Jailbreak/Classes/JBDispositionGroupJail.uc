// ============================================================================
// JBDispositionGroupJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionGroupJail.uc,v 1.5 2003/06/15 21:31:33 mychaeel Exp $
//
// Manages the icons of jailed players on a team, arranging them in the circle
// displayed next to the team status widget.
// ============================================================================


class JBDispositionGroupJail extends JBDispositionGroup;


// ============================================================================
// Types
// ============================================================================

struct TFormation
{
  var vector Location[6];  // formation locations of icons
  var float Scale;         // scale of icons within formation
};


// ============================================================================
// Constants
// ============================================================================

const LocationCenterX = 0.034;
const LocationCenterY = 0.047;


// ============================================================================
// Variables
// ============================================================================

var TFormation Formation[6];         // icon formations

var string FontCounter;              // font for counter for six or more icons
var float ScaleCounter;              // relative font scale
var vector LocationCounter;          // relative location of counter
var Color ColorCounter[2];           // team colors for counter

var private float FadeCounter;       // transparency of counter
var private string TextCounter;      // last displayed counter text
var private Font FontObjectCounter;  // loaded font object


// ============================================================================
// Initialize
//
// Loads the counter font.
// ============================================================================

function Initialize(JBDispositionTeam DispositionTeamOwner)
{
  if (FontCounter != "")
    FontObjectCounter = Font(DynamicLoadObject(FontCounter, Class'Font'));

  Super.Initialize(DispositionTeamOwner);
}


// ============================================================================
// BelongsToGroup
//
// Players belong to this group when they are not free.
// ============================================================================

function bool BelongsToGroup(JBTagPlayer TagPlayer)
{
  if (TagPlayer.IsFree())
    return False;

  return Super.BelongsToGroup(TagPlayer);
}


// ============================================================================
// Setup
//
// Arranges all icons in the circle next to the team status widget.
// ============================================================================

function Setup()
{
  local int iDisposition;
  local int iFormation;
  local float ScaleTarget;
  local vector LocationTarget;

  iFormation = Min(ArrayCount(Formation), ListDispositionPlayer.Length) - 1;

  for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++) {
    ScaleTarget    = Formation[iFormation].Scale;
    LocationTarget = Formation[iFormation].Location[Min(iDisposition, ArrayCount(Formation[0].Location) - 1)];

    if (LocationTarget.Z == 0)
      ScaleTarget = 0.0;

    LocationTarget.X += LocationCenterX;
    LocationTarget.Y += LocationCenterY;

    if (DispositionTeam.Team.TeamIndex != 0)
      LocationTarget.X = -LocationTarget.X;

    ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, ScaleTarget);
  }
}


// ============================================================================
// Move
//
// Moves icons and fades the counter in our out.
// ============================================================================

function Move(float TimeDelta)
{
  if (ListDispositionPlayer.Length >= ArrayCount(Formation))
    FadeCounter = FMin(1.0, FadeCounter + TimeDelta * 2.0);
  else
    FadeCounter = FMax(0.0, FadeCounter - TimeDelta * 2.0);

  Super.Move(TimeDelta);
}


// ============================================================================
// Draw
//
// Draws the number of players next to the icon if required.
// ============================================================================

function Draw(Canvas Canvas)
{
  local float ScaleCanvas;
  local float ScaleWidget;
  local vector LocationScreenCounter;

  if (ListDispositionPlayer.Length >= ArrayCount(Formation))
    TextCounter = string(ListDispositionPlayer.Length);

  if (FadeCounter > 0.0) {
    ScaleCanvas = Canvas.Viewport.Actor.myHUD.HudCanvasScale;
    ScaleWidget = Canvas.Viewport.Actor.myHUD.HudScale;

    Canvas.DrawColor = ColorCounter[DispositionTeam.Team.TeamIndex];
    Canvas.DrawColor.A = FadeCounter * Canvas.DrawColor.A;
    Canvas.Font = FontObjectCounter;
    Canvas.FontScaleX = ScaleCounter * ScaleWidget * ScaleCanvas * Canvas.ClipX / 1600.0;
    Canvas.FontScaleY = ScaleCounter * ScaleWidget * ScaleCanvas * Canvas.ClipX / 1600.0;

    LocationScreenCounter.X = (LocationCenterX + LocationCounter.X) * ScaleWidget;
    LocationScreenCounter.Y = (LocationCenterY + LocationCounter.Y) * ScaleWidget;

    if (DispositionTeam.Team.TeamIndex != 0)
      LocationScreenCounter.X = -LocationScreenCounter.X;
    LocationScreenCounter.X += 0.5;

    Canvas.DrawScreenText(
      TextCounter,
      ScaleCanvas * (LocationScreenCounter.X - 0.5) + 0.5,
      ScaleCanvas * (LocationScreenCounter.Y - 0.5) + 0.5,
      DP_MiddleMiddle);

    Canvas.FontScaleX = Canvas.Default.FontScaleX;
    Canvas.FontScaleY = Canvas.Default.FontScaleY;
  }

  Super.Draw(Canvas);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  FontCounter = "UT2003Fonts.FontEurostile37";
  ScaleCounter = 0.7;
  LocationCounter = (X=0.007,Y=0.014);
  ColorCounter[0] = (R=255,G=0,B=0,A=255);
  ColorCounter[1] = (R=0,G=0,B=255,A=255);

  Formation[0] = (Scale=1.0,Location[0]=(X=+0.000,Y=+0.000,Z=1));
  Formation[1] = (Scale=1.0,Location[0]=(X=+0.008,Y=+0.000,Z=1),Location[1]=(X=-0.008,Y=+0.000,Z=1));
  Formation[2] = (Scale=0.9,Location[0]=(X=+0.010,Y=+0.008,Z=1),Location[1]=(X=-0.010,Y=+0.008,Z=1),Location[2]=(X=+0.000,Y=-0.012,Z=1));
  Formation[3] = (Scale=0.9,Location[0]=(X=+0.012,Y=+0.000,Z=1),Location[1]=(X=-0.012,Y=+0.000,Z=1),Location[2]=(X=+0.000,Y=-0.014,Z=1),Location[3]=(X=+0.000,Y=+0.014,Z=1));
  Formation[4] = (Scale=0.9,Location[0]=(X=+0.012,Y=-0.010,Z=1),Location[1]=(X=-0.012,Y=-0.010,Z=1),Location[2]=(X=+0.000,Y=-0.014,Z=1),Location[3]=(X=+0.006,Y=+0.014,Z=1),Location[4]=(X=-0.006,Y=+0.014,Z=1));
  Formation[5] = (Scale=0.9,Location[0]=(X=+0.007,Y=+0.014,Z=0),Location[1]=(X=-0.013,Y=+0.001,Z=1),Location[2]=(X=-0.002,Y=-0.016,Z=1),Location[3]=(X=+0.007,Y=+0.014,Z=0),Location[4]=(X=+0.007,Y=+0.014,Z=0),Location[5]=(X=+0.007,Y=+0.014,Z=0));

  AddIconForFadein     = AddIconToEnd;
  AddIconForChange     = AddIconToEnd;
  RemoveIconForChange  = RemoveIconFromEnd;
  RemoveIconForFadeout = RemoveIconFromEnd;
}