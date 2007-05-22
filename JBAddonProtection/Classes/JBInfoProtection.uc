// ============================================================================
// JBInfoProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBInfoProtection.uc,v 1.10 2004-08-09 20:51:42 mychaeel Exp $
//
// Protection of protection add-on.
// ============================================================================


class JBInfoProtection extends Info;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    ProtectedPawn, RelatedPRI, ProtectionTime;
}


// ============================================================================
// Variables
// ============================================================================

var JBxEmitterProtectionRed ProtectionEffect;
var PlayerReplicationInfo RelatedPRI;
var private Pawn ProtectedPawn;
var private int   ProtectionTime;    // protection time read from config
var private float EndProtectionTime; // level time at which protection ends
var private float ProtectionCharge;
var private int   ProtectedPawnAbsorbedDamage; // keeps score of how much
  // damage protection has absorbed, to decide whether to make attacker llama

var private JBInterfaceHud LocalHUD;
var private HUDBase.SpriteWidget  ProtectionIcon;
var private HUDBase.NumericWidget ProtectionDigits;


// ============================================================================
// PostBeginPlay
//
// Initializes replicated variables and spawns the visual effect. Assigns
// itself to a vehicle's driver if the pawn is a vehicle. Prevent creation if
// the player is a llama.
// ============================================================================

event PostBeginPlay()
{
    local Inventory I;

    ProtectedPawn = Pawn(Owner);
    RelatedPRI = ProtectedPawn.PlayerReplicationInfo;

    if (Vehicle(ProtectedPawn) != None && Vehicle(ProtectedPawn).Driver != None)
        ProtectedPawn = Vehicle(ProtectedPawn).Driver;

    for (I = ProtectedPawn.Inventory; I != None; I = I.Inventory)
        if (I.IsA('JBLlamaTag')) {
            Destroy();
            return;
        }

    if(RelatedPRI.Team.TeamIndex == 0)
             ProtectionEffect = Spawn(Class'JBxEmitterProtectionRed',  ProtectedPawn, , ProtectedPawn.Location, ProtectedPawn.Rotation);
        else ProtectionEffect = Spawn(Class'JBxEmitterProtectionBlue', ProtectedPawn, , ProtectedPawn.Location, ProtectedPawn.Rotation);
}


// ============================================================================
// PostNetBeginPlay
//
// Registers the HUD overlay client-side.
// ============================================================================

simulated event PostNetBeginPlay()
{
    local PlayerController PlayerControllerLocal;

    PlayerControllerLocal = Level.GetLocalPlayerController();
    if (PlayerControllerLocal != None &&
        (PlayerControllerLocal.Pawn == ProtectedPawn ||
        (Vehicle(PlayerControllerLocal.Pawn) != None && Vehicle(PlayerControllerLocal.Pawn).Driver == ProtectedPawn)))
    {
        LocalHUD = JBInterfaceHud(PlayerControllerLocal.myHUD);
        LocalHUD.RegisterOverlay(Self);
    }
}


// ============================================================================
// Tick
//
// Calculate the protection charge.
// ============================================================================

function Tick(float DeltaTime)
{
    if(EndProtectionTime > 0)
        ProtectionCharge = (EndProtectionTime - Level.TimeSeconds);

    if((ProtectionCharge < 0)
    || (ProtectedPawn == None)
    || (ProtectedPawn.HasUDamage()))
        Destroy();
}


// ============================================================================
// StartProtectionLife
//
// Start the life of protection.
// ============================================================================

function StartProtectionLife()
{
    ProtectionTime = Class'JBAddonProtection'.Default.ProtectionTime;
    EndProtectionTime = Level.TimeSeconds + ProtectionTime;
}


// ============================================================================
// RenderOverlays
//
// Draw on HUD the protection bar charge.
// ============================================================================

simulated function RenderOverlays(Canvas C)
{
    if((LocalHUD.bHideHUD)
    || (LocalHUD.bShowScoreBoard)
    || (LocalHUD.bShowLocalStats))
        return;

    if(ProtectionTime != 0 && EndProtectionTime == 0)
      EndProtectionTime = Level.TimeSeconds + ProtectionTime;

    LocalHUD.DrawSpriteWidget(C, ProtectionIcon);

    if(ProtectionTime != 0)
    {
        ProtectionDigits.Value = Ceil(EndProtectionTime - Level.TimeSeconds);
        LocalHUD.DrawNumericWidget(C, ProtectionDigits, LocalHUD.DigitsBig);
    }
}


// ============================================================================
// KeepDamageScore
//
// Keep a score of how much damage Protection has absorbed
// Return True if we go over the threshold
// ============================================================================

function bool KeepDamageScore(int Damage, Pawn myPawn)
{
  ProtectedPawnAbsorbedDamage += Damage;

  if( ProtectedPawnAbsorbedDamage >= myPawn.Default.Health ) {
    ProtectedPawnAbsorbedDamage = 0;
    return True;
  }
  return False;
}


// ============================================================================
// Destroyed
//
// When this actor are destroyed, remove the protection of protected pawn.
// ============================================================================

event Destroyed()
{
    if(ProtectionEffect != None)
    {
        ProtectionEffect.mRegen    = False;
        ProtectionEffect.mRegenRep = False;
    }

    if(LocalHUD != None)
        LocalHUD.UnRegisterOverlay(Self);

    Super.Destroyed();
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True
    bHidden=True
    bStatic=False

    ProtectionIcon=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=126,Y1=165,X2=164,Y2=226),TextureScale=0.8,DrawPivot=DP_MiddleMiddle,PosX=0.05,PosY=0.75,OffsetY=7,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    ProtectionDigits=(RenderStyle=STY_Alpha,TextureScale=0.490000,DrawPivot=DP_MiddleMiddle,PosX=0.05,PosY=0.75,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
}
