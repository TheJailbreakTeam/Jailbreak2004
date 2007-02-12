//==============================================================================
// JBJailCardMessage
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// $Id$
//
// LocalMessage class for the JailCard addon for Jailbreak.
//
// SWITCHES:
//          100 - pickup message
//          200 - used message
//          300 - use now message
//          400 - dropped message
//
// CHANGELOG:
// 14 jan 2007 - Class created
//               Added custom sound
// 10 feb 2007 - Added GetRelatedString
//               Changed JailCardString[1]
//               Added PlayMySound method
// 11 feb 2007 - Added pickup and use-now messages
// 12 feb 2007 - Added female used string and dropped string
//               Removed PlayMySound method
//==============================================================================

class JBJailCardMessage extends LocalMessage;


//==============================================================================
// Properties
//==============================================================================

var localized string JailCardString[9];
var Color Yellow;


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
    switch (Switch) {
        case 100:
            return (RelatedPRI_1.GetHumanReadableName() $ Default.JailCardString[1]);
        break;
        case 200:
            if(RelatedPRI_1.bIsFemale)
                return (RelatedPRI_1.GetHumanReadableName() $ Default.JailCardString[4]);
            else
                return (RelatedPRI_1.GetHumanReadableName() $ Default.JailCardString[3]);
        break;
        case 400:
            if(RelatedPRI_1.bIsFemale)
                return (RelatedPRI_1.GetHumanReadableName() $ Default.JailCardString[7]);
            else
                return (RelatedPRI_1.GetHumanReadableName() $ Default.JailCardString[6]);
        break;
    }
}


//==============================================================================
// GetString
//
// Assemble the message
//==============================================================================

static function string GetRelatedString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch) {
        case 100:
            return Default.JailCardString[0];
        break;
        case 200:
            return Default.JailCardString[2];
        break;
        case 300:
            return Default.JailCardString[5];
        break;
        case 400:
            return Default.JailCardString[8];
        break;
    }
}


// ============================================================================
// GetColor
//
// Returns the color to use for the given message.
// ============================================================================

static function color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
{
       return Default.Yellow;
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
    // strings
    JailCardString(0)="Get Out Of Jail Free Card!";
    JailCardString(1)=" picked up a Jail Card!";
    JailCardString(2)="You used your Jail Card.";
    JailCardString(3)=" used his Jail Card.";
    JailCardString(4)=" used her Jail Card.";
    JailCardString(5)="Select and use your Jail Card to escape!";
    JailCardString(6)=" dropped his Jail Card!";
    JailCardString(7)=" dropped her Jail Card!";
    JailCardString(8)="You dropped your Jail Card!";

    // colours
    Yellow=(R=255,G=255,B=0,A=255);
    DrawColor=(R=255,G=255,B=0,A=255);
}
