// ============================================================================
// JBCamManager
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBCamManager.uc,v 1.1 2004/03/14 16:19:13 mychaeel Exp $
//
// Provides management functions for an array of cameras sharing the same Tag.
// ============================================================================


class JBCamManager extends Info
  notplaceable;


// ============================================================================
// Caches
// ============================================================================

struct TCacheFindCameraBest { var float Time; var JBCamera Result; };

var private TCacheFindCameraBest CacheFindCameraBest;  // best  camera in array
var private JBCamera CacheFindCameraFirst;             // first camera in array
var private JBCamera CacheFindCameraLast;              // last  camera in array

var private array<JBInventoryCamera> CacheInventoryCamera;  // reusable items


// ============================================================================
// SpawnFor
//
// Finds or spawns a manager actor for the given camera and returns it. If the
// given camera is not part of a camera array because there is no other camera
// sharing the same Tag, returns None instead.
// ============================================================================

static function JBCamManager SpawnFor(JBCamera Camera)
{
  local int nCameras;
  local JBCamera thisCamera;
  local JBCamManager thisCamManager;

  foreach Camera.DynamicActors(Class'JBCamManager', thisCamManager, Camera.Tag)
    return thisCamManager;
  
  foreach Camera.DynamicActors(Class'JBCamera', thisCamera, Camera.Tag)
    nCameras += 1;
  
  if (nCameras > 1)
    return Camera.Spawn(Class'JBCamManager', , Camera.Tag);
  return None;
}


// ============================================================================
// FindCameraFirst
//
// Finds and returns the first camera in the array. Caches its results after
// the first call. Use RefreshCameraOrder to clear the cache.
// ============================================================================

function JBCamera FindCameraFirst()
{
  local JBCamera thisCamera;

  if (CacheFindCameraFirst != None)
    return CacheFindCameraFirst;
  
  foreach DynamicActors(Class'JBCamera', thisCamera, Tag)
    if (CacheFindCameraFirst == None ||
        CacheFindCameraFirst.Switching.CamOrder > thisCamera.Switching.CamOrder)
      CacheFindCameraFirst = thisCamera;
  
  return CacheFindCameraFirst;
}


// ============================================================================
// FindCameraLast
//
// Finds and returns the last camera in the array. Caches its results after
// the first call. Use RefreshCameraOrder to clear the cache.
// ============================================================================

function JBCamera FindCameraLast()
{
  local JBCamera thisCamera;

  if (CacheFindCameraLast != None)
    return CacheFindCameraLast;

  foreach DynamicActors(Class'JBCamera', thisCamera, Tag)
    if (CacheFindCameraLast == None ||
        CacheFindCameraLast.Switching.CamOrder <= thisCamera.Switching.CamOrder)
      CacheFindCameraLast = thisCamera;
  
  return CacheFindCameraLast;
}


// ============================================================================
// FindCameraNext
//
// Finds and returns the camera which directly follows the given camera in the
// array. Results are partially cached.
// ============================================================================

function JBCamera FindCameraNext(JBCamera CameraCurrent)
{
  local bool bFoundCameraCurrent;
  local JBCamera CameraNext;
  local JBCamera thisCamera;

  if (CameraCurrent == None ||
      CameraCurrent == FindCameraLast())
    return FindCameraFirst();

  foreach DynamicActors(Class'JBCamera', thisCamera, Tag)
    if (thisCamera == CameraCurrent)
      bFoundCameraCurrent = True;
    else
      if (thisCamera.Switching.CamOrder >  CameraCurrent.Switching.CamOrder ||
         (thisCamera.Switching.CamOrder == CameraCurrent.Switching.CamOrder && bFoundCameraCurrent))
        if (CameraNext == None ||
            CameraNext.Switching.CamOrder > thisCamera.Switching.CamOrder)
          CameraNext = thisCamera;

  return CameraNext;
}


// ============================================================================
// FindCameraPrev
//
// Finds and returns the camera which comes directly before the given camera
// in the array. Results are partially cached.
// ============================================================================

function JBCamera FindCameraPrev(JBCamera CameraCurrent)
{
  local bool bFoundCameraCurrent;
  local JBCamera CameraPrev;
  local JBCamera thisCamera;
  
  if (CameraCurrent == None ||
      CameraCurrent == FindCameraFirst())
    return FindCameraLast();
  
  foreach DynamicActors(Class'JBCamera', thisCamera, Tag)
    if (thisCamera == CameraCurrent)
      bFoundCameraCurrent = True;
    else
      if (thisCamera.Switching.CamOrder <  CameraCurrent.Switching.CamOrder ||
         (thisCamera.Switching.CamOrder == CameraCurrent.Switching.CamOrder && !bFoundCameraCurrent))
        if (CameraPrev == None ||
            CameraPrev.Switching.CamOrder <= thisCamera.Switching.CamOrder)
          CameraPrev = thisCamera;

  return CameraPrev;
}


// ============================================================================
// RefreshCameraOrder
//
// Call this function when new cameras have been added to the array or when
// their order has been changed to update the cached sequence information.
// ============================================================================

function RefreshCameraOrder()
{
  CacheFindCameraFirst = None;
  CacheFindCameraLast  = None;
}


// ============================================================================
// FindCameraBest
//
// Finds the best camera in the array based on their self-rating and returns
// it. If no suitable camera can be found, returns None. Caches its results
// for one second.
// ============================================================================

function JBCamera FindCameraBest()
{
  local JBCamera CameraBest;
  local JBCamera thisCamera;
  local float Rating;
  local float RatingPrev;
  local float RatingBest;

  if (CacheFindCameraBest.Time + 1.0 > Level.TimeSeconds)
    return CacheFindCameraBest.Result;

  CacheFindCameraBest.Time = Level.TimeSeconds;
  
  foreach DynamicActors(Class'JBCamera', thisCamera, Tag) {
    thisCamera.UpdateMovement();
    
    Rating = thisCamera.RateCurrentView();
    
    if (Rating > RatingBest) {
      RatingBest = Rating;
      CameraBest = thisCamera;
    }
  
    if (thisCamera == CacheFindCameraBest.Result)
      RatingPrev = Rating;
  }

  if (RatingPrev == 0.0 ||
      RatingPrev < RatingBest / 1.2)
    CacheFindCameraBest.Result = CameraBest;

  return CacheFindCameraBest.Result;
}


// ============================================================================
// AddInventoryCamera
//
// Adds a JBInventoryCamera inventory item to the given player's inventory and
// returns a reference to it. Uses cached items if possible.
// ============================================================================

function JBInventoryCamera AddInventoryCamera(Controller Controller, JBCamera Camera)
{
  local JBInventoryCamera InventoryCamera;

  if (Controller.Pawn == None)
    return None;

  if (CacheInventoryCamera.Length == 0) {
    InventoryCamera = Spawn(Class'JBInventoryCamera', Controller.Pawn);
  }
  else {
    InventoryCamera = CacheInventoryCamera[CacheInventoryCamera.Length - 1];
    InventoryCamera.SetOwner(Controller.Pawn);
    CacheInventoryCamera.Remove(CacheInventoryCamera.Length - 1, 1);
  }

  InventoryCamera.Camera     = Camera;
  InventoryCamera.Instigator = Controller.Pawn;
  InventoryCamera.Inventory  = Controller.Pawn.Inventory;
  Controller.Pawn.Inventory  = InventoryCamera;
  
  return InventoryCamera;
}


// ============================================================================
// RemoveInventoryCamera
//
// Removes all JBInventoryCamera inventory items from the given player's
// inventory. Caches the used item.
// ============================================================================

function RemoveInventoryCamera(Controller Controller)
{
  local Actor thisActor;
  local JBInventoryCamera InventoryCamera;

  if (Controller.Pawn == None)
    return;

  thisActor = Controller.Pawn;
  do {
    InventoryCamera = JBInventoryCamera(thisActor.Inventory);
    if (InventoryCamera != None) {
      thisActor.Inventory = InventoryCamera.Inventory;
      InventoryCamera.Camera     = None;
      InventoryCamera.Instigator = None;
      InventoryCamera.Inventory  = None;
      InventoryCamera.SetOwner(None);
      CacheInventoryCamera[CacheInventoryCamera.Length] = InventoryCamera;
    }
    else {
      thisActor = thisActor.Inventory;
    }
  } until (thisActor == None);
}


// ============================================================================
// Destroyed
//
// Destroys all cached JBInventoryCamera inventory items.
// ============================================================================

event Destroyed()
{
  while (CacheInventoryCamera.Length > 0) {
    CacheInventoryCamera[CacheInventoryCamera.Length - 1].Destroy();
    CacheInventoryCamera.Remove(CacheInventoryCamera.Length - 1, 1);
  }
}