// ============================================================================
// JBMonsterSpawner
// Copyright 2003 by Will ([-will-]).
// $Id: JBMonsterSpawner.uc,v 1.7 2003/06/29 14:56:01 mychaeel Exp $
//
// Monster Spawner Actor.
// ============================================================================


Class JBMonsterSpawner Extends Keypoint
  Placeable;


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
Var() String CustomMonster;
Var() Mesh MonsterMesh;
Var() Material MonsterSkin[8];
var() Bool bMonsterControllable;


// ============================================================================
// Variables
// ============================================================================

Var Vector StartSpot;
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

  If (DynamicLoadObject("SkaarjPack.Monster", Class'class', True) == None)
    {
    For (Jails = JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstJail; Jails != None; Jails = Jails.NextJail)
        Jails.ExecutionDelayFallback = 3;

    Self.Destroy();
    }
  
  If (MonsterType != Custom)
    MonsterClass = Class<xPawn>(DynamicLoadObject("Skaarjpack." $ String(GetEnum(Enum'EMonsterType', MonsterType)), Class'class'));
  Else
    {
    MonsterClass = Class<xPawn>(DynamicLoadObject(CustomMonster, Class'class', True));
    If (MonsterClass == None);
      MonsterClass = Class<xPawn>(DynamicLoadObject("Skaarjpack.Krall", Class'class', True));
    }

  StartSpot = Self.Location;
}


// ============================================================================
// SpawnMonster
//
// Spawns a monster of the specified type at this actors location.
// ============================================================================

Function SpawnMonster()
{
  Local int i;

  MyMonster = Spawn(MonsterClass, , , StartSpot, Self.Rotation);
  
  If (MyMonster == None)
    MyMonster = Spawn(MonsterClass, , , StartSpot, Self.Rotation);
  
  If (MyMonster != None)
    {
    If (MonsterMesh != None)
      MyMonster.LinkMesh(MonsterMesh);
  
    For (i = 0; i < 8; i++)
      {
      If (MonsterSkin[i] != None)
        MyMonster.Skins[i] = MonsterSkin[i];
      }

    MyMonster.DamageScaling = 6.5;
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
    If (W != None)
      If (W.Owner.IsA('Monster'))
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
// Tick
//
// Prevents monsters fighting each other, removes their weapons, and makes them
// gods.
// ============================================================================

Function Tick(Float TimeDelta)
{
  If (MyMonster != None)
    {
    If ((MyMonster.Controller != None) && (MonsterController == None))
      MonsterController = MyMonster.Controller;

      If (MonsterController != None)
        {
        If ((MonsterController.Enemy != None) && (MonsterController.Enemy.IsA('Monster')))
          MonsterController.Enemy = None;
        EraseWeapons();
        }     
  
    If ((MyMonster != None) && (MyMonster.Controller != None))
      MyMonster.Controller.bGodMode = True;
    }
}


// ============================================================================
// State MonsterWait
//
// The monster is waiting. On triggering it will attack.
// ============================================================================

State MonsterWait
{
  
  // ============================================================================
  // Trigger
  //
  // Monster will attack.
  // ============================================================================
  
  Function Trigger(Actor Other, Pawn EventInstigator)
  {
    GoToState('MonsterAttack');
  }


  // ============================================================================
  // Timer
  //
  // Stops the monster attacking.
  // ============================================================================
  
  Function Timer()
  {
    If (MonsterController != None)
      {
      MonsterController.default.bStasis = True;
      MonsterController.bStasis = True;
      MonsterController.Velocity = Vect(0, 0, 0);
      MonsterController.bIsPlayer = False;
      MyMonster.bIgnoreForces = True;
      MyMonster.Default.bStasis = True;
      MyMonster.SetLocation(StartSpot);
      SetTimer(0, False);
      }
  }
  
  
  // ============================================================================
  // BeginState
  //
  // Spawns a monster, and sets the timer.
  // ============================================================================
  
  Function BeginState()
  {
    SpawnMonster();
    SetTimer(0.05, true);
  }
  
} // state MonsterWait


// ============================================================================
// State MonsterAttack
//
// The monster is attacking. On trigger it will be destroyed and a new one
// spawned.
// ============================================================================

State MonsterAttack
{
  
  // ============================================================================
  // Trigger
  //
  // Kill the monster and go back to 'MonsterWait'.
  // ============================================================================
  
  Function Trigger(Actor Other, Pawn EventInstigator)
  {
    KillMonster();
    GoToState('MonsterWait');
  }


  // ============================================================================
  // Timer
  //
  // Allow the monster to attack.
  // ============================================================================
  
  Function Timer()
  {
    If (MonsterController != None)
      {
      MonsterClass.Default.bStasis = False;
      MonsterController.bStasis = False;
      MonsterController.Default.bStasis = False;
      MyMonster.bStasis = False;
      MyMonster.bIgnoreForces = False;
      }

    SetTimer(0, False);
  }


  // ============================================================================
  // BeginState
  //
  // Sets timer to unset the variables holding the monsters.
  // ============================================================================
  
  Function BeginState()
  {
    SetTimer(0.05, true);
  }
  
} // state MonsterAttack


// ============================================================================
// Default properties
// ============================================================================

DefaultProperties
{
  MonsterType = SkaarjPupae
  bHidden     = True
  bDirectional= True
  bHiddenEd   = False
  bStatic     = False /* override Keypoint */
  InitialState= MonsterWait
  DrawType    = DT_Sprite
}