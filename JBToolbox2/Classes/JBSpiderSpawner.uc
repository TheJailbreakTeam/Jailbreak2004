// ============================================================================
// JBSpiderSpawner
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Spawns JBSpiderMines.
// ============================================================================


class JBSpiderSpawner extends Actor
    placeable;


// ============================================================================
// Properties
// ============================================================================

var(Events) name TagSpider;
var(Events) name EventSpiderDestroyed;
var() bool bInitiallyActive;
var() bool bRespawnDeadSpiders;
var() bool bTriggeredSpawnDelay;
var() float DetectionRange;
var() int SpiderDamage;
var() int SpiderHealth;
var() float RespawnDelay;
var() byte Team;
var() int TargetLocFuzz;


// ============================================================================
// Variables
// ============================================================================

var JBSpiderMine LastSpawned;


// ============================================================================
// PostBeginPlay
//
// Spawn a spider on startup, if desired..
// ============================================================================

event PostBeginPlay()
{
  Super.PostBeginPlay();

  if ( bInitiallyActive )
    SpawnSpider();
}


// ============================================================================
// SpawnSpider
//
// Spawn a new spider.
// ============================================================================

function SpawnSpider()
{
  if ( Team % 2 == 0 )
    LastSpawned = Spawn(class'JBSpiderMine', self);
  else
    LastSpawned = Spawn(class'JBSpiderMineBlue', self);
  if ( LastSpawned != None ) {
    LastSpawned.Event   = EventSpiderDestroyed;
    LastSpawned.Tag     = TagSpider;
    LastSpawned.DetectionRange = DetectionRange;
    LastSpawned.Damage  = SpiderDamage;
    LastSpawned.Health  = SpiderHealth;
    LastSpawned.bNoFX   = False;
    LastSpawned.TargetLocFuzz = TargetLocFuzz;
    LastSpawned.Spawner = self;
    TriggerEvent(Event, Self, None);
  }
  else
    Settimer(0.1, False);
}


// ============================================================================
// SpiderDestroyed
//
// Called when a spider is destroyed.
// ============================================================================

function SpiderDestroyed(JBSpiderMine Other)
{
  if ( Other != LastSpawned )
    return;

  LastSpawned = None;
  if ( bRespawnDeadSpiders ) {
    if ( RespawnDelay > 0 )
      SetTimer(RespawnDelay, False);
    else
      SetTimer(0.01, False);
  }
}


// ============================================================================
// Timer
//
// Called after a spider is destroyed.
// ============================================================================

function Timer()
{
  SpawnSpider();
}


// ============================================================================
// Trigger
//
// Reset the spider on triggering or spawn a new one if there isn't any.
// ============================================================================

singular function Trigger(Actor Other, Pawn InstigatedBy)
{
  if ( LastSpawned != None )
    LastSpawned.Destroy();

  if ( bTriggeredSpawnDelay && RespawnDelay > 0 )
    SetTimer(RespawnDelay, False);
  else
    SetTimer(0.01, False);
}


// ============================================================================
// Reset
//
// Reset the spider spawner and its spawned spider.
// ============================================================================

function Reset()
{
  if ( LastSpawned != None ) {
    LastSpawned.bNoFX = true;
    LastSpawned.Destroy();
  }
  LastSpawned = None;

  if ( bInitiallyActive )
    SpawnSpider();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  bInitiallyActive=True
  bRespawnDeadSpiders=True
  bTriggeredSpawnDelay=True
  DetectionRange=1000.000000
  SpiderDamage=50
  SpiderHealth=50
  RespawnDelay=0.200000
  TargetLocFuzz=50
  DrawType=DT_Mesh
  bHidden=True
  RemoteRole=ROLE_None
  Mesh=SkeletalMesh'JBToolbox2.SmallSpiderMineAnims'
  DrawScale=0.200000
  PrePivot=(Z=-2.900000)
  bUnlit=True
  bCollideWhenPlacing=True
  CollisionRadius=10.000000
  CollisionHeight=10.000000
  bDirectional=True
}
