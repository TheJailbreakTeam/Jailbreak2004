// ============================================================================
// JBExecution
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecution.uc,v 1.5 2003/07/26 05:55:18 crokx Exp $
//
// Base of all triggered execution.
// ============================================================================


class JBExecution extends Triggers abstract;


// ============================================================================
// Variables
// ============================================================================

var private JBTagPlayer DispatchedPlayer;
var private array<JBInfoJail> AttachedJails;

struct _DispatchExecution {
    var() bool bUseDispatch;
    var() float MaxExecutionInterval;
    var() float MinExecutionInterval;
    var bool bInstantKill;
    var class<DamageType> InstantKillType; };
var() _DispatchExecution DispatchExecution;
var() name TagAttachJail; // tag to match to one or more Jails
                          // if 'Auto' use value of the Tag property


// ============================================================================
// PostBeginPlay
//
// Seek JBInfoJails that target this actor (with their EventExecutionCommit) 
// TagAttachJail is used, unless it is 'Auto', in which case Tag is used.
// If no jails are found, attach to the jail this actor is in. 
// If this actor is not in a jail, log an error and go to sleep.
// ============================================================================

function PostBeginPlay()
{
    local JBInfoJail Jail;
    local name MatchTag;
    
    if(TagAttachJail == 'Auto')
      MatchTag = Tag;
    else
      MatchTag = TagAttachJail;
    
    if(MatchTag != '' ) {
        for(Jail=GetFirstJail(); Jail!=None; Jail=Jail.NextJail) {
            if((Jail.EventExecutionCommit == MatchTag)
            || (Jail.EventExecutionEnd == MatchTag)
            || (Jail.EventExecutionInit == MatchTag))
            {
                AttachedJails[AttachedJails.length] = Jail;
            }
        }
    }
    
    if(AttachedJails.length == 0 ) {
        for(Jail=GetFirstJail(); Jail!=None; Jail=Jail.NextJail)
        {
            if( Jail.ContainsActor(Self) ) {
                AttachedJails[0] = Jail;
                break;
            }
        }
    }
    if(AttachedJails.length == 0 ) {
        LOG("!!!!!"@name$".PostBeginPlay() : target jail not found !!!!!");
        Disable('Trigger');
    }
}


// ============================================================================
// ExecuteJailedPlayer (implemented in sub-class)
//
// Execute a player.
// ============================================================================
function ExecuteJailedPlayer(Pawn Victim);


// ============================================================================
// ExecuteAllJailedPlayers
//
// Seek all jailed players in the target jail and execute this players.
// Possible to kill this players now.
// ============================================================================
event ExecuteAllJailedPlayers(optional bool bInstantKill, optional class<DamageType> KillType)
{
    local JBTagPlayer JailedPlayer;

    Disable('Trigger');

    for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag)
    {
        if( PlayerIsInAttachedJail(JailedPlayer) && (JailedPlayer.GetPawn() != None)) {
            if(bInstantKill) JailedPlayer.GetPawn().Died(None, KillType, vect(0,0,0));
            else ExecuteJailedPlayer(JailedPlayer.GetPawn());
        }
    }

    Enable('Trigger');
}

// ============================================================================
// ExecutionDispatching
//
// Dispatch the execution.
// ============================================================================
state ExecutionDispatching
{
    ignores Trigger;

    Begin:
    for(DispatchedPlayer=GetFirstTagPlayer(); DispatchedPlayer!=None; DispatchedPlayer=DispatchedPlayer.NextTag)
    {
        if( PlayerIsInAttachedJail(DispatchedPlayer) && (DispatchedPlayer.GetPawn() != None))
        {
            if(DispatchExecution.bInstantKill) DispatchedPlayer.GetPawn().Died(None, DispatchExecution.InstantKillType, vect(0,0,0));
            else ExecuteJailedPlayer(DispatchedPlayer.GetPawn());
            Sleep(FMax(RandRange(DispatchExecution.MinExecutionInterval, DispatchExecution.MaxExecutionInterval), 0.10));
        }
    }

    GoToState('');
}


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================
function Trigger(Actor A, Pawn P)
{
    if(DispatchExecution.bUseDispatch) GoToState('ExecutionDispatching');
    else ExecuteAllJailedPlayers();
}


// ============================================================================
// GiveDamagerTo
//
// Give damager to a player.
// ============================================================================
final function GiveDamagerTo(Pawn Victim, class<JBDamager> DamagerType)
{
    local JBDamager Damager;

    Damager = Spawn(DamagerType);
    if(Damager != None) Damager.Victim = Victim;
}


// ============================================================================
// DestroyAllDamagers
//
// Destroy all damagers.
// ============================================================================
final function DestroyAllDamagers()
{
    local JBDamager Damager;

    foreach DynamicActors(class'JBDamager', Damager)
        if(Damager != None)
            Damager.Destroy();
}


// ============================================================================
// Accessors
// ============================================================================

final function JBInfoJail GetFirstJail() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstJail); }
final function JBTagPlayer GetFirstTagPlayer() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstTagPlayer); }
final function bool HasSkelete(Pawn P) {
    return ((P.IsA('xPawn')) && (xPawn(P).SkeletonMesh != None)); }
final function JBInfoJail GetTargetJail()
{
    // THIS FUNCTION IS DEPRECATED! 
    // code must be adapted to use PlayerIsInAttachedJail instead
    log("!!!!!"@name$": function GetTargetJail() is deprecated! Do not use!");
    return (AttachedJails[0]);
}

final function bool PlayerIsInAttachedJail(JBTagPlayer Player)
{
    local int i;
    for( i=0; i<AttachedJails.length; i++) {
        if(Player.GetJail() == AttachedJails[i] ) {
            return true;
        }
    }
    return false; 
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Texture=Texture'S_SpecialEvent'
    DispatchExecution=(MaxExecutionInterval=0.750000,MinExecutionInterval=0.250000)
    TagAttachJail=Auto
}
