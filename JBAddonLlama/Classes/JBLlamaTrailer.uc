//=============================================================================
// JBLlamaTrailer
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Llama heads and light effect as placeholder for a third-person llama effect.
//=============================================================================


class JBLlamaTrailer extends xEmitter;

//=============================================================================
// Imports
//=============================================================================

#exec texture import file=Textures\LlamaParticle.dds mips=on alpha=on lodset=LODSET_Interface


//=============================================================================
// Tick
//
// Modifies the light hue and radius to create a pulsing rainbow color effect.
//=============================================================================

simulated function Tick(float DeltaTime)
{
  LightHue = int(Level.TimeSeconds * 100.0) % 256;
  LightRadius = 3.0 * Cos(2.0 * Level.TimeSeconds * Pi) + 8.0;
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bNetTemporary=false
  bReplicateMovement=false
  Physics=PHYS_Trailer
  bTrailerSameRotation=true
  Skins(0)=Texture'LlamaParticle'
  Style=STY_Additive
  mColorRange(0)=(R=255,G=0,B=0,A=255)
  mColorRange(1)=(R=0,G=0,B=255,A=255)
  mSpawningType=ST_Explode
  mStartParticles=0
  mMaxParticles=20
  mLifeRange(0)=1.5
  mLifeRange(1)=2.5
  mRegenRange(0)=10.0
  mRegenRange(1)=15.0
  mPosDev=(X=55.0,Y=55.0,Z=45.0)
  mSpeedRange(0)=0.0
  mSpeedRange(1)=0.0
  mPosRelative=false
  mMassRange(0)=-0.15
  mMassRange(1)=-0.15
  mOwnerVelocityFactor=1.0
  mAirResistance=2.0
  mSizeRange(0)=10.0
  mSizeRange(1)=20.0
  mAttenKa=0.5
  mAttenFunc=ATF_ExpInOut
  LifeSpan=0.0
  mAttraction=5.0
  bDynamicLight=True
  LightType=LT_Steady
  LightEffect=LE_NonIncidence
  LightSaturation=127
  LightBrightness=250
}
