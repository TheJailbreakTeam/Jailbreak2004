// ============================================================================
// JBLocalMessageBerserker
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBLocalMessageBerserker.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// The message of berserker add-on.
// ============================================================================
class JBLocalMessageBerserker extends LocalMessage;


// ============================================================================
// Variables
// ============================================================================
var localized string PreBerserkMessage;
var localized string PostBerserkMessage;


// ============================================================================
// GetString
//
// Assemble the message.
// ============================================================================
static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject)
{
    return (default.PreBerserkMessage@Switch@default.PostBerserkMessage);
}


// ============================================================================
// ClientReceive
//
// Play berserk announcement and make a flash.
// ============================================================================
static simulated function ClientReceive( 
    PlayerController PC,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject)
{
    Super.ClientReceive(PC, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    PC.PlayAnnouncement(Sound'AnnouncerMain.Berzerk', 1, TRUE);
    PC.ClientFlash(0.25, vect(800,400,100));
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bFadeMessage=True
    bIsUnique=True
    bBeep=False

    StackMode=SM_Down
    PosY=0.120000
    LifeTime=5.00000

    DrawColor=(R=255,G=0,B=0,A=255)
    FontSize=0

    PreBerserkMessage="You are a Berserker for"
    PostBerserkMessage="seconds!"
}
