//=============================================================================
// JBInventoryAvenger
// Copyright 2004 by tarquin <tarquin@beyondunreal.com>
// $Id: JBInventoryAvenger.uc,v 1.1.2.4 2004/05/17 12:07:46 tarquin Exp $
//
// Spawned for each avenger player. Gives the player the combo and then 
// destroys it after set time.
//=============================================================================


class JBInventoryAvenger extends Inventory;
  
  
// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    AvengerDuration;
}


// ============================================================================
// Variables
// ============================================================================

var private JBInterfaceHud  LocalHUD;
var private int             LevelTimeAvengerStart;
var private int             LevelTimeAvengerEnd;
var private int             AvengerDuration;
var private HudBase.NumericWidget   AvengerRemainingCount;


// ============================================================================
// PostNetBeginPlay
//
// Notifies the Avenger of his status: registers the HUD overlay client-side, 
// and plays a voice announcement. 
// Replication: this doesn't happen on a server (with no PlayerControllerLocal)
// and for standalone and listen servers, check the local player is the owner.
// ============================================================================

simulated event PostNetBeginPlay()
{
    local PlayerController PlayerControllerLocal;

    PlayerControllerLocal = Level.GetLocalPlayerController();
    if (PlayerControllerLocal != None && PlayerControllerLocal.Pawn == Pawn(Owner))
    {
        LocalHUD = JBInterfaceHud(PlayerControllerLocal.myHUD);
        LocalHUD.RegisterOverlay(Self);
        
        Class'JBSpeechManager'.Static.PlayFor(Level, "$AddonVengeanceStart");
    }
}


// ============================================================================
// StartAvenger
// 
// Called by JBGameRulesAvenger to give the time value. 
// Cause the owner pawn to execute a combo power-up. (Using a combo class 
// means the avenger's death automatically removes the combo)
// Neutralises the adrenaline cost to prevent drain of adrenaline.
// Sets the timer, displays a message.
// ============================================================================

function StartAvenger(int Duration) 
{
  local class<Combo> ComboClass;

  AvengerDuration = Duration;
  
  if( xPawn(Owner) == None )
    return; // daft but just in case
    
  ComboClass = class'JBAddonAvenger'.default.ComboClasses[class'JBAddonAvenger'.default.PowerComboIndex];

  if( ComboClass == None )
    log("JB AVENGER: No combo class!");

  xPawn(Owner).DoCombo(ComboClass);  
  xPawn(Owner).CurrentCombo.AdrenalineCost = 0;
  
  SetTimer(AvengerDuration, False);

  xPawn(Owner).ReceiveLocalizedMessage(class'JBLocalMessageAvenger', AvengerDuration);
  
}


// ============================================================================
// RenderOverlays
//
// Draws the Avenger countdown on the HUD: rounded up, with no 0.
// On first call, sets the level time variables and hides the existing
// AdrenalineCount widget on the HUD.
// ============================================================================

simulated function RenderOverlays(Canvas C)
{
  if((LocalHUD.bHideHUD)
  || (LocalHUD.bShowScoreBoard)
  || (LocalHUD.bShowLocalStats))
      return;

  if( LevelTimeAvengerEnd == 0 && AvengerDuration != 0) {
    LevelTimeAvengerEnd   = Level.TimeSeconds + AvengerDuration;
    
    LocalHUD.AdrenalineCount.Tints[0].A = 0;
    LocalHUD.AdrenalineCount.Tints[1].A = 0;
  }
      
  AvengerRemainingCount.Value = ceil(LevelTimeAvengerEnd - Level.TimeSeconds);
  
  if( AvengerRemainingCount.Value == 0 )
    AvengerRemainingCount.Value = 1;

  LocalHUD.DrawNumericWidget (C, AvengerRemainingCount, LocalHUD.DigitsBig);

}


// ============================================================================
// Timer
//
// Destroy self after the AvengerTime delay: will stop the avenger effect
// ============================================================================

function Timer()
{
  Destroy();
}


// ============================================================================
// Destroyed
//
// Stop the avenger effect by destroying the owner's combo. 
// Restore the adrenaline count on the HUD
// ============================================================================

simulated event Destroyed() {
  if( xPawn(Owner) != None 
    && xPawn(Owner).CurrentCombo != None
    ) {
    xPawn(Owner).CurrentCombo.Destroy();
  }

  if(LocalHUD != None)
      LocalHUD.UnregisterOverlay(Self);
  
  LocalHUD.AdrenalineCount.Tints[0].A = LocalHUD.Default.AdrenalineCount.Tints[0].A;
  LocalHUD.AdrenalineCount.Tints[1].A = LocalHUD.Default.AdrenalineCount.Tints[1].A;
  
  Super.Destroyed();
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  bOnlyRelevantToOwner  = True;
  AvengerRemainingCount = (TextureScale=0.18,DrawPivot=DP_UpperRight,PosX=1.0,PosY=0,OffsetX=-260,OffsetY=40,RenderStyle=STY_Alpha,Tints[0]=(R=255,G=255,B=255,A=255),Tints[1]=(R=255,G=255,B=255,A=255))
}
