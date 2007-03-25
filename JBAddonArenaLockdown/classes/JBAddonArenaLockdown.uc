// ============================================================================
// JBAddonArenaLockdown
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBAddonArenaLockdown.uc,v 1.2 2006-12-08 21:12:54 jrubzjeknf Exp $
//
// The only way to get out of jail is by winning the arena match!
// ============================================================================

class JBAddonArenaLockdown extends JBAddon config cacheexempt;


//=============================================================================
// Configuration
//=============================================================================

var config bool bCrossBaseSpawning;
var config byte SelectionMethod;


//=============================================================================
// Localization
//=============================================================================

var localized string CrossBaseSpawningText, CrossBaseSpawningDesc;
var localized string SelectionMethodText, SelectionMethodDesc;
var localized string SelectionMethodOptions;


//=============================================================================
// Variables
//=============================================================================

var() const editconst string Build;
var JBGameRulesArenaLockdown ArenaLockdownRules;


// ============================================================================
// PostBeginPlay
//
// Registers the addon's GameRules.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  ArenaLockdownRules = Spawn(Class'JBGameRulesArenaLockdown');

  if(ArenaLockdownRules != None) {
    if(Level.Game.GameRulesModifiers == None)
      Level.Game.GameRulesModifiers = ArenaLockdownRules;
    else
      Level.Game.GameRulesModifiers.AddGameRules(ArenaLockdownRules);

    ArenaLockdownRules.bCrossBaseSpawning = bCrossBaseSpawning;
    ArenaLockdownRules.SelectionMethod    = SelectionMethod;
  }
  else {
    LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesArenaLockdown !!!!!");
    Destroy();
  }
}


//=============================================================================
// FillPlayInfo
//
// Adds configurable ArenaLockdown properties to the web admin interface.
//=============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
  // add current class to stack
  PlayInfo.AddClass(default.Class);

  // now register any mutator settings
  PlayInfo.AddSetting(PlayInfoGroup(), "bCrossBaseSpawning", default.CrossBaseSpawningText, 0, 1, "Check");
  PlayInfo.AddSetting(PlayInfoGroup(), "SelectionMethod",    default.SelectionMethodText,   0, 2, "Select", default.SelectionMethodOptions);

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
    case "bCrossBaseSpawning": return default.CrossBaseSpawningDesc;
    case "SelectionMethod":    return default.SelectionMethodDesc;
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Build = "%%%%-%%-%% %%:%%"

  CrossBaseSpawningText  = "Random base spawning"
  CrossBaseSpawningDesc  = "Players can be spawned in their enemy's base, so that basecamping is discouraged."
  SelectionMethodText    = "Selection method"
  SelectionMethodDesc    = "Choose how the arena players will be picked from their jail."
  SelectionMethodOptions = "0;Queue;1;Random"

  FriendlyName = "Arena Lockdown"
  Description  = "The only way to get out of jail is by winning the arena match!"
  ConfigMenuClassName="JBAddonArenaLockdown.JBGUIPanelConfigArenaLockdown"
}
