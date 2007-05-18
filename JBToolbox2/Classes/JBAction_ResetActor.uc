// ============================================================================
// JBAction_ResetActor
// Copyright (c) 2007 by Wormbo <wormbo@online.de>
// $Id: JBAction_IfMorePrisoners.uc,v 1.3 2007-05-15 12:48:48 wormbo Exp $
//
// Resets actors matching the specified class and/or tag.
// ============================================================================


class JBAction_ResetActor extends ScriptedAction;


// ============================================================================
// Properties
// ============================================================================

var(Action) name         ResetTag;
var(Action) class<Actor> ResetClass;


// ============================================================================
// InitActionFor
//
// Resets matching actors.
// ============================================================================

function bool InitActionFor(ScriptedController C)
{
  local Actor A;
  
  foreach C.AllActors(ResetClass, A, ResetTag) {
    A.Reset();
  }
  
  return false;	
}


// ============================================================================
// GetActionString
//
// Returns a string describing this scripted action.
// ============================================================================

function string GetActionString()
{
  return ActionString @ ResetTag @ ResetClass;
}


// ============================================================================
// Default Properties
// ============================================================================

defaultproperties
{
  ActionString  = "Reset actor"
  ResetClass    = class'Actor'
}