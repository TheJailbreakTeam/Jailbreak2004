// ============================================================================
// JBDamager
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBDamager.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// Base of all damagers, special for execution.
// ============================================================================
class JBDamager extends Actor Abstract NotPlaceable;


// ============================================================================
// Variables
// ============================================================================
var Pawn Victim;
var class<DamageType> DamageType;
var float MaxDelay;
var float MinDelay;


// ============================================================================
// Damage functions
//
// Some functions for change the damage.
// ============================================================================
function int GetDamageAmount()
{
    return 1;
}

function Pawn GetDamageInstigator()
{
    return Instigator;
}

function vector GetDamageLoc()
{
    return Victim.Location;
}

function vector GetDamageMomentum()
{
    return vect(0,0,0);
}


// ============================================================================
// DamageVictim
//
// Damage the victim.
// ============================================================================
function DamageVictim()
{
    Victim.TakeDamage(GetDamageAmount(), GetDamageInstigator(), GetDamageLoc(), GetDamageMomentum(), DamageType);
}


// ============================================================================
// VictimIsAlive
//
// Return true if the victim is yet alive.
// ============================================================================
function bool VictimIsAlive()
{
    return ((Victim != None) && (Victim.Health > 0));
}


// ============================================================================
// Damager
//
// The damaging loop.
// ============================================================================
auto state Damager
{
    Begin:
    while(VictimIsAlive())
    {
        Sleep(FMax(RandRange(MinDelay, MaxDelay), 0.10));
        DamageVictim();
    }
    Destroy();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bHidden=True
    MaxDelay=1.000000
    MinDelay=0.750000
}
