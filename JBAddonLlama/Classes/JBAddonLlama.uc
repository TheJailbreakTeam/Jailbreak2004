//=============================================================================
// JBAddonLlama
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBAddonLlama.uc,v 1.7 2004/05/11 10:53:10 wormbo Exp $
//
// The Llama Hunt add-on for Jailbreak.
//=============================================================================


class JBAddonLlama extends JBAddon config;


//=============================================================================
// Configuration
//=============================================================================

var config int RewardAdrenaline;
var config int RewardHealth;
var config int RewardShield;
var config int MaximumLlamaDuration;


//=============================================================================
// Localization
//=============================================================================

var localized string RewardAdrenalineText,     RewardAdrenalineDesc;
var localized string RewardHealthText,         RewardHealthDesc;
var localized string RewardShieldText,         RewardShieldDesc;
var localized string MaximumLlamaDurationText, MaximumLlamaDurationDesc;


//=============================================================================
// Variables
//=============================================================================

var JBGameRulesLlamaHunt LlamaHuntRules;     // JBGameRules class for Jailbreak notifications
var() const editconst string Build;


//=============================================================================
// PostBeginPlay
//
// Spawns the JBGameRulesLlamaHunt.
//=============================================================================

simulated event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  if ( Jailbreak(Level.Game) != None ) {
    // spawn the JBGameRules subclass for Jailbreak event notifications
    LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
    if ( LlamaHuntRules != None )
      LlamaHuntRules.OnLlamaReconnect = LlamaReconnected;
    else
      log("No LlamaHuntRules spawned.", Name);
  }
}


//=============================================================================
// LlamaReconnected
//
// Called when a llama reconnected.
//=============================================================================

function LlamaReconnected(PlayerController ControllerPlayer)
{
  Llamaize(ControllerPlayer);
}


//=============================================================================
// Mutate
//
// Console commands for allowing admins and offline players to control the
// Llama Hunt add-on.
//=============================================================================

function Mutate(string MutateString, PlayerController Sender)
{
  local array<string> SplittedString;
  local Controller theLlama;
  local int i;
  
  Super.Mutate(MutateString, Sender);
  
  if ( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_Standalone )
    return;
  
  // store the words in the MutateString in a string array word by word
  Split(MutateString, " ", SplittedString);
  
  // handle multiple space chars
  while (i < SplittedString.Length) {
    if ( SplittedString[i] == "" )
      SplittedString.Remove(i, 1);
    else
      i++;
  }
  
  // only do something if the first word after "mutate" was "llama" or "unllama"
  if ( SplittedString.Length > 0 && (SplittedString[0] ~= "llama" || SplittedString[0] ~= "unllama") ) {
    if ( SplittedString.Length == 1 ) {
      // no arguments - display "help"
      Sender.ReceiveLocalizedMessage(class'JBLlamaHelpMessage', 0);
      Sender.ReceiveLocalizedMessage(class'JBLlamaHelpMessage', 1);
      Sender.ReceiveLocalizedMessage(class'JBLlamaHelpMessage', 2);
    }
    else if ( SplittedString.Length >= 2 && SplittedString[1] ~= "config" ) {
      // handle config parameters
      while (SplittedString.Length > 2) {
        switch (Caps(SplittedString[1])) {
        Case "HEALTH":
          if ( IsInt(SplittedString[2]) ) {
            RewardHealth = Clamp(int(SplittedString[2]), 0, 199);
            SaveConfig();
          }
          break;
        Case "SHIELD":
          if ( IsInt(SplittedString[2]) ) {
            RewardShield = Clamp(int(SplittedString[2]), 0, 150);
            SaveConfig();
          }
          break;
        Case "ADRENALINE":
          if ( IsInt(SplittedString[2]) ) {
            RewardAdrenaline = Clamp(int(SplittedString[2]), 0, 100);
            SaveConfig();
          }
          break;
        Case "DURATION":
          if ( IsInt(SplittedString[2]) ) {
            MaximumLlamaDuration = Clamp(int(SplittedString[2]), 0, 120);
            SaveConfig();
          }
          break;
        }
        SplittedString.Remove(1, 2);
      }
      Sender.ClientMessage("Health ="@RewardHealth@"  Shield ="@RewardShield@"  Adrenaline ="@RewardAdrenaline@"  Duration ="@MaximumLlamaDuration);
    }
    else {
      if ( SplittedString.Length >= 2 && SplittedString[1] ~= "player" ) {
        // the "player" parameter can be left out if the playername isn't equal to a config parameter
        SplittedString.Remove(1, 1);
        //log("Removed 'player' keyword.", Name);
      }
      if ( SplittedString.Length > 1 ) {
        //log("Searching for player '"$SplittedString[1]$"'", Name);
        theLlama = FindPlayerByName(SplittedString[1], SplittedString[0] ~= "unllama");
        if ( theLlama != None ) {
          //log("Found"@theLlama, Name);
          if ( SplittedString[0] ~= "llama" )
            Llamaize(theLlama);
          else
            UnLlamaize(theLlama);
        }
      }
    }
  }
}


//=============================================================================
// IsInt
//
// Checks if a string is an int value.
// Modified from wUtils.wMath.IsNumeric()
// http://wiki.beyondunreal.com/WUtils
//=============================================================================

function bool IsInt(coerce string Param)
{
  local int p;
  
  p = 0;
  while (Mid(Param, p, 1) == " ") p++;
  while (Mid(Param, p, 1) >= "0" && Mid(Param, p, 1) <= "9") p++;
  while (Mid(Param, p, 1) == " ") p++;
  if (Mid(Param, p) != "") return false;
  return true;
}


//=============================================================================
// FindPlayerByName
//
// Returns the Controller of the player with the specified name.
//=============================================================================

function Controller FindPlayerByName(string PlayerName, bool bOnlyLlamas)
{
  local int i;
  
  //log(JBGameReplicationInfo, Name);
  
  if ( JBGameReplicationInfo == None )
    return None; // can't work without GRI
  
  // search for exact name
  for (i = 0; i < JBGameReplicationInfo.PRIArray.Length; i++) {
    /*log("Searching for exact match:"
        @ JBGameReplicationInfo.PRIArray[i]
        @ JBGameReplicationInfo.PRIArray[i].PlayerName
        @ JBGameReplicationInfo.PRIArray[i].Owner, Name);
    */
    if ( JBGameReplicationInfo.PRIArray[i] != None
        && JBGameReplicationInfo.PRIArray[i].PlayerName ~= PlayerName
        && Controller(JBGameReplicationInfo.PRIArray[i].Owner) != None
        && (bOnlyLlamas == IsLlama(Controller(JBGameReplicationInfo.PRIArray[i].Owner))) )
      return Controller(JBGameReplicationInfo.PRIArray[i].Owner);
  }
  
  // search for the first name containing the string
  for (i = 0; i < JBGameReplicationInfo.PRIArray.Length; i++) {
    /*log("Searching for partial match:"
        @ JBGameReplicationInfo.PRIArray[i]
        @ JBGameReplicationInfo.PRIArray[i].PlayerName
        @ JBGameReplicationInfo.PRIArray[i].Owner, Name);
    */
    if ( JBGameReplicationInfo.PRIArray[i] != None
        && InStr(Caps(JBGameReplicationInfo.PRIArray[i].PlayerName), Caps(PlayerName)) != -1
        && Controller(JBGameReplicationInfo.PRIArray[i].Owner) != None 
        && (bOnlyLlamas == IsLlama(Controller(JBGameReplicationInfo.PRIArray[i].Owner))) )
      return Controller(JBGameReplicationInfo.PRIArray[i].Owner);
  }
  
  return None; // no player found
}


//=============================================================================
// IsLlama
//
// Checks whether a is a llama or is about to become a llama.
//=============================================================================

function bool IsLlama(Controller C)
{
  local JBLlamaPendingTag thisLlamaPendingTag;
  
  if ( C == None )
    return False;
  else if ( C.Pawn != None )
    return C.Pawn.FindInventoryType(class'JBLlamaTag') != None;
  else {
    foreach C.ChildActors(class'JBLlamaPendingTag', thisLlamaPendingTag)
      return true;
  }
  
  return false;
}


//=============================================================================
// Llamaize
//
// Makes a player a Llama.
//=============================================================================

function Llamaize(Controller ControllerPlayer)
{
  //log("Llamaizing"@ControllerPlayer, Name);
  Spawn(class'JBLlamaPendingTag', ControllerPlayer);
}


//=============================================================================
// UnLlamaize
//
// Removes a player's llama effect
//=============================================================================

function UnLlamaize(Controller ControllerPlayer)
{
  local Inventory LlamaTag;
  local JBLlamaPendingTag thisLlamaPendingTag;
  
  if ( ControllerPlayer.Pawn != None ) {
    LlamaTag = ControllerPlayer.Pawn.FindInventoryType(class'JBLlamaTag');
    if ( LlamaTag != None )
      LlamaTag.Destroy();
  }
  else if ( ControllerPlayer != None ) {
    foreach ControllerPlayer.ChildActors(class'JBLlamaPendingTag', thisLlamaPendingTag)
      thisLlamaPendingTag.Destroy();
  }
}


//=============================================================================
// FillPlayInfo
//
// Adds configurable Llama Hunt properties to the web admin interface.
//=============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
  // add current class to stack
  PlayInfo.AddClass(default.Class);
  
  // now register any mutator settings
  PlayInfo.AddSetting(PlayInfoGroup(), "MaximumLlamaDuration", default.MaximumLlamaDurationText, 0, 1, "Text", "3;0:120");
  PlayInfo.AddSetting(PlayInfoGroup(), "RewardAdrenaline",     default.RewardAdrenalineText,     0, 2, "Text", "3;0:100");
  PlayInfo.AddSetting(PlayInfoGroup(), "RewardHealth",         default.RewardHealthText,         0, 3, "Text", "3;0:199");
  PlayInfo.AddSetting(PlayInfoGroup(), "RewardShield",         default.RewardShieldText,         0, 4, "Text", "3;0:150");
  
  // remove mutator class from class stack
  PlayInfo.PopClass();
}


//=============================================================================
// GetDescriptionText
//
// Returns a description text for the specified property.
//=============================================================================

static event string GetDescriptionText(string PropName)
{
  Switch (PropName) {
    Case "MaximumLlamaDuration": return default.MaximumLlamaDurationDesc;
    Case "RewardAdrenaline":     return default.RewardAdrenalineDesc;
    Case "RewardHealth":         return default.RewardHealthDesc;
    Case "RewardShield":         return default.RewardShieldDesc;
  }
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  ConfigMenuClassName="JBAddonLlama.JBGUIPanelConfigLlama"
  IconMaterialName="JBAddonLlama.Llama"
  FriendlyName="Llama Hunt"
  GroupName="LlamaHunt"
  Description="Turns cheating players into llamas and lets other players perform a jolly hunt on them."
  Build="%%%%-%%-%% %%:%%"
  RewardAdrenaline=100
  RewardHealth=25
  MaximumLlamaDuration=60
  RewardAdrenalineText     = "Adrenaline gained for killing a Llama"
  RewardHealthText         = "Health gained for killing a Llama"
  RewardShieldText         = "Shield gained for killing a Llama"
  MaximumLlamaDurationText = "Maximum duration of the llama hunt"
  
  RewardAdrenalineDesc     = "Players who kill a llama are awarded this ammount of adrenaline."
  RewardHealthDesc         = "Players who kill a llama are awarded this ammount of health."
  RewardShieldDesc         = "Players who kill a llama are awarded this ammount of shield."
  MaximumLlamaDurationDesc = "Maximum time a llama will last. The llama is killed if it has not been fragged by the end of the llama hunt."
}