// ============================================================================
// JBGameObjectiveTouchable
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGameObjectiveTouchable.uc,v 1.3 2004/03/19 19:18:54 tarquin Exp $
//
// GameObjective that must be touched to be disabled. TriggeredObjective
// requires an additional trigger for that.
// ============================================================================


class JBGameObjectiveTouchable extends GameObjective
  placeable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBGameObjectiveTouchable.pcx mips=off masked=on group=icons


// ============================================================================
// DisableObjective
//
// Disables this objective if instigated by a player not of the defending team.
// ============================================================================

function DisableObjective(Pawn PawnInstigator) 
{
  if (PawnInstigator                            == None ||
      PawnInstigator.PlayerReplicationInfo      == None ||
      PawnInstigator.PlayerReplicationInfo.Team == None ||
      PawnInstigator.PlayerReplicationInfo.Team.TeamIndex == DefenderTeamIndex)
    return;

  SetCollision(False, False, False);

  Super.DisableObjective(PawnInstigator);
}


// ============================================================================
// Reset
//
// Resets this actor to its default state. Restores its collision properties.
// ============================================================================

function Reset() 
{
  Super.Reset();

  SetCollision(Default.bCollideActors,  // resetting the collision will
               Default.bBlockActors,    // implicitly call Touch again if a
               Default.bBlockPlayers);  // player is still touching this actor
}


// ============================================================================
// Touch
//
// Disables this objective when touched by a player.
// ============================================================================

event Touch(Actor ActorOther) 
{
  if (Pawn(ActorOther) != None)
    DisableObjective(Pawn(ActorOther));
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties 
{
  bCollideActors = True;
  bBlockActors  = False;
  bBlockPlayers = False;
  Texture = Texture'JBToolbox.icons.JBGameObjectiveTouchable';
  Score = 0;
}