//=============================================================================
// JBEmitterKillLightning
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Emitter that creates a lightning beam effect.
//=============================================================================


class JBEmitterKillLightning extends Emitter;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bNoDelete=False
  bNetTemporary=True
  RemoteRole=ROLE_SimulatedProxy
  LifeSpan=1.0
  AutoDestroy=True
  
  Begin Object Class=BeamEmitter Name=MainLightning
    BeamEndPoints(0)=(offset=(X=(Min=0.000000,Max=0.000000),Y=(Min=-0.000000,Max=0.000000),Z=(Min=10000.000000,Max=10000.000000)))
    DetermineEndPointBy=PTEP_Offset
    BeamTextureUScale=20.000000
    RotatingSheets=2
    LowFrequencyNoiseRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000))
    LowFrequencyPoints=10
    HighFrequencyNoiseRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000))
    HighFrequencyPoints=100
    UseBranching=True
    BranchProbability=(Min=0.100000,Max=0.300000)
    BranchHFPointsRange=(Min=5.000000,Max=1000.000000)
    BranchEmitter=1
    BranchSpawnAmountRange=(Min=1.000000,Max=1.000000)
    LinkupLifetime=True
    NoiseDeterminesEndPoint=True
    UseColorScale=True
    ColorScale(0)=(Color=(B=255,G=255,R=255))
    ColorScale(1)=(RelativeTime=0.100000,Color=(B=255,G=255,R=255))
    ColorScale(2)=(RelativeTime=0.300000,Color=(B=64,G=64,R=64))
    ColorScale(3)=(RelativeTime=0.400000,Color=(B=255,G=255,R=255))
    ColorScale(4)=(RelativeTime=1.000000)
    ColorMultiplierRange=(X=(Min=0.700000,Max=0.800000),Y=(Min=0.800000,Max=0.900000))
    MaxParticles=1
    RespawnDeadParticles=False
    StartSizeRange=(X=(Min=25.000000,Max=25.000000),Y=(Min=25.000000,Max=25.000000),Z=(Min=25.000000,Max=25.000000))
    InitialParticlesPerSecond=1000.000000
    AutomaticInitialSpawning=False
    DrawStyle=PTDS_Brighten
    Texture=Texture'EpicParticles.Beams.HotBolt03aw'
    LifetimeRange=(Min=0.500000,Max=0.500000)
  End Object
  Emitters(0)=BeamEmitter'MainLightning'
  
  Begin Object Class=BeamEmitter Name=LightningBranches
    BeamEndPoints(0)=(offset=(X=(Min=-500.000000,Max=500.000000),Y=(Min=-500.000000,Max=500.000000),Z=(Min=-1000.000000,Max=-500.000000)))
    DetermineEndPointBy=PTEP_Offset
    RotatingSheets=2
    LowFrequencyNoiseRange=(X=(Min=-50.000000,Max=50.000000),Y=(Min=-50.000000,Max=50.000000),Z=(Min=-50.000000,Max=50.000000))
    HighFrequencyNoiseRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-20.000000,Max=20.000000))
    NoiseDeterminesEndPoint=True
    UseColorScale=True
    ColorScale(0)=(Color=(B=255,G=255,R=255))
    ColorScale(1)=(RelativeTime=0.100000,Color=(B=255,G=255,R=255))
    ColorScale(2)=(RelativeTime=0.300000,Color=(B=64,G=64,R=64))
    ColorScale(3)=(RelativeTime=0.400000,Color=(B=255,G=255,R=255))
    ColorScale(4)=(RelativeTime=1.000000)
    ColorMultiplierRange=(X=(Min=0.700000,Max=0.800000),Y=(Min=0.800000,Max=0.900000))
    MaxParticles=60
    RespawnDeadParticles=False
    StartSizeRange=(X=(Min=20.000000,Max=20.000000),Y=(Min=20.000000,Max=20.000000),Z=(Min=20.000000,Max=20.000000))
    AutomaticInitialSpawning=False
    InitialParticlesPerSecond=0.000000
    DrawStyle=PTDS_Brighten
    Texture=Texture'EpicParticles.Beams.HotBolt04aw'
    LifetimeRange=(Min=0.500000,Max=0.500000)
  End Object
  Emitters(1)=BeamEmitter'LightningBranches'
  
  Begin Object Class=BeamEmitter Name=LightningEnds
    BeamEndPoints(0)=(offset=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=-500.000000,Max=-500.000000)))
    DetermineEndPointBy=PTEP_Offset
    RotatingSheets=2
    LowFrequencyNoiseRange=(X=(Min=-50.000000,Max=50.000000),Y=(Min=-50.000000,Max=50.000000))
    LowFrequencyPoints=3
    HighFrequencyNoiseRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000))
    HighFrequencyPoints=10
    NoiseDeterminesEndPoint=True
    UseColorScale=True
    ColorScale(0)=(Color=(B=255,G=255,R=255))
    ColorScale(1)=(RelativeTime=0.100000,Color=(B=255,G=255,R=255))
    ColorScale(2)=(RelativeTime=0.300000,Color=(B=64,G=64,R=64))
    ColorScale(3)=(RelativeTime=0.400000,Color=(B=255,G=255,R=255))
    ColorScale(4)=(RelativeTime=1.000000)
    ColorMultiplierRange=(X=(Min=0.700000,Max=0.800000),Y=(Min=0.800000,Max=0.900000))
    MaxParticles=1
    RespawnDeadParticles=False
    StartSizeRange=(X=(Min=25.000000,Max=25.000000),Y=(Min=25.000000,Max=25.000000),Z=(Min=25.000000,Max=25.000000))
    InitialParticlesPerSecond=1000.000000
    AutomaticInitialSpawning=False
    DrawStyle=PTDS_Brighten
    Texture=Texture'EpicParticles.Beams.HotBolt04aw'
    LifetimeRange=(Min=0.500000,Max=0.500000)
  End Object
  Emitters(2)=BeamEmitter'LightningEnds'
}