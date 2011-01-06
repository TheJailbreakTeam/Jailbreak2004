// ============================================================================
// JBGameRulesProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesProtection.uc,v 1.13 2007-05-22 15:38:25 jrubzjeknf Exp $
//
// The rules for the protection add-on.
// ============================================================================


class JBGameRulesProtection extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var JBAddonProtection MyAddon;
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
    local JBInfoJail Jail;
    local TeamInfo Team;

    if(NewJailedPlayer.GetPlayerReplicationInfo() == MyAddon.LastRestartedPRI)
    {
        MyAddon.LastRestartedPRI = None;

        Jail = NewJailedPlayer.GetJail();
        Team = NewJailedPlayer.GetTeam();

        if(
             (Jail.IsReleaseOpening(Team))
          || (Jail.IsReleaseOpen   (Team))
          )
            GiveProtectionTo(NewJailedPlayer);
    }

    Super.NotifyPlayerJailed(NewJailedPlayer);
}


// ============================================================================
// NotifyJailOpening
//
// When a jail starts opening, give protection to jailed players.
// ============================================================================

function NotifyJailOpening(JBInfoJail Jail, TeamInfo Team)
{
    local JBTagPlayer JailedPlayer;

    for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag)
    {
        if(
             (JailedPlayer.GetJail() == Jail) // must be in this jail
          && (JailedPlayer.GetTeam() == Team) // must be of team being released
          )
            GiveProtectionTo(JailedPlayer);
    }

    Super.NotifyJailOpening(Jail, Team);
}


// ============================================================================
// NotifyPlayerReleased
//
// Called when a jailed player was escaped, start the protection delay.
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
// Called when the jail door was re-closed, remove possible protection.
// ============================================================================

function NotifyJailClosed(JBInfoJail Jail, TeamInfo Team)
{
    local JBTagPlayer ReJailedPlayer;
    local JBInfoProtection MyProtection;

    for(ReJailedPlayer=GetFirstTagPlayer(); ReJailedPlayer!=None; ReJailedPlayer=ReJailedPlayer.NextTag)
    {
        if((ReJailedPlayer.GetJail() == Jail))
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
// When a team is captured, remove all protection.
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
// When a player goes to the arena, remove his protection.
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
// The winner of the arena match is protected.
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
    if(TagPlayerWinner != None && class'JBAddonProtection'.default.bProtectArenaWinner)
        GiveProtectionTo(TagPlayerWinner, TRUE);

    Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// GiveProtectionTo
//
// Protect a player, given his JBTagPlayer.
// ============================================================================

function GiveProtectionTo(JBTagPlayer TagPlayer, optional bool bProtectNow)
{
    local JBInfoProtection MyProtection;
    local Pawn P;

    P = TagPlayer.GetPawn();

    if((P != None) && (P.Health > 0) && (!IsProtected(P)))
    {
        MyProtection = Spawn(class'JBInfoProtection', P);

        if((MyProtection != None) && (bProtectNow))
            MyProtection.StartProtectionLife();
    }
}


// ============================================================================
// IsProtected
//
// Returns True if given Pawn has protection
// ============================================================================

function bool IsProtected(Pawn thisPawn)
{
    if (thisPawn == None)
        return False;

    return GetMyProtection(thisPawn.PlayerReplicationInfo) != None;
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
// Called when a player receives damage.
// If the damaged player is protected, the damage is nullified, but the
// Protection item keeps a running total of *theoretical* damage.
// If this passes a threshold (the default full health) then the last damager
// is made a llama (not totally fair, but the way it was done in JBIII).
//
// If the attacking player is protected, he either does no damage
// or has protection removed, depending on config.
// ============================================================================

function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
  local JBInfoProtection MyProtection;

  if( Vehicle(Injured) == None && IsProtected(Injured) )
  {
    MyProtection = GetMyProtection(Injured.PlayerReplicationInfo);

    if( class'JBAddonProtection'.default.bLlamaizeCampers == True
        && InstigatedBy != None
        && InstigatedBy != Injured
        && InstigatedBy.Controller != None
        && Injured.GetTeamNum() != InstigatedBy.GetTeamNum() ) {
      if( MyProtection.KeepDamageScore(Damage, Injured) ) {
        Llamaize(InstigatedBy.Controller);
      }
    }

    HitShieldEffect(Injured);
    Momentum = vect(0,0,0);
    return 0;
  }

  if( InstigatedBy != None
    && IsProtected(InstigatedBy)
    && InstigatedBy != Injured )
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

  return super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
}


//=============================================================================
// PreventDeath
//
// Eject protected players from their destroyed vehicle.
//=============================================================================

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local bool bSuper;
    local Vehicle V;
    local int i;
    local ONSWeaponPawn ONSWP;

    bSuper = Super.PreventDeath(Killed, Killer, damageType, HitLocation);

    if (!bSuper && Vehicle(Killed) != None) {
        V = Vehicle(Killed);

        if (IsProtected(V))
            V.EjectDriver();

        if (ONSVehicle(V) != None)
            for (i = 0; i < ONSVehicle(V).WeaponPawns.Length; i++) {
                ONSWP = ONSVehicle(V).WeaponPawns[i];
                if (ONSWP != None && ONSWP.Driver != None && IsProtected(ONSWP))
                      ONSWP.EjectDriver();
            }
    }

    return bSuper;
}


//=============================================================================
// Llamaize
//
// Makes a player a Llama.
//=============================================================================

function Llamaize(Controller ControllerPlayer)
{
  local class<Actor> LlamaPendingTagClass;

  LlamaPendingTagClass = class<Actor>(DynamicLoadObject("JBAddonLlama.JBLlamaPendingTag", class'Class'));
  if ( LlamaPendingTagClass != None )
    Spawn(LlamaPendingTagClass, ControllerPlayer);
}


// ============================================================================
// CanBotAttackEnemy
//
// Called when a bot looks for a new enemy. Return false if: a) the enemy is
// protected, b) the bot is protected and protection prevents damage,
// c) the bot is protected and protection is droppable, but the bot has
// an inferior weapon.
// ============================================================================

function bool CanBotAttackEnemy(Bot Bot, Pawn PawnEnemy)
{
  if( PawnEnemy == None || PawnEnemy.Health <= 0 || Bot.Pawn == None || Bot.Pawn.Weapon == None || IsProtected(PawnEnemy) )
    return False;

  if( IsProtected(Bot.Pawn) && class'JBAddonProtection'.default.ProtectionType == 0 )
    return False;

  if( IsProtected(Bot.Pawn)
    && class'JBAddonProtection'.default.ProtectionType == 1
    && PawnEnemy.Weapon != None
    && Bot.RateWeapon(Bot.Pawn.Weapon) <= Bot.RateWeapon(PawnEnemy.Weapon) )
    return False;

  return super.CanBotAttackEnemy(Bot, PawnEnemy);
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
        if(MyProtection.RelatedPRI == PRI)
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
