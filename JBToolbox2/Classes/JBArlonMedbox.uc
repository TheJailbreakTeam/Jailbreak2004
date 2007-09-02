// ============================================================================
// JBArlonMedbox
// Copyright 2007 by Wormbo <wormbo@online.de>
// $Id$
//
// New pickup class for the Arlon medbox to fix problems arising from its
// custom healing amount.
// ============================================================================


class JBArlonMedbox extends HealthPack notplaceable;


// ============================================================================
// Default properties.
// ============================================================================

defaultproperties
{
	// NOTE: StaticMesh  = StaticMesh'JB-Arlon-Gold.Medbox3' (dependency on a map package!)
	PickupMessage        = "You picked up a Medbox +"
	HealingAmount        = 50
	bOnlyReplicateHidden = False
	Physics              = PHYS_None
	bUnlit               = True
	Style                = STY_Normal
	bCollideWorld        = False	// don't adjust location when spawning this new actor
}