// ============================================================================
// JBAddonBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonBerserker.uc,v 1.5 2004/04/04 00:53:36 mychaeel Exp $
//
// This add-on give berserk to arena winner.
// ============================================================================
class JBAddonBerserker extends JBAddon config;


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
    Build = "%%%%-%%-%% %%:%%";
    BerserkTimeMultiplier=50
    MaxBerserkTime=30
    FriendlyName="Berserker"
    Description="Arena winners are made Beserker. The amount of time depends on the swiftness of victory."
    ConfigMenuClassName="JBAddonBerserker.JBGUIPanelConfigBerserker"
}
