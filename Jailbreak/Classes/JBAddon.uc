// ============================================================================
// JBAddon
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBAddon.uc,v 1.1 2003/06/25 19:01:45 mychaeel Exp $
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

function bool MutatorIsAllowed() {

  return (Jailbreak(Level.Game) != None);
  }


// ============================================================================
// PostNetBeginPlay
//
// Sets the JBGameReplicationInfo reference both client- and server-side.
// ============================================================================

simulated event PostNetBeginPlay() {

  local PlayerController PlayerControllerLocal;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);

  if (Level.Game != None)
         JBGameReplicationInfo = JBGameReplicationInfo(Level.Game.GameReplicationInfo);
    else JBGameReplicationInfo = JBGameReplicationInfo(PlayerControllerLocal.GameReplicationInfo);
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

simulated event Destroyed() {

  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if (bIsOverlay && PlayerControllerLocal != None)
    JBInterfaceHud(PlayerControllerLocal.myHud).UnregisterOverlay(Self);

  if (Role == ROLE_Authority)
    Super.Destroyed();
  }