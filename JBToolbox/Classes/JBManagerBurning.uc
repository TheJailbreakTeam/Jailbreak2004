// ============================================================================
// JBManagerBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBManagerBurning.uc, v1.00 2003/03/03 03:04 crokx Exp $
//
// Manage the damage of burning execution.
// ============================================================================
class JBManagerBurning extends Info NotPlaceable;


// ============================================================================
// Variables
// ============================================================================
var Pawn BurningPlayer;


// ============================================================================
// PostBeginPlay
//
// Start burning damage.
// ============================================================================
function PostBeginPlay()
{
    LaunchRandomTime();
}


// ============================================================================
// LaunchRandomTime
//
// Launch the timer with a random time.
// ============================================================================
final function LaunchRandomTime()
{
    local float f;
    f = RandRange(0.375,0.625);
    SetTimer(f, FALSE);
}


// ============================================================================
// Tick
//
// If the burning player are dead before execution, remove flame effect.
// ============================================================================
function Tick(float DeltaTime)
{
    local int i;

    if(BurningPlayer == None) return;
    if(BurningPlayer.Health <= 0)
    {
        for(i=0; i<BurningPlayer.Attached.length; i++)
        {
            if(BurningPlayer.Attached[i].IsA('HitFlameBig'))
            {
                HitFlameBig(BurningPlayer.Attached[i]).mLifeRange[0] = 0;
                HitFlameBig(BurningPlayer.Attached[i]).mLifeRange[1] = 0;
                HitFlameBig(BurningPlayer.Attached[i]).mRegen = FALSE;
            }
        }

        Destroy();
    }
}


// ============================================================================
// BurningManager
//
// Instigate damage to burning player.
// ============================================================================
function Timer()
{
    local int RandomDamage;

    if(BurningPlayer == None) return;
    if(BurningPlayer.Health > 0)
    {
        RandomDamage = 2 + Rand(3);
        BurningPlayer.TakeDamage(RandomDamage, Instigator, BurningPlayer.Location, vect(0,0,0), class'Burned');
        LaunchRandomTime();
    }
}


// ============================================================================
// Destroyed
//
// Just before destroy this actor, remove all flame of burning player.
// ============================================================================
function Destroyed()
{
    local int i;

    if(BurningPlayer != None)
    {
        for(i=0; i<BurningPlayer.Attached.length; i++)
        {
            if(BurningPlayer.Attached[i].IsA('HitFlameBig'))
            {
                HitFlameBig(BurningPlayer.Attached[i]).mLifeRange[0] = 0.125;
                HitFlameBig(BurningPlayer.Attached[i]).mLifeRange[1] = 0.125;
                HitFlameBig(BurningPlayer.Attached[i]).mRegen = FALSE;
            }
        }
    }

    Super.Destroyed();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bHidden=True
}
