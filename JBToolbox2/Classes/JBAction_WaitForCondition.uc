// ============================================================================
// JBAction_WaitForCondition
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Waits until a TriggeredCondition has a certain value. Completes either
// instantly when the condition is matched or waits until the condition stays in
// that state for a specified duration.
// ============================================================================


class JBAction_WaitForCondition extends LatentScriptedAction;


// ============================================================================
// Properties
// ============================================================================

var(Action) name ConditionTag;
var(Action) bool bWaitWhileEnabled;
var(Action) float ConditionMatchDuration;


// ============================================================================
// Variables
// ============================================================================

var TriggeredCondition Condition;
var bool bConditionMatching;


// ============================================================================
// PostBeginPlay
//
// Find the TriggeredCondition associated with this action.
// ============================================================================

function PostBeginPlay(ScriptedSequence Parent)
{
  if (ConditionTag != '' && Parent != None) {
    foreach Parent.DynamicActors(class'TriggeredCondition', Condition, ConditionTag) {
      //log(Name $ " - Found condition: " $ Condition);
      return;
    }
  }
}


// ============================================================================
// GetActionString
//
// Returns a string describing this scripted action.
// ============================================================================

function string GetActionString()
{
  return ActionString @ ConditionTag @ bWaitWhileEnabled @ ConditionMatchDuration;
}


// ============================================================================
// InitActionFor
//
// Perform initial check of the TriggeredCondition's state.
// Complete immediately if the condition has the desired state and the match
// duration is 0.
// ============================================================================

function bool InitActionFor(ScriptedController C)
{
  Super.InitActionFor(C); // return value does not matter
  
  if (Condition == None || Condition.bEnabled != bWaitWhileEnabled) {
    // condition is either not available or is in desired state
    if (ConditionMatchDuration > 0) {
      // set timer and continue monitoring the condition's state
      bConditionMatching = True;
      C.SetTimer(ConditionMatchDuration, false);
    }
    else {
      // no additional delay, so immediately complete
      return false;
    }
  }
  else {
    // condition not matching yet, stop any running timer
    bConditionMatching = False;
    C.SetTimer(0, False);
  }
  return true;
}


// ============================================================================
// TickedAction
//
// Returns True to receive StillTicking() calls.
// ============================================================================

function bool TickedAction()
{
  return true;
}


// ============================================================================
// CompleteWhenTimer
//
// This action completes when a timer counted down.
// ============================================================================

function bool CompleteWhenTimer()
{
  return true;
}


// ============================================================================
// StillTicking
//
// Checks the state of the triggered condition and returns True until the
// desired condition state is found.
// ============================================================================

function bool StillTicking(ScriptedController C, float DeltaTime)
{
  if (Condition == None || Condition.bEnabled != bWaitWhileEnabled) {
    // condition was either not specified or has the desired state
    
    if (ConditionMatchDuration > 0) {
      // continue monitoring the state for the specified duration
      if (!bConditionMatching) {
        C.SetTimer(ConditionMatchDuration, False);
        bConditionMatching = True;
        //log(Name $ " - Monitoring started");
      }
      return true;
    }
    
    // stop waiting immediately
    C.Timer();
    return false;
  }
  // condition is not in desired state
  
  if (bConditionMatching) {
    // reset the monitoring duration
    C.SetTimer(0, False);
    bConditionMatching = False;
  }
  
  // continue waiting
  return true;
}


// ============================================================================
// Default values
// ============================================================================

defaultproperties
{
  ActionString="Wait for triggered condition"
}