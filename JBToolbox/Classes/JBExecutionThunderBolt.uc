// ============================================================================
// JBExecutionThunderbolt
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionThunderbolt.uc, v1.00 2003/02/28 ??:?? crokx Exp $
//
// An thunderbolt execution.
// ============================================================================
class JBExecutionThunderbolt extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
const MAX_THUNDERBOLT_DIST = 5120;


// ============================================================================
// ExecutePlayer
//
// Execute a player.
// ============================================================================
private function ExecutePlayer(Controller Victim)
{
    local Actor HitActor;
    local JBEffectThunderbolt Beam;
    local vector HitLocation, HitNormal, EndTrace, VictimLoc, StartThunderBoltLoc;

    VictimLoc = Victim.Pawn.Location + (vect(0,0,1)*24);
    EndTrace = VictimLoc + vector(Rot(16384,0,0)) * MAX_THUNDERBOLT_DIST;
    HitActor = Trace(HitLocation, HitNormal, EndTrace, VictimLoc, true);

    if(HitActor != None) StartThunderBoltLoc = HitLocation - (vect(0,0,1)*16);
    else StartThunderBoltLoc = EndTrace;

    Beam = Spawn(class'JBEffectThunderbolt',,, StartThunderBoltLoc);
    if(Beam != None)
    {
        Beam.mSpawnVecA = VictimLoc;
        Victim.Pawn.TakeDamage(1000, Instigator, VictimLoc, vector(Victim.Pawn.Rotation)*0.5, class'DamTypeSniperShot');
    }
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
}
