// ============================================================================
// JBAddonRoundup
// Copyright 2004 by EagleAR
// $Id: JBAddonRoundup.uc,v 1.3 2004/05/31 19:29:02 tarquin Exp $
//
//
// ============================================================================


class JBAddonRoundup extends JBAddon;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
//var int RoundTime;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
    local JBGameRulesRoundup RoundupRules;

    Super.PostBeginPlay();

    RoundupRules = Spawn(Class'JBGameRulesRoundup');
    if(RoundupRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = RoundupRules;
        else Level.Game.GameRulesModifiers.AddGameRules(RoundupRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesRoundup !!!!!");
        Destroy();
    }
}

/*
function CheckRounds()
{
  if ( JailBreak(Level.Game) != None )
    JailBreak(Level.Game).RestartAll();
}
*/


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
    Build="%%%%-%%-%% %%:%%"
    ConfigMenuClassName=""
    FriendlyName="Roundup"
    Description="One team hunts down the other team."
}
