// ============================================================================
// JBGUITabPanelAddons
// Copyright 2003 by Mychaeel <mychaeel@planetjailbreak.com>
// $Id: JBGUITabPanelAddons.uc,v 1.12 2004/04/04 01:22:48 mychaeel Exp $
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
// Localization
// ============================================================================

var localized string TextHintReset;             // hint for config reset button


// ============================================================================
// Variables
// ============================================================================

var array<TInfoAddon>   ListInfoAddon;          // loaded add-on information

var JBGUIComponentTabs  GUIComponentTabsAddons; // main tab control
var GUIVertScrollButton GUIScrollButtonUp;      // scroll up   for tab control
var GUIVertScrollButton GUIScrollButtonDown;    // scroll down for tab control
var GUIScrollTextBox    GUIScrollTextBoxAddon;  // text box for description
var GUIPanel            GUIPanelConfigTemplate; // template for config panels
var GUILabel            GUILabelConfigNone;     // shown if no config panel
var GUIButton           GUIButtonReset;         // reset addon settings


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

  GUIComponentTabsAddons = JBGUIComponentTabs(Controls[0]);
  GUIComponentTabsAddons.nTabsVisibleMax = 8;
  GUIComponentTabsAddons.OnTabOpened = GUIComponentTabsAddons_TabOpened;
  GUIComponentTabsAddons.OnTabClosed = GUIComponentTabsAddons_TabClosed;
  GUIComponentTabsAddons.OnScroll    = GUIComponentTabsAddons_Scroll;

  GUIScrollButtonUp   = GUIVertScrollButton(Controls[1]);
  GUIScrollButtonDown = GUIVertScrollButton(Controls[2]);

  GUIScrollTextBoxAddon = GUIScrollTextBox(GUIComponentTabsAddons.Controls[0]);
  GUILabelConfigNone    = GUILabel        (GUIComponentTabsAddons.Controls[1]); 
  GUIButtonReset        = GUIButton       (GUIComponentTabsAddons.Controls[2]); 

  for (iInfoAddon = 0; iInfoAddon < ListInfoAddon.Length; iInfoAddon++) {
    ListInfoAddon[iInfoAddon].moCheckBoxSelected =
      moCheckBox(GUIComponentTabsAddons.AddTab(ListInfoAddon[iInfoAddon].TextName));

    ListInfoAddon[iInfoAddon].moCheckBoxSelected.Checked(
      InStr("," $ Class'Jailbreak'.Default.Addons      $ ",",
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
// shows a label informing the user no options exist. Shows a reset button if
// the panel class is a child of JBGUIPanelConfig.
// ============================================================================

function GUIComponentTabsAddons_TabOpened(GUIComponent GUIComponentSender, GUIMenuOption GUIMenuOptionTab)
{
  local int iInfoAddon;
  local string TextHintResetReplaced;
  local GUIPanel GUIPanelConfig;

  iInfoAddon = GUIComponentTabsAddons.GetTabIndex(GUIMenuOptionTab);

  GUIScrollTextBoxAddon.SetContent(ListInfoAddon[iInfoAddon].TextDescription);
  
  if (ListInfoAddon[iInfoAddon].ClassGUIPanelConfig == None) {
    GUILabelConfigNone.SetVisibility(True);
    GUIButtonReset    .SetVisibility(False);
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
      
      GUIComponentTabsAddons.AddComponentObject(GUIPanelConfig);
    }
    
    TextHintResetReplaced = TextHintReset;
    ReplaceText(TextHintResetReplaced, "%addon%", ListInfoAddon[iInfoAddon].TextName);

    GUIButtonReset.SetVisibility(JBGUIPanelConfig(ListInfoAddon[iInfoAddon].GUIPanelConfig) != None);
    GUIButtonReset.SetHint(TextHintResetReplaced);
    
    GUILabelConfigNone.SetVisibility(False);
    ListInfoAddon[iInfoAddon].GUIPanelConfig.SetVisibility(True);
    ListInfoAddon[iInfoAddon].GUIPanelConfig.EnableMe();
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

  if (ListInfoAddon[iInfoAddon].GUIPanelConfig != None) {
    ListInfoAddon[iInfoAddon].GUIPanelConfig.SetVisibility(False);
    ListInfoAddon[iInfoAddon].GUIPanelConfig.DisableMe();
  }
}


// ============================================================================
// GUIComponentTabsAddons_Scroll
//
// Called when tabs are scrolled. Shows or hides the scroll buttons as
// appropriate.
// ============================================================================

function GUIComponentTabsAddons_Scroll(GUIComponent GUIComponentSender)
{
  if (GUIComponentTabsAddons.iTabFirst > 0)
         { GUIScrollButtonUp.SetVisibility(True);  EnableComponent (GUIScrollButtonUp); }
    else { GUIScrollButtonUp.SetVisibility(False); DisableComponent(GUIScrollButtonUp); }

  if (GUIComponentTabsAddons.iTabFirst + GUIComponentTabsAddons.nTabsVisibleMax < GUIComponentTabsAddons.CountTabs())
         { GUIScrollButtonDown.SetVisibility(True);  EnableComponent (GUIScrollButtonDown); }
    else { GUIScrollButtonDown.SetVisibility(False); DisableComponent(GUIScrollButtonDown); }
}


// ============================================================================
// GUIScrollButtonUp_Click
//
// Called when the scroll-up button is clicked.
// ============================================================================

function bool GUIScrollButtonUp_Click(GUIComponent GUIComponentSender)
{
  local int iTabLast;

  if (GUIComponentTabsAddons.iTabFirst <= 0)
    return False;

  GUIComponentTabsAddons.iTabFirst -= 1;
  
  iTabLast = GUIComponentTabsAddons.iTabFirst + GUIComponentTabsAddons.nTabsVisibleMax - 1;
  if (GUIComponentTabsAddons.GetCurrentTabIndex() > iTabLast)
    GUIComponentTabsAddons.GetTabComponent(iTabLast).SetFocus(None);
  
  return True;
}


// ============================================================================
// GUIScrollButtonDown_Click
//
// Called when the scroll-down button is clicked.
// ============================================================================

function bool GUIScrollButtonDown_Click(GUIComponent GUIComponentSender)
{
  if (GUIComponentTabsAddons.iTabFirst + GUIComponentTabsAddons.nTabsVisibleMax >= GUIComponentTabsAddons.CountTabs())
    return False;
    
  GUIComponentTabsAddons.iTabFirst += 1;
  if (GUIComponentTabsAddons.GetCurrentTabIndex() < GUIComponentTabsAddons.iTabFirst)
    GUIComponentTabsAddons.GetTabComponent(GUIComponentTabsAddons.iTabFirst).SetFocus(None);

  return True;
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

  Class'Jailbreak'.Default.Addons = GetAddons();
  Class'Jailbreak'.Static.StaticSaveConfig();
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
// GUIButtonConfigReset_Click
//
// Called when a user clicks the Reset button. Calls ResetConfiguration of the 
// current config panel object if it is a subclass of JBGUIPanelConfig.
// ============================================================================

function bool GUIButtonConfigReset_Click(GUIComponent GUIComponentClicked)
{
  local int iInfoAddon;
  
  iInfoAddon = GUIComponentTabsAddons.GetCurrentTabIndex();  
  
  if(JBGUIPanelConfig(ListInfoAddon[iInfoAddon].GUIPanelConfig) != None)
    JBGUIPanelConfig(ListInfoAddon[iInfoAddon].GUIPanelConfig).ResetConfiguration();

  return True;
}


// ============================================================================
// Defaults
// ============================================================================

defaultproperties
{
  TextHintReset = "Reset options for %addon%."
  
  WinLeft   = 0.000;
  WinWidth  = 1.000;
  WinHeight = 0.770;

  bAcceptsInput = False;
  FadeInTime = 0.25;

  Begin Object Class=GUIScrollTextBox Name=GUIScrollTextBoxAddonDef
    StyleName    = "NoBackground";
    WinTop       = 0.090;
    WinLeft      = 0.370;
    WinWidth     = 0.590;
    WinHeight    = 0.160;
    CharDelay    = 0.0025;
    EOLDelay     = 0.5000;
  End Object

  Begin Object Class=GUILabel Name=GUILabelConfigDefaultDef
    Caption      = "This add-on has no user options.";
    TextColor    = (B=0,G=180,R=220);
    WinTop       = 0.840;
    WinLeft      = 0.370;
    WinWidth     = 0.590;
    WinHeight    = 0.068;
  End Object

  Begin Object Class=GUIButton Name=GUIButtonConfigResetDef
    Caption      = "Reset Options";
    Hint         = "Reset this add-on's options.";
    OnClick      = GUIButtonConfigReset_Click;
    WinTop       = 0.843;
    WinLeft      = 0.765;
    WinWidth     = 0.184;
    WinHeight    = 0.058;
  End Object

  Begin Object Class=GUIVertScrollButton Name=GUIScrollButtonUpDef
    ImageIndex   = 6;
    StyleName    = "TextButton";
    OnClick      = GUIScrollButtonUp_Click;
    WinTop       = 0.035;
    WinLeft      = 0.140;
    WinWidth     = 0.050;
    WinHeight    = 0.025;
  End Object

  Begin Object Class=GUIVertScrollButton Name=GUIScrollButtonDownDef
    ImageIndex   = 7;
    StyleName    = "TextButton";
    OnClick      = GUIScrollButtonDown_Click;
    WinTop       = 0.840;
    WinLeft      = 0.140;
    WinWidth     = 0.050;
    WinHeight    = 0.025;
  End Object

  Begin Object Class=JBGUIComponentTabs Name=GUIComponentTabsAddonsDef
    TabOrder     = 1;
    WinTop       = 0.016;
    WinLeft      = 0.002;
    WinWidth     = 0.996;
    WinHeight    = 0.960;
    Controls[0]  = GUIScrollTextBox'GUIScrollTextBoxAddonDef';
    Controls[1]  = GUILabel'GUILabelConfigDefaultDef';
    Controls[2]  = GUIButton'GUIButtonConfigResetDef';
  End Object

  Begin Object Class=GUIButton Name=GUIButtonDownloadAddonsDef
    TabOrder     = 2;
    Caption      = "Download More Add-Ons!";
    Hint         = "Opens the add-on download page on PlanetJailbreak in a web browser.";
    WinTop       = 0.898;
    WinLeft      = 0.010;
    WinWidth     = 0.300;
    WinHeight    = 0.060;
    OnClick      = GUIButtonDownloadAddons_Click;
    OnClickSound = CS_Down;
  End Object

  Begin Object Class=GUIPanel Name=GUIPanelConfigTemplateDef
    bVisible     = False;
    WinTop       = 0.330;
    WinLeft      = 0.370;
    WinWidth     = 0.590;
    WinHeight    = 0.550;
  End Object

  Controls[0] = JBGUIComponentTabs'GUIComponentTabsAddonsDef';
  Controls[1] = GUIVertScrollButton'GUIScrollButtonUpDef';
  Controls[2] = GUIVertScrollButton'GUIScrollButtonDownDef';
  Controls[3] = GUIButton'GUIButtonDownloadAddonsDef';

  GUIPanelConfigTemplate = GUIPanel'GUIPanelConfigTemplateDef';
}