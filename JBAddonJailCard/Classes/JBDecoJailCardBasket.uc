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
    Emitter = Spawn(Class'JBEmitterBasket', Self, , Location + PrePivot, Rotation);
    Emitter.default.ColorBlue = myColor;
    Emitter.SetDefendingTeam(1);
}

defaultproperties
{
    myColor  = (R=255,G=255,B=0,A=128);
}
