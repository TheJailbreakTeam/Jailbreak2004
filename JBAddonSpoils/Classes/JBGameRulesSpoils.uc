// ============================================================================
// JBAddonSpoils - original by TheForgotten
//
// Copyright 2004 by TheForgotten
//
// $Id$
//
// The rules for the Spoils add-on.
// ============================================================================


class JBGameRulesSpoils extends JBGameRules;


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena is given the weapon when freedom.
// ============================================================================

function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
  local xPawn Avenger;
  local class<Weapon> WeaponClass;
  local Weapon Spoils;
  local Inventory Inv;

  if (TagPlayerWinner != None &&
      (TagPlayerWinner.GetController() != None) &&
      (TagPlayerWinner.GetController().Pawn != None) &&
      (TagPlayerWinner.GetController().Pawn.IsA('xPawn'))) {
    WeaponClass = class'JBAddonSpoils'.default.SpoilsWeapon;
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