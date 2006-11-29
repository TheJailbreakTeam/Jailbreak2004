// ============================================================================
// JBSpiderMine
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// A standalone version of the parasite mine.
// ============================================================================


class JBSpiderMine extends ONSMineProjectile;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file="Animations\SpiderMineMesh.ukx" package="JBToolbox2"
#exec audio import file="Sounds\SpiderJump.wav"


// ============================================================================
// Properties
// ============================================================================

var() int Health;
var() float DampenFactor, DampenFactorParallel, DetectionRange;
var() name IdleAnims[5];


// ============================================================================
// Variables
// ============================================================================

var JBSpiderSpawner Spawner;
var vector LastLocation;


// ============================================================================
// PostBeginPlay
// ============================================================================

simulated event PostBeginPlay()
{
  Super(Projectile).PostBeginPlay();

  TweenAnim('Startup', 0.01);
  bClosedDown = True;
}


// ============================================================================
// Destroyed
// ============================================================================

simulated event Destroyed()
{
  local ONSGrenadeExplosionEffect Explosion;

  if ( !bNoFX && (Level.NetMode == NM_ListenServer || EffectIsRelevant(Location, true)) ) {
    Explosion = Spawn(class'ONSGrenadeExplosionEffect');
    if ( Explosion != None && (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer) ) {
      Explosion.AutoDestroy = False;
      Explosion.LifeSpan = 2.0;
      Explosion.RemoteRole = ROLE_SimulatedProxy;
    }
  }
  Super(Projectile).Destroyed();
  if ( Level.NetMode != NM_Client && !bNoFX )
    TriggerEvent(Event, Self, None);
  if ( Spawner != None )
    Spawner.SpiderDestroyed(self);
}


// ============================================================================
// HitWall
// ============================================================================

simulated event HitWall(vector HitNormal, Actor Wall)
{
  local float PreHitSpeed;

  if ( Pawn(Wall) != None )
    Super.HitWall(HitNormal, Wall);
  else if ( Physics == PHYS_Falling ) {
    // Reflect off Wall w/damping
    Velocity -= (1 + DampenFactorParallel) * (Velocity dot HitNormal) * HitNormal;
    Velocity *= DampenFactor;

    if ( Level.NetMode != NM_DedicatedServer && Speed > 250 )
      PlaySound(ImpactSound, SLOT_Misc);
  }
  else {
    // ran against a wall
    PreHitSpeed = VSize(Velocity);
    Velocity -= 1.1 * (Velocity dot HitNormal) * HitNormal;
    Velocity *= PreHitSpeed / VSize(Velocity);
  }
  AcquireTarget();
}


// ============================================================================
// ProcessTouch
// ============================================================================

simulated function ProcessTouch(Actor Other, vector HitLocation)
{
  if ( ONSMineProjectile(Other) != None ) {
    if ( JBSpiderMine(Other) != None )
      BlowUp(Location);
    else if ( Physics == PHYS_Falling )
      Velocity = vect(0,0,250) + 100 * VRand();
  }
  else if ( Pawn(Other) != None )
    BlowUp(Location);
  else if ( Other.bCanBeDamaged && Other.Base != self )
    BlowUp(Location);
}


// ============================================================================
// EncroachedBy
// ============================================================================

simulated event EncroachedBy(Actor Other)
{
  BlowUp(Location);
}


// ============================================================================
// AcquireTarget
// ============================================================================

function AcquireTarget()
{
  local Pawn A;
  local float Dist, BestDist;

  TargetPawn = None;
  if ( bClosedDown )
    return;

  foreach CollidingActors(class'Pawn', A, DetectionRange, Location)
    if ( A.Health > 0 && (Vehicle(A) == None || Vehicle(A).Driver != None || Vehicle(A).bTeamLocked) && (ONSStationaryWeaponPawn(A) == None || ONSStationaryWeaponPawn(A).bPowered) && (FastTrace(A.Location, Location) || FastTrace(A.Location - vect(0,0,0.9) * A.CollisionHeight, Location)) ) {
      Dist = VSize(A.Location - Location);
      if ( (TargetPawn == None || Dist < BestDist) && (VSize(A.Location - Location) < DamageRadius || Normal(A.Location - Location) dot vect(0,0,1) < 0.7 || A.Location.Z - Location.Z > VSize(A.Location * vect(1,1,0) - Location * vect(1,1,0))) ) {
        TargetPawn = A;
        BestDist = Dist;
      }
    }
}


// ============================================================================
// SetScurryTarget
// ============================================================================

function SetScurryTarget(vector NewTargetLoc)
{
  local vector HN, HL;

  if ( (FastTrace(NewTargetLoc, Location) || FastTrace(NewTargetLoc + vect(0,0,20), Location + vect(0,0,20)) || FastTrace(NewTargetLoc + vect(0,0,20), Location) || FastTrace(NewTargetLoc, Location + vect(0,0,20))) && TargetPawn == None ) {
    TargetLoc = NewTargetLoc + VRand() * Rand(TargetLocFuzz);
    if ( Trace(HL, HN, TargetLoc, NewTargetLoc, False) != None )
      TargetLoc = HL;
    if ( !bClosedDown ) {
      bGoToTargetLoc = true;
      GotoState('ScurryToTargetLoc');
    }
  }
}


// ============================================================================
// TakeDamage
// ============================================================================

function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
  if ( Damage > 0 && InstigatedBy != None && DamageType != MyDamageType )
    Health -= Damage;

  if ( Health <= 0 )
    BlowUp(Location);
}


// ============================================================================
// Trigger
// ============================================================================

function Trigger(Actor Other, Pawn InstigatedBy)
{
  if ( FastTrace(Other.Location, Location) )
    SetScurryTarget(Other.Location);
}


// ============================================================================
// state Flying
// ============================================================================

auto state Flying
{
  simulated function Landed( vector HitNormal )
  {
    if ( Level.NetMode != NM_DedicatedServer && Velocity.Z < -50 )
      PlaySound(ImpactSound, SLOT_Misc);

    bProjTarget = True;

    //SetRotation(rotator(HitNormal));
    GotoState('OnGround');
  }
}


// ============================================================================
// state OnGround
// ============================================================================

simulated state OnGround
{
  simulated function Timer()
  {
    if ( Role < ROLE_Authority ) {
      if ( TargetPawn != None )
        GotoState('Scurrying');
      else if ( bGoToTargetLoc ) {
        TargetLoc = TargetLoc;  // force replication
        GotoState('ScurryToTargetLoc');
      }
      return;
    }

    AcquireTarget();

    if ( TargetPawn != None )
      GotoState('Scurrying');
  }

  simulated function BeginState()
  {
    SetPhysics(PHYS_None);
    Velocity = vect(0,0,0);
    TargetLoc = vect(0,0,0);
    SetTimer(DetectionTimer, True);
    if ( !bClosedDown )
      Timer();
  }

  simulated function EndState()
  {
    SetTimer(0, False);
  }

Begin:
  LastLocation = vect(0,0,0);
  bRotateToDesired = False;
  if ( bClosedDown ) {
    PlayAnim('StartUp');
    FinishAnim();
    bClosedDown = False;
    if ( TargetLoc != vect(0,0,0) ) {
      bGoToTargetLoc = true;
      GotoState('ScurryToTargetLoc');
    }
  }
  while (True) {
    PlayAnim(IdleAnims[Rand(ArrayCount(IdleAnims))], RandRange(0.8, 1.0), 0.3);
    FinishAnim();
    PlayAnim('Idle', 1.0, 0.3);
    FinishAnim();
  }
}


// ============================================================================
// state Scurrying
// ============================================================================

simulated state Scurrying
{
  simulated function Timer()
  {
    local vector NewLoc;
    local rotator TargetDirection;
    local float TargetDist;

    if ( TargetPawn == None ) {
      GotoState('OnGround');
      return;
    }
    if ( Physics != PHYS_Walking )
      return;

    NewLoc = TargetPawn.Location - Location;
    TargetDist = VSize(NewLoc);

    if ( TargetDist < DetectionRange * 1.2 ) {
      NewLoc.Z = 0;
      Velocity = Normal(NewLoc) * ScurrySpeed;
      if ( VSize(NewLoc) < CollisionRadius + TargetPawn.CollisionRadius ) {
        GotoState('OnGround');
        return;
      }
      if ( TargetDist < DetectionRange * 0.2 && FastTrace(Location + Velocity * vect(0.24,0.24,0) + vect(0,0,70), Location) ) {
        GotoState('Flying');
        PlaySound(Sound'SpiderJump');
        PlayAnim('Bob', 1.0, 0.2);
        Velocity *= 1.2;
        Velocity.Z = 350;
        WarnTarget();
        return;
      }
      else if ( FastTrace(TargetPawn.Location, Location) || FastTrace(TargetPawn.Location, Location + vect(0,0,20)) || FastTrace(TargetPawn.Location - vect(0,0,0.8) * TargetPawn.CollisionHeight, Location) || FastTrace(TargetPawn.Location - vect(0,0,0.8) * TargetPawn.CollisionHeight, Location + vect(0,0,20)) ) {
        if ( VSize(Location - LastLocation) < 2 ) {
          GotoState('OnGround');  // looks like we got stuck
          return;
        }
        LastLocation = Location;
        TargetDirection = Rotator(NewLoc);
        TargetDirection.Roll = 0;
        SetRotation(TargetDirection);
        LoopAnim('Scurry', ScurryAnimRate);
        return;
      }
    }

    GotoState('OnGround');
  }
}


// ============================================================================
// state ScurryToTargetLoc
// ============================================================================

simulated state ScurryToTargetLoc
{
  simulated function Timer()
  {
    local vector NewLoc;
    local rotator TargetDirection;

    if ( Physics != PHYS_Walking )
      return;

    NewLoc = TargetLoc - Location;
    NewLoc.Z = 0;
    if ( VSize(NewLoc) < TargetLocFuzz ) {
      AcquireTarget();
      if ( TargetPawn != None ) {
        GotoState('Scurrying');
        return;
      }
      else if ( VSize(NewLoc) < 0.5 * TargetLocFuzz ) {
        GotoState('OnGround');
        return;
      }
    }

    if ( VSize(Location - LastLocation) < 5 || !FastTrace(TargetLoc, Location) ) {
      GotoState('OnGround');  // looks like we got stuck
      return;
    }
    LastLocation = Location;
    Velocity = Normal(NewLoc) * ScurrySpeed * 0.5;
    TargetDirection = Rotator(NewLoc);
    TargetDirection.Roll = 0;
    SetRotation(TargetDirection);
    LoopAnim('Scurry', ScurryAnimRate * 0.5);
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  Health=60
  DampenFactor=0.600000
  DampenFactorParallel=0.500000
  DetectionRange=1000.000000
  IdleAnims(0)="clean"
  IdleAnims(1)="look"
  IdleAnims(2)="Bob"
  IdleAnims(3)="footTap"
  IdleAnims(4)="Idle"
  DetectionTimer=0.200000
  ScurrySpeed=384.000000
  ScurryAnimRate=3.000000
  TargetLocFuzz=50
  bNoFX=True
  bDramaticLighting=True
  bOrientOnSlope=True
  Mesh=SkeletalMesh'JBToolbox2.SmallSpiderMineAnims'
  AmbientGlow=0
  bUnlit=False
  TransientSoundRadius=150.000000
}
