//=============================================================================
// JBJailCardMessage
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// $Id$
//
// LocalMessage class for the localmessages that appear flashing on the screen
//
// CHANGELOG:
// 12 feb 2007 - Class created
//=============================================================================
class JBJailCardMessageScreen extends JBJailCardMessage;


//=============================================================================
// Properties
//=============================================================================

var int FontSizeLarge;
var int FontSizeSmall;
var sound JailCardSounds[2];

// ============================================================================
// GetFontSize
//
// Returns the font size to use for the given message.
// ============================================================================

static function int GetFontSize(int Switch,
                                PlayerReplicationInfo PlayerReplicationInfo1,
                                PlayerReplicationInfo PlayerReplicationInfo2,
                                PlayerReplicationInfo PlayerReplicationInfoLocal)
{
    if (Switch == 300)
        return Default.FontSizeSmall;
    else
        return Default.FontSizeLarge;

  return Super.GetFontSize(Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, PlayerReplicationInfoLocal);
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

    switch (Switch) {
        case 100:
            P.ClientPlaySound(Default.JailCardSounds[0], FALSE);
        break;
    }
}


//=============================================================================
// default properties
//=============================================================================

DefaultProperties
{
    bFadeMessage=True;
    bIsSpecial=True;
    bIsUnique=True;
    Lifetime=3;
    bBeep=False;

    FontSizeLarge=1;
    FontSizeSmall=0;

    StackMode=SM_Down;
    PosY=0.242;

    // sounds
    JailCardSounds(0)=sound'JBAddonJailCard.Pickup_JailCard';
    JailCardSounds(1)=sound'JBAddonJailCard.Pickup_JailCard'; // placeholder
}
