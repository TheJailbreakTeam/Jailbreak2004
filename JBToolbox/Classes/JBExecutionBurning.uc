// ============================================================================
// JBExecutionBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBurning.uc, v1.00 2003/03/03 04:23 crokx Exp $
//
// An burning execution.
// ============================================================================
class JBExecutionBurning extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var() float BurningTime;
var HitFlameBig Flame[5];
var JBTagPlayer JailedPlayer;
const DESTROY_FLAME_DELAY = 0.15; // 0.125001


// ============================================================================
// ExecutePlayer
//
// Execute a player.
// ============================================================================
private function ExecutePlayer(Controller Victim)
{
    local JBManagerBurning Manager;

    Manager = Spawn(class'JBManagerBurning');
    if(Manager != None) Manager.BurningPlayer = Victim.Pawn;

    // head flame
    Flame[0] = Spawn(class'HitFlameBig',,, Victim.Pawn.Location);
    if(Flame[0] != None)
    {
        Flame[0].LifeSpan = 0;
        if(Victim.Pawn.AttachToBone(Flame[0],'head') == FALSE)
            Flame[0].Destroy();
    }

    // left up flame
    Flame[1] = Spawn(class'HitFlameBig',,, Victim.Pawn.Location);
    if(Flame[1] != None)
    {
        Flame[1].LifeSpan = 0;
        if(Victim.Pawn.AttachToBone(Flame[1],'lfarm') == FALSE)
            Flame[1].Destroy();
    }

    // right up flame
    Flame[2] = Spawn(class'HitFlameBig',,, Victim.Pawn.Location);
    if(Flame[2] != None)
    {
        Flame[2].LifeSpan = 0;
        if(Victim.Pawn.AttachToBone(Flame[2],'rfarm') == FALSE)
            Flame[2].Destroy();
    }

    // left down flame
    Flame[3] = Spawn(class'HitFlameBig',,, Victim.Pawn.Location);
    if(Flame[3] != None)
    {
        Flame[3].LifeSpan = 0;
        if(Victim.Pawn.AttachToBone(Flame[3],'lthigh') == FALSE)
            Flame[3].Destroy();
    }

    // right down flame
    Flame[4] = Spawn(class'HitFlameBig',,, Victim.Pawn.Location);
    if(Flame[4] != None)
    {
        Flame[4].LifeSpan = 0;
        if(Victim.Pawn.AttachToBone(Flame[4],'rthigh') == FALSE)
            Flame[4].Destroy();
    }
}


// ============================================================================
// Trigger
//
// Start execution time.
// ============================================================================
function Trigger(Actor A, Pawn P)
{
    local float f;

    Super.Trigger(A, P);

    if((BurningTime - DESTROY_FLAME_DELAY) < 1) f = 1.0;
    else f = BurningTime - DESTROY_FLAME_DELAY;
    SetTimer(f, FALSE);
}


// ============================================================================
// Timer
//
// End of execution, remove flame, destroy manager, go execute player.
// ============================================================================
function Timer()
{
    local JBManagerBurning Manager;

    foreach DynamicActors(class'JBManagerBurning', Manager)
        if(Manager != None) Manager.Destroy();

    GoToState('FinalExecution');
}


// ============================================================================
// FinalExecution
//
// Wait a little for make sure the flame effect are removed and execute player.
// Like the French expression say: On y voit que du feu ;)
// ============================================================================
state FinalExecution
{
    Begin:
    Sleep(DESTROY_FLAME_DELAY);
    foreach DynamicActors(class'JBTagPlayer', JailedPlayer)
        if(JailedPlayer != None)
            if(JailedPlayer.GetController() != None)
                if(JailedPlayer.GetController().Pawn != None)
                    if(JailedPlayer.GetJail() == TargetedJail)
                        JailedPlayer.GetController().Pawn.Died(None, class'FellLava', vect(0,0,0));
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    BurningTime=3
}
