// ============================================================================
// JBGameRulesProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesProtection.uc,v 1.2 2004/01/15 07:25:40 crokx Exp $
//
// The rules for the protection add-on.
// ============================================================================


class JBGameRulesProtection extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var JBAddonProtection MyAddon;
//var private JBInfoProtection MyProtection;
var private Shader RedHitEffect, BlueHitEffect;
var private sound ProtectionHitSound;


// ============================================================================
// NotifyPlayerJailed
//
// give protection to a newly-jailed player, if the jail is in the process of 
// releasing his team
// ============================================================================

function NotifyPlayerJailed(JBTagPlayer NewJailedPlayer)
{
    if(NewJailedPlayer.GetPlayerReplicationInfo() == MyAddon.LastRestartedPRI)
    {
        MyAddon.LastRestartedPRI = None;

        if(NewJailedPlayer.GetJail().IsReleaseActive(NewJailedPlayer.GetTeam()))
            GiveProtectionTo(NewJailedPlayer, TRUE);
    }

    Super.NotifyPlayerJailed(NewJailedPlayer);
}


// ============================================================================
// NotifyJailOpening
//
// Called when a jail starts the opening, give protection to jailed players.
// ============================================================================

function NotifyJailOpening(JBInfoJail Jail, TeamInfo Team)
{
    local JBTagPlayer JailedPlayer;

    for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag)
    {
        if(
          (JailedPlayer != None) // might find no jailed players at all
          && (JailedPlayer.GetJail() == Jail) // must be in this jail
          && (JailedPlayer.GetTeam() == Team) // must be of team being released
          )
            GiveProtectionTo(JailedPlayer);
    }

    Super.NotifyJailOpening(Jail, Team);
}


// ============================================================================
// NotifyPlayerReleased
//
// Called when a jailled player was escaped, start the protection delay.
// ============================================================================
function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail)
{
    local JBInfoProtection MyProtection;

    MyProtection = GetMyProtection(TagPlayer.GetPlayerReplicationInfo());
    if(MyProtection != None) MyProtection.StartProtectionLife();

    Super.NotifyPlayerReleased(TagPlayer, Jail);
}


// ============================================================================
// NotifyJailClosed
//
// Called when the jail door was re-closed, remove evantual protection.
// ============================================================================
function NotifyJailClosed(JBInfoJail Jail, TeamInfo Team)
{
    local JBTagPlayer ReJailedPlayer;
    local JBInfoProtection MyProtection;

    for(ReJailedPlayer=GetFirstTagPlayer(); ReJailedPlayer!=None; ReJailedPlayer=ReJailedPlayer.NextTag)
    {
        if((ReJailedPlayer != None) // is not obligate to found re-jailed player
        && (ReJailedPlayer.GetJail() == Jail))
        {
            MyProtection = GetMyProtection(ReJailedPlayer.GetPlayerReplicationInfo());
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    Super.NotifyJailClosed(Jail, Team);
}


// ============================================================================
// NotifyExecutionCommit
//
// When a team are captured, remove all evantual protection.
// ============================================================================
function NotifyExecutionCommit(TeamInfo Team)
{
    local JBInfoProtection MyProtection;

    foreach DynamicActors(class'JBInfoProtection', MyProtection)
        if(MyProtection != None)
            MyProtection.Destroy();

    Super.NotifyExecutionCommit(Team);
}


// ============================================================================
// NotifyArenaStart
//
// When a player go fight in arena, this player lost his evantual protection.
// ============================================================================
function NotifyArenaStart(JBInfoArena Arena)
{
    local JBTagPlayer Fighter;
    local JBInfoProtection MyProtection;

    for(Fighter=GetFirstTagPlayer(); Fighter!=None; Fighter=Fighter.NextTag)
    {
        if(Fighter.GetArena() == Arena)
        {
            MyProtection = GetMyProtection(Fighter.GetPlayerReplicationInfo());
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    Super.NotifyArenaStart(Arena);
}


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena was protected.
// ============================================================================
function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
    if(class'JBAddonProtection'.default.bProtectArenaWinner)
        GiveProtectionTo(TagPlayerWinner, TRUE);

    Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// GiveProtectionTo
//
// Protect a player from his JBTagPlayer.
// ============================================================================
function GiveProtectionTo(JBTagPlayer TagPlayer, optional bool bProtectNow)
{
    local JBInfoProtection MyProtection;
    local Pawn P;

    P = TagPlayer.GetController().Pawn; // for make sure no GetPawn() here
    if((P != None) && (P.Health > 0) && (P.ReducedDamageType == None))
    {
        MyProtection = Spawn(class'JBInfoProtection', P);
        if((MyProtection != None) && (bProtectNow))
            MyProtection.StartProtectionLife();
    }
}


// ============================================================================
// HitShieldEffect
//
// Make a shield effect for see the damage absorption.
// ============================================================================
function HitShieldEffect(Pawn ProtectedPawn)
{
    local xPawn xProtectedPawn;

    xProtectedPawn = xPawn(ProtectedPawn);
    if(xProtectedPawn != None)
    {
        xProtectedPawn.PlaySound(ProtectionHitSound, SLOT_Pain, TransientSoundVolume*2,, 400);

        if(xProtectedPawn.PlayerReplicationInfo.Team.TeamIndex == 0)
            xProtectedPawn.SetOverlayMaterial(RedHitEffect, xProtectedPawn.ShieldHitMatTime, FALSE);
        else
            xProtectedPawn.SetOverlayMaterial(BlueHitEffect, xProtectedPawn.ShieldHitMatTime, FALSE);
    }
}


// ============================================================================
// NetDamage
//
// Called when a player receive damage.
// ============================================================================
function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    local JBInfoProtection MyProtection;

    if(Injured.ReducedDamageType == class'JBDamageTypeNone')
    {
        HitShieldEffect(Injured);
        Momentum = vect(0,0,0);
        return 0;
    }

    if((InstigatedBy != None)
    && (InstigatedBy.ReducedDamageType == class'JBDamageTypeNone')
    && (InstigatedBy != Injured))
    {
        if(class'JBAddonProtection'.default.ProtectionType == 0)
        {
            Momentum = vect(0,0,0);
            return 0;
        }
        else if(class'JBAddonProtection'.default.ProtectionType == 1)
        {
            MyProtection = GetMyProtection(InstigatedBy.PlayerReplicationInfo);
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    if(NextGameRules != None)
        return NextGameRules.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
}


// ============================================================================
// Accessors
// ============================================================================
final function JBTagPlayer GetFirstTagPlayer() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstTagPlayer); }

final function JBInfoProtection GetMyProtection(PlayerReplicationInfo PRI)
{
    local JBInfoProtection MyProtection;

    foreach DynamicActors(class'JBInfoProtection', MyProtection)
        if((MyProtection != None) && (MyProtection.RelatedPRI == PRI))
            return MyProtection;

    return None;
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    RedHitEffect=Shader'XGameShaders.PlayerShaders.PlayerTransRed'
    BlueHitEffect=Shader'XGameShaders.PlayerShaders.PlayerTrans'
    ProtectionHitSound=Sound'WeaponSounds.BaseImpactAndExplosions.bShieldReflection'
}
