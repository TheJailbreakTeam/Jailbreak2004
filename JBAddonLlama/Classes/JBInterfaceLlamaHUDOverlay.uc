//=============================================================================
// JBInterfaceLlamaHUDOverlay
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBInterfaceLlamaHUDOverlay.uc,v 1.2 2003/07/26 23:24:49 wormbo Exp $
//
// Registered as overlay for the Jailbreak HUD to draw the llama effects.
// Spawned client-side through the static function FindLlamaHUDOverlay called
// by a JBLlamaTag actor.
//=============================================================================


class JBInterfaceLlamaHUDOverlay extends Info;


//=============================================================================
// Imports
//=============================================================================

#exec texture import file=Textures\Llama.dds mips=on alpha=on lodset=LODSET_Interface


//=============================================================================
// Variables
//=============================================================================

var private JBInterfaceHud       JailbreakHUD;       // local player's Jailbreak HUD
var private array<JBLlamaArrow>  LlamaArrows;        // a spinning arrow over the Llama's head
var private JBLlamaTag           LocalLlamaTag;      // llama tag of local player (if any)
var private float                TimeIndexLocalLlamaStart;
var MotionBlur                   MotionBlur;         // a motion blur effect for the llama
var bool                         bMotionBlurEnabled; // whether the motion blur effect is active

// llama compass
var private HudBase.SpriteWidget LlamaCompassIcon;   // the llama icon
var private HudBase.SpriteWidget LlamaCompassIconBG; // black circle background
var private HudBase.SpriteWidget LlamaCompassBG[3];  // connection between canvas border and actual compass
var private HudBase.SpriteWidget LlamaCompassDot;    // compas dot showing llamas
var private float LlamaCompassSlideDistance;         // relative horizontal distance the llama compass is moved
var private float LlamaCompassSlidePosition;         // 0.0 = completely hidden, 1.0 = fully visible
var private float LlamaIconPulseRateR;
var private float LlamaIconPulseRateG;
var private float LlamaIconPulseRateB;


//=============================================================================
// PostBeginPlay
//
// Registers this actor as HUD overlay.
//=============================================================================

simulated function PostBeginPlay()
{
  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None ) {
    JailbreakHUD = JBInterfaceHud(PlayerControllerLocal.myHud);
    JBInterfaceHud(PlayerControllerLocal.myHud).RegisterOverlay(Self);
  }
}


//=============================================================================
// Destroyed
//
// Automatically unregisters this actor.
//=============================================================================

simulated event Destroyed()
{
  JailbreakHUD.UnregisterOverlay(Self);
}


//=============================================================================
// Tick
//
// Updates the relative positions of the llama HUD elements.
//=============================================================================

simulated event Tick(float DeltaTime)
{
  // update Llama compass position
  if ( ShouldDisplayLlamaCompass() ) {
    if ( LlamaCompassSlidePosition < 1.0 ) {
      LlamaCompassSlidePosition += DeltaTime;
      if ( LlamaCompassSlidePosition > 1.0 )
        LlamaCompassSlidePosition = 1.0;
    }
  }
  else {
    if ( LlamaCompassSlidePosition > 0.0 ) {
      LlamaCompassSlidePosition -= DeltaTime;
      if ( LlamaCompassSlidePosition < 0.0 )
        LlamaCompassSlidePosition = 0.0;
    }
  }
  
  if ( LocalLlamaTag != None && !bMotionBlurEnabled ) {
    if ( MotionBlur == None )
      MotionBlur = new(None) class'MotionBlur';
    
    Level.GetLocalPlayerController().AddCameraEffect(MotionBlur, True);
    bMotionBlurEnabled = True;
  }
  else if ( LocalLlamaTag == None && bMotionBlurEnabled ) {
    Level.GetLocalPlayerController().RemoveCameraEffect(MotionBlur);
    bMotionBlurEnabled = False;
  }
}


//=============================================================================
// RenderOverlays
//
// Render the Llama effects.
//=============================================================================

simulated function RenderOverlays(Canvas C)
{
  local int i;
  local float AngleDot;
  local vector LocationOwner;
  local plane OldModulate;
  local Pawn thisLlama;
  
  if ( JailbreakHUD == None ) {
    warn("JailbreakHUD == None");
    return;
  }
  
  UpdateLlamaHUDElements();
  
  OldModulate = C.ColorModulate;
  C.ColorModulate.X = 1;
  C.ColorModulate.Y = 1;
  C.ColorModulate.Z = 1;
  C.ColorModulate.W = JailbreakHUD.HudOpacity / 255;
  
  if ( ShouldDisplayLlamaCompass() || LlamaCompassSlidePosition > 0.0 ) {
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassBG[2]);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassBG[1]);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassBG[0]);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassIconBG);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassIcon);
  }
  
  if ( JailbreakHUD.PawnOwner != None)
    LocationOwner = JailbreakHUD.PawnOwner.Location;
  else
    LocationOwner = JailbreakHUD.PlayerOwner.Location;
  
  C.DrawColor = JailbreakHUD.GoldColor;
  for (i = 0; i < LlamaArrows.Length; i++) {
    if ( LlamaArrows[i].LlamaTag != None && Pawn(LlamaArrows[i].LlamaTag.Owner) != None ) {
      if ( !Pawn(LlamaArrows[i].LlamaTag.Owner).bHidden )
        thisLlama = Pawn(LlamaArrows[i].LlamaTag.Owner);
      else if ( Pawn(LlamaArrows[i].LlamaTag.Owner).Controller != None )
        thisLlama = Pawn(LlamaArrows[i].LlamaTag.Owner).Controller.Pawn;
      
      if ( thisLlama != None && C.Viewport.Actor.LineOfSightTo(thisLlama) )
        LlamaArrows[i].DrawArrow(C, thisLlama.Location + vect(0,0,1) * (thisLlama.CollisionHeight + 40.0));
      else
        LlamaArrows[i].DrawArrow(C);
    }
    else
      LlamaArrows[i].DrawArrow(C);
    
    if ( LlamaArrows[i].LlamaTag != None && LlamaArrows[i].LlamaTag != LocalLlamaTag ) {
      AngleDot = ((rotator(LlamaArrows[i].LlamaTag.TagPlayer.GetLocationPawn() - LocationOwner).Yaw - JailbreakHUD.PlayerOwner.Rotation.Yaw) & 65535) * Pi / 32768;
      LlamaCompassDot.PosX = LlamaCompassIconBG.PosX + 0.0305 * Sin(AngleDot) * JailbreakHUD.HudScale;
      LlamaCompassDot.PosY = LlamaCompassIconBG.PosY - 0.0405 * Cos(AngleDot) * JailbreakHUD.HudScale;
      JailbreakHUD.DrawSpriteWidget(C, LlamaCompassDot);
    }
  }
  C.ColorModulate = OldModulate;
}


//=============================================================================
// UpdateLlamaHUDElements
//
// Updates the relative draw locations of the SpriteWidgets based on
// LlamaCompassSlidePosition and LlamaIconSlidePosition.
//=============================================================================

simulated function UpdateLlamaHUDElements()
{
  if ( LocalLlamaTag != None ) {
    LlamaCompassIcon.Tints[0].R = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateR));
    LlamaCompassIcon.Tints[0].G = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateG));
    LlamaCompassIcon.Tints[0].B = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateB));
    LlamaCompassIcon.Tints[1].R = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateR));
    LlamaCompassIcon.Tints[1].G = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateG));
    LlamaCompassIcon.Tints[1].B = 255 * (0.6 + 0.4 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateB));
  }
  else {
    LlamaCompassIcon.Tints[0] = JailbreakHUD.WhiteColor;
    LlamaCompassIcon.Tints[1] = JailbreakHUD.WhiteColor;
  }
  
  LlamaCompassIcon.PosX   = Default.LlamaCompassIcon.PosX   + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
  LlamaCompassIconBG.PosX = Default.LlamaCompassIconBG.PosX + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
  LlamaCompassBG[0].PosX  = Default.LlamaCompassBG[0].PosX  + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
  LlamaCompassBG[1].PosX  = Default.LlamaCompassBG[1].PosX  + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
  LlamaCompassBG[2].PosX  = Default.LlamaCompassBG[2].PosX  + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
}


//=============================================================================
// ShouldDisplayLlamaCompass
//
// Returns whether the Llama compass should be displayed.
//=============================================================================

simulated function bool ShouldDisplayLlamaCompass()
{
  local int i;
  
  CleanArrowList();
  
  if ( LocalLlamaTag != None )
    return true;
  
  for (i = 0; i < LlamaArrows.Length; i++)
    if ( LlamaArrows[i].LlamaTag != None )
      return true;
  
  return false;
}


//=============================================================================
// FindLlamaHUDOverlay
//
// Returns an existing JBInterfaceLlamaHUDOverlay actor or spawns a new one if
// nothing was found.
//=============================================================================

static function JBInterfaceLlamaHUDOverlay FindLlamaHUDOverlay(Actor Requester)
{
  local JBInterfaceLlamaHUDOverlay thisLlamaHUDOverlay;
  
  if ( Requester == None ) {
    // can't work without an actor reference
    Warn("No requesting actor specified.");
    return None;
  }
  
  foreach Requester.DynamicActors(class'JBInterfaceLlamaHUDOverlay', thisLlamaHUDOverlay)
    break;
  
  if ( thisLlamaHUDOverlay == None ) {
    // no JBInterfaceLlamaHUDOverlay found, spawn a new one
    thisLlamaHUDOverlay = Requester.Spawn(Default.Class);
  }
  
  return thisLlamaHUDOverlay;
}


//=============================================================================
// CleanArrowList
//
// Removes empty array elements in LlamaArrows.
//=============================================================================

simulated function SetLocalLlamaTag(JBLlamaTag newLlamaTag)
{
  if ( newLlamaTag != None ) {
    LocalLlamaTag = newLlamaTag;
    TimeIndexLocalLlamaStart = Level.TimeSeconds;
  }
}


//=============================================================================
// AddArrow
//
// Adds a JBLlamaArrow to the LlamaArrows array.
//=============================================================================

simulated function AddArrow(JBLlamaArrow newArrow)
{
  if ( newArrow != None )
    LlamaArrows[LlamaArrows.Length] = newArrow;
}


//=============================================================================
// CleanArrowList
//
// Removes empty array elements in LlamaArrows.
//=============================================================================

simulated function CleanArrowList()
{
  local int i;
  
  for (i = LlamaArrows.Length-1; i >= 0; i--)
    if ( LlamaArrows[i] == None )
      LlamaArrows.Remove(i, 1);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  LlamaCompassIcon=(WidgetTexture=Material'Llama',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=128),TextureScale=0.25,DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassIconBG=(WidgetTexture=Material'SpriteWidgetHud',RenderStyle=STY_Alpha,TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.3,DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassBG(0)=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=900,X2=979,Y2=1023),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=255,G=255,B=255,A=200),Tints[1]=(R=255,G=255,B=255,A=200))
  LlamaCompassBG(1)=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=777,X2=979,Y2=899),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150))
  LlamaCompassBG(2)=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=654,X2=979,Y2=776),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=100,G=0,B=0,A=200),Tints[1]=(R=48,G=75,B=120,A=200))
  LlamaCompassDot=(WidgetTexture=Material'SpriteWidgetHud',RenderStyle=STY_Alpha,TextureCoords=(X1=304,Y1=352,X2=336,Y2=384),TextureScale=0.25,DrawPivot=DP_MiddleMiddle,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255))
  LlamaCompassSlideDistance=0.12
  LlamaIconPulseRateR=1.5317
  LlamaIconPulseRateG=2.6873
  LlamaIconPulseRateB=1.0912
}