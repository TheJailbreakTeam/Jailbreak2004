// ============================================================================
// JBGameRulesJailCard
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// Created by ?? (Someone from the Jailbreak community, most likely either
// Kartoshka or tarquin)
// $Id$
//
// GameRules class for the Jailbreak Addon JailCard (Get out of jail free card)
//
// CHANGELOG:
// 22 jan 2007 - Added first notifyround code, spawns jailcard(s) each round
//               Added reference to the JBAddon object
// 10 feb 2007 - Added AddPRI, RemovePRI and HasJailCard methods
//               Fixed CardHolder reset on new rounds
//               Added CanSendToJail code to force card-use when a player is
//               the last one to die
// 11 feb 2007 - Added PreventDeath code to allow people to steal JailCards by
//               fragging the carrier with the shieldgun
//               Added check for forced card-use if bAutoUseCard is set to True
// 12 feb 2007 - Added UseCard method
//               Modified NotifyPlayerJaied according to changes in the the
//               JailCard (weapon) code
//               Fixed a bug in PreventDeath that caused dropped pickups not to
//               register with the SpawnedPickups list.
// ============================================================================

class JBGameRulesJailCard extends JBGameRules;


//=============================================================================
// Properties
//=============================================================================

var class<LocalMessage> ConsoleMessageClass;


//=============================================================================
// Variables
//=============================================================================

var JBAddonJailCard myAddon;
var Array<PlayerReplicationInfo> CardHolders; // all PRI's of players who picked up a jailcard


//=============================================================================
// SetAddon
//=============================================================================

function SetAddon(JBAddonJailCard JBAJC)
{
    myAddon = JBAJC;
}


//=============================================================================
// AddPRI
//=============================================================================

function AddPRI(PlayerReplicationInfo myPRI)
{
    CardHolders.Insert(CardHolders.length, 1);
    CardHolders[CardHolders.length - 1] = myPRI;
    //log("PRI added: " $ myPRI.GetHumanReadableName());
    //log("CardHolders length: "$CardHolders.length);
}


//=============================================================================
// RemovePRI
//=============================================================================

function RemovePRI(PlayerReplicationInfo myPRI)
{
    local int i;
    i = HasJailCard(myPRI);

    if(i > -1)
        RemoveFromList(i);
}


//=============================================================================
// RemoveFromList
//=============================================================================

function RemoveFromList(int i)
{
    //log("PRI removed: " $ CardHolders[i].GetHumanReadableName());
    CardHolders.Remove(i, 1);
}


//=============================================================================
// HasJailCard
//
// Checks wether a given PRI is present in our CardHolders list
// If it is present, it returns its position in the list, otherwise returns -1
//=============================================================================

function int HasJailCard(PlayerReplicationInfo myPRI)
{
    local int result, i;
    result = -1;

    for(i = 0; i < CardHolders.length; i++) {
        if(CardHolders[i] == myPRI)
            result = i;
    }

    return result;
}


//=============================================================================
// UseCard
//
// Removes the PRI of the user from the list and spawns a new card
//=============================================================================

function UseCard(PlayerReplicationInfo myPRI, int i)
{
    if(i > -1)
        RemoveFromList(i);
    else
        RemovePRI(myPRI);

    BroadcastLocalizedMessage(ConsoleMessageClass, 200, myPRI);
    if(PlayerController(myPRI.Owner) != none)
        PlayerController(myPRI.Owner).ReceiveLocalizedMessage(MessageClass, 200, myPRI);

    myAddon.SpawnCard(myAddon.FindSpawnPoint());
}


// ============================================================================
// NotifyRound
//
// Called when a game round starts, including the first round in a game.
// ============================================================================

function NotifyRound()
{
    CardHolders.Remove(0, CardHolders.length);

    if(myAddon != none) {
        myAddon.ClearCards();
        myAddon.SpawnCards();
    }

    Super.NotifyRound();
}


// ============================================================================
// CanSendToJail
//
// Called when a player is about to be sent to jail by the game. Checks if the
// player has a Jail Card and if he is the last person of his team to die while
// free or bAutoUseCard is set to True (forced use).
// ============================================================================

function bool CanSendToJail(JBTagPlayer TagPlayer)
{
    local int i;
    local PlayerReplicationInfo myPRI;

    super.CanSendToJail(TagPlayer);

    myPRI = TagPlayer.GetPlayerReplicationInfo();
    i = HasJailCard(myPRI);
    if( (i > -1) &&
        (TagPlayer.IsFree()) &&
        ( (Jailbreak(Level.Game).CountPlayersJailed(TagPlayer.GetTeam()) == TagPlayer.GetTeam().Size - 1)  ||
        (myAddon.bAutoUseCard) ) ) {
        UseCard(myPRI, i);
        return false;
    }

    return true;
}


//=============================================================================
// PreventDeath
//
// Check if the killed person was carrying a JailCard and if he was killed with
// the shieldgun. If so, drop the JailCard.
//=============================================================================

function bool PreventDeath (Pawn Killed, Controller Killer, class<DamageType> myDamageType, vector HitLocation) {
    local int i;
    local PlayerReplicationInfo myPRI;

    Super.PreventDeath(Killed, Killer, myDamageType, HitLocation);

    myPRI = Killed.PlayerReplicationInfo;
    i = HasJailCard(myPRI);
    if(i > -1 && myDamageType == class'DamTypeShieldImpact' && myAddon.bAllowDropCard) { // shieldgun kill
        myAddon.SpawnCard(Killed.Location);
        RemoveFromList(i);
        BroadcastLocalizedMessage(ConsoleMessageClass, 400, myPRI);
    }

    return false;
}


//=============================================================================
// NotifyPlayerJailed
//
// Spawn the Jail Card in the jailed players inventory, if he picked it up
//=============================================================================

function NotifyPlayerJailed(JBTagPlayer TagPlayer)
{
    local JBWeaponJailCard myWeapon;

    Super.NotifyPlayerJailed(TagPlayer);

    if(HasJailCard(TagPlayer.GetController().PlayerReplicationInfo) > -1)
    {
        myWeapon = Spawn(class'JBAddonJailCard.JBWeaponJailCard');
        myWeapon.setGameRules(Self);
        myWeapon.GiveTo(TagPlayer.GetController().Pawn);

        if(PlayerController(TagPlayer.GetController()) != none)
           PlayerController(TagPlayer.GetController()).ReceiveLocalizedMessage(MessageClass, 300, TagPlayer.GetController().PlayerReplicationInfo);
    }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
    RemoteRole = ROLE_SimulatedProxy;
    MessageClass=class'JBJailCardMessageScreen';
    ConsoleMessageClass=class'JBJailCardMessageConsole';
}
