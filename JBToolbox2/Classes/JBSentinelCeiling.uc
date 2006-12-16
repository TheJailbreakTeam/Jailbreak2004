// ============================================================================
// JBSentinelCeiling
// Copyright 2004 by Blitz
// $Id$
//
// The sentinel that hangs from the ceiling.
// ============================================================================


class JBSentinelCeiling extends ASVehicle_Sentinel_Ceiling
  placeable;


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  TransientSoundVolume      = 0.250000
  DefaultWeaponClassName    = "JBToolbox2.JBSentinelWeapon"
  AutoTurretControllerClass = class'JBToolbox2.JBSentinelController'
}