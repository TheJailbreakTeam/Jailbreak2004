// ============================================================================
// JBEffectThunderbolt
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBEffectThunderbolt.uc, v1.00 2003/02/28 ??:?? crokx Exp $
//
// Effect of thunderbolt execution.
// ============================================================================
class JBEffectThunderbolt extends LightningBolt;


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
    mSizeRange(0)=60.000000
    mSizeRange(1)=60.000000
    mSpawnVecB=(X=5.0,Y=50.0,Z=50.0)
    mPosDev=(X=50.000000,Y=50.000000,Z=75.000000)
}
