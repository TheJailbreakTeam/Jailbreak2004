//=============================================================================
// JBJailCardFire
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// $Id$
//
// Firemode for JBWeaponJailCard
//
// CHANGELOG:
// 11 feb 2007 - Class created
// 12 feb 2007 - Modified TeleportMe to notify our gamerules class of card-use
// 19 may 2007 - Added JBGameRules and Pawn variables
//               Removed TeleportMe, moved contents to SpawnProjectile
//               Added mutator method for JBGameRules and Pawn variables
//=============================================================================
class JBJailCardFire extends BioFire;


var JBGameRulesJailCard myRules;
var Pawn myPawn;


//=============================================================================
// setGameRules
//=============================================================================

function setVars(JBGameRulesJailCard JBGR, Pawn P) {
    myRules = JBGR;
    myPawn = P;
}


//=============================================================================
// SpawnProjectile
//
// we dont spawn any projectiles, instead we teleport the player
//=============================================================================

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local JBTagPlayer myTag;

    myRules.UseCard(myPawn.Controller.PlayerReplicationInfo, -1);
    myTag = Class'JBTagPlayer'.static.FindFor(myPawn.Controller.PlayerReplicationInfo);
    myTag.RestartInFreedom();

    return none;
}

defaultproperties
{
    AmmoPerFire=0;
}
