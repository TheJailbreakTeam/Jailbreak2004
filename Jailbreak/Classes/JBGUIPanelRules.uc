// ============================================================================
// JBGUIPanelRules
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id$
//
// User interface panel for Jailbreak game rules.
// ============================================================================


class JBGUIPanelRules extends Tab_InstantActionBaseRules;


// ============================================================================
// Localization
// ============================================================================

var localized string TextGoalScore;


// ============================================================================
// Configuration
// ============================================================================

var config bool bLastJailFights;


// ============================================================================
// Variables
// ============================================================================

var moCheckBox CheckBoxJailFights;


// ============================================================================
// InitComponent
//
// Sets the caption of the goal score widget. Hides the max lives widget.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent ComponentOwner) {

  local GUIImage PanelTop;
  local GUIImage PanelLeft;
  local GUIImage PanelRight;

  Super.InitComponent(GUIController, ComponentOwner);

  MyGoalScore.MyLabel.Caption = TextGoalScore;
  MyMaxLives.bVisible = False;

  PanelTop   = GUIImage(Controls[0]);
  PanelRight = GUIImage(Controls[1]);
  PanelLeft  = GUIImage(Controls[2]);

  PanelLeft .WinHeight = 0.720;
  PanelRight.WinHeight = 0.720;

  PanelLeft .WinLeft = PanelTop.WinLeft;
  PanelRight.WinLeft = PanelTop.WinLeft + PanelTop.WinWidth - PanelRight.WinWidth;

  MyFriendlyFire.WinTop = 0.667;
  MyFriendlyFire.FriendlyLabel.WinTop = 0.600;

  MyBrightSkins.WinTop = 0.844;
  
  CheckBoxJailFights = moCheckBox(Controls[14]);
  CheckBoxJailFights.Checked(bLastJailFights);
  }


// ============================================================================
// Play
//
// Saves the current settings and constructs the parameter string.
// ============================================================================

function string Play() {

  local string Parameters;
  
  bLastJailFights = CheckBoxJailFights.IsChecked();

  Parameters = Super.Play();
  Parameters = Parameters $ "?JailFights=" $ bLastJailFights;
  
  return Parameters;
  }


// ============================================================================
// Defaults
// ============================================================================

defaultproperties {

  TextGoalScore = "Capture Limit";

  LastGoalScore = 5;
  LastTimeLimit = 0;
  bLastJailFights = True;

  Begin Object Class=moCheckBox Name=JBCheckBoxJailFights
    bSquare   = True;
    WinWidth  = 0.400;
    WinHeight = 0.040;
    WinLeft   = 0.050;
    WinTop    = 0.487;
    Caption   = "Allow Jail Fights";
    Hint      = "Lets players fight in jail with their Shield Gun.";
    CaptionWidth = 0.9;
    ComponentJustification = TXTA_Left;
  End Object

  Controls[14] = moCheckBox'JBCheckBoxJailFights';
  }
