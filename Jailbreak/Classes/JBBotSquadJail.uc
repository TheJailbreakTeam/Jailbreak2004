// ============================================================================
// JBBotSquadJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquadJail.uc,v 1.9 2003/02/26 20:01:30 mychaeel Exp $
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
// AddBot
//
// If the bot is currently following a scripted sequence, stops it.
// ============================================================================

function AddBot(Bot Bot) {

  Super.AddBot(Bot);

  Bot.FreeScript();
  TeamPlayerReplicationInfo(Bot.PlayerReplicationInfo).bHolding = False;
  }


// ============================================================================
// RemoveBot
//
// If the bot currently has an enemy, clears it. Prevents bots from starting
// to teamkill after a release during a jail fight.
// ============================================================================

function RemoveBot(Bot Bot) {

  Super.RemoveBot(Bot);
  Bot.Enemy = None;
  }


// ============================================================================
// SetEnemy
//
// If the given player is ready to fight in jail and there are no other
// players to fight with, draw primary default weapon and acquire this player
// as an enemy.
// ============================================================================

function bool SetEnemy(Bot Bot, Pawn PawnEnemy) {

  local Controller ControllerEnemy;
  local JBTagPlayer TagPlayerBot;
  local JBTagPlayer TagPlayerEnemy;
  
  if (!Jailbreak(Level.Game).bEnableJailFights)
    return False;
  
  ControllerEnemy = PawnEnemy.Controller;
  if (ControllerEnemy == None)
    return False;

  TagPlayerBot   = Class'JBTagPlayer'.Static.FindFor(Bot      .PlayerReplicationInfo);
  TagPlayerEnemy = Class'JBTagPlayer'.Static.FindFor(PawnEnemy.PlayerReplicationInfo);

  if (TagPlayerEnemy == None ||
      TagPlayerEnemy.GetJail() != TagPlayerBot.GetJail())
    return False;

  if (IsPlayerFighting(ControllerEnemy)) {
    if (IsPlayerFighting(Bot))
      return Super.SetEnemy(Bot, PawnEnemy);

    if (CanPlayerFight(Bot) && CountPlayersFighting(TagPlayerBot.GetJail()) < 2) {
      PrepareForFight(Bot);
      return Super.SetEnemy(Bot, PawnEnemy);
      }
    }

  if (Bot.Enemy == None && IsPlayerFighting(Bot))
    Bot.Pawn.SwitchToLastWeapon();

  return False;
  }


// ============================================================================
// CountPlayersFighting
//
// Counts the number of fighting players in the given jail.
// ============================================================================

static function int CountPlayersFighting(JBInfoJail Jail) {

  local int nPlayersFighting;
  local JBTagPlayer firstTagPlayer;
  local JBTagPlayer thisTagPlayer;
  
  firstTagPlayer = JBGameReplicationInfo(Jail.Level.Game.GameReplicationInfo).firstTagPlayer;
  for (thisTagPlayer = firstTagPlayer; thisTagPlayer != None; thisTagPlayer = thisTagPlayer.nextTag)
    if (thisTagPlayer.GetJail() == Jail &&
        IsPlayerFighting(thisTagPlayer.GetController()))
      nPlayersFighting += 1;

  return nPlayersFighting;
  }


// ============================================================================
// GetPrimaryWeaponFor
//
// Gets the given player's primary weapon, that is the non-discardable weapon
// in the lowest inventory slot.
// ============================================================================

static function Weapon GetPrimaryWeaponFor(Pawn Pawn) {

  local byte InventoryGroupSelected;
  local Inventory thisInventory;
  local Weapon WeaponSelected;

  for (thisInventory = Pawn.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
    if (Weapon(thisInventory) != None &&
       !Weapon(thisInventory).bCanThrow &&
       (WeaponSelected == None || InventoryGroupSelected > thisInventory.InventoryGroup)) {
     WeaponSelected = Weapon(thisInventory);
     InventoryGroupSelected = thisInventory.InventoryGroup;
     }

  return WeaponSelected;
  }


// ============================================================================
// CountWeaponsFor
//
// Counts the number of weapons in the given player's inventory.
// ============================================================================

static function int CountWeaponsFor(Pawn Pawn) {

  local int nWeapons;
  local Inventory thisInventory;

  for (thisInventory = Pawn.Inventory; thisInventory != None; thisInventory = thisInventory.Inventory)
    if (Weapon(thisInventory) != None)
      nWeapons += 1;

  return nWeapons;
  }


// ============================================================================
// CanPlayerFight
//
// Checks whether the given player is currently eligible for fighing.
// ============================================================================

static function bool CanPlayerFight(Controller Controller) {

  if (Controller      == None ||
      Controller.Pawn == None)
    return False;

  return (Bot(Controller) != None || IsPlayerFighting(Controller));
  }


// ============================================================================
// IsPlayerFighting
//
// Checks whether the given player is currently fighting or at least ready to
// fight, that is, has drawn their primary weapon and still the option to opt
// out by switching to a different weapon.
// ============================================================================

static function bool IsPlayerFighting(Controller Controller) {

  if (Controller      == None ||
      Controller.Pawn == None)
    return False;

  return (CountWeaponsFor(Controller.Pawn) > 1 &&
          GetPrimaryWeaponFor(Controller.Pawn) == Controller.Pawn.Weapon);
  }


// ============================================================================
// PrepareForFight
//
// Prepares the given bot for a fight by making it activate its primary
// weapon.
// ============================================================================

static function PrepareForFight(Bot Bot) {

  if (Bot      == None ||
      Bot.Pawn == None)
    return;

  Bot.Pawn.PendingWeapon = GetPrimaryWeaponFor(Bot.Pawn);

  if (Bot.Pawn.PendingWeapon == Bot.Pawn.Weapon)
    Bot.Pawn.PendingWeapon = None;
  if (Bot.Pawn.PendingWeapon == None)
    return;

  Bot.StopFiring();

  if (Bot.Pawn.Weapon == None)
    Bot.Pawn.ChangedWeapon();
  else if (Bot.Pawn.Weapon != Bot.Pawn.PendingWeapon)
    Bot.Pawn.Weapon.PutDown();
  }


// ============================================================================
// AssignSquadResponsibility
//
// Makes bots wander around unless they're currently engaged in a jail fight.
// ============================================================================

function bool AssignSquadResponsibility(Bot Bot) {

  if (Bot.Enemy != None) {
    if (IsPlayerFighting(Bot.Enemy.Controller))
      return Super.AssignSquadResponsibility(Bot);
    Bot.Enemy = None;
    }

  Bot.WanderOrCamp(False);
  return True;
  }


// ============================================================================
// GetOrderStringFor
//
// Returns a string describing the given player's current status. That is,
// in this squad, simply that they're jailed.
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