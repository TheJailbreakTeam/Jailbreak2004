// ============================================================================
// JBDispositionGroupFree
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDispositionGroupFree.uc,v 1.1 2003/01/01 22:11:16 mychaeel Exp $
//
// Manages the icons of free players on a team, arranging them in a horizontal
// row below the team status widget.
// ============================================================================


class JBDispositionGroupFree extends JBDispositionGroup;


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
    LocationTarget.X = 0.110 + 0.014 * iDisposition;
    LocationTarget.Y = 0.110;

    if (DispositionTeam.Team.TeamIndex == 0)
      LocationTarget.X = -LocationTarget.X;

    ListDispositionPlayer[iDisposition].SetTarget(LocationTarget, 1.0);
  }
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  AddIconForFadein     = AddIconToEnd;
  AddIconForChange     = AddIconToStart;
  RemoveIconForChange  = RemoveIconFromStart;
  RemoveIconForFadeout = RemoveIconFromEnd;
}