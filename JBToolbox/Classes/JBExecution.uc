// ============================================================================
// JBExecution
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecution.uc,v 1.2 2003/03/15 23:41:31 mychaeel Exp $
//
// Base of all triggered execution.
// ============================================================================
class JBExecution extends Triggers abstract;


// ============================================================================
// Variables
// ============================================================================
var private JBInfoJail TargetJail;


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
        if(Jail != None)
        {
            if((Jail.EventExecutionCommit == Tag)
            || (Jail.EventExecutionEnd == Tag)
            || (Jail.EventExecutionInit == Tag))
            {
                TargetJail = Jail;
                break;
            }
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
    local Controller JailedController;

    for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag)
    {
        if((JailedPlayer != None)
        && (JailedPlayer.GetJail() == TargetJail))
        {
            JailedController = JailedPlayer.GetController();
            if((JailedController != None)
            && (JailedController.Pawn != None))
            {
                if(bInstantKill) JailedController.Pawn.Died(None, KillType, vect(0,0,0));
                else ExecuteJailedPlayer(JailedController.Pawn);
            }
        }
    }
}


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================
function Trigger(Actor A, Pawn P)
{
    ExecuteAllJailedPlayers();
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
// DestroyAllDamager
//
// Destroy all damager.
// ============================================================================
final function DestroyAllDamager()
{
    local JBDamager Damager;

    foreach DynamicActors(class'JBDamager', Damager)
        if(Damager != None)
            Damager.Destroy();
}


// ============================================================================
// Accessors
// ============================================================================
simulated final function JBInfoJail GetFirstJail() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstJail); }
simulated final function JBTagPlayer GetFirstTagPlayer() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstTagPlayer); }
simulated final function JBInfoJail GetTargetJail() {
    return (TargetJail); }
final function bool HasSkelete(Pawn P) {
    return ((P.IsA('xPawn')) && (xPawn(P).SkeletonMesh != None)); }


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Texture=Texture'S_SpecialEvent'
}
