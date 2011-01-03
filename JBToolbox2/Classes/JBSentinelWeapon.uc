// ============================================================================
// JBSentinelWeapon
// Copyright 2004 by Blitz
// $Id: JBSentinelWeapon.uc,v 1.1 2006-12-16 19:39:37 jrubzjeknf Exp $
//
// The weapon that the sentinel uses.
// ============================================================================


class JBSentinelWeapon extends Weapon_Sentinel
  notplaceable cacheexempt;


// ============================================================================
// SetCustomProjectile
//
// Sets the proper variables in the WeaponFire class, so custom projectiles
// and their fancy stuff can be used.
// ============================================================================

function SetCustomProjectile(class<Projectile> ProjectileClass,
                             int Mode,
                             float FireRate,
                             Sound FireSound,
                             class<xEmitter> FlashEmitterClass,
                             class<xEmitter> SmokeEmitterClass)
{
  local FM_Sentinel_Fire SentinelFire;

  if (Mode < 0 || Mode >= NUM_FIRE_MODES)
    return;

  SentinelFire = FM_Sentinel_Fire(FireMode[Mode]);

  if (SentinelFire != None) {
    if (ProjectileClass != None) {
      SentinelFire.TeamProjectileClasses[0] = ProjectileClass;
      SentinelFire.TeamProjectileClasses[1] = ProjectileClass;
    }

    if (FireRate > 0.0)
      SentinelFire.FireRate = FireRate;

    SentinelFire.FireSound         = FireSound;
    SentinelFire.FlashEmitterClass = FlashEmitterClass;
    SentinelFire.SmokeEmitterClass = SmokeEmitterClass;
  }
}