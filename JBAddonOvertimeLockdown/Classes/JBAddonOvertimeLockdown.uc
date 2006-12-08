// ============================================================================
// JBAddonOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $id$
//
// When in overtime starts, the releases will be jammed. Once you're jailed,
// there's no getting out any more. Last chance to score a point!
// ============================================================================


class JBAddonOvertimeLockdown extends JBAddon config cacheexempt;


//=============================================================================
// Configuration
//=============================================================================

var config bool bNoArenaInOvertime;
var config bool bNoEscapeInOvertime;
var config byte RestartPlayers; // 0=dont, 1=free, 2=everybody
var config byte LockdownDelay;  // in minutes


//=============================================================================
// Localization
//=============================================================================

var localized string NoArenaInOvertimeText, NoArenaInOvertimeDesc;
var localized string NoEscapeInOvertimeText, NoEscapeInOvertimeDesc;
var localized string RestartPlayersText, RestartPlayersDesc;
var localized string RestartPlayersOptions;
var localized string LockdownDelayText, LockdownDelayDesc;


//=============================================================================
// Variables
//=============================================================================

var() const editconst string Build;
var JBGameRulesOvertimeLockdown OvertimeLockdownRules;


// ============================================================================
// PostBeginPlay
//
// Registers the addon's GameRules.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  OvertimeLockdownRules = Spawn(Class'JBGameRulesOvertimeLockdown');

  if(OvertimeLockdownRules != None) {
    if(Level.Game.GameRulesModifiers == None)
      Level.Game.GameRulesModifiers = OvertimeLockdownRules;
    else
      Level.Game.GameRulesModifiers.AddGameRules(OvertimeLockdownRules);

    // Copy variables to Gamerules.
    OvertimeLockdownRules.bNoArenaInOvertime  = bNoArenaInOvertime;
    OvertimeLockdownRules.bNoEscapeInOvertime = bNoEscapeInOvertime;
    OvertimeLockdownRules.RestartPlayers      = RestartPlayers;
    OvertimeLockdownRules.LockdownDelay       = LockdownDelay;
  }
  else {
    LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesOvertimeLockdown !!!!!");
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
  PlayInfo.AddSetting(PlayInfoGroup(), "bNoArenaInOvertime",  default.NoArenaInOvertimeText,  0, 1, "Check");
  PlayInfo.AddSetting(PlayInfoGroup(), "bNoEscapeInOvertime", default.NoEscapeInOvertimeText, 0, 2, "Check");
  PlayInfo.AddSetting(PlayInfoGroup(), "RestartPlayers",      default.RestartPlayersText,     0, 3, "Select", default.RestartPlayersOptions);
  PlayInfo.AddSetting(PlayInfoGroup(), "LockdownDelay",       default.LockdownDelayText,      0, 4, "Text", "3;0:150");

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
  switch (PropName) {
    case "bNoArenaInOvertime":  return default.NoArenaInOvertimeDesc;
    case "bNoEscapeInOvertime": return default.NoEscapeInOvertimeDesc;
    case "RestartPlayers":      return default.RestartPlayersDesc;
    case "LockdownDelay":       return default.LockdownDelayDesc;
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  NoArenaInOvertimeText  = "No arena matches in Overtime"
  NoArenaInOvertimeDesc  = "No arena matches will start when the game goes into overtime. Pending matches will be cancelled."
  NoEscapeInOvertimeText = "No escapes in Overtime"
  NoEscapeInOvertimeDesc = "Players who try to get out of jail during the Lockdown, will be killed."
  RestartPlayersText     = "Restart players in Overtime"
  RestartPlayersDesc     = "Restart all, free or no players when the game goes into overtime."
  RestartPlayersOptions  = "0;No-one;1;Free players;2;All players"
  LockdownDelayText      = "Lockdown delay"
  LockdownDelayDesc      = "How long normal overtime should last before before the lockdown kicks in."

  bNoArenaInOvertime  = True
  bNoEscapeInOvertime = True
  RestartPlayers      = 1
  LockdownDelay       = 3

  Build = "%%%%-%%-%% %%:%%";
  FriendlyName = "Overtime Lockdown"
  Description = "If the match goes into overtime, the release switches can become jammed and nobody can be released any more. Last chance to win the game!"
  ConfigMenuClassName = "JBAddonOvertimeLockdown.JBGUIPanelConfigOvertimeLockdown"
}
