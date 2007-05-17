// ============================================================================
// JBAction_DisplayMessage
// Copyright 2007 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id$
//
// Displays a message to a certain group of players.
// ============================================================================


class JBAction_DisplayMessage extends ACTION_DisplayMessage;


// ============================================================================
// Properties
// ============================================================================

var(Action) byte TeamIndex;
var(Action) bool bSendToFree;
var(Action) bool bSendToArenaCombatants;
var(Action) bool bSendToJailed;


// ============================================================================
// InitActionFor
//
// Sends a message to the appropiate players.
// ============================================================================

function bool InitActionFor(ScriptedController SC)
{
  local Controller C;

  if (bBroadCast)
    for (C = SC.Level.ControllerList; C != None; C = C.nextController)
      MessageTo(C.Pawn);
  else
    MessageTo(SC.GetInstigator());

  return False;
}


// ============================================================================
// MessageTo
//
// Sends a message to the Pawn if it meets certain conditions.
// ============================================================================

function MessageTo(Pawn P)
{
  local JBTagPlayer TagPlayer;

  if (P == None)
    return;

  if (TeamIndex != 255 && P.GetTeamNum() != TeamIndex)
    return;

  TagPlayer = class'JBTagPlayer'.static.FindFor(P.PlayerReplicationInfo);

  if (TagPlayer.IsFree()) {
    if (bSendToFree)
      P.ClientMessage(Message, MessageType);
  } else if (TagPlayer.IsInArena()) {
    if (bSendToArenaCombatants)
      P.ClientMessage(Message, MessageType);
  } else {
    if (bSendToJailed)
      P.ClientMessage(Message, MessageType);
  }
}


// ============================================================================
// GetActionString
//
// Returns a string describing this scripted action.
// ============================================================================

function string GetActionString()
{
	return ActionString @ "\"" $ Message $ "\"" @ TeamIndex @ bSendToFree @ bSendToArenaCombatants @ bSendToJailed;
}


// ============================================================================
// Default Properties
// ============================================================================

defaultproperties
{
  ActionString="display JB message"
}
