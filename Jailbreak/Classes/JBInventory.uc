// ============================================================================
// JBInventory
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Generic inventory item. Not intended for use by players, but used to
// associate arbitrary information with any actor in subclasses of this class.
// ============================================================================


class JBInventory extends Inventory
  abstract
  notplaceable;


// ============================================================================
// FindFor
//
// Finds and returns the inventory item of the class this function is called
// for. If no inventory is found, returns None.
// ============================================================================

static function JBInventory FindFor(Actor Actor, optional bool bCreate) {

  local Inventory thisInventory;
  
  for (thisInventory = Actor.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
    if (thisInventory.Class == Default.Class)
      return JBInventory(thisInventory);
  
  if (bCreate)
    return SpawnFor(Actor);
  
  return None;
  }


// ============================================================================
// SpawnFor
//
// Spawns an inventory item for the given actor and returns a reference to it.
// If an inventory item of this type already exists, returns that.
// ============================================================================

static function JBInventory SpawnFor(Actor Actor) {

  local JBInventory InventorySpawned;
  
  InventorySpawned = FindFor(Actor);
  if (InventorySpawned != None)
    return InventorySpawned;

  InventorySpawned = Actor.Spawn(Default.Class, Actor);
  InventorySpawned.Inventory = Actor.Inventory;
  Actor.Inventory = InventorySpawned;
  
  return InventorySpawned;
  }
