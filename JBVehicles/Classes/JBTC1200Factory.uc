//=============================================================================
// JBTC1200Factory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for toilet cars. :-)
//=============================================================================


class JBTC1200Factory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RedBuildEffectClass=Class'Onslaught.ONSRVBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSRVBuildEffectBlue'
  VehicleClass=Class'OnslaughtFull.ONSGenericSD'
  Mesh=SkeletalMesh'GenericSD.TC'
  CollisionRadius=30.000000
  CollisionHeight=12.000000
}
