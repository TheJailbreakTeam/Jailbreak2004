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
//=============================================================================
class JBJailCardFire extends BioFire;


//=============================================================================
// TeleportMe
//
// Restarts the player in freedom!
//=============================================================================

function TeleportMe(Pawn P, JBGameRulesJailCard myRules) {
    local JBTagPlayer myTag;

    myRules.UseCard(P.Controller.PlayerReplicationInfo, -1);
    myTag = Class'JBTagPlayer'.static.FindFor(P.Controller.PlayerReplicationInfo);
    myTag.RestartInFreedom();
}


//=============================================================================
// SpawnProjectile
//
// we dont spawn any projectiles
//=============================================================================

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    return none;
}

defaultproperties
{
    AmmoPerFire=0;
}
