// ============================================================================
// JBAddonAvenger (formerly JBAddonBerserker)
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonAvenger.uc,v 1.5 2004/05/20 14:47:56 wormbo Exp $
//
// This add-on give berserk to arena winner.
// ============================================================================


class JBAddonAvenger extends JBAddon config;


//=============================================================================
// Constants
//=============================================================================

const DEFAULT_TIME_MULTIPLIER = 100;
const DEFAULT_TIME_MAXIMUM    = 25;
const DEFAULT_POWERUP_TYPE    = 1;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
var() config int PowerTimeMultiplier; // multiply the arena time remaining
var() config int PowerTimeMaximum;    // subject to this maximum
var() config int PowerComboIndex;     // type of combo awarded

var class<Combo> ComboClasses[4]; 


//=============================================================================
// Localization
//=============================================================================

var localized string PowerTimeMultiplierText, PowerTimeMultiplierDesc;
var localized string PowerTimeMaximumText,    PowerTimeMaximumDesc;
var localized string PowerComboIndexText,     PowerComboIndexDesc;
var localized string PowerComboIndexOptions;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
    local JBGameRulesAvenger AvengerRules;

    Super.PostBeginPlay();

    AvengerRules = Spawn(Class'JBGameRulesAvenger');
    if(AvengerRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = AvengerRules;
        else Level.Game.GameRulesModifiers.AddGameRules(AvengerRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesAvenger !!!!!");
        Destroy();
    }
}


//=============================================================================
// FillPlayInfo
//
// Adds configurable Avenger properties to the web admin interface.
//=============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
  // add current class to stack
  PlayInfo.AddClass(default.Class);
  
  // now register any mutator settings
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerTimeMultiplier", default.PowerTimeMultiplierText, 0, 0, "Text", "3;1:200");
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerTimeMaximum",    default.PowerTimeMaximumText,    0, 0, "Text", "3;10:60");
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerComboIndex",     default.PowerComboIndexText,     0, 0, "Select", default.PowerComboIndexOptions);

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
    Case "PowerTimeMultiplier": return default.PowerTimeMultiplierDesc;
    Case "PowerTimeMaximum":    return default.PowerTimeMaximumDesc;
    Case "PowerComboIndex":     return default.PowerComboIndexDesc;
  }
}


//=============================================================================
// ResetConfiguration
//
// Resets the Avenger configuration.
//=============================================================================

static function ResetConfiguration()
{
  default.PowerTimeMultiplier = DEFAULT_TIME_MULTIPLIER;
  default.PowerTimeMaximum    = DEFAULT_TIME_MAXIMUM;
  default.PowerComboIndex     = DEFAULT_POWERUP_TYPE;
  StaticSaveConfig();
}


// ============================================================================
// Default properties
// ============================================================================

/*
  from xPLayer:
    ComboNameList(0)="XGame.ComboSpeed"
    ComboNameList(1)="XGame.ComboBerserk"
    ComboNameList(2)="XGame.ComboDefensive"
    ComboNameList(3)="XGame.ComboInvis"
*/

defaultproperties
{
  Build = "%%%%-%%-%% %%:%%";
  PowerTimeMultiplier = 100;
  PowerTimeMaximum    = 25;
  PowerComboIndex     = 1;
  FriendlyName        = "Arena Avenger"
  Description="The arena winner is mad... he's out to get his revenge on those who imprisoned him with the help of a power-up!"
  ConfigMenuClassName="JBAddonAvenger.JBGUIPanelConfigAvenger"

  PowerTimeMultiplierText = "Avenger time multiplier";
  PowerTimeMaximumText    = "Maximum avenger time";
  PowerComboIndexText     = "Avenger power";
  
  PowerTimeMultiplierDesc = "Percentage to multiply arena remaining time by to give avenger time.";
  PowerTimeMaximumDesc    = "Maximum avenger time allowable.";
  PowerComboIndexDesc     = "Combo awarded to the avenger.";
  
  PowerComboIndexOptions = "0;Speed;1;Berserk;2;Booster;3;Invisible;4;Random";
    
  ComboClasses(0)=class'XGame.ComboSpeed'
  ComboClasses(1)=class'XGame.ComboBerserk'
  ComboClasses(2)=class'XGame.ComboDefensive'
  ComboClasses(3)=class'XGame.ComboInvis'
}
