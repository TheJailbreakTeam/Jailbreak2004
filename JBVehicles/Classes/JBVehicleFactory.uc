//=============================================================================
// JBVehicleFactory
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBVehicleFactory.uc,v 1.2 2004/06/03 00:07:01 wormbo Exp $
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
var() bool  bInitiallyActive;
var() int   TeamNum;
var() float RespawnTime;
var() name  EventVehicleDestroyed;


//=============================================================================
// Variables
//=============================================================================

var float   PreSpawnEffectTime;
var bool    bPreSpawn;
var bool    bResetting;
var array<Vehicle> LastSpawned;

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
  
  if ( Level.NetMode != NM_Client && bInitiallyActive )
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
  local int i;
  
  Super.VehicleDestroyed(V);
  
  for (i = 0; i < LastSpawned.Length; i++)
    if ( LastSpawned[i] == V ) {
      LastSpawned.Remove(i, 1);
      break;
    }
  
  if ( !bResetting ) {
    bPreSpawn = True;
    if ( RespawnTime > 0 ) {
      if ( RespawnTime - PreSpawnEffectTime > 0 )
        SetTimer(RespawnTime - PreSpawnEffectTime, False);
      else
        Timer();
    }
  }
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
    LastSpawned[LastSpawned.Length] = Spawn(VehicleClass,,, Location, Rotation);
  
    if ( LastSpawned[LastSpawned.Length - 1] != None ) {
      VehicleCount++;
      LastSpawned[LastSpawned.Length - 1].SetTeamNum(TeamNum);
      LastSpawned[LastSpawned.Length - 1].Event = EventVehicleDestroyed;
      LastSpawned[LastSpawned.Length - 1].ParentFactory = Self;
      if ( !bLockedForOpponent )
        LastSpawned[LastSpawned.Length - 1].bTeamLocked = False;
    }
    else
      LastSpawned.Remove(LastSpawned.Length - 1, 1);
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

event Trigger(Actor Other, Pawn EventInstigator)
{
  if ( bPreSpawn )
    Timer();
}


//=============================================================================
// Reset
//
// Resets the vehicle factory and all currently unused vehicles spawned by it.
//=============================================================================

function Reset()
{
  local int i;
  
  bResetting = true;
  for (i = LastSpawned.Length - 1; i >= 0; i--)
    if ( LastSpawned[i] != None ) {
      if ( LastSpawned[i].Driver == None )
        LastSpawned[i].Destroy();
      else
        LastSpawned[i].ParentFactory = None;
    }
  
  VehicleCount = 0;
  bResetting = false;
  
  // respawn a vehicle if the factory is set to be initially active
  if ( bInitiallyActive )
    Timer();
}

//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bLockedForOpponent=True
  bInitiallyActive=True
  RespawnTime=15.000000
  PreSpawnEffectTime=2.000000
  bPreSpawn=True
  RedBuildEffectClass=Class'Onslaught.ONSVehicleBuildEffect'
  BlueBuildEffectClass=Class'Onslaught.ONSVehicleBuildEffect'
  DrawType=DT_Mesh
}
