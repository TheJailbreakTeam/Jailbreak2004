// ============================================================================
// JBSpiritSpawner
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
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
    log("!!!!" @ Self @ "Invalid SpiritCount specified");
    SpiritCount = 1;
    bHidden = False;
  }
  if (SpiritSpawnDelay <= 0) {
    log("!!!!" @ Self @ "SpiritSpawnDelay must be greater than 0");
    SpiritSpawnDelay = 0.001;
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
// Start spawning the spirits.
// ============================================================================

function Trigger(Actor Other, Pawn EventInstigator)
{
  GotoState('Spawning', 'Begin');
}


// ============================================================================
// state Spawning
// ============================================================================

state Spawning
{

  // ============================================================================
  // SpawnSpirit
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
} // Spawning

defaultproperties
{
  SpiritClass=class'JBToolbox2.JBFireSpirit'
  SpiritCount=1
  SpiritSpawnDelay=0.300000
  SpiritSpeed=200.000000
  SpiritDirRand=0.200000
  bDirectional=True
  bEdShouldSnap=True
  Texture = Texture'JBToolbox2.icons.JBExecutionSpirit'
}
