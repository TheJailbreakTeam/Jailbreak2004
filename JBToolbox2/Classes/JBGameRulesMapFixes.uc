// ============================================================================
// JBGameRulesMapFixes
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Fixes small bugs in maps that are not worth another release and adds a
// Spirit execution in some cases.
// ============================================================================


class JBGameRulesMapFixes extends JBGameRules
  NotPlaceable
  HideDropDown;


// ============================================================================
// Variables
// ============================================================================

var JBTagPlayer TagArenaWinner;

// Random execution details
var JBInfoJail RedJail, BlueJail;
var Name RedInit, RedCommit, RedEnd, BlueInit, BlueCommit, BlueEnd;
var float RedDelayCommit, RedDelayFallback, BlueDelayCommit, BlueDelayFallback;

var int OriginalCount, SpiritCount;


// ============================================================================
// SetInitialState
//
// Sets the correct state depending on the current map.
// ============================================================================

simulated event SetInitialState()
{
	Super.SetInitialState();

  switch (class'JBMapFixes'.static.GetJBMapName(Level)) {
    case "jb-arlon-gold":         GotoState('Arlon');         break;
    case "jb-babylontemple-gold": GotoState('BabylonTemple'); break;
    case "jb-heights-gold-v2":    GotoState('Heights');       break;
    case "jb-collateral":         GotoState('Collateral');    break;
  }
}


// ============================================================================
// state Arlon (JB-Arlon-Gold.ut2)
//
// Fixes various bugs in this map.
// ============================================================================

state Arlon
{
  // ============================================================================
  // OverridePickupQuery
  //
  // Only players who won the last arena match, are allowed to pick up the super
  // shock rifle. Everyone else trying to pick it up will hear an annoying sound.
  // ============================================================================

  function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
  {
    // Is true if the player shouldn't pick up the super shock rifle.
    if (item != None &&
        item.PickUpBase != None &&
        item.PickUpBase.Name == 'xWeaponBase10' &&
        Other != None &&
        Other.PlayerReplicationInfo != None &&
        class'JBTagPlayer'.static.FindFor(Other.PlayerReplicationInfo) != TagArenaWinner) {
      Other.PlaySound(Sound'MenuSounds.Denied1');
      bAllowPickup = 0;
      return true;
    }

    return Super.OverridePickupQuery(Other, item, bAllowPickup);
  }


  // ============================================================================
  // NotifyArenaEnd
  //
  // Remember the last arena winner.
  // ============================================================================

  function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer Winner)
  {
    if (Winner != None)
      TagArenaWinner = Winner;
  }
} // state Arlon


// ============================================================================
// state BabylonTemple (JB-BabylonTemple-Gold.ut2)
//
// Adds a fiery spirit execution.
// ============================================================================

state BabylonTemple
{
  // ============================================================================
  // BeginState
  //
  // Start by randomly picking the first execution.
  // ============================================================================

  function BeginState()
  {
    local JBInfoJail thisJail;

    // Find and set the JBInfoJails.
    for (thisJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail; thisJail != None; thisJail = thisJail.nextJail)
      switch (thisJail.Name) {
        case 'JBInfoJail0': RedJail  = thisJail; break;
        case 'JBInfoJail1': BlueJail = thisJail; break;
      }

    // Remember the original settings, so the original execution can be played again.
    RememberInitialSetup();

    // Pick an initial execution.
    SetRandomExecution();
  }


  // ============================================================================
  // NotifyExecutionEnd
  //
  // After each round, randomly pick the next execution.
  // ============================================================================

  function NotifyExecutionEnd()
  {
    Super.NotifyExecutionEnd();

    SetRandomExecution();
  }
} // state BabylonTemple


// ============================================================================
// state Heights (JB-Heights-Gold-v2.ut2)
//
// Adds a shocking spirit execution.
// ============================================================================

state Heights
{
  // ============================================================================
  // BeginState
  //
  // Start by randomly picking the first execution.
  // ============================================================================

  function BeginState()
  {
    local JBInfoJail thisJail;

    // Find and set the JBInfoJails.
    for (thisJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail; thisJail != None; thisJail = thisJail.nextJail)
      switch (thisJail.Name) {
        case 'JBInfoJail0': RedJail  = thisJail; break;
        case 'JBInfoJail1': BlueJail = thisJail; break;
      }

    // Remember the original settings, so the original execution can be played again.
    RememberInitialSetup();

    // Pick an initial execution.
    SetRandomExecution();
  }


  // ============================================================================
  // NotifyExecutionEnd
  //
  // After each round, randomly pick the next execution.
  // ============================================================================

  function NotifyExecutionEnd()
  {
    Super.NotifyExecutionEnd();

    SetRandomExecution();
  }
} // state Heights


// ============================================================================
// state Collateral (JB-Collateral.ut2)
//
// Adds a shocking spirit execution.
// ============================================================================

state Collateral
{
  // ============================================================================
  // BeginState
  //
  // Start by randomly picking the first execution.
  // ============================================================================

  function BeginState()
  {
    local JBInfoJail thisJail;

    // Find and set the JBInfoJails.
    for (thisJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail; thisJail != None; thisJail = thisJail.nextJail)
      switch (thisJail.Name) {
        case 'JBInfoJail2': RedJail  = thisJail; break;
        case 'JBInfoJail1': BlueJail = thisJail; break;
      }

    // Remember the original settings, so the original execution can be played again.
    RememberInitialSetup();

    // Pick an initial execution.
    SetRandomExecution();
  }


  // ============================================================================
  // NotifyExecutionEnd
  //
  // After each round, randomly pick the next execution.
  // ============================================================================

  function NotifyExecutionEnd()
  {
    Super.NotifyExecutionEnd();

    SetRandomExecution();
  }
} // state Collateral


// ============================================================================
// RememberInitialSetup
//
// Remembers the original settings in JBInfoJail, set by the mapper.
// ============================================================================

function RememberInitialSetup()
{
  RedInit           = RedJail.EventExecutionInit;
  RedCommit         = RedJail.EventExecutionCommit;
  RedEnd            = RedJail.EventExecutionEnd;
  RedDelayCommit    = RedJail.ExecutionDelayCommit ;
  RedDelayFallback  = RedJail.ExecutionDelayFallback;

  BlueInit          = BlueJail.EventExecutionInit;
  BlueCommit        = BlueJail.EventExecutionCommit;
  BlueEnd           = BlueJail.EventExecutionEnd;
  BlueDelayCommit   = BlueJail.ExecutionDelayCommit;
  BlueDelayFallback = BlueJail.ExecutionDelayFallback;
}


// ============================================================================
// SetRandomExecution
//
// Picks a random execution, and sets the proper variables in the JBInfoJail.
// ============================================================================

function SetRandomExecution()
{
  local int randInt;

  // The more often one execution gets chosen, the higher the chance the other will be picked next time.
  // This will try to make both executions be played an equal number of times, but maintain the randomness.
  randInt = Rand(OriginalCount + SpiritCount);

  if (randInt < SpiritCount) {
    RedJail.EventExecutionInit      = RedInit;
    RedJail.EventExecutionCommit    = RedCommit;
    RedJail.EventExecutionEnd       = RedEnd;
    RedJail.ExecutionDelayCommit    = RedDelayCommit;
    RedJail.ExecutionDelayFallback  = RedDelayFallback;

    BlueJail.EventExecutionInit     = BlueInit;
    BlueJail.EventExecutionCommit   = BlueCommit;
    BlueJail.EventExecutionEnd      = BlueEnd;
    BlueJail.ExecutionDelayCommit   = BlueDelayCommit;
    BlueJail.ExecutionDelayFallback = BlueDelayFallback;

    OriginalCount++;
  } else {
    RedJail.EventExecutionInit      = '';
    RedJail.EventExecutionCommit    = 'redspirit';
    RedJail.EventExecutionEnd       = '';
    RedJail.ExecutionDelayCommit    = 1;
    RedJail.ExecutionDelayFallback  = 10;

    BlueJail.EventExecutionInit     = '';
    BlueJail.EventExecutionCommit   = 'bluespirit';
    BlueJail.EventExecutionEnd      = '';
    BlueJail.ExecutionDelayCommit   = 1;
    BlueJail.ExecutionDelayFallback = 10;

    SpiritCount++;
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  // prevent divide-by-0 errors
  OriginalCount = 1
  SpiritCount   = 1
}