// ============================================================================
// JBReplicationInfoGame
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBReplicationInfoGame.uc,v 1.7 2003/01/06 11:14:44 mychaeel Exp $
//
// Replicated information for the entire game.
// ============================================================================


class JBReplicationInfoGame extends GameReplicationInfo
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    OrderNameTactics;
  }


// ============================================================================
// Types
// ============================================================================

struct TOrderName {

  var name OrderName;  // actual name of the given order
  var int iOrderName;  // index into the OrderName array in Bot
  };


// ============================================================================
// Variables
// ============================================================================

var JBInfoArena    firstArena;
var JBInfoJail     firstJail;
var JBTagObjective firstTagObjective;
var JBTagPlayer    firstTagPlayer;

var TOrderName OrderNameTactics[6];


// ============================================================================
// PostBeginPlay
//
// Registers order names for the custom team tactics menu in the speech menu.
// ============================================================================

simulated event PostBeginPlay() {

  if (Role == ROLE_Authority)
    RegisterOrderNames();

  Super.PostBeginPlay();
  }


// ============================================================================
// PostNetBeginPlay
//
// On both server and client creates the linked lists for jails and arenas.
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

  Super.PostNetBeginPlay();
  }


// ============================================================================
// RegisterOrderNames
//
// Registers the order names specified in the OrderNameTactics array. Finds
// empty slots in the OrderNames array in class Bot and initializes the order
// name indices in the OrderNameTactics array.
// ============================================================================

function RegisterOrderNames() {

  local int iOrderNameBot;
  local int iOrderNameTactics;
  local Class<Bot> ClassBot;
  
  ClassBot = Class'xBot';
  
  for (iOrderNameBot = 0; iOrderNameBot < ArrayCount(ClassBot.Default.OrderNames); iOrderNameBot++)
    if (ClassBot.Default.OrderNames[iOrderNameBot] == '') {
      OrderNameTactics[iOrderNameTactics++].iOrderName = iOrderNameBot;
      if (iOrderNameTactics == ArrayCount(OrderNameTactics))
        break;
      }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  OrderNameTactics[0] = (OrderName=TacticsAuto);
  OrderNameTactics[1] = (OrderName=TacticsSuicidal);
  OrderNameTactics[2] = (OrderName=TacticsAggressive);
  OrderNameTactics[3] = (OrderName=TacticsNormal);
  OrderNameTactics[4] = (OrderName=TacticsDefensive);
  OrderNameTactics[5] = (OrderName=TacticsEvasive);
  }