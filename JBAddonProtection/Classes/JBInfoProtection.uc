// ============================================================================
// JBInfoProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBInfoProtection.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// Protection of protection add-on.
// ============================================================================
class JBInfoProtection extends Info;


// ============================================================================
// Variables
// ============================================================================
var JBxEmitterProtectionRed ProtectionEffect;
var int RelatedID;
var private Pawn ProtectedPawn;
var private float EndProtectionTime;
var private float ProtectionCharge;

var private JBInterfaceHud LocalHUD;
var private HUDBase.SpriteWidget ProtectionFill;
var private HUDBase.SpriteWidget ProtectionTint;
var private HUDBase.SpriteWidget ProtectionTrim;


// ============================================================================
// PreBeginPlay
//
// Save the pawn owner to ProtectedPawn.
// ============================================================================
function PreBeginPlay()
{
    ProtectedPawn = Pawn(Owner);
    if(ProtectedPawn == None)
    {
        LOG("!!!!!"@name$".PreBeginPlay() : ProtectedPawn not found !!!!!");
        Destroy();
    }

    Super.PreBeginPlay();
}


// ============================================================================
// PostBeginPlay
//
// Protect the ProtectedPawn.
// ============================================================================
function PostBeginPlay()
{
    Super.PostBeginPlay();

    ProtectedPawn.ReducedDamageType = class'JBDamageTypeNone';

    if(ProtectedPawn.PlayerReplicationInfo.Team.TeamIndex == 0)
        ProtectionEffect = Spawn(class'JBxEmitterProtectionRed', ProtectedPawn,, ProtectedPawn.Location);
    else ProtectionEffect = Spawn(class'JBxEmitterProtectionBlue', ProtectedPawn,, ProtectedPawn.Location);
    if(ProtectionEffect != None) ProtectionEffect.SetBase(ProtectedPawn);

    if((ProtectedPawn.Controller != None)
    && (ProtectedPawn.Controller.IsA('PlayerController'))
    && (PlayerController(ProtectedPawn.Controller).myHUD != None)
    && (PlayerController(ProtectedPawn.Controller).myHUD.IsA('JBInterfaceHud')))
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
    if(EndProtectionTime == 0) return;
    ProtectionCharge = (EndProtectionTime - Level.TimeSeconds);
    if(ProtectionCharge < 0) Destroy();
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

    if(EndProtectionTime == 0) ProtectionFill.Scale = 1.0;
    else ProtectionFill.Scale = (ProtectionCharge / class'JBAddonProtection'.default.ProtectionTime);

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
    if(ProtectedPawn != None) ProtectedPawn.ReducedDamageType = None;
    if(ProtectionEffect != None) ProtectionEffect.Destroy();
    if(LocalHUD != None) LocalHUD.UnregisterOverlay(SELF);

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
