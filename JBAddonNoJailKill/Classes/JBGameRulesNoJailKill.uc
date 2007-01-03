// ============================================================================
// JBGameRulesNoJailKill - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// The rules for the NoJailKill add-on.
// ============================================================================


class JBGameRulesNoJailKill extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================
var private Shader RedHitEffect, BlueHitEffect;
var private Sound ProtectionHitSound;


//=============================================================================
// NetDamage
//
// Modifies the damage done if the instigator is jailed, and the victim is not.
//=============================================================================

function int NetDamage (int OriginalDamage, int Damage, Pawn injured, Pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
  local JBTagPlayer TagPlayerInstigator;
  local JBTagPlayer TagPlayerVictim;
  local xPawn xProtectedPawn;

  // No instigator or himself.
  if (instigatedBy == None ||
      instigatedBy.Controller == injured.Controller)
    return super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

  TagPlayerInstigator = Class'JBTagPlayer'.Static.FindFor(instigatedBy.PlayerReplicationInfo);
  TagPlayerVictim     = Class'JBTagPlayer'.Static.FindFor(injured     .PlayerReplicationInfo);

  // No tag found for the instigator or the victim.
  if (TagPlayerInstigator == None ||
      TagPlayerVictim     == None)
      return super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

  // Nullify damage and momentum.
  if (TagPlayerInstigator.IsInJail())
  {
    Momentum.X = 0;
    Momentum.Y = 0;
    Momentum.Z = 0;

    // Visual feedback: the victim lights up.
    xProtectedPawn = xPawn(injured);
    injured.PlaySound(ProtectionHitSound, SLOT_Pain, TransientSoundVolume*2,, 400);

    switch (xProtectedPawn.PlayerReplicationInfo.Team.TeamIndex) {
      case 0: xProtectedPawn.SetOverlayMaterial(RedHitEffect, xProtectedPawn.ShieldHitMatTime, False);
      case 1: xProtectedPawn.SetOverlayMaterial(BlueHitEffect,xProtectedPawn.ShieldHitMatTime, False);
    }

    return 0;
  }

  return super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  RedHitEffect  = Shader'XGameShaders.PlayerShaders.PlayerTransRed'
  BlueHitEffect = Shader'XGameShaders.PlayerShaders.PlayerTrans'
  ProtectionHitSound = Sound'WeaponSounds.BaseImpactAndExplosions.BShieldReflection'
}
