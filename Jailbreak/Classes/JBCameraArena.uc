// ============================================================================
// JBCameraArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCameraArena.uc,v 1.5 2004/05/31 18:15:45 mychaeel Exp $
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
    Arena,
    TagPlayerFollowed,
    TagPlayerOpponent;
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
// state Active
//
// Camera is active. When the last viewer leaves this camera, auto-destructs.
// ============================================================================

auto state Active
{
  // ================================================================
  // Tick
  //
  // Checks whether the followed player has left the arena. If so,
  // enters state Finished which will wait a bit and then destroy
  // the camera.
  // ================================================================
  
  simulated event Tick(float TimeDelta)
  {
    Global.Tick(TimeDelta);
  
    if (Role == ROLE_Authority &&
        (TagPlayerFollowed == None || !TagPlayerFollowed.IsInArena()) &&
        (TagPlayerOpponent == None || !TagPlayerOpponent.IsInArena()))
      GotoState('Finished');
  }


  // ================================================================
  // DeactivateFor
  //
  // Goes to state Deactivate when the last viewer is gone.
  // ================================================================
  
  function DeactivateFor(Controller Controller)
  {
    Global.DeactivateFor(Controller);
    
    if (!HasViewers())
      GotoState('Deactivate');
  }

} // state Active;


// ============================================================================
// state Finished
//
// Waits for three seconds before destroying itself.
// ============================================================================

state Finished
{
  ignores IsViewerAllowed;  // no viewers accepted in this state


  // ================================================================
  // State Code
  // ================================================================

  Begin:
    Sleep(3.0);
    GotoState('Deactivate');

}  // state Finished


// ============================================================================
// state Deactivate
//
// Waits for a short while before destroying the camera.
// ============================================================================

state Deactivate
{
  ignores IsViewerAllowed;  // no viewers accepted in this state
  ignores Tick;             // implicit deactivation by DeactivateFor fails


  // ================================================================
  // State Code
  //
  // Deactivates the camera for all viewers, waits for a short while
  // and destroys the camera.
  // ================================================================

  Begin:
    DeactivateForAll();
    Sleep(3.0);
    Destroy();

} // state Deactivate


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  ClassCamController = Class'JBCamControllerArena';

  Caption   = (Text="Arena Live Feed",Position=0.9);
  Switching = (bAllowAuto=False,bAllowManual=False,bAllowTimed=False,bAllowTriggered=False);

  bNoDelete = False;
}