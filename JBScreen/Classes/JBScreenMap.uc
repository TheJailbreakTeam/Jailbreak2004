// ============================================================================
// JBScreenMap
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Base class for client actors for a ScriptedTexture drawing player locations
// on a minimap. 
// ============================================================================


class JBScreenMap extends JBScreen
  abstract
  notplaceable;


// ============================================================================
// Imports
// ============================================================================

#exec texture import file=Textures\ScreenIconPlayer.tga mips=off alpha=on UClampMode=TC_Clamp VClampMode=TC_Clamp


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    IconMaterial,
    IconPulseRate,
    bShowTeamRed,
    bShowTeamBlue,
    bShowInFreedom,
    bShowInArena,
    bShowInJail;
  }


// ============================================================================
// Properties
// ============================================================================

var() Material IconMaterial[2];  // icon materials by team index
var() float IconPulseRate;       // icon pulse rate, zero if off

var() bool bShowTeamRed;         // show players of red team
var() bool bShowTeamBlue;        // show players of blue team

var() bool bShowInFreedom;       // show free players
var() bool bShowInArena;         // show players in arena
var() bool bShowInJail;          // show players in jail


// ============================================================================
// Localization
// ============================================================================

var localized string TextError;  // error in coordinate system setup


// ============================================================================
// Variables
// ============================================================================

var protected vector SizeIconMaterial[2];    // size of icon materials

var private bool bInitializationSuccessful;  // everything ready to render


// ============================================================================
// UpdatePrecacheMaterials
//
// Precaches the icon materials.
// ============================================================================

simulated function UpdatePrecacheMaterials() {

  local int iIcon;
  
  for (iIcon = 0; iIcon < ArrayCount(IconMaterial); iIcon++)
    Level.AddPrecacheMaterial(IconMaterial[iIcon]);

  Super.UpdatePrecacheMaterials();
  }


// ============================================================================
// PostNetBeginPlay
//
// Prepares the coordinate translations.
// ============================================================================

simulated event PostNetBeginPlay() {

  Super.PostNetBeginPlay();
  
  bInitializationSuccessful = PrepareCoords();
  }


// ============================================================================
// RenderTexture
//
// Draws player icons on the texture.
// ============================================================================

simulated event RenderTexture(ScriptedTexture ScriptedTexture) {

  local int HeightTextError;
  local int WidthTextError;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  if (bInitializationSuccessful) {
    Super.RenderTexture(ScriptedTexture);
    
    if (bEnabled) {
      firstTagPlayer = JBGameReplicationInfo(Level.GetLocalPlayerController().GameReplicationInfo).firstTagPlayer;
      for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
        if (IsIconDisplayed(thisTagPlayer))
          DrawIcon(ScriptedTexture, thisTagPlayer, CalcLocation(thisTagPlayer.GetLocationPawn()));
      }
    }
  
  else {
    ScriptedTexture.TextSize(TextError, Font'DefaultFont', WidthTextError, HeightTextError);
    ScriptedTexture.DrawText(
      (SizeScriptedTexture.X - WidthTextError)  / 2,
      (SizeScriptedTexture.Y - HeightTextError) / 2,
      TextError, Font'DefaultFont', ColorWhite);

    SetTimer(0.0, False);  // no further updates
    }
  }


// ============================================================================
// PrepareMaterial
//
// Caches information about the icon materials.
// ============================================================================

simulated protected function PrepareMaterial() {

  local int iIcon;

  Super.PrepareMaterial();

  for (iIcon = 0; iIcon < ArrayCount(IconMaterial); iIcon++)
    if (IconMaterial[iIcon] != None) {
      SizeIconMaterial[iIcon].X = IconMaterial[iIcon].MaterialUSize();
      SizeIconMaterial[iIcon].Y = IconMaterial[iIcon].MaterialVSize();
      }
  }


// ============================================================================
// PrepareCoords
//
// Performs whatever preparation should be done for the calculations that
// translate world coordinates into texture coordinates. Returns whether the
// coordinates could be successfully prepared. Implemented in subclasses.
// ============================================================================

simulated protected function bool PrepareCoords() {

  return True;
  }


// ============================================================================
// CalcLocation
//
// Calculates and returns the texture pixel coordinates corresponding to the
// given world coordinates. Called only after PrepareCoords was called.
// Implemented in subclasses.
// ============================================================================

simulated function vector CalcLocation(vector LocationWorld);


// ============================================================================
// IsIconDisplayed
//
// Checks and returns whether the icon for the given player should be shown on
// the minimap texture.
// ============================================================================

simulated function bool IsIconDisplayed(JBTagPlayer TagPlayer) {

  local int iTeam;
  
  if (TagPlayer.GetHealth(True) <= 0) return False;
  
  iTeam = TagPlayer.GetTeam().TeamIndex;
  if (iTeam == 0 && !bShowTeamRed)  return False;
  if (iTeam == 1 && !bShowTeamBlue) return False;

  if (TagPlayer.IsFree()    && !bShowInFreedom) return False;
  if (TagPlayer.IsInJail()  && !bShowInJail)    return False;
  if (TagPlayer.IsInArena() && !bShowInArena)   return False;
  
  return True;
  }


// ============================================================================
// DrawIcon
//
// Draws the icon for the given player on the given ScriptedTexture at the
// specified pixel location.
// ============================================================================

simulated function DrawIcon(ScriptedTexture ScriptedTexture, JBTagPlayer TagPlayer, vector LocationIcon) {

  local int iIcon;
  local Color ColorIcon;
  
  iIcon = TagPlayer.GetTeam().TeamIndex;

  if (IconMaterial[iIcon] == None)
    return;

  LocationIcon.X -= SizeIconMaterial[iIcon].X / 2;
  LocationIcon.Y -= SizeIconMaterial[iIcon].Y / 2;

  ColorIcon = ColorWhite;
  if (IconPulseRate > 0.0)
    ColorIcon.A = Clamp(ColorIcon.A * (1.0 - (Level.TimeSeconds * IconPulseRate / 2.0) % 0.5), 0, 255);
  
  ScriptedTexture.DrawTile(
    LocationIcon.X, LocationIcon.Y, SizeIconMaterial[iIcon].X, SizeIconMaterial[iIcon].Y,
    0,              0,              SizeIconMaterial[iIcon].X, SizeIconMaterial[iIcon].Y,
    IconMaterial[iIcon], ColorIcon);
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextError = "Error in coordinate system setup.";

  Begin Object Class=ColorModifier Name=ScreenIconPlayerRed
    Material = Texture'ScreenIconPlayer';
    Color = (R=255,G=0,B=0);
  End Object

  Begin Object Class=ColorModifier Name=ScreenIconPlayerBlue
    Material = Texture'ScreenIconPlayer';
    Color = (R=0,G=0,B=255);
  End Object

  IconMaterial[0] = Material'ScreenIconPlayerRed';
  IconMaterial[1] = Material'ScreenIconPlayerBlue';
  IconPulseRate = 1.0;

  bShowTeamRed   = True;
  bShowTeamBlue  = True;
  
  bShowInFreedom = True;
  bShowInArena   = False;
  bShowInJail    = False;
  }