// ============================================================================
// JBGUIHook
// Copyright 2004 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// Hidden actor which hooks into the menu system in order to make the
// Jailbreak theme music and the add-ons tab work.
// ============================================================================


class JBGUIHook extends Actor
  notplaceable;


// ============================================================================
// Localization
// ============================================================================

var localized string TextCaptionGoalScore;
var localized string TextCaptionAddons;
var localized string TextHintAddons;


// ============================================================================
// Variables
// ============================================================================

var private bool bIsHooked;  // default of this flag is set when hook placed

var string SongJailbreak;    // name of the Jailbreak theme song
var string SongPrev;         // name of the previously played song

var private UT2K4GamePageBase UT2K4GamePageBase;
var private GUITabPanel GUITabPanelAddons;


// ============================================================================
// Hook
//
// Hooks into the menu system unless the hook is in place already.
// ============================================================================

static function Hook()
{
  local UT2K4GamePageBase UT2K4GamePageBase;
  local JBGUIHook Hook;
  
  if (Default.bIsHooked)
    return;

  foreach Default.Class.AllObjects(Class'UT2K4GamePageBase', UT2K4GamePageBase)
    break;

  if (UT2K4GamePageBase == None)
    return;

  Hook = UT2K4GamePageBase.PlayerOwner().Spawn(Default.Class);
  Hook.Init(UT2K4GamePageBase);

  Default.bIsHooked = True;
}


// ============================================================================
// Init
//
// Initializes an object of this class by pointing a delegate to it.
// ============================================================================

function Init(UT2K4GamePageBase aUT2K4GamePageBase)
{
  UT2K4GamePageBase = aUT2K4GamePageBase;
  UT2K4GamePageBase.p_Game.OnChangeGameType = ChangeGameType;
  UT2K4GamePageBase.OnClose = Close;

  NotifyEntered();
}


// ============================================================================
// Unhook
//
// Cleans up and unhooks from the menu system by destroying the actor.
// ============================================================================

function Unhook()
{
  NotifyLeft();
  Destroy();

  UT2K4GamePageBase.p_Game.OnChangeGameType = UT2K4GamePageBase.ChangeGameType;
  UT2K4GamePageBase.OnClose = None;
}


// ============================================================================
// ChangeGameType
//
// Called by the menu system when the user changes game types. Unhooks and
// calls 
// ============================================================================

function ChangeGameType(bool bIsCustom)
{
  Unhook();
  UT2K4GamePageBase.ChangeGameType(bIsCustom);
}


// ============================================================================
// Close
//
// Called when the menu is closed. Unhooks.
// ============================================================================

function Close(optional bool bCancelled)
{
  Unhook();
}


// ============================================================================
// Destroyed
//
// Resets the shared flag which indicates that the hook is in place.
// ============================================================================

event Destroyed()
{
  Default.bIsHooked = False;
}


// ============================================================================
// NotifyEntered
//
// Called when the hook is placed, that is, when the user enters this game
// type. Starts the custom menu music and adds the Add-Ons tab.
// ============================================================================

function NotifyEntered()
{
  SongPrev = PlaySong(SongJailbreak, 2.0, 0.0);
  if (SongPrev == "")
    SongPrev = Class'UT2K4MainMenu'.Default.MenuSong;

  GUITabPanelAddons = UT2K4GamePageBase.c_Tabs.AddTab(
    TextCaptionAddons, "Jailbreak.JBGUITabPanelAddons", , TextHintAddons);

  UT2K4GamePageBase.c_Tabs.TabStack.Remove(UT2K4GamePageBase.c_Tabs.TabStack.Length - 1, 1);
  UT2K4GamePageBase.c_Tabs.TabStack.Insert(3, 1);
  UT2K4GamePageBase.c_Tabs.TabStack[3] = GUITabPanelAddons.MyButton;
}


// ============================================================================
// NotifyLeft
//
// Called when the hook is removed, that is, when the user leaves this game
// type. Ends the custom menu music and removes the Add-Ons tab.
// ============================================================================

function NotifyLeft()
{
  PlaySong(SongPrev, 1.0, 2.0);

  if (GUITabPanelAddons != None)
    UT2K4GamePageBase.c_Tabs.RemoveTab(TextCaptionAddons);
}


// ============================================================================
// PlaySong
//
// Starts playing the given song, cross-fading the current and the new song if
// desired. Returns the name of the previously played song.
// ============================================================================

function string PlaySong(string Song, optional float TimeFadeOut, optional float TimeFadeIn)
{
  local string SongPrev;
  local PlayerController PlayerController;
  
  PlayerController = UT2K4GamePageBase.PlayerOwner();
  SongPrev = PlayerController.Song;  

  if (Song == "" ||
      Song ~= SongPrev)
    return SongPrev;

  PlayerController.Song = Song;
  PlayerController.StopAllMusic(TimeFadeOut);
  PlayerController.PlayMusic(Song, TimeFadeIn);

  return SongPrev;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TextCaptionGoalScore = "Capture Limit";
  TextCaptionAddons = "Add-Ons";
  TextHintAddons = "Select and configure any Jailbreak add-ons to use...";

  SongJailbreak = "Jailbreak";
}