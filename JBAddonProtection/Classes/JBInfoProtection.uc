// ============================================================================
// JBInfoProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBInfoProtection.uc,v 1.1 2003/07/27 03:24:30 crokx Exp $
//
// Protection of protection add-on.
// ============================================================================
class JBInfoProtection extends Info;


// ============================================================================
// Variables
// ============================================================================
var JBxEmitterProtectionRed ProtectionEffect;
var PlayerReplicationInfo RelatedPRI;
var private Pawn ProtectedPawn;
var private float EndProtectionTime;
var private float ProtectionCharge;

var private JBInterfaceHud LocalHUD;
var private HUDBase.SpriteWidget ProtectionFill;
var private HUDBase.SpriteWidget ProtectionTint;
var private HUDBase.SpriteWidget ProtectionTrim;


// ============================================================================
// PostBeginPlay
//
// Protect the ProtectedPawn.
// ============================================================================
function PostBeginPlay()
{
    ProtectedPawn = Pawn(Owner);
    if(ProtectedPawn == None)
    {
        LOG("!!!!!"@name$".PostBeginPlay() : ProtectedPawn not found !!!!!");
        Destroy();
        return;
    }

    RelatedPRI = ProtectedPawn.PlayerReplicationInfo;

    Super.PostBeginPlay();

    ProtectedPawn.ReducedDamageType = class'JBDamageTypeNone';

    if(RelatedPRI.Team.TeamIndex == 0)
        ProtectionEffect = Spawn(class'JBxEmitterProtectionRed', ProtectedPawn,, ProtectedPawn.Location);
    else
        ProtectionEffect = Spawn(class'JBxEmitterProtectionBlue', ProtectedPawn,, ProtectedPawn.Location);

    if((ProtectedPawn.Controller != None)
    && (PlayerController(ProtectedPawn.Controller) != None)
    && (PlayerController(ProtectedPawn.Controller).myHUD != None)
    && (JBInterfaceHud(PlayerController(ProtectedPawn.Controller).myHUD) != None))
    {
        LocalHUD = JBInterfaceHud(PlayerController(ProtectedPawn.Controller).myHUD);
        LocalHUD.RegisterOverlay(SELF);
    }
}


// ============================================================================
// Tick
//
// Calculate the protection charge.
// ============================================================================
function Tick(float DeltaTime)
{
    if(EndProtectionTime == 0)
        return;

    ProtectionCharge = (EndProtectionTime - Level.TimeSeconds);

    if((ProtectionCharge < 0)
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
    EndProtectionTime = (Level.TimeSeconds + class'JBAddonProtection'.default.ProtectionTime);
}


// ============================================================================
// RenderOverlays
//
// Draw on HUD the protection bar charge.
// ============================================================================
function RenderOverlays(Canvas C)
{
    if((LocalHUD.bHideHUD)
    || (LocalHUD.bShowScoreBoard)
    || (LocalHUD.bShowLocalStats))
        return;

    if(EndProtectionTime == 0)
        ProtectionFill.Scale = 1.0;
    else
        ProtectionFill.Scale = (ProtectionCharge / class'JBAddonProtection'.default.ProtectionTime);

    LocalHUD.DrawSpriteWidget(C, ProtectionFill);
    LocalHUD.DrawSpriteWidget(C, ProtectionTint);
    LocalHUD.DrawSpriteWidget(C, ProtectionTrim);
}


// ============================================================================
// Destroyed
//
// When this actor are destroyed, remove the protection of protected pawn.
// ============================================================================
function Destroyed()
{
    if(ProtectedPawn != None)
        ProtectedPawn.ReducedDamageType = None;

    if(ProtectionEffect != None)
    //    ProtectionEffect.Destroy();
        ProtectionEffect.mRegen = FALSE;

    if(LocalHUD != None)
        LocalHUD.UnregisterOverlay(SELF);

    Super.Destroyed();
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    bHidden=True
    bStatic=False
    ProtectionFill=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=490,X1=836,Y2=454),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=0,B=0,A=255),Tints[1]=(R=0,G=0,B=255,A=255))
    ProtectionTint=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=490,X1=836,Y2=454),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=100,G=0,B=0,A=100),Tints[1]=(R=37,G=66,B=102,A=150))
    ProtectionTrim=(WidgetTexture=Material'InterfaceContent.Hud.SkinA',TextureCoords=(X2=450,Y1=453,X1=836,Y2=415),TextureScale=0.3,DrawPivot=DP_UpperLeft,PosX=0.0,PosY=0.835,OffsetX=137,OffsetY=15,ScaleMode=SM_Right,Scale=1.0,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
}
