// ============================================================================
// JBMutator
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBMutator.uc,v 1.2 2006-12-20 22:13:37 jrubzjeknf Exp $
//
// Jailbreak's base mutator.
// ============================================================================


class JBMutator extends DMMutator
  HideDropDown
  CacheExempt;


// ============================================================================
// Variables
// ============================================================================

var array<String> VariableNames;


// ============================================================================
// AddMutator
//
// Checks if the added mutator is an Arena mutator like Instagib.
// ============================================================================

function AddMutator(Mutator M)
{
  Super.AddMutator(M);

   if (M != None && M.GroupName ~= "Arena")
     Jailbreak(Level.Game).bArenaMutatorActive = True;
}


// ============================================================================
// AlwaysKeep
//
// Prevents the ShieldGun from being deleted from a user's inventory by an
// Arena mutator when it's added in prison.
// ============================================================================

function bool AlwaysKeep(Actor Other)
{
  local JBTagPlayer TagPlayer;

  if (Jailbreak(Level.Game).bArenaMutatorActive &&
      Jailbreak(Level.Game).bEnableJailFights &&
      Weapon(Other) != None &&
     !Weapon(Other).bCanThrow &&
      Weapon(Other).bMeleeWeapon &&
      Other.Instigator != None &&
      Other.Instigator.PlayerReplicationInfo != None) {
    TagPlayer = class'JBTagPlayer'.static.FindFor(Other.Instigator.PlayerReplicationInfo);
    return TagPlayer.IsInJail() || Super.AlwaysKeep(Other);
  }

  return Super.AlwaysKeep(Other);
}


// ============================================================================
// CheckReplacement
//
// All sentinels are passed through this function. Checks if we want to
// replace it with our own.
// ============================================================================

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
  if (ASVehicleFactory(Other) != None &&
      Mid(Other, InStr(Level, ".")+1, 37) ~= "ASVehicleFactory_SentinelCeiling_Proj") {
    ReplaceSentinelFactory(Other);
    return False;
  }

  return True;
}


// ============================================================================
// ReplaceSentinelFactory
//
// Stop the current factory from spawning sentinels, spawn our own factory and
// copy the custom variables.
// ============================================================================

function ReplaceSentinelFactory(Actor OldFactory)
{
  local class<Actor> NewFactoryClass;
  local Actor NewFactory;
  local int i;

  // Prevent the old factory from spawning more sentinels.
  SVehicleFactory(OldFactory).VehicleClass = None;

  // Spawn our own sentinel fctory.
  NewFactoryClass = class<Actor>(DynamicLoadObject("JBToolbox2.JBSentinelCeilingFactory", class'Class'));
  NewFactory = Spawn(NewFactoryClass,, OldFactory.Tag, OldFactory.Location, OldFactory.Rotation);

  // Copy the custom variables.
  for (i=0; i<VariableNames.length; ++i)
    NewFactory.SetPropertyText(VariableNames[i], OldFactory.GetPropertyText(VariableNames[i]));
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  VariableNames(0) = "bSleepWhenDisabled"
  VariableNames(1) = "ProjectileClass"
  VariableNames(2) = "ProjectileSpawnOffset"
  VariableNames(3) = "FireRate"
  VariableNames(4) = "FireSound"
  VariableNames(5) = "AttachmentClass"
  VariableNames(6) = "FlashEmitterClass"
  VariableNames(7) = "SmokeEmitterClass"
}
