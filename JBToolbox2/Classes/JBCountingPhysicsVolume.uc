// ============================================================================
// JBCountingPhysicsVolume
// Copyright 2007 by Wormbo <wormbo@onlinehome.de>
// $Id: JBCountingPhysicsVolume.uc,v 1.1 2007-05-14 15:37:42 jrubzjeknf Exp $
//
// Only get triggered when the first Pawn enters the Volume, and untriggers
// when the last Pawn leaves the Volume.
// ============================================================================


class JBCountingPhysicsVolume extends PhysicsVolume;


// ============================================================================
// Properties
// ============================================================================

var(PhysicsVolume) byte TeamIndex;


// ============================================================================
// Variables
// ============================================================================

var bool bPawnsInVolume;


// ============================================================================
// Reset
//
// There are no Pawns in the Volume at a reset.
// ============================================================================

function Reset()
{
  Super.Reset();

  bPawnsInVolume = False;
}


// ============================================================================
// PawnEnteredVolume
//
// Trigger only when the first Pawn enters the Volume.
// ============================================================================

simulated event PawnEnteredVolume(Pawn Other)
{
  local vector HitLocation,HitNormal;
  local Actor SpawnedEntryActor;

  // Copy from PhysicsVolume.PawnEnteredVolume().
  if ( bWaterVolume && (Level.TimeSeconds - Other.SplashTime > 0.3) && (PawnEntryActor != None) && !Level.bDropDetail && (Level.DetailMode != DM_Low) && EffectIsRelevant(Other.Location,false) &&
      !TraceThisActor(HitLocation, HitNormal, Other.Location - Other.CollisionHeight*vect(0,0,1), Other.Location + Other.CollisionHeight*vect(0,0,1)) )
    SpawnedEntryActor = Spawn(PawnEntryActor,Other,,HitLocation,rot(16384,0,0));

  // Trigger only the first time a Pawn enters.
  if (Role == ROLE_Authority && !bPawnsInVolume && Other.IsPlayerPawn() && Other.GetTeamNum() == TeamIndex) {
    TriggerEvent(Event, self, Other);
    bPawnsInVolume = True;
  }
}


// ============================================================================
// PawnLeavingVolume
//
// Untriggers if all the Pawns left the Volume.
// ============================================================================

event PawnLeavingVolume(Pawn Other)
{
  if (!PawnsInVolume() && Other.IsPlayerPawn() && Other.GetTeamNum() == TeamIndex)
    UntriggerEvent(Event, self, Other);
}


// ============================================================================
// PlayerPawnDiedInVolume
//
// Untriggers if there are no more Pawns in the Volume.
// ============================================================================

function PlayerPawnDiedInVolume(Pawn Other)
{
  if (!PawnsInVolume() && Other.GetTeamNum() == TeamIndex)
    UntriggerEvent(Event,self, Other);
}


// ============================================================================
// PawnsInVolume
//
// Checks if there are any Pawns in the Volume present.
// ============================================================================

function bool PawnsInVolume()
{
  local Pawn P;

  // Check if there are any Pawns in the Volume present.
  foreach TouchingActors(class'Pawn', P)
    if (Encompasses(P) && P.GetTeamNum() == TeamIndex && P.IsPlayerPawn() && P.Health > 0) {
      bPawnsInVolume = True;
      return True;
    }

  bPawnsInVolume = False;
  return False;
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  TeamIndex = 255
}
