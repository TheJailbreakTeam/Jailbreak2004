// ============================================================================
// JBExecutionBasic
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBasic.uc, v1.00 2003/02/28 ??:?? crokx Exp $
//
// Base of all triggered execution.
// ============================================================================
class JBExecutionBasic extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var() class<DamageType> DeathType;


// ============================================================================
// ExecutePlayer
//
// Execute a player.
// ============================================================================
private function ExecutePlayer(Controller Victim)
{
    Victim.Pawn.Died(None, DeathType, vect(0,0,0));
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    DeathType=Gibbed
}
