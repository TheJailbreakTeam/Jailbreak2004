// ============================================================================
// JBRandomDispatcher
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBRandomDispatcher.uc,v 1.1 2006-11-29 19:14:29 jrubzjeknf Exp $
//
// Triggers a random event.
// ============================================================================


class JBRandomDispatcher extends Triggers;


// ============================================================================
// Properties
// ============================================================================

var() array<name> EventList;
var() float DispatchInterval;
var() int DispatchLoops;


// ============================================================================
// Variables
// ============================================================================

var array<name> DispatchedEvents;
var int LoopsLeft;


// ============================================================================
// Trigger
//
// Start dispatching.
// ============================================================================

function Trigger(Actor Other, Pawn EventInstigator)
{
  if (EventList.Length == 0 || DispatchLoops < 1)
    return;

  Instigator = EventInstigator;
  GotoState('Dispatching', 'Begin');
}


// ============================================================================
// state Dispatching
// ============================================================================

state Dispatching
{
  // ============================================================================
  // FireEvent
  //
  // Start a randomly chosen event from the DispatchedEvents list.
  // ============================================================================

  function FireEvent()
  {
    local int i;

    i = Rand(DispatchedEvents.Length);
    TriggerEvent(DispatchedEvents[i], Self, Instigator);
    DispatchedEvents.Remove(i, 1);
  }

Begin:
  LoopsLeft = DispatchLoops;

  while (LoopsLeft-- > 0) {
    DispatchedEvents = EventList;

    do {
      FireEvent();
      Sleep(DispatchInterval);
    } until (DispatchedEvents.Length == 0);
  }

  TriggerEvent(Event, Self, Instigator);
  GotoState('');
}

// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  DispatchInterval=0.100000
  DispatchLoops=1
}
