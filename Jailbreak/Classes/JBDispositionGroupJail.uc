// ============================================================================
// JBDispositionGroupJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionGroupJail.uc,v 1.1 2003/01/01 22:11:16 mychaeel Exp $
//
// Manages the icons of jailed players on a team, arranging them in the circle
// displayed next to the team status widget.
// ============================================================================


class JBDispositionGroupJail extends JBDispositionGroup;


// ============================================================================
// Types
// ============================================================================

struct TFormation {

  var() vector Location[6];  // formation locations of icons
  var() float Scale;         // scale of icons within formation
  };


// ============================================================================
// Constants
// ============================================================================

const LocationCenterX = 0.034;
const LocationCenterY = 0.047;
  

// ============================================================================
// Variables
// ============================================================================

var TFormation Formation[6];     // icon formations for up to six players

var string FontCounter;          // font for counter for more than six players
var float ScaleCounter;          // relative font scale
var Color ColorCounter[2];       // team colors for counter

var private float FadeCounter;       // transparency of counter
var private string TextCounter;      // last displayed counter text
var private Font FontObjectCounter;  // loaded font object


// ============================================================================
// Initialize
//
// Loads the counter font.
// ============================================================================

function Initialize(JBDispositionTeam DispositionTeamOwner) {

  if (FontCounter != "")
    FontObjectCounter = Font(DynamicLoadObject(FontCounter, Class'Font'));

  Super.Initialize(DispositionTeamOwner);
  }


// ============================================================================
// BelongsToGroup
//
// Players belong to this group when they are not free.
// ============================================================================

function bool BelongsToGroup(JBTagPlayer TagPlayer) {

  if (TagPlayer.IsFree())
    return False;

  return Super.BelongsToGroup(TagPlayer);
  }


// ============================================================================
// Setup
//
// Arranges all icons in the circle next to the team status widget.
// ============================================================================

function Setup() {

  local int iDisposition;
  local int iFormation;
  local float ScaleTarget;
  local vector LocationTarget;
  
  if (ListDispositionPlayer.Length <= ArrayCount(Formation)) {
    iFormation = ListDispositionPlayer.Length - 1;
  
    for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++) {
      ScaleTarget    = Formation[iFormation].Scale;
      LocationTarget = Formation[iFormation].Location[iDisposition];
  
      LocationTarget.X += LocationCenterX;
      LocationTarget.Y += LocationCenterY;
  
      if (DispositionTeam.Team.TeamIndex != 0)
        LocationTarget.X = -LocationTarget.X;
      
      ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, ScaleTarget);
      }
    }
  
  else {
    LocationTarget.X = LocationCenterX;
    LocationTarget.Y = LocationCenterY;

    for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++)
      ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, 0.0);
    }
  }


// ============================================================================
// Move
//
// Moves icons and fades the counter in our out.
// ============================================================================

function Move(float TimeDelta) {

  if (ListDispositionPlayer.Length > ArrayCount(Formation))
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

function Draw(Canvas Canvas, float ScaleGlobal) {

  local vector LocationCounter;

  if (ListDispositionPlayer.Length > ArrayCount(Formation))
    TextCounter = string(ListDispositionPlayer.Length);

  if (FadeCounter > 0.0) {
    Canvas.DrawColor = ColorCounter[DispositionTeam.Team.TeamIndex];
    Canvas.DrawColor.A = FadeCounter * Canvas.DrawColor.A;
    Canvas.Font = FontObjectCounter;
    Canvas.FontScaleX = ScaleGlobal * ScaleCounter * Canvas.ClipX / 1600.0;
    Canvas.FontScaleY = ScaleGlobal * ScaleCounter * Canvas.ClipX / 1600.0;

    LocationCounter.X =  LocationCenterX          * ScaleGlobal;
    LocationCounter.Y = (LocationCenterY + 0.002) * ScaleGlobal;

    if (DispositionTeam.Team.TeamIndex != 0)
      LocationCounter.X = -LocationCounter.X;
    
    Canvas.DrawScreenText(TextCounter,
      LocationCounter.X + 0.5,
      LocationCounter.Y, DP_MiddleMiddle);
    Canvas.FontScaleX = Canvas.Default.FontScaleX;
    Canvas.FontScaleY = Canvas.Default.FontScaleY;
    }

  Super.Draw(Canvas, ScaleGlobal);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  FontCounter = "UT2003Fonts.FontEurostile37";
  ScaleCounter = 1.0;
  ColorCounter[0] = (R=255,G=0,B=0,A=255);
  ColorCounter[1] = (R=0,G=0,B=255,A=255);

  Formation[0] = (Scale=1.0,Location[0]=(X=+0.000,Y=+0.000));
  Formation[1] = (Scale=1.0,Location[0]=(X=+0.008,Y=+0.000),Location[1]=(X=-0.008,Y=+0.000));
  Formation[2] = (Scale=0.9,Location[0]=(X=+0.010,Y=+0.008),Location[1]=(X=-0.010,Y=+0.008),Location[2]=(X=+0.000,Y=-0.012));
  Formation[3] = (Scale=0.9,Location[0]=(X=+0.012,Y=+0.000),Location[1]=(X=-0.012,Y=+0.000),Location[2]=(X=+0.000,Y=-0.014),Location[3]=(X=+0.000,Y=+0.014));
  Formation[4] = (Scale=0.9,Location[0]=(X=+0.012,Y=-0.010),Location[1]=(X=-0.012,Y=-0.010),Location[2]=(X=+0.000,Y=-0.014),Location[3]=(X=+0.006,Y=+0.014),Location[4]=(X=-0.006,Y=+0.014));
  Formation[5] = (Scale=0.9,Location[0]=(X=+0.012,Y=-0.013),Location[1]=(X=-0.012,Y=-0.013),Location[2]=(X=+0.000,Y=-0.013),Location[3]=(X=+0.012,Y=+0.013),Location[4]=(X=+0.000,Y=+0.013),Location[5]=(X=-0.012,Y=+0.013));

  AddIconForFadein     = AddIconToEnd;
  AddIconForChange     = AddIconToEnd;
  RemoveIconForChange  = RemoveIconFromEnd;
  RemoveIconForFadeout = RemoveIconFromEnd;
  }