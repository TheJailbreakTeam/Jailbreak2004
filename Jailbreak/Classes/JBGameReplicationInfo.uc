// ============================================================================
// JBReplicationInfoGame
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoGame.uc,v 1.6 2003/01/02 14:15:03 mychaeel Exp $
//
// Replicated information for a the entire game.
// ============================================================================


class JBReplicationInfoGame extends GameReplicationInfo
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var JBInfoArena    firstArena;
var JBInfoJail     firstJail;
var JBTagObjective firstTagObjective;
var JBTagPlayer    firstTagPlayer;


// ============================================================================
// PostNetBeginPlay
//
// On both server and client, creates the linked lists for jails and arenas.
// ============================================================================

simulated event PostNetBeginPlay() {

  local JBInfoArena thisArena;
  local JBInfoJail thisJail;
  
  foreach DynamicActors(Class'JBInfoArena', thisArena) {
    thisArena.nextArena = firstArena;
    firstArena = thisArena;
    }
  
  foreach DynamicActors(Class'JBInfoJail', thisJail) {
    thisJail.nextJail = firstJail;
    firstJail = thisJail;
    }
  }
