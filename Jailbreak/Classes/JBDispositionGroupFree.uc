// ============================================================================
// JBDispositionGroupFree
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionGroupFree.uc,v 1.3 2004/04/05 22:27:55 mychaeel Exp $
//
// Manages the icons of free players on a team, arranging them in a horizontal
// row below the team status widget.
// ============================================================================


class JBDispositionGroupFree extends JBDispositionGroup;


// ============================================================================
// Variables
// ============================================================================

var vector LocationPlayers;  // upper-inner corner of row of player icons
var float WidthPlayer;       // width of a single player icon


// ============================================================================
// BelongsToGroup
//
// Players belong to this group when they are free.
// ============================================================================

function bool BelongsToGroup(JBTagPlayer TagPlayer)
{
  if (TagPlayer.IsFree())
    return Super.BelongsToGroup(TagPlayer);

  return False;
}


// ============================================================================
// Setup
//
// Arranges all icons horizontally below the team status widget.
// ============================================================================

function Setup()
{
  local int iDisposition;
  local vector LocationTarget;

  for (iDisposition = 0; iDisposition < ListDispositionPlayer.Length; iDisposition++) {
    LocationTarget.X = LocationPlayers.X + Scale * WidthPlayer * iDisposition;
    LocationTarget.Y = LocationPlayers.Y;

    if (DispositionTeam.Team.TeamIndex == 0)
      LocationTarget.X = -LocationTarget.X;

    ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, Scale);
  }
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  LocationPlayers = (X=0.110,Y=0.085);
  WidthPlayer = 0.014;

  AddIconForFadein     = AddIconToEnd;
  AddIconForChange     = AddIconToStart;
  RemoveIconForChange  = RemoveIconFromStart;
  RemoveIconForFadeout = RemoveIconFromEnd;
}