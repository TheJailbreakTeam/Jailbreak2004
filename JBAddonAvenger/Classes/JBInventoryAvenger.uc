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
  // do this in GiveTo instead?
  local Combo AvengerCombo;
  local class<Combo> ComboClass;

  
  if( xPawn(Owner) == None )
    return; // daft but just in case
    
  xPawn(Owner).Controller.Adrenaline = 1; 
  // cheat adrenaline for now. 
  // arena winner should be awarded adrenaline by core game rules.    

  ComboClass = class'JBAddonAvenger'.default.ComboClasses[class'JBAddonAvenger'.default.PowerComboIndex];

  if( ComboClass == None )
    log("JB AVENGER: No combo class!");

  xPawn(Owner).DoCombo(ComboClass);  
  xPawn(Owner).CurrentCombo.AdrenalineCost = 0;
  
  SetTimer(AvengerTime, False);

  xPawn(Owner).ReceiveLocalizedMessage(class'JBLocalMessageAvenger', AvengerTime);
}


// ============================================================================
// SetAvengerTime
// 
// Called by JBGameRulesAvenger. Sets the timer. Owned by the avenger combo
// ============================================================================

function SetAvengerTime(int AvengerTime) 
{
  SetTimer(AvengerTime, False);
}


// ============================================================================
// Timer
//
// Stop the avenger effect after the AvengerTime delay.
// ============================================================================

function Timer()
{
  Destroy();
}


// ============================================================================
// Destroyed
//
// Stop the avenger effect by destroying the owner combo
// ============================================================================

event Destroyed() {
  if( xPawn(Owner) != None 
    && xPawn(Owner).CurrentCombo != None
  ) {
    xPawn(Owner).CurrentCombo.Destroy();
  }
}
