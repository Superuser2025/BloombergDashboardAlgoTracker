//+------------------------------------------------------------------+
//|                      Module_AdvancedRisk_Render.mqh              |
//|                 ADVANCED RISK ANALYTICS RENDERING                |
//|                  Display Functions for Risk Module               |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_ADVANCED_RISK_RENDER_MQH
#define MODULE_ADVANCED_RISK_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_AdvancedRisk.mqh"
#include "Core_UIHelpers.mqh"

// Rendering functions for Advanced Risk Analytics panel

//+------------------------------------------------------------------+
//| Render Advanced Risk Panel                                        |
//+------------------------------------------------------------------+
void RenderAdvancedRiskPanel(AdvancedRiskMetrics &risk, 
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
   
   const string PREFIX = "RISK_";
   int panel_x = 20;
   int y = start_y;
   
   // Main background - REDUCED HEIGHT to fit on screen
   CreateRect(PREFIX + "main_bg", panel_x, y, panel_width, 700, bg_color, true, corner);
   
   // Header
   CreateRect(PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(PREFIX + "title", panel_x + 20, y + 15,
            "ADVANCED RISK ANALYTICS", header_color, header_size, "Arial Black", corner);
   
   CreateLbl(PREFIX + "subtitle", panel_x + 20, y + 45,
            "VaR | CVaR | Kelly | Monte Carlo | MAE/MFE | Risk Score",
            info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Risk Score - BIG PROMINENT DISPLAY
   CreateRect(PREFIX + "risk_bg", panel_x + 20, y, panel_width - 40, 100, 
              panel_color, true, corner);
   
   CreateLbl(PREFIX + "risk_label", panel_x + 40, y + 15,
            "PORTFOLIO RISK LEVEL", text_color, label_size + 2, "Arial Bold", corner);
   
   string score_text = StringFormat("%.0f / 100", risk.risk_score);
   CreateLbl(PREFIX + "risk_score", panel_x + 40, y + 45,
            score_text, risk.risk_color, 36, "Arial Black", corner);
   
   CreateLbl(PREFIX + "risk_level", panel_x + 250, y + 50,
            risk.risk_level, risk.risk_color, 32, "Arial Black", corner);
   
   y += 110;
   
   // Three columns layout
   int col1_x = panel_x + 30;
   int col2_x = panel_x + 480;
   int col3_x = panel_x + 930;
   int col_y = y;
   
   // Column 1: VaR & CVaR
   CreateRect(PREFIX + "var_panel", col1_x, col_y, 420, 350, panel_color, true, corner);
   
   int curr_y = col_y + 15;
   CreateLbl(PREFIX + "var_title", col1_x + 15, curr_y,
            "VALUE AT RISK", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   CreateLbl(PREFIX + "var95_label", col1_x + 15, curr_y,
            "95% VaR:", text_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 8;
   
   string var95_text = StringFormat("$%.2f", risk.var_95);
   color var95_color = (risk.var_95 > 1000) ? danger_color : warning_color;
   CreateLbl(PREFIX + "var95_value", col1_x + 30, curr_y,
            var95_text, var95_color, metric_size + 4, "Arial Black", corner);
   curr_y += metric_size + 18;
   
   CreateLbl(PREFIX + "var99_label", col1_x + 15, curr_y,
            "99% VaR:", text_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 8;
   
   string var99_text = StringFormat("$%.2f", risk.var_99);
   CreateLbl(PREFIX + "var99_value", col1_x + 30, curr_y,
            var99_text, danger_color, metric_size + 4, "Arial Black", corner);
   curr_y += metric_size + 18;
   
   CreateLine(PREFIX + "var_line", col1_x + 15, curr_y, 390, C'75,85,99', corner);
   curr_y += 12;
   
   CreateLbl(PREFIX + "cvar_label", col1_x + 15, curr_y,
            "Expected Shortfall:", text_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 8;
   
   string cvar_text = StringFormat("$%.2f", risk.cvar_95);
   CreateLbl(PREFIX + "cvar_value", col1_x + 30, curr_y,
            cvar_text, danger_color, metric_size + 2, "Arial Black", corner);
   
   // Column 2: Kelly & MAE/MFE
   CreateRect(PREFIX + "kelly_panel", col2_x, col_y, 420, 350, panel_color, true, corner);
   
   curr_y = col_y + 15;
   CreateLbl(PREFIX + "kelly_title", col2_x + 15, curr_y,
            "KELLY CRITERION", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   CreateLbl(PREFIX + "kelly_half_label", col2_x + 15, curr_y,
            "Half Kelly (Recommended):", good_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 8;
   
   string kelly_text = StringFormat("%.2f%%", risk.kelly_half);
   CreateLbl(PREFIX + "kelly_value", col2_x + 30, curr_y,
            kelly_text, good_color, metric_size + 4, "Arial Black", corner);
   curr_y += metric_size + 12;
   
   CreateLbl(PREFIX + "kelly_rec", col2_x + 30, curr_y,
            risk.kelly_recommendation, C'156,163,175', label_size, "Arial", corner);
   curr_y += label_size + 20;
   
   CreateLine(PREFIX + "kelly_line", col2_x + 15, curr_y, 390, C'75,85,99', corner);
   curr_y += 12;
   
   CreateLbl(PREFIX + "mae_title", col2_x + 15, curr_y,
            "MAE/MFE", header_color, label_size + 2, "Arial Bold", corner);
   curr_y += label_size + 12;
   
   string mae_text = StringFormat("Avg MAE: $%.2f", risk.mae_avg);
   CreateLbl(PREFIX + "mae_value", col2_x + 15, curr_y,
            mae_text, danger_color, label_size, "Arial", corner);
   curr_y += label_size + 8;
   
   string mfe_text = StringFormat("Avg MFE: $%.2f", risk.mfe_avg);
   CreateLbl(PREFIX + "mfe_value", col2_x + 15, curr_y,
            mfe_text, good_color, label_size, "Arial", corner);
   
   // Column 3: Monte Carlo
   CreateRect(PREFIX + "mc_panel", col3_x, col_y, 440, 350, panel_color, true, corner);
   
   curr_y = col_y + 15;
   CreateLbl(PREFIX + "mc_title", col3_x + 15, curr_y,
            "MONTE CARLO", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   string prob_profit = StringFormat("Profit Probability: %.1f%%", risk.mc_prob_profit);
   color prob_color = (risk.mc_prob_profit > 60) ? good_color : warning_color;
   CreateLbl(PREFIX + "mc_prob", col3_x + 15, curr_y,
            prob_profit, prob_color, label_size + 2, "Arial Bold", corner);
   curr_y += label_size + 18;
   
   CreateLine(PREFIX + "mc_line1", col3_x + 15, curr_y, 410, C'75,85,99', corner);
   curr_y += 12;
   
   CreateLbl(PREFIX + "mc_risk_title", col3_x + 15, curr_y,
            "DOWNSIDE RISKS:", danger_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 12;
   
   string loss10 = StringFormat("> 10%% Loss: %.1f%%", risk.mc_prob_10pct_loss);
   CreateLbl(PREFIX + "mc_loss10", col3_x + 25, curr_y,
            loss10, warning_color, label_size, "Arial", corner);
   curr_y += label_size + 8;
   
   string loss20 = StringFormat("> 20%% Loss: %.1f%%", risk.mc_prob_20pct_loss);
   CreateLbl(PREFIX + "mc_loss20", col3_x + 25, curr_y,
            loss20, danger_color, label_size, "Arial", corner);
   curr_y += label_size + 18;
   
   CreateLine(PREFIX + "mc_line2", col3_x + 15, curr_y, 410, C'75,85,99', corner);
   curr_y += 12;
   
   CreateLbl(PREFIX + "mc_upside_title", col3_x + 15, curr_y,
            "UPSIDE:", good_color, label_size + 1, "Arial Bold", corner);
   curr_y += label_size + 12;
   
   string gain50 = StringFormat("> 50%% Gain: %.1f%%", risk.mc_prob_50pct_gain);
   CreateLbl(PREFIX + "mc_gain50", col3_x + 25, curr_y,
            gain50, good_color, label_size, "Arial", corner);
   
   // Bottom row: Risk-Adjusted Returns & Drawdown
   y = col_y + 360;
   
   CreateRect(PREFIX + "ratios_panel", panel_x + 30, y, panel_width - 60, 130,
              panel_color, true, corner);
   
   curr_y = y + 15;
   CreateLbl(PREFIX + "ratios_title", panel_x + 50, curr_y,
            "RISK-ADJUSTED RETURNS", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   int rat_col1 = panel_x + 60;
   int rat_col2 = panel_x + 350;
   int rat_col3 = panel_x + 640;
   int rat_col4 = panel_x + 930;
   
   CreateLbl(PREFIX + "sharpe_label", rat_col1, curr_y,
            "Sharpe:", text_color, label_size, "Arial", corner);
   string sharpe = StringFormat("%.3f", risk.sharpe_ratio);
   color sharpe_color = (risk.sharpe_ratio > 1.0) ? good_color : 
                       (risk.sharpe_ratio > 0) ? warning_color : danger_color;
   CreateLbl(PREFIX + "sharpe_value", rat_col1, curr_y + label_size + 5,
            sharpe, sharpe_color, label_size + 6, "Arial Black", corner);
   
   CreateLbl(PREFIX + "sortino_label", rat_col2, curr_y,
            "Sortino:", text_color, label_size, "Arial", corner);
   string sortino = StringFormat("%.3f", risk.sortino_ratio);
   CreateLbl(PREFIX + "sortino_value", rat_col2, curr_y + label_size + 5,
            sortino, sharpe_color, label_size + 6, "Arial Black", corner);
   
   CreateLbl(PREFIX + "skew_label", rat_col3, curr_y,
            "Skewness:", text_color, label_size, "Arial", corner);
   string skew = StringFormat("%.3f", risk.skewness);
   color skew_color = (risk.skewness > 0) ? good_color : warning_color;
   CreateLbl(PREFIX + "skew_value", rat_col3, curr_y + label_size + 5,
            skew, skew_color, label_size + 6, "Arial Black", corner);
   
   CreateLbl(PREFIX + "kurt_label", rat_col4, curr_y,
            "Kurtosis:", text_color, label_size, "Arial", corner);
   string kurt = StringFormat("%.3f", risk.kurtosis);
   color kurt_color = risk.has_fat_tails ? danger_color : good_color;
   CreateLbl(PREFIX + "kurt_value", rat_col4, curr_y + label_size + 5,
            kurt, kurt_color, label_size + 6, "Arial Black", corner);
   
   // Drawdown
   y += 140;
   CreateRect(PREFIX + "dd_panel", panel_x + 30, y, panel_width - 60, 130,
              panel_color, true, corner);
   
   curr_y = y + 15;
   CreateLbl(PREFIX + "dd_title", panel_x + 50, curr_y,
            "DRAWDOWN & STRESS TEST", header_color, metric_size, "Arial Black", corner);
   curr_y += metric_size + 20;
   
   int dd_col1 = panel_x + 60;
   int dd_col2 = panel_x + 400;
   int dd_col3 = panel_x + 740;
   
   CreateLbl(PREFIX + "dd_current_label", dd_col1, curr_y,
            "Current DD:", text_color, label_size, "Arial", corner);
   string dd_current = StringFormat("%.2f%%", risk.current_dd);
   color dd_color = (risk.current_dd > 15) ? danger_color : 
                   (risk.current_dd > 8) ? warning_color : good_color;
   CreateLbl(PREFIX + "dd_current_value", dd_col1, curr_y + label_size + 5,
            dd_current, dd_color, label_size + 6, "Arial Black", corner);
   
   CreateLbl(PREFIX + "dd_max_label", dd_col2, curr_y,
            "Max DD:", text_color, label_size, "Arial", corner);
   string dd_max = StringFormat("%.2f%%", risk.max_dd);
   CreateLbl(PREFIX + "dd_max_value", dd_col2, curr_y + label_size + 5,
            dd_max, danger_color, label_size + 6, "Arial Black", corner);
   
   CreateLbl(PREFIX + "stress_label", dd_col3, curr_y,
            "Stress (10% move):", text_color, label_size, "Arial", corner);
   string stress = StringFormat("$%.0f", MathAbs(risk.stress_10pct));
   CreateLbl(PREFIX + "stress_value", dd_col3, curr_y + label_size + 5,
            stress, danger_color, label_size + 6, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Clear Advanced Risk Panel Objects                                 |
//+------------------------------------------------------------------+
void ClearAdvancedRiskPanel() {
   const string PREFIX = "RISK_";
   CleanupObjects(PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_ADVANCED_RISK_RENDER_MQH
