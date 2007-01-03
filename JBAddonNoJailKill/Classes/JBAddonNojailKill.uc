// ============================================================================
// JBAddonNoJailKill - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// This add-on give a weapon to arena winner.
// ============================================================================


class JBAddonNoJailKill extends JBAddon cacheexempt;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
    local JBGameRulesNoJailKill NoJailKillRules;

    Super.PostBeginPlay();

    NoJailKillRules = Spawn(Class'JBGameRulesNoJailKill');
    if(NoJailKillRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = NoJailKillRules;
        else Level.Game.GameRulesModifiers.AddGameRules(NoJailKillRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesNoJailKill !!!!!");
        Destroy();
    }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Build        = "%%%%-%%-%% %%:%%"
  GroupName    = "NoJailKill"
  FriendlyName = "No Jail Kills"
  Description  = "No kills from jail: jailed players can no longer hurt enemies."
}
