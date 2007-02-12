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
//=============================================================================
class JBWeaponJailCard extends BioRifle;


//=============================================================================
// Variables
//=============================================================================

var JBGameRulesJailCard myRules;


//=============================================================================
// setGameRules
//=============================================================================

function setGameRules(JBGameRulesJailCard JBGR) {
	myRules = JBGR;
}


//=============================================================================
// Fire & alt fire
//=============================================================================

simulated function Fire(float F)
{
    JBJailCardFire(FireMode[0]).TeleportMe(Instigator, myRules);
}


simulated function AltFire(float F)
{
    JBJailCardFire(FireMode[1]).TeleportMe(Instigator, myRules);
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
}
