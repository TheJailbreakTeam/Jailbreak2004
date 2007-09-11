// ============================================================================
// JBGiantSpiderMine
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGiantSpiderMine.uc,v 1.2 2007-02-10 19:13:25 wormbo Exp $
//
// A standalone version of the parasite mine.
// ============================================================================


class JBGiantSpiderMine extends Actor
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\XGameShaders.utx
#exec obj load file=..\Sounds\WeaponSounds.uax


// ============================================================================
// Properties
// ============================================================================

var(Events) edfindable array<JBInfoJail> AssociatedJails;
var(Events) name SpawnEvent, PreExplosionEvent;
var() float PreSpawnDelay;
var() float PreExplosionDelay;
var() float ExplosionDelay;
var() Material SpawnOverlayMaterial;
var() float SpawnOverlayTime;
var() float MomentumTransfer;
var() class<DamageType> MyDamageType;
var(Sounds) array<Sound> BulletSounds;


// ============================================================================
// Variables
// ============================================================================

var name IdleAnims[4];
var int IdleCounts[4];
var float ExplosionCountdown;
var bool bPreExplosion;
var name ExplosionEvent;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    SpawnEvent, PreExplosionEvent, PreSpawnDelay, PreExplosionDelay, ExplosionDelay, SpawnOverlayMaterial, SpawnOverlayTime, MomentumTransfer, MyDamageType, ExplosionEvent;
}


//== PreBeginPlay =============================================================
/**
Force clientside update of editable settings.
*/
// ============================================================================

event PreBeginPlay()
{
  Super.PreBeginPlay();
  if (SpawnEvent != default.SpawnEvent)
    SpawnEvent = SpawnEvent;
  if (PreExplosionEvent != default.PreExplosionEvent)
    PreExplosionEvent = PreExplosionEvent;
  if (PreSpawnDelay != default.PreSpawnDelay)
    PreSpawnDelay = PreSpawnDelay;
  if (PreExplosionDelay != default.PreExplosionDelay)
    PreExplosionDelay = PreExplosionDelay;
  if (ExplosionDelay != default.ExplosionDelay)
    ExplosionDelay = ExplosionDelay;
  if (SpawnOverlayMaterial != default.SpawnOverlayMaterial)
    SpawnOverlayMaterial = SpawnOverlayMaterial;
  if (SpawnOverlayTime != default.SpawnOverlayTime)
    SpawnOverlayTime = SpawnOverlayTime;
  if (MomentumTransfer != default.MomentumTransfer)
    MomentumTransfer = MomentumTransfer;
  if (MyDamageType != default.MyDamageType)
    MyDamageType = MyDamageType;
}


//== EncroachingOn ============================================================
/**
Telefrag players blocking the spawn point.
*/
// ============================================================================

event bool EncroachingOn(Actor Other)
{
  if ( Pawn(Other) != None )
    Pawn(Other).GibbedBy(Self);

  return Super.EncroachingOn(Other);
}


function Trigger(Actor Other, Pawn EventInstigator)
{
  local JBInfoJail thisJail;
  local int i;
  local PlayerReplicationInfo PRI;
  local JBTagPlayer TagPlayer;
  local Pawn thisPawn;
  
  if ( AssociatedJails.Length == 0 ) {
    foreach AllActors(class'JBInfoJail', thisJail) {
      if ( thisJail.ContainsActor(Self) ) {
        AssociatedJails[0] = thisJail;
        break;
      }
    }
    if ( AssociatedJails.Length == 0 ) {
      // no associated jails found, associate with all jails
      log("!!!!" @ Self @ "not associated with any jails!", 'Warning');
      foreach AllActors(class'JBInfoJail', thisJail) {
        AssociatedJails[AssociatedJails.Length] = thisJail;
      }
    }
  }
  
  // check if we actually have someone in this jail
  foreach DynamicActors(class'PlayerReplicationInfo', PRI) {
    TagPlayer = class'JBTagPlayer'.static.FindFor(PRI);
    if ( TagPlayer != None && TagPlayer.IsInJail() && TagPlayer.GetPawn() != None ) {
      thisJail = TagPlayer.GetJail();
      thisPawn = TagPlayer.GetPawn();
      for (i = 0; i < AssociatedJails.Length; ++i) {
        if ( thisJail == AssociatedJails[i] ) {
          // prisoner found, now spawn
          bClientTrigger = !bClientTrigger;
          if (ExplosionEvent != Event)
            ExplosionEvent = Event;
          NetUpdateTime = Level.TimeSeconds - 1;
          GotoState('Spawning');
          return;
        }
      }
    }
  }
}

simulated event ClientTrigger()
{
  GotoState('Spawning');
}


//== state Sleeping ===========================================================
/**
Wait hidden and non-colliding until triggered.
*/
// ============================================================================

auto simulated state Sleeping
{
Begin:
  bHidden = True;
  SetCollision(False, False, False);
}


//== TakeDamage ===============================================================
/**
Play sound effects for bullet hits.
*/
// ============================================================================

event TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
  if ( !bHidden && DamageType != None && DamageType.Default.bBulletHit && BulletSounds.Length > 0 )
    PlaySound(BulletSounds[Rand(BulletSounds.Length)], SLOT_None, 2.0, False, 100);
}


//== state Spawning ===========================================================
/**
Play a spawn effect.
*/
// ============================================================================

simulated state Spawning
{
  ignores ClientTrigger, Trigger;
  
Begin:
  if ( PrespawnDelay > 0 )
    Sleep(PrespawnDelay); // wait until external spawn effect is over
  bHidden = False;
  TriggerEvent(SpawnEvent, Self, None);
  SetCollision(True, True);
  SetLocation(Location);  // "telefrag" players at this location
  if ( SpawnOverlayTime > 0 && SpawnOverlayMaterial != None )
    SetOverlayMaterial(SpawnOverlayMaterial, SpawnOverlayTime, True);
  PlayAnim('Startup', 1.0);
  FinishAnim();
  GotoState('Waiting');
}


//== state Waiting ============================================================
/**
Spider idles a bit before detonating.
*/
// ============================================================================

simulated state Waiting
{
  ignores ClientTrigger, Trigger;
  
  simulated function Timer()
  {
    local JBInfoJail thisJail;
    local int i;
    local PlayerReplicationInfo PRI;
    local JBTagPlayer TagPlayer;
    local Pawn thisPawn;

    ExplosionCountdown -= 0.1;
    if ( !bPreExplosion && ExplosionCountdown <= PreExplosionDelay ) {
      bPreExplosion = True;
      TriggerEvent(PreExplosionEvent, Self, None);
    }
    if ( ExplosionCountdown <= 0 ) {
      SetTimer(0.0, False);
      if (bPreExplosion)
        UntriggerEvent(PreExplosionEvent, Self, None);
      TriggerEvent(ExplosionEvent, Self, None);

      if ( Role == ROLE_Authority ) {
        foreach DynamicActors(class'PlayerReplicationInfo', PRI) {
          TagPlayer = class'JBTagPlayer'.static.FindFor(PRI);
          if ( TagPlayer != None && TagPlayer.IsInJail() && TagPlayer.GetPawn() != None ) {
            thisJail = TagPlayer.GetJail();
            thisPawn = TagPlayer.GetPawn();
            for (i = 0; i < AssociatedJails.Length; ++i) {
              if ( thisJail == AssociatedJails[i] ) {
                thisPawn.TakeDamage(1000, None, thisPawn.Location, MomentumTransfer * Normal(thisPawn.Location - Location) * 1000 / VSize(thisPawn.Location - Location), MyDamageType);
                if ( thisPawn.Health > 0 )
                  thisPawn.Died(None, MyDamageType, thisPawn.Location);
                break;
              }
            }
          }
        }
      }
      UntriggerEvent(ExplosionEvent, Self, None);
      UntriggerEvent(SpawnEvent, Self, None);
      GotoState('Sleeping');
    }
  }
  
  simulated function name SelectIdleAnim()
  {
    local int Rnd, i;
    
    Rnd = Rand(IdleCounts[0] + IdleCounts[1] + IdleCounts[2] + IdleCounts[3]);
    for (i = 0; i < ArrayCount(IdleCounts); ++i) {
      Rnd -= IdleCounts[i];
      if (Rnd < 0) {
        break;
      }
    }
    if (i >= ArrayCount(IdleCounts)) {
      warn("This should never happen!");
      i = Rand(ArrayCount(IdleAnims));
    }
    IdleCounts[i]++;
    return IdleAnims[i];
  }

Begin:
  ExplosionCountdown = ExplosionDelay;
  bPreExplosion = False;
  SetTimer(0.1, True);
  while (True) {
    PlayAnim('Idle', 1.0, 0.3);
    FinishAnim();
    PlayAnim(SelectIdleAnim(), 1.0, 0.3);
    FinishAnim();
  }
}

// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  PreSpawnDelay=2.000000
  PreExplosionDelay=1.000000
  ExplosionDelay=5.000000
  SpawnOverlayMaterial=Shader'XGameShaders.PlayerShaders.VehicleSpawnShaderRed'
  SpawnOverlayTime=2.000000
  MomentumTransfer=100000.000000
  MyDamageType=class'Onslaught.DamTypeONSMine'
  BulletSounds(0)=Sound'WeaponSounds.BaseShieldReflections.BBulletReflect1'
  BulletSounds(1)=Sound'WeaponSounds.BaseShieldReflections.BBulletReflect2'
  BulletSounds(2)=Sound'WeaponSounds.BaseShieldReflections.BBulletReflect3'
  BulletSounds(3)=Sound'WeaponSounds.BaseShieldReflections.BBulletReflect4'
  BulletSounds(4)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact1'
  BulletSounds(5)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact2'
  BulletSounds(6)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact3'
  BulletSounds(7)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact4'
  BulletSounds(8)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact5'
  BulletSounds(9)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact6'
  BulletSounds(10)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact7'
  BulletSounds(11)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact8'
  BulletSounds(12)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact9'
  BulletSounds(13)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact11'
  BulletSounds(14)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact12'
  BulletSounds(15)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact13'
  BulletSounds(16)=Sound'WeaponSounds.BaseImpactAndExplosions.BBulletImpact14'
  IdleAnims(0)=clean
  IdleAnims(1)=look
  IdleAnims(2)=Bob
  IdleAnims(3)=footTap
  IdleCounts(0)=1
  IdleCounts(1)=1
  IdleCounts(2)=1
  IdleCounts(3)=1
  DrawType=DT_Mesh
  bUseDynamicLights=True
  bDramaticLighting=True
  RemoteRole=ROLE_SimulatedProxy
  Mesh=SkeletalMesh'CollidingSpiderMineMesh'
  InitialState=Sleeping
  DrawScale=1.500000
  SurfaceType=EST_Metal
  CollisionRadius=150.000000
  CollisionHeight=60.000000
  bProjTarget=True
  bEdShouldSnap=True
  bAlwaysRelevant=True
}
