// ============================================================================
// JBExecutionLightning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionLightning.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
//
// An lightning execution.
// ============================================================================
class JBExecutionLightning extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var private Actor StartActor;
var() name StartLightningTag;


// ============================================================================
// PostBeginPlay
//
// Seek evantual actor start point.
// ============================================================================
function PostBeginPlay()
{
    local Actor A;

    Super.PostBeginPlay();

    if(StartLightningTag != '')
    {
        ForEach DynamicActors(class'Actor', A, StartLightningTag)
        {
            StartActor = A;
            break;
        }
    }
}


// ============================================================================
// ExecuteJailedPlayer
//
// Execute a player.
// ============================================================================
function ExecuteJailedPlayer(Pawn Victim)
{
    local Actor HitActor;
    local JBxEmitterLightning Lightning;
    local vector HitLocation, HitNormal, EndTrace, VictimLoc, StartLightningLoc;

    VictimLoc = Victim.Location + (VRand()*(Victim.CollisionRadius*0.5));
    VictimLoc.Z = Victim.Location.Z + Rand(Victim.CollisionHeight*0.3);
    if(StartActor != None) StartLightningLoc = StartActor.Location;
    else
    {
        EndTrace = VictimLoc + (vector(Rot(16384,0,0)) * 5000);
        HitActor = Trace(HitLocation, HitNormal, EndTrace, VictimLoc, true);
        if(HitActor != None) StartLightningLoc = HitLocation - (vect(0,0,1)*16);
        else StartLightningLoc = EndTrace;
    }

    Lightning = Spawn(class'JBxEmitterLightning',,, StartLightningLoc);
    if(Lightning != None)
    {
        Lightning.mSpawnVecA = VictimLoc;
        if(Level.NetMode != NM_DedicatedServer) Spawn(class'BlueSparks',,, VictimLoc, rotator(StartLightningLoc-Location));
        Victim.TakeDamage(1000, None, VictimLoc, vector(Victim.Rotation)*0.3, class'DamTypeSniperShot');
    //    Victim.Died(None, class'DamTypeSniperShot', vector(Victim.Rotation)*0.3);
    }
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
}
