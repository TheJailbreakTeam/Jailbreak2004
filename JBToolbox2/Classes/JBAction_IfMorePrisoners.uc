// ============================================================================
// JBAction_IfMorePrisoners
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBAction_IfMorePrisoners.uc,v 1.1 2006-11-29 19:14:28 jrubzjeknf Exp $
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
//
// Checks if at least the desired number of players is in the specified jail.
// Skips to the end of the section if either no matching JBInfoJail was found
// or the jail did not contain enough players.
// ============================================================================

function ProceedToNextAction(ScriptedController C)
{
  if (Jail == None && JailTag != 'None') {
    ForEach C.AllActors(class'JBInfoJail', Jail, JailTag)
      break;
  }
  C.ActionNum++;

  if (Jail == None) {
    warn("No JBInfoJail with tag " $ JailTag $ " found, breaking " $ C.SequenceScript);
    ProceedToSectionEnd(C);
    return;
  }

  if (Jail.CountPlayersTotal() <= PrisonerCount)
    ProceedToSectionEnd(C);
}


// ============================================================================
// StartsSection
//
// Returns True because this action is the start of a block of actions.
// ============================================================================

function bool StartsSection()
{
  return true;
}


// ============================================================================
// GetActionString
//
// Returns a string describing this scripted action.
// ============================================================================

function string GetActionString()
{
  return ActionString @ PrisonerCount @ JailTag;
}


// ============================================================================
// Default Properties
// ============================================================================

defaultproperties
{
  ActionString="If more prisoners than"
}
