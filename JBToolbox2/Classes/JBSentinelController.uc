// ============================================================================
// JBSentinelController
// Copyright 2004 by Blitz
// $Id$
//
// The controller that controls the sentinel.
// ============================================================================


class JBSentinelController extends ASSentinelController
  notplaceable;


 // ============================================================================
// Variables
// ============================================================================

var bool bForceSleeping;


// ============================================================================
// state Sleeping
//
// The controller is idling.
// ============================================================================

auto state Sleeping {

  // ================================================================
  // Awake
  //
  // Wakes up. This function in the superclass will wake up the Pawn.
  // ================================================================

  function Awake() {
    if (!bForceSleeping)
      Super.Awake();
  }
} // state Sleeping


// ============================================================================
// state GameEnded
//
// Fixes an end-game issue with sentinels.
// ============================================================================

state GameEnded
{
  ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange, Falling, TakeDamage;


  // ================================================================
  // BeginState
  //
  // Fixes issue.
  // ================================================================

  function BeginState()
  {
    if (Pawn != None)
    {
      if (Pawn.Weapon != None)
        Pawn.Weapon.HolderDied();

      Pawn.SimAnim.AnimRate = 0;
      Pawn.TurnOff();
      Pawn.UnPossessed();
      Pawn = None;
    }

    Lifespan = 0.2;
  }
} // state GameEnded


// ============================================================================
// IsTargetRelevant
//
// Only target living players who are in the same jail as the sentinel's Pawn.
// ============================================================================

function bool IsTargetRelevant(Pawn Target)
{
  local JBTagPlayer TagPlayer;
  local JBInfoJail  Jail;

  if (Target != None && Target.Controller != None && Target.Health > 0) {
    TagPlayer = class'JBTagPlayer'.static.FindFor(Target.PlayerReplicationInfo);

    if (TagPlayer != None) {
      Jail = TagPlayer.GetJail();

      if (Jail != None)
        return Jail.ContainsActor(Pawn);
    }
  }

  return false;
}


// ============================================================================
// GetTeamNum
//
// Target players of both teams.
// ============================================================================

simulated function int GetTeamNum()
{
  return 255;
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  bForceSleeping=True
  bSelected=True
}