// ============================================================================
// JBEmitterBasket
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Emitter effect resembling a basket for the standard release switch.
// ============================================================================


class JBEmitterBasket extends Emitter
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\BasketSprite.tga alpha=1 UClampMode=TC_Clamp VClampMode=TC_Clamp


// ============================================================================
// Properties
// ============================================================================

var() Color ColorRed;
var() Color ColorBlue;


// ============================================================================
// SetDefendingTeam
//
// Initializes this emitter by setting its color properties for the given
// defending team.
// ============================================================================

function SetDefendingTeam(int iTeam)
{
  local Color Color;
  local ParticleEmitter ParticleEmitter;

  ParticleEmitter = Emitters[0];
  
  switch (iTeam) {
    case 0:  Color = ColorRed;   break;
    case 1:  Color = ColorBlue;  break;
  }

  ParticleEmitter.ColorScale[0].Color.A = Color.A;
  ParticleEmitter.ColorScale[1].Color   = Color;
  ParticleEmitter.ColorScale[2].Color   = Color;
}


// ============================================================================
// Trigger
// UnTrigger
//
// Disable or enable the emitter.
// ============================================================================

event   Trigger(Actor ActorOther, Pawn PawnInstigator) { GotoState('Disabled'); }
event UnTrigger(Actor ActorOther, Pawn PawnInstigator) { GotoState('Enabled' ); }


// ============================================================================
// state Enabled
//
// Starts the emitter.
// ============================================================================

state Enabled
{
  // ================================================================
  // BeginState
  //
  // Resets all emitter properties to their previous defaults and
  // triggers the emitter to restart it.
  // ================================================================

  event BeginState()
  {
    local ParticleEmitter ParticleEmitter;

    ParticleEmitter = Emitters[0];

    ParticleEmitter.RespawnDeadParticles     = True;
    ParticleEmitter.AutomaticInitialSpawning = True;
    ParticleEmitter.RelativeWarmupTime       = 0.0;

    ParticleEmitter.Trigger();
  }

} // state Enabled


// ============================================================================
// state Disabled
//
// Stops the emitter and fades out all currently present particles.
// ============================================================================

state Disabled
{
  // ================================================================
  // BeginState
  //
  // Stops the emitter and modifies all present particles to make
  // them start fading out at once.
  // ================================================================

  event BeginState()
  {
    local int iParticle;
    local ParticleEmitter ParticleEmitter;

    ParticleEmitter = Emitters[0];

    for (iParticle = 0; iParticle < ParticleEmitter.Particles.Length; iParticle++)
      ParticleEmitter.Particles[iParticle].Time = ParticleEmitter.FadeOutStartTime;

    ParticleEmitter.RespawnDeadParticles     = False;
    ParticleEmitter.AutomaticInitialSpawning = False;
  }

}  // state Disabled


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bNoDelete = False;

  ColorRed  = (R=255,G=0,B=0,A=128);
  ColorBlue = (R=0,G=0,B=255,A=196);

  Begin Object Class=SpriteEmitter Name=SpriteEmitterBasketDef
    Texture                   = Texture'BasketSprite';
    DrawStyle                 = PTDS_AlphaBlend;

    MaxParticles              = 400;
    RelativeWarmupTime        = 1.0;
    WarmupTicksPerSecond      = 1.0;

    Acceleration              = (Z=16.0);
    GetVelocityDirectionFrom  = PTVD_AddRadial;
    StartVelocityRadialRange  = (Min=16.0,Max=24.0);
    UseRevolution             = True;
    RevolutionsPerSecondRange = (Z=(Min=0.3,Max=0.3));

    FadeIn                    = True;
    FadeInEndTime             = 1.0;
    FadeOut                   = True;
    FadeOutStartTime          = 3.0;

    UseColorScale             = True;
    ColorScale[0]             = (RelativeTime=0.0,Color=(R=255,G=255,B=255));
    ColorScale[1]             = (RelativeTime=0.8);
    ColorScale[2]             = (RelativeTime=1.0);

    StartLocationShape        = PTLS_Polar
    StartLocationPolarRange   = (X=(Min=0,Max=65536),Y=(Min=16384,Max=16384),Z=(Min=20.0,Max=28.0));
    UniformSize               = True;
    StartSizeRange            = (X=(Min=1.0,Max=2.0));

    TriggerDisabled           = False;
    ResetOnTrigger            = True;
  End Object
  
  Emitters[0] = SpriteEmitter'SpriteEmitterBasketDef';
}