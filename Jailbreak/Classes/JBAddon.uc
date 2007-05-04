// ============================================================================
// JBAddon
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBAddon.uc,v 1.12 2007-02-11 17:25:30 wormbo Exp $
//
// Base class for Jailbreak Add-On mutators. Introduced only for the sake of
// distinguishing them from regular mutators in the user interface, but also
// provides some useful tool functions.
//
// See http://www.planetjailbreak.com/jdn/Jailbreak_Add-Ons for details.
// ============================================================================


class JBAddon extends Mutator
  abstract;


// ============================================================================
// Properties
// ============================================================================

var const bool bIsOverlay;  // set to have RenderOverlays called client-side


// ============================================================================
// Variables
// ============================================================================

var JBGameReplicationInfo JBGameReplicationInfo;
var PlayerController PlayerControllerLocal;


// ============================================================================
// MutatorIsAllowed
//
// Disallows this add-on unless it is run for a Jailbreak game.
// ============================================================================

function bool MutatorIsAllowed()
{
  return (Jailbreak(Level.Game) != None);
}


// ============================================================================
// state Startup
//
// Waits for a tick to ensure that the local player controller has been
// spawned if any is spawned at all, then registers this actor as an overlay.
// ============================================================================

auto simulated state Startup
{
Begin:
  Sleep(0.0);

  if (PlayerControllerLocal == None)
    PlayerControllerLocal = Level.GetLocalPlayerController();
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);

} // state Startup


// ============================================================================
// InitAddon
//
// Called server- and client-side when the game type has finished its own
// initialization. Sets the JBGameReplicationInfo reference.
// ============================================================================

simulated function InitAddon()
{
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (Level.Game != None)
    JBGameReplicationInfo = JBGameReplicationInfo(Level.Game.GameReplicationInfo);
  else
    JBGameReplicationInfo = JBGameReplicationInfo(PlayerControllerLocal.GameReplicationInfo);
}


// ============================================================================
// PostNetBeginPlay
//
// Calls the InitAddon function client-side. Server-side, InitAddon is called
// by the game type PostBeginPlay event itself.
// ============================================================================

simulated event PostNetBeginPlay()
{
  if (Role < ROLE_Authority)
    InitAddon();
}


// ============================================================================
// RenderOverlays
//
// If bIsOverlay is set to True, called client-side once per frame to allow
// the add-on to draw on the screen.
// ============================================================================

simulated function RenderOverlays(Canvas Canvas);


// ============================================================================
// NotifyLevelChange
//
// Called client-side and on listen servers when the level changes.
// ============================================================================

simulated function NotifyLevelChange();


// ============================================================================
// PlayInfoGroup
//
// Returns the name to be used for this add-on in FillPlayInfo.
// ============================================================================

static function string PlayInfoGroup()
{
  return Class'Jailbreak'.Default.TextWebAdminPrefixAddon @ Default.FriendlyName;
}


// ============================================================================
// GetServerDetails
//
// Puts Jailbreak add-ons into a separate list so that Jailbreak servers show
// up in the server browser even if Standard Servers Only is checked.
// ============================================================================

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
  local int iServerInfo;

  iServerInfo = ServerState.ServerInfo.Length;
  ServerState.ServerInfo.Insert(iServerInfo, 1);
  ServerState.ServerInfo[iServerInfo].Key = "AddOn";
  ServerState.ServerInfo[iServerInfo].Value = GetHumanReadableName();
}


// ============================================================================
// Destroyed
//
// Automatically unregisters this actor if bIsOverlay is set to True.
// ============================================================================

simulated event Destroyed()
{
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).UnregisterOverlay(Self);

  if (Role == ROLE_Authority)
    Super.Destroyed();
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bAddToServerPackages = True;
}
