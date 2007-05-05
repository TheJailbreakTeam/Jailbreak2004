// ============================================================================
// JBKickerTriggerable
// Copyright 2007 by Wormbo <wormbo@online.de>
// $Id: JBKickerTriggerable.uc,v 1.1 2007-05-01 13:22:26 wormbo Exp $
//
// A triggerable xKicker with several additional features:
//
// - can be trigger-toggled or trigger-controlled on/off
//
// - defines directions "in front" and "behind" by its location and rotation:
//   * can ignore touches if touching actor is behind
//   * can mirror the kick direction if the touching actor is behind
//
// - can cause damage to kicked actors
//
// - can play a sound on the kicked actor
// ============================================================================


class JBKickerTriggerable extends xKicker placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBKickerTriggerable.pcx mips=0 masked=1 group=Icons


// ============================================================================
// Properties
// ============================================================================

var(xKicker) bool bInitiallyEnabled;
var(xKicker) bool bOnlyKickIfInFront;
var(xKicker) bool bMirrorKickIfBehind;
var(xKicker) Sound KickSound;
var(xKicker) int KickDamage;
var(xKicker) class<DamageType> KickDamageType;


// ============================================================================
// Variables
// ============================================================================

var bool bEnabled;
var Volume AssociatedVolume;


// ============================================================================
// state Initializing
//
// Perform initialization of AssociatedVolume and bEnabled and check initially
// touching actors of the volume and own collision.
// ============================================================================

auto state Initializing
{
Begin:
  foreach AllActors(class'Volume', AssociatedVolume) {
    if (AssociatedVolume.AssociatedActor == Self)
      break;
  }
  if (AssociatedVolume != None && AssociatedVolume.AssociatedActor == Self) {
    if (bCollideActors) {
      log(Name $ " - Disabling bCollideActors because associated to volume " $ AssociatedVolume, 'Warning');
      SetCollision(False, False, False);
    }
  }
  else {
    AssociatedVolume = None;
    if (!bCollideActors)
      log(Name $ " - Not colliding and not associated to any volume.", 'Warning');
  }
  bEnabled = bInitiallyEnabled;
  if (bEnabled)
    CheckTouching();
}


// ============================================================================
// state TriggerToggle
//
// Trigger toogles the enabled status.
// ============================================================================

state() TriggerToggle extends Initializing
{
  event Trigger(Actor Other, Pawn EventInstigator)
  {
    bEnabled = !bEnabled;
    if (bEnabled)
      CheckTouching();
  }
}


// ============================================================================
// state TriggerControl
//
// Trigger inverts the initial enabled status, Untrigger resets.
// ============================================================================

state() TriggerControl extends Initializing
{
  event Trigger(Actor Other, Pawn EventInstigator)
  {
    if (bEnabled == bInitiallyEnabled) {
      bEnabled = !bInitiallyEnabled;
      
      if (bEnabled )
        CheckTouching();
    }
  }
  
  event Untrigger(Actor Other, Pawn EventInstigator)
  {
    if (bEnabled != bInitiallyEnabled) {
      bEnabled = bInitiallyEnabled;
      if (bEnabled)
        CheckTouching();
    }
  }
}


// ============================================================================
// Reset
//
// Resets the enabled status.
// ============================================================================

function Reset()
{
  if (bEnabled != bInitiallyEnabled) {
    bEnabled = bInitiallyEnabled;
    if (bEnabled)
      CheckTouching();
  }
}


// ============================================================================
// Touch
//
// Remembers the actor for kicking in PostTouch() if enabled and optionally if
// actor is in front of this kicker. Also causes the specified trigger event.
// ============================================================================

event Touch(Actor Other)
{
  if (bEnabled && (!bOnlyKickIfInFront || vector(Rotation) dot (Other.Location - Location) > 0))
    Super.Touch(Other);
}


// ============================================================================
// PostTouch
//
// Kicks the actor and optionally damages it and plays a sound.
// ============================================================================

event PostTouch(Actor Other)
{
  local bool bWasFalling;
  local vector Push, KickNormal, KickDir;
  local float PMag;
  
  bWasFalling = Other.Physics == PHYS_Falling;
  
  KickNormal = vector(Rotation);
  KickDir = KickVelocity;
  if (bMirrorKickIfBehind && KickNormal dot (Other.Location - Location) < 0) {
    KickDir -= 2 * KickNormal * (KickNormal dot KickDir);
    KickNormal *= -1;
  }
  
  if (bKillVelocity) {
    Push = -Other.Velocity;
  }
  else {
    Push = KickNormal * (KickNormal dot -Other.Velocity);
  }
  
  if (Push.Z < 0 && Push.Z + Other.Velocity.Z < 0) {
    Push.Z = -Velocity.Z;
  }
  if (bRandomize){
    PMag = VSize(KickDir);
    Push += PMag * Normal(KickDir + 0.5 * PMag * VRand());
  }
  else {
    Push += KickDir;
  }
  if (Pawn(Other) != None && Pawn(Other).Controller != None) {
    Pawn(Other).bNoJumpAdjust = True;
    Pawn(Other).Controller.SetFall();
  }
  if (Other.Physics == PHYS_Karma || Other.Physics == PHYS_KarmaRagdoll) {
    if (!Other.KIsAwake())
      Other.KWake();
    Other.KAddImpulse(Push * Other.Mass, vect(0,0,0));
  }
  else {
    Other.SetPhysics(PHYS_Falling);
    Other.Velocity += Push;
  }
  
  if (KickDamage > 0 && KickDamageType != None) {
    Other.TakeDamage(KickDamage, Other.Instigator, Other.Location - vector(Rotation) * Other.CollisionRadius, vect(0,0,0), KickDamageType);
  }
  if (Other != None && KickSound != None) {
    Other.PlaySound(KickSound,, TransientSoundVolume,, TransientSoundRadius);
  }
}


// ============================================================================
// CheckTouching
//
// Kick all actors touching this kicker or its associated volume.
// ============================================================================

function CheckTouching()
{
  local Actor A;
  
  if (AssociatedVolume != None) {
    foreach AssociatedVolume.TouchingActors(class'Actor', A) {
      Touch(A);
    }
  }
  else if (bCollideActors) {
    foreach TouchingActors(class'Actor', A) {
      Touch(A);
    }
  }
  
  while (PendingTouch != None) {
    PostTouch(PendingTouch);
    if (PendingTouch != None) {
      A = PendingTouch;
      PendingTouch = PendingTouch.PendingTouch;
      A.PendingTouch = None;
    }
  }
}


// ============================================================================
// Default values
// ============================================================================

defaultproperties
{
  bDirectional      = True
  bInitiallyEnabled = True
  DrawScale         = 0.5
  Texture           = Texture'JBKickerTriggerable'
}
