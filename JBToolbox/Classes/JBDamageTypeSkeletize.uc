// ============================================================================
// JBDamageTypeSkeletize
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBDamageTypeSkeletize.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// Used by JBExecutionSkeletize for skeletize the jailed player.
// ============================================================================
class JBDamageTypeSkeletize extends DamageType abstract;


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    DeathString="%o was skeletized."
    MaleSuicide="%o was skeletized."
    FemaleSuicide="%o was skeletized."
    bLocationalHit=false
    bArmorStops=false
    bSkeletize=true
    FlashFog=(X=16,Y=16,Z=16)
}
