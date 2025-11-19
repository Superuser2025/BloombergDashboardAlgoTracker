//+------------------------------------------------------------------+
//|                              Core_CompactRender.mqh              |
//|                         COMPACT RENDERING UTILITIES              |
//|                  Optimized UI Functions for Small Screens        |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef CORE_COMPACT_RENDER_MQH
#define CORE_COMPACT_RENDER_MQH

#include "Core_ResponsiveLayout.mqh"
#include "Core_UIHelpers.mqh"

//+------------------------------------------------------------------+
//| Create Compact Metric Display (2 columns max)                   |
//+------------------------------------------------------------------+
int CreateCompactMetric(string obj_prefix, int x, int y, int width,
                        string label, string value, color value_color,
                        ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   int label_x = x + config.margin;
   int value_x = x + width / 2;
   
   // Label
   CreateLbl(obj_prefix + "_lbl", label_x, y,
            GetAbbreviation(label), clrWhite, config.label_font, "Arial", corner);
   
   // Value
   CreateLbl(obj_prefix + "_val", value_x, y,
            value, value_color, config.metric_font, "Arial Black", corner);
   
   return y + config.metric_font + config.element_spacing;
}

//+------------------------------------------------------------------+
//| Create Compact Section Header                                   |
//+------------------------------------------------------------------+
int CreateCompactHeader(string obj_prefix, int x, int y, int width,
                        string title, color title_color,
                        ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   // Underline
   CreateRect(obj_prefix + "_line", x + config.margin, y + config.header_font + 2,
             width - config.margin * 2, 2, title_color, true, corner);
   
   // Title
   CreateLbl(obj_prefix + "_title", x + config.margin, y,
            title, title_color, config.header_font, "Arial Black", corner);
   
   return y + config.header_font + 10;
}

//+------------------------------------------------------------------+
//| Create Compact Button                                           |
//+------------------------------------------------------------------+
void CreateCompactButton(string name, int x, int y, int width, int height,
                        string text, color bg_color, color text_color,
                        ENUM_BASE_CORNER corner, int font_size = 11) {
   
   // Button background
   CreateRect(name + "_bg", x, y, width, height, bg_color, true, corner);
   
   // Button text (centered)
   int text_x = x + width / 2 - (StringLen(text) * font_size / 4);
   int text_y = y + (height - font_size) / 2;
   
   CreateLbl(name + "_txt", text_x, text_y, text, text_color, font_size, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Create Compact Algo Card (Single Line)                          |
//+------------------------------------------------------------------+
int CreateCompactAlgoCard(string obj_prefix, int x, int y, int width,
                          string algo_name, double profit, int magic,
                          color profit_color, color bg_color,
                          ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   int card_height = config.metric_font + config.element_spacing * 2 + 10;
   
   // Card background
   CreateRect(obj_prefix + "_bg", x, y, width, card_height, bg_color, true, corner);
   
   // Algo name (left)
   string short_name = (StringLen(algo_name) > 12) ? StringSubstr(algo_name, 0, 12) + "..." : algo_name;
   CreateLbl(obj_prefix + "_name", x + 10, y + 5,
            short_name, clrWhite, config.label_font + 1, "Arial", corner);
   
   // Profit (right)
   string profit_str = (profit >= 0 ? "+" : "") + DoubleToString(profit, 2);
   CreateLbl(obj_prefix + "_profit", x + width - 80, y + 5,
            profit_str, profit_color, config.metric_font - 6, "Arial Black", corner);
   
   return y + card_height + config.element_spacing;
}

//+------------------------------------------------------------------+
//| Create Compact Progress Bar                                     |
//+------------------------------------------------------------------+
void CreateCompactProgressBar(string obj_prefix, int x, int y, int width, int height,
                              double percentage, color fill_color, color bg_color,
                              ENUM_BASE_CORNER corner) {
   
   // Background
   CreateRect(obj_prefix + "_bg", x, y, width, height, bg_color, true, corner);
   
   // Fill
   int fill_width = (int)(width * MathMin(percentage / 100.0, 1.0));
   if(fill_width > 0) {
      CreateRect(obj_prefix + "_fill", x, y, fill_width, height, fill_color, true, corner);
   }
   
   // Percentage text
   string pct_text = DoubleToString(percentage, 1) + "%";
   CreateLbl(obj_prefix + "_txt", x + width / 2 - 15, y + 2,
            pct_text, clrWhite, 10, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Create Compact Stat Row (3 stats in one row)                    |
//+------------------------------------------------------------------+
int CreateCompactStatRow(string obj_prefix, int x, int y, int width,
                        string label1, string value1, color color1,
                        string label2, string value2, color color2,
                        string label3, string value3, color color3,
                        ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   int col_width = width / 3;
   
   // Column 1
   CreateLbl(obj_prefix + "_lbl1", x + 10, y,
            GetAbbreviation(label1), clrGray, config.label_font - 1, "Arial", corner);
   CreateLbl(obj_prefix + "_val1", x + 10, y + config.label_font + 2,
            value1, color1, config.label_font + 3, "Arial Black", corner);
   
   // Column 2
   CreateLbl(obj_prefix + "_lbl2", x + col_width, y,
            GetAbbreviation(label2), clrGray, config.label_font - 1, "Arial", corner);
   CreateLbl(obj_prefix + "_val2", x + col_width, y + config.label_font + 2,
            value2, color2, config.label_font + 3, "Arial Black", corner);
   
   // Column 3
   CreateLbl(obj_prefix + "_lbl3", x + col_width * 2, y,
            GetAbbreviation(label3), clrGray, config.label_font - 1, "Arial", corner);
   CreateLbl(obj_prefix + "_val3", x + col_width * 2, y + config.label_font + 2,
            value3, color3, config.label_font + 3, "Arial Black", corner);
   
   return y + config.label_font + config.label_font + 3 + config.element_spacing * 2;
}

//+------------------------------------------------------------------+
//| Create Expandable Section Toggle                                |
//+------------------------------------------------------------------+
void CreateExpandToggle(string obj_prefix, int x, int y,
                       string section_name, bool is_expanded,
                       color text_color, ENUM_BASE_CORNER corner) {
   
   string arrow = is_expanded ? "▼" : "►";
   
   CreateLbl(obj_prefix + "_arrow", x, y, arrow, text_color, 14, "Arial", corner);
   CreateLbl(obj_prefix + "_name", x + 20, y, section_name, text_color, 13, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Create Compact Alert Badge                                      |
//+------------------------------------------------------------------+
void CreateCompactAlertBadge(string obj_prefix, int x, int y,
                            int count, color badge_color,
                            ENUM_BASE_CORNER corner) {
   
   if(count <= 0) return;
   
   int badge_size = 20;
   
   // Badge circle
   CreateRect(obj_prefix + "_badge", x, y, badge_size, badge_size, badge_color, true, corner);
   
   // Count
   string count_str = (count > 99) ? "99+" : IntegerToString(count);
   CreateLbl(obj_prefix + "_count", x + 4, y + 3,
            count_str, clrWhite, 10, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Create Compact Tab Content Area                                 |
//+------------------------------------------------------------------+
void CreateTabContentArea(int x, int y, int width, int height,
                         color bg_color, ENUM_BASE_CORNER corner) {
   
   CreateRect("TAB_CONTENT_BG", x, y, width, height, bg_color, true, corner);
}

//+------------------------------------------------------------------+
//| Create Screen Size Indicator (Debug)                            |
//+------------------------------------------------------------------+
void CreateScreenSizeIndicator(ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   string size_text = "SCREEN: " + GetScreenSizeName() + " | " + 
                     IntegerToString(config.chart_width) + "x" + 
                     IntegerToString(config.chart_height);
   
   string mode_text = "MODE: " + GetLayoutModeName();
   
   int x = 20;
   int y = config.chart_height - 60;
   
   CreateLbl("DEBUG_SIZE", x, y, size_text, clrYellow, 10, "Arial", corner);
   CreateLbl("DEBUG_MODE", x, y + 15, mode_text, clrYellow, 10, "Arial", corner);
}

//+------------------------------------------------------------------+
//| Calculate Optimal Column Count                                  |
//+------------------------------------------------------------------+
int GetOptimalColumns(int panel_width, int min_col_width = 200) {
   int cols = panel_width / min_col_width;
   return MathMax(1, MathMin(cols, 4)); // Between 1-4 columns
}

//+------------------------------------------------------------------+
//| Create Compact Module Switcher (Bottom Bar)                     |
//+------------------------------------------------------------------+
void CreateModuleSwitcher(int y_position, bool show_risk, bool show_scenario,
                         bool show_visual, bool show_alerts, bool show_journal,
                         bool show_sizing, bool show_correlation,
                         color active_color, color inactive_color,
                         ENUM_BASE_CORNER corner, ResponsiveConfig &config) {
   
   const string OBJ_PREFIX = "MOD_";
   int btn_width = config.compact_buttons ? 80 : 110;
   int btn_height = config.compact_buttons ? 25 : 35;
   int btn_spacing = 5;
   int start_x = config.margin;
   
   string modules[] = {"RISK", "SCENARIO", "VISUAL", "ALERTS", "JOURNAL", "SIZING", "CORR"};
   bool states[] = {show_risk, show_scenario, show_visual, show_alerts, show_journal, show_sizing, show_correlation};
   
   for(int i = 0; i < 7; i++) {
      int btn_x = start_x + (i * (btn_width + btn_spacing));
      color btn_color = states[i] ? active_color : inactive_color;
      
      CreateCompactButton(OBJ_PREFIX + modules[i], btn_x, y_position,
                         btn_width, btn_height, modules[i],
                         btn_color, clrWhite, corner, config.label_font);
   }
}

#endif // CORE_COMPACT_RENDER_MQH
