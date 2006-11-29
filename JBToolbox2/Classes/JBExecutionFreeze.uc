// ============================================================================
// JBExecutionFreeze
// Copyright 2005 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Freezes all players (makes them immovable and adds fancy first- and third-
// person effects), then shatters them all.
// ============================================================================


class JBExecutionFreeze extends JBExecution
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec Texture import file=Textures\JBExecutionFreeze.dds mips=off masked=on group=icons


// ============================================================================
// ExecuteJailedPlayer
//
// Spawns an JBEmitterFreeze for the given victim which does the actual work,
// including shattering the victim at a later stage.
// ============================================================================

function ExecuteJailedPlayer(Pawn PawnVictim)
{
  Spawn(Class'JBFreezer', PawnVictim);
}


// ============================================================================
// default properties
// ============================================================================

defaultproperties
{
  Texture=Texture'JBToolbox2.icons.JBExecutionFreeze'
}
