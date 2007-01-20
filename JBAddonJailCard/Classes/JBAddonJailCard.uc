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

var   Array<JBPickupJailCard> SpawnedCardPickups;
var   array<NavigationPoint> NavPoints; // list of usable navpoints

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
        SpawnCards();
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
            NavPoints.Length = (NavPoints.Length + 1);
            NavPoints[(NavPoints.Length - 1)] = NP;
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
    local int PointCount, ChosenNavPoint, NavCount;
    local NavigationPoint NP;

    ChosenNavPoint = Rand(NavPoints.Length);

    // this code needs to be replaced with something that finds a decent spot: use
    // StartSpot = FindPlayerStart( None, InTeam, Portal );
    /*for (NavCount = 0; NavCount < NavPoints.Length; NavCount++)
    {
        NP = NavPoints[NavCount];
        if ( NP.IsA('PathNode') )
        {
            if (PointCount == ChosenNavPoint)
            {
                break;
            }
            PointCount++;
        }
    } */

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
    //debug
    log("Spawned JailCard");
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


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
   Build="%%%%-%%-%% %%:%%"
   ConfigMenuClassName="JBAddonJailCard.JBGUIPanelConfigJailCard"

   FriendlyName = "JailCard"
   Description  = "Pick up the Get Out of Jail Free card and use it when you are in jail to gain your freedom."

   bAutoUseCard   = False
   bAllowDropCard = True
   SpawnDelay     = 0
   NumCards       = 1
}

/*
1.A model of the pickup. I think it would be a good idea to make something in the same sort of general style as the release switch. Maybe we could even use the key model Rev made.
2. some code to spawn it in random places. We can do it like the Relics system in UT
3. a HUD icon to tell the player they possess this item
4. a means for them to use it (and something on screen to remind them how to use it). Do Power-ups work in jail? Perhaps we can just use one of the power-up combo moves, like Back-Back-Back-Back.
5. something that detects use, and teleports them home
6. bot support.
*/
