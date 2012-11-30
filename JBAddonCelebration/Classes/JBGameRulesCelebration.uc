//=============================================================================
// JBGameRulesCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBGameRulesCelebration.uc,v 1.9 2004/06/02 21:45:13 wormbo Exp $
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
  //var string PlayerName;
  var PlayerReplicationInfo PRI;
  //var string MeshName;
  //var string BodySkinName;
  //var string HeadSkinName;
  //var byte Team;
  var bool bBot;
  var bool bSuicide;
};

// information about a player's appearance
struct TRepTaunt {
  var string TauntAnim;
  var int Counter;
};


//=============================================================================
// Variables
//=============================================================================

var bool bInExecutionSequence;
var JBTagPlayer LastKiller[2], LastKilled[2];
var TPlayerInfo LastKillerInfo;
var TeamInfo CapturedTeam;
var TRepTaunt ReplicatedTaunt;
var int ClientTauntNum;
var name ClientTauntAnim;
var int NextCaptureMessage;

var JBInteractionCelebration CelebrationInteraction;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( Role == ROLE_Authority )
    bInExecutionSequence, LastKillerInfo, CapturedTeam, ReplicatedTaunt, NextCaptureMessage;

  unreliable if ( Role < ROLE_Authority )
    ServerSetTauntAnim;
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

  NextCaptureMessage = Rand(ArrayCount(class'JBAddonCelebration'.default.CapturedOtherMessage));
}


//=============================================================================
// ScoreKill
//
// Remember the last killer and killed player for kills or suicides in freedom.
//=============================================================================

function ScoreKill(Controller Killer, Controller Killed)
{
  local int TeamNum;
  local JBTagPlayer TagKilled;

  if ( Killed != None && Killed.PlayerReplicationInfo != None && !Killed.PlayerReplicationInfo.bOnlySpectator ) {
    TagKilled = class'JBTagPlayer'.static.FindFor(Killed.PlayerReplicationInfo);

    if ( TagKilled.IsFree() || TagKilled.IsInArena() ) {
      if ( Killed.PlayerReplicationInfo != None && Killed.PlayerReplicationInfo.Team != None )
        TeamNum = Killed.PlayerReplicationInfo.Team.TeamIndex;

      LastKilled[TeamNum] = TagKilled;
      if ( Killer != None )
        LastKiller[TeamNum] = class'JBTagPlayer'.static.FindFor(Killer.PlayerReplicationInfo);
      else
        LastKiller[TeamNum] = TagKilled;
    }
  }
  Super.ScoreKill(Killer, Killed);
}


//=============================================================================
// ServerSetTauntAnim
//
// Get rid of the PlayerMesh after execution is over.
//=============================================================================

function ServerSetTauntAnim(string TauntAnim)
{
  ReplicatedTaunt.TauntAnim = TauntAnim;
  ReplicatedTaunt.Counter++;
  ReplicatedTaunt = ReplicatedTaunt;  // force replication
  if ( Level.NetMode != NM_DedicatedServer )
    PostNetReceive();
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
      CelebrationInteraction.CelebrationGameRules = Self;
      if ( LastKillerInfo.PRI != None ) {
        CelebrationInteraction.SetupPlayerMesh(LastKillerInfo);
        if ( CapturedTeam != None )
          CelebrationInteraction.CaptureMessage = class'JBAddonCelebration'.static.GetCapturedMessage(
             LastKillerInfo.PRI, CapturedTeam, NextCaptureMessage);
      }
    }
  }
  else if ( bInExecutionSequence && CelebrationInteraction != None && LastKillerInfo.PRI != None
      && CelebrationInteraction.PlayerMesh == None ) {
    CelebrationInteraction.SetupPlayerMesh(LastKillerInfo);
  }
  else if ( CelebrationInteraction != None && CelebrationInteraction.CaptureMessage == ""
      && LastKillerInfo.PRI != None && CapturedTeam != None )
    CelebrationInteraction.CaptureMessage = class'JBAddonCelebration'.static.GetCapturedMessage(
        LastKillerInfo.PRI, CapturedTeam, NextCaptureMessage);

  if ( ReplicatedTaunt.Counter > ClientTauntNum ) {
    ClientTauntNum = ReplicatedTaunt.Counter;
    SetPropertyText("ClientTauntAnim", ReplicatedTaunt.TauntAnim);
    if ( CelebrationInteraction != None && CelebrationInteraction.PlayerMesh != None )
      CelebrationInteraction.PlayerMesh.PlayNamedTauntAnim(ClientTauntAnim);
  }
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
  local int TeamNum;
  local PlayerController CelebrationController;

  bInExecutionSequence = True;
  CapturedTeam = Team;
  if ( CapturedTeam != None )
    TeamNum = CapturedTeam.TeamIndex;

  // fill LastKillerInfo
  LastKillerInfo.Player = LastKiller[TeamNum];
  LastKillerInfo.bSuicide = LastKiller[TeamNum] == LastKilled[TeamNum];
  if ( LastKiller[TeamNum] != None ) {
    LastKillerInfo.bBot = PlayerController(LastKiller[TeamNum].GetController()) == None;
    if ( LastKiller[TeamNum].GetController() != None ) {
      LastKillerInfo.PRI = LastKiller[TeamNum].GetController().PlayerReplicationInfo;
    }
    if ( LastKiller[TeamNum].GetPawn() != None )
      LastKiller[TeamNum].GetPawn().bAlwaysRelevant = True;
    if ( !LastKillerInfo.bBot && LastKillerInfo.PRI.Team != Team ) {
      CelebrationController = PlayerController(LastKiller[TeamNum].GetController());
      SetOwner(CelebrationController);
      Jailbreak(Level.Game).IncrementGoalsScored(LastKillerInfo.PRI); // for ServerExt/ServQuery and "Hat Trick" announcement
      if ( CelebrationController != None )
        CelebrationController.ReceiveLocalizedMessage(class'JBLocalMessageCelebration', 520);
    }
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
  local int i;

  bInExecutionSequence = False;
  CapturedTeam = None;
  for (i = 0; i < ArrayCount(LastKiller); i++) {
    if ( LastKiller[i] != None && LastKiller[i].GetPawn() != None )
      LastKiller[i].GetPawn().bAlwaysRelevant = False;
    LastKiller[i] = None;
    LastKilled[i] = None;
  }
  SetOwner(None);

  LastKillerInfo = EmptyPlayerInfo;
  Super.NotifyExecutionEnd();
  if ( Level.NetMode != NM_DedicatedServer )
    PostNetReceive();

  NextCaptureMessage = Rand(ArrayCount(class'JBAddonCelebration'.default.CapturedOtherMessage));
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bAlwaysRelevant=True
  bNetNotify=True
  bOnlyDirtyReplication=False
  RemoteRole=ROLE_SimulatedProxy
}