// ============================================================================
// JBEmitterFreeze
// Copyright 2005 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Produces a visual and audible freeze-and-shattering effect on its owner.
// ============================================================================


class JBEmitterFreeze extends Emitter
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec new staticmesh import Name="IceChunk" file="StaticMeshes\IceChunk.ase"
#exec Texture import file=Textures\IceSkin.dds mips=on masked=on
#exec Texture import file=Textures\IceFullscreen.dds mips=on masked=on
#exec audio import file="Sounds\PlayerFreezing.wav"
#exec audio import file="Sounds\PlayerShattering.wav"


// ============================================================================
// Variables
// ============================================================================

var private float TimeFade;

var private Shader ShaderOverlay;
var private FadeColor FadeColorOverlay;


// ============================================================================
// PostBeginPlay
//
// Sets up the emitter for its current owner.
// ============================================================================

event PostBeginPlay()
{
  local vector LocationHit;
  local vector LocationStart;
  local vector NormalHit;
  local Plane PlaneFloor;

  if (Owner == None)
    return;

  Emitters[0].SkeletalMeshActor = Owner;

  LocationStart = Owner.Location - vect(0,0,1) * Owner.CollisionHeight;
  if (Owner.Trace(LocationHit, NormalHit, LocationStart - vect(0, 0, 512), LocationStart) != None) {
    PlaneFloor.X = NormalHit.X;
    PlaneFloor.Y = NormalHit.Y;
    PlaneFloor.Z = NormalHit.Z;
    PlaneFloor.W = NormalHit dot LocationHit;

    Emitters[0].UseCollisionPlanes = True;
    Emitters[0].CollisionPlanes[0] = PlaneFloor;
  }
}


// ============================================================================
// Destroyed
//
// Free the overlay shader and fader ConstantColor into the global object pool.
// ============================================================================

event Destroyed()
{
  if (ShaderOverlay != None) {
    ShaderOverlay.Specular = None;
    ShaderOverlay.SpecularityMask = None;
    Level.ObjectPool.FreeObject(ShaderOverlay);
    ShaderOverlay = None;
  }
  if (FadeColorOverlay != None) {
    Level.ObjectPool.FreeObject(FadeColorOverlay);
    FadeColorOverlay = None;
  }
}


// ============================================================================
// Tick
//
// Keeps the emitter location in sync with the owner.
// ============================================================================

event Tick(float TimeDelta)
{
  if (Owner == None)
    return;

  SetLocation(Owner.Location - vect(0,0,1) * Owner.CollisionHeight);
  SetRotation(Owner.Rotation - rot(0,16384,0));
}


// ============================================================================
// RenderOverlays
//
// Renders an icy texture over the screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas)
{
  Canvas.Style = ERenderStyle.STY_Alpha;

  Canvas.DrawColor.R = 255;
  Canvas.DrawColor.G = 255;
  Canvas.DrawColor.B = 255;
  Canvas.DrawColor.A = FadeColorOverlay.Color1.A;

  Canvas.SetPos(0, 0);
  Canvas.DrawTile(
    Texture'IceFullscreen',
    Canvas.ClipX,
    Canvas.ClipY,
    0,
    Texture'IceFullscreen'.VSize * 1/8,
    Texture'IceFullscreen'.USize,
    Texture'IceFullscreen'.VSize * 6/8);
}


// ============================================================================
// state FreezeAndShatter
//
// Visually freezes the owner by changing its skin and spawning ice chunks
// around it. Goes to state Shatter after a few seconds.
// ============================================================================

auto state Freeze
{
  // ======================================================
  // Freeze
  //
  // Adds an ice skin overlay to the owner and its weapon.
  // ======================================================

  function Freeze()
  {
    local Pawn PawnOwner;

    if (FadeColorOverlay == None) {
      FadeColorOverlay = FadeColor(Level.ObjectPool.AllocateObject(Class'FadeColor'));
      FadeColorOverlay.FadePeriod = 1.0;
      FadeColorOverlay.Color1.A = 0;
      FadeColorOverlay.Color2.A = 0;
      FadeColorOverlay.FallbackMaterial = None;
    }

    if (ShaderOverlay == None) {
      ShaderOverlay = Shader(Level.ObjectPool.AllocateObject(Class'Shader'));
      ShaderOverlay.Diffuse = None;
      ShaderOverlay.Opacity = None;
      ShaderOverlay.Specular = Texture'IceSkin';
      ShaderOverlay.SpecularityMask = FadeColorOverlay;
      ShaderOverlay.SelfIllumination = None;
      ShaderOverlay.SelfIlluminationMask = None;
      ShaderOverlay.Detail = None;
      ShaderOverlay.FallbackMaterial = None;
      ShaderOverlay.OutputBlending = OB_Normal;
      ShaderOverlay.TwoSided = False;
      ShaderOverlay.Wireframe = False;
      ShaderOverlay.PerformLightingOnSpecularPass = False;
      ShaderOverlay.ModulateSpecular2X = False;
    }

    Owner.PlaySound(Sound'PlayerFreezing',, 3.0);

    PawnOwner = Pawn(Owner);
    SetOverlayMaterialFor(PawnOwner);
  }


  // ======================================================
  // Tick
  //
  // Fades in the ice skin overlay and makes sure the
  // overlay material is set.
  // ======================================================

  event Tick(float TimeDelta)
  {
    local Pawn PawnOwner;

    Global.Tick(TimeDelta);

    PawnOwner = Pawn(Owner);

    bOwnerNoSee =      PawnOwner             != None &&
      PlayerController(PawnOwner.Controller) != None &&
     !PlayerController(PawnOwner.Controller).bBehindView;

    if (FadeColorOverlay == None)
      return;

    TimeFade += TimeDelta;

    FadeColorOverlay.Color1.A = 224 * FMin(1.0, TimeFade * 2);
    FadeColorOverlay.Color2.A = FadeColorOverlay.Color1.A;

    SetOverlayMaterialFor(PawnOwner);
    if (PawnOwner != None && PawnOwner.Health <= 0)
      GotoState('Shatter');
  }


  // ======================================================
  // SetOverlayMaterialFor
  //
  // Sets the icy overlay material on the given pawn and
  // its weapon.
  // ======================================================

  function SetOverlayMaterialFor(Pawn Pawn)
  {
    if (Pawn == None)
      return;

    Pawn.SetOverlayMaterial(ShaderOverlay, 1000, True);

    if (Pawn.Weapon != None)
      Pawn.Weapon.SetOverlayMaterial(ShaderOverlay, 1000, True);

    if (xPawn(Pawn)                  != None &&
        xPawn(Pawn).WeaponAttachment != None)
      xPawn(Pawn).WeaponAttachment.SetOverlayMaterial(ShaderOverlay, 1000, True);

    if (Pawn.Weapon                  != None &&
        Pawn.Weapon.ThirdPersonActor != None)
      Pawn.Weapon.ThirdPersonActor.SetOverlayMaterial(ShaderOverlay, 1000, True);
  }


  // ======================================================
  // State
  // ======================================================

  Begin:
    Freeze();
    Sleep(4.0);
    GotoState('Shatter');

} // state FreezeAndShatter


// ============================================================================
// state Shatter
//
// Shatters the previously frozen player and destroys its pawn.
// ============================================================================

state Shatter
{
  // ======================================================
  // Shatter
  //
  // Hides the owner. Gives all particles an initial
  // velocity and subjects them to gravity.
  // ======================================================

  function Shatter()
  {
    local int iParticle;
    local Pawn PawnOwner;

    PlaySound(Sound'PlayerShattering', , 3.0);

    if (Owner != None)
      Owner.bHidden = True;

    PawnOwner = Pawn(Owner);
    if (PawnOwner                         != None &&
        PawnOwner.Weapon                  != None &&
        PawnOwner.Weapon.ThirdPersonActor != None)
      PawnOwner.Weapon.ThirdPersonActor.bHidden = True;

    for (iParticle = 0; iParticle < Emitters[0].Particles.Length; iParticle++) {
      Emitters[0].Particles[iParticle].Velocity = VRand() * 100.0;
      Emitters[0].Particles[iParticle].Location += Location;
    }

    Emitters[0].Acceleration.Z = PhysicsVolume.Gravity.Z;

    Emitters[0].CoordinateSystem      = Emitters[0].EParticleCoordinateSystem.PTCS_Independent;
    Emitters[0].UseSkeletalLocationAs = Emitters[0].ESkelLocationUpdate.PTSU_None;

    bOwnerNoSee = False;
  }


  // ======================================================
  // State
  // ======================================================

  Begin:
    Shatter();
    Sleep(6.0);
    Destroy();

} // state Shatter


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Begin Object class=MeshEmitter Name=MeshEmitterIce
    StaticMesh=StaticMesh'JBToolbox2.IceChunk'
    RespawnDeadParticles=False
    SpinParticles=True
    UseSizeScale=True
    UseRegularSizeScale=False
    UniformSize=True
    AutomaticInitialSpawning=False
    DampingFactorRange=(X=(Min=0.000000,Max=0.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
    CoordinateSystem=PTCS_Relative
    MaxParticles=500
    StartLocationRange=(X=(Min=-2.000000,Max=2.000000),Y=(Min=-2.000000,Max=2.000000),Z=(Min=-5.000000,Max=1.000000))
    UseRotationFrom=PTRS_Offset
    StartSpinRange=(X=(Max=1.000000),Y=(Max=1.000000),Z=(Max=1.000000))
    SizeScale(0)=(RelativeSize=0.700000)
    SizeScale(1)=(RelativeTime=0.020000,RelativeSize=0.800000)
    SizeScale(2)=(RelativeTime=0.030000,RelativeSize=1.000000)
    SizeScale(3)=(RelativeTime=0.400000,RelativeSize=1.000000)
    SizeScale(4)=(RelativeTime=1.000000)
    StartSizeRange=(X=(Min=0.220000,Max=0.280000))
    UseSkeletalLocationAs=PTSU_Location
    SkeletalScale=(X=0.350000,Y=0.350000,Z=0.350000)
    InitialParticlesPerSecond=2000.000000
    LifetimeRange=(Min=10.000000,Max=10.000000)
  End Object
  Emitters(0)=MeshEmitter'JBToolbox2.MeshEmitterIce'

  bNoDelete=False
  AmbientGlow=128
  Skins(0) = Texture'JBToolbox2.IceSkin'
}
