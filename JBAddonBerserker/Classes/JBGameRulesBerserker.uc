// ============================================================================
// JBGameRulesBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesBerserker.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// The rules for the berserker add-on.
// ============================================================================
class JBGameRulesBerserker extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================
var private xEmitter BerserkEffect;
var private xPawn Berserker;
var private float StartArenaMatchTime;


// ============================================================================
// NotifyRound
//
// The eventual berserker don't restart with the beserk effect.
// ============================================================================
function NotifyRound()
{
    StopBerserk();

    Super.NotifyRound();
}


// ============================================================================
// NotifyArenaStart
//
// Set the current time for calculate after the berserk delay.
// ============================================================================
function NotifyArenaStart(JBInfoArena Arena)
{
    StartArenaMatchTime = Level.TimeSeconds;

    Super.NotifyArenaStart(Arena);
}


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena is the Berserker when freedom.
// ============================================================================
function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
    local int ArenaCountDown;
    local int BerserkTime;

    ArenaCountDown = int(Arena.MaxCombatTime - (Level.TimeSeconds - StartArenaMatchTime)) + 3;
    if(class'JBAddonBerserker'.default.BerserkTimeMultiplier > 0)
        ArenaCountDown = (ArenaCountDown * class'JBAddonBerserker'.default.BerserkTimeMultiplier) / 100;
    BerserkTime = Clamp(ArenaCountDown, 10, class'JBAddonBerserker'.default.MaxBerserkTime) ;

    if((TagPlayerWinner.GetController() != None)
    && (TagPlayerWinner.GetController().Pawn != None)
    && (TagPlayerWinner.GetController().Pawn.IsA('xPawn')))
    {
        Berserker = xPawn(TagPlayerWinner.GetController().Pawn);
        if(Berserker.Role == ROLE_Authority) BerserkEffect = Spawn(class'OffensiveEffect', Berserker,, Berserker.Location, Berserker.Rotation);
        if(Berserker.Weapon != None) Berserker.Weapon.StartBerserk();
        Berserker.bBerserk = TRUE;
        Berserker.ReceiveLocalizedMessage(class'JBLocalMessageBerserker', BerserkTime);
        SetTimer(BerserkTime, FALSE);
    }

    Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// Timer
//
// Wait the fight time delay and stop the berserk effect.
// ============================================================================
function Timer()
{
    StopBerserk();
}


// ============================================================================
// StopBerserk
//
// Stop the berserk effect.
// ============================================================================
function StopBerserk()
{
    local Inventory Inv;

    if(Berserker != None)
    {
        for(Inv=Berserker.Inventory; Inv!=None; Inv=Inv.Inventory)
            if((Inv != None) && (Inv.IsA('Weapon')))
                Weapon(Inv).StopBerserk();

        if((Berserker.Controller != None)
        && (Berserker.Controller.IsA('PlayerController')))
            PlayerController(Berserker.Controller).ClientFlash(0.5, vect(500,250,75));

        Berserker.bBerserk = FALSE;
        Berserker = None;
    }

    if(BerserkEffect != None) BerserkEffect.Destroy();
}


// ============================================================================
// PreventDeath
//
// If the berserker are dead, the berserk effect are stoped.
// ============================================================================
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if((Berserker != None)
    && (Berserker == Killed))
        StopBerserk();

    return ((NextGameRules != None) && (NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation)));
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
}
