//+------------------------------------------------------------------+
//|                                    Core_ResponsiveLayout.mqh     |
//|                              RESPONSIVE LAYOUT ENGINE            |
//|                    Screen Detection & Adaptive UI System         |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef CORE_RESPONSIVE_LAYOUT_MQH
#define CORE_RESPONSIVE_LAYOUT_MQH

//+------------------------------------------------------------------+
//| Screen Size Classification                                        |
//+------------------------------------------------------------------+
enum SCREEN_SIZE {
   SCREEN_SMALL,      // < 1366px width (Laptops, small monitors)
   SCREEN_MEDIUM,     // 1366-1920px (Standard desktops)
   SCREEN_LARGE       // > 1920px (Large monitors, 4K)
};

//+------------------------------------------------------------------+
//| Layout Mode                                                       |
//+------------------------------------------------------------------+
enum LAYOUT_MODE {
   LAYOUT_FULL,       // All panels visible, stacked vertically
   LAYOUT_TABBED,     // Tabbed interface, one panel at a time
   LAYOUT_MINI        // Ultra-compact, minimal info only
};

//+------------------------------------------------------------------+
//| Responsive Layout Configuration                                  |
//+------------------------------------------------------------------+
struct ResponsiveConfig {
   // Screen info
   SCREEN_SIZE screen_size;
   int chart_width;
   int chart_height;
   
   // Layout settings
   LAYOUT_MODE layout_mode;
   int panel_width;
   int panel_max_height;
   
   // Font sizes
   int header_font;
   int metric_font;
   int label_font;
   
   // Spacing
   int panel_spacing;
   int element_spacing;
   int margin;
   
   // Tab system (for small screens)
   bool use_tabs;
   int active_tab;
   string tab_names[7];
   
   // Compact mode flags
   bool show_abbreviated;    // Use abbreviations
   bool single_column;       // Stack metrics vertically
   bool hide_secondary;      // Hide less important info
   bool compact_buttons;     // Smaller buttons
};

//+------------------------------------------------------------------+
//| Global Responsive Config                                         |
//+------------------------------------------------------------------+
ResponsiveConfig g_layout;

//+------------------------------------------------------------------+
//| Detect Screen Size                                               |
//+------------------------------------------------------------------+
SCREEN_SIZE DetectScreenSize() {
   int width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   
   g_layout.chart_width = width;
   g_layout.chart_height = height;
   
   if(width < 1366) {
      return SCREEN_SMALL;
   } else if(width <= 1920) {
      return SCREEN_MEDIUM;
   } else {
      return SCREEN_LARGE;
   }
}

//+------------------------------------------------------------------+
//| Initialize Responsive Layout                                     |
//+------------------------------------------------------------------+
void InitResponsiveLayout() {
   g_layout.screen_size = DetectScreenSize();
   
   // Initialize tab names
   g_layout.tab_names[0] = "PORTFOLIO";
   g_layout.tab_names[1] = "RISK";
   g_layout.tab_names[2] = "SCENARIO";
   g_layout.tab_names[3] = "VISUAL";
   g_layout.tab_names[4] = "ALERTS";
   g_layout.tab_names[5] = "JOURNAL";
   g_layout.tab_names[6] = "SIZING";
   
   g_layout.active_tab = 0; // Start with Portfolio tab
   
   // Configure based on screen size
   switch(g_layout.screen_size) {
      case SCREEN_SMALL:
         ConfigureSmallScreen();
         break;
      case SCREEN_MEDIUM:
         ConfigureMediumScreen();
         break;
      case SCREEN_LARGE:
         ConfigureLargeScreen();
         break;
   }
}

//+------------------------------------------------------------------+
//| Configure for Small Screens (Laptops)                           |
//+------------------------------------------------------------------+
void ConfigureSmallScreen() {
   g_layout.layout_mode = LAYOUT_TABBED;
   g_layout.panel_width = (g_layout.chart_width > 800) ? 780 : g_layout.chart_width - 40;
   g_layout.panel_max_height = g_layout.chart_height - 100;
   
   // Smaller fonts for laptops
   g_layout.header_font = 16;
   g_layout.metric_font = 20;
   g_layout.label_font = 11;
   
   // Tight spacing
   g_layout.panel_spacing = 10;
   g_layout.element_spacing = 3;
   g_layout.margin = 15;
   
   // Enable compact features
   g_layout.use_tabs = true;
   g_layout.show_abbreviated = true;
   g_layout.single_column = (g_layout.chart_width < 1024);
   g_layout.hide_secondary = true;
   g_layout.compact_buttons = true;
}

//+------------------------------------------------------------------+
//| Configure for Medium Screens (Standard Desktop)                 |
//+------------------------------------------------------------------+
void ConfigureMediumScreen() {
   g_layout.layout_mode = LAYOUT_FULL;
   g_layout.panel_width = 1000;
   g_layout.panel_max_height = g_layout.chart_height - 100;
   
   // Standard fonts
   g_layout.header_font = 22;
   g_layout.metric_font = 28;
   g_layout.label_font = 14;
   
   // Normal spacing
   g_layout.panel_spacing = 20;
   g_layout.element_spacing = 5;
   g_layout.margin = 20;
   
   // Disable compact features
   g_layout.use_tabs = false;
   g_layout.show_abbreviated = false;
   g_layout.single_column = false;
   g_layout.hide_secondary = false;
   g_layout.compact_buttons = false;
}

//+------------------------------------------------------------------+
//| Configure for Large Screens (4K, Large Monitors)                |
//+------------------------------------------------------------------+
void ConfigureLargeScreen() {
   g_layout.layout_mode = LAYOUT_FULL;
   g_layout.panel_width = 1200;
   g_layout.panel_max_height = g_layout.chart_height - 150;
   
   // Larger fonts for big screens
   g_layout.header_font = 26;
   g_layout.metric_font = 32;
   g_layout.label_font = 16;
   
   // Generous spacing
   g_layout.panel_spacing = 30;
   g_layout.element_spacing = 8;
   g_layout.margin = 30;
   
   // Disable compact features
   g_layout.use_tabs = false;
   g_layout.show_abbreviated = false;
   g_layout.single_column = false;
   g_layout.hide_secondary = false;
   g_layout.compact_buttons = false;
}

//+------------------------------------------------------------------+
//| Get Layout Configuration                                         |
//+------------------------------------------------------------------+
ResponsiveConfig GetLayoutConfig() {
   return g_layout;
}

//+------------------------------------------------------------------+
//| Update Screen Size (call on chart resize)                       |
//+------------------------------------------------------------------+
void UpdateScreenSize() {
   SCREEN_SIZE old_size = g_layout.screen_size;
   SCREEN_SIZE new_size = DetectScreenSize();
   
   // If screen size changed, reconfigure
   if(old_size != new_size) {
      InitResponsiveLayout();
   }
}

//+------------------------------------------------------------------+
//| Switch Active Tab (for tabbed mode)                             |
//+------------------------------------------------------------------+
void SwitchTab(int tab_index) {
   if(tab_index >= 0 && tab_index < 7) {
      g_layout.active_tab = tab_index;
   }
}

//+------------------------------------------------------------------+
//| Get Active Tab                                                   |
//+------------------------------------------------------------------+
int GetActiveTab() {
   return g_layout.active_tab;
}

//+------------------------------------------------------------------+
//| Check if Using Tabbed Layout                                    |
//+------------------------------------------------------------------+
bool IsTabbed() {
   return g_layout.use_tabs;
}

//+------------------------------------------------------------------+
//| Get Screen Size Name (for debugging)                            |
//+------------------------------------------------------------------+
string GetScreenSizeName() {
   switch(g_layout.screen_size) {
      case SCREEN_SMALL:  return "SMALL (Laptop)";
      case SCREEN_MEDIUM: return "MEDIUM (Desktop)";
      case SCREEN_LARGE:  return "LARGE (4K)";
      default: return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Get Layout Mode Name                                            |
//+------------------------------------------------------------------+
string GetLayoutModeName() {
   switch(g_layout.layout_mode) {
      case LAYOUT_FULL:   return "FULL PANELS";
      case LAYOUT_TABBED: return "TABBED";
      case LAYOUT_MINI:   return "MINI";
      default: return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Render Tab Bar (for small screens)                              |
//+------------------------------------------------------------------+
void RenderTabBar(ENUM_BASE_CORNER corner, color bg_color, color active_color, 
                  color inactive_color, color text_color) {
   
   if(!g_layout.use_tabs) return;
   
   const string OBJ_PREFIX = "TAB_";
   int tab_width = 110;
   int tab_height = 35;
   int tab_y = 10;
   int start_x = 20;
   
   // Tab bar background
   CreateRect(OBJ_PREFIX + "bar_bg", start_x, tab_y, 
              tab_width * 7 + 10, tab_height + 4, bg_color, true, corner);
   
   // Render each tab
   for(int i = 0; i < 7; i++) {
      int tab_x = start_x + 5 + (i * tab_width);
      string tab_name = OBJ_PREFIX + "btn_" + IntegerToString(i);
      
      color btn_color = (i == g_layout.active_tab) ? active_color : inactive_color;
      
      // Tab button background
      CreateRect(tab_name + "_bg", tab_x, tab_y + 2, tab_width - 5, tab_height, 
                btn_color, true, corner);
      
      // Tab label
      CreateLbl(tab_name + "_lbl", tab_x + (tab_width - 5) / 2 - 20, tab_y + 10,
               g_layout.tab_names[i], text_color, 11, "Arial Black", corner);
   }
}

//+------------------------------------------------------------------+
//| Handle Tab Click                                                 |
//+------------------------------------------------------------------+
bool HandleTabClick(int x, int y) {
   if(!g_layout.use_tabs) return false;
   
   int tab_width = 110;
   int tab_height = 35;
   int tab_y = 10;
   int start_x = 20;
   
   // Check if click is within tab bar
   if(y < tab_y || y > tab_y + tab_height + 4) return false;
   if(x < start_x || x > start_x + tab_width * 7 + 10) return false;
   
   // Calculate which tab was clicked
   int relative_x = x - start_x - 5;
   int tab_index = relative_x / tab_width;
   
   if(tab_index >= 0 && tab_index < 7) {
      SwitchTab(tab_index);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get Abbreviated Text (for compact mode)                         |
//+------------------------------------------------------------------+
string GetAbbreviation(string full_text) {
   if(!g_layout.show_abbreviated) return full_text;
   
   // Common abbreviations
   if(full_text == "Profit & Loss") return "P&L";
   if(full_text == "Total Equity") return "Equity";
   if(full_text == "Daily Profit") return "Daily P&L";
   if(full_text == "Weekly Profit") return "Week P&L";
   if(full_text == "Open Positions") return "Positions";
   if(full_text == "Win Rate") return "Win%";
   if(full_text == "Profit Factor") return "PF";
   if(full_text == "Sharpe Ratio") return "Sharpe";
   if(full_text == "Max Drawdown") return "Max DD";
   if(full_text == "Current Drawdown") return "Curr DD";
   if(full_text == "Recovery Factor") return "Recovery";
   if(full_text == "Average Trade") return "Avg Trade";
   if(full_text == "Total Trades") return "Trades";
   if(full_text == "Winning Trades") return "Wins";
   if(full_text == "Losing Trades") return "Losses";
   
   return full_text;
}

//+------------------------------------------------------------------+
//| Calculate Start Y Position (accounts for tab bar)               |
//+------------------------------------------------------------------+
int GetContentStartY() {
   if(g_layout.use_tabs) {
      return 55; // After tab bar
   }
   return 20; // Standard position
}

#endif // CORE_RESPONSIVE_LAYOUT_MQH
