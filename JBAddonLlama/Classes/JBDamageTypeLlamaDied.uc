//=============================================================================
// JBDamageTypeLlamaDied
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Damage type used for killing the llama when the llama hunt lasts too long.
//=============================================================================


class JBDamageTypeLlamaDied extends DamageType
  abstract;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  DeathString="%o didn't want to be a llama anymore."
  MaleSuicide="%o didn't want to be a llama anymore."
  FemaleSuicide="%o didn't want to be a llama anymore."
  bLocationalHit=false
  bArmorStops=false
  bSpecial=True
  bCausesBlood=False
  bNeverSevers=True
}