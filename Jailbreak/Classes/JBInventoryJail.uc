// ============================================================================
// JBInventoryJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInventoryJail.uc,v 1.1 2003/06/15 14:32:14 mychaeel Exp $
//
// Inventory item temporarily given to bots in jail to make them prefer a
// specific weapon over all others during a jail fight.
// ============================================================================


class JBInventoryJail extends Inventory
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var Weapon WeaponRecommended;  // temporarily preferred weapon


// ============================================================================
// RecommendWeapon
//
// Tells the bot to prefer the specified weapon over all others.
// ============================================================================

simulated function Weapon RecommendWeapon(out float RatingWeapon)
{
  if (WeaponRecommended == None)
    return Super.RecommendWeapon(RatingWeapon);

  RatingWeapon = 10.0;  // very high
  return WeaponRecommended;
}
