// ============================================================================
// JBExecutionBasic
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBasic.uc,v 1.5 2004/03/19 19:18:53 tarquin Exp $
//
// A basic execution.
// ============================================================================


class JBExecutionBasic extends JBExecution;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBExecutionBasic.pcx mips=off masked=on group=icons


// ============================================================================
// Variables
// ============================================================================

var() class<DamageType> DeathType;


// ============================================================================
// PostBeginPlay
//
// Initialise for dispatching execution.
// ============================================================================

function PostBeginPlay()
{
  if (DeathType == None)
    DeathType = class'DamageType';
  Super.PostBeginPlay();

  if(DispatchExecution.bUseDispatch)
  {
    DispatchExecution.bInstantKill = TRUE;
    DispatchExecution.InstantKillType = DeathType;
  }
}


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================

function Trigger(Actor A, Pawn P)
{
  if(DispatchExecution.bUseDispatch) GoToState('ExecutionDispatching');
  else ExecuteAllJailedPlayers(TRUE, DeathType);
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  DeathType=class'Gibbed'
  Texture = Texture'JBToolbox.icons.JBExecutionBasic';
}
