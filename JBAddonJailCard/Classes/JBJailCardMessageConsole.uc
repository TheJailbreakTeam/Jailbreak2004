//==============================================================================
// JBJailCardMessageConsole
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
//
// Console message when someone picks up the JailCard
//
// CHANGELOG:
// 22 jan 2007 - Class created
// 10 feb 2007 - Added ClientReceive and PlayMySound methods
// 11 feb 2007 - Removed ClientReceive and PlayMySound methods
//               Added code to colour the message according to the players team
//==============================================================================
class JBJailCardMessageConsole extends JBJailCardMessage notplaceable;


//==============================================================================
// Properties
//==============================================================================

var Color Red;
var Color Blue;


// ============================================================================
// GetColor
//
// Returns the color to use for the given message.
// ============================================================================

static function color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
{
    if(RelatedPRI_1.Team.TeamIndex == 0)
        return Default.Red;
    else
        return Default.Blue;


    return Super.GetConsoleColor(RelatedPRI_1);
}


//=============================================================================
// default properties
//=============================================================================

DefaultProperties
{
    bIsConsoleMessage=True;
    bBeep=True;
    bIsSpecial=False;
    Lifetime=6;

    // colours
    Red=(R=255,G=0,B=0,A=255);
    Blue=(R=0,G=0,B=255,A=255);
}
