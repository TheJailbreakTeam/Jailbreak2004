//=============================================================================
// JBEmitterKillExplosion
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Emitter that creates an explosion effect.
//=============================================================================


class JBEmitterKillExplosion extends Emitter;


//=============================================================================
// Import
//=============================================================================

#exec audio import file=Sounds\Explosion.wav name=Explosion group=KillSounds


//=============================================================================
// PostBeginPlay
//
// Handle low framerate conditions.
//=============================================================================

simulated event PostBeginPlay()
{
  PlaySound(Sound'Explosion', SLOT_Interact, 250.0,, 500.0);
  if ( Level.bDropDetail )
    LightRadius = 5;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bNoDelete=False
  RemoteRole=ROLE_SimulatedProxy
  bNetTemporary=True
  
  Begin Object Class=SpriteEmitter Name=ExplosionParticles
    MaxParticles=20
    FadeOutStartTime=0.200000
    FadeOut=True
    RespawnDeadParticles=False
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Min=20.000000,Max=50.000000)
    SpinParticles=True
    StartSpinRange=(X=(Max=65535.000000),Y=(Max=65535.000000),Z=(Max=65535.000000))
    UseSizeScale=True
    UseRegularSizeScale=False
    SizeScale(0)=(RelativeSize=0.500000)
    SizeScale(1)=(RelativeTime=0.700000,RelativeSize=1.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.000000)
    StartSizeRange=(X=(Min=40.000000,Max=60.000000),Y=(Min=40.000000,Max=60.000000),Z=(Min=40.000000,Max=60.000000))
    UniformSize=True
    InitialParticlesPerSecond=1000.000000
    AutomaticInitialSpawning=False
    Texture=Texture'XEffects.Skins.fexpt'
    LifetimeRange=(Min=0.500000,Max=1.000000)
    StartVelocityRadialRange=(Min=-20.000000,Max=-10.000000)
    VelocityLossRange=(X=(Min=2.000000,Max=2.500000),Y=(Min=2.000000,Max=2.500000),Z=(Min=2.000000,Max=2.500000))
    GetVelocityDirectionFrom=PTVD_AddRadial
  End Object
  Emitters(0)=SpriteEmitter'ExplosionParticles'
  
  AutoDestroy=True
  
  bDynamicLight=true
  LightEffect=LE_QuadraticNonIncidence
  LightType=LT_FadeOut
  LightBrightness=255
  LightHue=28
  LightSaturation=90
  LightRadius=7
  LightPeriod=32
  LightCone=128
}