//=============================================================================
// JBLlamaMessage
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Localized messages for Llama Hunt announcements.
//=============================================================================


class JBLlamaMessage extends LocalMessage;


//=============================================================================
// Localization
//=============================================================================

// allowed placeholders in llama messages:
//   %llama%      Name of the player who is or was the llama
//   %killer%     Name of the player who killed the llama

var localized string TextLlamaHuntStart;
var localized string TextLlamaCaught;
var localized string TextLlamaDied;


//=============================================================================
// GetString
//
// Gets the localized string for the given event.
// The parameters assume the following values:
//
//   Switch   Meaning                        Info 1   Info 2   Object    
//   ======   ============================   ======   ======   ======
//   1        Player became the llama        Llama
//   2        Llama was killed by a player   Llama    Killer
//   3        Llama suicided                 Llama
//
//=============================================================================

static function string GetString(optional int Switch,
                                 optional PlayerReplicationInfo PlayerReplicationInfo1, 
                                 optional PlayerReplicationInfo PlayerReplicationInfo2,
                                 optional Object ObjectOptional)
{
  local string ReturnText;
  
  switch (Switch) {
    case 1:
      return class'JBLocalMessage'.static.StaticReplaceText(Default.TextLlamaHuntStart,
                                                            "%llama%",
                                                            PlayerReplicationInfo1.PlayerName);
    case 2:
      ReturnText = class'JBLocalMessage'.static.StaticReplaceText(Default.TextLlamaCaught,
                                                                  "%llama%",
                                                                  PlayerReplicationInfo1.PlayerName);
      return class'JBLocalMessage'.static.StaticReplaceText(ReturnText,
                                                            "%killer%",
                                                            PlayerReplicationInfo2.PlayerName);
    case 3:
      return class'JBLocalMessage'.static.StaticReplaceText(Default.TextLlamaDied,
                                                            "%llama%",
                                                            PlayerReplicationInfo1.PlayerName);
  }
  
}


//=============================================================================
// ClientReceive
//
// Receives an event on a client's computer and performs appropriate actions.
//=============================================================================

static function ClientReceive(PlayerController Player,
                              optional int Switch,
                              optional PlayerReplicationInfo PlayerReplicationInfo1, 
                              optional PlayerReplicationInfo PlayerReplicationInfo2,
                              optional Object ObjectOptional)
{
  // TODO: insert announcement here
  
  if ( Switch != 1 || !class'JBLocalMessage'.static.IsLocalPlayer(PlayerReplicationInfo1) )
    Super.ClientReceive(Player, Switch, PlayerReplicationInfo1, PlayerReplicationInfo2, ObjectOptional);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  TextLlamaHuntStart="Kill %llama% for a little reward."
  TextLlamaCaught="%llama% was caught by %killer%!"
  TextLlamaDied="%llama% was busted!"
  DrawColor=(R=255,G=255,B=0,A=255)
  StackMode=SM_Down
  PosY=0.12
  bFadeMessage=True
  bIsUnique=True
  bIsSpecial=True
}