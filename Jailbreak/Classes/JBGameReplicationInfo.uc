// ============================================================================
// JBReplicationInfoGame
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoGame.uc,v 1.3 2002/11/20 22:56:50 mychaeel Exp $
//
// Replicated information for a the entire game.
// ============================================================================


class JBReplicationInfoGame extends GameReplicationInfo
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var array<JBInfoArena> ListInfoArena;
var array<JBInfoJail> ListInfoJail;

var array<JBReplicationInfoPlayer> ListInfoPlayer;


// ============================================================================
// PostBeginPlay
//
// Gives every GameObjective a JBInventoryObjective item.
// ============================================================================

event PostBeginPlay() {

  local GameObjective thisObjective;

  foreach AllActors(Class'GameObjective', thisObjective)
    Class'JBInventoryObjective'.Static.SpawnFor(thisObjective);
  }


// ============================================================================
// PostNetBeginPlay
//
// Initializes the ListInfoArena and ListInfoJail arrays.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBInfoArena thisArena;
  local JBInfoJail thisJail;
  
  Level.GRI = Self;  // for convenience
  
  foreach DynamicActors(Class'JBInfoArena', thisArena)
    ListInfoArena[ListInfoArena.Length] = thisArena;
  
  foreach DynamicActors(Class'JBInfoJail', thisJail)
    ListInfoJail[ListInfoJail.Length] = thisJail;
  }
