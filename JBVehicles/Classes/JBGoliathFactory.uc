//=============================================================================
// JBGoliathFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Goliath tanks.
//=============================================================================


class JBGoliathFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RespawnTime=30.000000
  RedBuildEffectClass=Class'Onslaught.ONSTankBuildEffectRed'
  BlueBuildEffectClass=Class'Onslaught.ONSTankBuildEffectBlue'
  VehicleClass=Class'Onslaught.ONSHoverTank'
  Mesh=SkeletalMesh'ONSVehicles-A.HoverTank'
  CollisionRadius=150.000000
  CollisionHeight=35.000000
}
