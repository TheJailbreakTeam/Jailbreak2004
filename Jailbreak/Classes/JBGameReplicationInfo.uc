// ============================================================================
// JBReplicationInfoGame
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoGame.uc,v 1.4 2002/12/23 01:11:24 mychaeel Exp $
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
// On the server, creates a JBTagObjective actor for every objective in game.
// On both server and client, creates the linked lists for jails and arenas.
// ============================================================================

simulated event PostNetBeginPlay() {

  local GameObjective thisObjective;
  local JBInfoArena thisArena;
  local JBInfoJail thisJail;
  
  if (Role == ROLE_Authority)
    foreach AllActors(Class'GameObjective', thisObjective)
      Class'JBTagObjective'.Static.SpawnFor(thisObjective);

  foreach DynamicActors(Class'JBInfoArena', thisArena) {
    thisArena.nextArena = firstArena;
    firstArena = thisArena;
    }
  
  foreach DynamicActors(Class'JBInfoJail', thisJail) {
    thisJail.nextJail = firstJail;
    firstJail = thisJail;
    }
  }
