// ============================================================================
// JBGameRulesTeleport
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id$
//
// The rules for the teleport addon.
// ============================================================================


class JBGameRulesTeleport extends JBGameRules;


// ============================================================================
// Constants
// ============================================================================

const CHANCE_AMOUNT = 20; // seek maximum 5x time


// ============================================================================
// Variables
// ============================================================================

var private int GetSpotChance;


// ============================================================================
// CanRelease
//
// When a player release his team.
// ============================================================================

function bool CanRelease(TeamInfo Team, Pawn Releaser, GameObjective Objective)
{
    local PlayerStart TeleportSpot;
    local bool bCanRelease;

    bCanRelease = Super.CanRelease(Team, Releaser, Objective);

    if((bCanRelease)
    && (Releaser.Controller != None)
    && (Releaser.PlayerReplicationInfo != None)
    && (Releaser.PlayerReplicationInfo.Team != None))
    {
        TeleportSpot = GetTeleportSpot(Releaser.PlayerReplicationInfo.Team.TeamIndex);
        if(TeleportSpot != None)
        {
            Releaser.PlayTeleportEffect(TRUE, TRUE);
            Releaser.SetLocation(TeleportSpot.Location);
            Releaser.SetRotation(TeleportSpot.Rotation);
            Releaser.ClientSetLocation(TeleportSpot.Location, TeleportSpot.Rotation);
            Releaser.PlayTeleportEffect(TRUE, TRUE);
        }
    }
  
    return bCanRelease;
}


// ============================================================================
// GetTeleportSpot
//
// Seek a free team PlayerStart.
// ============================================================================

final function PlayerStart GetTeleportSpot(byte Team)
{
    local NavigationPoint NP;

    GetSpotChance += CHANCE_AMOUNT;

    for(NP=Level.NavigationPointList; NP!=None; NP=NP.NextNavigationPoint)
    {
        if((NP != None)
        && (PlayerStart(NP) != None)
        && (PlayerStart(NP).TeamNumber == Team)
        && (Jailbreak(Level.Game).ContainsActorJail(NP) == FALSE)
        && (Jailbreak(Level.Game).ContainsActorArena(NP) == FALSE))
        {
            if((GetSpotChance >= 100)
            || (GetSpotChance >= Rand(100)))
            {
                GetSpotChance = 0; // reset for future use
                return PlayerStart(NP);
            }
        }
    }

    return GetTeleportSpot(Team);
}
