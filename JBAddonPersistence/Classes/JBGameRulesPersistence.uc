// ============================================================================
// JBGameRulesPersistence
// Copyright 2006 by Mitchell Davis <mitchelld02@yahoo.com>
//
// The game rules to allow weapons and other attributes to transfer over
// into the next round.
// ============================================================================

class JBGameRulesPersistence extends JBGameRules
      config
      CacheExempt;

// ============================================================================
// Structures
// ============================================================================
struct TPersistWeapons
{
  var class<Weapon> PersistentWeapon;
  var int PrimaryAmmo;
  var int SecondaryAmmo;
};

struct TPersistence
{
  var string Owner;
  var int Adrenaline;
  var int Score;
  var int Rank;      //This will be used when carrying over weapons
  var bool bWasJailed;
  var array<TPersistWeapons> WeaponList;
};

// ============================================================================
// Variables
// ============================================================================
var private array<TPersistence> CapturerList, CapturedList;
var private TeamInfo CapturedTeam;
var private int NumCapturers, NumCaptured;
var private bool bNewRound;   //When a new round starts, set to true
var private bool bUprising;   //Give the losing team the winner's weapons
var private int nHealth;      //The ammount of health to transfer

// ============================================================================
// Functions
// ============================================================================

// ============================================================================
// PreBeginPlay
//
// This function will be called on level start-up. This will initialize all
// values and set the timer.
// ============================================================================
function PreBeginPlay()
{
  NumCapturers = 0;
  NumCaptured = 0;
  bNewRound = false;
  bUprising = class'JBAddonPersistence'.default.bUprising;
  nHealth = class'JBAddonPersistence'.default.nHealth;
  SetTimer(0.5, true);
  Super.PreBeginPlay();
}

// ============================================================================
// Timer
//
// This function is called every second to determine if a new round has
// started. The reason for this approach is because in the function
// NotifyRound, each Controller's Pawn has not been created at that point.
// Using this approach allows the Pawns to be created so that their weapons
// may be carried over.
// ============================================================================
function Timer()
{
  local Controller t;

  if(bNewRound && (NumCapturers > 0 || NumCaptured > 0))
  {
    SortListByScore(CapturerList, 0, NumCapturers);
    SortListByScore(CapturedList, 0, NumCaptured);
    for(t = Level.ControllerList; t != None; t = t.nextController)
    {
      //loop through each controller's pawn and find one that is a player
      if(t.Pawn != None && t.Pawn.GetHumanReadableName() ~= CapturerList[0].Owner)
      {
        //once we find a pawn, carry over all weapons for that player.
        CarryOverWeapons();
        CleanUpArray();
        bNewRound = false;
        break;
      }
    }
  }

  Super.Timer();
}

// ============================================================================
// NotifyExecutionEnd
//
// Called when the execution sequence has been completed, directly before the
// next round starts.
// ============================================================================
function NotifyExecutionEnd()
{
  bNewRound = true;

  Super.NotifyExecutionEnd();
}

// ============================================================================
// NotifyPlayerJailed
//
// Called when a player enters a jail, for instance by being spawned there
// after being killed, or by being sent there after losing an arena fight, or
// by simply physically walking into it.
// ============================================================================
function NotifyPlayerJailed(JBTagPlayer TagPlayer)
{
  local JBTagTeam thisTeam;

  thisTeam = class'JBTagTeam'.static.FindFor(TagPlayer.GetTeam());

  if(thisTeam.CountPlayersJailed() == thisTeam.CountPlayersTotal())
  {
    ExtractPlayers(thisTeam.GetTeam());
  }

  Super.NotifyPlayerJailed(TagPlayer);
}

// ============================================================================
// ExtractPlayers
//
// This function will extract the pawns associated with the capturing team and
// retrieve their inventory. This information will be recorded into a
// structure to easily handle moving over inventory to the next round.
//
// The new version now extracts not only the capturing players, but also the
// captured players.
// ============================================================================
function ExtractPlayers(TeamInfo Team)
{
  local Controller thisController;

  CapturedTeam = Team;  //Keep track of which team was the captured team for
                        //health transfer.

  for(thisController = Level.ControllerList; thisController != None; thisController = thisController.NextController)
  {
    if((thisController.PlayerReplicationInfo != None) &&
       (thisController.PlayerReplicationInfo.Team != Team))
    {
      AddToCapturingList(thisController);
    }
    else if((thisController.PlayerReplicationInfo != None) &&
            (thisController.PlayerReplicationInfo.Team == Team))
    {
      AddToCapturedList(thisController);
    }
  }
}

// ============================================================================
// CarryOverWeapons
//
// Runs through the list of controllers on this level to determine who was on
// the capturing team in the previous round. If they were on that team, they
// will receive their inventory back.
// ============================================================================
function CarryOverWeapons()
{
  local int i, j;
  local int Count;  //Use this to keep track of which capturing players' weapons
                    //we are handing over to the captured players.
  local Controller thisController;

  Count = 0;
  //Make sure a new round has started.
  if(bNewRound)
  {
    for(thisController = Level.ControllerList; thisController != None; thisController = thisController.nextController)
    {
      TransferHealth(thisController);
      //if not bUprising, then don't transfer weapons to opposing team
      if(!bUprising)
      {
        for(i = 0; i < CapturerList.Length; i++)
        {
          if((thisController.Pawn != None) &&
             (thisController.Pawn.GetHumanReadableName() ~= CapturerList[i].Owner))
          {
            //We will set the adrenaline first
            SetAdrenaline(thisController, CapturerList[i].Adrenaline);
            //Loop through all the weapons in the structure array and add them
            //to the Pawn.
            for(j = 0; j < CapturerList[i].WeaponList.Length - 1; j++)
            {
              PersistWeapon(thisController.Pawn, CapturerList[i].WeaponList[j]);
            }
          }
        }
      }
      else //if bUprising is set to true, then transfer weapons over
      {
        for(i = CapturedList.Length - 1; i >= 0; i--)
        {
          if((thisController.Pawn != None) &&
             (thisController.Pawn.GetHumanReadableName() ~= CapturedList[i].Owner))
          {
            //this is used in case teams are unbalanced.
            if(Count >= CapturerList.Length - 1)
              Count = 0;
            for(j = 0; j < CapturerList[Count].WeaponList.Length - 1; j++)
            {
              PersistWeapon(thisController.Pawn, CapturerList[Count].WeaponList[j]);
            }
            Count++;
          }
        }
      }
    }
  }

  bNewRound = false;
}

// ============================================================================
// SetAdrenaline
//
// This function will set the current controller's adrenaline to the amount
// available from the previous round. The game already handles this, but in the
// case where a player is in mid Combo, this will make sure that the player
// receives what is left of the combo.
// ============================================================================
function bool SetAdrenaline(Controller C, int Adrenaline)
{
  C.Adrenaline = Adrenaline;

  return true;
}

// ============================================================================
// PersistWeapon
//
// This function will spawn the weapon and add the weapon to the Pawn's
// inventory.
// ============================================================================
function bool PersistWeapon(Pawn P, TPersistWeapons Weapon)
{
  local Weapon W;
  local Inventory Inv;

  if(Weapon.PersistentWeapon == None)
    return false;

  W = P.Spawn(Weapon.PersistentWeapon);

  if(W == None)
    return false;

  //if the weapon is the assault rifle, consume all ammo first, then add
  //ammunition from the Weapon structure.
  if(W.Class == class'XWeapons.AssaultRifle')
  {
    for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
    {
      if(Inv.Class == class'XWeapons.AssaultRifle')
      {
        Weapon(Inv).ConsumeAmmo(0, 100);
        Weapon(Inv).ConsumeAmmo(1, 4);
        Weapon(Inv).AddAmmo(Weapon.PrimaryAmmo, 0);
        Weapon(Inv).AddAmmo(Weapon.SecondaryAmmo, 1);
      }
    }
  }
  //If the weapon is the shield gun or the translocator,
  //don't add it to the inventory
  else if((W.Class == class'XWeapons.ShieldGun') ||
          (W.Class == class'XWeapons.TransLauncher'))
  {
    return true;
  }
  else
  {
    W.AddAmmo(Weapon.PrimaryAmmo, 0);
    W.ClientWeaponSet(true);    //Prevent weapons to appear funky on next round
    P.AddInventory(W);
  }

  return true;
}

// ============================================================================
// TransferHealth
//
// Adds health to the captured players and takes away health from the
// capturing players.
// Param:    C - The current controller to add or subtract health from.
// ============================================================================
function TransferHealth(Controller C)
{
  //Check for replication info
  if(C.PlayerReplicationInfo == None)
    return;

  //If the current controller was not on the captured team,
  //take away health
  if((C.Pawn != None) && (C.PlayerReplicationInfo.Team != CapturedTeam))
  {
    C.Pawn.Health -= nHealth;
  }
  //If the current controller was on the captured team, add health
  else if((C.Pawn != None) && (C.PlayerReplicationInfo.Team == CapturedTeam))
  {
    C.Pawn.Health += nHealth;
  }
}

// ============================================================================
// AddToCapturingList
//
// Adds information about the capturing pawns into the TPersistance structure
// to carry over into the next round.
// Param:    Capturer - The controller that is on the capturing team.
//                      Used to extract adrenaline.
// ============================================================================
function AddToCapturingList(Controller Capturer)
{
  local int i;
  local Pawn P;
  local Inventory Inv;
  local JBTagPlayer TagPlayer; //Used to determine if capturer was in jail
                               //at time of winning

  if(Capturer == None || Capturer.Pawn == None)
    return;

  P = Capturer.Pawn;

  TagPlayer = class'JBTagPlayer'.static.FindFor(Capturer.PlayerReplicationInfo);
  //If tag player is in jail, then do not add that player to the list.
  //The player won't have any weapons of use for the losing team.
  if(TagPlayer.IsInJail())
    return;

  CapturerList.Insert(NumCapturers, 1);
  CapturerList[NumCapturers].Owner = P.GetHumanReadableName();
  CapturerList[NumCapturers].Adrenaline = Capturer.Adrenaline;
  CapturerList[NumCapturers].Score = Capturer.PlayerReplicationInfo.Score;

  //Loop through the inventory list and extract all inventory that are weapons
  i = 0;
  for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
  {
    if((Inv != None) &&
       (Inv.IsA('Weapon')))
    {
      //If we insert one element at i and try to access that element, we get
      //Accessed None warnings.
      //For some odd reason, if we insert two elements at i, everything is fine.
      //Need to investigate furthur.
      CapturerList[NumCapturers].WeaponList.Insert(i, 2);
      CapturerList[NumCapturers].WeaponList[i].PersistentWeapon = Weapon(Inv).Class;
      CapturerList[NumCapturers].WeaponList[i].PrimaryAmmo = Weapon(Inv).AmmoAmount(0);
      CapturerList[NumCapturers].WeaponList[i].SecondaryAmmo = Weapon(Inv).AmmoAmount(1);
    }
    i++;
  }

  NumCapturers++;     //Increment array
}

// ============================================================================
// AddToCapturedList
//
// Adds information about the captured pawn to the list.
// Param:    Captured - The controller that is on the captured team.
// ============================================================================
function AddToCapturedList(Controller Captured)
{
  local Pawn P;

  if(Captured == None || Captured.Pawn == None)
    return;

  P = Captured.Pawn;

  CapturedList.Insert(NumCaptured, 1);
  CapturedList[NumCaptured].Owner = P.GetHumanReadableName();
  CapturedList[NumCaptured].Score = Captured.PlayerReplicationInfo.Score;

  NumCaptured++;
}

// ============================================================================
// SortListByScore
//
// Sort the list in ascending order based on the score. The algorithm used is
// insertion sort.
// Param:    Team - The current list to sort.
//           LowerBound - The lower bound of the sort
//           UpperBound - The upper bound of the sort
// ============================================================================
function SortListByScore(out array<TPersistence> Team, int LowerBound, int UpperBound)
{
  local int i, j, Index;
  local TPersistence Temp;

  for(i = LowerBound + 1; i < UpperBound; ++i)
  {
    Index = i;
    j = i;
    while(j > 0)
    {
      if(Team[j - 1].Score < Team[Index].Score)
      {
        Temp = Team[j - 1];
        Team[j - 1] = Team[Index];
        Team[Index] = Temp;
        Index = j - 1;
      }
      --j;
    }
  }
}

// ============================================================================
// CleanUpArray
//
// Empty out the array each round.
// ============================================================================
function CleanUpArray()
{
  if(CapturerList.Length > 0)
  {
    CapturerList.Remove(0, CapturerList.Length);
    NumCapturers = 0;
  }
  if(CapturedList.Length > 0)
  {
    CapturedList.Remove(0, CapturedList.Length);
    NumCaptured = 0;
  }
}

defaultproperties
{
}
