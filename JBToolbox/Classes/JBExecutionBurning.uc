// ============================================================================
// JBExecutionBurning
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBurning.uc,v 1.7 2004-08-23 09:26:05 mychaeel Exp $
//
// An burning execution.
// ============================================================================

class JBExecutionBurning extends JBExecution;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBExecutionBurning.pcx mips=off masked=on group=icons


// ============================================================================
// Variables
// ============================================================================

var() float         BurningTime;


// ============================================================================
// Unused Variables
// ============================================================================
const DESTROY_FLAME_DELAY = 0.15;
var   deprecated HitFlameBig   Flame[5];
var   deprecated private name  AttachFlamePart[5];
var   deprecated private float RealBurningTime;


// ============================================================================
// ExecuteJailedPlayer
//
// Execute a player.
// ============================================================================

function ExecuteJailedPlayer(Pawn Victim)
{
  local JBDamager Damager;

  Spawn(class'JBEmitterBurningPlayer', Victim,, Victim.Location);
  Damager = Spawn(class'JBDamagerBurning');

  if (Damager != None) {
    Damager.Victim = Victim;
    Damager.SetTimer(BurningTime, False);
  }
}


// ============================================================================
// Unused functions and state
// ============================================================================

function Trigger(Actor A, Pawn P) { Super.Trigger(A, P); }
function PostBeginPlay()          { Super.PostBeginPlay(); }
state WaitAndKill{}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  BurningTime=3.000000
  Texture=Texture'JBToolbox.icons.JBExecutionBurning';
}
