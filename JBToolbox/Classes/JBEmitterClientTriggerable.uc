//=============================================================================
// JBEmitterClientTriggerable
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// An emitter that replicates its Trigger() events to all clients.
//=============================================================================


class JBEmitterClientTriggerable extends Emitter;


//=============================================================================
// Variables
//=============================================================================

var int ClientTriggerCount;
var int OldClientTriggerCount;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( Role == ROLE_Authority )
    ClientTriggerCount;
}


//=============================================================================
// Trigger
//
// Toggles bClientTrigger to call ClientTrigger() on all clients.
//=============================================================================

simulated event Trigger(Actor Other, Pawn EventInstigator)
{
  if ( Role == ROLE_Authority )
    ClientTriggerCount++;
  Super.Trigger(Other, EventInstigator);
}


//=============================================================================
// PostNetReceive
//
// Called on clients when ClientTriggerCount (or another variable) changes.
//=============================================================================

simulated event PostNetReceive()
{
  local int i;
  
  while ( ClientTriggerCount > OldClientTriggerCount ) {
    OldClientTriggerCount++;
    
    for (i = 0; i < Emitters.Length; i++)
      if ( Emitters[i] != None )
        Emitters[i].Trigger();
  }
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bNetNotify=True
}