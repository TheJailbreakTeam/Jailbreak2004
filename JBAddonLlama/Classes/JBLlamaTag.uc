//=============================================================================
// JBLlamaTag
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaTag.uc,v 1.7.2.4 2004/05/31 19:55:00 wormbo Exp $
//
// The JBLlamaTag is added to a llama's inventory to identify him or her as the
// llama and to handle llama effects.
//=============================================================================


class JBLlamaTag extends Inventory;


//=============================================================================
// Imports
//=============================================================================

#exec audio import file=Sounds\alarm.wav
#exec audio import file=Sounds\falarm.wav
#exec audio import file=Sounds\cluck.wav
#exec audio import file=Sounds\clucksnort.wav
#exec audio import file=Sounds\hummun.wav
#exec audio import file=Sounds\humw.wav
#exec audio import file=Sounds\mom.wav
#exec audio import file=Sounds\snort.wav


//=============================================================================
// Variables
//=============================================================================

var JBGameRulesLlamaHunt       LlamaHuntRules;  // JBGameRules class for Jailbreak notifications
var JBInterfaceLlamaHUDOverlay HUDOverlay;      // HUD overlay for drawing llama compass and arrows
var JBLlamaTrailer             Trail;           // 3rd person xEmitter effect for the llama
var JBLlamaArrow               LlamaArrow;      // client-side spinning arrow over the llama's head
var JBTagPlayer                TagPlayer;       // the llama's JBTagPlayer
var float                      LlamaStartTime;  // Level.TimeSeconds when this player was llamaized
var JBInterfaceHUD             LocalHUD;        // the Llama's HUD
var JBInterfaceScores          LocalScoreboard; // the local scoreboard
var array<Sound>               LlamaSounds;
var bool                       bNotYetRegistered;
var bool                       bShiftedView;
var rotator                    ViewRotationOffset;


//=============================================================================
// Replication
//=============================================================================

replication
{
  reliable if ( Role == ROLE_Authority )
    TagPlayer;
}


//=============================================================================
// PostBeginPlay
//
// Finds a JBGameRulesLlamaHunt actor which is responsible for preventing
// llamas from releasing team mates and from sending players killed by them to
// jail.
//=============================================================================

simulated event PostBeginPlay()
{
  local PlayerController PlayerControllerLocal;
  
  Super.PostBeginPlay();
  
  LlamaStartTime = Level.TimeSeconds;
  if ( Role == ROLE_Authority )
    LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
  HUDOverlay = class'JBInterfaceLlamaHUDOverlay'.static.FindLlamaHUDOverlay(Self);
  LlamaArrow = Spawn(class'JBLlamaArrow', Self,,,rot(0,0,0));
  
  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None && PlayerControllerLocal.MyHud != None )
    LocalScoreboard = JBInterfaceScores(PlayerControllerLocal.MyHud.ScoreBoard);
}


//=============================================================================
// PostNetBeginPlay
//
// Registers the JBLlamaTag clientside as an overlay.
//=============================================================================

simulated event PostNetBeginPlay()
{
  Super.PostNetBeginPlay();
  
  if ( Role < ROLE_Authority )
    InitLlamaTag();
}


//=============================================================================
// GiveTo
//
// Registers the JBLlamaTag as an overlay offline and on listen servers.
// Notifies other players of a new llama hunt.
//=============================================================================

function GiveTo(Pawn Other, optional Pickup Pickup)
{
  Super.GiveTo(Other, Pickup);
  
  Trail = Spawn(class'JBLlamaTrailer', Owner);
  
  //log("Tagged"@Owner@"as llama.", Name);
  
  InitLlamaTag();
  
  Timer();
  BroadcastLocalizedMessage(class'JBLlamaMessage', 1, Other.PlayerReplicationInfo);
}


//=============================================================================
// InitLlamaTag
//
// Registers the JBLlamaTag as an overlay and add the llama effects.
//=============================================================================

simulated function InitLlamaTag()
{
  local PlayerController PlayerControllerLocal;
  
  //log("InitLlamaTag()", Name);
  
  // find local playercontroller
  PlayerControllerLocal = Level.GetLocalPlayerController();
  
  if ( TagPlayer == None && Pawn(Owner) != None ) {
    TagPlayer = class'JBTagPlayer'.static.FindFor(Pawn(Owner).PlayerReplicationInfo);
  }
  if ( TagPlayer == None ) {
    //warn("Owner ="@Owner);
    bNotYetRegistered = True;
    return;
  }
  else
    bNotYetRegistered = False;
  
  // make sure that the local player owns the llama tag
  if ( TagPlayer != None && PlayerControllerLocal == TagPlayer.GetController() ) {
    HUDOverlay.SetLocalLlamaTag(Self);
    LocalHUD = JBInterfaceHUD(PlayerControllerLocal.myHUD);
  }
  
  // attach the llama head
  AttachToPawn(Pawn(Owner));
}


//=============================================================================
// AttachToPawn
//
// Hides the player's head and attaches a llama head instead.
//=============================================================================

function AttachToPawn(Pawn P)
{
  if ( ThirdPersonActor == None ) {
    ThirdPersonActor = Spawn(AttachmentClass,Owner);
    InventoryAttachment(ThirdPersonActor).InitFor(self);
  }
  P.AttachToBone(ThirdPersonActor, Pawn(Owner).HeadBone);
  
  ThirdPersonActor.SetRelativeRotation(rot(16384,16384,-18000));
}


//=============================================================================
// DetachFromPawn
//
// Detaches the llama head and restores the original head.
//=============================================================================

function DetachFromPawn(Pawn P)
{
  Super.DetachFromPawn(P);
  Pawn(Owner).SetHeadScale(P.default.HeadScale);
}


//=============================================================================
// Destroyed
//
// Unregister the JBLlamaTag and remove the llama effects.
//=============================================================================

simulated event Destroyed()
{
  if ( LocalHUD != None )
    ResetCrosshairLocations();
  
  if ( LocalScoreboard != None && TagPlayer != None )
    LocalScoreboard.ResetEntryColor(TagPlayer);
  
  if ( Trail != None ) {
    Trail.Destroy();
  }
  
  if ( LlamaArrow != None ) {
    LlamaArrow.LlamaDied();
  }
  
  DetachFromPawn(Pawn(Owner));
  
  Super.Destroyed();
}


//=============================================================================
// ResetCrosshairLocations
//
// Reset all crosshair SpriteWidgets of the current HUD.
//=============================================================================

simulated function ResetCrosshairLocations()
{
  local int i;
  
  for (i = 0; i < LocalHUD.default.Crosshairs.Length; i++) {
    LocalHUD.Crosshairs[i].PosX = LocalHUD.default.Crosshairs[i].PosX;
    LocalHUD.Crosshairs[i].PosY = LocalHUD.default.Crosshairs[i].PosY;
  }
}


//=============================================================================
// Tick
//
// Update third person llama effects and checks whether the maximum llama hunt
// duration was exceeded.
//=============================================================================

simulated function Tick(float DeltaTime)
{
  local int CurrentCrosshair;
  local PlayerController MyController;
  
  if ( LocalScoreboard != None && TagPlayer != None )
    LocalScoreboard.OverrideEntryColor(TagPlayer,
        class'JBInterfaceLlamaHUDOverlay'.static.HueToRGB(int(Level.TimeSeconds * 150.0) % 256));
  
  if ( bNotYetRegistered && Owner != None )
    InitLlamaTag();
  if ( bNotYetRegistered || Owner == None )
    return;
  
  if ( Pawn(Owner) != None )
    MyController = PlayerController(Pawn(Owner).Controller);
  if ( MyController == None && TagPlayer != None )
    MyController = PlayerController(TagPlayer.GetController());
  
  if ( MyController != None && (MyController.ViewTarget == MyController
      || MyController.ViewTarget == Self || MyController.ViewTarget == Owner
      || Vehicle(MyController.Pawn) != None && MyController.ViewTarget == MyController.Pawn) ) {
    MyController.SetRotation(MyController.Rotation - ViewRotationOffset);
    ViewRotationOffset.Pitch = 1536 * Sin(1.2 * Pi * (Level.TimeSeconds - LlamaStartTime));
    ViewRotationOffset.Yaw   = 1536 * Sin(0.9 * Pi * (Level.TimeSeconds - LlamaStartTime));
    ViewRotationOffset.Roll  = 1536 * Sin(1.1 * Pi * (Level.TimeSeconds - LlamaStartTime));
    MyController.SetRotation(MyController.Rotation + ViewRotationOffset);
    bShiftedView = True;
  }
  else if ( bShiftedView ) {
    if ( MyController != None )
      Pawn(Owner).Controller.SetRotation(MyController.Rotation - ViewRotationOffset);
    bShiftedView = False;
  }
  
  Pawn(Owner).SetHeadScale(0.01);
  
  if ( LocalHUD != None ) {
    CurrentCrosshair = Clamp(LocalHUD.CrosshairStyle, 0, LocalHUD.Crosshairs.Length - 1);
    LocalHUD.Crosshairs[CurrentCrosshair].PosX
        = 0.5 + 0.05 * Sin(Level.TimeSeconds * 3.0);
    LocalHUD.Crosshairs[CurrentCrosshair].PosY
        = 0.5 + 0.05 * Cos(Level.TimeSeconds * 4.0);
  }
  
  if ( MyController != None && MyController.Pawn != None
      && Trail != None && Trail.Owner != MyController.Pawn )
    Trail.SetOwner(MyController.Pawn);
  
  if ( Role == ROLE_Authority
      && Level.TimeSeconds - LlamaStartTime > class'JBAddonLlama'.default.MaximumLlamaDuration ) {
    if ( MyController != None )
      Spawn(class'JBLlamaKillAutoSelect', MyController);
    else
      Pawn(Owner).Died(None, class'JBDamageTypeLlamaDied', Owner.Location);
  }
}


//=============================================================================
// Timer
//
// Plays a random llama sound and sets up the timer for playing the next sound.
//=============================================================================

function Timer()
{
  local int RandSound;
  
  RandSound = Rand(LlamaSounds.Length);
  Trail.PlaySound(LlamaSounds[RandSound],, 255,, 1000, RandRange(0.9, 1.1));
  SetTimer((GetSoundDuration(LlamaSounds[RandSound]) + FRand() + 1.0) * 2.0 * Level.TimeDilation, False);
}


//=============================================================================
// default properties
//=============================================================================

defaultproperties
{
  bGameRelevant=True
  bAlwaysRelevant=True
  bOnlyRelevantToOwner=False
  AttachmentClass=class'JBLlamaHeadAttachment'
  LlamaSounds=(Sound'Alarm',Sound'FAlarm',Sound'Cluck',Sound'CluckSnort',Sound'hummun',Sound'humw',Sound'mom',Sound'Snort')
}