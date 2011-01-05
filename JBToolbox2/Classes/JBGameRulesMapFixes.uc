// ============================================================================
// JBGameRulesMapFixes
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBGameRulesMapFixes.uc,v 1.7 2011-01-03 18:20:27 wormbo Exp $
//
// Fixes small bugs in maps that are not worth another release and adds a
// Spirit execution in some cases.
// ============================================================================


class JBGameRulesMapFixes extends JBGameRules NotPlaceable HideDropDown;


// ============================================================================
// Variables
// ============================================================================

var JBTagPlayer TagArenaWinner;
var int CountExecutionRegular, CountExecutionAlternate;


// ============================================================================
// SetInitialState
//
// Sets the correct state depending on the current map.
// ============================================================================

simulated event PreBeginPlay()
{
  local xWeaponBase thisBase;

  AddToPackageMap();

  // weapon base skin fix
  foreach AllActors(class'xWeaponBase', thisBase) {
    if (thisBase.StaticMesh == class'xWeaponBase'.default.StaticMesh && thisBase.Skins.Length > 0 && thisBase.Skins[0] == class'xWeaponBase'.default.Skins[0]) {
      thisBase.Skins.Length = 0;
      thisBase.ResetStaticFilterState();
    }
  }

  switch (Locs(Level.Outer.Name)) {
    case "jb-arlon-gold":         InitialState = 'Arlon';         break;
    case "jb-aswan-v2":           InitialState = 'Aswan';         break;
    case "jb-atlantis-gold":      InitialState = 'Atlantis';      break;
    case "jb-babylontemple-gold": InitialState = 'BabylonTemple'; break;
    case "jb-collateral":         InitialState = 'Collateral';    break;
    case "jb-cosmos":             InitialState = 'Cosmos';        break;
    case "jb-frostbite":          InitialState = 'Frostbite';     break;
    case "jb-heights-gold-v2":    InitialState = 'Heights';       break;
    case "jb-indusrage2-gold":    InitialState = 'IndusRage';     break;
    case "jb-poseidon-gold":      InitialState = 'Poseidon';      break;
  }
}


// ============================================================================
// state Arlon (JB-Arlon-Gold.ut2)
//
// Fixes elevators and med packs and prevents anyone except the arena winner
// from picking up the super shock rifle.
// ============================================================================

state Arlon
{
  // ==========================================================================
  // BeginState
  //
  // Fixes elevator encroach damage and clientside med box appearance.
  // ==========================================================================

  function BeginState()
  {
    local Mover M;
    local HealthPack HP;
    local JBArlonMedbox MB;
    local ZoneInfo ZI;

    // Fix elevators.
    foreach DynamicActors(class'Mover', M) {
      if (M.Name != 'Mover0' && M.Name != 'Mover6') {
        M.EncroachDamage    = 0;
        M.MoverEncroachType = ME_ReturnWhenEncroach;
      }
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

    // Fix underwater fog
    foreach AllActors(class'ZoneInfo', ZI) {
      ZI.bClearToFogColor = True;
    }

    // add as game modifier to get OverridePickupQuery() and NotifyArenaEnd() calls
    Level.Game.AddGameModifier(Self);
  }


  // ==========================================================================
  // OverridePickupQuery
  //
  // Only players who won the last arena match, are allowed to pick up the
  // super shock rifle. Everyone else trying to pick it up will hear an
  // annoying sound.
  // ==========================================================================

  function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
  {
    // Is true if the player shouldn't pick up the super shock rifle.
    if (item != None && item.PickUpBase != None && item.PickUpBase.Name == 'xWeaponBase10'
        && Other != None && Other.PlayerReplicationInfo != None
        && class'JBTagPlayer'.static.FindFor(Other.PlayerReplicationInfo) != TagArenaWinner) {
      Other.PlaySound(Sound'MenuSounds.Denied1');
      bAllowPickup = 0;
      return true;
    }

    return Super.OverridePickupQuery(Other, item, bAllowPickup);
  }


  // ==========================================================================
  // NotifyArenaEnd
  //
  // Remember the last arena winner.
  // ==========================================================================

  function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer Winner)
  {
    if (Winner != None)
      TagArenaWinner = Winner;

    Super.NotifyArenaEnd(Arena, Winner);
  }
} // state Arlon


// ============================================================================
// state Atlantis (JB-Atlantis-Gold.ut2)
//
// Improves bot support.
// ============================================================================

state Atlantis
{
  // ============================================================================
  // BeginState
  //
  // Apply AI fixes.
  // ============================================================================

  function BeginState()
  {
    local UnrealScriptedSequence thisSequence;
    local Actor thisActor, otherActor;

    // red side
    thisActor = FindActor('PlayerStart6', class'PlayerStart');
    otherActor = FindActor('PlayerStart5', class'PlayerStart');
    CreateScriptedSequence(0.5 * (thisActor.Location + otherActor.Location), otherActor.Rotation, 'DefendBlueSwitch', 1);
    otherActor = FindActor('PlayerStart10', class'PlayerStart');
    CreateScriptedSequence(0.5 * (thisActor.Location + otherActor.Location), otherActor.Rotation, 'DefendBlueSwitch', 1);
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence1', class'UnrealScriptedSequence'));
    thisSequence.Priority = 1;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence2', class'UnrealScriptedSequence'));
    thisSequence.Priority = 1;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence6', class'UnrealScriptedSequence'));
    thisSequence.bSniping = True;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence0', class'UnrealScriptedSequence'));
    thisSequence.bSniping = True;

    // blue side
    thisActor = FindActor('PlayerStart14', class'PlayerStart');
    otherActor = FindActor('PlayerStart13', class'PlayerStart');
    CreateScriptedSequence(0.5 * (thisActor.Location + otherActor.Location), otherActor.Rotation, 'DefendRedSwitch', 1);
    otherActor = FindActor('PlayerStart46', class'PlayerStart');
    CreateScriptedSequence(0.5 * (thisActor.Location + otherActor.Location), otherActor.Rotation, 'DefendRedSwitch', 1);
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence7', class'UnrealScriptedSequence'));
    thisSequence.Priority = 1;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence8', class'UnrealScriptedSequence'));
    thisSequence.Priority = 1;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence11', class'UnrealScriptedSequence'));
    thisSequence.bSniping = True;
    thisSequence = UnrealScriptedSequence(FindActor('UnrealScriptedSequence13', class'UnrealScriptedSequence'));
    thisSequence.bSniping = True;
  }
} // state Atlantis


// ============================================================================
// state Aswan (JB-Aswan-v2.ut2)
//
// Upgrades the spider mines and improves performance optimizations.
// ============================================================================

state Aswan
{
  simulated function BeginState()
  {
    local ScriptedTrigger thisScriptedTrigger;
    local JBInfoJail thisJail;
    local Actor thisSpider;
    local bool bTemp;
    local ZoneInfo thisZone;
    local AssaultPath thisPath;
    local NavigationPoint thisNP;
    local int i;

    if (Level.NetMode != NM_Client) {
      // giant spiders
      ReplaceGiantSpider(FindActor('JBGiantSpiderMine0',     class'Actor'), class'JBGiantSpiderMine');
      ReplaceGiantSpider(FindActor('JBGiantBlueSpiderMine0', class'Actor'), class'JBGiantBlueSpiderMine');

      // temporarily disable default initial spawning
      bTemp = class'JBSpiderSpawner'.default.bInitiallyActive;
      class'JBSpiderSpawner'.default.bInitiallyActive = False;

      // red spider spawners
      foreach DynamicActors(class'Actor', thisSpider, 'RedExecutionEnd') {
        if (thisSpider.IsA('JBSpiderSpawner') && thisSpider.Class != class'JBSpiderSpawner')
          ReplaceSpiderSpawner(thisSpider);
      }
      // blue spider spawners
      foreach DynamicActors(class'Actor', thisSpider, 'BlueExecutionEnd') {
        if (thisSpider.IsA('JBSpiderSpawner') && thisSpider.Class != class'JBSpiderSpawner')
          ReplaceSpiderSpawner(thisSpider);
      }

      // reenable default initial spawning
      class'JBSpiderSpawner'.default.bInitiallyActive = bTemp;


      // set up giant spider execution as final execution
      foreach AllActors(class'JBInfoJail', thisJail) {
        if (thisJail.Tag == 'RedReleased') {
          thisJail.EventFinalExecutionCommit = 'RedGiantExecutionStart';
          thisJail.EventFinalExecutionEnd = 'RedExecutionEnd';
        }
        else {
          thisJail.EventFinalExecutionCommit = 'BlueGiantExecutionStart';
          thisJail.EventFinalExecutionEnd = 'BlueExecutionEnd';
        }
        thisJail.FinalExecutionDelayFallback = 20.0;
      }
      PickExecution();

      // red regular execution
      thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger26', class'ScriptedTrigger'));
      thisScriptedTrigger.Actions.Remove(2, 4);

      // blue regular execution
      thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger29', class'ScriptedTrigger'));
      thisScriptedTrigger.Actions.Remove(2, 4);

      // red giant spider execution
      thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger32', class'ScriptedTrigger'));
      ACTION_WaitForEvent(thisScriptedTrigger.Actions[0]).ExternalEvent = 'RedGiantExecutionStart';
      thisScriptedTrigger.Actions.Insert(1, 2);
      thisScriptedTrigger.Actions[1] = NewTriggerEvent(thisScriptedTrigger, 'RedExecutionInProgress');
      thisScriptedTrigger.Actions[2] = NewTriggerEvent(thisScriptedTrigger, 'RedGiantSpider');
      thisScriptedTrigger.Actions.Insert(6, 2);
      /*
      TODO: This might be a bit fragile when players immediately die after
      the giant spider execution started
      */
      thisScriptedTrigger.Actions[6] = NewWaitForEvent(thisScriptedTrigger, 'RedExecutionEnd');
      thisScriptedTrigger.Actions[7] = NewTriggerEvent(thisScriptedTrigger, 'RedExecutionInProgress');

      // blue giant spider execution
      thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger35', class'ScriptedTrigger'));
      ACTION_WaitForEvent(thisScriptedTrigger.Actions[0]).ExternalEvent = 'BlueGiantExecutionStart';
      thisScriptedTrigger.Actions.Insert(1, 2);
      thisScriptedTrigger.Actions[1] = NewTriggerEvent(thisScriptedTrigger, 'BlueExecutionInProgress');
      thisScriptedTrigger.Actions[2] = NewTriggerEvent(thisScriptedTrigger, 'BlueGiantSpider');
      thisScriptedTrigger.Actions.Insert(6, 2);
      // TODO: (See above.)
      thisScriptedTrigger.Actions[6] = NewWaitForEvent(thisScriptedTrigger, 'BlueExecutionEnd');
      thisScriptedTrigger.Actions[7] = NewTriggerEvent(thisScriptedTrigger, 'BlueExecutionInProgress');

      // add as game modifier to get NotifyExecutionEnd() calls
      Level.Game.AddGameModifier(Self);


      // tweak assault path priorities (bots use the lift too much)
      foreach AllActors(class'AssaultPath', thisPath) {
        if (thisPath.Position == 1) {
          switch (thisPath.PathTag[0]) {
            case 'Left':
              thisPath.Priority = 0.1;
              break;
            case 'Right':
              thisPath.Priority = 0.15;
              break;
            case 'LeftLift':
              thisPath.Priority = 0.55;
              break;
          }
        }
      }

      // turn off problematic path reachspecs where bots are likely to fail
      thisNP = NavigationPoint(FindActor('PathNode30', class'PathNode'));
      for (i = 0; i < thisNP.PathList.Length; i++) {
        if (thisNP.PathList[i].End.Name == 'InventorySpot287') {
          thisNP.PathList[i].reachFlags = 128; // R_PROSCRIBED
          break;
        }
      }
      thisNP = NavigationPoint(FindActor('PathNode31', class'PathNode'));
      for (i = 0; i < thisNP.PathList.Length; i++) {
        if (thisNP.PathList[i].End.Name == 'InventorySpot282') {
          thisNP.PathList[i].reachFlags = 128; // R_PROSCRIBED
          break;
        }
      }
      thisNP = NavigationPoint(FindActor('PathNode111', class'PathNode'));
      for (i = 0; i < thisNP.PathList.Length; i++) {
        if (thisNP.PathList[i].End.Name == 'InventorySpot272') {
          thisNP.PathList[i].reachFlags = 128; // R_PROSCRIBED
          break;
        }
      }
      thisNP = NavigationPoint(FindActor('PathNode117', class'PathNode'));
      for (i = 0; i < thisNP.PathList.Length; i++) {
        if (thisNP.PathList[i].End.Name == 'InventorySpot277') {
          thisNP.PathList[i].reachFlags = 128; // R_PROSCRIBED
          break;
        }
      }

      // bots might get stuck here, so scare them away
      CreateFearSpot(vect(-672,-3696,-1014),40,10);
      CreateFearSpot(vect( 672,-3696,-1014),40,10);
      CreateFearSpot(vect(-672, 3696,-1014),40,10);
      CreateFearSpot(vect( 672, 3696,-1014),40,10);
    }

    // some performance improvements:
    if (Level.NetMode != NM_DedicatedServer) {
      // Cull distance for the back room light boxes
      FindActor('StaticMeshActor79',  class'StaticMeshActor').CullDistance = 4000.0;
      FindActor('StaticMeshActor114', class'StaticMeshActor').CullDistance = 4000.0;

      // Arena is lonely zone (not connected to others and no skyzone)
      ZoneInfo(FindActor('ZoneInfo23', class'ZoneInfo')).bLonelyZone = True;

      // fix minor HOM when viewing from back room to back room (exceeds distance fog end)
      ZoneInfo(FindActor('ZoneInfo1', class'ZoneInfo')).DistanceFogEnd = 10000.0;
      ZoneInfo(FindActor('ZoneInfo2', class'ZoneInfo')).DistanceFogEnd = 10000.0;

      // Manual excludes:
      thisZone = ZoneInfo(FindActor('ZoneInfo9', class'ZoneInfo')); // BlueEntryUpper
      thisZone.DistanceFogEnd = 9000.0; // better transition to the default 8000 DistanceFogEnd
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo17', class'ZoneInfo')); // blue backroom entry (RL)
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo18', class'ZoneInfo')); // blue backroom entry (Flak)
      thisZone.ManualExcludes[2] = ZoneInfo(FindActor('ZoneInfo5', class'ZoneInfo'));  // red Flak
      thisZone.ManualExcludes[3] = ZoneInfo(FindActor('ZoneInfo6', class'ZoneInfo'));  // red RL

      thisZone = ZoneInfo(FindActor('ZoneInfo10', class'ZoneInfo')); // RedEntryUpper
      thisZone.DistanceFogEnd = 9000.0; // better transition to the default 8000 DistanceFogEnd
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo16', class'ZoneInfo')); // red backroom entry (RL)
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo19', class'ZoneInfo')); // red backroom entry (Flak)
      thisZone.ManualExcludes[2] = ZoneInfo(FindActor('ZoneInfo3', class'ZoneInfo'));  // blue Flak
      thisZone.ManualExcludes[3] = ZoneInfo(FindActor('ZoneInfo4', class'ZoneInfo'));  // blue RL

      thisZone = ZoneInfo(FindActor('ZoneInfo17', class'ZoneInfo')); // blue backroom entry (RL)
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo9', class'ZoneInfo')); // BlueEntryUpper
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo0', class'ZoneInfo')); // outside

      thisZone = ZoneInfo(FindActor('ZoneInfo18', class'ZoneInfo')); // blue backroom entry (Flak)
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo9', class'ZoneInfo')); // BlueEntryUpper
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo0', class'ZoneInfo')); // outside

      thisZone = ZoneInfo(FindActor('ZoneInfo16', class'ZoneInfo')); // red backroom entry (RL)
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo10', class'ZoneInfo')); // RedEntryUpper
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo0', class'ZoneInfo')); // outside

      thisZone = ZoneInfo(FindActor('ZoneInfo19', class'ZoneInfo')); // red backroom entry (Flak)
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo10', class'ZoneInfo')); // RedEntryUpper
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo0', class'ZoneInfo')); // outside

      thisZone = ZoneInfo(FindActor('ZoneInfo4', class'ZoneInfo')); // blue RL
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo5', class'ZoneInfo')); // red Flak

      thisZone = ZoneInfo(FindActor('ZoneInfo3', class'ZoneInfo')); // blue Flak
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo6', class'ZoneInfo')); // red RL

      thisZone = ZoneInfo(FindActor('ZoneInfo6', class'ZoneInfo')); // red RL
      thisZone.ManualExcludes[1] = ZoneInfo(FindActor('ZoneInfo3', class'ZoneInfo')); // blue Flak

      thisZone = ZoneInfo(FindActor('ZoneInfo5', class'ZoneInfo')); // red Flak
      thisZone.ManualExcludes[0] = ZoneInfo(FindActor('ZoneInfo4', class'ZoneInfo')); // blue RL
    }
  }


  // ============================================================================
  // NotifyExecutionEnd
  //
  // After each round, randomly pick the next execution.
  // ============================================================================

  function NotifyExecutionEnd()
  {
    Super.NotifyExecutionEnd();

    PickExecution();
  }

  function PickExecution()
  {
    local bool bUseGiantSpiderExecution;
    local JBInfoJail thisJail;

    bUseGiantSpiderExecution = SelectExecution(4, 1);

    // update red jail execution
    thisJail = JBInfoJail(FindActor('JBInfoJail1', class'JBInfoJail'));
    if (bUseGiantSpiderExecution)
      thisJail.EventExecutionCommit = 'RedGiantExecutionStart';
    else
      thisJail.EventExecutionCommit = 'RedExecutionStart';

    // update blue jail execution
    thisJail = JBInfoJail(FindActor('JBInfoJail0', class'JBInfoJail'));
    if (bUseGiantSpiderExecution)
      thisJail.EventExecutionCommit = 'BlueGiantExecutionStart';
    else
      thisJail.EventExecutionCommit = 'BlueExecutionStart';
  }
}


// ============================================================================
// state BabylonTemple (JB-BabylonTemple-Gold.ut2)
//
// Adds a fiery spirit execution.
// ============================================================================

state BabylonTemple
{
  // ==========================================================================
  // BeginState
  //
  // Replace the default execution with fire spirits.
  // ==========================================================================

  function BeginState()
  {
    local ScriptedTrigger thisScriptedTrigger;
    local JBInfoJail thisJail;

    // Create a SpiritSpawner for the red jail.
    CreateSpiritSpawner('redspirit', vect(-40, -4488, -7828), rot(-4096, 16384, 0), class'JBFireSpirit', 2, 0.3);

    // Create a SpiritSpawner for the blue jail.
    CreateSpiritSpawner('bluespirit', vect(40, 4488, -7828), rot(-4096, -16384, 0), class'JBFireSpirit', 2, 0.3);

    foreach AllActors(class'JBInfoJail', thisJail) {
      if (thisJail.Tag == 'RedJail')
        thisJail.EventExecutionCommit = 'redspirit';
      else
        thisJail.EventExecutionCommit = 'bluespirit';

      thisJail.EventExecutionEnd = '';
      thisJail.ExecutionDelayCommit = 1.0;
      thisJail.ExecutionDelayFallback = 10.0;
    }

    // delay the evil laugh
    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger0', class'ScriptedTrigger'));
    ACTION_WaitForEvent(thisScriptedTrigger.Actions[0]).ExternalEvent = 'bluespirit';
    thisScriptedTrigger.Actions.Insert(1, 1);
    thisScriptedTrigger.Actions[1] = NewWaitForTimer(thisScriptedTrigger, 2.0);

    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger1', class'ScriptedTrigger'));
    ACTION_WaitForEvent(thisScriptedTrigger.Actions[0]).ExternalEvent = 'redspirit';
    thisScriptedTrigger.Actions.Insert(1, 1);
    thisScriptedTrigger.Actions[1] = NewWaitForTimer(thisScriptedTrigger, 2.0);
  }
} // state BabylonTemple


// ============================================================================
// state Collateral (JB-Collateral.ut2)
//
// Fixes a Volume's LocationName.
// ============================================================================

state Collateral
{
  simulated function BeginState()
  {
    local Volume V;

    V = Volume(FindActor('Volume4', class'Volume'));
    ReplaceText(V.LocationName, "Red", "Blue");
  }
}


// ============================================================================
// state Cosmos (JB-Cosmos.ut2)
//
// Fixes the breaking glas emitters.
// ============================================================================

state Cosmos
{
  simulated function BeginState()
  {
    local JBEmitterClientTriggerable E;
    local name NewTag;

    foreach AllActors(class'JBEmitterClientTriggerable', E) {
      if (E.Class.Name == 'JBEmitterClientTriggerableGlassSpawner') {
        // spawn fixed emitter
        if (E.Tag == 'BlueGlass')
          NewTag = 'BlueGlassSound';
        else
          NewTag = 'RedGlassSound';
        Spawn(class'JBEmitterCosmosBreakingGlass', None, NewTag, E.Location, E.Rotation);
        E.Tag = ''; // disable broken emitter
      }
    }
  }
}


// ============================================================================
// state Frostbite (JB-Frostbite.ut2)
//
// Adds an ice spirit execution.
// ============================================================================

state Frostbite
{
  // ==========================================================================
  // BeginState
  //
  // Replace the default execution with fire spirits.
  // ==========================================================================

  function BeginState()
  {
    local JBInfoJail thisJail;

    // Create SpiritSpawners for the red jail.
    CreateSpiritSpawner('redspirit', vect(-312,  64, -432), rot(0, -33792, 0), class'JBIceSpirit', 1, 0.3, 750.0);
    CreateSpiritSpawner('redspirit', vect(-312, -32, -432), rot(0, -31744, 0), class'JBIceSpirit', 1, 0.5, 750.0);

    // Create a SpiritSpawner for the blue jail.
    CreateSpiritSpawner('bluespirit', vect(6080, -6460, -432), rot(0, -17408, 0), class'JBIceSpirit', 1, 0.3, 750.0);
    CreateSpiritSpawner('bluespirit', vect(6178, -6460, -432), rot(0, -15360, 0), class'JBIceSpirit', 1, 0.5, 750.0);

    foreach AllActors(class'JBInfoJail', thisJail) {
      if (thisJail.Tag == 'RedJBInfoJail')
        thisJail.EventFinalExecutionCommit = 'redspirit';
      else
        thisJail.EventFinalExecutionCommit = 'bluespirit';

      thisJail.FinalExecutionDelayFallback = 10;
    }

    PickExecution();

    // add as game modifier to get NotifyExecutionEnd() calls
    Level.Game.AddGameModifier(Self);
  }


  // ============================================================================
  // NotifyExecutionEnd
  //
  // After each round, randomly pick the next execution.
  // ============================================================================

  function NotifyExecutionEnd()
  {
    Super.NotifyExecutionEnd();

    PickExecution();
  }

  function PickExecution()
  {
    local bool bUseSpiritExecution;
    local JBInfoJail thisJail;

    bUseSpiritExecution = SelectExecution(2, 1);

    // update red jail execution
    thisJail = JBInfoJail(FindActor('JBInfoJail0', class'JBInfoJail'));
    if (bUseSpiritExecution) {
      thisJail.EventExecutionCommit = 'redspirit';
      thisJail.ExecutionDelayFallback = 10;
    }
    else {
      thisJail.EventExecutionCommit = 'RedJailLift';
      thisJail.ExecutionDelayFallback = 7;
    }

    // update blue jail execution
    thisJail = JBInfoJail(FindActor('JBInfoJail2', class'JBInfoJail'));
    if (bUseSpiritExecution) {
      thisJail.EventExecutionCommit = 'bluespirit';
      thisJail.ExecutionDelayFallback = 10;
    }
    else {
      thisJail.EventExecutionCommit = 'BlueJailLift';
      thisJail.ExecutionDelayFallback = 7;
    }
  }
} // state Frostbite


// ============================================================================
// state Heights (JB-Heights-Gold-v2.ut2)
//
// Adds a shocking spirit execution and fixes lift cranes.
// ============================================================================

state Heights
{
  simulated function BeginState()
  {
    local Mover thisMover;
    local ScriptedTrigger thisScriptedTrigger;
    local JBInfoJail thisJail;

    // Fix the crane elevators.
    foreach AllActors(class'Mover', thisMover) {
      switch (thisMover.Name) {
        // red crane
        case 'Mover0':
        case 'Mover1':
          thisMover.Tag = 'Mover';
          thisMover.ReturnGroup = 'red_crane';
          thisMover.InitialState = 'TriggerControl';
          break;
        case 'Mover2':
          thisMover.ReturnGroup = 'red_crane';
          thisMover.bIsLeader = True;
          thisMover.ClosedEvent = 'red_crane_finished';
          break;

        // blue crane
        case 'Mover3':
        case 'Mover4':
          thisMover.Tag = 'Mover';
          thisMover.ReturnGroup = 'blue_crane';
          thisMover.InitialState = 'TriggerControl';
          break;
        case 'Mover6':
          thisMover.ReturnGroup = 'blue_crane';
          thisMover.bIsLeader = True;
          thisMover.ClosedEvent = 'blue_crane_finished';
          break;

        // red lift
        case 'Mover9':
          thisMover.Tag = 'Mover';
          thisMover.ReturnGroup = 'redlift';
          thisMover.InitialState = 'TriggerControl';
        case 'Mover10':
          thisMover.ReturnGroup = 'redlift';
          thisMover.bIsLeader = True;
          thisMover.ClosedEvent = 'redlift_finished';
          break;

        // blue lift
        case 'Mover5':
          thisMover.Tag = 'Mover';
          thisMover.ReturnGroup = 'bluelift';
          thisMover.InitialState = 'TriggerControl';
        case 'Mover7':
          thisMover.ReturnGroup = 'bluelift';
          thisMover.bIsLeader = True;
          thisMover.ClosedEvent = 'bluelift_finished';
          break;

        // helicopter (rotation fix)
        case 'Mover8':
          thisMover.bUseShortestRotation = True;
          break;
      }
    }
    // red crane script
    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger9', class'ScriptedTrigger'));
    thisScriptedTrigger.Actions.Remove(3, 2); // now handled through return groups
    thisScriptedTrigger.Actions[7] = NewWaitForEvent(thisScriptedTrigger, 'red_crane_finished');

    // blue crane script
    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger5', class'ScriptedTrigger'));
    thisScriptedTrigger.Actions.Remove(3, 2); // now handled through return groups
    thisScriptedTrigger.Actions[7] = NewWaitForEvent(thisScriptedTrigger, 'blue_crane_finished');

    // red lift script
    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger11', class'ScriptedTrigger'));
    thisScriptedTrigger.Actions.Remove(3, 2); // now handled through return groups
    thisScriptedTrigger.Actions[3] = NewWaitForEvent(thisScriptedTrigger, 'redlift_finished');

    // blue lift script
    thisScriptedTrigger = ScriptedTrigger(FindActor('ScriptedTrigger10', class'ScriptedTrigger'));
    thisScriptedTrigger.Actions.Remove(3, 2); // now handled through return groups
    thisScriptedTrigger.Actions[3] = NewWaitForEvent(thisScriptedTrigger, 'bluelift_finished');

    // add spirit execution
    foreach AllActors(class'JBInfoJail', thisJail) {
      if (thisJail.Tag == 'RedJail')
        thisJail.EventExecutionCommit = 'redspirit';
      else
        thisJail.EventExecutionCommit = 'bluespirit';
      thisJail.ExecutionDelayCommit = 1.0;
      thisJail.ExecutionDelayFallback = 10.0;
    }

    if (Level.NetMode != NM_Client) {
      // Create two SpiritSpawners for the red jail.
      CreateSpiritSpawner('redspirit', vect(1024, -1396, -1916), rot(-16384, 0, 0), class'JBThunderSpirit', 1, 0.3);
      CreateSpiritSpawner('redspirit', vect(1024,  -428, -1916), rot(-16384, 0, 0), class'JBThunderSpirit', 1, 0.3);

      // Create two SpiritSpawners for the blue jail.
      CreateSpiritSpawner('bluespirit', vect(1024,  484, -1916), rot(-16384, 0, 0), class'JBThunderSpirit', 1, 0.3);
      CreateSpiritSpawner('bluespirit', vect(1024, 1524, -1916), rot(-16384, 0, 0), class'JBThunderSpirit', 1, 0.3);
    }
  }
} // state Heights


// ============================================================================
// state IndusRage (JB-IndusRage2-Gold.ut2)
//
// Fixes the HOM caused by a wrong setting in all ZoneInfos.
// ============================================================================

state IndusRage
{
  simulated function BeginState()
  {
    local ZoneInfo Z;
    local StaticMeshActor SMA;

    // fix HOM
    foreach AllActors(class'ZoneInfo', Z) {
      Z.bClearToFogColor = True;
    }

    // fix disappearing door frames and pipe thingies
    foreach AllActors(class'StaticMeshActor', SMA) {
      if (SMA.StaticMesh.Name == 'Indus_DoorFrame' || SMA.StaticMesh.Name == 'indus_slinky_pipe')
        SMA.CullDistance = 0;
    }
  }
}


// ============================================================================
// state Poseidon (JB-Poseidon-Gold.ut2)
//
// Spawn blocking actors to prevent players from getting stuck on the lift.
// Also apply various visual fixes.
// ============================================================================

state Poseidon
{
  simulated function BeginState()
  {
    local Actor A;
    local Texture T;

    // fill red lift gaps
    CreateBlockPlayer(vect(   0,  1208, -48), 54, 176);
    CreateBlockPlayer(vect(  82,  1244, -48), 38, 176);
    CreateBlockPlayer(vect( -82,  1244, -48), 38, 176);
    CreateBlockPlayer(vect( 124,  1286, -48), 32, 176);
    CreateBlockPlayer(vect(-124,  1286, -48), 32, 176);

    // fill blue lift gaps
    CreateBlockPlayer(vect(   0, -1208, -48), 54, 176);
    CreateBlockPlayer(vect(  82, -1244, -48), 38, 176);
    CreateBlockPlayer(vect( -82, -1244, -48), 38, 176);
    CreateBlockPlayer(vect( 124, -1286, -48), 32, 176);
    CreateBlockPlayer(vect(-124, -1286, -48), 32, 176);

    // fix unlit shark
    A = FindActor('Shark4', class'Decoration');
    if (A != None) {
      A.AmbientGlow = 16;
    }

    // sort-of fix skybox
    T = Texture(FindObject("CheckerFX.Skybox.IceEast", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
    T = Texture(FindObject("CheckerFX.Skybox.IceNorth", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
    T = Texture(FindObject("CheckerFX.Skybox.IceWest", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
    T = Texture(FindObject("CheckerFX.Skybox.IceSouth", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
    T = Texture(FindObject("CheckerFX.Skybox.IceFloor", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
    T = Texture(FindObject("CheckerFX.Skybox.IceRoof", class'Texture'));
    if (T != None) {
      T.UClampMode = TC_Wrap;
      T.VClampMode = TC_Wrap;
    }
  }
}


// ============================================================================
// ReplaceGiantSpider
//
// Replaces a giant spider mine.
// ============================================================================

final function ReplaceGiantSpider(Actor OldSpider, class<JBGiantSpiderMine> NewClass)
{
  local JBGiantSpiderMine NewSpider;

  // spawn a new spawner
  NewSpider = Spawn(NewClass, None, OldSpider.Tag, OldSpider.Location, OldSpider.Rotation);
  NewSpider.SetPropertyText("PreExplosionEvent", OldSpider.GetPropertyText("PreExplosionEvent"));
  NewSpider.Event = OldSpider.Event;
  NewSpider.SoundVolume = OldSpider.SoundVolume;
  NewSpider.SoundRadius = OldSpider.SoundRadius;
  NewSpider.SoundPitch  = OldSpider.SoundPitch;
  NewSpider.TransientSoundVolume = OldSpider.TransientSoundVolume;
  NewSpider.TransientSoundRadius = OldSpider.TransientSoundRadius;

  // destroy old spider
  OldSpider.Destroy();
}


// ============================================================================
// ReplaceSpiderSpawner
//
// Replaces a spider spawner.
// ============================================================================

final function ReplaceSpiderSpawner(Actor OldSpawner)
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

final function CreateSpiritSpawner(name SpawnerTag, vector SpawnerLocation, rotator SpawnerRotation,
class<JBSpirit> SpiritClass, int SpiritCount, float SpiritSpawnDelay, optional float SpiritSpeed)
{
  local JBSpiritSpawner SpiritSpawner;

  SpiritSpawner = Spawn(class'JBSpiritSpawner',, SpawnerTag,  SpawnerLocation, SpawnerRotation);

  SpiritSpawner.SpiritClass      = SpiritClass;
  SpiritSpawner.SpiritCount      = SpiritCount;
  SpiritSpawner.SpiritSpawnDelay = SpiritSpawnDelay;
  if (SpiritSpeed > 0)
    SpiritSpawner.SpiritSpeed = SpiritSpeed;
}


// ============================================================================
// CreateBlockPlayer
//
// Creates a cylinder that blocks players.
// ============================================================================

final function CreateBlockPlayer(vector BlockLocation, float BlockRadius, float BlockHeight, optional ESurfaceTypes BlockSurface)
{
  local ShootTarget Blocker;

  // we need a spawnable class available to old clients that doesn't have any effects by default
  Blocker = Spawn(class'ShootTarget',, '',  BlockLocation);
  Blocker.RemoteRole      = ROLE_DumbProxy;
  Blocker.bAlwaysRelevant = True;

  Blocker.SetCollisionSize(BlockRadius, BlockHeight);
  Blocker.SetCollision(True, True, True);
  Blocker.bWorldGeometry            = True;
  Blocker.bProjTarget               = False;
  Blocker.bBlockZeroExtentTraces    = False;
  Blocker.bBlockNonZeroExtentTraces = True;
  Blocker.SurfaceType               = BlockSurface;
}


// ============================================================================
// CreateFearSpot
//
// Creates a a fear spot for bots to avoid.
// ============================================================================

final function CreateFearSpot(vector FearLocation, float FearRadius, float FearHeight)
{
  local AvoidMarker FearSpot;

  FearSpot = Spawn(class'AvoidMarker',, '',  FearLocation);
  FearSpot.SetCollisionSize(FearRadius, FearHeight);
}


// ============================================================================
// CreateScriptedSequence
//
// Creates a scripted sequence, e.g. a defense point.
// ============================================================================

final function JBDynamicScriptedSequence CreateScriptedSequence(vector SequenceLocation, rotator SequenceRotation, name SequenceTag, byte SequencePriority)
{
  local JBDynamicScriptedSequence Seq;

  Seq = Spawn(class'JBDynamicScriptedSequence',,  SequenceTag, SequenceLocation, SequenceRotation);
  Seq.Priority = SequencePriority;

  return Seq;
}


// ============================================================================
// SelectExecution
//
// Randomly selects an execution. Returns whether the alternate execution
// should be used.
// ============================================================================

final function bool SelectExecution(int RatioRegular, int RatioAlternate)
{
  if (Rand(CountExecutionRegular + CountExecutionAlternate) >= CountExecutionRegular) {
    // alternate execution (make regular one more probably for next selection)
    CountExecutionRegular += RatioRegular;
    return true;
  }
  // else regular execution (make alternate one more probably for next selection)
  CountExecutionAlternate += RatioAlternate;
  return false;
}


// ============================================================================
// FindActor
//
// Finds an Actor by name.
// ============================================================================

simulated final function Actor FindActor(name ActorName, class<Actor> ActorClass)
{
  return Actor(FindObject(Outer $ "." $ ActorName, ActorClass));
}


// ============================================================================
// NewWaitForEvent
//
// Creates a new WaitForEvent action.
// ============================================================================

final function ACTION_WaitForEvent NewWaitForEvent(ScriptedSequence Parent, name ExternalEvent)
{
  local ACTION_WaitForEvent action;

  action = new(Parent) class'ACTION_WaitForEvent';
  action.ExternalEvent = ExternalEvent;
  return action;
}


// ============================================================================
// NewTriggerEvent
//
// Creates a new TriggerEvent action.
// ============================================================================

final function ACTION_TriggerEvent NewTriggerEvent(ScriptedSequence Parent, name EventName)
{
  local ACTION_TriggerEvent action;

  action = new(Parent) class'ACTION_TriggerEvent';
  action.Event = EventName;
  return action;
}


// ============================================================================
// NewWaitForTimer
//
// Creates a new WaitForTimer action.
// ============================================================================

final function ACTION_WaitForTimer NewWaitForTimer(ScriptedSequence Parent, float PauseTime)
{
  local ACTION_WaitForTimer action;

  action = new(Parent) class'ACTION_WaitForTimer';
  action.PauseTime = PauseTime;
  return action;
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  RemoteRole = ROLE_SimulatedProxy
  bAlwaysRelevant = True

  CountExecutionRegular   = 1
  CountExecutionAlternate = 1
}