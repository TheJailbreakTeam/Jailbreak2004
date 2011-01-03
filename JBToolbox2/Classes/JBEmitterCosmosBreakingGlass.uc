// ============================================================================
// JBEmitterCosmosBreakingGlass
// Copyright 2010 by Wormbo
// $Id$
//
// Replacement glass shattering emitter for JB-Cosmos execution network fix.
// ============================================================================

class JBEmitterCosmosBreakingGlass extends JBEmitterClientTriggerable notplaceable;


//=============================================================================
// PostBeginPlay
//
// Find the particle texture.
//=============================================================================

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Emitters[0].Texture = Texture(DynamicLoadObject("JB-Cosmos.Particles.NewGlassShards", class'Texture'));
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		//UseCollision=True
		RespawnDeadParticles=False
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		//Acceleration=(Z=-950.0)
		DampingFactorRange=(X=(Min=0.95,Max=0.9),Y=(Min=0.5,Max=0.5),Z=(Min=0.5,Max=0.5))
		ColorScale(0)=(Color=(B=128,G=128,R=128))
		ColorScale(1)=(Color=(B=0,G=0,R=0),RelativeTime=1.0)
		UseColorScale=True
		MaxParticles=500
		StartLocationRange=(Y=(Min=-256.0,Max=256.0),Z=(Min=-128.0,Max=128.0))
		UseRotationFrom=PTRS_Actor
		StartSizeRange=(X=(Min=0.25,Max=10.0),Y=(Max=250.0),Z=(Max=250.0))
		//InitialParticlesPerSecond=50000.000000
		//Texture=Texture'JB-Cosmos.Particles.NewGlassShards'
		TriggerDisabled=False
		SpawnOnTriggerPPS=50000.0
		SpawnOnTriggerRange=(Min=500,Max=500)
		TextureUSubdivisions=2
		TextureVSubdivisions=2
		LifetimeRange=(Min=7.0,Max=7.0)
		StartVelocityRange=(X=(Min=200.0,Max=400.0),Y=(Min=-100.0,Max=100.0),Z=(Min=-100.0,Max=100.0))
		SecondsBeforeInactive=0.0
	End Object
	Emitters(0)=SpriteEmitter'SpriteEmitter0'

	bNoDelete = False
	bAlwaysRelevant = True
	bIgnoreTriggerDuringInitialization = True
}
