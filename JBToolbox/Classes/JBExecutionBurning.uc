// ============================================================================
// JBExecutionBurning
// Copyright 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBExecutionBurning.uc,v 1.8 2006-07-17 14:18:27 jrubzjeknf Exp $
//
// A burning execution.
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
// Left-over Variables (only for binary compatibility)
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
  local JBDamagerBurning Damager;

  Damager = Spawn(class'JBDamagerBurning');

  if (Damager != None) {
    Damager.Victim = Victim;
    Damager.SetTimer(BurningTime, False);
    Damager.FlameEmitter = Spawn(class'JBEmitterBurningPlayer', Victim,, Victim.Location);
  }
}


// ============================================================================
// Left-over functions and state (only for binary compatibility)
// ============================================================================

function Trigger(Actor A, Pawn P) { Super.Trigger(A, P); }
function PostBeginPlay()          { Super.PostBeginPlay(); }
state WaitAndKill                 {}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  BurningTime=3.000000
  Texture=Texture'JBToolbox.icons.JBExecutionBurning';
}
