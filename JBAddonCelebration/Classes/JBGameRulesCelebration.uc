//=============================================================================
// JBGameRulesCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// The JBGameRules class for the Celebration Screen used to get Jailbreak
// notifications.
//=============================================================================


class JBGameRulesCelebration extends JBGameRules
    dependson(xUtil);


//=============================================================================
// Structs
//=============================================================================

// information about a player's appearance
struct TPlayerInfo {
  var JBTagPlayer Player;
  var string PlayerName;
  var string MeshName;
  var string BodySkinName;
  var string HeadSkinName;
  var byte Team;
  var bool bBot;
  var bool bSuicide;
};


//=============================================================================
// Variables
//=============================================================================

var bool bInExecutionSequence;
var JBTagPlayer LastKiller, LastKilled;
var TPlayerInfo LastKillerInfo;
var TeamInfo CapturedTeam;

var JBInteractionCelebration CelebrationInteraction;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( Role == ROLE_Authority )
    bInExecutionSequence, LastKillerInfo, CapturedTeam;
}


//=============================================================================
// BeginPlay
//
// Registers the JBGameRulesCelebration.
//=============================================================================

function BeginPlay()
{
  local JBGameRules thisJBGameRules;
  
  if ( JailBreak(Level.Game) == None ) {
    // doesn't work without Jailbreak
    log("Not a Jailbreak game.", Name);
    Destroy();
    return;
  }
  
  for (thisJBGameRules = JailBreak(Level.Game).GetFirstJBGameRules();
       thisJBGameRules != None;
       thisJBGameRules = thisJBGameRules.GetNextJBGameRules())
    if ( JBGameRulesCelebration(thisJBGameRules) != None ) {
      log(thisJBGameRules@"already registered.", Name);
      if ( thisJBGameRules != Self )
        Destroy();
      return;
    }
  
  // no JBGameRulesCelebration found, register this one
  if ( Level.Game.GameRulesModifiers == None )
    Level.Game.GameRulesModifiers = self;
  else
    Level.Game.GameRulesModifiers.AddGameRules(self);
}


//=============================================================================
// ScoreKill
//
// Remember the last killer and killed player.
//=============================================================================

function ScoreKill(Controller Killer, Controller Killed)
{
  if ( Killed != None ) {
    LastKilled = class'JBTagPlayer'.static.FindFor(Killed.PlayerReplicationInfo);
    if ( Killer != None )
      LastKiller = class'JBTagPlayer'.static.FindFor(Killer.PlayerReplicationInfo);
    else
      LastKiller = LastKilled;
  }
  Super.ScoreKill(Killer, Killed);
}


//=============================================================================
// PostNetReceive
//
// Get rid of the PlayerMesh after execution is over.
//=============================================================================

simulated event PostNetReceive()
{
  local PlayerController LocalPlayer;
    
  if ( !bInExecutionSequence && CelebrationInteraction != None ) {
    CelebrationInteraction.Remove();
    CelebrationInteraction = None;
  }
  else if ( bInExecutionSequence && CelebrationInteraction == None ) {
    LocalPlayer = Level.GetLocalPlayerController();
    if ( LocalPlayer != None ) {
      CelebrationInteraction = JBInteractionCelebration(LocalPlayer.Player.InteractionMaster.AddInteraction(
          string(class'JBInteractionCelebration'), LocalPlayer.Player));
      if ( LastKillerInfo.MeshName != "" )
        CelebrationInteraction.SetupPlayerMesh(LastKillerInfo);
      if ( LastKillerInfo.Player != None && CapturedTeam != None )
        CelebrationInteraction.CaptureMessage = class'JBAddonCelebration'.static.GetRandomCapturedMessage(
            LastKillerInfo.Player.GetPlayerReplicationInfo(), CapturedTeam);
    }
  }
  else if ( bInExecutionSequence && CelebrationInteraction != None && LastKillerInfo.MeshName != "" ) {
    CelebrationInteraction.SetupPlayerMesh(LastKillerInfo);
  }
  else if ( CelebrationInteraction.CaptureMessage == "" && LastKillerInfo.Player != None && CapturedTeam != None )
    CelebrationInteraction.CaptureMessage = class'JBAddonCelebration'.static.GetRandomCapturedMessage(
        LastKillerInfo.Player.GetPlayerReplicationInfo(), CapturedTeam);
}


//=============================================================================
// NotifyExecutionCommit
//
// Called when a team is about to be executed, before the execution sequence
// starts and directly after the other players' views switch to the execution
// camera.
//=============================================================================

function NotifyExecutionCommit(TeamInfo Team)
{
  local xUtil.PlayerRecord rec;
  
  bInExecutionSequence = True;
  CapturedTeam = Team;
  
  // fill LastKillerInfo
  LastKillerInfo.Player = LastKiller;
  LastKillerInfo.bSuicide = LastKiller == LastKilled;
  if ( LastKiller != None ) {
    LastKillerInfo.bBot = PlayerController(LastKiller.GetController()) == None;
    if ( LastKiller.GetController() != None ) {
      LastKillerInfo.PlayerName = LastKiller.GetController().PlayerReplicationInfo.PlayerName;
      if ( LastKiller.GetController().PlayerReplicationInfo.Team != None )
        LastKillerInfo.Team = LastKiller.GetController().PlayerReplicationInfo.Team.TeamIndex;
      rec = class'xUtil'.static.FindPlayerRecord(LastKiller.GetController().PlayerReplicationInfo.CharacterName);
      LastKillerInfo.MeshName = rec.MeshName;
      LastKillerInfo.BodySkinName = rec.BodySkinName;
      LastKillerInfo.HeadSkinName = rec.FaceSkinName;
    }
    if ( LastKiller.GetPawn() != None )
      LastKiller.GetPawn().bAlwaysRelevant = True;
  }
  
  Super.NotifyExecutionCommit(Team);
  if ( Level.NetMode != NM_DedicatedServer )
    PostNetReceive();
}


//=============================================================================
// NotifyExecutionEnd
//
// Called when the execution sequence has been completed, directly before the
// next round starts.
//=============================================================================

function NotifyExecutionEnd()
{
  local TPlayerInfo EmptyPlayerInfo;
  
  bInExecutionSequence = False;
  CapturedTeam = None;
  if ( LastKiller != None && LastKiller.GetPawn() != None )
    LastKiller.GetPawn().bAlwaysRelevant = False;
  
  LastKillerInfo = EmptyPlayerInfo;
  LastKiller = None;
  LastKilled = None;
  Super.NotifyExecutionEnd();
  if ( Level.NetMode != NM_DedicatedServer )
    PostNetReceive();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bAlwaysRelevant=True
  bNetNotify=True
  bOnlyDirtyReplication=True
  RemoteRole=ROLE_SimulatedProxy
}