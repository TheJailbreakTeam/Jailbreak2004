//=============================================================================
// JBInterfaceLlamaHUDOverlay
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBInterfaceLlamaHUDOverlay.uc,v 1.3 2003/07/29 19:06:54 wormbo Exp $
//
// Registered as overlay for the Jailbreak HUD to draw the llama effects.
// Spawned client-side through the static function FindLlamaHUDOverlay called
// by a JBLlamaTag actor.
//=============================================================================


class JBInterfaceLlamaHUDOverlay extends Info;


//=============================================================================
// Imports
//=============================================================================

#exec Texture Import File=Textures\Llama.dds Mips=Off Alpha=1 Group=JBInterfaceLlamaHUDOverlay
#exec Texture Import File=Textures\LlamaIconMask.dds Mips=Off Alpha=1 Group=JBInterfaceLlamaHUDOverlay
#exec Texture Import File=Textures\LlamaScreenOverlay.dds Mips=Off Alpha=1 Group=JBInterfaceLlamaHUDOverlay
#exec Audio Import File=Sounds\Heartbeat.wav


//=============================================================================
// Variables
//=============================================================================

var private JBInterfaceHud       JailbreakHUD;          // local player's Jailbreak HUD
var private array<JBLlamaArrow>  LlamaArrows;           // a spinning arrow over the Llama's head
var private JBLlamaTag           LocalLlamaTag;         // llama tag of local player (if any)
var private float                TimeIndexLocalLlamaStart;
var MotionBlur                   MotionBlur;            // a motion blur effect for the llama
var CameraOverlay                CameraOverlay;         // an overlay camera effect for the llama
var bool                         bCameraEffectsEnabled; // whether the motion blur and overlay is active
var private float                HUDCanvasScale;
var private bool                 bHeartbeakPlayed;

// llama compass
var private HudBase.SpriteWidget LlamaCompassIcon;    // the llama icon
var private HudBase.SpriteWidget LlamaCompassIconBG;  // black circle background
var private HudBase.SpriteWidget LlamaCompassBG[3];   // connection between canvas border and actual compass
var private HudBase.SpriteWidget LlamaCompassDot;     // compas dot showing llamas
var private Material LlamaizedCompassIcon;            // the llama icon material when player is a llama
var private Material LlamaScreenOverlayMaterial;      // screen overlay material when player is a llama
var private float LlamaCompassSlideDistance;          // relative horizontal distance the llama compass is moved
var private float LlamaCompassSlidePosition;          // 0.0 = completely hidden, 1.0 = fully visible
var private float LlamaIconPulseRateR;
var private float LlamaIconPulseRateG;
var private float LlamaIconPulseRateB;


//=============================================================================
// HueToRGB
//
// Converts a LightHue value to a color assuming full saturation.
// Adapted from inio's implementation of the Chroma2RGB function at
// http://wiki.beyondunreal.com/wiki/HLS_To_RGB_Conversion
//=============================================================================

simulated function color HueToRGB(float Hue)
{
  local color C;
  local float R,G,B;
  
  hue /= 85;
  if (hue <= 1)      { g = hue  ; r = 1-g; b = 0;}
  else if (hue <= 2) { b = hue-1; g = 1-b; r = 0;}
  else               { r = hue-2; b = 1-r; g = 0;}
  
  C.R = R * 255.0;
  C.G = G * 255.0;
  C.B = B * 255.0;
  C.A = 255;
  return C;
}


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
  if ( bCameraEffectsEnabled ) {
    if ( CameraOverlay != None )
      Level.GetLocalPlayerController().RemoveCameraEffect(CameraOverlay);
    if ( MotionBlur != None )
      Level.GetLocalPlayerController().RemoveCameraEffect(MotionBlur);
  }
  Level.ObjectPool.FreeObject(MotionBlur);
  Level.ObjectPool.FreeObject(CameraOverlay);
  MotionBlur = None;
  CameraOverlay = None;
}


//=============================================================================
// Tick
//
// Updates the relative positions of the llama HUD elements.
//=============================================================================

simulated event Tick(float DeltaTime)
{
  local float HeartbeatTime;
  local PlayerController PlayerControllerLocal;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  
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
  
  if ( LocalLlamaTag != None && PlayerControllerLocal.ViewTarget == PlayerControllerLocal.Pawn
      && (MotionBlur == None || CameraOverlay == None) ) {
    if ( MotionBlur == None ) {
      MotionBlur = MotionBlur(Level.ObjectPool.AllocateObject(class'MotionBlur'));
      MotionBlur.Alpha = 1.0;
      MotionBlur.BlurAlpha = 128;
      MotionBlur.FinalEffect = False;
    }
    if ( CameraOverlay == None ) {
      CameraOverlay = CameraOverlay(Level.ObjectPool.AllocateObject(class'CameraOverlay'));
      CameraOverlay.OverlayMaterial = LlamaScreenOverlayMaterial;
      CameraOverlay.Alpha = 1.0;
      CameraOverlay.FinalEffect = False;
    }
    
    PlayerControllerLocal.AddCameraEffect(CameraOverlay, True);
    PlayerControllerLocal.AddCameraEffect(MotionBlur, True);
    bCameraEffectsEnabled = True;
    if ( JailbreakHUD != None )
      HUDCanvasScale = JailbreakHUD.HUDCanvasScale;
  }
  else if ( (LocalLlamaTag == None || PlayerControllerLocal.ViewTarget != PlayerControllerLocal.Pawn)
      && bCameraEffectsEnabled ) {
    PlayerControllerLocal.RemoveCameraEffect(CameraOverlay);
    PlayerControllerLocal.RemoveCameraEffect(MotionBlur);
    Level.ObjectPool.FreeObject(MotionBlur);
    Level.ObjectPool.FreeObject(CameraOverlay);
    MotionBlur = None;
    CameraOverlay = None;
    bCameraEffectsEnabled = False;
    if ( JailbreakHUD != None ) {
      JailbreakHUD.HUDCanvasScale = HUDCanvasScale;
      JailbreakHUD.SaveConfig();
    }
  }
  
  if ( JailbreakHUD != None && LocalLlamaTag != None
      && PlayerControllerLocal.ViewTarget == PlayerControllerLocal.Pawn ) {
    HeartbeatTime = ((Level.TimeSeconds - LocalLlamaTag.LlamaStartTime) / Level.TimeDilation) % 1.0;
    if ( HeartbeatTime < 0.05 ) {
      JailbreakHUD.HUDCanvasScale = HUDCanvasScale + 2 * HeartbeatTime;
      if ( !bHeartbeakPlayed ) {
        PlayerController(JailbreakHUD.Owner).ViewTarget.PlayOwnedSound(sound'Heartbeat', SLOT_Misc);
        bHeartbeakPlayed = True;
      }
    }
    else {
      bHeartbeakPlayed = False;
      if ( HeartbeatTime < 0.35 )
        JailbreakHUD.HUDCanvasScale = HUDCanvasScale + (0.35 - HeartbeatTime) / 3;
      else if ( HeartbeatTime < 0.4 )
        JailbreakHUD.HUDCanvasScale = HUDCanvasScale + (HeartbeatTime - 0.35) * 2;
      else if ( HeartbeatTime < 0.7 )
        JailbreakHUD.HUDCanvasScale = HUDCanvasScale + (0.7 - HeartbeatTime) / 3;
      else
        JailbreakHUD.HUDCanvasScale = HUDCanvasScale;
    }
  }
  
  if ( CameraOverlay != None )
    CameraOverlay.OverlayColor = HueToRGB((Level.TimeSeconds * 100.0) % 256);
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
        LlamaArrows[i].DrawArrow(C, thisLlama.Location + vect(0,0,1) * (2 * thisLlama.default.CollisionHeight - thisLlama.CollisionHeight + 40));
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
    LlamaCompassIcon.Tints[0].R = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateR));
    LlamaCompassIcon.Tints[0].G = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateG));
    LlamaCompassIcon.Tints[0].B = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateB));
    LlamaCompassIcon.Tints[1].R = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateR));
    LlamaCompassIcon.Tints[1].G = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateG));
    LlamaCompassIcon.Tints[1].B = 255 * (0.85 + 0.15 * Cos(Level.TimeSeconds * Pi * LlamaIconPulseRateB));
    LlamaCompassIcon.TextureScale = 0.28;
    LlamaCompassIcon.WidgetTexture = LlamaizedCompassIcon;
  }
  else {
    LlamaCompassIcon = Default.LlamaCompassIcon;
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
// SetLocalLlamaTag
//
// Sets LocalLlamaTag to the local player's JBLlamaTag.
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
  //===========================================================================
  // Llama icon textures
  //===========================================================================

  Begin Object Class=TexOscillator Name=LlamaIconOscillator
    UOscillationRate=0.7
    VOscillationRate=0.8
    UOscillationAmplitude=0.2
    VOscillationAmplitude=0.2
    UOscillationType=OT_Stretch
    VOscillationType=OT_Stretch
    UOffset=64.000000
    VOffset=64.000000
    Material=Texture'Llama'
    FallbackMaterial=Texture'Llama'
  End Object
  
  Begin Object Class=TexRotator Name=LlamaIconRotator
    TexRotationType=TR_OscillatingRotation
    UOffset=64.0
    VOffset=64.0
    OscillationRate=(Yaw=20000)
    OscillationAmplitude=(Yaw=8000)
    Material=TexOscillator'LlamaIconOscillator'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
  End Object
  
  Begin Object Class=Combiner Name=LlamaIconCombiner
    AlphaOperation=AO_Multiply
    Material1=TexRotator'LlamaIconRotator'
    Material2=Texture'LlamaIconMask'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
  End Object
  
  Begin Object Class=FinalBlend Name=LlamaIconFinalBlend
    FrameBufferBlending=FB_AlphaBlend
    Material=Combiner'LlamaIconCombiner'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
  End Object
  
  
  //===========================================================================
  // Llama screen overlay textures
  //===========================================================================
  
  Begin Object Class=TexOscillator Name=OverlayOscillator1
    UOscillationRate=0.015
    VOscillationRate=0.020
    UOscillationPhase=0.1
    VOscillationPhase=0.7
    UOscillationAmplitude=0.5
    VOscillationAmplitude=0.5
    Material=Texture'LlamaScreenOverlay'
    FallbackMaterial=Texture'LlamaScreenOverlay'
  End Object
  
  Begin Object Class=TexOscillator Name=OverlayOscillator2
    UOscillationRate=0.020
    VOscillationRate=0.015
    UOscillationPhase=0.6
    VOscillationPhase=0.2
    UOscillationAmplitude=0.5
    VOscillationAmplitude=0.5
    Material=Texture'LlamaScreenOverlay'
    FallbackMaterial=Texture'LlamaScreenOverlay'
  End Object
  
  Begin Object Class=TexOscillator Name=Overlay1Scaler
    UOscillationRate=0.020
    VOscillationRate=0.015
    VOscillationPhase=0.1
    UOscillationAmplitude=0.3
    VOscillationAmplitude=0.3
    UOscillationType=OT_Stretch
    VOscillationType=OT_Stretch
    UOffset=128.0
    VOffset=128.0
    Material=TexOscillator'OverlayOscillator1'
    FallbackMaterial=TexOscillator'OverlayOscillator1'
  End Object
  
  Begin Object Class=TexOscillator Name=Overlay2Scaler
    UOscillationRate=0.004
    VOscillationRate=0.003
    UOscillationPhase=0.4
    VOscillationPhase=0.5
    UOscillationAmplitude=0.5
    VOscillationAmplitude=0.5
    UOscillationType=OT_Stretch
    VOscillationType=OT_Stretch
    UOffset=128.0
    VOffset=128.0
    Material=TexOscillator'OverlayOscillator2'
    FallbackMaterial=TexOscillator'OverlayOscillator2'
  End Object
  
  Begin Object Class=Combiner Name=OverlayCombiner
    CombineOperation=AO_Multiply
    AlphaOperation=CO_Add
    Material1=TexOscillator'Overlay1Scaler'
    Material2=TexOscillator'Overlay2Scaler'
  End Object
  
  Begin Object Class=FinalBlend Name=LlamaScreenOverlayFinal
    FrameBufferBlending=FB_Translucent
    Material=Combiner'OverlayCombiner'
    FallbackMaterial=TexOscillator'Overlay2Scaler'
  End Object
  
  
  //===========================================================================
  // HUD elements
  //===========================================================================
  
  LlamaCompassIcon=(WidgetTexture=Texture'Llama',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=128),DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassIconBG=(WidgetTexture=Texture'SpriteWidgetHud',RenderStyle=STY_Alpha,TextureCoords=(X1=368,Y1=352,X2=510,Y2=494),TextureScale=0.3,DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassBG(0)=(WidgetTexture=Texture'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=900,X2=979,Y2=1023),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=255,G=255,B=255,A=200),Tints[1]=(R=255,G=255,B=255,A=200))
  LlamaCompassBG(1)=(WidgetTexture=Texture'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=777,X2=979,Y2=899),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150))
  LlamaCompassBG(2)=(WidgetTexture=Texture'InterfaceContent.Hud.SkinA',RenderStyle=STY_Alpha,TextureCoords=(X1=611,Y1=654,X2=979,Y2=776),TextureScale=0.3,DrawPivot=DP_MiddleLeft,PosX=0.94,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=100,G=0,B=0,A=200),Tints[1]=(R=48,G=75,B=120,A=200))
  LlamaCompassDot=(WidgetTexture=Texture'SpriteWidgetHud',RenderStyle=STY_Alpha,TextureCoords=(X1=304,Y1=352,X2=336,Y2=384),TextureScale=0.25,DrawPivot=DP_MiddleMiddle,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255))
  LlamaizedCompassIcon=FinalBlend'LlamaIconFinalBlend'
  LlamaScreenOverlayMaterial=FinalBlend'LlamaScreenOverlayFinal'
  LlamaCompassSlideDistance=0.12
  LlamaIconPulseRateR=1.5317
  LlamaIconPulseRateG=2.6873
  LlamaIconPulseRateB=1.0912
}