//=============================================================================
// JBLlamaTag
// Copyright 2003 by Wormbo <wormbo@onlinehome.de>
// $Id: JBLlamaTag.uc,v 1.9 2004/05/17 20:25:45 wormbo Exp $
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
var array<Sound>               LlamaSounds;
var bool                       bNotYetRegistered;
var bool                       bShiftedView;
var rotator                    ViewRotationOffset;


//=============================================================================
// PostBeginPlay
//
// Finds a JBGameRulesLlamaHunt actor which is responsible for preventing
// llamas from releasing team mates and from sending players killed by them to
// jail.
//=============================================================================

simulated event PostBeginPlay()
{
  Super.PostBeginPlay();
  
  LlamaStartTime = Level.TimeSeconds;
  if ( Role == ROLE_Authority )
    LlamaHuntRules = class'JBGameRulesLlamaHunt'.static.FindLlamaHuntRules(Self);
  HUDOverlay = class'JBInterfaceLlamaHUDOverlay'.static.FindLlamaHUDOverlay(Self);
  LlamaArrow = Spawn(class'JBLlamaArrow', Self);
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
  
  if ( Level.NetMode != NM_DedicatedServer )
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
  
  if ( Pawn(Owner) != None ) {
    TagPlayer = class'JBTagPlayer'.static.FindFor(Pawn(Owner).PlayerReplicationInfo);
    bNotYetRegistered = False;
  }
  else {
    warn("Owner ="@Owner);
    bNotYetRegistered = True;
    return;
  }
  
  // make sure that the local player owns the llama tag
  if ( Pawn(Owner) != None && PlayerControllerLocal == Pawn(Owner).Controller ) {
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
  
  for (i = 0; i < LocalHUD.Crosshairs.Length; i++) {
    LocalHUD.Crosshairs[i].PosX = 0.5;
    LocalHUD.Crosshairs[i].PosY = 0.5;
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
  
  if ( bNotYetRegistered && Owner != None )
    InitLlamaTag();
  
  if ( PlayerController(Pawn(Owner).Controller) != None
      && !PlayerController(Pawn(Owner).Controller).bBehindView
      && (PlayerController(Pawn(Owner).Controller).ViewTarget == None
          || PlayerController(Pawn(Owner).Controller).ViewTarget == Self
          || PlayerController(Pawn(Owner).Controller).ViewTarget == Owner) ) {
    PlayerController(Pawn(Owner).Controller).SetRotation(PlayerController(Pawn(Owner).Controller).Rotation - ViewRotationOffset);
    ViewRotationOffset.Pitch = 1536 * Sin(1.2 * Pi * (Level.TimeSeconds - LlamaStartTime));
    ViewRotationOffset.Yaw   = 1536 * Sin(0.9 * Pi * (Level.TimeSeconds - LlamaStartTime));
    ViewRotationOffset.Roll  = 1536 * Sin(1.1 * Pi * (Level.TimeSeconds - LlamaStartTime));
    PlayerController(Pawn(Owner).Controller).SetRotation(PlayerController(Pawn(Owner).Controller).Rotation + ViewRotationOffset);
    bShiftedView = True;
  }
  else if ( bShiftedView ) {
    if ( Pawn(Owner).Controller != None )
      Pawn(Owner).Controller.SetRotation(Pawn(Owner).Controller.Rotation - ViewRotationOffset);
    bShiftedView = False;
  }
  
  //Pawn(Owner).SetHeadScale(2.0 + 1.0 * Cos(2.0 * Level.TimeSeconds));
  Pawn(Owner).SetHeadScale(0.01);
  
  if ( LocalHUD != None ) {
    CurrentCrosshair = Clamp(LocalHUD.CrosshairStyle, 0, LocalHUD.Crosshairs.Length - 1);
    LocalHUD.Crosshairs[CurrentCrosshair].PosX
        = 0.5 + 0.05 * Sin(Level.TimeSeconds * 3.0);
    LocalHUD.Crosshairs[CurrentCrosshair].PosY
        = 0.5 + 0.05 * Cos(Level.TimeSeconds * 4.0);
  }
  
  if ( Pawn(Owner).Controller != None && Pawn(Owner).Controller.Pawn != None
      && Trail != None && Trail.Owner != Pawn(Owner).Controller.Pawn )
    Trail.SetOwner(Pawn(Owner).Controller.Pawn);
  
  if ( Role == ROLE_Authority
      && Level.TimeSeconds - LlamaStartTime > class'JBAddonLlama'.default.MaximumLlamaDuration ) {
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