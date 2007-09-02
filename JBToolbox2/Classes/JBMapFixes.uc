// ============================================================================
// JBMapFixes
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBMapFixes.uc,v 1.6 2007-04-30 11:19:48 jrubzjeknf Exp $
//
// Fixes small bugs in maps that are not worth another release and adds a
// Spirit execution in some cases.
// ============================================================================


class JBMapFixes extends ReplicationInfo
  NotPlaceable
  HideDropDown;


// ============================================================================
// Variables
// ============================================================================

var String MapName;
var JBGameRulesMapFixes GameRules;


// ============================================================================
// PostBeginPlay
//
// Executes the proper function for the proper map.
// ============================================================================

simulated function PostBeginPlay()
{
  AddToPackageMap();
  MapName = GetJBMapName(Level);

  // Pick your function!
  switch (MapName) {
    case "jb-indusrage2-gold":    IndusRage();     break;
    case "jb-arlon-gold":         Arlon();         break;
    case "jb-babylontemple-gold": BabylonTemple(); break;
    case "jb-heights-gold-v2":    Heights();       break;
    case "jb-collateral":         Collateral();    break;
    case "jb-aswan-v2":           Aswan();         break;
  }
}


// ============================================================================
// SpawnGameRules
//
// Spawns the gamerules and saves it in a variable. Only executed if a map is
// loaded that actually needs these gamerules.
// ============================================================================

function SpawnGameRules()
{
  GameRules = Spawn(class'JBGameRulesMapFixes');

  Level.Game.AddGameModifier(GameRules);
}


// ============================================================================
// IndusRage (JB-IndusRage2-Gold.ut2)
//
// Fixes the HOM caused by a wrong setting in all ZoneInfos.
// ============================================================================

simulated function IndusRage()
{
  local ZoneInfo Z;

  if (Level.NetMode != NM_DedicatedServer)
    foreach AllActors(class'ZoneInfo', Z)
      Z.bClearToFogColor = True;
}


// ============================================================================
// Arlon (JB-Arlon-Gold.ut2)
//
// Fixes various bugs in this map.
// ============================================================================

simulated function Arlon()
{
  local Mover M;
  local HealthPack HP;
	local JBArlonMedbox MB;

  if (Role == ROLE_Authority) {
    // Fix players other than the winner of the arenamatch grabbing the super shock rifle.
    SpawnGameRules();

    // Fix elevators.
    foreach DynamicActors(class'Mover', M)
      if (M.Name != 'Mover2' && M.Name != 'Mover4') {
        M.EncroachDamage    = 0;
        M.MoverEncroachType = ME_ReturnWhenEncroach;
      }

    // Fix the appearance of the custom healthpacks in netplay.
    foreach DynamicActors(class'HealthPack', HP) {
      if (HP.Class == class'HealthPack') {
        MB = Spawn(class'JBArlonMedbox', None, HP.Tag, HP.Location, HP.Rotation);
        if (MB != None) {
          MB.SetStaticMesh(HP.StaticMesh);
          HP.Destroy();
        }
      }
    }
  }
}


// ============================================================================
// BabylonTemple (JB-BabylonTemple-Gold.ut2)
//
// Adds a fiery Spirit execution.
// ============================================================================

function BabylonTemple()
{
  // Create a SpiritSpawner for the red jail.
  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'redspirit',
                      vect(-36, -4488, -7828),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBFireSpirit',
                      2,
                      0.3);

  // Create a SpiritSpawner for the blue jail.
  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'bluespirit',
                      vect(36, 4488, -7828),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBFireSpirit',
                      2,
                      0.3);

  // Picking a random execution is handled by our GameRules.
  SpawnGameRules();
}


// ============================================================================
// Heights (JB-Heights-Gold-v2.ut2)
//
// Fixes the crane elevators and adds a shocking Spirit execution.
// ============================================================================

function Heights()
{
  local ScriptedTrigger ST;

  // Fix the crane elevators.
  foreach AllActors(class'ScriptedTrigger', ST)
    if (ST.Name == 'ScriptedTrigger5' || ST.Name == 'ScriptedTrigger9')
      ACTION_WaitForTimer(ST.Actions[9]).PauseTime = 14.00;

  // Create two SpiritSpawners for the red jail.
  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'redspirit',
                      vect(1024, -1396, -1916),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBThunderSpirit',
                      1,
                      0.3);

  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'redspirit',
                      vect(1024,  -428, -1916),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBThunderSpirit',
                      1,
                      0.3);

  // Create two SpiritSpawners for the blue jail.
  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'bluespirit',
                      vect(1024,  484, -1916),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBThunderSpirit',
                      1,
                      0.3);

  CreateSpiritSpawner(class'JBSpiritSpawner',
                      'bluespirit',
                      vect(1024, 1524, -1916),
                      rot(-16384, 0, 0),
                      class'JBToolbox2.JBThunderSpirit',
                      1,
                      0.3);

  // Picking a random execution is handled by our GameRules.
  SpawnGameRules();
}


// ============================================================================
// Collateral (JB-Collateral.ut2)
//
// Fixes a ZoneInfo's LocationName.
// ============================================================================

simulated function Collateral()
{
  local Volume V;

  if (Level.NetMode != NM_DedicatedServer)
    foreach AllActors(class'Volume', V)
      if (V.Name == 'Volume4') {
        V.LocationName = "Blue Base: Lowest Walkway";
        break;
      }
}


// ============================================================================
// Aswan (JB-Aswan-v2.ut2)
//
// Fixes the spider mines.
// ============================================================================

simulated function Aswan()
{
  local Actor A;
  local bool bTemp;

  // red giant spider and explosion emitter
  foreach DynamicActors(class'Actor', A, 'RedGiantSpider') {
    if (A.IsA('JBGiantBlueSpiderMine') && A.Class != class'JBGiantBlueSpiderMine')
      ReplaceGiantSpider(A, class'JBGiantBlueSpiderMine');
    else if (A.IsA('JBGiantSpiderMine') && A.Class != class'JBGiantBlueSpiderMine' && A.Class != class'JBGiantSpiderMine')
      ReplaceGiantSpider(A, class'JBGiantSpiderMine');
  }

  // blue giant spider and explosion emitter
  foreach DynamicActors(class'Actor', A, 'BlueGiantSpider') {
    if (A.IsA('JBGiantBlueSpiderMine') && A.Class != class'JBGiantBlueSpiderMine')
      ReplaceGiantSpider(A, class'JBGiantBlueSpiderMine');
    else if (A.IsA('JBGiantSpiderMine') && A.Class != class'JBGiantBlueSpiderMine' && A.Class != class'JBGiantSpiderMine')
      ReplaceGiantSpider(A, class'JBGiantSpiderMine');
  }

  // temporarily disable default initial spawning
  bTemp = class'JBSpiderSpawner'.default.bInitiallyActive;
  class'JBSpiderSpawner'.default.bInitiallyActive = False;

  // red spider spawners
  foreach DynamicActors(class'Actor', A, 'RedExecutionEnd') {
    if (A.IsA('JBSpiderSpawner') && A.Class != class'JBSpiderSpawner') {
      ReplaceSpiderSpawner(A);
    }
  }
  // blue spider spawners
  foreach DynamicActors(class'Actor', A, 'BlueExecutionEnd') {
    if (A.IsA('JBSpiderSpawner') && A.Class != class'JBSpiderSpawner') {
      ReplaceSpiderSpawner(A);
    }
  }

  // reenable default initial spawning
  class'JBSpiderSpawner'.default.bInitiallyActive = bTemp;
}


// ============================================================================
// ReplaceGiantSpider
//
// Replaces a giant spider mine.
// ============================================================================

function ReplaceGiantSpider(Actor OldSpider, class<JBGiantSpiderMine> NewClass)
{
  local JBGiantSpiderMine NewSpider;

  // spawn a new spawner
  NewSpider = Spawn(NewClass, None, OldSpider.Tag, OldSpider.Location, OldSpider.Rotation);
  NewSpider.SetPropertyText("AssociatedJails", OldSpider.GetPropertyText("AssociatedJails"));
  NewSpider.SetPropertyText("SpawnEvent", OldSpider.GetPropertyText("SpawnEvent"));
  NewSpider.SetPropertyText("PreExplosionEvent", OldSpider.GetPropertyText("PreExplosionEvent"));
  NewSpider.SetPropertyText("SpawnOverlayMaterial", OldSpider.GetPropertyText("SpawnOverlayMaterial"));
  NewSpider.SetPropertyText("MyDamageType", OldSpider.GetPropertyText("MyDamageType"));
  NewSpider.SetPropertyText("BulletSounds", OldSpider.GetPropertyText("BulletSounds"));

  NewSpider.PreSpawnDelay = float(OldSpider.GetPropertyText("PreSpawnDelay"));
  NewSpider.PreExplosionDelay = float(OldSpider.GetPropertyText("PreExplosionDelay"));
  NewSpider.ExplosionDelay = float(OldSpider.GetPropertyText("ExplosionDelay"));
  NewSpider.SpawnOverlayTime = float(OldSpider.GetPropertyText("SpawnOverlayTime"));
  NewSpider.MomentumTransfer = float(OldSpider.GetPropertyText("MomentumTransfer"));

  NewSpider.Event = OldSpider.Event;

  // destroy old spider
  OldSpider.Destroy();
}


// ============================================================================
// ReplaceSpiderSpawner
//
// Replaces a spider spawner.
// ============================================================================

function ReplaceSpiderSpawner(Actor OldSpawner)
{
  local JBSpiderSpawner newSpawner;

  // spawn a new spawner
  newSpawner = Spawn(class'JBSpiderSpawner', None, OldSpawner.Tag, OldSpawner.Location, OldSpawner.Rotation);
  newSpawner.SetPropertyText("TagSpider", OldSpawner.GetPropertyText("TagSpider"));
  newSpawner.SetPropertyText("EventSpiderDestroyed", OldSpawner.GetPropertyText("EventSpiderDestroyed"));
  newSpawner.bInitiallyActive     = bool(OldSpawner.GetPropertyText("bInitiallyActive"));
  newSpawner.bRespawnDeadSpiders  = bool(OldSpawner.GetPropertyText("bRespawnDeadSpiders"));
  newSpawner.bTriggeredSpawnDelay = bool(OldSpawner.GetPropertyText("bInitiallyActive"));
  newSpawner.bInitiallyActive     = bool(OldSpawner.GetPropertyText("bTriggeredSpawnDelay"));
  newSpawner.DetectionRange       = float(OldSpawner.GetPropertyText("DetectionRange"));
  newSpawner.SpiderDamage         = int(OldSpawner.GetPropertyText("SpiderDamage"));
  newSpawner.SpiderHealth         = int(OldSpawner.GetPropertyText("SpiderHealth"));
  newSpawner.RespawnDelay         = float(OldSpawner.GetPropertyText("RespawnDelay"));
  newSpawner.Team                 = byte(OldSpawner.GetPropertyText("Team"));
  newSpawner.TargetLocFuzz        = int(OldSpawner.GetPropertyText("TargetLocFuzz"));

  // destroy spawned spider first
  OldSpawner.SetPropertyText("bRespawnDeadSpiders", "False");
  OldSpawner.SetPropertyText("bInitiallyActive", "False");
  OldSpawner.Reset();
  OldSpawner.Destroy();

  // now spawn new spider
  if (newSpawner.bInitiallyActive)
    newSpawner.SpawnSpider();
}


// ============================================================================
// CreateSpiritSpawner
//
// Creates a spirit spawner.
// ============================================================================

function CreateSpiritSpawner(class<JBSpiritSpawner> SSClass, Name SSTag, Vector SSLocation, Rotator SSRotation,
                             class<JBSpirit> SpiritClass, int SpiritCount, float SpiritSpawnDelay)
{
  local JBSpiritSpawner SpiritSpawner;

  SpiritSpawner = Spawn(SSClass,, SSTag,  SSLocation, SSRotation);

  SpiritSpawner.SpiritClass      = SpiritClass;
  SpiritSpawner.SpiritCount      = SpiritCount;
  SpiritSpawner.SpiritSpawnDelay = SpiritSpawnDelay;
}


// ============================================================================
// GetJBMapName: Returns the name of the current map played in a proper format.
// ============================================================================

static function string GetJBMapName(LevelInfo L) {  return Locs(Left(L, InStr(L, ".")));  }
