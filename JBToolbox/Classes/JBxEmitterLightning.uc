// ============================================================================
// JBxEmitterLightning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBxEmitterLightning.uc,v1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// Effect of lightning execution.
// ============================================================================
class JBxEmitterLightning extends LightningBolt;


// ============================================================================
// PostBeginPlay
//
// Play effect sound.
// ============================================================================
simulated function PostBeginPlay()
{
    PlaySound(Sound'xEffects.LightningSound', SLOT_None, 10,, 1000);
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    mSizeRange(0)=50.000000
    mSizeRange(1)=50.000000
    mSpawnVecB=(X=5.0,Y=40.0,Z=40.0)
    mPosDev=(X=20.000000,Y=20.000000,Z=20.000000)
}
