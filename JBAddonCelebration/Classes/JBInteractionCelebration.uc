//=============================================================================
// JBInteractionCelebration
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id$
//
// Handles drawing the celebration screen.
//=============================================================================


class JBInteractionCelebration extends Interaction
    dependson(JBGameRulesCelebration);


//=============================================================================
// Variables
//=============================================================================

var JBTauntingMeshActor PlayerMesh;
var string CaptureMessage;

var() vector MeshLoc;
var() JBGameRulesCelebration.TPlayerInfo PlayerInfo;


//=============================================================================
// PostRender
//
// Draws on the screen.
//=============================================================================

function PostRender(Canvas C)
{
  local int MessageSize;
  local float XL, YL;
  
  if ( !ViewportOwner.Actor.ViewTarget.IsA('JBCamera') )
    return;
  
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
    
    PlayerMesh.SetLocation(MeshLoc);
    C.DrawScreenActor(PlayerMesh, 30, False, True);
  }
  if ( CaptureMessage != "" ) {
    MessageSize = 3;
    do {
      MessageSize--;
      C.Font = ViewportOwner.Actor.myHUD.GetFontSizeIndex(C, MessageSize);
      C.TextSize(CaptureMessage, XL, YL);
    } until (XL < 0.7 * C.SizeX);
    C.DrawScreenText(CaptureMessage, 0.65, 0.95, DP_LowerMiddle);
  }
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
  
  PlayerInfo = NewPlayerInfo;
  
  if ( PlayerMesh == None && PlayerInfo.Player != None && (PlayerInfo.Player.GetPawn() != None
      || !PlayerInfo.bSuicide && PlayerInfo.bBot) )
    PlayerMesh = ViewportOwner.Actor.Spawn(class'JBTauntingMeshActor', PlayerInfo.Player.GetPawn(),,
        MeshLoc, rot(0,26000,0));
  else if ( PlayerMesh == None )
    return;
  else if ( PlayerInfo.Player != None )
    PlayerMesh.SetOwner(PlayerInfo.Player.GetPawn());
  
  if ( PlayerMesh.Owner != None ) {
    PlayerMesh.LinkMesh(PlayerMesh.Owner.Mesh);
    PlayerMesh.Skins = PlayerMesh.Owner.Skins;
  }
  else {
    PlayerMesh.bAnimByOwner = False;
    ActorMesh = Mesh(DynamicLoadObject(PlayerInfo.MeshName, class'Mesh'));
    if ( ActorMesh != None ) {
      PlayerMesh.LinkMesh(ActorMesh);
      ActorSkin = Material(DynamicLoadObject(PlayerInfo.BodySkinName$"_"$PlayerInfo.Team, class'Material'));
      if ( ActorSkin == None )
        ActorSkin = Material(DynamicLoadObject(PlayerInfo.BodySkinName, class'Material'));
      if ( ActorSkin != None )
        PlayerMesh.Skins[0] = ActorSkin;
      ActorSkin = Material(DynamicLoadObject(PlayerInfo.HeadSkinName, class'Material'));
      if ( ActorSkin != None )
        PlayerMesh.Skins[1] = ActorSkin;
    }
  }
  PlayerMesh.bAnimByOwner = !PlayerInfo.bBot || PlayerInfo.bSuicide;
  if ( !PlayerMesh.bAnimByOwner )
    PlayerMesh.GotoState('Taunting');
}


//=============================================================================
// Remove
//
// Removes the interaction.
//=============================================================================

function Remove()
{
  if ( PlayerMesh != None )
    PlayerMesh.Destroy();
  Master.RemoveInteraction(Self);
}


//=============================================================================
// Default properties
//=============================================================================

defaultproperties
{
  bVisible=True
  bActive=True
  MeshLoc=(X=450,Y=-70,Z=-35)
}