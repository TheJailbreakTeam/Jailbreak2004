// ============================================================================
// JBAddonTeleport
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// 2003/18/11 (yyyy/dd/mm)
//
// This addon teleport a player to his base when he release his team.
// ============================================================================
class JBAddonTeleport extends JBAddon;


// ============================================================================
// PostBeginPlay
//
// Spawn and registre the additional rules.
// ============================================================================
function PostBeginPlay()
{
    local JBGameRulesTeleport TeleportRules;

    if(MutatorIsAllowed() == FALSE)
    {
        LOG("#####"@name@": addon for Jailbreak #####");
        Destroy();
        return;
    }

    Super.PostBeginPlay();

    TeleportRules = Spawn(class'JBGameRulesTeleport');
    if(TeleportRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = TeleportRules;
        else Level.Game.GameRulesModifiers.AddGameRules(TeleportRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to registre the JBGameRulesTeleport !!!!!");
        Destroy();
    }
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  Description   = "When a player releases his team, he is teleported back to his base.";
  FriendlyName  = "Teleport releaser";
}