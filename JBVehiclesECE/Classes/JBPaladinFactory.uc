//=============================================================================
// JBPaladinFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Factory for Paladin tanks.
//=============================================================================


class JBPaladinFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Mesh=Mesh'ONSBPAnimations.ShockTankMesh'
  VehicleClass=class'OnslaughtBP.ONSShockTank'
  RedBuildEffectClass=class'ONSTankBuildEffectRed'
  BlueBuildEffectClass=class'ONSTankBuildEffectBlue'
  CollisionHeight=40.0
  CollisionRadius=260.0
}
