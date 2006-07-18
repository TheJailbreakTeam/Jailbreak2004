// ============================================================================
// JBEmitterBurningPlayer
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBEmitterBurningPlayer.uc,v 1.2 2006-07-17 15:07:13 wormbo Exp $
//
// An emitter that sets a player on fire.
// ============================================================================

class JBEmitterBurningPlayer extends Emitter;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\EmitterTextures.utx
#exec obj load file=..\Sounds\GeneralAmbience.uax


// ============================================================================
// Variables
// ============================================================================

/** The victim these flames are attached to. (Owner doesn't replicate to all clients!) */
var Pawn Victim;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    Victim;
}


// ============================================================================
// PostBeginPlay
//
// Set the owner as the victim (for replication) and set up the emitter on the
// serverside or offline.
// ============================================================================

function PostBeginPlay()
{
  Victim = Pawn(Owner);
}


// ============================================================================
// PostNetBeginPlay
//
// Set the mesh actor and proper scale. Make sure the emitter moves with the
// player.
// ============================================================================

simulated function PostNetBeginPlay()
{
  if (Victim != None) {
    Emitters[0].SkeletalScale = Emitters[0].SkeletalScale * Victim.DrawScale3D * Victim.DrawScale;
    Emitters[0].SkeletalMeshActor = Victim;
    SetLocation(Victim.Location);
    SetBase(Victim);
  }
}


// ============================================================================
// TornOff
//
// Make sure the emitter goes away when the player died.
// ============================================================================

simulated function TornOff()
{
  Kill();
  LifeSpan = 0.6;
  AmbientSound = None;
  Disable('Tick');
}


// ============================================================================
// Tick
//
// Update the emitter rotation offset (neccessary for actors that are not
// ragdolls).
// ============================================================================

simulated function Tick(float DeltaTime)
{
  if (Victim != None) Emitters[0].RotationOffset = Victim.Rotation - rot(0,16384,0);
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Begin Object Class=SpriteEmitter Name=PlayerFlames
    FadeOut=True
    FadeIn=True
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    UseRandomSubdivision=True
    AddVelocityFromOwner=True
    Acceleration=(Z=20.000000)
    Opacity=0.500000
    FadeOutStartTime=0.200000
    FadeInEndTime=0.200000
    MaxParticles=100
    StartLocationOffset=(Z=-48.000000)
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Max=5.000000)
    UseRotationFrom=PTRS_Offset
    RotationOffset=(Yaw=-16384)
    StartSpinRange=(X=(Min=0.375000,Max=0.375000))
    SizeScale(0)=(RelativeSize=0.300000)
    SizeScale(1)=(RelativeTime=0.700000,RelativeSize=2.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
    StartSizeRange=(X=(Min=10.000000,Max=15.000000),Y=(Min=10.000000,Max=15.000000),Z=(Min=10.000000,Max=15.000000))
    UseSkeletalLocationAs=PTSU_SpawnOffset
    SkeletalScale=(X=0.390000,Y=0.390000,Z=0.390000)
    Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
    TextureUSubdivisions=4
    TextureVSubdivisions=4
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=0.500000,Max=0.500000)
    StartVelocityRange=(Z=(Min=10.000000,Max=20.000000))
    VelocityLossRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=5.000000,Max=5.000000),Z=(Min=5.000000,Max=5.000000))
  End Object
  Emitters(0)=SpriteEmitter'PlayerFlames'

  bNoDelete   = False
  bHardAttach = True
  RemoteRole  = ROLE_SimulatedProxy
  bReplicateMovement = False
  AmbientSound  = Sound'GeneralAmbience.firefx9'
}
