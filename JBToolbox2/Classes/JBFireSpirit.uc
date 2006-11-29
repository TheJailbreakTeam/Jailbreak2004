// ============================================================================
// JBFireSpirit
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// A fiery spirit.
// ============================================================================


class JBFireSpirit extends JBSpirit;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\EmitterTextures.utx
#exec audio import file=Sounds\FireSpiritAmbient.wav  group=FireSpirit
#exec audio import file=Sounds\FireSpiritSpawn.wav    group=FireSpirit
#exec audio import file=Sounds\FireSpiritIgnite.wav   group=FireSpirit


// ============================================================================
// ExecutePlayer
//
// Sets the Victim on fire.
// ============================================================================

function ExecutePlayer(Pawn Victim)
{
  local JBDamagerBurning thisDamager;

  thisDamager = Spawn(class'JBDamagerBurning');

  if (thisDamager != None) {
    Trigger(Self, Victim);
    thisDamager.Victim = Victim;
    thisDamager.FlameEmitter = Spawn(class'JBEmitterBurningPlayer', Victim,, Victim.Location);
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  SpawnSound=Sound'JBToolbox2.FireSpirit.FireSpiritSpawn'
  TouchSound=Sound'JBToolbox2.FireSpirit.FireSpiritIgnite'

  Begin Object class=SpriteEmitter Name=FireTrail
    FadeOut=True
    FadeIn=True
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    UseRandomSubdivision=True
    TriggerDisabled=False
    AddVelocityFromOwner=True
    Acceleration=(Z=20.000000)
    Opacity=0.500000
    FadeOutStartTime=0.200000
    FadeInEndTime=0.200000
    MaxParticles=150
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Max=20.000000)
    StartSpinRange=(X=(Min=0.375000,Max=0.375000))
    SizeScale(0)=(RelativeSize=0.300000)
    SizeScale(1)=(RelativeTime=0.700000,RelativeSize=2.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
    StartSizeRange=(X=(Min=14.000000,Max=20.000000),Y=(Min=14.000000,Max=20.000000),Z=(Min=14.000000,Max=20.000000))
    Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
    TextureUSubdivisions=4
    TextureVSubdivisions=4
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=0.500000,Max=0.500000)
    StartVelocityRange=(Z=(Min=10.000000,Max=20.000000))
    VelocityLossRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=5.000000,Max=5.000000),Z=(Min=5.000000,Max=5.000000))
  End Object
  Emitters(1)=SpriteEmitter'JBToolbox2.JBFireSpirit.FireTrail'

  Begin Object class=SpriteEmitter Name=FireBurst
    FadeOut=True
    FadeIn=True
    RespawnDeadParticles=False
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    AutomaticInitialSpawning=False
    UseRandomSubdivision=True
    TriggerDisabled=False
    AddVelocityFromOwner=True
    Acceleration=(Z=100.000000)
    Opacity=0.500000
    FadeOutStartTime=0.200000
    FadeInEndTime=0.200000
    MaxParticles=100
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Max=20.000000)
    StartSpinRange=(X=(Min=0.375000,Max=0.375000))
    SizeScale(0)=(RelativeSize=0.300000)
    SizeScale(1)=(RelativeTime=0.700000,RelativeSize=2.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
    StartSizeRange=(X=(Min=20.000000,Max=30.000000),Y=(Min=20.000000,Max=30.000000),Z=(Min=20.000000,Max=30.000000))
    InitialParticlesPerSecond=1500.000000
    Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
    TextureUSubdivisions=4
    TextureVSubdivisions=4
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=0.500000,Max=1.000000)
    SpawnOnTriggerRange=(Min=50.000000,Max=50.000000)
    SpawnOnTriggerPPS=2000.000000
    StartVelocityRange=(Z=(Min=30.000000,Max=50.000000))
    StartVelocityRadialRange=(Min=-200.000000,Max=-100.000000)
    VelocityLossRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=5.000000,Max=5.000000),Z=(Min=5.000000,Max=5.000000))
    GetVelocityDirectionFrom=PTVD_AddRadial
  End Object
  Emitters(2)=SpriteEmitter'JBToolbox2.JBFireSpirit.FireBurst'

  AmbientSound=Sound'JBToolbox2.FireSpirit.FireSpiritAmbient'
  SoundVolume=255
  SoundRadius=500.000000
  TransientSoundVolume=2.000000
  TransientSoundRadius=500.000000
}
