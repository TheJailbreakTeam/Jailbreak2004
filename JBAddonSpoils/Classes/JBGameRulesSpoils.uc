// ============================================================================
// JBAddonSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id: JBGameRulesSpoils.uc,v 1.2 2007-05-12 23:11:54 wormbo Exp $
//
// The rules for the Spoils add-on.
// ============================================================================


class JBGameRulesSpoils extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================

var class<Weapon> WeaponClass;


// ============================================================================
// PostBeginPlay
//
// Register the additional rules.
// ============================================================================

function PostBeginPlay()
{
  Super.PostBeginPlay();

  WeaponClass = class<Weapon>(DynamicLoadObject(class'JBAddonSpoils'.default.SpoilsWeapon, class'Class'));
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

  if (TagPlayerWinner != None &&
      (TagPlayerWinner.GetController() != None) &&
      (TagPlayerWinner.GetController().Pawn != None) &&
      (TagPlayerWinner.GetController().Pawn.IsA('xPawn'))) {
    Avenger = xPawn(TagPlayerWinner.GetController().Pawn);

    Spoils = Spawn( WeaponClass, Avenger );
    Spoils.GiveTo(Avenger);

    for (Inv = Avenger.Inventory; Inv != None; Inv = Inv.Inventory)
      if (Inv.name == WeaponClass.name) {
        Weapon(Inv).Loaded();

        if (class'JBAddonSpoils'.default.bMaxAmmo)
          Weapon(Inv).MaxOutAmmo();

        Weapon(Inv).bCanThrow = class'JBAddonSpoils'.default.bCanThrow;
        Avenger.ReceiveLocalizedMessage(class'JBLocalMessageSpoils',,,,Weapon(Inv));
      }

      TagPlayerWinner.GetController().ClientSetWeapon(WeaponClass);
    }

  Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}