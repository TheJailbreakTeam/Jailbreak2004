// ============================================================================
// JBAddonProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonProtection.uc,v 1.6.2.2 2004/04/05 09:52:53 tarquin Exp $
//
// This add-on protects players released from jail.
// ============================================================================


class JBAddonProtection extends JBAddon config;


//=============================================================================
// Constants
//=============================================================================

const DEFAULT_PROTECTION_TIME = 3;
const DEFAULT_PROTECTION_TYPE = 0;
const DEFAULT_PROTECT_ARENA   = 1; // doesn't work
const DEFAULT_LLAMAIZE_CAMPERS= 1; // doesn't work


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
var() config float ProtectionTime;
var() config byte ProtectionType;
var() config bool bProtectArenaWinner;
var() config bool bLlamaizeCampers;

var PlayerReplicationInfo LastRestartedPRI;
var localized string desc_ProtectionType;
var localized string desc_ProtectionTime;
var localized string desc_ProtectArenaWinner;
var localized string desc_LlamaizeCampers;


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
    PlayInfo.AddSetting(default.FriendlyName, "bLlamaizeCampers", default.desc_LlamaizeCampers , 0, 0, "Check");
    PlayInfo.PopClass();
}


//=============================================================================
// ResetConfiguration
//
// Resets the Avenger configuration.
//=============================================================================

static function ResetConfiguration()
{
  default.ProtectionTime      = DEFAULT_PROTECTION_TIME;
  default.ProtectionType      = DEFAULT_PROTECTION_TYPE;
  default.bProtectArenaWinner = true; // bool(DEFAULT_PROTECT_ARENA);
  default.bLlamaizeCampers    = true; // bool(DEFAULT_LLAMAIZE_CAMPERS);
  StaticSaveConfig();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Build = "%%%%-%%-%% %%:%%";
    ProtectionTime      =3.000000
    ProtectionType      =0
    bProtectArenaWinner =True
    bLlamaizeCampers    =True
    FriendlyName="Release Protection"
    Description="Players released from jail are protected from enemy fire."
    ConfigMenuClassName="JBAddonProtection.JBGUIPanelConfigProtection"
    desc_ProtectionTime="The protection time."
    desc_ProtectionType="The protection type."
    desc_ProtectArenaWinner="When enabled, the arena winner gains protection."
    desc_LlamaizeCampers="When enabled, players causing lethal damage to protected players are made llamas."
}
