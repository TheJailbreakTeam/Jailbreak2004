// ============================================================================
// JBBotSquadArena
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquadArena.uc,v 1.1 2002/12/20 20:54:30 mychaeel Exp $
//
// Controls the bots fighting in an arena.
// ============================================================================


class JBBotSquadArena extends DMSquad
  notplaceable;


// ============================================================================
// AddBot
//
// If the bot is currently following a scripted sequence, stops it.
// ============================================================================

function AddBot(Bot Bot) {

  Super.AddBot(Bot);

  Bot.FreeScript();
  TeamPlayerReplicationInfo(Bot.PlayerReplicationInfo).bHolding = False;
  }
