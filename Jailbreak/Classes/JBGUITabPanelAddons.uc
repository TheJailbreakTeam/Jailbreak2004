// ============================================================================
// JBGUITabPanelAddons
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUITabPanelAddons.uc,v 1.6 2004/03/11 17:31:04 tarquin Exp $
//
// User interface panel for Jailbreak mutators.
// ============================================================================


class JBGUITabPanelAddons extends GUITabPanel;


// ============================================================================
// Types
// ============================================================================

struct TInfoAddon
{
  var() string TextName;                        // short add-on name
  var() string TextDescription;                 // brief add-on description
  var() string Group;                           // only one from each group

  var() Class<JBAddon> ClassAddon;              // class of add-on mutator
  var() Class<GUIPanel> ClassGUIPanelConfig;    // class of its config panel

  var moCheckBox moCheckBoxSelected;            // checkbox for this addon
  var GUIPanel GUIPanelConfig;                  // instantiated config panel
};


// ============================================================================
// Configuration
// ============================================================================

var config string LastAddons;                   // comma-separated class list


// ============================================================================
// Variables
// ============================================================================

var array<TInfoAddon> ListInfoAddon;            // loaded add-on information

var JBGUIComponentTabs GUIComponentTabsAddons;  // main tab control
var GUIScrollTextBox GUIScrollTextBoxAddon;     // text box for description
var GUIPanel GUIPanelConfigTemplate;            // template for config panels
var GUILabel GUILabelConfigNone;                // shown if no config


// ============================================================================
// InitComponent
//
// Reads the list of add-ons and creates a checkbox for each.
// ============================================================================

function InitComponent(GUIController GUIController, GUIComponent GUIComponentOwner)
{
  local int iInfoAddon;

  Super.InitComponent(GUIController, GUIComponentOwner);

  ReadListInfoAddon();
  SortListInfoAddon(0, ListInfoAddon.Length - 1);

  GUILabelConfigNone = GUILabel(Controls[2]); 
  
  GUIComponentTabsAddons = JBGUIComponentTabs(Controls[0]);
  GUIComponentTabsAddons.OnTabOpened = GUIComponentTabsAddons_TabOpened;
  GUIComponentTabsAddons.OnTabClosed = GUIComponentTabsAddons_TabClosed;

  GUIScrollTextBoxAddon = GUIScrollTextBox(GUIComponentTabsAddons.Controls[0]);

  for (iInfoAddon = 0; iInfoAddon < ListInfoAddon.Length; iInfoAddon++) {
    ListInfoAddon[iInfoAddon].moCheckBoxSelected =
      moCheckBox(GUIComponentTabsAddons.AddTab(ListInfoAddon[iInfoAddon].TextName));

    ListInfoAddon[iInfoAddon].moCheckBoxSelected.Checked(
      InStr("," $ LastAddons                           $ ",",
            "," $ ListInfoAddon[iInfoAddon].ClassAddon $ ",") >= 0);

    ListInfoAddon[iInfoAddon].moCheckBoxSelected.OnChange = moCheckBoxSelected_Change;
  }
}


// ============================================================================
// ReadListInfoAddon
//
// Reads a list of Jailbreak add-ons and pre-loads the add-on classes. Takes
// all information from the loaded classes' default properties.
// ============================================================================

function ReadListInfoAddon()
{
  local int iClassAddon;
  local int iInfoAddon;
  local string NameClassAddon;
  local Class<JBAddon> ClassAddon;

  ListInfoAddon.Length = 0;

  while (True) {
    NameClassAddon = PlayerOwner().GetNextInt("JBAddon", iClassAddon++);
    if (NameClassAddon == "")
      break;

    ClassAddon = Class<JBAddon>(DynamicLoadObject(NameClassAddon, Class'Class', True));
    if (ClassAddon == None ||
        ClassAddon.Default.FriendlyName == Class'JBAddon'.Default.FriendlyName)
      continue;

    iInfoAddon = ListInfoAddon.Length;
    ListInfoAddon.Length = ListInfoAddon.Length + 1;

    ListInfoAddon[iInfoAddon].ClassAddon      = ClassAddon;
    ListInfoAddon[iInfoAddon].TextName        = ClassAddon.Default.FriendlyName;
    ListInfoAddon[iInfoAddon].TextDescription = ClassAddon.Default.Description;
    ListInfoAddon[iInfoAddon].Group           = ClassAddon.Default.GroupName;

    if (ClassAddon.Default.ConfigMenuClassName != "")
      ListInfoAddon[iInfoAddon].ClassGUIPanelConfig =
        Class<GUIPanel>(DynamicLoadObject(ClassAddon.Default.ConfigMenuClassName, Class'Class', True));
  }
}


// ============================================================================
// SortListInfoAddon
//
// Sorts the list of add-ons alphabetically by their name.
// ============================================================================

function SortListInfoAddon(int iInfoAddonStart, int iInfoAddonEnd)
{
  local int iInfoAddonLeft;
  local int iInfoAddonRight;
  local TInfoAddon InfoAddonMiddle;
  local TInfoAddon InfoAddonSwapped;

  if (iInfoAddonStart >= iInfoAddonEnd)
    return;

  iInfoAddonLeft  = iInfoAddonStart;
  iInfoAddonRight = iInfoAddonEnd;

  InfoAddonMiddle = ListInfoAddon[(iInfoAddonStart + iInfoAddonEnd) / 2];

  while (iInfoAddonLeft < iInfoAddonRight) {
    while (iInfoAddonLeft  < iInfoAddonEnd   && ListInfoAddon[iInfoAddonLeft] .TextName < InfoAddonMiddle.TextName) iInfoAddonLeft  += 1;
    while (iInfoAddonRight > iInfoAddonStart && ListInfoAddon[iInfoAddonRight].TextName > InfoAddonMiddle.TextName) iInfoAddonRight -= 1;

    if (iInfoAddonLeft < iInfoAddonRight) {
      InfoAddonSwapped               = ListInfoAddon[iInfoAddonLeft];
      ListInfoAddon[iInfoAddonLeft]  = ListInfoAddon[iInfoAddonRight];
      ListInfoAddon[iInfoAddonRight] = InfoAddonSwapped;
    }

    iInfoAddonLeft  += 1;
    iInfoAddonRight -= 1;
  }

  SortListInfoAddon(iInfoAddonStart, iInfoAddonRight);
  SortListInfoAddon(iInfoAddonLeft,  iInfoAddonEnd);
}


// ============================================================================
// GUIComponentTabsAddons_TabOpened
//
// Called when a tab is opened. Shows the corresponding add-on description. 
// Loads and displays its configuration panel if one is available, or
// shows a label informing the user no options exist.
// ============================================================================

function GUIComponentTabsAddons_TabOpened(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab)
{
  local int iInfoAddon;
  local GUIPanel GUIPanelConfig;

  iInfoAddon = GUIComponentTabsAddons.GetTabIndex(GUIMenuOptionTab);

  GUIScrollTextBoxAddon.SetContent(ListInfoAddon[iInfoAddon].TextDescription);
  
  if (ListInfoAddon[iInfoAddon].ClassGUIPanelConfig == None) {
    GUILabelConfigNone.bVisible = True;
  }
  else {
    if (ListInfoAddon[iInfoAddon].GUIPanelConfig == None) {
      GUIPanelConfig = new ListInfoAddon[iInfoAddon].ClassGUIPanelConfig;
      ListInfoAddon[iInfoAddon].GUIPanelConfig = GUIPanelConfig;

      GUIPanelConfig.bBoundToParent = True;
      GUIPanelConfig.bScaleToParent = True;
      GUIPanelConfig.Background = None;

      GUIPanelConfig.WinTop    = GUIPanelConfigTemplate.WinTop;
      GUIPanelConfig.WinLeft   = GUIPanelConfigTemplate.WinLeft;
      GUIPanelConfig.WinWidth  = GUIPanelConfigTemplate.WinWidth;
      GUIPanelConfig.WinHeight = GUIPanelConfigTemplate.WinHeight;

      GUIComponentTabsAddons.AddComponent(GUIPanelConfig);
    }

    GUILabelConfigNone.bVisible = False;
    ListInfoAddon[iInfoAddon].GUIPanelConfig.bVisible = True;
  }
}


// ============================================================================
// GUIComponentTabsAddons_TabClosed
//
// Called when a tab is closed. Removes the current configuration panel.
// ============================================================================

function GUIComponentTabsAddons_TabClosed(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab)
{
  local int iInfoAddon;

  iInfoAddon = GUIComponentTabsAddons.GetTabIndex(GUIMenuOptionTab);

  if (ListInfoAddon[iInfoAddon].GUIPanelConfig != None)
    ListInfoAddon[iInfoAddon].GUIPanelConfig.bVisible = False;
}


// ============================================================================
// GetAddons
//
// Returns a comma-separated list of the fully qualified class names of all
// currently selected add-ons.
// ============================================================================

function string GetAddons()
{
  local int iInfoAddon;
  local string Addons;

  for (iInfoAddon = 0; iInfoAddon < ListInfoAddon.Length; iInfoAddon++)
    if (ListInfoAddon[iInfoAddon].moCheckBoxSelected.IsChecked()) {
      if (Addons != "")
        Addons = Addons $ ",";
      Addons = Addons $ ListInfoAddon[iInfoAddon].ClassAddon;
    }

  return Addons;
}


// ============================================================================
// moCheckBoxSelected_Change
//
// Called when the state of one of the add-on checkboxes is changed. If a
// checkbox was checked and the corresponding add-on belongs to a group,
// unchecks all other checkboxes in that group.
// ============================================================================

function moCheckBoxSelected_Change(GUIComponent GUIComponentSender)
{
  local int iInfoAddon;
  local int iInfoAddonChanged;

  iInfoAddonChanged = GUIComponentTabsAddons.GetTabIndex(GUIMenuOption(GUIComponentSender));

  if (ListInfoAddon[iInfoAddonChanged].Group != "" &&
      ListInfoAddon[iInfoAddonChanged].moCheckBoxSelected.IsChecked())
    for (iInfoAddon = 0; iInfoAddon < ListInfoAddon.Length; iInfoAddon++)
      if (              iInfoAddon        !=               iInfoAddonChanged &&
          ListInfoAddon[iInfoAddon].Group ~= ListInfoAddon[iInfoAddonChanged].Group)
        ListInfoAddon[iInfoAddon].moCheckBoxSelected.Checked(False);

  LastAddons = GetAddons();
  SaveConfig();
}


// ============================================================================
// Play
//
// Called when a game is started using the current settings. Returns additions
// to the game parameter string.
// ============================================================================

function string Play()
{
  LastAddons = GetAddons();
  SaveConfig();

  return "?Addon=" $ LastAddons;
}


// ============================================================================
// GUIButtonDownloadAddons_Click
//
// Called when a user clicks the Download More Add-Ons button. Opens a page
// on PlanetJailbreak pointing to those downloads.
// ============================================================================

function bool GUIButtonDownloadAddons_Click(GUIComponent GUIComponentClicked)
{
  PlayerOwner().ConsoleCommand("start http://www.planetjailbreak.com/download/addons/");
  return True;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  LastAddons = "JBAddonCelebration.JBAddonCelebration,JBAddonLlama.JBAddonLlama,JBAddonProtection.JBAddonProtection";

  WinLeft   = 0.000;
  WinWidth  = 1.000;
  WinHeight = 0.770;

  bAcceptsInput = False;

  Begin Object Class=GUIScrollTextBox Name=GUIScrollTextBoxAddonDef
    StyleName    = "NoBackground";
    WinTop       = 0.050;
    WinLeft      = 0.360;
    WinWidth     = 0.610;
    WinHeight    = 0.200;
    CharDelay    = 0.0025;
    EOLDelay     = 0.5000;
  End Object

  Begin Object Class=JBGUIComponentTabs Name=GUIComponentTabsAddonsDef
    WinTop       = 0.025;
    WinLeft      = 0.022;
    WinWidth     = 0.957;
    WinHeight    = 0.936;
    Controls[0]  = GUIScrollTextBox'GUIScrollTextBoxAddonDef';
  End Object

  Begin Object Class=GUIButton Name=GUIButtonDownloadAddonsDef
    Caption      = "Download More Add-Ons!";
    Hint         = "Opens the add-on download page on PlanetJailbreak in a web browser.";
    WinTop       = 0.898;
    WinLeft      = 0.022;
    WinWidth     = 0.288;
    WinHeight    = 0.060;
    OnClick      = GUIButtonDownloadAddons_Click;
    OnClickSound = CS_Down;
  End Object

  Begin Object Class=GUIPanel Name=GUIPanelConfigTemplateDef
    bVisible     = False;
    WinTop       = 0.330;
    WinLeft      = 0.360;
    WinWidth     = 0.610;
    WinHeight    = 0.600;
  End Object

  Begin Object class=GUILabel Name=GUILabelConfigDefault
    Caption      = "This add-on has no user options.";
    WinTop       = 0.860;
    WinLeft      = 0.360;
    WinWidth     = 0.610;
    WinHeight    = 0.068;
  End Object

  Controls[0] = JBGUIComponentTabs'GUIComponentTabsAddonsDef';
  Controls[1] = GUIButton'GUIButtonDownloadAddonsDef';
  Controls[2] = GUILabel'GUILabelConfigDefault';

  GUIPanelConfigTemplate = GUIPanel'GUIPanelConfigTemplateDef';
}