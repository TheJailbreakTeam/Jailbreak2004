// ============================================================================
// JBSpiritSpawner
// Copyright 2006 by Wormbo <wormbo@online.de>
// $Id: JBSpiritSpawner.uc,v 1.1 2006-11-29 19:14:29 jrubzjeknf Exp $
//
// Spawns the spirits.
// ============================================================================


class JBSpiritSpawner extends Triggers placeable;


// ============================================================================
// Imports
// ============================================================================

#exec Texture import file=Textures\JBExecutionSpirit.dds mips=off masked=on group=icons


// ============================================================================
// Properties
// ============================================================================

var() class<JBSpirit> SpiritClass;
var() int             SpiritCount;
var() float           SpiritSpawnDelay;
var() float           SpiritSpeed;
var() float           SpiritDirRand;


// ============================================================================
// Variables
// ============================================================================

var int SpiritsToSpawn;


// ============================================================================
// PostBeginPlay
//
// Checks for illegal input.
// ============================================================================

function PostBeginPlay()
{
  if (SpiritClass == None) {
    log("!!!!" @ Self @ "No SpiritClass specified");
    bHidden = False;
  }
  if (SpiritCount <= 0) {
    log("!!!!" @ Self @ "SpiritCount must be greater than 0");
    SpiritCount = 1;
    bHidden = False;
  }
  if (SpiritSpawnDelay < 0) {
    log("!!!!" @ Self @ "SpiritSpawnDelay must be greater than or equal to 0");
    SpiritSpawnDelay = 0.0;
    bHidden = False;
  }
  if (SpiritSpeed < 0) {
    log("!!!!" @ Self @ "SpiritSpeed must be greater than or equal to 0");
    SpiritSpeed = 0.0;
    bHidden = False;
  }
}


// ============================================================================
// Trigger
//
// Start spawning spirits.
// ============================================================================

function Trigger(Actor Other, Pawn EventInstigator)
{
  GotoState('Spawning', 'Begin');
}


// ============================================================================
// state Spawning
//
// Spawns the desired number of spirits, then returns to idle state.
// ============================================================================

state Spawning
{
  // ============================================================================
  // SpawnSpirit
  //
  // Spawns a new spirit and sets its initial movement speed.
  // ============================================================================

  function SpawnSpirit()
  {
    local JBSpirit Spirit;

    Spirit = Spawn(SpiritClass,,, Location);
    if (Spirit != None)
      Spirit.Velocity = SpiritSpeed * Normal(vector(Rotation) + SpiritDirRand * VRand());
    else {
      log("!!!!" @ Self @ "Invalid SpiritClass" @ SpiritClass @ "specified");
      bHidden = False;
    }
  }

Begin:
  SpiritsToSpawn = SpiritCount;
  while(SpiritsToSpawn-- > 0) {
    Sleep(SpiritSpawnDelay);
    SpawnSpirit();
  }
  GotoState('');
}


// ============================================================================
// Default values
// ============================================================================

defaultproperties
{
  SpiritClass       = class'JBToolbox2.JBFireSpirit'
  SpiritCount       =   1
  SpiritSpawnDelay  =   0.3
  SpiritSpeed       = 200.0
  SpiritDirRand     =   0.2
  bDirectional      = True
  bEdShouldSnap     = True
  bCollideActors    = False
  Texture           = Texture'JBToolbox2.icons.JBExecutionSpirit'
}
