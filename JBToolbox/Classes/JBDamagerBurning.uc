// ============================================================================
// JBDamagerBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBDamagerBurning.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// Damage of Burning execution.
// ============================================================================
class JBDamagerBurning extends JBDamager NotPlaceable;


// ============================================================================
// Tick
//
// If the Victim are dead before execution, remove all flames effects attached.
// ============================================================================
function Tick(float DeltaTime)
{
    local int i;

    if(Victim == None) return;
    if(Victim.Health <= 0)
    {
        for(i=0; i<Victim.Attached.length; i++)
        {
            if(Victim.Attached[i].IsA('HitFlameBig'))
            {
                HitFlameBig(Victim.Attached[i]).mLifeRange[0] = 0;
                HitFlameBig(Victim.Attached[i]).mLifeRange[1] = 0;
                HitFlameBig(Victim.Attached[i]).mRegen = FALSE;
            }
        }
    }
}

// ============================================================================
// Damage functions
//
// Some functions for change the damage.
// ============================================================================
function int GetDamageAmount()
{
    return (2+Rand(3));
}

function vector GetDamageMomentum()
{
    local vector v;

    v = VRand() * 600;
    v.Z = 0;

    return v;
}


// ============================================================================
// Destroyed
//
// Just before destroy this actor, remove all flames of victim.
// ============================================================================
function Destroyed()
{
    local int i;

    if(Victim != None)
    {
        for(i=0; i<Victim.Attached.length; i++)
        {
            if(Victim.Attached[i].IsA('HitFlameBig'))
            {
                HitFlameBig(Victim.Attached[i]).mLifeRange[0] = 0.125;
                HitFlameBig(Victim.Attached[i]).mLifeRange[1] = 0.125;
                HitFlameBig(Victim.Attached[i]).mRegen = FALSE;
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
    DamageType=class'Burned'
    MaxDelay=0.625000
    MinDelay=0.375000
}
