// ============================================================================
// JBThunderSpirit
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// An electrical spirit.
// ============================================================================


class JBThunderSpirit extends JBSpirit;


// ============================================================================
// ExecutePlayer
//
// Electrocute the Victim. Practically copied from JBExecutionLightning.
// ============================================================================

function ExecutePlayer(Pawn Victim)
{
  if (Level.NetMode != NM_DedicatedServer)
    Spawn(class'BlueSparks',,, Victim.Location, rotator(Victim.Location-Location));

  if (Victim.Controller != None && Victim.Controller.bGodMode)
       Victim.Died(None, class'DamTypeSniperShot', vector(Victim.Rotation)*0.3); // make sure to kill stupid player
  else Victim.TakeDamage(1000, None, Victim.Location, vector(Victim.Rotation)*0.3, class'DamTypeSniperShot');
}


// ============================================================================
// default properties
// ============================================================================

defaultproperties
{
  SpawnSound=Sound'WeaponSounds.LightningGun.LightningGunExplosion'
  TouchSound=Sound'WeaponSounds.LightningGun.LightningGunImpact'

  Begin Object Class=BeamEmitter Name=ThunderTrail
    BeamDistanceRange=(Min=30.000000,Max=40.000000)
    DetermineEndPointBy=PTEP_Distance
    RotatingSheets=3
    LowFrequencyNoiseRange=(X=(Min=-5.000000,Max=5.000000),Y=(Min=-5.000000,Max=5.000000),Z=(Min=-5.000000,Max=5.000000))
    HighFrequencyNoiseRange=(X=(Min=-3.000000,Max=3.000000),Y=(Min=-3.000000,Max=3.000000),Z=(Min=-3.000000,Max=3.000000))
    NoiseDeterminesEndPoint=True
    UseColorScale=True
    TriggerDisabled=False
    ColorScale(0)=(color=(B=255,G=255,R=255,A=255))
    ColorScale(1)=(RelativeTime=0.100000,color=(B=255,G=255,R=255,A=255))
    ColorScale(2)=(RelativeTime=0.200000,color=(B=32,G=32,R=32,A=128))
    ColorScale(3)=(RelativeTime=1.000000)
    MaxParticles=400
    StartSizeRange=(X=(Min=4.000000,Max=5.000000),Y=(Min=3.000000,Max=5.000000),Z=(Min=3.000000,Max=5.000000))
    DrawStyle=PTDS_Brighten
    Texture=Texture'EpicParticles.Beams.HotBolt04aw'
    LifetimeRange=(Min=0.400000,Max=0.500000)
    StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=-100.000000,Max=100.000000))
  End Object
  Emitters(1)=BeamEmitter'ThunderTrail'

  Begin Object class=SpriteEmitter Name=SparkBurst
    UseDirectionAs=PTDU_Up
    UseColorScale=True
    RespawnDeadParticles=False
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    ScaleSizeYByVelocity=True
    AutomaticInitialSpawning=False
    TriggerDisabled=False
    Acceleration=(Z=-600.000000)
    DampingFactorRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.100000,Max=0.100000))
    ColorScale(0)=(color=(B=255,G=255,R=255))
    ColorScale(1)=(RelativeTime=1.000000)
    MaxParticles=2000
    Name="SpriteEmitter56"
    StartLocationRange=(X=(Min=-10.000000,Max=10.000000))
    UseRotationFrom=PTRS_Actor
    SizeScale(2)=(RelativeTime=0.070000,RelativeSize=2.000000)
    SizeScale(3)=(RelativeTime=1.000000,RelativeSize=2.000000)
    StartSizeRange=(X=(Min=2.000000,Max=4.000000),Y=(Min=2.000000,Max=2.000000))
    ScaleSizeByVelocityMultiplier=(X=0.010000,Y=0.003000)
    ScaleSizeByVelocityMax=1000.000000
    InitialParticlesPerSecond=10000.000000
    Texture=Texture'AW-2004Particles.Energy.SparkHead'
    LifetimeRange=(Min=1.500000,Max=1.500000)
    StartVelocityRange=(X=(Min=-500.000000,Max=500.000000),Y=(Min=-500.000000,Max=500.000000),Z=(Min=-500.000000,Max=500.000000))
    MaxAbsVelocity=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    VelocityLossRange=(X=(Min=1.000000,Max=2.000000),Y=(Min=1.000000,Max=2.000000),Z=(Min=1.000000,Max=2.000000))
  End Object
  Emitters(2)=SpriteEmitter'SparkBurst'

  AmbientSound=Sound'GeneralAmbience.electricalfx12'
  SoundVolume=255
  SoundRadius=500.000000
  TransientSoundVolume=2.000000
  TransientSoundRadius=500.000000
}