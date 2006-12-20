// ============================================================================
// JBSentinelCeilingFactory
// Copyright 2004 by Blitz
// $Id: JBSentinelCeilingFactory.uc,v 1.1 2006-12-16 19:39:37 jrubzjeknf Exp $
//
// The factory that produces the sentinel hanging from the ceiling.
// ============================================================================


class JBSentinelCeilingFactory extends ASVehicleFactory_SentinelCeiling
  placeable;


// ============================================================================
// Properties
// ============================================================================

var() bool bSleepWhenDisabled;
var() class<Projectile> ProjectileClass;
var() vector ProjectileSpawnOffset;
var() float FireRate;
var() Sound FireSound;
var() cache class<InventoryAttachment> AttachmentClass;
var() class<xEmitter> FlashEmitterClass;
var() class<xEmitter> SmokeEmitterClass;


// ============================================================================
// PostBeginPlay
//
// Delays spawning the Sentinel.
// ============================================================================

simulated function PostBeginPlay()
{
  Super.PostBeginPlay();

  if (Role == Role_Authority && !bEnabled &&
      bSleepWhenDisabled && TriggeredFunction != EAVSF_TriggeredSpawn)
    SetTimer(SpawnDelay, False);
}


// ============================================================================
// SetupProjectiles
//
// Passes the variables set in this Factory to the Sentinel's weapon. Spawns
// a ThirdPersonActor is necessary.
// ============================================================================

function SetupProjectiles(JBSentinelWeapon SentinelWeapon)
{
  SentinelWeapon.SetCustomProjectile(ProjectileClass, 0, FireRate, FireSound, FlashEmitterClass, SmokeEmitterClass);
  SentinelWeapon.SetCustomProjectile(ProjectileClass, 1, FireRate, FireSound, FlashEmitterClass, SmokeEmitterClass);
  SentinelWeapon.AttachmentClass = AttachmentClass;

  if (SentinelWeapon.ThirdPersonActor != None)
    SentinelWeapon.ThirdPersonActor = Spawn(AttachmentClass, SentinelWeapon.Owner);
}


// ============================================================================
// VehicleSpawned
//
// Initializes the custom projectiles. Makes the sentinel sleep or wake up.
// ============================================================================

function VehicleSpawned()
{
  local Inventory Inv;
  local JBSentinelController ChildController;

  Super.VehicleSpawned();

  if (JBSentinelCeiling(Child) == None)
    return;

  // Initialize projectiles.
  Inv = Child.FindInventoryType(class'JBToolbox2.JBSentinelWeapon');
  if (Inv != None) {
    SetupProjectiles(JBSentinelWeapon(Inv));
    ASVehicle(Child).VehicleProjSpawnOffset = ProjectileSpawnOffset;
  }

  ChildController = JBSentinelController(Child.Controller);

  if (ChildController == None)
    return;

  // Go to sleep or wake up.
  if (!bEnabled && bSleepWhenDisabled) {
    ChildController.bForceSleeping = true;
    ChildController.GoToSleep();
  } else {
    ChildController.bForceSleeping = false;
    ChildController.Awake();
  }
}


// ============================================================================
// SetEnabled
//
// Wakes the sentinel up, or spawns one if it doesn't exist.
// ============================================================================

function SetEnabled(bool bNewEnabled)
{
  local JBSentinelController ChildController;

  Super.SetEnabled( bNewEnabled );

  if (!bSleepWhenDisabled)
    return;

  // No sentinel: spawn one.
  if (Child == None && TriggeredFunction != EAVSF_TriggeredSpawn) {
    SetTimer(SpawnDelay, false);
    return;
  }

  ChildController = JBSentinelController(Child.Controller);

  if (ChildController == None)
    return;

  // Wake the sentinel up.
  if (bEnabled) {
    ChildController.bForceSleeping = false;
    ChildController.Awake();

    return;
  }

  // Trigger disables
  Reset();
}


// ============================================================================
// Reset
// ============================================================================

function Reset()
{
  bResetting = true;
  bEnabled   = BACKUP_bEnabled;
  BlockCount = 0;

  // Force vehicle destruction at round reset.
  if ( Child != None )
  {
    Child.Destroy();
    Child = None;
  }

  // Spawn at startup.
  if ((bEnabled || bSleepWhenDisabled) && TriggeredFunction != EAVSF_TriggeredSpawn )
    SetTimer(SpawnDelay, false);

  bResetting = false;
}


// ============================================================================
// Timer
//
// Spawns the sentinel.
// ============================================================================

function Timer()
{
  if ( bResetting || (!bEnabled && !bSleepWhenDisabled))
    return;

  // Spawn vehicle
  if ( Child == None )
    SpawnVehicle();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  bNoDelete             = False
  bSleepWhenDisabled    = True
  bEnabled              = False
  ProjectileSpawnOffset = (X=110.000000,Z=-14.000000)
  VehicleClass          = class'JBToolbox2.JBSentinelCeiling'
}