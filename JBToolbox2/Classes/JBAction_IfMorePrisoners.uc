// ============================================================================
// JBAction_IfMorePrisoners
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id$
// ============================================================================


class JBAction_IfMorePrisoners extends ScriptedAction;


// ============================================================================
// Properties
// ============================================================================

var(Action) name JailTag;
var(Action) int PrisonerCount;


// ============================================================================
// Variables
// ============================================================================

var JBInfoJail Jail;


// ============================================================================
// ProceedToNextAction
// ============================================================================

function ProceedToNextAction(ScriptedController C)
{
  if (Jail == None && JailTag != 'None')
    ForEach C.AllActors(class'JBInfoJail', Jail, JailTag)
      break;

  C.ActionNum += 1;

  if (Jail == None) {
    warn("No JBInfoJail with tag " $ JailTag $ " found, breaking " $ C.SequenceScript);
    ProceedToSectionEnd(C);
    return;
  }

  if (Jail.CountPlayersTotal() <= PrisonerCount)
    ProceedToSectionEnd(C);
}

function bool StartsSection()
{
  return true;
}

function string GetActionString()
{
  return ActionString @ Jail @ JailTag;
}


// ============================================================================
// Default Properties
// ============================================================================

defaultproperties
{
  ActionString="If more prisoners"
}
