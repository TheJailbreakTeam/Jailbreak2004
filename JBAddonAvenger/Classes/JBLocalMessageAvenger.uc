// ============================================================================
// JBLocalMessageAvenger
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBLocalMessageAvenger.uc,v 1.1 2003/07/27 03:21:17 crokx Exp $
//
// The message of Avenger add-on.
// ============================================================================


class JBLocalMessageAvenger extends LocalMessage;


// ============================================================================
// Variables
// ============================================================================

var localized string PreAvengerMessage;
var localized string PostAvengerMessage;


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
    return (default.PreAvengerMessage@Switch@default.PostAvengerMessage);
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

    // PC.PlayAnnouncement(Sound'AnnouncerMain.Berzerk', 1, TRUE);
    // an 'Avenger' sound would be nice!
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

  PreAvengerMessage="You are an Avenger for"
  PostAvengerMessage="seconds!"
}
