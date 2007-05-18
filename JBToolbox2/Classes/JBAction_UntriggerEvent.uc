// ============================================================================
// JBAction_UntriggerEvent
// Copyright (c) 2007 by Wormbo <wormbo@online.de>
// $Id: JBAction_IfMorePrisoners.uc,v 1.3 2007-05-15 12:48:48 wormbo Exp $
//
// Untriggers actors matching the specified tag.
// ============================================================================


class JBAction_UntriggerEvent extends ACTION_TriggerEvent;


// ============================================================================
// InitActionFor
//
// Resets matching actors.
// ============================================================================

function bool InitActionFor(ScriptedController C)
{
  C.UntriggerEvent(Event, C.SequenceScript, C.GetInstigator());
  return false;	
}


// ============================================================================
// Default Properties
// ============================================================================

defaultproperties
{
  ActionString  = "untrigger event"
}