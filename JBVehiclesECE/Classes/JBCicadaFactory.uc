//=============================================================================
// JBCicadaFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBRaptorFactory.uc,v 1.1 2004/05/29 12:49:23 wormbo Exp $
//
// Factory for Cicada attack crafts.
//=============================================================================


class JBCicadaFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Mesh=Mesh'ONSBPAnimations.DualAttackCraftMesh'
  VehicleClass=class'OnslaughtBP.ONSDualAttackCraft'
  RedBuildEffectClass=class'ONSAttackCraftBuildEffectRed'
  BlueBuildEffectClass=class'ONSAttackCraftBuildEffectBlue'
  RespawnTime=30.0
  CollisionRadius=240.000000
  CollisionHeight=55.000000
}
