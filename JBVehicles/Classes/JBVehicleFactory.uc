//=============================================================================
// JBVehicleFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Base class for Jailbreak vehicle factories.
//=============================================================================


class JBVehicleFactory extends SVehicleFactory
    abstract
    placeable;


//=============================================================================
// Properties
//=============================================================================

var() bool  bLockedForOpponent;
var() int   TeamNum;
var() float RespawnTime;


//=============================================================================
// Variables
//=============================================================================

var float   PreSpawnEffectTime;
var bool    bPreSpawn;
var Vehicle LastSpawned;

var class<Emitter> RedBuildEffectClass;
var class<Emitter> BlueBuildEffectClass;
var Emitter        BuildEffect;


//=============================================================================
// PostBeginPlay
//
// Precache vehicle mesh unless dedicated server.
//=============================================================================

simulated event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  if ( Level.NetMode != NM_DedicatedServer )
    VehicleClass.static.StaticPrecache(Level);
  
  if ( Level.NetMode != NM_Client )
    Timer();
}


//=============================================================================
// UpdatePrecacheMaterials
//
// Precache materials and vehicle mesh.
//=============================================================================

simulated function UpdatePrecacheMaterials()
{
  Level.AddPrecacheMaterial(Material'VMParticleTextures.buildEffects.PC_buildBorderNew');
  Level.AddPrecacheMaterial(Material'VMParticleTextures.buildEffects.PC_buildStreaks');
  VehicleClass.static.StaticPrecache(Level);
}


//=============================================================================
// VehicleDestroyed
//
// Called when a vehicle is destroyed.
//=============================================================================

event VehicleDestroyed(Vehicle V)
{
  Super.VehicleDestroyed(V);
  
  bPreSpawn = True;
  SetTimer(RespawnTime - PreSpawnEffectTime, False);
}


//=============================================================================
// SpawnVehicle
//
// Spawns a new vehicle.
//=============================================================================

function SpawnVehicle()
{
  local Pawn P;
  local bool bBlocked;
  
  foreach CollidingActors(class'Pawn', P, VehicleClass.default.CollisionRadius * 1.25) {
    bBlocked = true;
    if ( PlayerController(P.Controller) != None )
      PlayerController(P.Controller).ReceiveLocalizedMessage(class'ONSOnslaughtMessage', 11);
  }
  
  if ( bBlocked )
    SetTimer(1, false); //try again later
  else {
    LastSpawned = Spawn(VehicleClass,,, Location, Rotation);
  
    if ( LastSpawned != None ) {
      VehicleCount++;
      LastSpawned.SetTeamNum(TeamNum);
      LastSpawned.Event = Tag;
      LastSpawned.ParentFactory = Self;
      if ( !bLockedForOpponent )
        LastSpawned.bTeamLocked = False;
    }
  }
}


//=============================================================================
// SpawnBuildEffect
//
// Plays a respawn effect before the vehicle is spawned.
//=============================================================================

function SpawnBuildEffect()
{
  local rotator YawRot;
  
  YawRot = Rotation;
  YawRot.Roll = 0;
  YawRot.Pitch = 0;
  
  if ( TeamNum == 0 )
    BuildEffect = Spawn(RedBuildEffectClass,,, Location, YawRot);
  else
    BuildEffect = Spawn(BlueBuildEffectClass,,, Location, YawRot);
}


//=============================================================================
// Timer
//
// Spawns a new vehicle.
//=============================================================================

function Timer()
{
  if ( Level.Game.bAllowVehicles && VehicleCount < MaxVehicleCount ) {
    if ( bPreSpawn ) {
      bPreSpawn = False;
      SpawnBuildEffect();
      SetTimer(PreSpawnEffectTime, False);
    }
    else
      SpawnVehicle();
  }
}


//=============================================================================
// Trigger
//
// Triggering is not used.
//=============================================================================

event Trigger(Actor Other, Pawn EventInstigator);


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bLockedForOpponent=True
  RespawnTime=15.000000
  PreSpawnEffectTime=2.000000
  bPreSpawn=True
  RedBuildEffectClass=Class'Onslaught.ONSVehicleBuildEffect'
  BlueBuildEffectClass=Class'Onslaught.ONSVehicleBuildEffect'
  DrawType=DT_Mesh
}
