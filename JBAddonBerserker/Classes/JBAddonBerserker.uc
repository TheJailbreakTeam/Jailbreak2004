// ============================================================================
// JBAddonBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonBerserker.uc,v 1.3 2004/03/12 20:57:54 tarquin Exp $
//
// This add-on give berserk to arena winner.
// ============================================================================
class JBAddonBerserker extends JBAddon config(JBAddons);


// ============================================================================
// Variables
// ============================================================================
var() const editconst string Build;
var() config int BerserkTimeMultiplier;
var() config int MaxBerserkTime;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================
function PostBeginPlay()
{
    local JBGameRulesBerserker BerserkerRules;

    Super.PostBeginPlay();

    BerserkerRules = Spawn(Class'JBGameRulesBerserker');
    if(BerserkerRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = BerserkerRules;
        else Level.Game.GameRulesModifiers.AddGameRules(BerserkerRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesBerserker !!!!!");
        Destroy();
    }
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Build = "2003-07-24 19:41";
    BerserkTimeMultiplier=50
    MaxBerserkTime=30
    FriendlyName="Berserker"
    Description="Arena winners are made Beserker. The amount of time depends on the swiftness of victory."
    ConfigMenuClassName="JBAddonBerserker.JBGUIPanelConfigBerserker"
}
