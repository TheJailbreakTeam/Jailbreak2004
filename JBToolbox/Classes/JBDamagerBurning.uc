// ============================================================================
// JBDamagerBurning
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBDamagerBurning.uc,v 1.3 2006-07-17 15:07:13 wormbo Exp $
//
// Damager for burning execution.
// ============================================================================
class JBDamagerBurning extends JBDamager NotPlaceable;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Sounds\WeaponSounds.uax


//=============================================================================
// Variables
//=============================================================================

var JBEmitterBurningPlayer FlameEmitter;


// ============================================================================
// GetDamageAmount
//
// Return the damage amount for the next TakeDamage() call.
// ============================================================================
function int GetDamageAmount()
{
  return 7 + Rand(6);
}


// ============================================================================
// DamageVictim
//
// Check, whether the victim is still alive and if not, spawn a LavaDeath-style
// explosion that also shows up in low detail mode.
// ============================================================================

function DamageVictim()
{
  Super.DamageVictim();

  if (Victim != None && Victim.Health <= 0)
    SpawnEffects();
}


// ============================================================================
// Timer
//
// Kill the victim after he's "done".
// ============================================================================

function Timer()
{
  if (VictimIsAlive()) {
    SpawnEffects();
    Victim.Died(None, DamageType, Victim.Location);
  }
}


// ============================================================================
// SpawnEffects
//
// Spawns a flame explosion effect and play an appropriate sound effect.
// ============================================================================

function SpawnEffects()
{
  local Emitter DeathExplosion;

  // kill the flame emitter
  if (FlameEmitter != None) {
    FlameEmitter.bTearOff = True;
    FlameEmitter.TornOff();
    FlameEmitter = None;
  }

  DeathExplosion = Spawn(class'JBEmitterKillLaserFlame',,, Victim.Location + vect(0, 0, 10), Victim.Rotation);
  DeathExplosion.RemoteRole = ROLE_SimulatedProxy;
  Victim.PlaySound(Sound'WeaponSounds.BExplosion5', SLOT_None, 1.5 * Victim.TransientSoundVolume);
}


// ============================================================================
// Left-over functions (only for binary compatibility)
// ============================================================================

function Tick(float DeltaTime)      { Super.Tick(DeltaTime); }
function vector GetDamageMomentum() { return Super.GetDamageMomentum(); }
function Destroyed()                { Super.Destroyed(); }


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  DamageType  = class'JBDamageTypeIncinerated'
  MaxDelay    = 0.4
  MinDelay    = 0.2
}
