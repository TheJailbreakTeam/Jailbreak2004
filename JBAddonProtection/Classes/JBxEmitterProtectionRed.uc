// ============================================================================
// JBxEmitterProtectionRed
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id$
//
// The red protection effect.
// ============================================================================


class JBxEmitterProtectionRed extends xEmitter;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    mRegenRep;
}


// ============================================================================
// Variables
// ============================================================================

var bool mRegenRep;


// ============================================================================
// PostNetReceive
//
// Sets the local mRegen variable to the value of the replicated mRegenRep
// variable.
// ============================================================================

simulated event PostNetReceive()
{
  mRegen = mRegenRep;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bNetTemporary=False
    bNetNotify=True

    Physics=PHYS_Trailer
    bTrailerSameRotation=True
    bReplicateMovement=False

    LifeSpan=60.0
    mRegen=True
    mRegenRep=True
    mAirResistance=0.0
    mAttenKa=0.5
    mAttenFunc=ATF_ExpInOut
    mDirDev=(X=0,Y=0,Z=5)
    mLifeRange(0)=1.0
    mLifeRange(1)=1.0
    mMaxParticles=10
    mMeshNodes(0)=StaticMesh'XEffects.TeleRing'
    mParticleType=PT_Mesh
    mPosRelative=True
    mRegenRange(0)=3.0
    mRegenRange(1)=3.0
    mSizeRange(0)=0.6
    mSizeRange(1)=0.8
    mSpeedRange(0)=6.0
    mSpeedRange(1)=12.0
    mStartParticles=0
    Skins(0)=Shader'xGameShaders.BRShaders.BombIconRS'
    Style=STY_Additive
}
