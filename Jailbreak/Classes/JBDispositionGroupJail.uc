// ============================================================================
// JBDispositionGroupJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
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
// Properties
// ============================================================================

var() TFormation Formation[6];


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
  
  iFormation = ListDispositionPlayer.Length - 1;
  
  for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++) {
    ScaleTarget    = Formation[iFormation].Scale;
    LocationTarget = Formation[iFormation].Location[iDisposition];

    LocationTarget.X += 0.034;
    LocationTarget.Y += 0.047;

    if (DispositionTeam.Team.TeamIndex != 0)
      LocationTarget.X = -LocationTarget.X;
    
    ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, ScaleTarget);
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

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