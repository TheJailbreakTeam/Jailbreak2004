// ============================================================================
// JBAddonAvenger (formerly JBAddonBerserker)
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonAvenger.uc,v 1.1.2.2 2004/05/12 10:04:45 tarquin Exp $
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
var() config int PowerTimeMultiplier;
var() config int PowerTimeMaximum;
var() config int PowerComboIndex;

var class<Combo> ComboClasses[4]; 


//=============================================================================
// Localization
//=============================================================================

var localized string PowerTimeMultiplierText;
var localized string PowerTimeMaximumText;
var localized string PowerComboIndexText;


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
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerTimeMultiplier", default.PowerTimeMultiplierText,  0, 0, "Text", "3;1:200");
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerTimeMaximum",    default.PowerTimeMaximumText,     0, 0, "Text", "3;10:60");
  PlayInfo.AddSetting(PlayInfoGroup(), "PowerComboIndex",     default.PowerComboIndexText,      0, 0, "Select", "0;Speed;1;Berserk;2;Booster;3;Invisible;");

  // remove mutator class from class stack
  PlayInfo.PopClass();
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

  PowerTimeMultiplierText = "Percentage to multiply arena remaining time by to give avenger time";
  PowerTimeMaximumText    = "Maximum avenger time allowable";
  PowerComboIndexText     = "Combo awarded to the avenger";
    
  ComboClasses(0)=class'XGame.ComboSpeed'
  ComboClasses(1)=class'XGame.ComboBerserk'
  ComboClasses(2)=class'XGame.ComboDefensive'
  ComboClasses(3)=class'XGame.ComboInvis'
}
