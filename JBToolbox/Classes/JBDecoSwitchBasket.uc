// ============================================================================
// JBDecoSwitchBasket
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBDecoSwitchBasket.uc,v 1.3 2004-07-25 14:03:59 mychaeel Exp $
//
// Holder for emitter resembling a basket for the standard release switch.
// ============================================================================


class JBDecoSwitchBasket extends Decoration
  notplaceable;


// ============================================================================
// Variables
// ============================================================================

var JBEmitterBasket Emitter;


// ============================================================================
// PostBeginPlay
//
// Spawns an Emitter actor which holds the configured ParticleEmitter.
// ============================================================================

simulated event PostBeginPlay()
{
  Emitter = Spawn(Class'JBEmitterBasket', Self, , Location + PrePivot, Rotation);
  Emitter.SetDefendingTeam(GameObjective(Owner).DefenderTeamIndex);
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

  RemoteRole                = ROLE_None;
}
