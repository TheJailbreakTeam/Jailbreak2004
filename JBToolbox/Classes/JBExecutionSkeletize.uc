// ============================================================================
// JBExecutionSkeletize
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBExecutionSkeletize.uc,v 1.1 2003/06/27 11:14:02 crokx Exp $
//
// An Skeletization execution.
// ============================================================================


class JBExecutionSkeletize extends JBExecution;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBExecutionSkeletize.pcx mips=off masked=on group=icons


// ============================================================================
// ExecuteJailedPlayer
//
// Execute a player.
// ============================================================================

function ExecuteJailedPlayer(Pawn Victim)
{
  local xPawn xVictim;

  xVictim = xPawn(Victim);
  if(xVictim != None) {
    xVictim.PlaySound(xVictim.GibGroupClass.static.GibSound(), SLOT_Pain,2.5*TransientSoundVolume,true,500);
    if(class'GameInfo'.Static.UseLowGore()) Spawn(xVictim.GibGroupClass.default.LowGoreBloodGibClass,,, Victim.Location);
    else Spawn(xVictim.GibGroupClass.default.BloodGibClass,,, Victim.Location);
  }
  else
    LOG("!!!!!"@name$".ExecutePlayer() : victim is not a xPawn !!!!!");

  if(HasSkelete(Victim)) Victim.Died(None, class'JBDamageTypeSkeletize', vect(0,0,0));
  else Victim.Died(None, class'Suicided', vect(0,0,0));
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
  Texture = Texture'JBToolbox.icons.JBExecutionSkeletize';  
}
