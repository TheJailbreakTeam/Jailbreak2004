// ============================================================================
// JBLocalMessageSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// The message of Spoils add-on.
// ============================================================================


class JBLocalMessageSpoils extends LocalMessage;


// ============================================================================
// Variables
// ============================================================================

var localized string PreSpoilsMessage;


// ============================================================================
// GetString
//
// Assemble the message.
// ============================================================================

static function string GetString(optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1,
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
  return (default.PreSpoilsMessage@Weapon(OptionalObject).ItemName);
}


// ============================================================================
// ClientReceive
//
// Play Spoils announcement and make a flash.
// ============================================================================

static simulated function ClientReceive(
  PlayerController PC,
  optional int Switch,
  optional PlayerReplicationInfo RelatedPRI_1,
  optional PlayerReplicationInfo RelatedPRI_2,
  optional Object OptionalObject)
{
  Super.ClientReceive(PC, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

  PC.ClientFlash(0.25, vect(800,400,100));
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  PreSpoilsMessage="You have been awarded a"
  bIsUnique=True
  bFadeMessage=True
  Lifetime=5
  DrawColor=(B=0,G=0)
  StackMode=SM_Down
  PosY=0.120000
}
