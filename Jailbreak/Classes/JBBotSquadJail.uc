// ============================================================================
// JBBotSquadJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquadJail.uc,v 1.2 2003/01/01 22:11:16 mychaeel Exp $
//
// Controls the bots in jail.
// ============================================================================


class JBBotSquadJail extends DMSquad
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextJailed;


// ============================================================================
// CanFight
//
// Checks and returns whether the given player is currently carrying their
// primary default weapon and isn't scheduled for an upcoming arena fight.
// ============================================================================

static function bool CanFight(Pawn PawnOther, optional bool bCanSwitchWeapon) {

  local JBTagPlayer TagPlayer;
  
  if (PawnOther == None || !Class'Jailbreak'.Default.bEnableJailFights)
    return False;
  
  TagPlayer = Class'JBTagPlayer'.Static.FindFor(PawnOther.PlayerReplicationInfo);

  if (TagPlayer == None    ||
     !TagPlayer.IsInJail() ||
      TagPlayer.GetArenaPending() != None)
    return False;
  
  if (bCanSwitchWeapon)
    return True;
  
  return (PawnOther.Weapon != None &&
          PawnOther.Weapon.Class == PawnOther.Level.Game.BaseMutator.GetDefaultWeapon());
  }


// ============================================================================
// FriendlyToward
//
// Returns True for anybody except other players carrying their primary
// default weapon for jail fights.
// ============================================================================

function bool FriendlyToward(Pawn PawnOther) {

  return CanFight(PawnOther);
  }


// ============================================================================
// SetEnemy
//
// If the given player is ready to fight in jail, draw primary default weapon
// and acquire this player as an enemy.
// ============================================================================

function bool SetEnemy(Bot Bot, Pawn PawnEnemy) {

  if (CanFight(Bot.Pawn, True) &&
      CanFight(PawnEnemy) &&
      Super.SetEnemy(Bot, PawnEnemy)) {

    PawnEnemy.PendingWeapon = Weapon(PawnEnemy.FindInventoryType(Level.Game.BaseMutator.GetDefaultWeapon()));
  
    if (PawnEnemy.PendingWeapon == None ||
       !PawnEnemy.PendingWeapon.HasAmmo())
      return False;

    if (PawnEnemy.PendingWeapon == PawnEnemy.Weapon)
      return True;
  
    if (PawnEnemy.Weapon == None)
      PawnEnemy.ChangedWeapon();
    else
      PawnEnemy.Weapon.PutDown();
  
    return True;
    }
  
  else {
    return False;
    }
  }


// ============================================================================
// GetOrderStringFor
//
// Returns a string describing the given player's current status. That is,
// in this squad, simply jailed.
// ============================================================================

simulated function string GetOrderStringFor(TeamPlayerReplicationInfo TeamPlayerReplicationInfo) {

  return TextJailed;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextJailed = "jailed";
  }