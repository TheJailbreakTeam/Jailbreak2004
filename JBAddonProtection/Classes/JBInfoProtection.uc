// ============================================================================
// JBInfoProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id$
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
var private HUDBase.SpriteWidget ProtectionFill;
var private HUDBase.SpriteWidget ProtectionTint;
var private HUDBase.SpriteWidget ProtectionTrim;


// ============================================================================
// PostBeginPlay
//
// Initializes replicated variables and spawns the visual effect.
// ============================================================================

event PostBeginPlay()
{
    ProtectedPawn = Pawn(Owner);
    RelatedPRI = ProtectedPawn.PlayerReplicationInfo;

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
        PlayerControllerLocal.Pawn == ProtectedPawn)
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

    if(ProtectionTime == 0)
        ProtectionFill.Scale = 1.0;
    else
        ProtectionFill.Scale = (EndProtectionTime - Level.TimeSeconds) / ProtectionTime;

    LocalHUD.DrawSpriteWidget(C, ProtectionFill);
    LocalHUD.DrawSpriteWidget(C, ProtectionTint);
    LocalHUD.DrawSpriteWidget(C, ProtectionTrim);
}


// ============================================================================
// KeepDamageScore
//
// Keep a total of how much damage Protection has absorbed
// Return True if we go over the threshold and reset the damage total
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
        LocalHUD.UnregisterOverlay(Self);

    Super.Destroyed();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True
    bHidden=True
    bStatic=False

    ProtectionFill=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=490,X1=836,Y2=454),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=0,B=0,A=255),Tints[1]=(R=0,G=0,B=255,A=255))
    ProtectionTint=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=490,X1=836,Y2=454),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150))
    ProtectionTrim=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=453,X1=836,Y2=415),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
}
