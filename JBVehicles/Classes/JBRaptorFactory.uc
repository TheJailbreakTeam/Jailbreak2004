//=============================================================================
// JBRaptorFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Raptor attack crafts.
//=============================================================================


class JBRaptorFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RedBuildEffectClass=Class'Onslaught.ONSAttackCraftBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSAttackCraftBuildEffectBlue'
  VehicleClass=Class'Onslaught.ONSAttackCraft'
  Mesh=SkeletalMesh'ONSVehicles-A.AttackCraft'
  CollisionRadius=80.000000
  CollisionHeight=55.000000
}
