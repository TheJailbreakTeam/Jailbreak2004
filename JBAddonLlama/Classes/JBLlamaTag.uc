//=============================================================================
// JBLlamaTag
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// The JBLlamaTag is added to a llama's inventory to identify him or her as the
// llama and to handle llama effects.
//=============================================================================


class JBLlamaTag extends Inventory;


//=============================================================================
// variables
//=============================================================================

var JBGameRulesLlamaHunt       LlamaHuntRules;  // JBGameRules class for Jailbreak notifications
var JBInterfaceLlamaHUDOverlay HUDOverlay;      // HUD overlay for drawing llama compass and arrows
var JBLlamaTrailer             Trail;           // 3rd person xEmitter effect for the llama
var JBLlamaArrow               LlamaArrow;      // client-side spinning arrow over the llama's head
var JBTagPlayer                TagPlayer;       // the llama's JBTagPlayer

//=============================================================================
// PostBeginPlay
//
// Finds a JBGameRulesLlamaHunt actor which is responsible for preventing
// llamas from releasing team mates and from sending players killed by them to
// jail.
//=============================================================================

simulated event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
  HUDOverlay = class'JBInterfaceLlamaHUDOverlay'.static.FindLlamaHUDOverlay(Self);
  LlamaArrow = Spawn(class'JBLlamaArrow', Self);
}


//=============================================================================
// PostNetBeginPlay
//
// Registers the JBLlamaTag clientside as an overlay.
//=============================================================================

simulated event PostNetBeginPlay()
{
  Super.PostNetBeginPlay();
  
  if ( Role < ROLE_Authority )
    InitLlamaTag();
}


//=============================================================================
// GiveTo
//
// Registers the JBLlamaTag as an overlay offline and on listen servers.
//=============================================================================

function GiveTo(Pawn Other, optional Pickup Pickup)
{
  Super.GiveTo(Other, Pickup);
  
  Trail = Spawn(class'JBLlamaTrailer', Owner);
  
  //log("Tagged"@Owner@"as llama.", Name);
  
  if ( Level.NetMode != NM_DedicatedServer )
    InitLlamaTag();
}


//=============================================================================
// InitLlamaTag
//
// Registers the JBLlamaTag as an overlay and add the llama effects.
//=============================================================================

simulated function InitLlamaTag()
{
  local PlayerController PlayerControllerLocal;
  
  //log("InitLlamaTag()", Name);
  
  // find local playercontroller
  PlayerControllerLocal = Level.GetLocalPlayerController();
  
  if ( Pawn(Owner) != None )
    TagPlayer = class'JBTagPlayer'.static.FindFor(Pawn(Owner).PlayerReplicationInfo);
  else
    warn("Owner ="@Owner);
  
  // make sure that the local player owns the llama tag
  if ( Pawn(Owner) != None && PlayerControllerLocal == Pawn(Owner).Controller ) {
    //log("Found local player.", Name);
    
    //JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);
    HUDOverlay.SetLocalLlamaTag(Self);
  }
}


//=============================================================================
// Destroyed
//
// Unregister the JBLlamaTag and remove the llama effects.
//=============================================================================

simulated event Destroyed()
{
  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None ) {
    JBInterfaceHud(PlayerControllerLocal.myHud).UnregisterOverlay(Self);
  }
  
  if ( Trail != None ) {
    Trail.Destroy();
  }
  
  if ( LlamaArrow != None ) {
    LlamaArrow.LlamaDied();
  }
  
  Super.Destroyed();
}


//=============================================================================
// Tick
//
// Update third person llama effects.
//=============================================================================

simulated function Tick(float DeltaTime)
{
  Pawn(Owner).SetHeadScale(2.0 + 1.0 * Cos(2.0 * Level.TimeSeconds));
  
  if ( Pawn(Owner).Controller != None && Pawn(Owner).Controller.Pawn != None
      && Trail != None && Trail.Owner != Pawn(Owner).Controller.Pawn )
    Trail.SetOwner(Pawn(Owner).Controller.Pawn);
}

//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  bGameRelevant=True
  bAlwaysRelevant=True
  bOnlyRelevantToOwner=False
}