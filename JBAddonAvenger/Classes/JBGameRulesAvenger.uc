// ============================================================================
// JBGameRulesAvenger
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesAvenger.uc,v 1.1 2003/07/27 03:23:37 crokx Exp $
//
// The rules for the Avenger add-on.
// ============================================================================


class JBGameRulesAvenger extends JBGameRules;


// ============================================================================
// NotifyRound
//
// Remove all avenger effects
// ============================================================================

function NotifyRound()
{
  /*local JBInventoryAvenger InfoAvenger;
  
  foreach AllActors(class'JBInventoryAvenger', InfoAvenger)
  {
    // execute something here
  }
  */
  Super.NotifyRound();
}


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena is the Berserker when freedom.
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
  local float ArenaCountDown;
  local int AvengerTime;
  local xPawn Avenger;
  local JBInventoryAvenger InvAvenger;
  
  ArenaCountDown = Arena.GetCountdownTie();
  if(class'JBAddonAvenger'.default.PowerTimeMultiplier > 0)
    ArenaCountDown = (ArenaCountDown * class'JBAddonAvenger'.default.PowerTimeMultiplier) / 100;
  AvengerTime = Clamp(ArenaCountDown, 10, class'JBAddonAvenger'.default.PowerTimeMaximum);  

  if((TagPlayerWinner.GetController() != None)
  && (TagPlayerWinner.GetController().Pawn != None)
  && (TagPlayerWinner.GetController().Pawn.IsA('xPawn')))
  {
    Avenger = xPawn(TagPlayerWinner.GetController().Pawn);
    InvAvenger = Spawn( class'JBInventoryAvenger', Avenger );
    InvAvenger.GiveTo(Avenger);
    InvAvenger.StartAvenger(AvengerTime);
  }

  Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// StartAvenger
//
// Start the avenger effect: give the avenger an inventory item
// ============================================================================

function StartAvenger(xPawn Avenger, int AvengerTime)
{
  
}
