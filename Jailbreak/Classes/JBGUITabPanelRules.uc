// ============================================================================
// JBGUITabPanelRules
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUITabPanelRules.uc,v 1.4 2004/03/06 13:10:12 mychaeel Exp $
//
// User interface panel for Jailbreak game rules.
// ============================================================================


class JBGUITabPanelRules extends Tab_InstantActionBaseRules;


// ============================================================================
// Localization
// ============================================================================

var localized string TextCaptionGoalScore;
var localized string TextCaptionAddons;
var localized string TextHintAddons;


// ============================================================================
// Configuration
// ============================================================================

var config bool bLastJailFights;       // configuration for jail fights


// ============================================================================
// Variables
// ============================================================================

var string SongJailbreak;              // Jailbreak theme song
var string SongPrev;                   // previously played song

var GUITabPanel GUITabPanelAddons;     // new tab panel for add-ons 
var moCheckBox moCheckBoxJailFights;   // new checkbox for jail fights


// ============================================================================
// InitComponent
//
// Sets the caption of the Goal Score widget. Hides the Max Lives widget.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  local GUIImage GUIImageTop;
  local GUIImage GUIImageLeft;
  local GUIImage GUIImageRight;

  Super.InitComponent(GUIController, GUIComponentOwner);

  MyGoalScore.MyLabel.Caption = TextCaptionGoalScore;
  MyMaxLives.bVisible = False;

  GUIImageTop   = GUIImage(Controls[0]);
  GUIImageRight = GUIImage(Controls[1]);
  GUIImageLeft  = GUIImage(Controls[2]);

  GUIImageLeft .WinHeight = 0.720;
  GUIImageRight.WinHeight = 0.720;

  GUIImageLeft .WinLeft = GUIImageTop.WinLeft;
  GUIImageRight.WinLeft = GUIImageTop.WinLeft + GUIImageTop.WinWidth - GUIImageRight.WinWidth;

  MyFriendlyFire.WinTop = 0.667;
  MyFriendlyFire.FriendlyLabel.WinTop = 0.600;

  MyBrightSkins.WinTop = 0.844;

  moCheckBoxJailFights = moCheckBox(Controls[14]);
  moCheckBoxJailFights.Checked(bLastJailFights);
}


// ============================================================================
// InitPanel
//
// Adds the Add-Ons panel and hooks into the game type change event.
// ============================================================================

function InitPanel()
{
  Super.InitPanel();

  AddPanelAddons();
  
  HookChangeGameType();
  HookMenuClose();

  SongPrev = PlaySong(SongJailbreak, 2.0, 0.0);
  if (SongPrev ~= SongJailbreak)
    SongPrev = ExtendedConsole(PlayerOwner().Player.Console).MusicManager.PlayList.Current;
}


// ============================================================================
// GUIButtonConfigureAddons_Click
//
// Called when the Configure Jailbreak Add-Ons button is clicked. Opens the
// corresponding tab.
// ============================================================================

function bool GUIButtonConfigureAddons_Click(GUIComponent GUIComponentClicked)
{
  return GUITabControl(MenuOwner).ActivateTab(GUITabPanelAddons.MyButton, True);
}


// ============================================================================
// Play
//
// Saves the current settings and constructs the parameter string.
// ============================================================================

function string Play()
{
  local string Parameters;

  bLastJailFights = moCheckBoxJailFights.IsChecked();

  Parameters = Super.Play();
  Parameters = Parameters $ "?JailFights=" $ bLastJailFights;
  Parameters = Parameters $ JBGUITabPanelAddons(GUITabPanelAddons).Play();

  return Parameters;
}


// ============================================================================
// AddPanelAddons
//
// Adds the Jailbreak Add-Ons tab directly following the Game Rules tab.
// ============================================================================

function AddPanelAddons()
{
  GUITabPanelAddons = GUITabControl(MenuOwner).AddTab(
    TextCaptionAddons, "Jailbreak.JBGUITabPanelAddons", , TextHintAddons);

  GUITabControl(MenuOwner).TabStack.Remove(GUITabControl(MenuOwner).TabStack.Length - 1, 1);
  GUITabControl(MenuOwner).TabStack.Insert(2, 1);
  GUITabControl(MenuOwner).TabStack[2] = GUITabPanelAddons.MyButton;
}


// ============================================================================
// RemovePanelAddons
//
// Removes the previously added Jailbreak Add-Ons tab.
// ============================================================================

function RemovePanelAddons()
{
  if (GUITabPanelAddons != None)
    GUITabControl(MenuOwner).RemoveTab(TextCaptionAddons);
}


// ============================================================================
// HookChangeGameType
//
// Hooks the ChangeGameType function into the user interface system to get
// notified when the user changes the game type away from Jailbreak.
// ============================================================================

function HookChangeGameType()
{
  local GUITabPanel GUITabPanelMain;

  GUITabPanelMain = GUITabControl(MenuOwner).TabStack[0].MyPanel;

  if (Tab_InstantActionMain(GUITabPanelMain) != None) {
    OnChangeGameType = Tab_InstantActionMain(GUITabPanelMain).OnChangeGameType;
    Tab_InstantActionMain(GUITabPanelMain).OnChangeGameType = ChangeGameType;
  }

  if (Tab_MultiplayerHostMain(GUITabPanelMain) != None) {
    OnChangeGameType = Tab_MultiplayerHostMain(GUITabPanelMain).OnChangeGameType;
    Tab_MultiplayerHostMain(GUITabPanelMain).OnChangeGameType = ChangeGameType;
  }
}


// ============================================================================
// UnhookChangeGameType
//
// Restores the previous function receiving the ChangeGameType notification
// and calls it.
// ============================================================================

function UnhookChangeGameType()
{
  local GUITabPanel GUITabPanelMain;

  GUITabPanelMain = GUITabControl(MenuOwner).TabStack[0].MyPanel;

  if (Tab_InstantActionMain(GUITabPanelMain) != None)
    Tab_InstantActionMain(GUITabPanelMain).OnChangeGameType = OnChangeGameType;
  if (Tab_MultiplayerHostMain(GUITabPanelMain) != None)
    Tab_MultiplayerHostMain(GUITabPanelMain).OnChangeGameType = OnChangeGameType;

  OnChangeGameType();
}


// ============================================================================
// delegate OnChangeGameType
//
// Called when the user switches to another game type. Used to reference the
// function previously set up for this event by the user interface system.
// ============================================================================

delegate OnChangeGameType();


// ============================================================================
// ChangeGameType
//
// Called when the game type is changed in the main panel. Cleans up the
// additional Jailbreak Mutators tab panel.
// ============================================================================

function ChangeGameType()
{
  PlaySong(SongPrev, 1.0, 2.0);
  RemovePanelAddons();
  UnhookChangeGameType();
}


// ============================================================================
// HookMenuClose
//
// Hooks the MenuClose function into the user interface system to get notified
// when the user closes the menu containing this control.
// ============================================================================

function HookMenuClose()
{
  local GUIPage GUIPageMenu;
  
  GUIPageMenu = GUIPage(MenuOwner.MenuOwner);

  if (UT2InstantActionPage(GUIPageMenu) != None) {
    OnMenuClose = UT2InstantActionPage(GUIPageMenu).OnClose;
    UT2InstantActionPage(GUIPageMenu).OnClose = MenuClose;
  }

  if (UT2MultiplayerHostPage(GUIPageMenu) != None) {
    OnMenuClose = UT2MultiplayerHostPage(GUIPageMenu).OnClose;
    UT2MultiplayerHostPage(GUIPageMenu).OnClose = MenuClose;
  }
}


// ============================================================================
// UnhookMenuClose
//
// Restores the previous function receiving the MenuClose notification and
// calls it.
// ============================================================================

function UnhookMenuClose(optional bool bCancelled)
{
  local GUIPage GUIPageMenu;
  
  GUIPageMenu = GUIPage(MenuOwner.MenuOwner);

  if (UT2InstantActionPage(GUIPageMenu) != None)
    UT2InstantActionPage(GUIPageMenu).OnClose = OnMenuClose;
  if (UT2MultiplayerHostPage(GUIPageMenu) != None)
    UT2MultiplayerHostPage(GUIPageMenu).OnClose = OnMenuClose;
  
  OnMenuClose(bCancelled);
}


// ============================================================================
// delegate OnMenuClose
//
// Called when the menu containing this control is closed. Used to reference
// the function previously set up for OnClose of the menu control.
// ============================================================================

delegate OnMenuClose(optional bool bCancelled);


// ============================================================================
// MenuClose
//
// Called when the menu containing this control is closed. Reverts the theme
// song to the previously played song.
// ============================================================================

function MenuClose(optional bool bCancelled)
{
  PlaySong(SongPrev, 1.0, 2.0);
  UnhookMenuClose(bCancelled);
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
  
  PlayerController = PlayerOwner();
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
  SongJailbreak = "Jailbreak";
  
  TextCaptionGoalScore = "Capture Limit";
  TextCaptionAddons = "Add-Ons";
  TextHintAddons = "Select and configure any Jailbreak add-ons to use...";

  LastGoalScore = 5;
  LastTimeLimit = 0;
  bLastJailFights = True;

  Begin Object Class=moCheckBox Name=moCheckBoxJailFightsDef
    Caption      = "Allow Jail Fights";
    Hint         = "Lets players fight in jail with their Shield Gun.";
    WinWidth     = 0.400;
    WinHeight    = 0.040;
    WinLeft      = 0.050;
    WinTop       = 0.487;
    bSquare      = True;
    CaptionWidth = 0.900;
    ComponentJustification = TXTA_Left;
  End Object

  Begin Object Class=GUIButton Name=GUIButtonConfigureAddonsDef
    Caption      = "Configure Jailbreak Add-Ons";
    Hint         = "Open the Add-Ons tab to select and configure Jailbreak Add-Ons";
    WinTop       = 0.833;
    WinLeft      = 0.550;
    WinWidth     = 0.390;
    WinHeight    = 0.060;
    OnClick      = GUIButtonConfigureAddons_Click;
    OnClickSound = CS_Down;
  End Object

  Controls[14] = moCheckBox'moCheckBoxJailFightsDef';
  Controls[15] = GUIButton'GUIButtonConfigureAddonsDef';
}
