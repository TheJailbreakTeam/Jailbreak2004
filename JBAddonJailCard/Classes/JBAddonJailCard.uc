// ============================================================================
// JBAddonJailCard
// Copyright 2007 by [GSF]JohnDoe <gsfjohndoe@hotmail.com>
// Created by tarquin <tarquin@planetjailbreak.com>
// $Id$
//
// Implements a "Get Out of Jail Free" card
//
// CHANGELOG:
// 14 jan 2007 - Changed friendly name to "JailCard"
// 15 jan 2007 - Seperated code for finding a proper JailCard spawnpoint and
//               the code to spawn it
//               Added spawning multiple cards.
//               Fixed config
//               Stopped cards from spawning in jail/arena
// 22 jan 2007 - Moved SpawnCards call to gamerules class
// 10 feb 2007 - Added variable to address our GameRules class
//               Added RenderOverlays method (does not work correctly yet)
//               Added code to the auto state to register RenderOverlays
// ============================================================================


class JBAddonJailCard extends JBAddon config;


//=============================================================================
// Configuration & Defaults
//=============================================================================

var config bool bAutoUseCard;     // card is used automatically when jailed
  const DEFAULT_AUTOUSE_CARD      = False;

var config bool bAllowDropCard;   // can the GOOJF card be dropped?
  const DEFAULT_ALLOW_DROP        = True;

var config int  SpawnDelay;       // delay at round start before spawning card
  const DEFAULT_SPAWN_DELAY       = 0;

var config int  NumCards;         // number of cards to spawn
  const DEFAULT_NUM_CARDS         = 1;

var() const editconst string Build;


// ============================================================================
// Variables
// ============================================================================

var Array<JBPickupJailCard> SpawnedCardPickups; // list of spawned jailcards
var Array<NavigationPoint> NavPoints; // list of usable navpoints
var JBGameRulesJailCard myGameRules; // our gamerules class
var private HUDBase.SpriteWidget  JailCardIcon; // our hud icon
var PlayerController PC;

struct NavPointScore
{
    var NavigationPoint NP;
    var float score;
};


// ============================================================================
// PostBeginPlay
//
// Register the additional rules, count number of navigation points in map.
// ============================================================================

function PostBeginPlay()
{
    local JBGameRulesJailCard MyRules;

    Super.PostBeginPlay();

    MyRules = Spawn(Class'JBGameRulesJailCard');

    if(MyRules != None) {
        MyRules.SetAddon(self);
        myGameRules = MyRules;
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = MyRules;
        else
            Level.Game.GameRulesModifiers.AddGameRules(MyRules);
    }
    else {
        LOG("!!!!!"@name$".PostBeginPlay() : Failed to register the JBGameRulesJailCard !!!!!");
        Destroy();
    }
}


//=============================================================================
// MyState
//
// This is here to make sure the code is executed AFTER the GRI is created
//=============================================================================

auto state MyState
{
    Begin:
        MakeNavPointList();

        PC = Level.GetLocalPlayerController();
        if (PC != None)
            JBInterfaceHud(PC.myHud).RegisterOverlay(Self);
}


//=============================================================================
// MakeNavPointList
//
// Makes a list (NavPoints) of all usable navigationpoints in game. This
// excludes jail and arena navigationpoints.
//=============================================================================

function MakeNavPointList()
{
    local NavigationPoint NP;
    local Jailbreak JB;

    JB = Jailbreak(Level.Game);
    if(JB == none)
        log("Invalid gametype");

    // nicked from UT's Relics system and adapted
    for (NP = Level.NavigationPointList; NP != None; NP = NP.nextNavigationPoint) {
        if (NP.IsA('PathNode') && !JB.ContainsActorJail(NP) && !JB.ContainsActorArena(NP) ) {
            NavPoints.length = (NavPoints.length + 1);
            NavPoints[(NavPoints.length - 1)] = NP;
        }
    }
}


//=============================================================================
// MakeNavPointScoreList
//
// Makes a sorted list of NavigationPoints, based on
// abs(Distance_to_red_switch - Distance_to_blue_switch), sorted from low to
// high
//=============================================================================

//TODO


//=============================================================================
// FindSpawnPoint
//
// Finds a suitable spawnpoint for our JailCard
//=============================================================================

function NavigationPoint FindSpawnPoint()
{
    local int ChosenNavPoint;

    ChosenNavPoint = Rand(NavPoints.Length);

    // current 'bug': cards may appear on the same PathNode
    return NavPoints[ChosenNavPoint];
}


//=============================================================================
// SpawnCard
//
// Spawns the GOOJF card pickup.
//=============================================================================

function SpawnCard(NavigationPoint NP)
{
    local int len;

    len = SpawnedCardPickups.Length;
    SpawnedCardPickups.Length = len +1;
    SpawnedCardPickups[len] = Spawn(class'JBPickupJailCard', , , NP.Location);
    SpawnedCardPickups[len].setMyAddon(Self);
}

//=============================================================================
// SpawnCards
//
// spawn X amount of jailcards, X being the number of cards set in the
// config, or the amount of NavPoints in a map; whichever is lowest.
//=============================================================================

function SpawnCards()
{
    local int i;

    for (i = 0; i < min(NavPoints.Length, NumCards); i++)
        SpawnCard(FindSpawnPoint());

    log("Cards: "$NumCards);
    log("Auto Use: "$bAutoUseCard);
    log("Allow Drop: "$bAllowDropCard);
    log("Delay: "$SpawnDelay);
}


//=============================================================================
// ClearCards
//
// Removes all cards
//=============================================================================
function ClearCards()
{
    local int i;

    if(SpawnedCardPickups.Length > 0) {
        for (i = 0; i < SpawnedCardPickups.Length; i++)
            SpawnedCardPickups[i].Destroy();

        SpawnedCardPickups.Remove(0, SpawnedCardPickups.Length);
    }

}


//=============================================================================
// ResetConfiguration
//
// Resets the user configuration.
//=============================================================================

static function ResetConfiguration()
{
  default.bAutoUseCard    = DEFAULT_AUTOUSE_CARD;
  default.bAllowDropCard  = DEFAULT_ALLOW_DROP;
  default.SpawnDelay      = DEFAULT_SPAWN_DELAY;
  default.NumCards        = DEFAULT_NUM_CARDS;

  StaticSaveConfig();
}

//=============================================================================
// RenderOverlays
//
// Draw HUD icon if a player has the jail card
//=============================================================================
simulated function RenderOverlays(Canvas Canvas)
{
    local JBInterfaceHud myHUD;

    if(PC != none) {   // This HasJailCard() call should be moved to somewhere where it is not called quite as often.
                       // Afterall, the HUD icon only needs to change when a player gets or loses a jailcard
        if(myGameRules.HasJailCard(PC.PlayerReplicationInfo) > -1) {    // not returning the right result because HasJailCard is only present correctly on the server ARG!
            myHUD = JBInterfaceHud(PC.myHUD);
            myHUD.DrawSpriteWidget(Canvas, JailCardIcon);
            //log("I have a card!");   // works fine on Instant Action
        }
        //else
            //log("no card =|");
    }
    //else
        //log("why's my PC none? :("); // logs this when playing on a dedicated server
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
    Build="%%%%-%%-%% %%:%%";
    ConfigMenuClassName="JBAddonJailCard.JBGUIPanelConfigJailCard";

    FriendlyName = "JailCard";
    Description  = "Pick up the Get Out of Jail Free card and use it when you are in jail to gain your freedom.";

    bAutoUseCard   = False;
    bAllowDropCard = True;
    SpawnDelay     = 0;
    NumCards       = 1;

    bIsOverlay = True;
    RemoteRole = ROLE_SimulatedProxy;
    bAlwaysRelevant = True;
    JailCardIcon=(WidgetTexture=Texture'JBJailCard.jailcardhud',RenderStyle=STY_Alpha,TextureCoords=(X1=8,Y1=0,X2=56,Y2=63),TextureScale=2.0,DrawPivot=DP_MiddleMiddle,PosX=0.05,PosY=0.75,OffsetY=7,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128));
}

/*
1.A model of the pickup. I think it would be a good idea to make something in the same sort of general style as the release switch. Maybe we could even use the key model Rev made.
2. some code to spawn it in random places. We can do it like the Relics system in UT
3. a HUD icon to tell the player they possess this item
4. a means for them to use it (and something on screen to remind them how to use it). Do Power-ups work in jail? Perhaps we can just use one of the power-up combo moves, like Back-Back-Back-Back.
5. something that detects use, and teleports them home
6. bot support.
*/
