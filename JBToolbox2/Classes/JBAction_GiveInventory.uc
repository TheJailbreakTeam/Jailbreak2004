// ============================================================================
// JBAction_GiveInventory
// Copyright (c) 2010 by Wormbo <wormbo@online.de>
// $Id$
//
// Adds the specified type of inventory, e.g. a weapon or the JBFreezer, which
// actually is a weapon as well.
// ============================================================================


class JBAction_GiveInventory extends ScriptedAction;


// ============================================================================
// Properties
// ============================================================================

var() class<Inventory> InventoryType;


// ============================================================================
// InitActionFor
//
// Resets matching actors.
// ============================================================================

function bool InitActionFor(ScriptedController C)
{
  if (C.GetInstigator() != None)
	C.GetInstigator().CreateInventory(string(InventoryType));

  return false;
}


// ============================================================================
// GetActionString
//
// Returns a string describing this scripted action.
// ============================================================================

function string GetActionString()
{
  return ActionString @ InventoryType;
}


//=============================================================================
// Default values
//=============================================================================

defaultproperties
{
  ActionString = "Give Inventory"
}

