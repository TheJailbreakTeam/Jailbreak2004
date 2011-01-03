//=============================================================================
// JBEmitterClientTriggerable
// Copyright (c) 2004 by Wormbo <wormbo@onlinehome.de>
// $Id: JBEmitterClientTriggerable.uc,v 1.2 2004/05/24 20:58:59 wormbo Exp $
//
// An emitter that replicates its Trigger() events to all clients.
//=============================================================================


class JBEmitterClientTriggerable extends Emitter;


//=============================================================================
// Variables
//=============================================================================

var int ClientTriggerCount;
var int OldClientTriggerCount;

var(Global) bool bIgnoreTriggerDuringInitialization;
var bool bPostNetBegun;


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
  if ( Role == ROLE_Authority ) {
    ClientTriggerCount++;
    NetUpdateTime = Level.TimeSeconds - 1;
  }
  Super.Trigger(Other, EventInstigator);
}


//=============================================================================
// PostNetBeginPlay
//
// If configured, no triggering happens before this point.
//=============================================================================

simulated function PostNetBeginPlay()
{
  bPostNetBegun = True;
}


//=============================================================================
// PostNetReceive
//
// Called on clients when ClientTriggerCount (or another variable) changes.
//=============================================================================

simulated event PostNetReceive()
{
  local int i;
  
  if (bIgnoreTriggerDuringInitialization && !bPostNetBegun)
    OldClientTriggerCount = ClientTriggerCount;
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