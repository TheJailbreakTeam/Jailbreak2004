// ============================================================================
// JBAddonProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonProtection.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// This mutator protect the released players.
// ============================================================================
class JBAddonProtection extends JBAddon config(JBAddons);


// ============================================================================
// Variables
// ============================================================================
var() const editconst string Build;
var() config byte ProtectionType;
var() config bool bProtectArenaWinner;
var() config float ProtectionTime;
var int LastRestartedPlayerID;


// ============================================================================
// PostBeginPlay
//
// Spawn and registre the additional rules.
// ============================================================================
function PostBeginPlay()
{
    local JBGameRulesProtection ProtectionRules;

    Super.PostBeginPlay();

    ProtectionRules = Spawn(class'JBGameRulesProtection');
    if(ProtectionRules != None)
    {
        ProtectionRules.MyAddon = SELF;
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = ProtectionRules;
        else Level.Game.GameRulesModifiers.AddGameRules(ProtectionRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to registre the JBGameRulesProtection !!!!!");
        Destroy();
    }
}


// ============================================================================
// ModifyPlayer
//
// When a player restart, save his PlayerID.
// ============================================================================
function ModifyPlayer(Pawn P)
{
    if(P.PlayerReplicationInfo != None)
        LastRestartedPlayerID = P.PlayerReplicationInfo.PlayerID;

    Super.ModifyPlayer(P);
}


// ============================================================================
// MutatorFillPlayInfo
//
// ?????
// ============================================================================
function MutatorFillPlayInfo(PlayInfo PlayInfo)
{
    PlayInfo.AddClass(class);
    PlayInfo.AddSetting("Release protection", "bProtectArenaWinner", "When enabled, the arena winner gain protection.", 0, 0, "Check");
    PlayInfo.PopClass();

    Super.MutatorFillPlayInfo(PlayInfo);
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Build = "2003-07-24 19:35";
    bProtectArenaWinner=True
    ProtectionTime=3.000000
    ProtectionType=0
    FriendlyName="Release protection"
    Description="The released players are protected some time."
    ConfigMenuClassName="JBAddonProtection.JBGUIPanelProtectionConfig"
}
