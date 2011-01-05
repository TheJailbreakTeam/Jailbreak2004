// ============================================================================
// JBFreezer
// Copyright 2005 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBFreezer.uc,v 1.1 2006-11-29 19:14:28 jrubzjeknf Exp $
//
// Spawned with a Pawn as its owner, freezes this pawn in place and kills it
// by shattering it after a few seconds.
// ============================================================================


class JBFreezer extends Weapon
  cacheexempt
  notplaceable;


// ============================================================================
// Replication
// ============================================================================

replication
{
  reliable if (Role == ROLE_Authority)
    PawnOwner;
}


// ============================================================================
// Types
// ============================================================================

struct TAnimState
{
  var name Sequence[4];
  var float Frame[4];
  var float Rate[4];
};


// ============================================================================
// Variables
// ============================================================================

var private Pawn PawnOwner;
var private Controller ControllerOwner;

var private Weapon Weapon;
var private Inventory InventorySaved;

var private JBEmitterFreeze EmitterFreeze;

var private TAnimState AnimStateOwner;
var private TAnimState AnimStateWeaponFirst;
var private TAnimState AnimStateWeaponThird;


// ============================================================================
// PostBeginPlay
//
// Replicates the owner and initiates self-destruction in a few seconds.
// ============================================================================

event PostBeginPlay()
{
  PawnOwner = Pawn(Owner);

  if (PawnOwner == None) {
    Destroy();
  }
  else {
    ControllerOwner = PawnOwner.Controller;
    if (Bot(ControllerOwner) != None)
      ControllerOwner.bStasis = True;

    SetTimer(4.0, False);
  }
}


// ============================================================================
// PostNetBeginPlay
//
// Freezes the player, copies rendering-relevant properties of their weapon to
// itself and replaces the weapon by itself to prevent any further changing of
// the weapon. Spawns the visual and audible freeze-and-shatter effects.
// ============================================================================

simulated function PostNetBeginPlay()
{
  FreezeAnim(PawnOwner, AnimStateOwner);

  if (PawnOwner.Controller != None)
    PawnOwner.Controller.GotoState('');

  Weapon         = PawnOwner.Weapon;
  InventorySaved = PawnOwner.Inventory;

  if (Weapon != None) {
    FreezeAnim(Weapon,                  AnimStateWeaponFirst);
    FreezeAnim(Weapon.ThirdPersonActor, AnimStateWeaponThird);

    IconMaterial           = Weapon.IconMaterial;
    IconCoords             = Weapon.IconCoords;
    DisplayFOV             = Weapon.DisplayFOV;
    bShowChargingBar       = Weapon.bShowChargingBar;
    CustomCrossHairTexture = Weapon.CustomCrossHairTexture;
    CustomCrossHairColor   = Weapon.CustomCrossHairColor;
    CustomCrossHairScale   = Weapon.CustomCrossHairScale;
    ThirdPersonActor       = Weapon.ThirdPersonActor;
  }

  PawnOwner.Weapon        = Self;
  PawnOwner.Inventory     = Self;
  PawnOwner.PendingWeapon = None;

  EmitterFreeze = Spawn(Class'JBEmitterFreeze', PawnOwner);
}


// ============================================================================
// FreezeAnim
//
// Freezes an actor's animation and stores its current state.
// ============================================================================

simulated function FreezeAnim(Actor Actor, out TAnimState AnimState)
{
  local int iChannel;

  if (Actor == None)
    return;

  for (iChannel = 0; iChannel < ArrayCount(AnimState.Sequence); iChannel++) {
    Actor.GetAnimParams(iChannel, AnimState.Sequence[iChannel], AnimState.Frame[iChannel], AnimState.Rate[iChannel]);
    Actor.FreezeAnimAt(0.0, iChannel);
  }
}


// ============================================================================
// RestoreAnim
//
// Restores an actor's animation to a state previously frozen by FreezeAnim.
// ============================================================================

simulated function RestoreAnim(Actor Actor, TAnimState AnimState, optional bool bKeepFrozen)
{
  local int iChannel;

  if (Actor == None)
    return;

  for (iChannel = 0; iChannel < ArrayCount(AnimState.Sequence); iChannel++) {
    if (AnimState.Sequence[iChannel] == 'None')
      continue;

    if (bKeepFrozen)
           Actor.PlayAnim(AnimState.Sequence[iChannel], 0.0,                      , iChannel);
      else Actor.PlayAnim(AnimState.Sequence[iChannel], AnimState.Rate[iChannel], , iChannel);

    Actor.SetAnimFrame(AnimState.Frame[iChannel], iChannel);
  }
}


// ============================================================================
// Tick
//
// Keeps the player and weapon animation frozen in the state it had when the
// player was frozen, and keeps the player frozen in place.
// ============================================================================

simulated event Tick(float TimeDelta)
{
  RestoreAnim(PawnOwner, AnimStateOwner, True);

  if (Weapon != None) {
    RestoreAnim(Weapon,                  AnimStateWeaponFirst, True);
    RestoreAnim(Weapon.ThirdPersonActor, AnimStateWeaponThird, True);
  }

  if (PawnOwner.Physics != PHYS_Falling) {
    PawnOwner.Velocity     = vect(0,0,0);
    PawnOwner.Acceleration = vect(0,0,0);
  }
}


// ============================================================================
// Timer
//
// Destroys its owner and then itself.
// ============================================================================

event Timer()
{
  Owner.Destroy();
  Destroy();
}


// ============================================================================
// Destroyed
//
// Restores the original inventory chain to make sure that all inventory is
// properly destroyed.
// ============================================================================

event Destroyed()
{
  if (Bot(ControllerOwner) != None)
    ControllerOwner.bStasis = False;

  Inventory = InventorySaved;
  Super.Destroyed();
}


// ============================================================================
// The following overrides prevent the player from switching weapons.
// ============================================================================


simulated function Weapon PrevWeapon(Weapon WeaponChoice, Weapon WeaponCurrent)
{
  return None;
}


simulated function Weapon NextWeapon(Weapon WeaponChoice, Weapon WeaponCurrent)
{
  return None;
}


simulated function Weapon WeaponChange(byte Group, bool bSilent)
{
  return Self;
}


simulated function Weapon RecommendWeapon(out float Rating)
{
  return Self;
}


function HolderDied()
{
  // do nothing
}


// ============================================================================
// The following overrides forward HUD-related queries to the weapon the
// player originally carried before being frozen.
// ============================================================================


simulated function SetOverlayMaterial(Material MaterialOverlay, float TimeOverlay, bool bOverride)
{
  if (Weapon != None)
    Weapon.SetOverlayMaterial(MaterialOverlay, TimeOverlay, bOverride);
}


simulated function RenderOverlays(Canvas Canvas)
{
  if (Weapon != None)
    Weapon.RenderOverlays(Canvas);

  if (EmitterFreeze != None)
    EmitterFreeze.RenderOverlays(Canvas);
}


simulated function class<Ammunition> GetAmmoClass(int Mode)
{
  if (Weapon != None)
    return Weapon.GetAmmoClass(Mode);

  return None;
}


simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
  if (Weapon != None)
    Weapon.GetAmmoCount(MaxAmmoPrimary, CurAmmoPrimary);
}


simulated function DrawWeaponInfo(Canvas Canvas)
{
  if (Weapon != None)
    Weapon.DrawWeaponInfo(Canvas);
}


simulated function NewDrawWeaponInfo(Canvas Canvas, float PosY)
{
  if (Weapon != None)
    Weapon.NewDrawWeaponInfo(Canvas, PosY);
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  bOnlyRelevantToOwner=False
  bAlwaysRelevant=True
}
