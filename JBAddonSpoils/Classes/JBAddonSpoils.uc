// ============================================================================
// JBAddonSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// This add-on give a weapon to arena winner.
// ============================================================================


class JBAddonSpoils extends JBAddon config cacheexempt;


//=============================================================================
// Constants
//=============================================================================

const DEFAULT_MAX_AMMO  = False;
const DEFAULT_CAN_THROW = False;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
var() config class<Weapon> SpoilsWeapon;     // type of weapon awarded
var() config bool bMaxAmmo;
var() config bool bCanThrow;


//=============================================================================
// Localization
//=============================================================================

var localized string WeaponComboText, WeaponComboDesc;
var localized string MaxAmmoText,     MaxAmmoCheckDesc;
var localized string CanThrowText,    CanThrowCheckDesc;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
  local JBGameRulesSpoils SpoilsRules;

  Super.PostBeginPlay();

  SpoilsRules = Spawn(class'JBGameRulesSpoils');

  if (SpoilsRules != None)
  {
    if (Level.Game.GameRulesModifiers == None)
      Level.Game.GameRulesModifiers = SpoilsRules;
    else
      Level.Game.GameRulesModifiers.AddGameRules(SpoilsRules);
  }
  else
  {
    LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesSpoils !!!!!");
    Destroy();
  }
}


//=============================================================================
// FillPlayInfo
//
// Adds configurable Spoils properties to the web admin interface.
//=============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
  local array<CacheManager.WeaponRecord> Recs;
  local string WeaponOptions;
  local int i;

  // add current class to stack
  PlayInfo.AddClass(default.Class);

  class'CacheManager'.static.GetWeaponList(Recs);

  for (i = 0; i < Recs.Length; i++)
  {
    if (WeaponOptions != "")
      WeaponOptions $= ";";

    WeaponOptions $= Recs[i].ClassName $ ";" $ Recs[i].FriendlyName;
  }

  WeaponOptions $= "XWeapons.SuperShockRifle;Super Shock Rifle";
  WeaponOptions $= "XWeapons.ZoomSuperShockRifle;Zoom Super Shock Rifle";

  // now register any mutator settings
  PlayInfo.AddSetting(PlayInfoGroup(), "WeaponClassName", default.WeaponComboText, 0, 0, "Select", WeaponOptions);
  PlayInfo.AddSetting(PlayInfoGroup(), "MaxAmmo",         default.MaxAmmoText,     0, 1, "Check");
  PlayInfo.AddSetting(PlayInfoGroup(), "CanThrow",        default.CanThrowText,    0, 2, "Check");

  // remove mutator class from class stack
  PlayInfo.PopClass();
}


//=============================================================================
// GetDescriptionText
//
// Returns a description text for the specified property.
//=============================================================================

static event string GetDescriptionText(string PropName)
{
  Switch (PropName) {
    Case "WeaponClassName": return default.WeaponComboDesc;
    Case "MaxAmmo":         return default.MaxAmmoCheckDesc;
    Case "CanThrow":        return default.CanThrowCheckDesc;
  }
}


//=============================================================================
// ResetConfiguration
//
// Resets the Spoils configuration.
//=============================================================================

static function ResetConfiguration()
{
  default.SpoilsWeapon = class'XWeapons.AssaultRifle';
  default.bMaxAmmo     = DEFAULT_MAX_AMMO;
  default.bCanThrow    = DEFAULT_CAN_THROW;

  StaticSaveConfig();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Build = "%%%%-%%-%% %%:%%"

  SpoilsWeapon = class'XWeapons.AssaultRifle'

  WeaponComboText   = "Avenger weapon"
  WeaponComboDesc   = "The weapon which is awarded to the avenger."
  MaxAmmoText       = "Max out ammo"
  MaxAmmoCheckDesc  = "Maximize the ammunition of the Avenger's weapon."
  CanThrowText      = "Allow weapon drop"
  CanThrowCheckDesc = "Allow the weapon to be thrown by the Avenger or dropped when he dies."

  ConfigMenuClassName = "JBAddonSpoils.JBGUIPanelConfigSpoils"
  FriendlyName        = "Arena Spoils"
  Description         = "Rewards the winner of an Arena Match with a weapon to use against those who imprisioned him!"
}
