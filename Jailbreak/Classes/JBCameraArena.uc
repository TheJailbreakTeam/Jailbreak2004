// ============================================================================
// JBCameraArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCameraArena.uc,v 1.1 2004/03/28 22:45:37 mychaeel Exp $
//
// Arena follower camera which tracks the arena opponent. Destroys itself when
// the trailed player dies or is respawned or when the last viewer is gone.
// ============================================================================


class JBCameraArena extends JBCamera
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    Arena, TagPlayerFollowed, TagPlayerOpponent;
}


// ============================================================================
// Variables
// ============================================================================

var JBInfoArena Arena;              // attached arena

var JBTagPlayer TagPlayerFollowed;  // player followed by this camera
var JBTagPlayer TagPlayerOpponent;  // opponent tracked by this camera


// ============================================================================
// IsViewerAllowed
//
// Checks and returns whether the given player is a spectator or in the same
// team as the followed player.
// ============================================================================

function bool IsViewerAllowed(Controller Controller)
{
  if (JBCamControllerArena(CamController) == None)
    return Super.IsViewerAllowed(Controller);
  
  if (TagPlayerFollowed                == None ||
      Controller.PlayerReplicationInfo == None)
    return False;
  
  if (Controller.PlayerReplicationInfo.Team == None ||
      Controller.PlayerReplicationInfo.Team == TagPlayerFollowed.GetTeam())
    return Super.IsViewerAllowed(Controller);
    
  return False;
}


// ============================================================================
// Tick
//
// Checks whether the followed player has left the arena. If so, 
// ============================================================================

simulated event Tick(float TimeDelta)
{
  Super.Tick(TimeDelta);

  if (!TagPlayerFollowed.IsInArena() &&
      !TagPlayerOpponent.IsInArena())
    GotoState('Finished');
}


// ============================================================================
// DeactivateFor
//
// Destroys this camera when the last viewer is gone.
// ============================================================================

function DeactivateFor(Controller Controller)
{
  Super.DeactivateFor(Controller);
  
  if (!HasViewers())
    Destroy();
}


// ============================================================================
// state Finished
//
// Waits for three seconds before destroying itself.
// ============================================================================

state Finished
{
  // ================================================================
  // Tick
  //
  // Just calls the superclass method, thus deactivating the finish
  // check of the main implementation.
  // ================================================================

  simulated event Tick(float TimeDelta)
  {
    Super.Tick(TimeDelta);
  }


  // ================================================================
  // State
  // ================================================================

  Begin:
    Sleep(3.0);
    Destroy();

}  // state Finished


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Begin Object Class=JBCamControllerArena Name=JBCamControllerArenaDef
  End Object

  CamController = JBCamControllerArena'JBCamControllerArenaDef';

  Caption   = (Text="Arena Live Feed",Position=0.9);
  Switching = (bAllowAuto=False,bAllowManual=False,bAllowTimed=False,bAllowTriggered=False);

  bNoDelete = False;
}