// ============================================================================
// JBProjectileSpawner
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBProjectileSpawner.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// An triggered projectile spawner.
// ============================================================================
class JBProjectileSpawner extends Actor Placeable;


// ============================================================================
// Variables
// ============================================================================
struct _LimitedSpawn {
    var() bool bUseLimitedSpawn;
    var() int SpawnLimit;
    var private int TotalProjectileSpawned; };
var() _LimitedSpawn LimitedSpawn;

struct _RandomProjectileType {
    var() bool bUseRandomProjectileType;
    var() class<Projectile> RandomProjectileType[16];
    var private int NumOfProjectileType; };
var() _RandomProjectileType RandomProjectileType;

var() bool bUseInstigator;
var() class<Projectile> ProjectileType;
var() float Precision;
var() float SleepDelay;
var() float SpawnRate;
var() int SpawnAmount;
var() name EndSpawningEvent;
var() name TargetTag;
var() sound SpawnSound;
var private int ProjectileSpawned;
var private vector TargetLoc;


// ============================================================================
// SetAim
//
// Initialize target location.
// ============================================================================
function SetAim()
{
    local vector EndTrace, HitNormal;

    EndTrace = Location + (vector(rotation) * 5000);
    Trace(TargetLoc, HitNormal, EndTrace, Location, true);
}


// ============================================================================
// GetAim
//
// Return an randomize target orientation.
// ============================================================================
function rotator GetAim()
{
    return rotator((TargetLoc + (VRand()*Precision)) - Location);
}


// ============================================================================
// GetProjectileType
//
// Return the type of projectile.
// ============================================================================
function class<Projectile> GetProjectileType()
{
    local int Random;

    if(RandomProjectileType.bUseRandomProjectileType)
    {
        Random = Rand(RandomProjectileType.NumOfProjectileType);
        return RandomProjectileType.RandomProjectileType[Random];
    }

    return ProjectileType;
}


// ============================================================================
// PreSpawning
//
// Called just before the spawning.
// ============================================================================
function PreSpawning()
{
    Disable('Trigger');
    ProjectileSpawned = 0;
}


// ============================================================================
// SpawnProjectile
//
// Spawn a projectile.
// ============================================================================
function SpawnProjectile()
{
    local Projectile Proj;

    Proj = Spawn(GetProjectileType(),,, Location, GetAim());
    if(Proj != None)
    {
        if(SpawnSound != None) PlaySound(SpawnSound,, 5);
        if(bUseInstigator) Proj.Instigator = Instigator;
    }

    if(LimitedSpawn.bUseLimitedSpawn)
    {
        LimitedSpawn.TotalProjectileSpawned++;
        if(LimitedSpawn.TotalProjectileSpawned >= LimitedSpawn.SpawnLimit)
            Destroy();
    }
}


// ============================================================================
// PostSpawning
//
// Called just after the spawning.
// ============================================================================
function PostSpawning()
{
    TriggerEvent(EndSpawningEvent, SELF, Instigator);
    if(bUseInstigator) Instigator = None;
    if(SleepDelay > 0) GoToState('Sleeping');
    else Enable('Trigger');
}


// ============================================================================
// Spawning
//
// The projectile spawning loop.
// ============================================================================
state Spawning
{
    Begin:
    PreSpawning();
    while(ProjectileSpawned < SpawnAmount)
    {
        ProjectileSpawned++;
        SpawnProjectile();
        Sleep(SpawnRate);
    }
    PostSpawning();
}


// ============================================================================
// Sleeping
//
// This actor turns off some time.
// ============================================================================
state Sleeping
{
    ignores Trigger; // make sure

    Begin:
    Sleep(SleepDelay);
    Enable('Trigger');
    GoToState(''); // for stop ignores
}


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================
function Trigger(Actor Other, Pawn EventInstigator)
{
    if(bUseInstigator)
    {
        if(EventInstigator != None)
            Instigator = EventInstigator;
        else return;
    }

    GoToState('Spawning');
}


// ============================================================================
// PostBeginPlay
//
// Initialize the variables.
// ============================================================================
function PostBeginPlay()
{
    local Actor A;
    local int i;

    Super.PostBeginPlay();

    // force default/minimum variable
    if(ProjectileType == None) ProjectileType = class'xWeapons.RocketProj';
    SpawnAmount = Max(SpawnAmount, 1);
    SpawnRate = FMax(SpawnRate, 0.1);

    // automatic orientation by tagged actor
    if(TargetTag != '')
        foreach DynamicActors(class'Actor', A, TargetTag)
            if(A != None)
                SetRotation(rotator(A.Location - Location));

    // calculate the number of random projectile type used
    if(RandomProjectileType.bUseRandomProjectileType)
    {
        for(i=0; i<16; i++)
        {
            if(RandomProjectileType.RandomProjectileType[i] == None)
            {
                if(i > 0) RandomProjectileType.NumOfProjectileType = i;
                else RandomProjectileType.bUseRandomProjectileType = FALSE;
                break;
            }
        }
    }

    SetAim();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bDirectional=True
    bHidden=True
    bUseInstigator=True
    LimitedSpawn=(SpawnLimit=32)
    Precision=128
    ProjectileType=class'xWeapons.RocketProj'
    SleepDelay=10
    SpawnAmount=3
    SpawnRate=1.000000
}
