// ============================================================================
// JBScout
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBScout.uc,v 1.3 2003/06/29 10:14:00 mychaeel Exp $
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
  Health = Default.Health;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bCollideActors  = False;
  bCollideWorld   = False;
  CollisionRadius = 25.0;
  CollisionHeight = 44.0;
  CrouchHeight    = 29.0;
  CrouchRadius    = 25.0;
}