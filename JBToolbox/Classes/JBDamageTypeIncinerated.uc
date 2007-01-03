// ============================================================================
// JBDamageTypeIncinerated
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBDamageTypeIncinerated.uc,v 1.1 2006-07-17 14:18:27 jrubzjeknf Exp $
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
  DeathString="%o was incinerated."
  FemaleSuicide="%o was incinerated."
  MaleSuicide="%o was incinerated."
  bArmorStops=False
  bLocationalHit=False
  bSkeletize=True
  bCausedByWorld=True
  GibModifier=2.000000
  GibPerterbation=0.500000
}
