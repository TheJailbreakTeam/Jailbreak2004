// ============================================================================
// JBAddon
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBAddon.uc,v 1.4 2004/02/16 17:17:01 mychaeel Exp $
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
var const bool bCanResetConfig; // requests a button in JBGUITabPanelAddons


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