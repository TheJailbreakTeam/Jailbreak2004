// ============================================================================
// JBEmitter1stPersonFlames
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// An emitter that sets a player on fire in first person.
// ============================================================================

class JBEmitter1stPersonFlames extends Emitter;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\EmitterTextures.utx
#exec obj load file=..\Sounds\GeneralAmbience.uax


// ============================================================================
// TornOff
//
// Destroy the emitter as soon as the player dies.
// ============================================================================

simulated function TornOff()
{
  Destroy();
}


// ============================================================================
// Tick
//
// Update the emitter's location and rotation.
// ============================================================================

simulated function Tick(float DeltaTime)
{
  local Controller C;

  if (Pawn(Owner) != None && Pawn(Owner).Controller != None) {
    C = Pawn(Owner).Controller;

    SetLocation(Owner.Location + Pawn(Owner).EyePosition() + Vector(C.Rotation)*20);
    SetRotation(Owner.Rotation);

    // Show only in first person.
    if (PlayerController(C) != None &&
        Emitters[0].Disabled != PlayerController(C).bBehindView)
      Emitters[0].Disabled = PlayerController(C).bBehindView;
  }
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
    MaxParticles=25
    StartLocationShape=PTLS_Sphere
    SphereRadiusRange=(Min=8.00000,Max=16.000000)
    StartSpinRange=(X=(Min=0.375000,Max=0.375000))
    SizeScale(0)=(RelativeSize=0.300000)
    SizeScale(1)=(RelativeTime=0.700000,RelativeSize=2.000000)
    SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
    StartSizeRange=(X=(Min=10.000000,Max=15.000000),Y=(Min=10.000000,Max=15.000000),Z=(Min=10.000000,Max=15.000000))
    Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
    TextureUSubdivisions=4
    TextureVSubdivisions=4
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=0.500000,Max=0.500000)
    StartVelocityRange=(Z=(Min=10.000000,Max=20.000000))
    VelocityLossRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=5.000000,Max=5.000000),Z=(Min=5.000000,Max=5.000000))
    CoordinateSystem=PTCS_Relative
  End Object
  Emitters(0)=SpriteEmitter'PlayerFlames'

  bNoDelete   = False
  bHardAttach = True
}
