//+------------------------------------------------------------------+
//|                      Module_PositionSizing_Render.mqh            |
//|                   POSITION SIZING RENDERING                      |
//|                  Position Calculator Display Functions           |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_POSITION_SIZING_RENDER_MQH
#define MODULE_POSITION_SIZING_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_PositionSizing.mqh"
#include "Core_UIHelpers.mqh"

// Global input controls
string g_calc_symbol = "";
double g_calc_sl_pips = 50.0;
double g_calc_tp_pips = 100.0;

//+------------------------------------------------------------------+
//| Render Position Sizing Panel                                      |
//+------------------------------------------------------------------+
void RenderPositionSizingPanel(PositionSizingData &data,
                               TradeStats &stats,
                               int start_y,
                               int panel_width,
                               ENUM_BASE_CORNER corner,
                               int header_size,
                               int metric_size,
                               int label_size,
                               color header_color,
                               color good_color,
                               color warning_color,
                               color danger_color,
                               color info_color,
                               color bg_color,
                               color panel_color,
                               color text_color) {
   
   const string OBJ_PREFIX = "SIZE_";
   int panel_x = 20;
   int y = start_y;
   
   int total_height = 1100;
   
   // Main background
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, total_height, bg_color, true, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "POSITION SIZING CALCULATOR", header_color, header_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            "Dynamic Size Recommendations | Risk Management",
            info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Input Controls
   y = RenderInputControls(panel_x, y, panel_width, corner, header_color,
                          panel_color, text_color, label_size);
   
   y += 20;
   
   // Optimal Recommendation
   y = RenderOptimalRecommendation(data, panel_x, y, panel_width, corner,
                                   header_color, good_color, panel_color, 
                                   text_color, label_size, metric_size);
   
   y += 20;
   
   // All Recommendations
   y = RenderAllRecommendations(data, panel_x, y, panel_width, corner,
                               header_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Risk Summary
   y = RenderRiskSummary(data, panel_x, y, panel_width, corner, header_color,
                        good_color, warning_color, danger_color, panel_color,
                        text_color, label_size, metric_size);
   
   y += 20;
   
   // Portfolio Heat Gauge
   RenderHeatGauge(data, panel_x, y, panel_width, corner, header_color,
                  good_color, warning_color, danger_color, panel_color,
                  text_color, label_size);
}

//+------------------------------------------------------------------+
//| Render Input Controls                                             |
//+------------------------------------------------------------------+
int RenderInputControls(int x, int y, int width, ENUM_BASE_CORNER corner,
                        color header_color, color panel_color, 
                        color text_color, int label_size) {
   
   const string OBJ_PREFIX = "SIZE_";
   
   CreateRect(OBJ_PREFIX + "input_bg", x + 20, y, width - 40, 120,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "input_title", x + 40, curr_y,
            "CALCULATE POSITION SIZE", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Symbol input
   CreateLbl(OBJ_PREFIX + "symbol_lbl", x + 60, curr_y,
            "Symbol:", text_color, label_size, "Arial", corner);
   
   if(g_calc_symbol == "") g_calc_symbol = Symbol();
   CreateLbl(OBJ_PREFIX + "symbol_val", x + 150, curr_y,
            g_calc_symbol, header_color, label_size + 2, "Arial Bold", corner);
   
   CreateBtn(OBJ_PREFIX + "symbol_change", x + 300, curr_y - 5, 120, 30,
            "CHANGE", text_color, C'55,65,81', corner);
   
   curr_y += 35;
   
   // Stop Loss input
   CreateLbl(OBJ_PREFIX + "sl_lbl", x + 60, curr_y,
            "Stop Loss (pips):", text_color, label_size, "Arial", corner);
   
   CreateLbl(OBJ_PREFIX + "sl_val", x + 200, curr_y,
            StringFormat("%.1f", g_calc_sl_pips), header_color, 
            label_size + 2, "Arial Bold", corner);
   
   CreateBtn(OBJ_PREFIX + "sl_down", x + 290, curr_y - 5, 50, 30,
            "-10", text_color, C'55,65,81', corner);
   CreateBtn(OBJ_PREFIX + "sl_up", x + 350, curr_y - 5, 50, 30,
            "+10", text_color, C'55,65,81', corner);
   
   // Take Profit input
   CreateLbl(OBJ_PREFIX + "tp_lbl", x + 480, curr_y,
            "Take Profit (pips):", text_color, label_size, "Arial", corner);
   
   CreateLbl(OBJ_PREFIX + "tp_val", x + 640, curr_y,
            StringFormat("%.1f", g_calc_tp_pips), header_color,
            label_size + 2, "Arial Bold", corner);
   
   CreateBtn(OBJ_PREFIX + "tp_down", x + 730, curr_y - 5, 50, 30,
            "-10", text_color, C'55,65,81', corner);
   CreateBtn(OBJ_PREFIX + "tp_up", x + 790, curr_y - 5, 50, 30,
            "+10", text_color, C'55,65,81', corner);
   
   // Calculate button
   CreateBtn(OBJ_PREFIX + "calculate", x + 900, curr_y - 5, 140, 30,
            "CALCULATE", text_color, C'59,130,246', corner);
   
   return y + 120;
}

//+------------------------------------------------------------------+
//| Render Optimal Recommendation                                     |
//+------------------------------------------------------------------+
int RenderOptimalRecommendation(PositionSizingData &data, int x, int y, int width,
                                ENUM_BASE_CORNER corner, color header_color,
                                color good_color, color panel_color,
                                color text_color, int label_size, int metric_size) {
   
   const string OBJ_PREFIX = "SIZE_";
   
   CreateRect(OBJ_PREFIX + "optimal_bg", x + 20, y, width - 40, 140,
              good_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "optimal_title", x + 40, curr_y,
            "⭐ RECOMMENDED POSITION SIZE", C'255,255,255', 
            label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Large lot size display
   CreateLbl(OBJ_PREFIX + "optimal_lots", x + 60, curr_y,
            StringFormat("%.2f LOTS", data.optimal_size), C'255,255,255',
            metric_size + 8, "Arial Black", corner);
   
   curr_y += metric_size + 20;
   
   // Method and explanation
   CreateLbl(OBJ_PREFIX + "optimal_method", x + 60, curr_y,
            "Method: " + data.optimal_method, C'255,255,255',
            label_size + 1, "Arial", corner);
   curr_y += label_size + 12;
   
   CreateLbl(OBJ_PREFIX + "optimal_exp", x + 60, curr_y,
            data.optimal_explanation, C'240,240,240', label_size, "Arial", corner);
   
   return y + 140;
}

//+------------------------------------------------------------------+
//| Render All Recommendations                                        |
//+------------------------------------------------------------------+
int RenderAllRecommendations(PositionSizingData &data, int x, int y, int width,
                            ENUM_BASE_CORNER corner, color header_color,
                            color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "SIZE_";
   
   int panel_height = 380;
   
   CreateRect(OBJ_PREFIX + "all_bg", x + 20, y, width - 40, panel_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "all_title", x + 40, curr_y,
            "ALL SIZING METHODS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Table header
   CreateRect(OBJ_PREFIX + "tbl_hdr", x + 40, curr_y, width - 100, 30,
              C'25,30,40', true, corner);
   
   CreateLbl(OBJ_PREFIX + "hdr_method", x + 60, curr_y + 7,
            "Method", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_lots", x + 320, curr_y + 7,
            "Lots", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_risk", x + 440, curr_y + 7,
            "Risk %", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_riskloss", x + 560, curr_y + 7,
            "Risk $", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_profit", x + 700, curr_y + 7,
            "Potential Profit", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_conf", x + 870, curr_y + 7,
            "Confidence", text_color, label_size - 1, "Arial Bold", corner);
   
   curr_y += 35;
   
   // Display all recommendations
   for(int i = 0; i < data.recommendation_count; i++) {
      SizeRecommendation rec = data.recommendations[i];
      
      // Alternating row
      if(i % 2 == 0) {
         CreateRect(OBJ_PREFIX + "row_" + IntegerToString(i), x + 40, curr_y,
                   width - 100, 45, C'31,41,55', true, corner);
      }
      
      CreateLbl(OBJ_PREFIX + "method_" + IntegerToString(i), x + 60, curr_y + 8,
               rec.method_name, text_color, label_size, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "lots_" + IntegerToString(i), x + 320, curr_y + 8,
               StringFormat("%.2f", rec.recommended_lots), header_color,
               label_size + 2, "Arial Bold", corner);
      
      color risk_color = (rec.risk_percent <= 1.0) ? C'34,197,94' :
                        (rec.risk_percent <= 2.0) ? C'251,191,36' : C'239,68,68';
      CreateLbl(OBJ_PREFIX + "risk_" + IntegerToString(i), x + 440, curr_y + 8,
               StringFormat("%.2f%%", rec.risk_percent), risk_color,
               label_size + 1, "Arial Bold", corner);
      
      CreateLbl(OBJ_PREFIX + "riskloss_" + IntegerToString(i), x + 560, curr_y + 8,
               StringFormat("$%.2f", rec.risk_amount), text_color,
               label_size, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "profit_" + IntegerToString(i), x + 700, curr_y + 8,
               StringFormat("$%.2f", rec.potential_profit), C'34,197,94',
               label_size + 1, "Arial Bold", corner);
      
      CreateLbl(OBJ_PREFIX + "conf_" + IntegerToString(i), x + 870, curr_y + 8,
               StringFormat("%d%%", rec.confidence_score), rec.recommendation_color,
               label_size, "Arial", corner);
      
      // Explanation below
      CreateLbl(OBJ_PREFIX + "exp_" + IntegerToString(i), x + 60, curr_y + 28,
               rec.explanation, C'156,163,175', label_size - 2, "Arial Italic", corner);
      
      curr_y += 50;
   }
   
   return y + panel_height;
}

//+------------------------------------------------------------------+
//| Render Risk Summary                                               |
//+------------------------------------------------------------------+
int RenderRiskSummary(PositionSizingData &data, int x, int y, int width,
                     ENUM_BASE_CORNER corner, color header_color,
                     color good_color, color warning_color, color danger_color,
                     color panel_color, color text_color, int label_size, int metric_size) {
   
   const string OBJ_PREFIX = "SIZE_";
   
   CreateRect(OBJ_PREFIX + "summary_bg", x + 20, y, width - 40, 120,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "summary_title", x + 40, curr_y,
            "QUICK SIZE GUIDE", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   int col1 = x + 80;
   int col2 = x + 400;
   int col3 = x + 720;
   
   // Conservative
   CreateRect(OBJ_PREFIX + "cons_card", col1, curr_y, 280, 60, C'34,197,94,40', true, corner);
   CreateLbl(OBJ_PREFIX + "cons_lbl", col1 + 15, curr_y + 10,
            "Conservative", good_color, label_size + 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "cons_val", col1 + 15, curr_y + 32,
            StringFormat("%.2f lots", data.conservative_size), text_color,
            label_size + 2, "Arial Black", corner);
   
   // Moderate
   CreateRect(OBJ_PREFIX + "mod_card", col2, curr_y, 280, 60, C'251,191,36,40', true, corner);
   CreateLbl(OBJ_PREFIX + "mod_lbl", col2 + 15, curr_y + 10,
            "Moderate", warning_color, label_size + 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "mod_val", col2 + 15, curr_y + 32,
            StringFormat("%.2f lots", data.moderate_size), text_color,
            label_size + 2, "Arial Black", corner);
   
   // Aggressive
   CreateRect(OBJ_PREFIX + "agg_card", col3, curr_y, 280, 60, C'239,68,68,40', true, corner);
   CreateLbl(OBJ_PREFIX + "agg_lbl", col3 + 15, curr_y + 10,
            "Aggressive", danger_color, label_size + 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "agg_val", col3 + 15, curr_y + 32,
            StringFormat("%.2f lots", data.aggressive_size), text_color,
            label_size + 2, "Arial Black", corner);
   
   return y + 120;
}

//+------------------------------------------------------------------+
//| Render Portfolio Heat Gauge                                       |
//+------------------------------------------------------------------+
int RenderHeatGauge(PositionSizingData &data, int x, int y, int width,
                    ENUM_BASE_CORNER corner, color header_color,
                    color good_color, color warning_color, color danger_color,
                    color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "SIZE_";
   
   CreateRect(OBJ_PREFIX + "heat_bg", x + 20, y, width - 40, 160,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "heat_title", x + 40, curr_y,
            "PORTFOLIO HEAT ANALYSIS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Heat bars
   int bar_width = 800;
   int bar_height = 40;
   int bar_x = x + 80;
   
   // Current heat bar
   CreateLbl(OBJ_PREFIX + "current_heat_lbl", bar_x, curr_y,
            "Current Heat:", text_color, label_size, "Arial", corner);
   curr_y += label_size + 8;
   
   CreateRect(OBJ_PREFIX + "heat_bar_bg", bar_x, curr_y, bar_width, bar_height,
              C'25,30,40', true, corner);
   
   int current_width = (int)((data.current_heat / 10.0) * bar_width);
   color heat_color = (data.current_heat < 5.0) ? good_color :
                     (data.current_heat < 8.0) ? warning_color : danger_color;
   
   if(current_width > 0) {
      CreateRect(OBJ_PREFIX + "heat_bar_fill", bar_x, curr_y, current_width, bar_height,
                heat_color, true, corner);
   }
   
   CreateLbl(OBJ_PREFIX + "heat_pct", bar_x + bar_width + 20, curr_y + 10,
            StringFormat("%.2f%%", data.current_heat), heat_color,
            label_size + 2, "Arial Black", corner);
   
   curr_y += bar_height + 15;
   
   // After trade heat bar
   CreateLbl(OBJ_PREFIX + "after_heat_lbl", bar_x, curr_y,
            "After This Trade:", text_color, label_size, "Arial", corner);
   curr_y += label_size + 8;
   
   CreateRect(OBJ_PREFIX + "after_bar_bg", bar_x, curr_y, bar_width, bar_height,
              C'25,30,40', true, corner);
   
   int after_width = (int)((data.heat_after_trade / 10.0) * bar_width);
   color after_color = (data.heat_after_trade < 5.0) ? good_color :
                      (data.heat_after_trade < 8.0) ? warning_color : danger_color;
   
   if(after_width > 0) {
      CreateRect(OBJ_PREFIX + "after_bar_fill", bar_x, curr_y, after_width, bar_height,
                after_color, true, corner);
   }
   
   CreateLbl(OBJ_PREFIX + "after_pct", bar_x + bar_width + 20, curr_y + 10,
            StringFormat("%.2f%%", data.heat_after_trade), after_color,
            label_size + 2, "Arial Black", corner);
   
   return y + 160;
}

//+------------------------------------------------------------------+
//| Clear Position Sizing Panel                                       |
//+------------------------------------------------------------------+
void ClearPositionSizingPanel() {
   const string OBJ_PREFIX = "SIZE_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_POSITION_SIZING_RENDER_MQH
