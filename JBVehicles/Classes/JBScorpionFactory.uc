//=============================================================================
// JBScorpionFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Scorpion vehicles.
//=============================================================================


class JBScorpionFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RedBuildEffectClass=Class'Onslaught.ONSRVBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSRVBuildEffectBlue'
  VehicleClass=Class'Onslaught.ONSRV'
  Mesh=SkeletalMesh'ONSVehicles-A.RV'
  CollisionRadius=70.000000
  CollisionHeight=40.000000
}
