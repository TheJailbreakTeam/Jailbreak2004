// ============================================================================
// JBBotSquadJail
// Copyright 2002 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBBotSquadJail.uc,v 1.13 2004/01/01 20:09:51 mychaeel Exp $
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
// Variables
// ============================================================================

var float TimeStartFighting;  // delay bot engaging in jail fight


// ============================================================================
// AddBot
//
// If the bot is currently following a scripted sequence, stops it.
// ============================================================================

function AddBot(Bot Bot)
{
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

function RemoveBot(Bot Bot)
{
  StopFighting(Bot, True);
  Super.RemoveBot(Bot);
}


// ============================================================================
// NotifyKilled
//
// If the killed bot is on this squad, makes it stop jail-fighting.
// ============================================================================

function NotifyKilled(Controller ControllerKiller, Controller ControllerVictim, Pawn PawnVictim)
{
  if (IsOnSquad(ControllerVictim))
    StopFighting(Bot(ControllerVictim));

  Super.NotifyKilled(ControllerKiller, ControllerVictim, PawnVictim);
}


// ============================================================================
// SetEnemy
//
// If the given player is ready to fight in jail and there are no other
// players to fight with, draw primary default weapon and acquire this player
// as an enemy.
// ============================================================================

function bool SetEnemy(Bot Bot, Pawn PawnEnemy)
{
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

    if (Bot(ControllerEnemy) == None &&
        CanPlayerFight(Bot)          &&
        CountPlayersFighting(TagPlayerBot.GetJail()) < 2) {

      if (TimeStartFighting == 0.0)
        TimeStartFighting = Level.TimeSeconds + RandRange(1.0, 3.0);

      if (TimeStartFighting > Level.TimeSeconds)
        return False;
      StartFighting(Bot);
      return Super.SetEnemy(Bot, PawnEnemy);
    }

    TimeStartFighting = 0.0;
  }

  if (Bot.Enemy == None && IsPlayerFighting(Bot))
    StopFighting(Bot, True);

  return False;
}


// ============================================================================
// CountPlayersFighting
//
// Counts the number of fighting players in the given jail.
// ============================================================================

static function int CountPlayersFighting(JBInfoJail Jail)
{
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

static function Weapon GetPrimaryWeaponFor(Pawn Pawn)
{
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

static function int CountWeaponsFor(Pawn Pawn)
{
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

static function bool CanPlayerFight(Controller Controller)
{
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

static function bool IsPlayerFighting(Controller Controller)
{
  local Weapon WeaponPrimary;

  if (Controller      == None ||
      Controller.Pawn == None)
    return False;

  if (CountWeaponsFor(Controller.Pawn) <= 1)
    return False;

  WeaponPrimary = GetPrimaryWeaponFor(Controller.Pawn);

  return (WeaponPrimary == Controller.Pawn.Weapon ||
          WeaponPrimary == Controller.Pawn.PendingWeapon);
}


// ============================================================================
// StartFighting
//
// Makes the given bot start jail-fighting with its primary weapon.
// ============================================================================

static function StartFighting(Bot Bot)
{
  local JBInventoryJail InventoryJail;

  if (Bot      == None ||
      Bot.Pawn == None)
    return;

  InventoryJail = JBInventoryJail(Bot.Pawn.FindInventoryType(Class'JBInventoryJail'));

  if (InventoryJail == None) {
    InventoryJail = Bot.Pawn.Spawn(Class'JBInventoryJail');
    InventoryJail.GiveTo(Bot.Pawn);
  }

  InventoryJail.WeaponRecommended = GetPrimaryWeaponFor(Bot.Pawn);

  Bot.Aggressiveness = 10.0;
  Bot.SwitchToBestWeapon();
}


// ============================================================================
// StopFighting
//
// Makes the given bot stop jail-fighting. Optionally also tries to switch the
// bot's weapon back to its previous weapon.
// ============================================================================

static function StopFighting(Bot Bot, optional bool bSwitchWeapon)
{
  local JBInventoryJail InventoryJail;

  if (JBBotSquadJail(Bot.Squad) != None)
    JBBotSquadJail(Bot.Squad).TimeStartFighting = 0.0;

  Bot.LoseEnemy();
  Bot.Aggressiveness = Bot.BaseAggressiveness;

  if (Bot.Pawn == None)
    return;

  InventoryJail = JBInventoryJail(Bot.Pawn.FindInventoryType(Class'JBInventoryJail'));
  if (InventoryJail != None)
    InventoryJail.Destroy();

  if (bSwitchWeapon)
    Bot.Pawn.SwitchToLastWeapon();
}


// ============================================================================
// AssignSquadResponsibility
//
// Makes bots wander around unless they're currently engaged in a jail fight.
// ============================================================================

function bool AssignSquadResponsibility(Bot Bot)
{
  if (Bot.Enemy != None) {
    if (IsPlayerFighting(Bot.Enemy.Controller))
      return Super.AssignSquadResponsibility(Bot);
    StopFighting(Bot);
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

simulated function string GetOrderStringFor(TeamPlayerReplicationInfo TeamPlayerReplicationInfo)
{
  return TextJailed;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TextJailed = "jailed";
}