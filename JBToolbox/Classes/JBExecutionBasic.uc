// ============================================================================
// JBExecutionBasic
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBasic.uc,v 1.1.1.1 2003/03/12 23:53:20 mychaeel Exp $
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
protected function ExecutePlayer(Controller Victim)
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
