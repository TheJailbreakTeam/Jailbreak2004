// ============================================================================
// JBAddonTeleport
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonTeleport.uc,v 1.2 2004/04/23 08:59:01 mychaeel Exp $
//
// This addon teleport a player to his base when he release his team.
// ============================================================================


class JBAddonTeleport extends JBAddon;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;


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
  Build = "%%%%-%%-%% %%:%%";

  Description   = "When a player releases his team, the releaser is teleported back to his or her base.";
  FriendlyName  = "Teleport Releaser";
}