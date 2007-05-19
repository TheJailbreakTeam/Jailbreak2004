//=============================================================================
// JBWeaponJailCard
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// $Id$
//
// The JailCard cardholders can select in the jail to be freed
//
// CHANGELOG:
// 11 feb 2007 - Class created
// 12 feb 2007 - Added myRules variable and corresponding mutator-method
// 19 may 2007 - Moved myRules variable to weaponfire class, changed
//               setGameRules into setVars, changed parameters
//=============================================================================
class JBWeaponJailCard extends BioRifle;


//=============================================================================
// setGameRules
//=============================================================================

function setVars(JBGameRulesJailCard JBGR, Pawn P) {
    JBJailCardFire(FireMode[0]).setVars(JBGR, P);
    JBJailCardFire(FireMode[1]).setVars(JBGR, P);
}



function float GetAIRating()
{
    return AIRating;
}


//=============================================================================
// defaultproperties
//=============================================================================

DefaultProperties
{
    ItemName="Get Out Of Jail Free Card";
    Description="";
    PickupClass=none;
    bCanThrow=false;
    FireModeClass(0)=JBJailCardFire;
    FireModeClass(1)=JBJailCardFire;
    Priority=0;
    InventoryGroup=10;
    AIRating=+2.00
    CurrentRating=+2.00
}
