// ============================================================================
// JBTriggerTimed
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTriggerTimed.uc,v 1.1 2003/06/29 15:05:46 mychaeel Exp $
//
// Trigger that periodically fires a certain event. Can be activated and
// deactivated by being triggered itself. Trigger times are randomly chosen
// between a given minimum and maximum delay.
// ============================================================================


class JBTriggerTimed extends Triggers
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBTriggerTimed.pcx mips=off masked=on


// ============================================================================
// Properties
// ============================================================================

var() bool bEnabled;          // trigger is enabled by default
var() bool bRepeating;        // event is fired repeatedly instead of just once
var() bool bUseInstigator;    // pawn enabling this trigger is event instigator
var() float MinDelaySeconds;  // minimum number of seconds between events
var() float MaxDelaySeconds;  // maximum number of seconds between events


// ============================================================================
// PostBeginPlay
//
// If the trigger is enabled, starts the timer.
// ============================================================================

event PostBeginPlay() {

  if (bEnabled)
    StartTimer();
  }


// ============================================================================
// Trigger
//
// Toggles the trigger between enabled and disabled state. If the trigger is
// being enabled, starts the timer.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator) {

  bEnabled = !bEnabled;
  
  if (bEnabled)
    StartTimer();
  else
    SetTimer(0.0, False);
  
  if (bUseInstigator)
    Instigator = PawnInstigator;
  }


// ============================================================================
// Timer
//
// Fires the trigger's event and restarts the timer if appropriate.
// ============================================================================

event Timer() {

  TriggerEvent(Event, Self, Instigator);
  
  if (bRepeating)
    StartTimer();
  }


// ============================================================================
// StartTimer
//
// Adjusts MinDelaySeconds and MaxDelaySeconds. Starts the timer with a random
// interval between those two values.
// ============================================================================

function StartTimer() {

  if (MinDelaySeconds <= 0.0)
    MinDelaySeconds = 0.0001;  // small but non-zero

  if (MaxDelaySeconds < MinDelaySeconds)
    MaxDelaySeconds = MinDelaySeconds;
  
  SetTimer(MinDelaySeconds + FRand() * (MaxDelaySeconds - MinDelaySeconds), False);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bEnabled = True;
  bRepeating = True;
  bUseInstigator = False;
  Texture = Texture'JBTriggerTimed';
  }