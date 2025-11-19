//+------------------------------------------------------------------+
//|                   Module_ScenarioSimulator_Render.mqh            |
//|              SCENARIO SIMULATOR RENDERING FUNCTIONS              |
//|                  Display Functions for Scenario Module           |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_SCENARIO_SIMULATOR_RENDER_MQH
#define MODULE_SCENARIO_SIMULATOR_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_ScenarioSimulator.mqh"
#include "Core_UIHelpers.mqh"

// Global state for scenario module
int g_selected_algo_idx = 0;
int g_selected_scenario = 0;  // 0=Close Algo, 1=Market Gap, 2=Close All Losing, 3=Reduce Size
double g_gap_pips = 100;
double g_reduce_pct = 50;


//+------------------------------------------------------------------+
//| Render Scenario Simulator Panel                                   |
//+------------------------------------------------------------------+
void RenderScenarioSimulatorPanel(ScenarioResult &current_scenario,
                                  AlgoMetrics &algo_list[],
                                  int total_algos,
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
   
   const string OBJ_PREFIX = "SCENARIO_";
   int panel_x = 20;
   int y = start_y;
   
   // Main background - REDUCED HEIGHT to fit on screen
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, 650, bg_color, true, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "SCENARIO SIMULATOR", header_color, header_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            "What-If Analysis | See Impact BEFORE You Act",
            info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Scenario selector
   CreateRect(OBJ_PREFIX + "selector_bg", panel_x + 20, y, panel_width - 40, 80,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "selector_title", panel_x + 40, curr_y,
            "SELECT SCENARIO:", header_color, label_size + 2, "Arial Bold", corner);
   curr_y += label_size + 18;
   
   int btn_w = 330;
   int btn_h = 40;
   int spacing = 12;
   int btn_x = panel_x + 40;
   
   color btn1_color = (g_selected_scenario == 0) ? info_color : C'55,65,81';
   CreateBtn(OBJ_PREFIX + "scenario_close", btn_x, curr_y, btn_w, btn_h,
            "CLOSE ALGO", text_color, btn1_color, corner);
   
   btn_x += btn_w + spacing;
   color btn2_color = (g_selected_scenario == 1) ? info_color : C'55,65,81';
   CreateBtn(OBJ_PREFIX + "scenario_gap", btn_x, curr_y, btn_w, btn_h,
            "MARKET GAP", text_color, btn2_color, corner);
   
   btn_x += btn_w + spacing;
   color btn3_color = (g_selected_scenario == 2) ? info_color : C'55,65,81';
   CreateBtn(OBJ_PREFIX + "scenario_all", btn_x, curr_y, btn_w, btn_h,
            "CLOSE ALL LOSING", text_color, btn3_color, corner);
   
   btn_x += btn_w + spacing;
   color btn4_color = (g_selected_scenario == 3) ? info_color : C'55,65,81';
   CreateBtn(OBJ_PREFIX + "scenario_reduce", btn_x, curr_y, btn_w, btn_h,
            "REDUCE SIZE", text_color, btn4_color, corner);
   
   y += 90;
   
   // Scenario controls
   CreateRect(OBJ_PREFIX + "controls_bg", panel_x + 20, y, panel_width - 40, 75,
              C'25,30,40', true, corner);
   
   curr_y = y + 15;
   
   if(g_selected_scenario == 0 && total_algos > 0) {
      CreateLbl(OBJ_PREFIX + "control_label", panel_x + 40, curr_y,
               "SELECT ALGO:", text_color, label_size + 1, "Arial Bold", corner);
      curr_y += label_size + 12;
      
      CreateBtn(OBJ_PREFIX + "algo_prev", panel_x + 40, curr_y, 90, 32,
               "< PREV", text_color, C'55,65,81', corner);
      
      string algo_name = algo_list[g_selected_algo_idx].name;
      CreateLbl(OBJ_PREFIX + "algo_current", panel_x + 150, curr_y + 6,
               algo_name, header_color, label_size + 3, "Arial Bold", corner);
      
      CreateBtn(OBJ_PREFIX + "algo_next", panel_x + 380, curr_y, 90, 32,
               "NEXT >", text_color, C'55,65,81', corner);
      
   } else if(g_selected_scenario == 1) {
      CreateLbl(OBJ_PREFIX + "control_label", panel_x + 40, curr_y,
               "GAP SIZE:", text_color, label_size + 1, "Arial Bold", corner);
      curr_y += label_size + 12;
      
      CreateBtn(OBJ_PREFIX + "gap_down", panel_x + 40, curr_y, 75, 32,
               "- 50", text_color, C'55,65,81', corner);
      
      string gap_text = StringFormat("%.0f pips", g_gap_pips);
      CreateLbl(OBJ_PREFIX + "gap_current", panel_x + 135, curr_y + 6,
               gap_text, header_color, label_size + 4, "Arial Black", corner);
      
      CreateBtn(OBJ_PREFIX + "gap_up", panel_x + 270, curr_y, 75, 32,
               "+ 50", text_color, C'55,65,81', corner);
      
   } else if(g_selected_scenario == 3) {
      CreateLbl(OBJ_PREFIX + "control_label", panel_x + 40, curr_y,
               "REDUCTION:", text_color, label_size + 1, "Arial Bold", corner);
      curr_y += label_size + 12;
      
      CreateBtn(OBJ_PREFIX + "reduce_down", panel_x + 40, curr_y, 75, 32,
               "- 10%", text_color, C'55,65,81', corner);
      
      string reduce_text = StringFormat("%.0f%%", g_reduce_pct);
      CreateLbl(OBJ_PREFIX + "reduce_current", panel_x + 135, curr_y + 6,
               reduce_text, header_color, label_size + 4, "Arial Black", corner);
      
      CreateBtn(OBJ_PREFIX + "reduce_up", panel_x + 250, curr_y, 75, 32,
               "+ 10%", text_color, C'55,65,81', corner);
   }
   
   y += 85;
   
   // Before/After comparison - SIDE BY SIDE
   int panel_height = 350;
   
   int left_x = panel_x + 20;
   int left_w = (panel_width - 60) / 2;
   CreateRect(OBJ_PREFIX + "before_bg", left_x, y, left_w, panel_height,
              panel_color, true, corner);
   
   int right_x = left_x + left_w + 20;
   int right_w = left_w;
   CreateRect(OBJ_PREFIX + "after_bg", right_x, y, right_w, panel_height,
              panel_color, true, corner);
   
   curr_y = y + 15;
   
   CreateLbl(OBJ_PREFIX + "before_title", left_x + 15, curr_y,
            "BEFORE", warning_color, metric_size + 2, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "after_title", right_x + 15, curr_y,
            "AFTER", good_color, metric_size + 2, "Arial Black", corner);
   
   curr_y += metric_size + 25;
   
   // BEFORE metrics
   int metric_y = curr_y;
   RenderScenarioMetric("Equity:", current_scenario.before_equity, left_x + 25, metric_y, text_color, label_size, metric_size);
   metric_y += 45;
   
   RenderScenarioMetric("Margin:", current_scenario.before_margin_level, left_x + 25, metric_y, text_color, label_size, metric_size, "%");
   metric_y += 45;
   
   RenderScenarioMetric("Float P&L:", current_scenario.before_floating_pl, left_x + 25, metric_y,
               (current_scenario.before_floating_pl >= 0) ? good_color : danger_color, label_size, metric_size);
   metric_y += 45;
   
   RenderScenarioMetric("Lots:", current_scenario.before_total_lots, left_x + 25, metric_y, text_color, label_size, metric_size);
   metric_y += 45;
   
   string pos_text = StringFormat("%d positions", current_scenario.before_position_count);
   CreateLbl(OBJ_PREFIX + "before_pos", left_x + 25, metric_y,
            pos_text, C'156,163,175', label_size - 1, "Arial", corner);
   
   // AFTER metrics
   metric_y = curr_y;
   RenderScenarioMetric("Equity:", current_scenario.after_equity, right_x + 25, metric_y, text_color, label_size, metric_size);
   metric_y += 45;
   
   color ml_color = (current_scenario.after_margin_level > current_scenario.before_margin_level) ? good_color : danger_color;
   RenderScenarioMetric("Margin:", current_scenario.after_margin_level, right_x + 25, metric_y, ml_color, label_size, metric_size, "%");
   metric_y += 45;
   
   RenderScenarioMetric("Float P&L:", current_scenario.after_floating_pl, right_x + 25, metric_y,
               (current_scenario.after_floating_pl >= 0) ? good_color : danger_color, label_size, metric_size);
   metric_y += 45;
   
   RenderScenarioMetric("Lots:", current_scenario.after_total_lots, right_x + 25, metric_y, text_color, label_size, metric_size);
   metric_y += 45;
   
   StringFormat(pos_text, "%d positions", current_scenario.after_position_count);
   CreateLbl(OBJ_PREFIX + "after_pos", right_x + 25, metric_y,
            pos_text, C'156,163,175', label_size - 1, "Arial", corner);
   
   y += panel_height + 10;
   
   // Impact Analysis
   CreateRect(OBJ_PREFIX + "impact_bg", panel_x + 20, y, panel_width - 40, 160,
              panel_color, true, corner);
   
   curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "impact_title", panel_x + 40, curr_y,
            "IMPACT ANALYSIS", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   CreateLbl(OBJ_PREFIX + "action", panel_x + 40, curr_y,
            "ACTION: " + current_scenario.action_description, info_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 15;
   
   CreateLbl(OBJ_PREFIX + "impact", panel_x + 40, curr_y,
            "IMPACT: " + current_scenario.impact_summary, text_color, label_size, "Arial", corner);
   curr_y += label_size + 18;
   
   // Warnings & Benefits
   if(current_scenario.warning_count > 0) {
      CreateLbl(OBJ_PREFIX + "warnings_title", panel_x + 40, curr_y,
               "⚠ WARNINGS:", danger_color, label_size + 1, "Arial Bold", corner);
      curr_y += label_size + 10;
      
      for(int i = 0; i < MathMin(current_scenario.warning_count, 2); i++) {
         CreateLbl(OBJ_PREFIX + "warning_" + IntegerToString(i), panel_x + 55, curr_y,
                  "• " + current_scenario.warnings[i], danger_color, label_size - 1, "Arial", corner);
         curr_y += label_size + 5;
      }
      curr_y += 5;
   }
   
   if(current_scenario.benefit_count > 0) {
      CreateLbl(OBJ_PREFIX + "benefits_title", panel_x + 40, curr_y,
               "✓ BENEFITS:", good_color, label_size + 1, "Arial Bold", corner);
      curr_y += label_size + 10;
      
      for(int i = 0; i < MathMin(current_scenario.benefit_count, 2); i++) {
         CreateLbl(OBJ_PREFIX + "benefit_" + IntegerToString(i), panel_x + 55, curr_y,
                  "• " + current_scenario.benefits[i], good_color, label_size - 1, "Arial", corner);
         curr_y += label_size + 5;
      }
   }
   
   y += 170;
   
   // Recommendation
   CreateRect(OBJ_PREFIX + "rec_bg", panel_x + 20, y, panel_width - 40, 100,
              current_scenario.recommendation_color, true, corner);
   
   curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "rec_title", panel_x + 40, curr_y,
            "RECOMMENDATION", text_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 20;
   
   CreateLbl(OBJ_PREFIX + "rec_text", panel_x + 40, curr_y,
            current_scenario.recommendation, text_color, metric_size + 2, "Arial Black", corner);
   curr_y += metric_size + 12;
   
   string confidence = StringFormat("Confidence: %.0f%%", current_scenario.confidence_score);
   CreateLbl(OBJ_PREFIX + "confidence", panel_x + 40, curr_y,
            confidence, text_color, label_size + 1, "Arial", corner);
}

//+------------------------------------------------------------------+
//| Helper: Render Scenario Metric                                    |
//+------------------------------------------------------------------+
void RenderScenarioMetric(string label, double value, int x, int y, color clr,
                         int label_size, int metric_size, string suffix = "") {
   const string OBJ_PREFIX = "SCENARIO_";
   
   CreateLbl(OBJ_PREFIX + "metric_lbl_" + label, x, y,
            label, C'156,163,175', label_size - 1, "Arial", CORNER_LEFT_UPPER);
   
   string value_text = "";
   if(suffix == "%") {
      value_text = StringFormat("%.1f%%", value);
   } else {
      value_text = StringFormat("$%.2f", value);
   }
   
   CreateLbl(OBJ_PREFIX + "metric_val_" + label, x, y + label_size + 3,
            value_text, clr, metric_size, "Arial Black", CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Clear Scenario Simulator Panel Objects                            |
//+------------------------------------------------------------------+
void ClearScenarioSimulatorPanel() {
   const string OBJ_PREFIX = "SCENARIO_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_SCENARIO_SIMULATOR_RENDER_MQH
