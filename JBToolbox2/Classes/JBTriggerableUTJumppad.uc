// ============================================================================
// JBTriggerableUTJumppad
// Copyright 2005 by Cooldude
// $Id$
//
// A JumpPad that can be triggered.
// ============================================================================


class JBTriggerableUTJumppad extends UTJumpPad
  placeable;


// ============================================================================
// Variables
// ============================================================================

var (UTJumppad) bool bInitialyActive;
var bool bActive;


// ============================================================================
// PostBeginPlay
//
// (De)activate the JumpPad, and remember the initial value so it resets
// properly.
// ============================================================================

function PostBeginPlay()
{
  bActive = bInitialyActive;

  Super.PostBeginPlay();
}


// ============================================================================
// Trigger
//
// Activate/Deactivate the JumpPad.
// ============================================================================

function Trigger( actor Other, pawn EventInstigator )
{
  bActive = !bActive;
}


// ============================================================================
// Touch
//
// Only let Touch() work if the JumpPad is active.
// ============================================================================

function Touch(Actor Other)
{
  if (!bActive)
    return;

  Super.Touch(Other);
}


// ============================================================================
// SpecialCost
//
// Don't let bots use the JumpPad if it's not active.
// ============================================================================

function int SpecialCost(Pawn Other, ReachSpec Path)
{
  if (!bActive)
    return 100000000;

  Super.SpecialCost(Other,Path);
}
