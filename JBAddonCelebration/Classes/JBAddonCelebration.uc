//=============================================================================
// JBAddonCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// The Celebration Screen add-on for Jailbreak.
//=============================================================================


class JBAddonCelebration extends JBAddon;


//=============================================================================
// Variables
//=============================================================================

var() const editconst string Build;
var() localized string CapturedOtherMessage[32];
var() localized int NumCapturedOtherMessages;
var() localized string CapturedSelfMessage[32];
var() localized int NumCapturedSelfMessages;
var() localized string TeamString[2];


//=============================================================================
// PostBeginPlay
//
// Spawns the JBGameRulesCelebration.
//=============================================================================

event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  Spawn(class'JBGameRulesCelebration');
}


//=============================================================================
// GetRandomCapturedMessage
//
// Returns a random message for the specified player and team.
//=============================================================================

static function string GetRandomCapturedMessage(PlayerReplicationInfo PRI, TeamInfo Team)
{
  local string CapturedMessage;
  local string TeamName;
  
  if ( PRI.Team == Team )
    CapturedMessage = default.CapturedSelfMessage[Rand(default.NumCapturedSelfMessages)];
  else
    CapturedMessage = default.CapturedOtherMessage[Rand(default.NumCapturedOtherMessages)];
  
  PRI.ReplaceText(CapturedMessage, "%p", PRI.PlayerName);
  
  TeamName = default.TeamString[Team.TeamIndex];
  PRI.ReplaceText(CapturedMessage, "%t", TeamName);
  PRI.ReplaceText(CapturedMessage, "%T", Caps(Left(TeamName, 1)) $ Mid(TeamName, 1));
  
  return CapturedMessage;
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  FriendlyName="Celebration Screen"
  GroupName="Celebration"
  Description="Enables the widescreen celebration screen during executions."
  Build="%%%%-%%-%% %%:%%"
  
  CapturedOtherMessage(0)="%p captured the last loser on the %t team."
  CapturedOtherMessage(1)="%p just threw the switch on the %t team."
  CapturedOtherMessage(2)="%p just sent the %t team to the joint."
  CapturedOtherMessage(3)="%p just locked down the %t team."
  CapturedOtherMessage(4)="%p has closed the gates on the %t team."
  CapturedOtherMessage(5)="%p sent the %t team down the river."
  CapturedOtherMessage(6)="%p just fitted the %t team for stripes."
  CapturedOtherMessage(7)="%p sent the %t team to death row."
  CapturedOtherMessage(8)="%p gave the %t team the chair!"
  CapturedOtherMessage(9)="%p has passed sentence on the %t team."
  CapturedOtherMessage(10)="%p sent the %t team up the creek without a paddle."
  CapturedOtherMessage(11)="%p just revoked the %t team's parole!"
  CapturedOtherMessage(12)="%p gave the %t team a free trip to the BIG house!"
  CapturedOtherMessage(13)="%p locked the door on %c and threw away the key."
  CapturedOtherMessage(14)="%p says No Bail! for the %t team."
  CapturedOtherMessage(15)="%p lays the lockdown on the %t team!"
  CapturedOtherMessage(16)="%p slammed the door in the %t team's face!"
  CapturedOtherMessage(17)="%p sentences the %t team to death!"
  CapturedOtherMessage(18)="%p locks up the %t team and throws away the key!"
  CapturedOtherMessage(19)="%p says don't do the crime if ya can't do the time..."
  CapturedSelfMessage(0)="%p couldn't stand to be alone out of jail anymore."
  CapturedSelfMessage(1)="A dyed-in-the-wool killer would have asked about that button, %p."
  CapturedSelfMessage(2)="%p blew it for the %t team."
  TeamString(0)="red"
  TeamString(1)="blue"
}