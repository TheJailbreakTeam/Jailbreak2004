// ============================================================================
// JBDamageTypeIncinerated
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Damage type for incineration execution.
// ============================================================================

class JBDamageTypeIncinerated extends DamageType
  abstract;


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  DeathString="%o was incinerated by %k"
  FemaleSuicide="%o was incinerated"
  MaleSuicide="%o was incinerated"
  bArmorStops=False
  bLocationalHit=False
  bSkeletize=True
  bCausedByWorld=True
  GibModifier=2.000000
  GibPerterbation=0.500000
}
