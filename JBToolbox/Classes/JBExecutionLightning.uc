// ============================================================================
// JBExecutionLightning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionLightning.uc,v 1.2 2003/07/26 05:58:36 crokx Exp $
//
// An lightning execution.
// ============================================================================


class JBExecutionLightning extends JBExecution;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBExecutionLightning.pcx mips=off masked=on group=icons


// ============================================================================
// Variables
// ============================================================================
var() enum _StartLightningPoint
    { SLP_Here, SLP_Heaven, SLP_RandomTag } StartLightningPoint;

const NUM_RANDOM_TAG = 16;
var() name RandomTag[NUM_RANDOM_TAG];
var private int NumTagUse;
var private vector RandomTagLoc[NUM_RANDOM_TAG];


// ============================================================================
// PostBeginPlay
//
// Seek tagged actors for mode SLP_RandomTag.
// ============================================================================
function PostBeginPlay()
{
    local Actor A;
    local int i;

    Super.PostBeginPlay();

    if(StartLightningPoint != SLP_RandomTag) return;

    for(i=0; i<NUM_RANDOM_TAG; i++)
    {
        if(RandomTag[i] == '')
        {
            NumTagUse = i;
            break;
        }
    }

    if(NumTagUse < 1)
    {
        LOG("!!!!!"@name$".PostBeginPlay() : No enough RandomTag for use mode SLP_RandomTag !!!!!");
        StartLightningPoint = SLP_Here;
    }
    else
    {
        for(i=0; i<NumTagUse; i++)
        {
            foreach DynamicActors(class'Actor', A, RandomTag[i])
            {
                RandomTagLoc[i] = A.Location;
                break;
            }
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

  VictimLoc = Victim.Location + (VRand()*(Victim.CollisionRadius*0.8));
  VictimLoc.Z = Victim.Location.Z + Rand(Victim.CollisionHeight*0.4);

  switch(StartLightningPoint) {
    case SLP_Here:
    StartLightningLoc = Location;
    break;

    case SLP_Heaven:
    EndTrace = VictimLoc + (vector(Rot(16384,0,0)) * 5000);
    HitActor = Trace(HitLocation, HitNormal, EndTrace, VictimLoc, true);
    if(HitActor != None) StartLightningLoc = HitLocation - (vect(0,0,1)*16);
    else StartLightningLoc = EndTrace;
    break;

    case SLP_RandomTag:
    StartLightningLoc = RandomTagLoc[Rand(NumTagUse)];
    break;
  }

  Lightning = Spawn(class'JBxEmitterLightning',,, StartLightningLoc);
  if(Lightning != None) {
    Lightning.mSpawnVecA = VictimLoc;
    if(Level.NetMode != NM_DedicatedServer)
        Spawn(class'BlueSparks',,, VictimLoc, rotator(Victim.Location-StartLightningLoc));
    if((Victim.Controller != None) && (Victim.Controller.bGodMode))
        Victim.Died(None, class'DamTypeSniperShot', vector(Victim.Rotation)*0.3); // make sure to kill stupid player
    else Victim.TakeDamage(1000, None, VictimLoc, vector(Victim.Rotation)*0.3, class'DamTypeSniperShot');
  }
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
  Texture = Texture'JBToolbox.icons.JBExecutionLightning';  
}
