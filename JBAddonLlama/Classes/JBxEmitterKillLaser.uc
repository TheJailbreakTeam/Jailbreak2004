//=============================================================================
// JBxEmitterKillLaser
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// A red laser beam.
//=============================================================================


class JBxEmitterKillLaser extends xEmitter;


//=============================================================================
// Variables
//=============================================================================

var vector HitNormal, PlayerLoc;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( bNetInitial && Role == ROLE_Authority )
    HitNormal, PlayerLoc;
}


//=============================================================================
// SetBeam
//
// Sets the beam's start and end locations.
//=============================================================================

function SetBeam(vector NewStart, vector NewEnd)
{
  local vector HN, HL;
  
  Trace(HL, HN, NewStart + Normal(NewEnd - NewStart) * 50000, NewStart, False);
  mSpawnVecA = HL - Normal(NewEnd - NewStart) * 2;
  HitNormal = HN;
  PlayerLoc = NewEnd;
  if ( Level.NetMode != NM_DedicatedServer )
    SpawnEffects();
}


//=============================================================================
// PostNetBeginPlay
//
// Creates the beam effect on the client.
//=============================================================================

simulated function PostNetBeginPlay()
{
  if ( Role < ROLE_Authority )
    SpawnEffects();
}


//=============================================================================
// SpawnEffects
//
// Creates the beam effect.
//=============================================================================

simulated function SpawnEffects()
{
  Spawn(class'JBEmitterKillLaserFlame',,, PlayerLoc);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bReplicateInstigator=false
  bAlwaysRelevant=true
  bReplicateMovement=false
  bNetTemporary=true
  LifeSpan=1.0
  NetPriority=3.0
  
  mParticleType=PT_Beam
  mStartParticles=1
  mAttenKa=0.1
  mSizeRange(0)=50.0
  mSizeRange(1)=100.0
  mRegenDist=150.0
  mLifeRange(0)=1.0
  mMaxParticles=3
  
  Texture=Texture'ShockBeamTex'
  Skins(0)=InstagibEffects.RedSuperShockBeam
  Style=STY_Additive
  bUnlit=true
}
