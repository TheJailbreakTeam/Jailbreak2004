// ============================================================================
// JBTriggerRandomPathUnblocker
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id
//
// When triggered, it makes all BlockedPaths in the given array block, except
// for one, which is picked randomly.
// ============================================================================


class JBTriggerRandomPathUnblocker extends Trigger placeable;


// ============================================================================
// Variables
// ============================================================================

var array<BlockedPath> BlockedPaths;


// ============================================================================
// PostBeginPlay
//
// Remove any empty entries from the array.
// ============================================================================

event PostBeginPlay()
{
  local NavigationPoint NP;

  Super.PostBeginPlay();

  for (NP = Level.NavigationPointList; NP != None; NP = NP.nextNavigationPoint)
    if (BlockedPath(NP) != None && NP.Tag == self.event)
      BlockedPaths[BlockedPaths.Length] = BlockedPath(NP);
}


// ============================================================================
// Trigger
//
// Pick a BlockedPath to unblock, and block the rest.
// ============================================================================

event Trigger(Actor A, Pawn P)
{
  local int i;
  local int randomIndex;

  // No BlockedPaths in the array.
  if (BlockedPaths.Length == 0)
    return;

  // Pick a random index in the array.
  randomIndex = rand(BlockedPaths.Length);

  for (i=0; i<BlockedPaths.Length; i++)
      BlockedPaths[i].bBlocked = True;

  BlockedPaths[randomIndex].bBlocked = False;
}
