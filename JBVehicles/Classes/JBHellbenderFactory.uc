//=============================================================================
// JBHellbenderFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Hellbender vehicles.
//=============================================================================


class JBHellbenderFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RedBuildEffectClass=Class'Onslaught.ONSPRVBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSPRVBuildEffectBlue'
  VehicleClass=Class'Onslaught.ONSPRV'
  Mesh=SkeletalMesh'ONSVehicles-A.PRVchassis'
  CollisionRadius=100.000000
  CollisionHeight=65.000000
}
