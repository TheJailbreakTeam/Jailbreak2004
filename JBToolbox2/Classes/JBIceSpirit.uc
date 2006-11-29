// ============================================================================
// JBIceSpirit
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// An icy spirit.
// ============================================================================


class JBIceSpirit extends JBSpirit;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\EmitterTextures.utx
#exec audio import file=Sounds\IceSpiritAmbient.wav group=IceSpirit
#exec audio import file=Sounds\IceSpiritSpawn.wav   group=IceSpirit


// ============================================================================
// ExecutePlayer
//
// Freezes the Victim.
// ============================================================================

function ExecutePlayer(Pawn Victim)
{
  Spawn(class'JBFreezer', Victim);
}


// ============================================================================
// Default properties.
// ============================================================================

defaultproperties
{
  SpawnSound=Sound'JBToolbox2.IceSpirit.IceSpiritSpawn'

  Begin Object class=SpriteEmitter Name=CloudTrail
    UseColorScale=True
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    UseRandomSubdivision=True
    TriggerDisabled=False
    AddVelocityFromOwner=True
    ColorScale(1)=(RelativeTime=0.100000,color=(B=204,G=153,R=153,A=255))
    ColorScale(2)=(RelativeTime=0.500000,color=(B=51,G=51,R=51,A=51))
    ColorScale(3)=(RelativeTime=1.000000)
    MaxParticles=150
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Max=15.000000)
    StartSpinRange=(X=(Max=1.000000))
    SizeScale(1)=(RelativeTime=0.100000,RelativeSize=0.700000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.000000)
    StartSizeRange=(X=(Min=15.000000,Max=20.000000),Y=(Min=15.000000,Max=20.000000),Z=(Min=15.000000,Max=20.000000))
    Texture=Texture'EmitterTextures.MultiFrame.waterfall03'
    TextureUSubdivisions=2
    TextureVSubdivisions=2
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=1.000000,Max=1.000000)
    StartVelocityRadialRange=(Min=-30.000000,Max=-20.000000)
    VelocityLossRange=(X=(Min=4.000000,Max=4.000000),Y=(Min=4.000000,Max=4.000000),Z=(Min=4.000000,Max=4.000000))
    GetVelocityDirectionFrom=PTVD_AddRadial
  End Object
  Emitters(1)=SpriteEmitter'JBToolbox2.JBIceSpirit.CloudTrail'

  Begin Object class=SpriteEmitter Name=ColdBurstCloud
    UseColorScale=True
    RespawnDeadParticles=False
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    AutomaticInitialSpawning=False
    UseRandomSubdivision=True
    TriggerDisabled=False
    Acceleration=(Z=-5.000000)
    ColorScale(1)=(RelativeTime=0.100000,color=(B=204,G=153,R=153,A=255))
    ColorScale(2)=(RelativeTime=0.500000,color=(B=51,G=51,R=51,A=51))
    ColorScale(3)=(RelativeTime=1.000000)
    Opacity=0.300000
    MaxParticles=200
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Max=10.000000)
    StartSpinRange=(X=(Max=1.000000))
    SizeScale(1)=(RelativeTime=0.250000,RelativeSize=1.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=2.000000)
    StartSizeRange=(X=(Min=15.000000,Max=20.000000),Y=(Min=15.000000,Max=20.000000),Z=(Min=15.000000,Max=20.000000))
    Texture=Texture'EmitterTextures.MultiFrame.waterfall03'
    TextureUSubdivisions=2
    TextureVSubdivisions=2
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=1.000000,Max=2.000000)
    SpawnOnTriggerRange=(Min=100.000000,Max=100.000000)
    SpawnOnTriggerPPS=3000.000000
    StartVelocityRadialRange=(Min=-80.000000,Max=-60.000000)
    VelocityLossRange=(X=(Min=2.000000,Max=2.000000),Y=(Min=2.000000,Max=2.000000),Z=(Min=2.000000,Max=2.000000))
    GetVelocityDirectionFrom=PTVD_AddRadial
  End Object
  Emitters(2)=SpriteEmitter'JBToolbox2.JBIceSpirit.ColdBurstCloud'

  AmbientSound=Sound'JBToolbox2.IceSpirit.IceSpiritAmbient'
  SoundVolume=255
  SoundRadius=500.000000
  TransientSoundVolume=2.000000
  TransientSoundRadius=500.000000
}
