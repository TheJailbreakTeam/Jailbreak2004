// ============================================================================
// JBExecutionBasic
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBasic.uc,v 1.3 2003/06/27 11:11:30 crokx Exp $
//
// A basic execution.
// ============================================================================
class JBExecutionBasic extends JBExecution;


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
}
