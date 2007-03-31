// ============================================================================
// JBLocalMessageOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBLocalMessageOvertimeLockdown.uc,v 1.3 2007-02-03 14:36:22 jrubzjeknf Exp $
//
// Used instead of normal overtime announcement.
// ============================================================================


class JBLocalMessageOvertimeLockdown extends LocalMessage;


// ============================================================================
// Variables
// ============================================================================

var localized string TextOvertimeLockdown;


//============================================================================
// ClientReceive
//
// Play the closing lock sound.
//============================================================================
static simulated function ClientReceive(PlayerController P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	P.ClientPlaySound(Sound'JBToolbox.PadlockClose', true, 2);
}


// ============================================================================
// GetColor
//
// Returns the Hud's highlight color, ie the color used for the blinking icon.
// ============================================================================

static function color GetColor(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
    return class'HudCDeathMatch'.default.HudColorHighLight;
}


// ============================================================================
// GetString
// ============================================================================

static function string GetString(optional int Switch, optional PlayerReplicationInfo PlayerReplicationInfo1, optional PlayerReplicationInfo PlayerReplicationInfo2, optional Object ObjectOptional)
{
  return default.TextOvertimeLockdown;
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  TextOvertimeLockdown  = "Locks jammed - last chance to win!"

  bIsUnique=True
  bFadeMessage=True
  Lifetime=4
  FontSize=1
  StackMode=2
  PosY=0.60
}
