// ============================================================================
// JBAddonPersistence
// Copyright 2006 by Mitchell "mdavis" Davis <mitchelld02@yahoo.com>
//
// This addon will allow winning players to keep their weapons for the next
// round.
// ============================================================================

class JBAddonPersistence extends JBAddon
      CacheExempt;

// ============================================================================
// Variables
// ============================================================================
var() config bool bUprising;
var() config int nHealth;

//=============================================================================
// Localization
//=============================================================================
var localized string UprisingText, UprisingDesc;
var localized string HealthTransferText, HealthTransferDesc;

// ============================================================================
// PostBeginPlay
//
// Register the new rules to the current map.
// ============================================================================
function PostBeginPlay()
{
  local JBGameRulesPersistence PersistentRules;

  Super.PostBeginPlay();

  PersistentRules = Spawn(class'JBGameRulesPersistence');
  if(PersistentRules != None)
  {
    if(Level.Game.GameRulesModifiers == None)
      Level.Game.GameRulesModifiers = PersistentRules;
    else Level.Game.AddGameModifier(PersistentRules);
  }
  else
  {
    Log("***Failed to add JBGameRulesPersistence***");
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
  //add current class to stack
  PlayInfo.AddClass(default.Class);

  //now register any mutator settings
  PlayInfo.AddSetting(PlayInfoGroup(), "bUprising", default.UprisingText, 0, 0, "Text", "3;1:200");
  PlayInfo.AddSetting(PlayInfoGroup(), "nHealth", default.HealthTransferText, 0, 0, "Text", "3;1:200");

  //remove mutator class from class stack
  PlayInfo.PopClass();
}

//=============================================================================
// GetDescriptionText
//
// Returns a description text for the specified property.
//=============================================================================
static event string GetDescriptionText(string PropName)
{
  switch(PropName)
  {
    case "bUprising": return default.UprisingDesc;
    case "nHealth": return default.HealthTransferDesc;
  }
}

defaultproperties
{
  ConfigMenuClassName="JBAddonPersistence.JBGUIPanelConfigPersistence"

  bUprising = false;
  UprisingText="The Uprising"
  UprisingDesc="Giving capturing players' weapons to the captured."

  nHealth = 0;
  HealthTransferText="Health Transfer"
  HealthTransferDesc="Give a percentage of health from the capturing players to the captured players."

  FriendlyName="Persistence"
  Description="The winning team will be able to keep their weapons and other attributes upon the start of a new round."
}
