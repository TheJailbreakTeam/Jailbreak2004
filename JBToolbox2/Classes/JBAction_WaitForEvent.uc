// ============================================================================
// JBAction_WaitForEvent
// Copyright (c) 2007 by Wormbo <wormbo@online.de>
// $Id: JBAction_WaitForCondition.uc,v 1.1 2007-04-27 15:50:59 wormbo Exp $
//
// Works around a bug in ScriptedController which causes the ScriptedSequence
// to skip over actions if the event of an Action_WaitForEvent is triggered
// more than once in the same tick.
// ============================================================================


class JBAction_WaitForEvent extends Action_WaitForEvent;


// ============================================================================
// Variables
// ============================================================================

var bool bWaitsForTrigger;


// ============================================================================
// PostBeginPlay
//
// Makes sure bWaitsForTrigger is unset.
// ============================================================================

function PostBeginPlay(ScriptedSequence Parent)
{
  bWaitsForTrigger = False;
}


// ============================================================================
// InitActionFor
//
// Sets bWaitsForTrigger (if necessary), so ScriptedController listens for
// Trigger events.
// ============================================================================

function bool InitActionFor(ScriptedController C)
{
  bWaitsForTrigger = Super.InitActionFor(C);
  return bWaitsForTrigger;
}


// ============================================================================
// CompleteWhenTriggered
//
// This action completes on trigger only when it did not yet complete.
// (Sounds stupid, but due to the implementation in ScriptedController a
// LatentAction can "complete again" after it was already completed, causing
// the ScriptedSequence to skip over following actions.)
// ============================================================================

function bool CompleteWhenTriggered()
{
  return bWaitsForTrigger;
}


// ============================================================================
// ActionCompleted
//
// Unsets bWaitsForTrigger, so ScriptedController stops listening for Trigger
// events.
// ============================================================================

function ActionCompleted()
{
  bWaitsForTrigger = False;
}