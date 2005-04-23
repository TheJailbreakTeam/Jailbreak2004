// ============================================================================
// JBBotSquadArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquadArena.uc,v 1.5 2004/05/18 20:00:00 mychaeel Exp $
//
// Controls the bots fighting in an arena.
// ============================================================================


class JBBotSquadArena extends DMSquad
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextArena;


// ============================================================================
// AddBot
//
// If the bot is currently following a scripted sequence, stops it.
// ============================================================================

function AddBot(Bot Bot)
{
  Super.AddBot(Bot);

  Bot.FreeScript();
  TeamPlayerReplicationInfo(Bot.PlayerReplicationInfo).bHolding = False;
}


// ============================================================================
// SetEnemy
//
// Ignores all players except those in the same arena.
// ============================================================================

function bool SetEnemy(Bot Bot, Pawn PawnEnemy)
{
  local JBTagPlayer TagPlayerBot;
  local JBTagPlayer TagPlayerEnemy;

  TagPlayerBot   = Class'JBTagPlayer'.Static.FindFor(Bot      .PlayerReplicationInfo);
  TagPlayerEnemy = Class'JBTagPlayer'.Static.FindFor(PawnEnemy.PlayerReplicationInfo);

  if (TagPlayerEnemy == None ||
      TagPlayerEnemy.GetArena() != TagPlayerBot.GetArena())
    return False;

  return Super.SetEnemy(Bot, PawnEnemy);
}


// ============================================================================
// AssignCombo
//
// Does nothing. Required because bots are given full adrenaline temporarily
// while they're in the arena to prevent them from going after adrenaline
// pills (which they cannot pick up anyway).
// ============================================================================

function AssignCombo(Bot Bot)
{
  // do nothing, adrenaline is disabled
}


// ============================================================================
// GetOrderStringFor
//
// Returns a string describing the given player's current status. That is,
// in this squad, simply that they're fighting in an arena.
// ============================================================================

simulated function string GetOrderStringFor(TeamPlayerReplicationInfo TeamPlayerReplicationInfo)
{
  return TextArena;
}


// ============================================================================
// AssignSquadResponsibility
//
// Makes bots use vehicles in the arena if there are any.
// ============================================================================

function bool AssignSquadResponsibility(Bot Bot)
{
  if (CheckVehicle(Bot))
    return True;

  return Super.AssignSquadResponsibility(Bot);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TextArena = "fighting in arena";
}