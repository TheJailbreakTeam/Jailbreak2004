//=============================================================================
// JBLlamaPendingTag
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Spawned for Controllers without a Pawn to make the next xPawn possessed by
// that Controller a Llama.
//=============================================================================


class JBLlamaPendingTag extends Info
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
// jail.
// If the Owner is a Controller, the next xPawn possessed by that controller
// will be made a Llama.
//=============================================================================

simulated event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  //log("Tagged"@Owner@"as llama.", Name);
  
  if ( Role == ROLE_Authority ) {
    LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
  }
}


//=============================================================================
// Tick
//
// Checks, whether the Controller has a Pawn and activates the Llama effect
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
}
