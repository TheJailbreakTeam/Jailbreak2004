// ============================================================================
// JBAddonPersistence
// Copyright 2006 by Mitchell "mdavis" Davis <mitchelld02@yahoo.com>
//
// This addon will allow winning players to keep their weapons for the next
// round.
// ============================================================================

class JBAddonPersistence extends JBAddon;

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
    Log("***Failed to add JBGameRulesKeepWeapons***");
    Destroy();
  }
}

defaultproperties
{
     FriendlyName="Persistence"
     Description="The winning team will be able to keep their weapons and other attributes upon the start of a new round."
}
