//=============================================================================
// JBSPMAFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGoliathFactory.uc,v 1.1 2004/05/29 12:49:23 wormbo Exp $
//
// Factory for SPMA artillery.
//=============================================================================


class JBSPMAFactory extends JBVehicleFactory;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  Mesh=Mesh'ONSBPAnimations.ArtilleryMesh'
  VehicleClass=class'OnslaughtBP.ONSArtillery'
  RedBuildEffectClass=class'ONSPRVBuildEffectRed'
  BlueBuildEffectClass=class'ONSPRVBuildEffectBlue'
  CollisionRadius=260.0
  CollisionHeight=50.0
}
