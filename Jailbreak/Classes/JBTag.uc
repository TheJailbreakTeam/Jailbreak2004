// ============================================================================
// JBTag
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBTag.uc,v 1.2 2003/01/01 22:11:17 mychaeel Exp $
//
// Abstract base class for information-holding actors that can be attached to
// arbitrary other actors. Actors of the same subclass of JBTag are linked as a
// list and can be efficiently retrieved given the actor they are attached to.
//
// Subclasses should expose the following public interface:
//
//   var JBTagCustom nextTag
//   static function JBTagCustom FindFor(KeeperClass Keeper)
//   static function JBTagCustom SpawnFor(KeeperClass Keeper)
//
// FindFor and SpawnFor can be implemented by means of calling the protected
// functions InternalFindFor and InternalSpawnFor. Overwriting them in the
// subclass gives it the opportunity to return a reference to a JBTag instance
// of that specific subclass and to restrict the class of actors it can be
// attached to.
//
// Internally, subclasses must overwrite the following protected functions
// which take care of maintaining the linked list:
//
//   protected simulated function JBTag InternalGetFirst()
//   protected simulated function       InternalSetFirst(JBTag TagFirst)
//   protected simulated function JBTag InternalGetNext()
//   protected simulated function       InternalSetNext(JBTag TagNext)
//
// InternalGetNext and InternalSetNext act as accessors for the nextTag
// variable declared in the JBTag subclass. InternalGetFirst and
// InternalSetFirst access a centrally available reference to the first item
// in the linked list. This may be anywhere, for instance in the globally
// available instance of JBReplicationInfoGame.
//
// Mixing JBTag actors with inventory of any other kind is not advisable.
// ============================================================================


class JBTag extends Inventory
  abstract
  notplaceable;


// ============================================================================
// Subclass Template
//
// Replace the following terms in the following code by existing sybols:
//
//   JBTagCustom      Your custom subclass of JBTag.
//   KeeperClass      Class of actors that keep items of your JBTag subclass.
//   firstTagCustom   Reference to the first item in the linked list.
//
// Also introduce the firstTagCustom variable in JBReplicationInfoGame.
// ============================================================================

/*
var JBTagCustom nextTag;

static function JBTagCustom FindFor(KeeperClass Keeper) {
  return JBTagCustom(InternalFindFor(Keeper)); }
static function JBTagCustom SpawnFor(KeeperClass Keeper) {
  return JBTagCustom(InternalSpawnFor(Keeper)); }

protected simulated function JBTag InternalGetFirst() {
  return JBReplicationInfoGame(GetGameReplicationInfo()).firstTagCustom; }
protected simulated function InternalSetFirst(JBTag TagFirst) {
  JBReplicationInfoGame(GetGameReplicationInfo()).firstTagCustom = JBTagCustom(TagFirst); }
protected simulated function JBTag InternalGetNext() {
  return nextTag; }
protected simulated function InternalSetNext(JBTag TagNext) {
  nextTag = JBTagCustom(TagNext); }
*/


// ============================================================================
// Replication
// ============================================================================

replication {

  reliable if (Role == ROLE_Authority)
    Keeper, bIsRegisteredOnServer;
  }


// ============================================================================
// Variables
// ============================================================================

var private Actor Keeper;                // replicated keeper actor

var private bool bIsRegisteredOnServer;  // registered on the server
var private bool bIsRegisteredOnClient;  // registered on this client


// ============================================================================
// DestroyFor
//
// Finds and destroys the JBTag actor of the calling subclass associated with
// the given keeper. Does nothing if none is found.
// ============================================================================

static function DestroyFor(Actor Keeper) {

  local JBTag TagDestroy;
  
  TagDestroy = InternalFindFor(Keeper);
  if (TagDestroy != None)
    TagDestroy.Destroy();
  }


// ============================================================================
// GetGameReplicationInfo
//
// Returns a reference to the GameReplicationInfo actor.
// ============================================================================

simulated function GameReplicationInfo GetGameReplicationInfo() {

  if (Level.Game != None)
    return Level.Game.GameReplicationInfo;

  return Level.GetLocalPlayerController().GameReplicationInfo;
  }


// ============================================================================
// InternalFindFor
//
// Finds and returns a reference to the JBTag actor of the calling subclass
// associated with the given keeper. Client-side, if no item is found in the
// keeper actor's inventory, tries to find it with DynamicActors and registers
// it locally in the keeper's inventory on success. Otherwise returns None.
// ============================================================================

protected static function JBTag InternalFindFor(Actor Keeper) {

  local JBTag thisTag;
  local Inventory thisInventory;
  
  if (Keeper == None)
    return None;

  for (thisInventory = Keeper.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
    if (thisInventory.Class == Default.Class)
      return JBTag(thisInventory);
  
  if (Keeper.Role < ROLE_Authority)
    foreach Keeper.DynamicActors(Class'JBTag', thisTag)
      if (thisTag.Class == Default.Class &&
          thisTag.Keeper == Keeper)
        return thisTag.RegisterInInventory();
  
  return None;
  }


// ============================================================================
// InternalSpawnFor
//
// If the given keeper actor doesn't already possess a JBTag actor of the
// calling subclass, spawns one and returns a reference to it. Otherwise
// returns a reference to the existing item.
// ============================================================================

protected static function JBTag InternalSpawnFor(Actor Keeper) {

  local JBTag TagSpawned;
  
  if (Keeper == None)
    return None;
  
  TagSpawned = InternalFindFor(Keeper);
  if (TagSpawned == None)
    TagSpawned = Keeper.Spawn(Default.Class, Keeper);
  
  return TagSpawned;
  }


// ============================================================================
// InternalGetFirst
// InternalSetFirst
// InternalGetNext
// InternalSetNext
//
// Protected maintenance functions. Must be implemented in subclasses.
// ============================================================================

protected simulated function JBTag InternalGetFirst();
protected simulated function       InternalSetFirst(JBTag TagFirst);
protected simulated function JBTag InternalGetNext();
protected simulated function       InternalSetNext(JBTag TagNext);


// ============================================================================
// Register
//
// Registers this item both in the global linked list and in the keeper
// actor's inventory. Requires the item to be owned by its keeper actor before
// being called. Communicates the registration to all clients.
// ============================================================================

function Register() {

  if (bIsRegisteredOnServer || Owner == None)
    return;
  
  Keeper = Owner;
  
  RegisterInList();
  RegisterInInventory();
  
  bIsRegisteredOnServer = True;  // triggers PostNetReceive on clients
  }


// ============================================================================
// Unregister
//
// Unregisters this item from both the global linked list and the keeper
// actor's inventory. Communicates the unregistration to all clients.
// ============================================================================

function Unregister() {

  if (!bIsRegisteredOnServer)
    return;
  
  UnregisterFromList();
  UnregisterFromInventory();
  
  bIsRegisteredOnServer = False;  // triggers PostNetReceive on clients
  }


// ============================================================================
// RegisterInList
//
// Registers this item in the global linked list. Doesn't check whether the
// item is present there already and thus assumes that this isn't the case.
// Returns a reference to the item.
// ============================================================================

private simulated function JBTag RegisterInList() {

  InternalSetNext(InternalGetFirst());
  InternalSetFirst(Self);
  
  return Self;
  }


// ============================================================================
// RegisterInInventory
//
// Registers this item in its keeper actor's inventory. Doesn't check whether
// the item is present there already and thus assumes that this isn't the case.
// Returns a reference to the item.
// ============================================================================

private simulated function JBTag RegisterInInventory() {

  if (Keeper == None)
    return Self;
  
  Inventory = Keeper.Inventory;
  Keeper.Inventory = Self;
  
  return Self;
  }


// ============================================================================
// UnregisterFromList
//
// Removes this item from the global linked list.
// ============================================================================

private simulated function UnregisterFromList() {

  local JBTag thisTag;

  if (InternalGetFirst() == Self)
    InternalSetFirst(InternalGetNext());
  else
    for (thisTag = InternalGetFirst(); thisTag != None; thisTag = thisTag.InternalGetNext())
      if (thisTag.InternalGetNext() == Self)
        thisTag.InternalSetNext(InternalGetNext());
  }


// ============================================================================
// UnregisterFromInventory
//
// Removes this item from its keeper actor's inventory.
// ============================================================================

private simulated function UnregisterFromInventory() {

  local Inventory thisInventory;

  if (Keeper != None)
    if (Keeper.Inventory == Self)
      Keeper.Inventory = Inventory;
    else
      for (thisInventory = Keeper.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
        if (thisInventory.Inventory == Self)
          thisInventory.Inventory = Inventory;
  }


// ============================================================================
// BeginPlay
//
// Registers this item server-side. Client-side registration is taken care of
// by the PostNetReceive event.
// ============================================================================

event BeginPlay() {

  Register();
  }


// ============================================================================
// PostNetReceive
//
// Called when a replication update is received. Client-side, checks whether
// a change in the server-side registration change occurred and registers or
// unregisters the item accordingly.
// ============================================================================

simulated event PostNetReceive() {

  if (Role == ROLE_Authority || bIsRegisteredOnClient == bIsRegisteredOnServer)
    return;
  
  if (bIsRegisteredOnServer)
    GotoState('Registering');
  else {
    UnregisterFromList();
    UnregisterFromInventory();
    }

  bIsRegisteredOnClient = bIsRegisteredOnServer;
  }


// ============================================================================
// Destroyed
//
// Automatically unregisters this JBTag item.
// ============================================================================

simulated event Destroyed() {

  UnregisterFromList();
  UnregisterFromInventory();
  }


// ============================================================================
// state Registering
//
// Used for client-side registration of this actor. Waits until the
// GameReplicationInfo actor has been replicated and is available on the
// client, then registers itself.
// ============================================================================

simulated state Registering {

  Begin:
    while (GetGameReplicationInfo() == None)
      Sleep(0.0001);  // sleep for a tick

    RegisterInList();
    RegisterInInventory();

  } // state Registering


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  RemoteRole = ROLE_None;  // may be changed in subclasses

  bAlwaysRelevant = True;
  bNetNotify = True;
  bOnlyRelevantToOwner = False;
  bSkipActorPropertyReplication = True;
  NetUpdateFrequency = 10.0;
  }