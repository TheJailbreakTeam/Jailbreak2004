// ============================================================================
// JBAction_WaitOnlyForTimer
// Copyright (c) 2007 by Wormbo <wormbo@online.de>
// $Id: JBAction_WaitForEvent.uc,v 1.1 2007-04-28 10:57:28 wormbo Exp $
//
// Waits exclusively for timer and unlike its superclass NOT for triggering.
// ============================================================================


class JBAction_WaitOnlyForTimer extends Action_WaitForTimer;


// ============================================================================
// CompleteWhenTriggered
//
// Does NOT react to triggering. (Why should it anyway?)
// ============================================================================

function bool CompleteWhenTriggered()
{
  return false;
}