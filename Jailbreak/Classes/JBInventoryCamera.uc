// ============================================================================
// JBInventoryCamera
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBInventoryCamera.uc,v 1.1 2004/03/14 16:19:13 mychaeel Exp $
//
// Inventory item used to track use of the PrevWeapon and NextWeapon console
// commands to switch cameras within a camera array.
// ============================================================================


class JBInventoryCamera extends Inventory
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role < ROLE_Authority)
    ServerPrevWeapon,
    ServerNextWeapon;
}


// ============================================================================
// Variables
// ============================================================================

var JBCamera Camera;   // camera controlled by this inventory item


// ============================================================================
// PrevWeapon
// NextWeapon
//
// Cause the attached camera to switch to its array predecessor or successor,
// respectively. Prevent actual weapon switching.
// ============================================================================

simulated function Weapon PrevWeapon(Weapon WeaponChoice, Weapon WeaponCurrent) { ServerPrevWeapon(); return Instigator.PendingWeapon; }
simulated function Weapon NextWeapon(Weapon WeaponChoice, Weapon WeaponCurrent) { ServerNextWeapon(); return Instigator.PendingWeapon; }


// ============================================================================
// ServerPrevWeapon
// ServerNextWeapon
//
// Send switching commands to the attached camera.
// ============================================================================

function ServerPrevWeapon() { Camera.SwitchToPrev(Instigator.Controller, True); }
function ServerNextWeapon() { Camera.SwitchToNext(Instigator.Controller, True); }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bAlwaysRelevant      = True;
  bOnlyRelevantToOwner = True;
  bReplicateInstigator = True;
}