// ============================================================================
// JBTagNavigation
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagNavigation.uc,v 1.2 2003/01/26 12:41:32 mychaeel Exp $
//
// Caches information about an actor used for navigational purposes.
// ============================================================================


class JBTagNavigation extends JBTag
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TInfoDistance {

  var NavigationPoint NavigationPointTo;  // target navigation point
  var float Distance;                     // distance to that navigation point
  };


// ============================================================================
// Variables
// ============================================================================

var private array<TInfoDistance> ListInfoDistance;  // cached distance values
var private Controller Controller;                  // used for path finding


// ============================================================================
// Internal
// ============================================================================

static function JBTagNavigation FindFor(Actor Keeper) {
  return JBTagNavigation(InternalFindFor(Keeper)); }
static function JBTagNavigation SpawnFor(Actor Keeper) {
  return JBTagNavigation(InternalSpawnFor(Keeper)); }


// ============================================================================
// CalcDistance
//
// Calculates the traveling distance between two given actors. Expensive on
// the first call for a given set of two actors, but results are cached for
// subsequent calls.
// ============================================================================

static function float CalcDistance(NavigationPoint NavigationPointFrom, NavigationPoint NavigationPointTo) {

  local int iDistance;
  local float Distance;
  local Actor ActorFrom;
  local Actor ActorTo;
  local JBTagNavigation TagNavigationFrom;

  if (NavigationPointFrom == NavigationPointTo)
    return 0.0;

  if (NavigationPointFrom == None ||
      NavigationPointTo   == None)
    return -1.0;  // error

  TagNavigationFrom = SpawnFor(NavigationPointFrom);  // retrieves existing tag
  
  for (iDistance = 0; iDistance < TagNavigationFrom.ListInfoDistance.Length; iDistance++)
    if (TagNavigationFrom.ListInfoDistance[iDistance].NavigationPointTo == NavigationPointTo)
      return TagNavigationFrom.ListInfoDistance[iDistance].Distance;

  SpawnController(NavigationPointFrom.Level);  // initialize Default.Controller

  ActorFrom = NavigationPointFrom;
  ActorTo   = NavigationPointTo;
  if (JBGameObjective(ActorFrom) != None) ActorFrom = JBGameObjective(ActorFrom).TriggerRelease;
  if (JBGameObjective(ActorTo)   != None) ActorTo   = JBGameObjective(ActorTo  ).TriggerRelease;

  Default.Controller.Pawn.SetLocation(ActorFrom.Location);
  Default.Controller.Pawn.SetRotation(ActorFrom.Rotation);

  if (Default.Controller.FindPathToward(ActorTo) != None)
    Distance = Default.Controller.RouteDist;
  else
    Distance = VSize(ActorFrom.Location - ActorTo.Location);  // fallback

  iDistance = TagNavigationFrom.ListInfoDistance.Length;
  TagNavigationFrom.ListInfoDistance.Insert(iDistance, 1);
  TagNavigationFrom.ListInfoDistance[iDistance].NavigationPointTo = NavigationPointTo;
  TagNavigationFrom.ListInfoDistance[iDistance].Distance = Distance;
  
  return Distance;
  }


// ============================================================================
// SpawnController
//
// Makes sure a controller and a scout pawn are spawned and stores a reference
// to the controller in the default property of the Controller variable.
// ============================================================================

private static function SpawnController(LevelInfo Level) {

  local Controller thisController;

  if (Default.Controller != None &&
      Default.Controller.Level != Level)
    Default.Controller = None;

  if (Default.Controller == None)
    for (thisController = Level.ControllerList;
         thisController != None && Default.Controller == None;
         thisController = thisController.NextController)
      if (JBScout(thisController.Pawn) != None)
        Default.Controller = thisController;

  if (Default.Controller == None)
    Default.Controller = Level.Spawn(Class'AIController');

  if (Default.Controller.Pawn == None)
    Default.Controller.Possess(Level.Spawn(Class'JBScout'));
  }