// ============================================================================
// JBAddonSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id: JBGameRulesSpoils.uc,v 1.3 2008-05-01 12:17:46 wormbo Exp $
//
// The rules for the Spoils add-on.
// ============================================================================


class JBGameRulesSpoils extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var class<Weapon> WeaponClass;
var bool bMaxAmmo, bCanThrow;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  WeaponClass = class<Weapon>(DynamicLoadObject(class'JBAddonSpoils'.default.SpoilsWeapon, class'Class'));
  if (WeaponClass != None)
    AddToPackageMap(string(WeaponClass.Outer));
  
  bMaxAmmo = class'JBAddonSpoils'.default.bMaxAmmo;
  bCanThrow = class'JBAddonSpoils'.default.bCanThrow;
}


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena is given the weapon when freedom.
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
  local xPawn Avenger;
  local Weapon Spoils;
  local Inventory Inv;

  if (WeaponClass != None && TagPlayerWinner != None &&
      TagPlayerWinner.GetController() != None &&
      xPawn(TagPlayerWinner.GetController().Pawn) != None)
  {
    Avenger = xPawn(TagPlayerWinner.GetController().Pawn);

    Spoils = Spawn(WeaponClass, Avenger);
    Spoils.GiveTo(Avenger);

    for (Inv = Avenger.Inventory; Inv != None; Inv = Inv.Inventory)
      if (Inv.name == WeaponClass.Name) {
        Weapon(Inv).Loaded();

        if (bMaxAmmo)
          Weapon(Inv).MaxOutAmmo();

        Weapon(Inv).bCanThrow = bCanThrow;
        Avenger.ReceiveLocalizedMessage(class'JBLocalMessageSpoils',,,,Weapon(Inv));
      }

    TagPlayerWinner.GetController().ClientSetWeapon(WeaponClass);
  }

  Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}