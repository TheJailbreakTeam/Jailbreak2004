// ============================================================================
// JBScout
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBScout.uc,v 1.1 2003/01/19 19:11:19 mychaeel Exp $
//
// Pawn used by JBTagNavigation to calculate travelling distances between two
// arbitrary actors in a map.
// ============================================================================


class JBScout extends Pawn;


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bCollideActors  = False;
  bCollideWorld   = False;
  CollisionRadius = 25.0;
  CollisionHeight = 44.0;
  CrouchHeight    = 29.0;
  CrouchRadius    = 25.0;
  }