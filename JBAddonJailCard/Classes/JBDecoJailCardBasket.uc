// ============================================================================
// JBDecoJailCardBasket
// Copyright 2007 by Valentijn Geirnaert <gsfjohndoe@hotmail.com>
// $Id$
//
// Holder for emitter resembling a basket for the JailCard pickup.
// Placeholder class - the final effect should be different I think
//
// CHANGELOG:
// 17 jan 2007 - class created
// 20 jan 2007 - Fixed bug where the first emitter spawned would be blue
//               instead of myColor
// ============================================================================


class JBDecoJailCardBasket extends JBDecoSwitchBasket
  notplaceable;

//=============================================================================
// Properties
//=============================================================================

var() Color myColor;


// ============================================================================
// PostBeginPlay
//
// Spawns an Emitter actor which holds the configured ParticleEmitter.
// ============================================================================

simulated event PostBeginPlay()
{
    Class'JBEmitterBasket'.default.ColorBlue = myColor;
    Emitter = Spawn(Class'JBEmitterBasket', Self, , Location + PrePivot, Rotation);
    Emitter.SetDefendingTeam(1);
    Class'JBEmitterBasket'.default.ColorBlue = Class'JBEmitterBasket'.default.ColorBlue;
}

defaultproperties
{
    myColor  = (R=255,G=255,B=0,A=128);
}
