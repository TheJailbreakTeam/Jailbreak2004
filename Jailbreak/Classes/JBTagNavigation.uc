// ============================================================================
// JBTagNavigation
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTagNavigation.uc,v 1.6 2003/06/29 11:03:36 mychaeel Exp $
//
// Caches information about an actor used for navigational purposes.
// ============================================================================


class JBTagNavigation extends JBTag
  notplaceable;


// ============================================================================
// Types
// ============================================================================

struct TInfoDistance
{
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

static function float CalcDistance(NavigationPoint NavigationPointFrom, NavigationPoint NavigationPointTo)
{
  local int iDistance;
  local float Distance;
  local Actor ActorFrom;
  local Actor ActorTo;
  local Controller Controller;
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

  Controller = TagNavigationFrom.GetController();

  ActorFrom = NavigationPointFrom;
  ActorTo   = NavigationPointTo;
  if (JBGameObjective(ActorFrom) != None) ActorFrom = JBGameObjective(ActorFrom).TriggerRelease;
  if (JBGameObjective(ActorTo)   != None) ActorTo   = JBGameObjective(ActorTo  ).TriggerRelease;

  Controller.Pawn.SetLocation(ActorFrom.Location);
  Controller.Pawn.SetRotation(ActorFrom.Rotation);

  if (Controller.FindPathToward(ActorTo) != None)
    Distance = Controller.RouteDist;
  else
    Distance = VSize(ActorFrom.Location - ActorTo.Location);

  Controller.Pawn.SetPhysics(PHYS_None);  // may be set to falling

  iDistance = TagNavigationFrom.ListInfoDistance.Length;
  TagNavigationFrom.ListInfoDistance.Insert(iDistance, 1);
  TagNavigationFrom.ListInfoDistance[iDistance].NavigationPointTo = NavigationPointTo;
  TagNavigationFrom.ListInfoDistance[iDistance].Distance = Distance;

  return Distance;
}


// ============================================================================
// GetController
//
// Returns a reference to a controller with a scout pawn. Tries to find an
// existing controller and pawn first before spawning a new one.
// ============================================================================

private function Controller GetController()
{
  local JBTagNavigation thisTagNavigation;

  if (Controller != None)
    return Controller;

  foreach DynamicActors(Class'JBTagNavigation', thisTagNavigation)
    if (thisTagNavigation.Controller != None) {
      Controller = thisTagNavigation.Controller;
      return Controller;
    }

  Controller = Spawn(Class'ScriptedTriggerController');
  Controller.Possess(Spawn(Class'JBScout'));

  return Controller;
}
