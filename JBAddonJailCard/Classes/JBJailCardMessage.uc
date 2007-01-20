//==============================================================================
// JBJailCardMessage
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// $Id$
//
// LocalMessage class for the JailCard addon for Jailbreak.
//
// CHANGELOG:
// 14 jan 2007 - Class created
//               Added custom sound
//==============================================================================

class JBJailCardMessage extends LocalMessage;


//==============================================================================
// Variables
//==============================================================================

var localized string JailCardString[2];
var sound JailCardSounds[2];


//==============================================================================
// GetString
//
// Assemble the message
//==============================================================================

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    return Default.JailCardString[0];
}


//==============================================================================
// ClientReceive
//
// Play sound file and show the message
//==============================================================================

static simulated function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    P.ClientPlaySound(Default.JailCardSounds[0], FALSE);
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
    JailCardString(0)="Get Out Of Jail Free Card!"
    JailCardString(1)="Placeholder string for more messages"
    JailCardSounds(0)=sound'JBAddonJailCard.Pickup_JailCard'
    JailCardSounds(1)=sound'JBAddonJailCard.Pickup_JailCard' // placeholder
    bFadeMessage=True
    bIsSpecial=True
    bIsUnique=True
    Lifetime=3
    bBeep=False

    DrawColor=(R=255,G=255,B=0)
    FontSize=1

    StackMode=SM_Down
    PosY=0.242

}
