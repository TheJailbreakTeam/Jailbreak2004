// ============================================================================
// JBSpirit
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Base class of all spirits.
// ============================================================================


class JBSpirit extends Emitter abstract;


// ============================================================================
// Imports
// ============================================================================

#exec obj load file=..\Textures\EpicParticles.utx


// ============================================================================
// Properties
// ============================================================================

var() float DetectionRadius, MaxSpeed, AccelStrength;
var() bool  bExecuteOutsideJail;
var() Sound SpawnSound, TouchSound;
var() float FadeoutTime;


// ============================================================================
// Variables
// ============================================================================

var Pawn CurrentTarget;
var vector previousLocation;
var JBInfoJail ExecutionJail;
var bool bNoTargetsLeft;


// ============================================================================
// PostBeginPlay
//
// Sets initial velocity, plays the spawn Sound and sets the ExecutionJail.
// ============================================================================

simulated function PostBeginPlay()
{
  log("==================================================================================================");

  Velocity = vector(Rotation);

  if (SpawnSound != None)
    PlaySound(SpawnSound, SLOT_Misc);

  previousLocation = Location;
  Jailbreak(Level.Game).ContainsActorJail(self, ExecutionJail);
}


// ============================================================================
// Timer
// ============================================================================

function Timer()
{
  if (CurrentTarget != None) {
    if (VSize(previousLocation - Location) < 1) {
      log("False");
      bCollideWorld = False;
    } else if (!bCollideWorld) {
      bCollideWorld = True;
      log("True");
    }
  }

  // Set target.
  CurrentTarget = GetTarget();

  // Check if there is a target and still people alive. If neither is the case, die.
  if (CurrentTarget == None && bNoTargetsLeft) {
    SetTimer(0, False);
    bTearOff = True;
    TornOff();
  }
  else
    SetTimer(0.1, False);

  previousLocation = Location;
}


// ============================================================================
// GetTarget
// ============================================================================

function Pawn GetTarget() {
  local JBDamager thisDamager;
  local Pawn thisPawn, bestPawn;
  local JBTagPlayer firstTagPlayer, thisTagPlayer;
  local JBInfoJail thisJail;
  local vector dir;
  local float bestRating, thisRating;
  local int i;
  local array<Pawn> IgnoredTargets;

  // Ignore players who are being killed by a JBDamager.
  foreach DynamicActors(class'JBDamager', thisDamager)
    if (thisDamager.Victim != None)
      IgnoredTargets[IgnoredTargets.Length] = thisDamager.Victim;

  bNoTargetsLeft = True;

  firstTagPlayer = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag) {
  //foreach CollidingActors(class'Pawn', thisPawn, DetectionRadius) {
    thisPawn = thisTagPlayer.GetPawn();

    // Can't kill dead or non-existant players.
    if (thisPawn == None || thisPawn.Health <= 0 || thisPawn.Controller == None || JBFreezer(thisPawn.Inventory) != None)
      continue;

    thisJail = thisTagPlayer.FindJail();

    // Check if the Pawn is in the IgnoredTargets array.
    for (i = 0; i < IgnoredTargets.Length; i++)
      if (thisPawn == IgnoredTargets[i])
        break;

    // Pawn was found in the IgnoredTargets array.
    if (i != IgnoredTargets.Length)
      continue;

    // Still players around to kill. Takes players with JBDamagers in account.
    if (thisJail != None)
      bNoTargetsLeft = False;

    // Don't chase players outside the jail this spirit spawned in.
    if (!bExecuteOutsideJail && ExecutionJail != None && thisJail != ExecutionJail)
      continue;

    // Calculate rating.
    dir = thisPawn.Location - Location;
    thisRating = 1000 * (1.1 + Normal(dir) dot Normal(Velocity)) / FMax(1, VSize(dir));

    // Don't chase players with a lower rating.
    if (thisRating < bestRating)
      continue;

    // Better possible target found.
    bestPawn = thisPawn;
    bestRating = thisRating;
  }

  return bestPawn;
}


// ============================================================================
// Tick
// ============================================================================

function Tick(float DeltaTime)
{
  local vector dir, Accel;

  if (CurrentTarget != None) {
    dir = Normal(CurrentTarget.Location - Location);
    Accel = AccelStrength * dir + Velocity * (dir dot Normal(Velocity) - 1);
    Velocity += DeltaTime * Accel;

    if (VSize(Velocity) > MaxSpeed)
      Velocity = Normal(Velocity) * MaxSpeed;
  }
  else {
    Velocity -= 2 * DeltaTime * Velocity;
  }
}

// ============================================================================
// TornOff
// ============================================================================

simulated function TornOff()
{
  log("//////////////////////////////////////////////////////////////////////////////////////////////////");
  GotoState('FadingOut');
}

function Touch(Actor Other)
{
  local JBDamager thisDamager;

  if (Pawn(Other) != None && Pawn(Other).Health > 0 && Pawn(Other).Controller != None && JBFreezer(Pawn(Other).Inventory) == None) {
    foreach DynamicActors(class'JBDamager', thisDamager)
      if (thisDamager.Victim == Other)
        return;

    Trigger(Self, None);

    ExecutePlayer(Pawn(Other));
    Timer();
  }
}

function ExecutePlayer(Pawn Victim);


// ============================================================================
// ClientTrigger
// ============================================================================

simulated function ClientTrigger()
{
  Trigger(Self, None);
}


// ============================================================================
// Trigger
// ============================================================================

simulated function Trigger(Actor Other, Pawn EventInstigator)
{
  if (Level.NetMode != NM_Client)
    bClientTrigger = !bClientTrigger;

  Super.Trigger(Other, EventInstigator);

  if (TouchSound != None)
    PlaySound(TouchSound, SLOT_Interact);
}

// ============================================================================
// state Spawning
// ============================================================================

auto state Spawning
{
Begin:
  Timer();
  Sleep(0.1);
  bCollideWorld = True;
  SetCollision(True, False, False);
  GotoState('');
}


// ============================================================================
// state FadingOut
// ============================================================================

simulated state FadingOut
{
Begin:
  //log(Level.TimeSeconds@Self@"fading out");
  Sleep(0.5);
  AmbientSound = None;
  Kill();
  Disable('Touch');
  LifeSpan = FadeoutTime;
}


// ============================================================================
// HitWall
// ============================================================================

simulated function HitWall(vector HitNormal, Actor Wall)
{
  // Go straight through if you're inside a wall.
  if (Region.ZoneNumber != 0)
    Velocity -= 1.5 * HitNormal * (HitNormal dot Velocity);
}

function FellOutOfWorld(eKillZType KillType);


// ============================================================================
// default properties
// ============================================================================

defaultproperties
{
  DetectionRadius=2000.000000
  MaxSpeed=700.000000
  AccelStrength=2000.000000
  FadeOutTime=2.000000

  Begin Object Class=SpriteEmitter Name=SpiritFlare
    FadeOut=True
    FadeIn=True
    SpinParticles=True
    UniformSize=True
    TriggerDisabled=False
    FadeOutStartTime=0.500000
    FadeInEndTime=0.500000
    CoordinateSystem=PTCS_Relative
    MaxParticles=4
    StartSpinRange=(X=(Max=1.000000))
    StartSizeRange=(X=(Min=50.000000,Max=50.000000),Y=(Min=50.000000,Max=50.000000),Z=(Min=50.000000,Max=50.000000))
    Texture=Texture'EpicParticles.Flares.FlickerFlare'
    SecondsBeforeInactive=0.000000
    LifetimeRange=(Min=0.500000,Max=0.500000)
  End Object
  Emitters(0)=SpriteEmitter'JBToolbox2.JBSpirit.SpiritFlare'

  bNoDelete=False
  bAlwaysRelevant=True
  bUpdateSimulatedPosition=True
  Physics=PHYS_Projectile
  RemoteRole=ROLE_SimulatedProxy
  CollisionRadius=20.000000
  CollisionHeight=20.000000
  bIgnoreOutOfWorld=True
}
