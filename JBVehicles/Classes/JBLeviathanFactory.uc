//=============================================================================
// JBLeviathanFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Leviathan mobile assault station.
//=============================================================================


class JBLeviathanFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RespawnTime=120.000000
  RedBuildEffectClass=Class'OnslaughtFull.ONSMASBuildEffectRed'
  BlueBuildEffectClass=Class'OnslaughtFull.ONSMASBuildEffectBlue'
  VehicleClass=Class'OnslaughtFull.ONSMobileAssaultStation'
  Mesh=SkeletalMesh'ONSFullAnimations.MASchassis'
  CollisionRadius=230.000000
  CollisionHeight=90.000000
}
