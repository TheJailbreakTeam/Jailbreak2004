// ============================================================================
// JBMonsterSpawner
// Copyright 2003 by Will ([-will-]).
// $Id: JBMonsterSpawner.uc,v 1.12 2004/04/22 16:27:06 mychaeel Exp $
//
// Monster Spawner Actor.
// ============================================================================


Class JBMonsterSpawner Extends Keypoint
  Placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBMonsterSpawner.pcx mips=off masked=on group=icons


// ============================================================================
// Properties
// ============================================================================

Var() ENum EMonsterType
{
  SkaarjPupae,
  Razorfly,
  Manta,
  Krall,
  EliteKrall,
  Gasbag,
  Brute,
  Skaarj,
  Behemoth,
  IceSkaarj,
  FireSkaarj,
  WarLord,
  Custom,
} MonsterType;

Var() String    CustomMonster;
Var() Mesh      MonsterMesh;
Var() Material  MonsterSkin[8];
Var   bool      bMonsterControllable;
Var() bool      bMonsterInGodMode;
Var() bool      bResetOnExecutionEnd;

var(Events) name TagExecutionCommit; // tag for start of execution 
var(Events) name TagExecutionEnd;    // tag for end of execution: reset monster
var(Events) bool bUseExecutionTags;  // use above tags or Tag property


// ============================================================================
// Variables
// ============================================================================

Var Vector StartSpot;
Var Vector MonsterLocationPrev;
Var xPawn MyMonster;
Var Controller MonsterController;
Var Class<xPawn> MonsterClass;


// ============================================================================
// PostBeginPlay
//
// Checks for the existance of the bonuspack, and also sets a few variables for
// use in other functions.
// ============================================================================

Function PostBeginPlay()
{
  Local JBInfoJail Jails; 

  If (DynamicLoadObject("SkaarjPack.Monster", Class'Class', True) == None)
  {
    For (Jails = JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstJail; Jails != None; Jails = Jails.NextJail)
      Jails.ExecutionDelayFallback = Jails.Default.ExecutionDelayFallback;
    Destroy();
  }
  
  If (MonsterType == Custom)
         MonsterClass = Class<xPawn>(DynamicLoadObject(CustomMonster,                                                    Class'Class'));
    Else MonsterClass = Class<xPawn>(DynamicLoadObject("SkaarjPack." $ String(GetEnum(Enum'EMonsterType', MonsterType)), Class'Class'));

  If (MonsterClass == None)
    MonsterClass = Class<xPawn>(DynamicLoadObject("SkaarjPack.Krall", Class'Class'));

  StartSpot = Location;
}


// ============================================================================
// SpawnMonster
//
// Spawns a monster of the specified type at this actors location.
// ============================================================================

Function SpawnMonster()
{
  Local int i;

  KillMonster();

  MyMonster = Spawn(MonsterClass, , , StartSpot, Rotation);
  If (MyMonster == None)
    Return;

  MonsterLocationPrev = StartSpot;

  MonsterController = MyMonster.Controller;
  MonsterController.bIsPlayer = False;
  MonsterController.bGodMode = bMonsterInGodMode;

  If (MyMonster != None)
  {
    If (MonsterMesh != None)
      MyMonster.LinkMesh(MonsterMesh);
  
    For (i = 0; i < 8; i++)
      If (MonsterSkin[i] != None)
        MyMonster.Skins[i] = MonsterSkin[i];

    MyMonster.DamageScaling = 6.5;
    MyMonster.PlayTeleportEffect(True, True);
  }
}


// ============================================================================
// EraseWeapons
//
// Monsters don't need weapons, and they look odd.
// ============================================================================

Function EraseWeapons()
{
  Local Weapon W;

  ForEach DynamicActors(Class'Weapon', W)
    If (W.Owner != None &&
        W.Owner.IsA('Monster'))
      W.Destroy();
}


// ============================================================================
// KillMonster
//
// Kills the monster, ready for respawning.
// ============================================================================

Function KillMonster()
{
  If (MyMonster != None)
    MyMonster.Destroy();
}


// ============================================================================
// State MonsterSpawnedOnTrigger
//
// Nothing happens. On triggering, the monster is spawned and attacks.
// ============================================================================

State() MonsterSpawnedOnTrigger
{
  // ================================================================
  // BeginState
  //
  // Sets Tag to TagExecutionCommit if bUseExecutionTags is used.
  // ================================================================
  
  Function BeginState()
  {
    if (bUseExecutionTags)
      Tag = TagExecutionCommit;
  }


  // ================================================================
  // Trigger
  //
  // Monster will attack.
  // ================================================================
  
  Function Trigger(Actor Other, Pawn EventInstigator)
  {
    SpawnMonster();
    GoToState('MonsterAttack');
  }

} // state MonsterSpawnedOnTrigger


// ============================================================================
// State MonsterWaitsDormant
//
// The monster is spawned and waits. On triggering it will attack.
// ============================================================================

State() MonsterWaitsDormant
{
  // ================================================================
  // BeginState
  //
  // Sets Tag to TagExecutionCommit if bUseExecutionTags is used.
  // ================================================================

  Function BeginState()
  {
    If (bUseExecutionTags)
      Tag = TagExecutionCommit;
  }


  // ================================================================
  // Trigger
  //
  // Enters state MonsterAttack so that monsters start attacking.
  // ================================================================
  
  Function Trigger(Actor Other, Pawn EventInstigator)
  {
    GoToState('MonsterAttack');
  }


  // ================================================================
  // State Code
  //
  // Waits until the level is not in the startup phase anymore.
  // Then spawns a monster and sets it up to ignore players.
  // ================================================================
  
  Begin:
  
    While (Level.bStartup)
      Sleep(0.0);  // wait until next tick

    SpawnMonster();

    If (MyMonster != None)
    {
      MonsterController.bStasis = True;
      MyMonster.bStasis         = True;
      MyMonster.bIgnoreForces   = True;
    }

} // state MonsterWaitsDormant


// ============================================================================
// State MonsterAttack
//
// The monster is attacking. On trigger it will be destroyed and the actor
// returns to initial state.
// ============================================================================

State MonsterAttack
{
  // ================================================================
  // BeginState
  //
  // Sets Tag to TagExecutionEnd if bUseExecutionTags is used. Sets
  // the monsters up to attack players.
  // ================================================================
  
  Function BeginState()
  {
    If (bUseExecutionTags)
      Tag = TagExecutionEnd;

    If (MyMonster != None)
    {
      MonsterController.bStasis = False;
      MyMonster.bStasis         = False;
      MyMonster.bIgnoreForces   = False;
    }
  }
  

  // ================================================================
  // Trigger
  //
  // Kill the monster and go back to InitialState.
  // ================================================================
  
  Function Trigger(Actor Other, Pawn EventInstigator)
  {
    KillMonster();
    GoToState(InitialState);
  }


  // ================================================================
  // Tick
  //
  // Prevents monsters from fighting each other and removes their
  // weapons. Ends this state when the execution sequence ends.
  // ================================================================
  
  Function Tick(Float TimeDelta)
  {
    If (MonsterController != None)
    {
      EraseWeapons();
      
      If (MonsterController.Enemy != None &&
          MonsterController.Enemy.IsA('Monster'))
        MonsterController.Enemy = None;
    }

    If (MyMonster != None)
    {
      // reset monster if it teleported away
      If (VSize(MonsterLocationPrev - MyMonster.Location) > 256.0)
        MyMonster.SetLocation(MonsterLocationPrev);
      MonsterLocationPrev = MyMonster.Location;
    }

    If (bResetOnExecutionEnd && !Level.Game.IsInState('Executing'))
      Trigger(Self, None);
  }

} // state MonsterAttack


// ============================================================================
// Defaults
// ============================================================================

DefaultProperties
{
  MonsterType          = SkaarjPupae;
  bMonsterControllable = False;
  bMonsterInGodMode    = True;
  bResetOnExecutionEnd = True;
  bUseExecutionTags    = True;
  InitialState         = MonsterWaitsDormant;

  Texture              = Texture'JBToolbox.Icons.JBMonsterSpawner';  
  bHidden              = True;
  bHiddenEd            = False;
  bStatic              = False;

  bDirectional         = True;
  DrawType             = DT_Sprite;
}