//=============================================================================
// JBDamageTypeLlamaLaser
// Copyright 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Damage type for the JBLlamaKillLaser punishment.
//=============================================================================


class JBDamageTypeLlamaLaser extends DamageType
  abstract;


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  DeathString="%o was toasted"
  MaleSuicide="%o was toasted"
  FemaleSuicide="%o was toasted"
  
  Begin Object Class=Shader Name=LaserHit
    Diffuse=Texture'PlayerSkins.JuggFemaleABodyA'
    Specular=Texture'UCGeneric.SolidColours.Red'
    SpecularityMask=ConstantColor'XGameShaders.OverlayConstant'
  End Object
  
  DamageOverlayMaterial=LaserHit
  DamageOverlayTime=3.0
  bSkeletize=true
  bArmorStops=False
  GibPerterbation=0.5
  GibModifier=2.0
  bLocationalHit=false
}