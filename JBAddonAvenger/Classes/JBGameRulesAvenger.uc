// ============================================================================
// JBGameRulesAvenger
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesAvenger.uc,v 1.1 2004/04/09 19:16:35 tarquin Exp $
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
  
  if (TagPlayerWinner != None)
  {
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
