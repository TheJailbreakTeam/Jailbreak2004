// ============================================================================
// JBProbeEvent
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBProbeEvent.uc,v 1.1.1.1 2002/11/16 20:35:10 mychaeel Exp $
//
// Forwards handling of an event with a given Tag to another class.
// ============================================================================


class JBProbeEvent extends Actor
  notplaceable;


// ============================================================================
// Delegates
// ============================================================================

delegate OnTrigger  (Actor ActorOther, Pawn PawnInstigator);
delegate OnUnTrigger(Actor ActorOther, Pawn PawnInstigator);


// ============================================================================
// Trigger
//
// Forwards triggering event to the delegate.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator) {

  OnTrigger(ActorOther, PawnInstigator);
  }


// ============================================================================
// UnTrigger
//
// Forwards untriggering event to the delegate.
// ============================================================================

event UnTrigger(Actor ActorOther, Pawn PawnInstigator) {

  OnUnTrigger(ActorOther, PawnInstigator);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  bHidden = True;
  }