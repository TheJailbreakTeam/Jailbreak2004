// ============================================================================
// JBScreen
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBScreen.uc,v 1.2 2003/06/30 22:08:29 mychaeel Exp $
//
// Abstract base class for ScriptedTexture clients.
// ============================================================================


class JBScreen extends Info
  abstract
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\JBScreen.pcx mips=off masked=on


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    ScriptedTexture, RefreshRate;
  }


// ============================================================================
// Properties
// ============================================================================

var() const editconst string Build;

var() ScriptedTexture ScriptedTexture;        // ScriptedTexture to draw on
var() float RefreshRate;                      // frequency of texture updates


// ============================================================================
// Variables
// ============================================================================

var protected bool bEnabled;                  // screens are enabled

var protected vector SizeScriptedTexture;     // size of ScriptedTexture
var protected vector SizeMaterialBackground;  // size of background material

var protected Color ColorWhite;               // white color used for textures


// ============================================================================
// UpdatePrecacheMaterials
//
// Precaches the ScriptedTexture and the background material.
// ============================================================================

simulated function UpdatePrecacheMaterials() {

  if (ScriptedTexture == None)
    return;

  Level.AddPrecacheMaterial(ScriptedTexture);
  Level.AddPrecacheMaterial(ScriptedTexture.FallbackMaterial);
  }


// ============================================================================
// PostNetBeginPlay
//
// Registers this actor with the specified ScriptedTexture. Sets a timer to
// refresh the texture periodically. Prepares the used materials.
// ============================================================================

simulated event PostNetBeginPlay() {

  if (ScriptedTexture == None || RefreshRate <= 0.0)
    return;

  ScriptedTexture.Client = Self;
  
  bEnabled = Class'Jailbreak'.Default.bEnableScreens;
  if (bEnabled)
         SetTimer(1.0 / RefreshRate, True);   // periodically update
    else SetTimer(1.0 / RefreshRate, False);  // initial update only

  PrepareMaterial();
  }


// ============================================================================
// Reset
//
// Called when the bEnableScreens config setting is changed. Sets the update
// timer accordingly.
// ============================================================================

simulated function Reset() {

  bEnabled = Class'Jailbreak'.Default.bEnableScreens;
  if (bEnabled)
         SetTimer(1.0 / RefreshRate, True);   // periodically update
    else SetTimer(1.0 / RefreshRate, False);  // update once more and freeze
  }


// ============================================================================
// Timer
//
// Updates the texture.
// ============================================================================

simulated event Timer() {

  ScriptedTexture.Revision++;
  }


// ============================================================================
// RenderTexture
//
// Renders the FallbackMaterial on the background of the texture.
// ============================================================================

simulated event RenderTexture(ScriptedTexture ScriptedTexture) {

  if (ScriptedTexture.FallbackMaterial != None)
    ScriptedTexture.DrawTile(
      0, 0, SizeScriptedTexture   .X, SizeScriptedTexture   .Y, 
      0, 0, SizeMaterialBackground.X, SizeMaterialBackground.Y,
      ScriptedTexture.FallbackMaterial, ColorWhite);
  }


// ============================================================================
// PrepareMaterial
//
// Caches information about the used materials.
// ============================================================================

simulated protected function PrepareMaterial() {

  if (ScriptedTexture == None)
    return;

  SizeScriptedTexture.X = ScriptedTexture.MaterialUSize();
  SizeScriptedTexture.Y = ScriptedTexture.MaterialVSize();

  if (ScriptedTexture.FallbackMaterial != None) {
    SizeMaterialBackground.X = ScriptedTexture.FallbackMaterial.MaterialUSize();
    SizeMaterialBackground.Y = ScriptedTexture.FallbackMaterial.MaterialVSize();
    }
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  Build = "%%%%-%%-%% %%:%%";

  ScriptedTexture = None;
  RefreshRate = 20.0;

  ColorWhite = (R=255,G=255,B=255,A=255);
  
  Texture = Texture'JBScreen';
  bAlwaysRelevant = True;
  RemoteRole = ROLE_SimulatedProxy;
  }