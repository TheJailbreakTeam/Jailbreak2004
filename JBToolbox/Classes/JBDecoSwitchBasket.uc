// ============================================================================
// JBDecoSwitchBasket
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Holder for emitter resembling a basket for the standard release switch.
// ============================================================================


class JBDecoSwitchBasket extends Decoration
  notplaceable;


// ============================================================================
// Properties
// ============================================================================

var() Material MaterialSkinRed;
var() Material MaterialSkinBlue;


// ============================================================================
// Variables
// ============================================================================

var Emitter Emitter;


// ============================================================================
// PostBeginPlay
//
// Spawns an Emitter actor which holds the configured ParticleEmitter.
// ============================================================================

simulated event PostBeginPlay()
{
  Emitter = Spawn(Class'JBEmitterBasket', Self, , Location + PrePivot, Rotation);
  
  switch (GameObjective(Owner).DefenderTeamIndex) {
    case 0:  Emitter.Skins[0] = MaterialSkinRed;   break;
    case 1:  Emitter.Skins[0] = MaterialSkinBlue;  break;
  }
}


// ============================================================================
// Trigger
//
// Triggers the emitter.
// ============================================================================

event Trigger(Actor ActorOther, Pawn PawnInstigator)
{
  Emitter.Trigger(ActorOther, PawnInstigator);
}


// ============================================================================
// UnTrigger
//
// Untriggers the emitter.
// ============================================================================

event UnTrigger(Actor ActorOther, Pawn PawnInstigator)
{
  Emitter.UnTrigger(ActorOther, PawnInstigator);
}


// ============================================================================
// Destroyed
//
// Destroys the emitter.
// ============================================================================

event Destroyed()
{
  Emitter.Destroy();
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  Location                  = (Z=-40.0);

  bStatic                   = False;
  bBlockActors              = False;
  bBlockNonZeroExtentTraces = False;
  bBlockPlayers             = False;
  bCollideActors            = False;
  bCollideWorld             = False;

  MaterialSkinRed           = Shader'XGameShaders.BRShaders.BombIconRS';
  MaterialSkinBlue          = Shader'XGameShaders.BRShaders.BombIconBS';
}