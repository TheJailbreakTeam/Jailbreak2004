// ============================================================================
// JBGameRulesOvertimeLockdown - original by _Lynx
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBGameRulesOvertimeLockdown.uc,v 1.6 2007-04-01 00:34:19 jrubzjeknf Exp $
//
// When in overtime starts, the releases will be jammed. Once you're jailed,
// there's no getting out any more. Last chance to score a point!
// ============================================================================


class JBGameRulesOvertimeLockdown extends JBGameRules;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\LockIcon.dds mips=off masked=off group=icons


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    LockdownDelay;
}


// ============================================================================
// Variables
// ============================================================================

// Received from addon
var bool bNoArenaInOvertime;
var bool bNoEscapeInOvertime;
var byte LockdownDelay;            // in minutes

var class<JBLocalMessageOvertimeLockdown> MessageClassOvertimeLockdown;
var int EndTime;

var Color TimerDisplayColor;
var HudBase.SpriteWidget LockIcon;


// ============================================================================
// PostBeginPlay
//
// We'll be using Tick to find out if and when we need to start the lockdown.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  Disable('Tick');
}


// ============================================================================
// CanBroadcast
//
// When overtime starts, a message is passed through and ends up here.
// ============================================================================

function bool CanBroadcast(class<LocalMessage> MessageClass, optional int switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  // When overtime start.
  if (Switch == 910) {
    // Initiate clients overtime effects by notifying them.
    bClientTrigger = !bClientTrigger;

    if (Level.NetMode != NM_DedicatedServer)
      ClientTrigger();

    if (LockdownDelay == 0)
      GotoState('InitiateLockdown');
    else
      GotoState('WaitAndCountdown');
  }

  return Super.CanBroadcast(MessageClass, switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}


// ============================================================================
// PostNetReceive
//
// Changes the timer's display color and icon and alters the time displayed.
// ============================================================================

simulated function ClientTrigger()
{
  local JBInterfaceHud H;

  if (Level.GetLocalPlayerController() == None ||
      Level.GetLocalPlayerController().myHUD == None ||
      JBInterfaceHud(Level.GetLocalPlayerController().myHUD) == None)
    return;

  H = JBInterfaceHud(Level.GetLocalPlayerController().myHUD);
  H.ModifyTimerDisplay(class'HudCDeathmatch'.default.HudColorHighLight, LockIcon, LockdownDelay * 60 + 1, True, True, 1.0, LockdownDelay * 60);
}


// ============================================================================
// state WaitAndCountdown
//
// Wait before starting the Lockdown.
// ============================================================================

state WaitAndCountdown
{
  // ================================================================
  // BeginState
  //
  // Calculate when to start the lockdown.
  // ================================================================

  event BeginState()
  {
    EndTime = Level.Game.GameReplicationInfo.ElapsedTime + LockdownDelay * 60 + 1;

    Enable('Tick');
  }


  // ================================================================
  // Tick
  //
  // When the time is up, initiate the lockdown.
  // ================================================================

  function Tick(float dt)
  {
    // Cancel lockdown if executing.
    if (Jailbreak(Level.Game).IsInState('Executing')) {
      Disable('Tick');
      return;
    }

    if (Level.Game.GameReplicationInfo.ElapsedTime == EndTime) {
      Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown);

      Disable('Tick');
      GotoState('InitiateLockdown');
    }
  }
} // state WaitAndCountdown


// ============================================================================
// state InitiateLockdown
//
// Lockdown has been initiated.
// ============================================================================

state InitiateLockdown
{
  // ================================================================
  // BeginState
  //
  // Jam the locks, cancel any ongoing arena match, restart players,
  // prevent escapes and notify the players of the lockdown.
  // ================================================================

  event BeginState()
  {
    local JBInfoJail firstJail;
    local JBInfoJail thisJail;
    local JBInfoArena firstArena;
    local JBInfoArena thisArena;

    firstJail = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstJail;
    firstArena = JBGameReplicationInfo(Level.Game.GameReplicationInfo).firstArena;

    // Jam the jails, thus the locks
    for (thisJail = firstJail; thisJail != None; thisJail = thisJail.nextJail) {
      thisJail.Jam(0);
      thisJail.Jam(1);
    }

    // Cancel ongoing arena matches.
    if (bNoArenaInOvertime) {
      for (thisArena = firstArena; thisArena != None; thisArena = thisArena.nextArena)
        if (thisArena.IsInState('MatchRunning'))
          thisArena.MatchTie();
    }

    // Prevent players from being able to escape jail.
    if (bNoEscapeInOvertime)
      Jailbreak(Level.Game).bDisallowEscaping = True;

    // Tell everybody the lockdown has started.
    Level.Game.BroadcastHandler.BroadcastLocalizedMessage(MessageClassOvertimeLockdown);

    GotoState('Lockdown');
  }


  // ================================================================
  // CanBroadcast
  //
  // Prevent a message from popping up when an arena match is
  // cancelled when the lockdown kicks in.
  // ================================================================

  function bool CanBroadcast(class<LocalMessage> MessageClass, optional int switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
  {
    // Arenamatch tie.
    if (switch == 410 || switch == 420)
      return False;

    return Super.CanBroadcast(MessageClass, switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
  }
} // state InitiateLockdown


// ============================================================================
// state Lockdown
//
// Lockdown has started.
// ============================================================================

state Lockdown
{
  // ================================================================
  // CanSendToArena
  //
  // If specified, don't allow arena matches in overtime. Arena
  // matches in countdown will be automatically cancelled.
  // ================================================================

  function bool CanSendToArena(JBTagPlayer TagPlayer, JBInfoArena Arena, out byte bForceSendToArena)
  {
    if (bNoArenaInOvertime)
      return False;

    return Super.CanSendToArena(TagPlayer, Arena, bForceSendToArena);
  }


  // ================================================================
  // AllowForcedRelease
  //
  // Do not allow any releases in overtime.
  // ================================================================

  function bool AllowForcedRelease(JBInfoJail Jail, TeamInfo Team, optional Controller ControllerInstigator)
  {
    return False;
  }
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  MessageClassOvertimeLockdown = class'JBLocalMessageOvertimeLockdown'

  LockIcon = (WidgetTexture=Texture'JBAddonOvertimeLockdown.icons.LockIcon',PosX=0.0,PosY=0.0,OffsetX=10,OffsetY=9,DrawPivot=DP_UpperLeft,RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=34,Y2=33),TextureScale=0.55,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(G=255,R=255,B=255,A=255),Tints[1]=(G=255,R=255,B=255,A=255))

  bNetNotify = True
  bAlwaysRelevant = True
  bSkipActorPropertyReplication = False
  RemoteRole = ROLE_SimulatedProxy
}
