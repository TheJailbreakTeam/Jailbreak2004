// ============================================================================
// JBGameReplicationInfo
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameReplicationInfo.uc,v 1.10 2003/02/26 20:01:30 mychaeel Exp $
//
// Replicated information for the entire game.
// ============================================================================


class JBGameReplicationInfo extends GameReplicationInfo
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    bIsExecuting, OrderNameTactics;
  }


// ============================================================================
// Types
// ============================================================================

struct TOrderName {

  var name OrderName;  // name of order passed to SetOrders
  var int iOrderName;  // index into OrderName array in class Bot
  };


// ============================================================================
// Variables
// ============================================================================

var bool bIsExecuting;                 // set during an execution sequence

var JBInfoArena    firstArena;         // first arena in chain
var JBInfoJail     firstJail;          // first jail in chain
var JBTagObjective firstTagObjective;  // first objective tag in chain
var JBTagPlayer    firstTagPlayer;     // first player tag in chain

var TOrderName OrderNameTactics[6];    // registered tactics order names


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