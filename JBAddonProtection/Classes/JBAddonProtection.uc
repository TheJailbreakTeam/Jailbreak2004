// ============================================================================
// JBAddonProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonProtection.uc,v 1.5 2004/03/18 20:07:42 tarquin Exp $
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
var PlayerReplicationInfo LastRestartedPRI;
var localized string desc_ProtectionType;
var localized string desc_ProtectionTime;
var localized string desc_ProtectArenaWinner;


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
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to spawn JBGameRulesProtection !!!!!");
        Destroy();
    }
}


// ============================================================================
// ModifyPlayer
//
// When a player restart, save his PRI.
// ============================================================================
function ModifyPlayer(Pawn P)
{
    LastRestartedPRI = P.PlayerReplicationInfo;

    Super.ModifyPlayer(P);
}


// ============================================================================
// FillPlayInfo
//
// Adds configurable addon properties to the web admin interface.
// ============================================================================
static function FillPlayInfo(PlayInfo PlayInfo)
{
    PlayInfo.AddClass(default.class);
    PlayInfo.AddSetting(default.FriendlyName, "ProtectionType", default.desc_ProtectionType, 0, 0, "Text", "3;0:2");
    PlayInfo.AddSetting(default.FriendlyName, "ProtectionTime", default.desc_ProtectionTime, 0, 0, "Text", "3;1:10");
    PlayInfo.AddSetting(default.FriendlyName, "bProtectArenaWinner", default.desc_ProtectArenaWinner , 0, 0, "Check");
    PlayInfo.PopClass();
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
    Description="Players released from jail are protected from enemy fire."
    ConfigMenuClassName="JBAddonProtection.JBGUIPanelConfigProtection"
    desc_ProtectionTime="The protection time."
    desc_ProtectionType="The protection type."
    desc_ProtectArenaWinner="When enabled, the arena winner gains protection."
}
