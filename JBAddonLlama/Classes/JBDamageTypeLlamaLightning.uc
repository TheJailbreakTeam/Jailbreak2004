//=============================================================================
// JBDamageTypeLlamaLightning
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Damage type for the lightning strike punishment.
//=============================================================================


class JBDamageTypeLlamaLightning extends DamageType
  abstract;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  DeathString="%o was struck by lightning"
  MaleSuicide="%o was struck by lightning"
  FemaleSuicide="%o was struck by lightning"
  DamageOverlayMaterial=Material'XGameShaders.PlayerShaders.LightningHit'
  DamageOverlayTime=1.0
  bCauseConvulsions=true
  bArmorStops=false
  bNeverSevers=true
  bCausesBlood=false
  bLocationalHit=false
}