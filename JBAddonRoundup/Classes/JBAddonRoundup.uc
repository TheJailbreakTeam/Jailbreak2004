// ============================================================================
// JBAddonHunt
// $Id$
// ============================================================================


class JBAddonHunt extends JBAddon;


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
    local JBGameRulesHunt HuntRules;

    Super.PostBeginPlay();

    HuntRules = Spawn(Class'JBGameRulesHunt');
    if(HuntRules != None)
    {
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = HuntRules;
        else Level.Game.GameRulesModifiers.AddGameRules(HuntRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to register the JBGameRulesHunt !!!!!");
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
    Build="2004-04-26 15:24"
    ConfigMenuClassName=""
    FriendlyName="Hunt"
    Description="One team hunt down Other team."
}
