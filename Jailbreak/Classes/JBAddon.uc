// ============================================================================
// JBAddon
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
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
// InitAddon
//
// Called server- and client-side when the game type has finished its own
// initialization. Sets the JBGameReplicationInfo reference and registers the
// addon as an overlay actor if bIsOverlay is set.
// ============================================================================

simulated function InitAddon()
{
  local PlayerController PlayerControllerLocal;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);

  if (Level.Game != None)
         JBGameReplicationInfo = JBGameReplicationInfo(Level.Game.GameReplicationInfo);
    else JBGameReplicationInfo = JBGameReplicationInfo(PlayerControllerLocal.GameReplicationInfo);
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
  local PlayerController PlayerControllerLocal;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).UnregisterOverlay(Self);

  if (Role == ROLE_Authority)
    Super.Destroyed();
}
