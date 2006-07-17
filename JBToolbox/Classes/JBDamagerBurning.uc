// ============================================================================
// JBDamagerBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBDamagerBurning.uc,v 1.1 2003-06-27 11:14:25 crokx Exp $
//
// Damage of Burning execution.
// ============================================================================
class JBDamagerBurning extends JBDamager NotPlaceable;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Sounds\WeaponSounds.uax


// ============================================================================
// Damage functions
//
// Some functions for change the damage.
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
    Victim.Died(None, DamageType, vect(0,0,0));
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

  DeathExplosion = Spawn(class'JBEmitterKillLaserFlame', Victim,, Victim.Location);
  DeathExplosion.RemoteRole = ROLE_SimulatedProxy;
  Victim.PlaySound(Sound'WeaponSounds.BExplosion5', SLOT_None, 1.5 * Victim.TransientSoundVolume);
}


// ============================================================================
// Unused functions and state
// ============================================================================
function Tick(float DeltaTime)      {}
function vector GetDamageMomentum() { return Super.GetDamageMomentum(); }
function Destroyed()                { Super.Destroyed(); }


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    DamageType=class'JBToolbox.JBDamageTypeIncinerated'
    MaxDelay=0.400000
    MinDelay=0.200000
}
