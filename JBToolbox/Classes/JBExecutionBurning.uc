// ============================================================================
// JBExecutionBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBurning.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// An burning execution.
// ============================================================================
class JBExecutionBurning extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var() float BurningTime;
var HitFlameBig Flame[5];
var private name AttachFlamePart[5];
const DESTROY_FLAME_DELAY = 0.15; // 0.125001


// ============================================================================
// ExecuteJailedPlayer
//
// Execute a player.
// ============================================================================
function ExecuteJailedPlayer(Pawn Victim)
{
    local int i;

    GiveDamagerTo(Victim, class'JBDamagerBurning');

    for(i=0; i<5; i++)
    {
        Flame[i] = Spawn(class'HitFlameBig',,, Victim.Location);
        if(Flame[i] != None)
        {
            Flame[i].LifeSpan = 0;
            if(Victim.AttachToBone(Flame[i], AttachFlamePart[i]) == FALSE)
                Flame[i].Destroy();
        }
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

    f = FMax((BurningTime-DESTROY_FLAME_DELAY), 1);
    SetTimer(f, FALSE);
}


// ============================================================================
// Timer
//
// End of execution, remove flames, destroy damager, go execute player.
// ============================================================================
function Timer()
{
    DestroyAllDamager();
    GoToState('WaitAndKill');
}


// ============================================================================
// WaitAndKill
//
// Wait a little for make sure the flame effect are removed and execute player.
// Like the French expression say: On y voit que du feu :)
// ============================================================================
state WaitAndKill
{
    Begin:
    Sleep(DESTROY_FLAME_DELAY);
    ExecuteAllJailedPlayers(TRUE, class'FellLava');
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    BurningTime=3.000000
    AttachFlamePart(0)=head
    AttachFlamePart(1)=lfarm
    AttachFlamePart(2)=rfarm
    AttachFlamePart(3)=lthigh
    AttachFlamePart(4)=rthigh
}
