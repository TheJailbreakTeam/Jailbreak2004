//=============================================================================
// JBAddonLlama
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBAddonLlama.uc,v 1.1 2003/07/26 20:20:32 wormbo Exp $
//
// The Llama Hunt add-on for Jailbreak.
//=============================================================================


class JBAddonLlama extends JBAddon config;


//=============================================================================
// Configuration
//=============================================================================

var config int RewardHealth;
var config int RewardAdrenaline;


//=============================================================================
// Localization
//=============================================================================

var localized string RewardHealthText;
var localized string RewardAdrenalineText;


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
  
  Super.Mutate(MutateString, Sender);
  
  if ( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_Standalone )
    return;
  
  // store the words in the MutateString in a string array word by word
  Split(MutateString, " ", SplittedString);
  
  // possibly handle multiple space chars?
  
  
  // only do something if the first word after "mutate" was "llama"
  if ( SplittedString.Length > 0 && (SplittedString[0] ~= "llama" || SplittedString[0] ~= "unllama") ) {
    if ( SplittedString.Length == 1 ) {
      // no arguments - display "help"
      Sender.ClientMessage("Syntax: mutate llama [[player] playername]"); // TODO: needs localization
    }
    /*else if ( ... ) {
      // handle config parameters here 
    }*/
    else {
      if ( SplittedString[1] ~= "player" ) {
        // the "player" parameter can be left out if the playername isn't equal to a config parameter
        SplittedString.Remove(1, 1);
        //log("Removed 'player' keyword.", Name);
      }
      if ( SplittedString.Length > 1 ) {
        //log("Searching for player '"$SplittedString[1]$"'", Name);
        theLlama = FindPlayerByName(SplittedString[1]);
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
// FindPlayerByName
//
// Returns the Controller of the player with the specified name.
//=============================================================================

function Controller FindPlayerByName(string PlayerName, optional bool bExactName)
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
        && Controller(JBGameReplicationInfo.PRIArray[i].Owner) != None )
      return Controller(JBGameReplicationInfo.PRIArray[i].Owner);
  }
  
  if ( bExactName )
    return None; // no exact match
  
  // search for the first name containing the string
  for (i = 0; i < JBGameReplicationInfo.PRIArray.Length; i++) {
    /*log("Searching for partial match:"
        @ JBGameReplicationInfo.PRIArray[i]
        @ JBGameReplicationInfo.PRIArray[i].PlayerName
        @ JBGameReplicationInfo.PRIArray[i].Owner, Name);
    */
    if ( JBGameReplicationInfo.PRIArray[i] != None
        && InStr(Caps(JBGameReplicationInfo.PRIArray[i].PlayerName), Caps(PlayerName)) != -1
        && Controller(JBGameReplicationInfo.PRIArray[i].Owner) != None )
      return Controller(JBGameReplicationInfo.PRIArray[i].Owner);
  }
  
  return None; // no player found
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
  
  if ( ControllerPlayer.Pawn != None ) {
    LlamaTag = ControllerPlayer.Pawn.FindInventoryType(class'JBLlamaTag');
    if ( LlamaTag != None )
      LlamaTag.Destroy();
  }
}


//=============================================================================
// MutatorFillPlayInfo
//
// Adds configurable Llama Hunt properties to the web admin interface.
//=============================================================================

function MutatorFillPlayInfo(PlayInfo PlayInfo)
{
  // add current class to stack
  PlayInfo.AddClass(Class);
  
  // now register any mutator settings
  PlayInfo.AddSetting("Add-Ons", "RewardAdrenaline", RewardAdrenalineText, 0, 0, "Text", "3;0:100");
  PlayInfo.AddSetting("Add-Ons", "RewardHealth",     RewardHealthText,     0, 0, "Text", "3;0:199");
  
  // remove mutator class from class stack
  PlayInfo.PopClass();
  
  // call default implementation
  Super.MutatorFillPlayInfo(PlayInfo);
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  ConfigMenuClassName="JBAddonLlama.JBGUILlamaConfigPanel"
  IconMaterialName="JBAddonLlama.Llama"
  FriendlyName="Llama Hunt"
  GroupName="LlamaHunt"
  Description="Turns cheating players into llamas and lets other players perform a jolly hunt on them."
  Build="%%%%-%%-%% %%:%%"
  RewardAdrenaline=100
  RewardHealth=25
  RewardAdrenalineText="Adrenaline gained for killing a Llama"
  RewardHealthText="Health gained for killing a Llama"
}