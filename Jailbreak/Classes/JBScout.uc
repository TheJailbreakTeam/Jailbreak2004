// ============================================================================
// JBScout
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Pawn used by JBTagNavigation to calculate travelling distances between two
// arbitrary actors in a map.
// ============================================================================


class JBScout extends Pawn;


// ============================================================================
// Died
//
// Never die (even if you fall out of the world or anything like that).
// ============================================================================

function Died(Controller ControllerKiller, class<DamageType> ClassDamageType, vector LocationHit)
{
  Log(Level.TimeSeconds @ "JBScout.Died");
  Health = Default.Health;
}


// ============================================================================
// Destroyed
//
// Logs a warning to help debugging.
// ============================================================================

event Destroyed()
{
  Log(Level.TimeSeconds @ "JBScout.Destroyed");
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bProjTarget     = False;
  bCollideActors  = False;
  bCollideWorld   = False;
  CollisionRadius = 25.0;
  CollisionHeight = 44.0;
  CrouchHeight    = 29.0;
  CrouchRadius    = 25.0;
}