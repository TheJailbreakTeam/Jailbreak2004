// ============================================================================
// JBExecution
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecution.uc, v1.00 2003/03/01 ??:?? crokx Exp $
//
// Base of all triggered execution.
// ============================================================================
class JBExecution extends Triggers abstract;


// ============================================================================
// Variables
// ============================================================================
var JBInfoJail TargetedJail;


// ============================================================================
// PostBeginPlay
//
// Seek the jail targeted.
// ============================================================================
function PostBeginPlay()
{
    local JBInfoJail Jail;

    foreach DynamicActors(class'JBInfoJail', Jail)
    {
        if(Jail != None)
        {
            if((Jail.EventExecutionCommit == Tag)
            || (Jail.EventExecutionEnd == Tag)
            || (Jail.EventExecutionInit == Tag))
            {
                TargetedJail = Jail;
                break;
            }
        }
    }

    if(TargetedJail == None)
    {
        LOG("#####"@name@": targeted jail not found #####");
        Disable('Trigger');
    }
}


// ============================================================================
// ExecutePlayer (implemented in sub-class)
//
// Execute a player.
// ============================================================================
private function ExecutePlayer(Controller Victim);


// ============================================================================
// SeekJailedPlayerForExecution
//
// Seek all players jailed in the targeted jail and execute this players.
// ============================================================================
event SeekJailedPlayerForExecution()
{
    local JBTagPlayer JailedPlayer;

    foreach DynamicActors(class'JBTagPlayer', JailedPlayer)
        if(JailedPlayer != None)
            if(JailedPlayer.GetController() != None)
                if(JailedPlayer.GetController().Pawn != None)
                    if(JailedPlayer.GetJail() == TargetedJail)
                        ExecutePlayer(JailedPlayer.GetController());
}


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================
function Trigger(Actor A, Pawn P)
{
    SeekJailedPlayerForExecution();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Texture=Texture'S_SpecialEvent'
}
