// ============================================================================
// JBSentinelCeiling
// Copyright 2004 by Blitz
// $Id: JBSentinelCeiling.uc,v 1.1 2006-12-16 19:39:37 jrubzjeknf Exp $
//
// The sentinel that hangs from the ceiling.
// ============================================================================


class JBSentinelCeiling extends ASVehicle_Sentinel_Ceiling
  placeable
  cacheexempt;


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  TransientSoundVolume      = 0.250000
  DefaultWeaponClassName    = "JBToolbox2.JBSentinelWeapon"
  AutoTurretControllerClass = class'JBToolbox2.JBSentinelController'
}