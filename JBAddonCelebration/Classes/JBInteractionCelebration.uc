//=============================================================================
// JBInteractionCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBInteractionCelebration.uc,v 1.6 2004/04/26 16:06:54 wormbo Exp $
//
// Handles drawing the celebration screen.
//=============================================================================


class JBInteractionCelebration extends Interaction
    dependson(JBGameRulesCelebration);


//=============================================================================
// Variables
//=============================================================================

var JBGameRulesCelebration CelebrationGameRules;

var string CaptureMessage;              // the capture message displayed during the execution
var color MessageColor;                 // color to display the CaptureMessage in

var string SavedCameraMessage;          // the message the execution camera would display
var JBCamera ExecutionCamera;           // the camera the execution is viewed through

var vector MeshLoc, ShadowLoc;
var Material MeshShadowMaterial;        // the material used to display the player shadow
var JBTauntingMeshActor PlayerMesh;     // the displayed player mesh
var JBGameRulesCelebration.TPlayerInfo PlayerInfo;
var name TauntAnim;                     // used to convert a string to a name to the taunt animation


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
      && ViewportOwner.Actor.MyHud.bShowScoreBoard )
    return;
  
  if ( ExecutionCamera == None )
    ExecutionCamera = JBCamera(ViewportOwner.Actor.ViewTarget);
  if ( ExecutionCamera.Caption.Text != "" ) {
    SavedCameraMessage = ExecutionCamera.Caption.Text;
    ExecutionCamera.Caption.Text = "";
  }
  
  if ( JBInterfaceHud(ViewportOwner.Actor.myHUD) != None )
    JBInterfaceHud(ViewportOwner.Actor.myHUD).bWidescreen = True;
  
  if ( PlayerMesh == None ) {
    if ( PlayerInfo.Player != None )
      SetupPlayerMesh(PlayerInfo);
  }
  if ( PlayerMesh != None ) {
    if ( PlayerMesh.IsInState('Taunting') && !PlayerMesh.bStartedTaunting ) {
      PlayerMesh.bStartedTaunting = true;
      PlayerMesh.GotoState('Taunting', 'BeginTaunting');
    }
    
    PlayerMesh.OverlayMaterial = MeshShadowMaterial;
    PlayerMesh.SetLocation(ShadowLoc);
    C.DrawScreenActor(PlayerMesh, 30, False, True);
    
    PlayerMesh.OverlayMaterial = None;
    PlayerMesh.SetLocation(MeshLoc);
    C.DrawScreenActor(PlayerMesh, 30, False, True);
    
    // redraw the console messages since otherwise they would be hidden behind the player mesh
    ViewportOwner.Actor.myHUD.DisplayMessages(C);
    if ( Console(Master.Console).bTyping )
      ViewportOwner.Actor.myHUD.DrawTypingPrompt(C, Console(Master.Console).TypedStr);
  }
  if ( CaptureMessage != "" ) {
    MessageSize = 3;
    do {
      MessageSize--;
      C.Font = ViewportOwner.Actor.myHUD.GetFontSizeIndex(C, MessageSize);
      C.TextSize(CaptureMessage, XL, YL);
    } until (XL < 0.7 * C.SizeX);
    C.DrawColor = MessageColor;
    C.DrawScreenText(CaptureMessage, 1 - 0.5 * YL / C.ClipY, 1 - 0.5 * YL / C.ClipY, DP_LowerRight);
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
        else if ( Trim(Binds[i]) ~= "RandomTaunt" ) {
          RandomTaunt();
          break;
        }
        else if ( Trim(Binds[i]) ~= "MoveForward" ) {
          Taunt("PThrust");
          break;
        }
        else if ( Trim(Binds[i]) ~= "MoveBackward" ) {
          Taunt("AssSmack");
          break;
        }
        else if ( Trim(Binds[i]) ~= "StrafeLeft" ) {
          Taunt("ThroatCut");
          break;
        }
        else if ( Trim(Binds[i]) ~= "StrafeRight" ) {
          Taunt("Specific_1");
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
  if ( PlayerInfo.Player != None && PlayerInfo.Player.GetController() == ViewportOwner.Actor
      && PlayerMesh.HasAnim(TauntAnim) )
    CelebrationGameRules.ServerSetTauntAnim(AnimName);
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
    PlayerMesh.bAnimByOwner = False;
    rec = class'xUtil'.static.FindPlayerRecord(PlayerInfo.PRI.CharacterName);
    if ( rec.DefaultName == "" )
      rec = class'xUtil'.static.FindPlayerRecord("Gorge");
    ActorMesh = Mesh(DynamicLoadObject(rec.MeshName, class'Mesh'));
    if ( ActorMesh != None ) {
      PlayerMesh.LinkMesh(ActorMesh);
      ActorSkin = Material(DynamicLoadObject(rec.BodySkinName$"_"$PlayerInfo.PRI.Team.TeamIndex, class'Material'));
      if ( ActorSkin == None )
        ActorSkin = Material(DynamicLoadObject(rec.BodySkinName, class'Material'));
      if ( ActorSkin != None )
        PlayerMesh.Skins[0] = ActorSkin;
      ActorSkin = Material(DynamicLoadObject(rec.FaceSkinName, class'Material'));
      if ( ActorSkin != None )
        PlayerMesh.Skins[1] = ActorSkin;
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
// Remove
//
// Restores the execution camera's caption text, cleans up actor references and
// removes the interaction.
//=============================================================================

function Remove()
{
  if ( ExecutionCamera != None && SavedCameraMessage != "" )
    ExecutionCamera.Caption.Text = SavedCameraMessage;
  
  ExecutionCamera = None;
  SavedCameraMessage = "";
  
  if ( PlayerMesh != None )
    PlayerMesh.Destroy();
  
  PlayerMesh = None;
  CelebrationGameRules = None;
  
  Master.RemoveInteraction(Self);
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