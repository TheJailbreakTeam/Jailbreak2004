//=============================================================================
// JBMantaFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Manta hovercrafts.
//=============================================================================


class JBMantaFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RedBuildEffectClass=Class'Onslaught.ONSHoverBikeBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSHoverBikeBuildEffectBlue'
  VehicleClass=Class'Onslaught.ONSHoverBike'
  Mesh=SkeletalMesh'ONSVehicles-A.HoverBike'
  CollisionRadius=70.000000
  CollisionHeight=25.000000
}
