// ============================================================================
// JBAddonJailCard
// Copyright 2004 by tarquin <tarquin@planetjailbreak.com>
// $Id$
//
// Implements a "Get Out of Jail Free" card
// ============================================================================


class JBAddonJailCard extends JBAddon;


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

// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
var   int NumNavPoints; // number of NavigationPoints in the entire level
var   JBPickupJailCard SpawnedCardPickup;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules, count number of navigation points in map.
// ============================================================================

function PostBeginPlay()
{
  local JBGameRulesJailCard MyRules;
  local NavigationPoint NP;

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

  // nicked from UT's Relics system
  for (NP = Level.NavigationPointList; NP != None; NP = NP.nextNavigationPoint) {
    if (NP.IsA('PathNode'))
      // must eliminate jail & arena nodes!
      NumNavPoints++;
  }
  SpawnCard();
}


//=============================================================================
// SpawnCard
//
// Spawns the GOOJF card pickup.
//=============================================================================

function SpawnCard()
{
  local int PointCount, ChosenNavPoint;
  local NavigationPoint NP;

  ChosenNavPoint = Rand(NumNavPoints);

  // this code needs to be replaced with something that finds a decent spot: use
  //     StartSpot = FindPlayerStart( None, InTeam, Portal );



  for (NP = Level.NavigationPointList; NP != None; NP = NP.NextNavigationPoint)
  {
    if ( NP.IsA('PathNode') )
    {
      if (PointCount == ChosenNavPoint)
      {
        SpawnedCardPickup = Spawn(class'JBPickupJailCard', , , NP.Location);
        SpawnedCardPickup.MyAddon = Self;
        return;
      }
      PointCount++;
    }
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


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
   Build="%%%%-%%-%% %%:%%"
   ConfigMenuClassName="JBAddonJailCard.JBGUIPanelConfigJailCard"

   FriendlyName = "Get Out of Jail Free"
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
