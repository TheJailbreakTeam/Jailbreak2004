// ============================================================================
// JBExecution
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecution.uc,v 1.4 2003/06/30 06:54:02 crokx Exp $
//
// Base of all triggered execution.
// ============================================================================
class JBExecution extends Triggers abstract;


// ============================================================================
// Variables
// ============================================================================
var private JBInfoJail TargetJail;
var private JBTagPlayer DispatchedPlayer;

struct _DispatchExecution {
    var() bool bUseDispatch;
    var() float MaxExecutionInterval;
    var() float MinExecutionInterval;
    var bool bInstantKill;
    var class<DamageType> InstantKillType; };
var() _DispatchExecution DispatchExecution;


// ============================================================================
// PostBeginPlay
//
// Seek the jail targeted.
// ============================================================================
function PostBeginPlay()
{
    local JBInfoJail Jail;

    for(Jail=GetFirstJail(); Jail!=None; Jail=Jail.NextJail)
    {
        if((Jail.EventExecutionCommit == Tag)
        || (Jail.EventExecutionEnd == Tag)
        || (Jail.EventExecutionInit == Tag))
        {
            TargetJail = Jail;
            break;
        }
    }

    if(TargetJail == None)
    {
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
        if((JailedPlayer.GetJail() == TargetJail)
        && (JailedPlayer.GetPawn() != None))
        {
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
        if((DispatchedPlayer.GetJail() == TargetJail)
        && (DispatchedPlayer.GetPawn() != None))
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
final function JBInfoJail GetTargetJail() {
    return (TargetJail); }
final function bool HasSkelete(Pawn P) {
    return ((P.IsA('xPawn')) && (xPawn(P).SkeletonMesh != None)); }


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Texture=Texture'S_SpecialEvent'
    DispatchExecution=(MaxExecutionInterval=0.750000,MinExecutionInterval=0.250000)
}
