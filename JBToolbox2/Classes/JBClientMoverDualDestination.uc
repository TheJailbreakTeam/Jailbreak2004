// ============================================================================
// JBClientMoverDualDestination
// Copyright 2007 by Wormbo <wormbo@online.de>
// $Id$
//
// ClientMover version of the JBMoverDualDestination.
// ============================================================================


class JBClientMoverDualDestination extends JBMoverDualDestination;


// ============================================================================
// PostBeginPlay
//
// Sends the mover to an idle state on dedicated servers.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();
  
  if (Level.NetMode == NM_DedicatedServer) {
    GotoState('ServerIdle');
    SetTimer(0, false);
    SetPhysics(PHYS_None);
  }
}


// ============================================================================
// state ServerIdle
//
// Dummy idle state for dedicated server.
// ============================================================================

state ServerIdle {}


// ============================================================================
// Default Values
// ============================================================================

defaultproperties
{
  bAlwaysRelevant       = false
  RemoteRole            = ROLE_None
  bClientAuthoritative  = true
}