//=============================================================================
// JBAddonCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBAddonCelebration.uc,v 1.2 2004/03/05 19:18:23 wormbo Exp $
//
// The Celebration Screen add-on for Jailbreak.
//=============================================================================


class JBAddonCelebration extends JBAddon
    cacheexempt;


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
// InitAddon
//
// Spawns the JBGameRulesCelebration.
//=============================================================================

simulated function InitAddon()
{
  Super.InitAddon();
  
  if ( Level.Game != None )
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
  
  StaticReplaceText(CapturedMessage, "%p", PRI.PlayerName);
  
  TeamName = default.TeamString[Team.TeamIndex];
  StaticReplaceText(CapturedMessage, "%t", TeamName);
  StaticReplaceText(CapturedMessage, "%T", Caps(Left(TeamName, 1)) $ Mid(TeamName, 1));
  
  TeamName = default.TeamString[(Team.TeamIndex + 1) % 2];
  StaticReplaceText(CapturedMessage, "%o", TeamName);
  StaticReplaceText(CapturedMessage, "%O", Caps(Left(TeamName, 1)) $ Mid(TeamName, 1));
  
  return CapturedMessage;
}


//=============================================================================
// StaticReplaceText
//
// Static version of Actor.ReplaceText()
//=============================================================================

static final function StaticReplaceText(out string Text, string Replace, string With)
{
  local int i;
  local string Input;
    
  Input = Text;
  Text = "";
  i = InStr(Input, Replace);
  while(i != -1) {  
    Text = Text $ Left(Input, i) $ With;
    Input = Mid(Input, i + Len(Replace));  
    i = InStr(Input, Replace);
  }
  Text = Text $ Input;
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
  bAddToServerPackages=True
  
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
  CapturedOtherMessage(13)="%p locked the door on the %t team and threw away the key."
  CapturedOtherMessage(14)="%p says No Bail! for the %t team."
  CapturedOtherMessage(15)="%p lays the lockdown on the %t team!"
  CapturedOtherMessage(16)="%p slammed the door in the %t team's face!"
  CapturedOtherMessage(17)="%p sentences the %t team to death!"
  CapturedOtherMessage(18)="%p locks up the %t team and throws away the key!"
  CapturedOtherMessage(19)="%p says don't do the crime if ya can't do the time..."
  CapturedOtherMessage(20)="%p caught the %t team red-handed."
  CapturedOtherMessage(21)="%p successfully tightened security in the house."
  CapturedOtherMessage(22)="%T is %p's favorite color for decorating jails."
  CapturedOtherMessage(23)="%p scored for %o. The %t team won't enjoy it, though."
  CapturedSelfMessage(0)="%p couldn't stand to be alone out of jail anymore."
  CapturedSelfMessage(1)="A dyed-in-the-wool killer would have asked about that button, %p."
  CapturedSelfMessage(2)="%p blew it for the %t team."
  CapturedSelfMessage(3)="%p didn't read the 'aim away from face' label."
  CapturedSelfMessage(4)="Hey %p, you're on the %t team in case you didn't notice."
  CapturedSelfMessage(5)="Erm %p, you're supposed to shoot the %o guys, not the %t ones..."
  TeamString(0)="red"
  TeamString(1)="blue"
}