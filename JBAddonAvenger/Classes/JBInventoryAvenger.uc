//=============================================================================
// JBInventoryAvenger
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id$
//
// Spawned for each avenger player. Gives the player the combo and then 
// destroys it after set time.
//=============================================================================


class JBInventoryAvenger extends Inventory;
  
  
// ============================================================================
// StartAvenger
// 
// Called by JBGameRulesAvenger. Sets the timer.
// Using a combo class means the avenger's death automatically removes the combo
// ============================================================================

function StartAvenger(int AvengerTime) 
{
  // could be done in GiveTo() instead but we need to receive the time value
  local Combo AvengerCombo;
  local class<Combo> ComboClass;

  
  if( xPawn(Owner) == None )
    return; // daft but just in case
    
  ComboClass = class'JBAddonAvenger'.default.ComboClasses[class'JBAddonAvenger'.default.PowerComboIndex];

  if( ComboClass == None )
    log("JB AVENGER: No combo class!");

  xPawn(Owner).DoCombo(ComboClass);  
  xPawn(Owner).CurrentCombo.AdrenalineCost = 0;
  
  SetTimer(AvengerTime, False);

  xPawn(Owner).ReceiveLocalizedMessage(class'JBLocalMessageAvenger', AvengerTime);
}


// ============================================================================
// Timer
//
// Destroy self after the AvengerTime delay: will stop the avenger effect
// ============================================================================

function Timer()
{
  Destroy();
}


// ============================================================================
// Destroyed
//
// Stop the avenger effect by destroying the owner's combo
// ============================================================================

event Destroyed() {
  if( xPawn(Owner) != None 
    && xPawn(Owner).CurrentCombo != None
  ) {
    xPawn(Owner).CurrentCombo.Destroy();
  }
}
