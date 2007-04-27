// ============================================================================
// JBMoverDualDestination
// Copyright 2007 by Wormbo <wormbo@online.de>
// $Id: JBMoverDualDestination.uc,v 1.1 2007-04-22 14:01:57 wormbo Exp $
//
// A mover with a multitude of improvements over standard movers:
//
// - can trigger an event when receiving damage (like my DamageTriggerMover)
//   See: http://wiki.beyondunreal.com/wiki/DamageTriggerMover
//
// - can trigger/untrigger an event when someone stands in it (not only in
//   StandOpenTimed state)
//
// - mapper can define two different movement paths (like tarquin's DecksMover)
//   with individual trigger tags, sounds and events
//
// - mapper can specify separate open and close times (like VitalOverdose's
//   VariableTimedMover)
//   See: http://wiki.beyondunreal.com/wiki/VitalOverdose/VariableTimedMover
//
// - mapper can specify indifid move times for every key (like SuperApe's
//   VariableTimedMover)
//   See: http://wiki.beyondunreal.com/wiki/VariableTimedMover
//
//
// The mover will ignore the AlternateTag event when it was opened with the Tag
// event and vice versa until it has closed again. AlternateTag doesn't make
// sense in some states.
// ============================================================================


class JBMoverDualDestination extends Mover;


// ============================================================================
// Properties
// ============================================================================

/**
Actual number of keys for the primary movement. The secondary movement consists
of key 0 (closed) and any keys greater than or equal to this value.
Values must be greater than 1 for most mover types and greater than 2 for the
LeadInOutLooper.
Additionally, if an AlternateTag is used, the NumKeys value must be greater
than NumKeysPrimary, for a LeadInOutLooper NumKeys must be greater than
NumKeysPrimary+1, because the alternate movement loop starts at NumKeysPrimary
and goes up to NumKeys-1.
*/
var(Mover) byte NumKeysPrimary;


// ----------------------------------------------------------------------------
// Sounds
// ----------------------------------------------------------------------------

/**
Sound to play when starting to open in alternate movement.
*/
var(MoverSounds) Sound  AlternateOpeningSound;

/**
Sound to play when opening in alternate movement finished.
*/
var(MoverSounds) Sound  AlternateOpenedSound;

/**
Sound to play when starting to close in alternate movement.
*/
var(MoverSounds) Sound  AlternateClosingSound;

/**
Sound to play when closing in alternate movement finished.
*/
var(MoverSounds) Sound  AlternateClosedSound;

/**
Ambient sound to play during alternate movement.
*/
var(MoverSounds) Sound  AlternateMoveAmbientSound;

/**
Sound to play when the mover loops in alternate movement.
*/
var(MoverSounds) Sound  AlternateLoopSound;


// ----------------------------------------------------------------------------
// Events
// ----------------------------------------------------------------------------

/**
Name of the event that opens this mover with its alternate movement.
*/
var(Events)      name   AlternateTag;

/**
Event to trigger when opened in alternate movement, untriggered when starting
to close again.
*/
var(Events)      name   AlternateEvent;

/**
Event to trigger when starting to open in alternate movement, untriggered when
finished closing again.
*/
var(MoverEvents) name   AlternateOpeningEvent;

/**
Event to trigger when finished opening in alternate movement.
*/
var(MoverEvents) name   AlternateOpenedEvent;

/**
Event to trigger when starting to close in alternate movement.
*/
var(MoverEvents) name   AlternateClosingEvent;

/**
Event to trigger when finished closing in alternate movement.
*/
var(MoverEvents) name   AlternateClosedEvent;

/**
Event to trigger when the mover loops in alternate movement.
*/
var(MoverEvents) name   AlternateLoopEvent;

/**
Event triggered when the mover takes damage.
*/
var(MoverEvents) name DamageEvent;

/**
The minimum amount of damage (per hit) required for triggering the DamageEvent.
*/
var(MoverEvents) int  DamageEventThreshold;

/**
Event triggered when a player stands on the mover, untriggered when no player
stands on the mover anymore.
*/
var(MoverEvents) name StandOnMoverEvent;


// ----------------------------------------------------------------------------
// Timing
// ----------------------------------------------------------------------------

/** Time per key for closing the mover in primary movement. */
var(Mover) float CloseTime;

/** Time per key for closing the mover in alternate movement. */
var(Mover) float AlternateCloseTime;

/** Delay time before opening the mover in alternate movement. */
var(Mover) float AlternateDelayTime;

/** Time per key for opening the mover in alternate movement. */
var(Mover) float AlternateMoveTime;

/** Delay time before automatically closing the StandOpenTimed mover in alternate movement. */
var(Mover) float AlternateStayOpenTime;

/** Delay time before closing the TriggerPound mover in alternate movement. */
var(Mover) float AlternateOtherTime;


/**
Time multipliers for (Alternate)CloseTime.
Each element specifies a factor for closing FROM that key, i.e. going to a
lower key number.
The only exception here is the LeadInOutLooper, which uses the value as time
multiplier for going backward TO that key.
*/
var(Mover) float TimeMultipliersClose[ArrayCount(KeyPos)];

/**
Time multipliers for (Alternate)MoveTime.
Each element specifies a factor for opening TO that key, i.e. coming from a
lower key number.
The only exception here is the LeadInOutLooper, which uses the value as time
multiplier for going forward FROM that key.
*/
var(Mover) float TimeMultipliersOpen[ArrayCount(KeyPos)];


// ============================================================================
// Variables
// ============================================================================

/** Used instead of Disable('Attach') in StandOpenTimed state. */
var bool bTriggerDisabled;

/** Whether the StandOnMoverEvent has been triggered. */
var bool bTriggeredStandOnMoverEvent;

/** Alternate movement handling. */
var bool bAlternateMovement;


// ============================================================================
// BeginPlay
//
// Perform various consistency checks for NumKeys, NumKeysPrimary and
// AlternateTag. If an AlternateTag was specified and passed the consistency
// checks, spawns JBProbeEvents for Tag (which is cleared afterwards) and
// AlternateTag in order to catch Trigger and Untrigger events.
// 
// ============================================================================

event BeginPlay()
{
  local JBProbeEvent ProbeEvent;
  
  if (IsA('JBClientMoverDualDestination') && Level.NetMode == NM_DedicatedServer) {
    // skip most of the logic that could lead to spawning JBProbeEvents
    AlternateTag = '';
  }
  if (Tag == Name && AlternateTag != '') {
    log(Name $ " - Tag should not be equal to any actor's Name", 'Warning');
  }
  if (Tag != Name && AlternateTag == Tag) {
    log(Name $ " - AlternateTag is ignored because it's identical to Tag", 'Warning');
    AlternateTag = '';
  }
  if (NumKeys > ArrayCount(KeyPos) || NumKeys < 2) {
    log(Name $ " - NumKeys out of bounds! (" $ NumKeys $ "/" $ ArrayCount(KeyPos) $ ")", 'Warning');
  }
  if (NumKeysPrimary > NumKeys || NumKeysPrimary < 2) {
    log(Name $ " - NumKeysPrimary out of bounds! (" $ NumKeysPrimary $ "/" $ NumKeys $ ")", 'Warning');
    NumKeysPrimary = Clamp(NumKeysPrimary, 2, NumKeys);
  }
  if (AlternateTag != '') {
    switch (InitialState) {
      case 'BumpButton':        // doesn't use triggering
      case 'BumpOpenTimed':     // doesn't use triggering
      case 'ConstantLoop':      // doesn't use triggering
      case 'LoopMove':          // wouldn't make sense
      case 'RotatingMover':     // wouldn't make sense
      case 'StandOpenTimed':    // doesn't use triggering
        log(Name $ " - AlternateTag is ignored in state " $ InitialState, 'Warning');
        
      case 'ServerIdle':
        break;
        
      default:
        if (NumKeysPrimary < NumKeys) {
          if (Tag != '' && Tag != Name) {
            // redirect the primary event to prevent unchecked triggering
            ProbeEvent = Spawn(class'JBProbeEvent', Self, Tag);
            ProbeEvent.OnTrigger   = PrimaryTrigger;
            ProbeEvent.OnUntrigger = PrimaryUntrigger;
            Tag = Name;
          }
          else {
            log(Name $ " - No Tag specified but AlternateTag is present. Are you sure this is what you want?", 'Warning');
          }
          
          // catch the alternate event
          ProbeEvent = Spawn(class'JBProbeEvent', Self, AlternateTag);
          ProbeEvent.OnTrigger   = AlternateTrigger;
          ProbeEvent.OnUntrigger = AlternateUntrigger;
        }
        else {
          log(Name $ " - AlternateTag is ignored because there are no keys left for the alternate movement (" $ NumKeysPrimary $ "/" $ NumKeys $ ")", 'Warning');
          AlternateTag = '';
        }
    }
  }
  
  if (AlternateTag != '' && KeyNum != 0) {
    log(Name $ " - Mover must start at key 0 if AlternateTag is specified", 'Warning');
    KeyNum = 0;
  }
  
  bAlternateMovement = False;
  
  Super.BeginPlay();
}


// ============================================================================
// PrimaryTrigger
//
// Triggers the mover for its primary movement.
// ============================================================================

function PrimaryTrigger(Actor Other, Pawn EventInstigator)
{
  if (bClosed)
    SetGroupMovement(False);
  
  if (!bAlternateMovement)
    Trigger(Other, EventInstigator);
}


// ============================================================================
// PrimaryUntrigger
//
// Untriggers the mover if it's in its primary movement.
// ============================================================================

function PrimaryUntrigger(Actor Other, Pawn EventInstigator)
{
  if (!bAlternateMovement)
    Untrigger(Other, EventInstigator);
}


// ============================================================================
// AlternateTrigger
//
// Triggers the mover for its alternate movement.
// ============================================================================

function AlternateTrigger(Actor Other, Pawn EventInstigator)
{
  if (bClosed)
    SetGroupMovement(True);
  
  if (bAlternateMovement)
    Trigger(Other, EventInstigator);
}

// ============================================================================
// AlternateUntrigger
//
// Untriggers the mover if it's in its alternate movement.
// ============================================================================

function AlternateUntrigger(Actor Other, Pawn EventInstigator)
{
  if (bAlternateMovement)
    Untrigger(Other, EventInstigator);
}


// ============================================================================
// SetGroupMovement
//
// Sets the value of bAlternateMovement for this mover's ReturnGroup.
// ============================================================================

function SetGroupMovement(bool bNewAlternateMovement)
{
  local Mover M;
  
  if (bIsLeader || Leader == Self) {
    for (M = Self; M != None; M = M.Follower) {
      if (JBMoverDualDestination(M) != None)
        JBMoverDualDestination(M).bAlternateMovement = bNewAlternateMovement;
    }
  }
}


// ============================================================================
// TakeDamage
//
// Fires the DamageEvent if enough damage was received.
// (in addition to a regular mover's behavior)
// ============================================================================

event TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
  if (DamageEvent != '' && Damage >= DamageEventThreshold)
    TriggerEvent(DamageEvent, Self, InstigatedBy);
  
  Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
}


// ============================================================================
// Attach
//
// Triggers the StandOnMoverEvent, if a relevant Pawn stands on the mover.
// ============================================================================

event Attach(Actor Other)
{
  if (!bTriggeredStandOnMoverEvent && RelevantForStandOnMoverEvent(Pawn(Other))) {
    TriggerEvent(StandOnMoverEvent, Self, Other.Instigator);
    bTriggeredStandOnMoverEvent = True;
  }
}


// ============================================================================
// Detach
//
// Untriggers the StandOnMoverEvent, if no relevant Pawn stands on the mover.
// ============================================================================

event Detach(Actor Other)
{
  local Pawn P;
  
  if (bTriggeredStandOnMoverEvent) {
    foreach BasedActors(class'Pawn', P) {
      if (RelevantForStandOnMoverEvent(P))
        return;
    }
    
    UntriggerEvent(StandOnMoverEvent, Self, Other.Instigator);
    bTriggeredStandOnMoverEvent = False;
  }
}


// ============================================================================
// RelevantForStandOnMoverEvent
//
// Returns whether the Pawn is relevant for triggering the StandOnMoverEvent.
// ============================================================================

function bool RelevantForStandOnMoverEvent(Pawn Candidate)
{
  return Candidate != None && Candidate.IsPlayerPawn();
}


// ============================================================================
// FinishedClosing
//
// Called when the mover has finished closing.
// ============================================================================

function FinishedClosing()
{
  local Mover M;
  
  if (bAlternateMovement) {
    // Update sound effects.
    PlaySound(AlternateClosedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0); 
    
    // Handle Events
    TriggerEvent(AlternateClosedEvent, Self, Instigator);
    
	// Notify our triggering actor that we have completed.
	if( SavedTrigger != None )
      SavedTrigger.EndEvent();
    
	SavedTrigger = None;
	Instigator = None;
	if (MyMarker != None)
      MyMarker.MoverClosed();
	bClosed	= true;
	FinishNotify(); 
	for (M = Leader; M != None; M = M.Follower) {
      if (!M.bClosed)
        return;
    }
	UnTriggerEvent(AlternateOpeningEvent, Self, Instigator);
  }
  else {
    Super.FinishedClosing();
  }
}


// ============================================================================
// FinishedOpening
//
// Called when the mover has finished opening.
// ============================================================================

function FinishedOpening()
{
  if (bAlternateMovement) {
	// Update sound effects.
	PlaySound(AlternateOpenedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    
	// Trigger any chained movers / Events
	TriggerEvent(AlternateEvent, Self, Instigator);
	TriggerEvent(AlternateOpenedEvent, Self, Instigator);
    
	if (MyMarker != None)
      MyMarker.MoverOpened();
	FinishNotify();
  }
  else {
    Super.FinishedOpening();
  }
}
  

// ============================================================================
// DoOpen
//
// Open the mover.
// ============================================================================

function DoOpen()
{
  bOpening = true;
  bDelaying = false;
  if (bAlternateMovement) {
    if (KeyNum == 0) {
      //log("Alternate open first" @ NumKeysPrimary);
      InterpolateTo(NumKeysPrimary, AlternateMoveTime * TimeMultipliersOpen[NumKeysPrimary]);
    }
    else {
      //log("Alternate open" @ Min(KeyNum + 1, NumKeys - 1));
      InterpolateTo(Min(KeyNum + 1, NumKeys - 1), AlternateMoveTime * TimeMultipliersOpen[Min(KeyNum + 1, NumKeys - 1)]);
    }
  }
  else {
    //log("Primary open" @ Min(KeyNum + 1, NumKeysPrimary - 1));
    InterpolateTo(Min(KeyNum + 1, NumKeysPrimary - 1), MoveTime * TimeMultipliersOpen[Min(KeyNum + 1, NumKeysPrimary - 1)]);
  }
  MakeNoise(1.0);
  
  if (bAlternateMovement) {
    PlaySound(AlternateOpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    AmbientSound = AlternateMoveAmbientSound;
    TriggerEvent(AlternateOpeningEvent, Self, Instigator);
  }
  else {
    PlaySound(OpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    AmbientSound = MoveAmbientSound;
    TriggerEvent(OpeningEvent, Self, Instigator);
  }
  if (Follower != None)
    Follower.DoOpen();
}


// ============================================================================
// DoOpen
//
// Close the mover.
// ============================================================================

function DoClose()
{
  bOpening = false;
  bDelaying = false;
  if (bAlternateMovement) {
    if (KeyNum <= NumKeysPrimary) {
      //log("Alternate close first" @ 0);
      InterpolateTo(0, AlternateCloseTime * TimeMultipliersClose[NumKeysPrimary]);
    }
    else {
      //log("Alternate close" @ KeyNum - 1);
      InterpolateTo(KeyNum - 1, AlternateCloseTime * TimeMultipliersClose[KeyNum]);
    }
  }
  else {
    //log("Primary close" @ Max(0, KeyNum - 1));
    InterpolateTo(Max(0, KeyNum - 1), CloseTime * TimeMultipliersClose[Max(1, KeyNum)]);
  }
  MakeNoise(1.0);
  if (bAlternateMovement) {
    PlaySound(AlternateClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    UntriggerEvent(AlternateEvent, self, Instigator);
    AmbientSound = AlternateMoveAmbientSound;
    TriggerEvent(AlternateClosingEvent,Self,Instigator);
  }
  else {
    PlaySound(ClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    UntriggerEvent(Event, self, Instigator);
    AmbientSound = MoveAmbientSound;
    TriggerEvent(ClosingEvent,Self,Instigator);
  }
  if (Follower != None)
    Follower.DoClose();
}


// ============================================================================
// DoOpen
//
// Interpolation ended.
// ============================================================================

simulated event KeyFrameReached()
{
  local Mover M;
  
  PhysAlpha  = 0;
  ClientUpdate--;
  
  if (bAlternateMovement) {
    // If more than two keyframes, chain them.
    if (KeyNum > 0 && KeyNum < PrevKeyNum) {
      // Chain to previous.
      if (KeyNum > NumKeysPrimary)
        InterpolateTo(KeyNum - 1, AlternateCloseTime * TimeMultipliersClose[KeyNum]);
      else
        InterpolateTo(0, AlternateCloseTime * TimeMultipliersClose[KeyNum]);
      return;
    }
    else if (KeyNum < NumKeys - 1 && KeyNum > PrevKeyNum) {
      // Chain to next.
      InterpolateTo(KeyNum + 1, AlternateMoveTime * TimeMultipliersOpen[KeyNum + 1]);
      return;
    }
  }
  else {
    // If more than two keyframes, chain them.
    if (KeyNum > 0 && KeyNum < PrevKeyNum) {
      // Chain to previous.
      InterpolateTo(KeyNum - 1, CloseTime * TimeMultipliersClose[KeyNum]);
      return;
    }
    else if (KeyNum < NumKeysPrimary - 1 && KeyNum > PrevKeyNum) {
      // Chain to next.
      InterpolateTo(KeyNum + 1, MoveTime * TimeMultipliersOpen[KeyNum + 1]);
      return;
    }
  }
  
  // Finished interpolating.
  PrevKeyNum = KeyNum;
  AmbientSound = None;
  NetUpdateTime = Level.TimeSeconds - 1;
  if (bJumpLift && KeyNum == 1) {
    FinishNotify();
  }
  if (ClientUpdate == 0 && (Level.NetMode != NM_Client || bClientAuthoritative)) {
    RealPosition = Location;
    RealRotation = Rotation;
    foreach BasedActors(class'Mover', M) {
      M.BaseFinished();
    }
  }
}


// ============================================================================
// MoverLooped
//
// Called when the mover loops.
// ============================================================================

function MoverLooped()	
{
  if (bAlternateMovement) {
    TriggerEvent(AlternateLoopEvent, Self, Instigator);
    if (AlternateLoopSound != None)
      PlaySound(AlternateLoopSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
  }
  else {
    Super.MoverLooped();
  }
}


// ============================================================================
// state BumpButton
//
// Open when bumped, close when event ends or when reset.
// Implemented fix for crash in combination with TriggerControl'd TriggerLight.
// ============================================================================

state() BumpButton
{
  function BeginEvent()
  {
    if (bOpening)
      Super.BeginEvent();
  }
  
  function EndEvent()
  {
    if (bSlave)
      Super.EndEvent();
  }
}


// ============================================================================
// state ConstantLoop
//
// Loop this mover from the moment we begin.
// Modified so its upper key number limit is specified with NumKeysPrimary and
// the movement time is scaled by TimeMultipliersOpen.
// ============================================================================

state() ConstantLoop
{
  event KeyFrameReached()
  {
    if (bOscillatingLoop) {
      if (KeyNum == 0 || KeyNum == NumKeysPrimary - 1) {
        StepDirection *= -1;
        MoverLooped();
      }
      InterpolateTo(KeyNum + StepDirection, MoveTime * TimeMultipliersOpen[KeyNum + StepDirection]);	
    }
    else {
      if (KeyNum + 1 == NumKeysPrimary) {
        MoverLooped();
        InterpolateTo(0, MoveTime * TimeMultipliersOpen[0]);
      }
      else {
        InterpolateTo(KeyNum + 1, MoveTime * TimeMultipliersOpen[KeyNum + 1]);
      }
    }
  }

Begin:
  InterpolateTo(1, MoveTime * TimeMultipliersOpen[1]);
}


// ============================================================================
// state LeadInOutLooper
//
// A looping move that idles at 0.
// If primary triggered, goes to key 1, then loops 1..(NumKeysPrimary-1) and
// back to 1.
// If alternate triggered, goes to key (NumKeysPrimary), then loops
// (NumKeysPrimary)..(NumKeys-1) and back to (NumKeysPrimary).
// Returns to key 0 if triggered again while looping.
// ============================================================================

state() LeadInOutLooper
{
  function Trigger(Actor Other, Pawn EventInstigator)
  {
    if (bAlternateMovement) {
      // Sanity check
      if (NumKeys - NumKeysPrimary < 2) {
        log(Name $ " - LeadInOutLooper requires at least two keys for alternate movement, found " $ NumKeys - NumKeysPrimary, 'Error');
        return;
      }
      InterpolateTo(NumKeysPrimary, AlternateMoveTime * TimeMultipliersOpen[0]);
      PlaySound(AlternateOpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
      AmbientSound = AlternateMoveAmbientSound;
      TriggerEvent(AlternateOpeningEvent, Self, Instigator);
    }
    else {
      // Sanity check
      if (NumKeysPrimary < 3) {
        log(Name $ " - LeadInOutLooper requires at least two keys for alternate movement, found " $ NumKeysPrimary - 1, 'Error');
        return;
      }
      InterpolateTo(1, MoveTime * TimeMultipliersOpen[0]);
      PlaySound(OpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
      AmbientSound = MoveAmbientSound;
      TriggerEvent(OpeningEvent, Self, Instigator);
    }
    bClosed = False;
    bOpening = True;
    GotoState('LeadInOutLooping');
  }
  
  event KeyFrameReached()
  {
    if (KeyNum == 0)
      FinishedClosing();
  }
}


// ============================================================================
// state LeadInOutLooping
//
// Loop state of a LeadInOutLooper.
// ============================================================================

state LeadInOutLooping
{
  function Trigger(Actor Other, Pawn EventInstigator)
  {
    if (bAlternateMovement) {
      InterpolateTo(0, AlternateMoveTime * TimeMultipliersClose[0]);
      PlaySound(AlternateClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
      TriggerEvent(AlternateClosingEvent, Self, Instigator);
    }
    else {
      InterpolateTo(0, MoveTime * TimeMultipliersClose[0]);
      PlaySound(ClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
      TriggerEvent(ClosingEvent, Self, Instigator);
    }
    bOpening = False;
    GotoState('LeadInOutLooper');
  }
  
  event KeyFrameReached()
  {
    if (bOscillatingLoop) {
      if (bAlternateMovement) {
        if (PrevKeyNum == 0) {
          StepDirection = 1;
        }
        else if (KeyNum == NumKeysPrimary || KeyNum == NumKeys - 1) {
          StepDirection *= -1;
          MoverLooped();
        }
        if (StepDirection < 0)
          InterpolateTo(KeyNum - 1, AlternateMoveTime * TimeMultipliersClose[KeyNum - 1]);
        else
          InterpolateTo(KeyNum + 1, AlternateMoveTime * TimeMultipliersOpen[KeyNum]);			
      }
      else {
        if (PrevKeyNum == 0) {
          StepDirection = 1;
        }
        else if (KeyNum == 1 || KeyNum == NumKeysPrimary - 1) {
          StepDirection *= -1;
          MoverLooped();
        }
        if (StepDirection < 0)
          InterpolateTo(KeyNum - 1, MoveTime * TimeMultipliersClose[KeyNum - 1]);
        else
          InterpolateTo(KeyNum + 1, MoveTime * TimeMultipliersOpen[KeyNum]);	
      }
    }
    else {
      if (bAlternateMovement) {
        if (KeyNum + 1 == NumKeys) {
          MoverLooped();
          InterpolateTo(NumKeysPrimary, AlternateMoveTime * TimeMultipliersOpen[NumKeys - 1]);
        }
        else
          InterpolateTo(KeyNum + 1, AlternateMoveTime * TimeMultipliersOpen[KeyNum]);
      }
      else {
        if (KeyNum + 1 == NumKeysPrimary) {
          MoverLooped();
          InterpolateTo(1, MoveTime * TimeMultipliersOpen[NumKeysPrimary - 1]);
        }
        else
          InterpolateTo(KeyNum + 1, MoveTime * TimeMultipliersOpen[KeyNum]);
      }
    }
  }
}


// ============================================================================
// state LoopMove
//
// Loop when triggered, stop when untriggered.
// Modified so its upper key number limit is specified with NumKeysPrimary and
// the movement time is scaled by TimeMultipliersOpen.
// ============================================================================

state() LoopMove
{
Running:
  FinishInterpolation();
  InterpolateTo((KeyNum + 1) % NumKeysPrimary, MoveTime * TimeMultipliersOpen[(KeyNum + 1) % NumKeysPrimary]);
  Goto 'Running';

Stopping:
  FinishInterpolation();
  FinishedOpening();
  UnTriggerEvent(Event, self, Instigator);
  bOpening = false;
}


// ============================================================================
// state StandOpenTimed
//
// Open when stood on, wait, then close.
// Implements compatibility with StandOnMoverEvent triggering.
// ============================================================================

state() StandOpenTimed
{ 
  event Attach(Actor Other)
  {
    Global.Attach(Other); // global Attach() in this class
    
    if (!bTriggerDisabled)
      Super.Attach(Other); // Attach() in state Mover.StandOpenTimed
  }
  
  function DisableTrigger()
  {
    bTriggerDisabled = True;
  }
  
  function EnableTrigger()
  {
    bTriggerDisabled = False;
  }
  
  event BeginState()
  {
    Super.BeginState();
    bTriggerDisabled = False;
  }
}


// ============================================================================
// state TriggerAdvance
//
// Open when triggered, stop when untriggered, close when reset.
// Replaces state code to add support for alternate delay time.
// ============================================================================

state() TriggerAdvance
{
Open:
  if (Physics == PHYS_None) // Check if Mover has been UnTriggered since
    GotoState('TriggerAdvance', '');
  bClosed = false;
  
  if (!bAlternateMovement && DelayTime > 0) {
    bDelaying = true;
    Sleep(DelayTime);
  }
  else if (bAlternateMovement && AlternateDelayTime > 0) {
    bDelaying = true;
    Sleep(AlternateDelayTime);
  }
  
  if (Physics == PHYS_None) // Check if Mover has been UnTriggered since
    GotoState('TriggerAdvance', '');
  SetStoppedPosition(0);
  DoOpen();
  FinishInterpolation();
  FinishedOpening();
  if (SavedTrigger != None)
    SavedTrigger.EndEvent();
  GotoState('WasTriggerAdvance');
  Stop;
  
Close:		
  SetStoppedPosition(0);
  SetPhysics(PHYS_MovingBrush);
  DoClose();
  FinishInterpolation();
  FinishedClosing();
  SetResetStatus(false);
}


// ============================================================================
// state TriggerControl
//
// Open when triggered, close when get untriggered.
// Replaces state code to add support for alternate delay time.
// ============================================================================

state() TriggerControl
{
Open:
  bClosed = false;
  
  if (!bAlternateMovement && DelayTime > 0) {
    bDelaying = true;
    Sleep(DelayTime);
  }
  else if (bAlternateMovement && AlternateDelayTime > 0) {
    bDelaying = true;
    Sleep(AlternateDelayTime);
  }
  
  if (!bOpening)
    DoOpen();
  FinishInterpolation();
  FinishedOpening();
  if (SavedTrigger != None)
    SavedTrigger.EndEvent();
  if (bTriggerOnceOnly)
    GotoState('WasTriggerControl');
  Stop;
  
Close:		
  if (bOpening || !bInterpolating && KeyNum > 0)
    DoClose();
  if (bInterpolating) {
    FinishInterpolation();
    FinishedClosing();
  }
  SetResetStatus(false);
}


// ============================================================================
// state TriggerOpenTimed
//
// When triggered, open, wait, then close.
// Replaces OpenTimedMover state code to add support for the alternate movement
// pre-move and stay-open delays.
// ============================================================================

state TriggerOpenTimed
{
Open:
  if (bTriggerOnceOnly)
    Disable('Trigger');
  bClosed = false;
  DisableTrigger();
  
  if (!bAlternateMovement && DelayTime > 0) {
    bDelaying = true;
    Sleep(DelayTime);
  }
  else if (bAlternateMovement && AlternateDelayTime > 0) {
    bDelaying = true;
    Sleep(AlternateDelayTime);
  }
  
  DoOpen();
  FinishInterpolation();
  FinishedOpening();
  
  if (bAlternateMovement)
    Sleep(AlternateStayOpenTime);
  else
    Sleep(StayOpenTime);
  
  if (bTriggerOnceOnly)
    GotoState('WasOpenTimedMover', '');
  
Close:
  DoClose();
  FinishInterpolation();
  FinishedClosing();
  EnableTrigger();
  if (bResetting) {
    SetResetStatus( false );
    GotoState(Backup_InitialState, '');
    Stop;
  }
}


// ============================================================================
// state TriggerOpenTimed
//
// Start pounding when triggered.
// Replaces state code to add support for alternate pre-move, stay-open and
// other delay time.
// ============================================================================

state() TriggerPound
{
Open:
  if (bTriggerOnceOnly)
    Disable('Trigger');
  bClosed = false;
  
  if (!bAlternateMovement && DelayTime > 0) {
    bDelaying = true;
    Sleep(DelayTime);
  }
  else if (bAlternateMovement && AlternateDelayTime > 0) {
    bDelaying = true;
    Sleep(AlternateDelayTime);
  }
  
  DoOpen();
  FinishInterpolation();
  FinishedOpening();
  
  if (!bAlternateMovement) {
    Sleep(OtherTime);
  }
  else if (bAlternateMovement) {
    Sleep(AlternateOtherTime);
  }
  
Close:
  if (bOpening || bResetting || !bInterpolating && KeyNum > 0)
    DoClose();
  if (bInterpolating) {
    FinishInterpolation();
    FinishedClosing();
  }
  if (bAlternateMovement)
    Sleep(AlternateStayOpenTime);
  else
    Sleep(StayOpenTime);
  
  SetResetStatus(false);
  if (bTriggerOnceOnly)
    GotoState('WasTriggerPound');
  if (SavedTrigger != None)
    Goto 'Open';
}


// ============================================================================
// state TriggerOpenTimed
//
// Toggle when triggered.
// Replaces state code to add support for alternate delay time.
// ============================================================================

state() TriggerToggle
{
Open:
  bClosed = false;
  
  if (!bAlternateMovement && DelayTime > 0) {
    bDelaying = true;
    Sleep(DelayTime);
  }
  else if (bAlternateMovement && AlternateDelayTime > 0) {
    bDelaying = true;
    Sleep(AlternateDelayTime);
  }
  
  DoOpen();
  FinishInterpolation();
  FinishedOpening();
  if (SavedTrigger != None)
    SavedTrigger.EndEvent();
  Stop;
  
Close:		
  if (bOpening || !bInterpolating && KeyNum > 0)
    DoClose();
  if (bInterpolating) {
    FinishInterpolation();
    FinishedClosing();
  }
  SetResetStatus(false);
}


// ============================================================================
// Default Values
// ============================================================================

defaultproperties
{
  NumKeysPrimary    = 2
  
  CloseTime             = 1.0
  AlternateCloseTime    = 1.0
  AlternateDelayTime    = 0.0
  AlternateMoveTime     = 1.0
  AlternateStayOpenTime = 4.0
  AlternateOtherTime    = 0.0
  
  TimeMultipliersClose(0)   = 1.0
  TimeMultipliersClose(1)   = 1.0
  TimeMultipliersClose(2)   = 1.0
  TimeMultipliersClose(3)   = 1.0
  TimeMultipliersClose(4)   = 1.0
  TimeMultipliersClose(5)   = 1.0
  TimeMultipliersClose(6)   = 1.0
  TimeMultipliersClose(7)   = 1.0
  TimeMultipliersClose(8)   = 1.0
  TimeMultipliersClose(9)   = 1.0
  TimeMultipliersClose(10)  = 1.0
  TimeMultipliersClose(11)  = 1.0
  TimeMultipliersClose(12)  = 1.0
  TimeMultipliersClose(13)  = 1.0
  TimeMultipliersClose(14)  = 1.0
  TimeMultipliersClose(15)  = 1.0
  TimeMultipliersClose(16)  = 1.0
  TimeMultipliersClose(17)  = 1.0
  TimeMultipliersClose(18)  = 1.0
  TimeMultipliersClose(19)  = 1.0
  TimeMultipliersClose(20)  = 1.0
  TimeMultipliersClose(21)  = 1.0
  TimeMultipliersClose(22)  = 1.0
  TimeMultipliersClose(23)  = 1.0
  
  TimeMultipliersOpen(0)   = 1.0
  TimeMultipliersOpen(1)   = 1.0
  TimeMultipliersOpen(2)   = 1.0
  TimeMultipliersOpen(3)   = 1.0
  TimeMultipliersOpen(4)   = 1.0
  TimeMultipliersOpen(5)   = 1.0
  TimeMultipliersOpen(6)   = 1.0
  TimeMultipliersOpen(7)   = 1.0
  TimeMultipliersOpen(8)   = 1.0
  TimeMultipliersOpen(9)   = 1.0
  TimeMultipliersOpen(10)  = 1.0
  TimeMultipliersOpen(11)  = 1.0
  TimeMultipliersOpen(12)  = 1.0
  TimeMultipliersOpen(13)  = 1.0
  TimeMultipliersOpen(14)  = 1.0
  TimeMultipliersOpen(15)  = 1.0
  TimeMultipliersOpen(16)  = 1.0
  TimeMultipliersOpen(17)  = 1.0
  TimeMultipliersOpen(18)  = 1.0
  TimeMultipliersOpen(19)  = 1.0
  TimeMultipliersOpen(20)  = 1.0
  TimeMultipliersOpen(21)  = 1.0
  TimeMultipliersOpen(22)  = 1.0
  TimeMultipliersOpen(23)  = 1.0
}
