// ============================================================================
// JBExecutionBasic
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionBasic.uc,v 1.2 2003/03/15 23:41:31 mychaeel Exp $
//
// A basic execution.
// ============================================================================
class JBExecutionBasic extends JBExecution;


// ============================================================================
// Variables
// ============================================================================
var() class<DamageType> DeathType;


// ============================================================================
// Trigger
//
// When this class are Triggered.
// ============================================================================
function Trigger(Actor A, Pawn P)
{
    ExecuteAllJailedPlayers(TRUE, DeathType);
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    DeathType=class'Gibbed'
}
