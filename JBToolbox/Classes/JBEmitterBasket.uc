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
// SetInitialState
//
// Disables the Tick event.
// ============================================================================

event SetInitialState()
{
  Super.SetInitialState();
  Disable('Tick');
}


// ============================================================================
// Trigger
//
// Stops the emitter and makes the present particles fade out.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator)
{
  Emitters[0].RespawnDeadParticles = False;
  Enable('Tick');
}


// ============================================================================
// Tick
//
// Gradually fades out the emitter.
// ============================================================================

event Tick(float TimeDelta)
{
  Emitters[0].Opacity = FMax(0.0, Emitters[0].Opacity - Default.Emitters[0].Opacity * TimeDelta * 2.0);

  if (Emitters[0].Opacity == 0.0)
    Disable('Tick');
}


// ============================================================================
// UnTrigger
//
// Restarts the emitter with default settings.
// ============================================================================

event UnTrigger(Actor ActorOther, Pawn PawnInstigator)
{
  Emitters[0].Opacity = Default.Emitters[0].Opacity;
  Disable('Tick');

  Emitters[0].RespawnDeadParticles = True;
  Emitters[0].RelativeWarmupTime = 0.0;
  Emitters[0].Reset();
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bNoDelete = False;

  Begin Object Class=MeshEmitter Name=MeshEmitterBasketDef
    StaticMesh                    = StaticMesh'XEffects.TeleRing';
    Opacity                       = 0.4;
    UseParticleColor              = True;
    
    RelativeWarmupTime            = 1.0;
    WarmupTicksPerSecond          = 10.0;
    LifetimeRange                 = (Min=3.0,Max=3.0);

    Acceleration                  = (Z=13.0);

    FadeIn                        = True;
    FadeInEndTime                 = 2.0;
    FadeOut                       = True;
    FadeOutStartTime              = 2.5;
    
    UseSizeScale                  = True;
    UseRegularSizeScale           = False;
    ScaleSizeXByVelocity          = True;
    ScaleSizeYByVelocity          = True;
    SizeScale[0]                  = (RelativeTime=1.0,RelativeSize=0.3);
    StartSizeRange                = (X=(Min=3.7,Max=3.7),Y=(Min=3.7,Max=3.7),Z=(Min=1.0,Max=1.0));
    ScaleSizeByVelocityMultiplier = (X=0.016,Y=0.016);
  End Object

  Emitters[0] = MeshEmitter'MeshEmitterBasketDef';
}