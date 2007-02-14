//=============================================================================
// JBLlamaPendingTag
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaPendingTag.uc,v 1.3 2004/05/31 11:14:57 wormbo Exp $
//
// Spawned for Controllers without a Pawn to make the next xPawn possessed by
// that Controller a Llama.
//=============================================================================


class JBLlamaPendingTag extends Inventory
  notplaceable;


//=============================================================================
// variables
//=============================================================================

var JBGameRulesLlamaHunt LlamaHuntRules; // JBGameRules class for Jailbreak notifications


//=============================================================================
// PostBeginPlay
//
// Finds a JBGameRulesLlamaHunt actor which is responsible for preventing
// llamas from releasing team mates and from sending players killed by them to
// jail. Adds this tag to the owner's Inventory chain for faster lookup.
//=============================================================================

function PostBeginPlay()
{
  local Actor OwnerInventory;
  
  OwnerInventory = Owner;
  while(OwnerInventory.Inventory != None) {
    OwnerInventory = OwnerInventory.Inventory;
  }
  OwnerInventory.Inventory = Self;
  
  LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
}


//=============================================================================
// Destroyed
//
// Remove this tag from the owner's Inventory chain.
//=============================================================================

function Destroyed()
{
  local Actor OwnerInventory;
  
  if (Owner != None) {
    OwnerInventory = Owner;
    while(OwnerInventory.Inventory != None && OwnerInventory.Inventory != Self) {
      OwnerInventory = OwnerInventory.Inventory;
    }
    OwnerInventory.Inventory = Inventory;
  }
  Inventory = None;
}


//=============================================================================
// Tick
//
// Checks, whether the Controller has an xPawn and activates the Llama effect
// if that's the case.
//=============================================================================

function Tick(float DeltaTime)
{
  if ( Controller(Owner) == None )
    Destroy();
  else if ( xPawn(Controller(Owner).Pawn) != None ) {
    //log("Spawning JBLlamaTag for"@Controller(Owner).Pawn, Name);
    Controller(Owner).Pawn.CreateInventory("JBAddonLlama.JBLlamaTag");
    Destroy();
  }
  else if ( Vehicle(Controller(Owner).Pawn) != None && xPawn(Vehicle(Controller(Owner).Pawn).Driver) != None ) {
    //log("Spawning JBLlamaTag for"@Controller(Owner).Pawn, Name);
    Vehicle(Controller(Owner).Pawn).Driver.CreateInventory("JBAddonLlama.JBLlamaTag");
    Destroy();
  }
}
