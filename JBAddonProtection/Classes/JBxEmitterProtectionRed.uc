// ============================================================================
// JBxEmitterProtectionRed
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBxEmitterProtectionRed.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// The red protection effect.
// ============================================================================
class JBxEmitterProtectionRed extends xEmitter;


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bNetTemporary=false
    bReplicateMovement=false
    bTrailerSameRotation=true
    mAirResistance=0.0
    mAttenKa=0.5
    mAttenFunc=ATF_ExpInOut
    mDirDev=(X=0,Y=0,Z=5)
    mLifeRange(0)=1.0
    mLifeRange(1)=1.0
    mMaxParticles=10
    mMeshNodes(0)=StaticMesh'XEffects.TeleRing'
    mParticleType=PT_Mesh
    mPosRelative=true
    mRegenRange(0)=3.0
    mRegenRange(1)=3.0
    mSizeRange(0)=0.6
    mSizeRange(1)=0.8
    mSpeedRange(0)=6.0
    mSpeedRange(1)=12.0
    mStartParticles=0
    Physics=PHYS_Trailer
    RemoteRole=ROLE_SimulatedProxy
    Skins(0)=Shader'xGameShaders.BRShaders.BombIconRS'
    Style=STY_Additive
}
