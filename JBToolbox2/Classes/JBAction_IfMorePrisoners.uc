// ============================================================================
// JBAction_IfMorePrisoners
// Copyright (c) 2006 by Wormbo <wormbo@onlinehome.de>
// $Id: JBAction_IfMorePrisoners.uc,v 1.2 2007-04-22 14:12:01 wormbo Exp $
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

var array<JBInfoJail> Jails;


// ============================================================================
// ProceedToNextAction
//
// Checks if at least the desired number of players is in the specified jail.
// Skips to the end of the section if either no matching JBInfoJail was found
// or the jail did not contain enough players.
// ============================================================================

function ProceedToNextAction(ScriptedController C)
{
  local JBInfoJail thisJail;
  local int i, Count;
  
  if (Jails.Length == 0) {
    foreach C.AllActors(class'JBInfoJail', thisJail) {
      if (thisJail.Tag == JailTag || thisJail.Name == JailTag)
        Jails[Jails.Length] = thisJail;
    }
    if (Jails.Length == 0)
      log(Self $ " - No JBInfoJail with tag or name " $ JailTag $ " found!", 'Warning');
  }
  C.ActionNum++;
  
  while (i < Jails.Length && Count <= PrisonerCount)
    Count += Jails[i++].CountPlayersTotal();
    
  if (Count <= PrisonerCount)
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
  ActionString  = "If more prisoners than"
}
