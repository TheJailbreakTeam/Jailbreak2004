//=============================================================================
// JBLlamaHelpMessage
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaHelpMessage.uc,v 1.1 2003/11/11 17:48:49 wormbo Exp $
//
// Localized help message for "mutate llama" commands.
//=============================================================================


class JBLlamaHelpMessage extends LocalMessage abstract;


//=============================================================================
// Localization
//=============================================================================

var localized string HelpMessageLines[3];


//=============================================================================
// GetString
//
// Returns the help line specified by the Switch parameter.
//=============================================================================

static function string GetString(optional int Switch,
                                 optional PlayerReplicationInfo PlayerReplicationInfo1, 
                                 optional PlayerReplicationInfo PlayerReplicationInfo2,
                                 optional Object ObjectOptional)
{
  return default.HelpMessageLines[Switch];
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  HelpMessageLines[0]="Syntax: 'mutate llama <parameter>' or 'mutate unllama <playername>'"
  HelpMessageLines[1]=" <parameter> can be a playername or 'config' followed by a second parameter."
  HelpMessageLines[2]=" Additional parameters for 'config' can be 'health', 'shield', 'adrenaline' and 'duration', each followed by their new value."
  bIsSpecial=false
  Lifetime=10
}