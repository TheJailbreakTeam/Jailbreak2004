//=============================================================================
// JBInteractionCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBInteractionCelebration.uc,v 1.15 2004/06/02 09:48:25 wormbo Exp $
//
// Handles drawing the celebration screen.
//=============================================================================


class JBInteractionCelebration extends Interaction
    dependson(JBGameRulesCelebration);


//=============================================================================
// Variables
//=============================================================================

var JBGameRulesCelebration CelebrationGameRules;

var   string CaptureMessage;            // the capture message displayed during the execution
var() color MessageColor;               // color to display the CaptureMessage in

var string SavedCameraMessage;          // the message the execution camera would display
var JBCamera ExecutionCamera;           // the camera the execution is viewed through

var() vector MeshLoc, ShadowLoc;
var() Material MeshShadowMaterial;      // the material used to display the player shadow
var   JBTauntingMeshActor PlayerMesh;   // the displayed player mesh
var   JBGameRulesCelebration.TPlayerInfo PlayerInfo;
var   name TauntAnim;                   // used to convert a string to a name to the taunt animation

// TODO: remove debugging code before release
var() editconst int DebugCounter;


//=============================================================================
// PostRender
//
// Draws on the screen.
//=============================================================================

function PostRender(Canvas C)
{
  local int MessageSize;
  local float XL, YL;
  
  if ( !ViewportOwner.Actor.ViewTarget.IsA('JBCamera') || ViewportOwner.Actor.MyHud != None
      && ViewportOwner.Actor.MyHud.bShowScoreBoard ) {
    if ( !ViewportOwner.Actor.ViewTarget.IsA('JBCamera') )
      JBInterfaceHud(ViewportOwner.Actor.myHUD).bChatMovedToTop = False;
    return;
  }
  if ( ExecutionCamera == None )
    ExecutionCamera = JBCamera(ViewportOwner.Actor.ViewTarget);
  if ( ExecutionCamera.Caption.Text != "" ) {
    SavedCameraMessage = ExecutionCamera.Caption.Text;
    ExecutionCamera.Caption.Text = "";
  }
  
  if ( JBInterfaceHud(ViewportOwner.Actor.myHUD) != None ) {
    if ( ExecutionCamera == None || ExecutionCamera.Overlay.Material == None || ExecutionCamera.bWidescreen )
      JBInterfaceHud(ViewportOwner.Actor.myHUD).bWidescreen = True;
    else
      JBInterfaceHud(ViewportOwner.Actor.myHUD).bWidescreen = False;
    JBInterfaceHud(ViewportOwner.Actor.myHUD).bChatMovedToTop = True;
  }
  
  if ( PlayerMesh == None ) {
    if ( PlayerInfo.Player != None )
      SetupPlayerMesh(PlayerInfo);
  }
  if ( PlayerMesh != None ) {
    if ( PlayerMesh.IsInState('Taunting') && !PlayerMesh.bStartedTaunting ) {
      PlayerMesh.bStartedTaunting = true;
      PlayerMesh.GotoState('Taunting', 'BeginTaunting');
    }
    PlayerMesh.PrePivot += PlayerMesh.LastLocationOffset;
    
    PlayerMesh.OverlayMaterial = MeshShadowMaterial;
    PlayerMesh.SetLocation(ShadowLoc);
    C.DrawScreenActor(PlayerMesh, 30, False, True);
    
    PlayerMesh.OverlayMaterial = None;
    PlayerMesh.SetLocation(MeshLoc);
    C.DrawScreenActor(PlayerMesh, 30, False, True);
  }
  if ( CaptureMessage != "" ) {
    MessageSize = 2;
    do {
      MessageSize--;
      C.Font = ViewportOwner.Actor.myHUD.GetFontSizeIndex(C, MessageSize);
      C.TextSize(CaptureMessage, XL, YL);
    } until (XL < C.SizeX * (1 - 0.5 * YL / C.ClipY) || MessageSize < -6);
    C.DrawColor = MessageColor;
    if ( XL > C.SizeX * (1 - 0.5 * YL / C.ClipY) )
      C.FontScaleX = C.SizeX / XL;
    C.DrawScreenText(CaptureMessage, 1 - 0.5 * YL / C.ClipY, 1 - 0.5 * YL / C.ClipY, DP_LowerRight);
    C.FontScaleX = 1.0;
  }
}


//=============================================================================
// KeyEvent
//
// Catch taunt keys.
//=============================================================================

function bool KeyEvent(EInputKey Key, EInputAction Action, float Delta)
{
  local string KeyBind;
  local array<string> Binds;
  local string TauntName;
  local int i;
  
  if ( Action == IST_Press ) {
    KeyBind = ViewportOwner.Actor.ConsoleCommand("KEYNAME" @ Key);
    KeyBind = ViewportOwner.Actor.ConsoleCommand("KEYBINDING" @ KeyBind);
    
    if ( KeyBind != "" && Split(KeyBind, "|", Binds) > 0 ) {
      for (i = 0; i < Binds.Length; i++) {
        if ( Divide(Trim(Binds[i]), " ", KeyBind, TauntName) && Keybind ~= "Taunt" && TauntName != "" ) {
          Taunt(TauntName);
          break;
        }
        else if ( Trim(Binds[i]) ~= "RandomTaunt" || Trim(Binds[i]) ~= "Fire" || Trim(Binds[i]) ~= "AltFire" ) {
          RandomTaunt();
          break;
        }
        else if ( Trim(Binds[i]) ~= "MoveForward" || Trim(Binds[i]) ~= "LookUp" ) {
          Taunt("PThrust");
          break;
        }
        else if ( Trim(Binds[i]) ~= "MoveBackward" || Trim(Binds[i]) ~= "LookDown" ) {
          Taunt("AssSmack");
          break;
        }
        else if ( Trim(Binds[i]) ~= "StrafeLeft" || Trim(Binds[i]) ~= "TurnLeft" ) {
          Taunt("ThroatCut");
          break;
        }
        else if ( Trim(Binds[i]) ~= "StrafeRight" || Trim(Binds[i]) ~= "TurnRight" ) {
          Taunt("Specific_1");
          break;
        }
        else if ( Trim(Binds[i]) ~= "Jump" ) {
          Taunt("Gesture_Taunt01");
          break;
        }
        else if ( Trim(Binds[i]) ~= "Duck" ) {
          Taunt("Idle_Character01");
          break;
        }
      }
    }
  }
  return Super.KeyEvent(Key, Action, Delta);
}


//=============================================================================
// Trim
//
// Trims leading and trailing space chars.
//=============================================================================

static final function string Trim(coerce string S)
{
  while (Left(S, 1) == " ")
    S = Right(S, Len(S) - 1);
  while (Right(S, 1) == " ")
    S = Left(S, Len(S) - 1);
  return S;
}


//=============================================================================
// Taunt
//
// Plays the specified taunt animation.
//=============================================================================

function Taunt(string AnimName)
{
  if ( CelebrationGameRules == None || PlayerMesh == None )
    return;
  
  SetPropertyText("TauntAnim", AnimName); // hacky string to name "typecasting"
  if ( PlayerInfo.Player != None && PlayerInfo.Player.GetController() == ViewportOwner.Actor ) {
    if ( PlayerMesh.HasAnim(TauntAnim) )
      CelebrationGameRules.ServerSetTauntAnim(AnimName);
    else {
      TauntAnim = FixAnimName(AnimName);
      if ( PlayerMesh.HasAnim(TauntAnim) )
        CelebrationGameRules.ServerSetTauntAnim(AnimName);
    }
  }
}


//=============================================================================
// FixAnimName
//
// Fix animation name for skaarj model.
//=============================================================================

function name FixAnimName(string AnimName)
{
  switch (Locs(AnimName)) {
    case "pthrust":
      return 'Gesture_Taunt02';
    case "asssmack":
      return 'Gesture_Taunt03';
    case "throatcut":
      return 'Idle_Character03';
    default:
      return 'Gesture_Taunt01';
  }
}


//=============================================================================
// RandomTaunt
//
// Plays a random taunt animation.
//=============================================================================

function RandomTaunt()
{
  if ( CelebrationGameRules == None || PlayerMesh == None )
    return;
  
  TauntAnim = PlayerMesh.GetRandomTauntAnim();
  if ( PlayerInfo.Player != None && PlayerInfo.Player.GetController() == ViewportOwner.Actor && TauntAnim != '' )
    CelebrationGameRules.ServerSetTauntAnim(string(TauntAnim));
}


//=============================================================================
// SetupPlayerMesh
//
// Sets up the player mesh.
//=============================================================================

function SetupPlayerMesh(JBGameRulesCelebration.TPlayerInfo NewPlayerInfo)
{
  local Material ActorSkin;
  local Mesh ActorMesh;
  local xUtil.PlayerRecord rec;
  
  PlayerInfo = NewPlayerInfo;
  
  if ( PlayerMesh == None && PlayerInfo.Player != None && (PlayerInfo.Player.GetPawn() != None
      || !PlayerInfo.bSuicide) )
    PlayerMesh = ViewportOwner.Actor.Spawn(class'JBTauntingMeshActor', PlayerInfo.Player.GetPawn(),,
        MeshLoc, rot(0,26000,0));
  else if ( PlayerMesh == None )
    return;
  else if ( PlayerInfo.Player != None )
    PlayerMesh.SetOwner(PlayerInfo.Player.GetPawn());
  
  if ( PlayerMesh.Owner != None ) {
    PlayerMesh.LinkMesh(PlayerMesh.Owner.Mesh);
    PlayerMesh.Skins = PlayerMesh.Owner.Skins;
    PlayerMesh.bAnimByOwner = True;
  }
  else {
    if ( PlayerInfo.bSuicide ) {
      PlayerMesh.Destroy();
      PlayerMesh = None;
      return;
    }
    PlayerMesh.bAnimByOwner = False;
    rec = class'xUtil'.static.FindPlayerRecord(PlayerInfo.PRI.CharacterName);
    if ( rec.DefaultName == "" )
      rec = class'xUtil'.static.FindPlayerRecord("Gorge");
    ActorMesh = Mesh(DynamicLoadObject(rec.MeshName, class'Mesh'));
    if ( ActorMesh != None ) {
      PlayerMesh.LinkMesh(ActorMesh);
      
      // load body skin
      if (class'DMMutator'.Default.bBrightSkins && Left(rec.BodySkinName,12) ~= "PlayerSkins.")
        ActorSkin = Material(DynamicLoadObject("Bright"$rec.BodySkinName$"_"$PlayerInfo.PRI.Team.TeamIndex$"B", class'Material', True));
      if (ActorSkin == None)
        ActorSkin = Material(DynamicLoadObject(rec.BodySkinName$"_"$PlayerInfo.PRI.Team.TeamIndex, class'Material', True));
      if (ActorSkin == None)
        ActorSkin = Material(DynamicLoadObject(rec.BodySkinName, class'Material'));
      if (ActorSkin != None)
        PlayerMesh.Skins[0] = ActorSkin;
      
      // load face skin
      if (rec.TeamFace)
        ActorSkin = Material(DynamicLoadObject(rec.FaceSkinName$"_"$PlayerInfo.PRI.Team.TeamIndex, class'Material', True));
      if (!rec.TeamFace || ActorSkin == None)
        ActorSkin = Material(DynamicLoadObject(rec.FaceSkinName, class'Material'));
      if (ActorSkin != None)
        PlayerMesh.Skins[1] = ActorSkin;
      
      // Xan hack
      if (rec.BodySkinName ~= "UT2004PlayerSkins.XanMk3V2_Body")
        PlayerMesh.Skins[2] = Material(DynamicLoadObject("UT2004PlayerSkins.XanMk3V2_abdomen", class'Material'));
    }
  }
  
  if ( !PlayerMesh.bAnimByOwner ) {
    if ( PlayerInfo.bBot )
      PlayerMesh.GotoState('Taunting', 'BeginTaunting');
    else {
      PlayerMesh.bStartedTaunting = true;
      PlayerMesh.GotoState('Taunting', 'ManualTaunting');
    }
  }
}


//=============================================================================
// Initialized
//
// Debug logging to help tracking down the arana cam display bug and the
// problem with multiple player meshes and/or capture messages.
//=============================================================================

function Initialized()
{
  default.DebugCounter++;
  log("Initialized"@Name@DebugCounter, 'JBDebug');
}


//=============================================================================
// Remove
//
// Restores the execution camera's caption text, cleans up actor references and
// removes the interaction.
//=============================================================================

function Remove()
{
  log("Removing"@Name@DebugCounter, 'JBDebug');
  
  if ( ExecutionCamera != None && SavedCameraMessage != "" )
    ExecutionCamera.Caption.Text = SavedCameraMessage;
  
  ExecutionCamera = None;
  SavedCameraMessage = "";
  
  if ( PlayerMesh != None )
    PlayerMesh.Destroy();
  
  PlayerMesh = None;
  if ( CelebrationGameRules != None && CelebrationGameRules.CelebrationInteraction == Self )
    CelebrationGameRules.CelebrationInteraction = None;
  else if ( CelebrationGameRules != None )
    warn(CelebrationGameRules@"has another CelebrationInteraction!");
  CelebrationGameRules = None;
  
  if ( JBInterfaceHud(ViewportOwner.Actor.myHUD) != None )
    JBInterfaceHud(ViewportOwner.Actor.myHUD).bChatMovedToTop = False;
  Master.RemoveInteraction(Self);
}


//=============================================================================
// NotifyLevelChange
//
// Removes the interaction on mapchange or disconnect.
//=============================================================================

function NotifyLevelChange()
{
  Remove();
  Super.NotifyLevelChange();
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bVisible=True
  bActive=True
  MeshLoc=(X=450,Y=-75,Z=-41)
  ShadowLoc=(X=450,Y=-78,Z=-43)
  MessageColor=(R=255,G=255,B=255,A=255)
  
  Begin Object Class=ConstantColor Name=MeshShadowColor
    Color=(R=0,G=0,B=0,A=64)
  End Object
  
  Begin Object Class=FinalBlend Name=MeshShadowFinal
    Material=MeshShadowColor
    FrameBufferBlending=FB_AlphaBlend
  End Object
  MeshShadowMaterial=MeshShadowFinal
}