//=============================================================================
// JBInterfaceLlamaHUDOverlay
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBInterfaceLlamaHUDOverlay.uc,v 1.9 2004/05/31 11:14:57 wormbo Exp $
//
// Registered as overlay for the Jailbreak HUD to draw the llama effects.
// Spawned client-side through the static function FindLlamaHUDOverlay called
// by a JBLlamaTag actor.
//=============================================================================


class JBInterfaceLlamaHUDOverlay extends Info notplaceable;


//=============================================================================
// Imports
//=============================================================================

#exec Texture Import File=Textures\Llama.dds Mips=Off Alpha=1 Group=LlamaCompass
#exec Texture Import File=Textures\LlamaIconMask.dds Mips=Off Alpha=1 Group=LlamaCompass
#exec Texture Import File=Textures\LlamaScreenOverlay.dds Mips=Off Alpha=1 Group=LlamaHudOverlay
#exec Audio Import File=Sounds\Heartbeat.wav
#exec obj load file=..\Textures\HudContent.utx


//=============================================================================
// Variables
//=============================================================================

var private JBInterfaceHud       JailbreakHUD;          // local player's Jailbreak HUD
var private array<JBLlamaArrow>  LlamaArrows;           // a spinning arrow over the Llama's head
var private JBLlamaTag           LocalLlamaTag;         // llama tag of local player (if any)
var private float                TimeIndexLocalLlamaStart;
var GameEngine                   GameEngine;            // reference to the GameEngine object
var MotionBlur                   MotionBlur;            // a motion blur effect for the llama
var CameraOverlay                CameraOverlay;         // an overlay camera effect for the llama
var bool                         bCameraEffectsEnabled; // whether the motion blur and overlay is active
var private float                HUDCanvasScale;
var private bool                 bHeartbeakPlayed;

// llama compass
var private HudBase.SpriteWidget LlamaCompassIcon;    // the llama icon
var private HudBase.SpriteWidget LlamaCompassIconBG;  // black circle background
var private HudBase.SpriteWidget LlamaCompassBG;      // connection between canvas border and actual compass
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

static final function color HueToRGB(float Hue)
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
// FindCameraEffect
//
// Looks for an existing CameraEffect object in the CameraEffects array first.
// Only if it doesn't find one, it takes one from the ObjectPool.
// That CameraEffect will be returned.
//=============================================================================

simulated function CameraEffect FindCameraEffect(class<CameraEffect> CameraEffectClass)
{
  local PlayerController PlayerControllerLocal;
  local CameraEffect CameraEffectFound;
  local int i;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None ) {
    for (i = 0; i < PlayerControllerLocal.CameraEffects.Length; i++)
      if ( PlayerControllerLocal.CameraEffects[i].Class == CameraEffectClass ) {
        CameraEffectFound = PlayerControllerLocal.CameraEffects[i];
        //log("Found"@CameraEffectFound@"in CammeraEffects array");
        break;
      }
    if ( CameraEffectFound == None ) {
      CameraEffectFound = CameraEffect(Level.ObjectPool.AllocateObject(CameraEffectClass));
      //log("Got"@CameraEffectFound@"from ObjectPool");
    }
    if ( CameraEffectFound != None )
      PlayerControllerLocal.AddCameraEffect(CameraEffectFound);
  }
  return CameraEffectFound;
}


//=============================================================================
// RemoveCameraEffect
//
// Removes one reference to the CameraEffect from the CameraEffects array. If
// there are any more references to the same CameraEffect object, they remain
// there. The CameraEffect will be put back in the ObjectPool if no other
// references to it are left in the CameraEffects array.
//=============================================================================

simulated function RemoveCameraEffect(CameraEffect CameraEffect)
{
  local PlayerController PlayerControllerLocal;
  local int i;
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None ) {
    PlayerControllerLocal.RemoveCameraEffect(CameraEffect);
    for (i = 0; i < PlayerControllerLocal.CameraEffects.Length; i++)
      if ( PlayerControllerLocal.CameraEffects[i] == CameraEffect ) {
        //log(CameraEffect@"still in CameraEffects array");
        return;
      }
    //log("Freeing"@CameraEffect);
    Level.ObjectPool.FreeObject(CameraEffect);
  }
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
  if ( JailbreakHUD != None ) {
    if ( HUDCanvasScale != 0 && JailbreakHUD.HUDCanvasScale != HUDCanvasScale ) {
      JailbreakHUD.HUDCanvasScale = HUDCanvasScale;
      JailbreakHUD.SaveConfig();
    }
    JailbreakHUD.UnregisterOverlay(Self);
  }
  
  if ( bCameraEffectsEnabled ) {
    if ( CameraOverlay != None )
      RemoveCameraEffect(CameraOverlay);
    if ( MotionBlur != None )
      RemoveCameraEffect(MotionBlur);
    MotionBlur = None;
    CameraOverlay = None;
  }
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
  
  if ( LocalLlamaTag != None && Pawn(PlayerControllerLocal.ViewTarget) != None
      && Pawn(PlayerControllerLocal.ViewTarget).Controller == PlayerControllerLocal
      && (MotionBlur == None && MotionBlurWanted() || CameraOverlay == None) ) {
    if ( MotionBlur == None && MotionBlurWanted() ) {
      MotionBlur = MotionBlur(FindCameraEffect(class'MotionBlur'));
      MotionBlur.Alpha = 1.0;
      MotionBlur.BlurAlpha = 128;
      MotionBlur.FinalEffect = False;
    }
    if ( CameraOverlay == None ) {
      CameraOverlay = CameraOverlay(FindCameraEffect(class'CameraOverlay'));
      CameraOverlay.OverlayMaterial = LlamaScreenOverlayMaterial;
      CameraOverlay.Alpha = 1.0;
      CameraOverlay.FinalEffect = False;
    }
    bCameraEffectsEnabled = True;
    if ( JailbreakHUD != None )
      HUDCanvasScale = JailbreakHUD.HUDCanvasScale;
  }
  else if ( bCameraEffectsEnabled && (LocalLlamaTag == None || Pawn(PlayerControllerLocal.ViewTarget) == None
      || Pawn(PlayerControllerLocal.ViewTarget).Controller != PlayerControllerLocal) ) {
    if ( CameraOverlay != None )
      RemoveCameraEffect(CameraOverlay);
    if ( MotionBlur != None )
      RemoveCameraEffect(MotionBlur);
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
// MotionBlurWanted
//
// Returns whether MotionBlur should be used.
//=============================================================================

simulated function bool MotionBlurWanted()
{
  if ( GameEngine == None )
    foreach AllObjects(class'GameEngine', GameEngine)
      break;
  
  if ( GameEngine != None && GameEngine.GRenDev != None && !GameEngine.GRenDev.IsA('D3DRenderDevice')
      && !GameEngine.GRenDev.IsA('D3D9RenderDevice') )
    return false;
  
  return true;
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
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassBG);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassIconBG);
    JailbreakHUD.DrawSpriteWidget(C, LlamaCompassIcon);
  }
  
  if ( JailbreakHUD.PawnOwner != None)
    LocationOwner = JailbreakHUD.PawnOwner.Location;
  else
    LocationOwner = JailbreakHUD.PlayerOwner.Location;
  
  C.DrawColor = JailbreakHUD.GoldColor;
  for (i = 0; i < LlamaArrows.Length; i++) {
    if ( LlamaArrows[i].LlamaTag != None && LlamaArrows[i].GetArrowOwner() != None ) {
      if ( !LlamaArrows[i].GetArrowOwner().bHidden )
        thisLlama = LlamaArrows[i].GetArrowOwner();
      else if ( LlamaArrows[i].GetArrowOwner().Controller != None )
        thisLlama = LlamaArrows[i].GetArrowOwner().Controller.Pawn;
      
      if ( thisLlama != None && C.Viewport.Actor.LineOfSightTo(thisLlama) )
        LlamaArrows[i].DrawArrow(C, thisLlama.Location + vect(0,0,1) * (2 * thisLlama.default.CollisionHeight - thisLlama.CollisionHeight + 40));
      else
        LlamaArrows[i].DrawArrow(C);
    }
    else
      LlamaArrows[i].DrawArrow(C);
    
    if ( LlamaArrows[i].LlamaTag != None && LlamaArrows[i].LlamaTag != LocalLlamaTag
        && LlamaArrows[i].LlamaTag.TagPlayer != None ) {
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
  LlamaCompassBG.PosX     = Default.LlamaCompassBG.PosX     + Smerp(LlamaCompassSlidePosition, LlamaCompassSlideDistance, 0.0);
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
    Outer=LlamaCompass
  End Object
  
  Begin Object Class=TexRotator Name=LlamaIconRotator
    TexRotationType=TR_OscillatingRotation
    UOffset=64.0
    VOffset=64.0
    OscillationRate=(Yaw=20000)
    OscillationAmplitude=(Yaw=8000)
    Material=TexOscillator'LlamaIconOscillator'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
    Outer=LlamaCompass
  End Object
  
  Begin Object Class=Combiner Name=LlamaIconCombiner
    AlphaOperation=AO_Multiply
    Material1=TexRotator'LlamaIconRotator'
    Material2=Texture'LlamaIconMask'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
    Outer=LlamaCompass
  End Object
  
  Begin Object Class=FinalBlend Name=LlamaIconFinalBlend
    FrameBufferBlending=FB_AlphaBlend
    Material=Combiner'LlamaIconCombiner'
    FallbackMaterial=TexOscillator'LlamaIconOscillator'
    Outer=LlamaCompass
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
    Outer=LlamaHudOverlay
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
    Outer=LlamaHudOverlay
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
    Outer=LlamaHudOverlay
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
    Outer=LlamaHudOverlay
  End Object
  
  Begin Object Class=Combiner Name=OverlayCombiner
    CombineOperation=AO_Multiply
    AlphaOperation=CO_Add
    Material1=TexOscillator'Overlay1Scaler'
    Material2=TexOscillator'Overlay2Scaler'
    Outer=LlamaHudOverlay
  End Object
  
  Begin Object Class=FinalBlend Name=LlamaScreenOverlayFinal
    FrameBufferBlending=FB_Translucent
    Material=Combiner'OverlayCombiner'
    FallbackMaterial=TexOscillator'Overlay2Scaler'
    Outer=LlamaHudOverlay
  End Object
  
  
  //===========================================================================
  // HUD elements
  //===========================================================================
  
  LlamaCompassIcon=(WidgetTexture=Texture'Llama',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=128),TextureScale=0.3,DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassIconBG=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.85,DrawPivot=DP_MiddleMiddle,PosX=0.93,PosY=0.7,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
  LlamaCompassBG=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=168,Y1=211,X2=334,Y2=255),TextureScale=0.6,DrawPivot=DP_MiddleLeft,PosX=0.93,PosY=0.7,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(R=0,G=0,B=0,A=150),Tints[1]=(R=0,G=0,B=0,A=150))
  LlamaCompassDot=(WidgetTexture=Texture'HUDContent.Generic.GlowCircle',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=64,Y2=64),TextureScale=0.15,DrawPivot=DP_MiddleMiddle,Tints[0]=(R=255,G=255,B=0,A=255),Tints[1]=(R=255,G=255,B=0,A=255))
  LlamaizedCompassIcon=FinalBlend'LlamaIconFinalBlend'
  LlamaScreenOverlayMaterial=FinalBlend'LlamaScreenOverlayFinal'
  LlamaCompassSlideDistance=0.12
  LlamaIconPulseRateR=1.5317
  LlamaIconPulseRateG=2.6873
  LlamaIconPulseRateB=1.0912
  bAlwaysTick=True
}