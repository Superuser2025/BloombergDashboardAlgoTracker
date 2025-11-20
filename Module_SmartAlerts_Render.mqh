//+------------------------------------------------------------------+
//|                      Module_SmartAlerts_Render.mqh               |
//|                   SMART ALERTS RENDERING                         |
//|                  Alert Panel Display Functions                   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
////#property strict

#ifndef MODULE_SMART_ALERTS_RENDER_MQH
#define MODULE_SMART_ALERTS_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_SmartAlerts.mqh"
#include "Core_UIHelpers.mqh"

//+------------------------------------------------------------------+
//| Render Smart Alerts Panel                                         |
//+------------------------------------------------------------------+
void RenderSmartAlertsPanel(AlertMonitorData &data,
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
   
   const string OBJ_PREFIX = "ALERT_";
   int panel_x = 20;
   int y = start_y;
   
   // Calculate panel height based on active alerts
   int min_height = 600;
   int alert_section_height = MathMax(300, data.active_count * 70 + 100);
   int total_height = min_height + alert_section_height;
   
   // Main background
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, total_height, bg_color, false, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, false, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "SMART ALERTS & MONITORING", header_color, header_size, "Arial Black", corner);
   
   string subtitle = StringFormat("Real-Time Alerts | %d Active | %d Today",
                                 data.active_count, data.total_alerts_today);
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            subtitle, info_color, label_size, "Arial", corner);
   
   
   
   // CLOSE BUTTON
   
   CreateCloseButton(OBJ_PREFIX, panel_x, y - 80, panel_width, corner);
   
   y += 80;
   
   // Alert Statistics Summary
   y = RenderAlertStats(data, panel_x, y, panel_width, corner, header_color,
                        good_color, warning_color, danger_color, info_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Active Alerts Section
   y = RenderActiveAlerts(data, panel_x, y, panel_width, corner, header_color,
                         warning_color, danger_color, panel_color, text_color, label_size, metric_size);
   
   y += 20;
   
   // Alert Configuration
   RenderAlertConfig(panel_x, y, panel_width, corner, header_color,
                     panel_color, text_color, label_size);
}

//+------------------------------------------------------------------+
//| Render Alert Statistics                                           |
//+------------------------------------------------------------------+
int RenderAlertStats(AlertMonitorData &data, int x, int y, int width,
                     ENUM_BASE_CORNER corner, color header_color, color good_color,
                     color warning_color, color danger_color, color info_color, color panel_color, 
                     color text_color, int label_size) {
   
   const string OBJ_PREFIX = "ALERT_";
   
   CreateRect(OBJ_PREFIX + "stats_bg", x + 20, y, width - 40, 140,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "stats_title", x + 40, curr_y,
            "TODAY'S SUMMARY", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Row 1: Alerts today and critical alerts
   int col1_x = x + 60;
   int col2_x = x + 300;
   int col3_x = x + 540;
   int col4_x = x + 780;
   
   CreateLbl(OBJ_PREFIX + "stat_lbl1", col1_x, curr_y,
            "Total Alerts:", text_color, label_size, "Arial", corner);
   
   string total_str = IntegerToString(data.alerts_triggered_today);
   CreateLbl(OBJ_PREFIX + "stat_val1", col1_x, curr_y + label_size + 5,
            total_str, info_color, label_size + 4, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "stat_lbl2", col2_x, curr_y,
            "Critical:", text_color, label_size, "Arial", corner);
   
   color crit_color = (data.critical_alerts_today > 0) ? danger_color : good_color;
   string crit_str = IntegerToString(data.critical_alerts_today);
   CreateLbl(OBJ_PREFIX + "stat_val2", col2_x, curr_y + label_size + 5,
            crit_str, crit_color, label_size + 4, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "stat_lbl3", col3_x, curr_y,
            "Win Streak:", text_color, label_size, "Arial", corner);
   
   string win_str = IntegerToString(data.current_win_streak);
   CreateLbl(OBJ_PREFIX + "stat_val3", col3_x, curr_y + label_size + 5,
            win_str, good_color, label_size + 4, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "stat_lbl4", col4_x, curr_y,
            "Loss Streak:", text_color, label_size, "Arial", corner);
   
   color loss_color = (data.current_loss_streak > 0) ? danger_color : good_color;
   string loss_str = IntegerToString(data.current_loss_streak);
   CreateLbl(OBJ_PREFIX + "stat_val4", col4_x, curr_y + label_size + 5,
            loss_str, loss_color, label_size + 4, "Arial Black", corner);
   
   curr_y += label_size + 50;
   
   // Daily P&L
   CreateLbl(OBJ_PREFIX + "daily_pl_lbl", col1_x, curr_y,
            "Daily P&L:", text_color, label_size, "Arial", corner);
   
   color pl_color = (data.daily_pl >= 0) ? good_color : danger_color;
   string pl_str = StringFormat("$%.2f", data.daily_pl);
   CreateLbl(OBJ_PREFIX + "daily_pl_val", col1_x + 120, curr_y,
            pl_str, pl_color, label_size + 4, "Arial Black", corner);
   
   return y + 140;
}

//+------------------------------------------------------------------+
//| Render Active Alerts                                              |
//+------------------------------------------------------------------+
int RenderActiveAlerts(AlertMonitorData &data, int x, int y, int width,
                       ENUM_BASE_CORNER corner, color header_color,
                       color warning_color, color danger_color, color panel_color,
                       color text_color, int label_size, int metric_size) {
   
   const string OBJ_PREFIX = "ALERT_";
   
   int section_height = MathMax(300, data.active_count * 70 + 100);
   
   CreateRect(OBJ_PREFIX + "active_bg", x + 20, y, width - 40, section_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "active_title", x + 40, curr_y,
            "ACTIVE ALERTS", header_color, label_size + 3, "Arial Black", corner);
   
   // Clear button
   CreateBtn(OBJ_PREFIX + "clear_all", x + width - 200, curr_y - 5, 140, 35,
            "CLEAR ALL", text_color, C'55,65,81', corner);
   
   curr_y += label_size + 25;
   
   if(data.active_count == 0) {
      CreateLbl(OBJ_PREFIX + "no_alerts", x + 40, curr_y + 50,
               "✓ No active alerts - All systems normal", C'34,197,94', 
               label_size + 2, "Arial Bold", corner);
      return y + section_height;
   }
   
   // Display active alerts (up to 10 most recent)
   int displayed = MathMin(data.active_count, 10);
   
   for(int i = 0; i < displayed; i++) {
      if(!data.active_alerts[i].is_active) continue;
      
      // Alert card
      int card_h = 60;
      CreateRect(OBJ_PREFIX + "card_" + IntegerToString(i), x + 40, curr_y,
                width - 100, card_h, data.active_alerts[i].alert_color, true, corner);
      
      // Priority indicator
      string priority_text = "";
      switch(data.active_alerts[i].priority) {
         case PRIORITY_INFO: priority_text = "ℹ INFO"; break;
         case PRIORITY_WARNING: priority_text = "⚠ WARNING"; break;
         case PRIORITY_CRITICAL: priority_text = "🔴 CRITICAL"; break;
      }
      
      CreateLbl(OBJ_PREFIX + "priority_" + IntegerToString(i), x + 55, curr_y + 8,
               priority_text, text_color, label_size + 1, "Arial Black", corner);
      
      // Time
      string time_str = TimeToString(data.active_alerts[i].timestamp, TIME_MINUTES);
      CreateLbl(OBJ_PREFIX + "time_" + IntegerToString(i), x + 180, curr_y + 8,
               time_str, text_color, label_size - 1, "Arial", corner);
      
      // Message
      CreateLbl(OBJ_PREFIX + "msg_" + IntegerToString(i), x + 55, curr_y + 28,
               data.active_alerts[i].message, text_color, label_size + 1, "Arial Bold", corner);
      
      // Acknowledge button
      if(!data.active_alerts[i].acknowledged) {
         CreateBtn(OBJ_PREFIX + "ack_" + IntegerToString(i), x + width - 180, curr_y + 12,
                  100, 35, "ACK", text_color, C'55,65,81', corner);
      }
      
      curr_y += card_h + 8;
   }
   
   if(data.active_count > 10) {
      string more_text = StringFormat("+ %d more alerts...", data.active_count - 10);
      CreateLbl(OBJ_PREFIX + "more_alerts", x + 40, curr_y,
               more_text, text_color, label_size, "Arial Italic", corner);
   }
   
   return y + section_height;
}

//+------------------------------------------------------------------+
//| Render Alert Configuration                                        |
//+------------------------------------------------------------------+
int RenderAlertConfig(int x, int y, int width, ENUM_BASE_CORNER corner,
                      color header_color, color panel_color, color text_color, 
                      int label_size) {
   
   const string OBJ_PREFIX = "ALERT_";
   
   CreateRect(OBJ_PREFIX + "config_bg", x + 20, y, width - 40, 180,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "config_title", x + 40, curr_y,
            "ALERT SETTINGS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Quick settings
   int col_x = x + 60;
   int row_spacing = 35;
   
   CreateLbl(OBJ_PREFIX + "margin_setting", col_x, curr_y,
            StringFormat("Margin Warning: %.0f%% | Critical: %.0f%%",
                        g_alert_config.margin_warning_level,
                        g_alert_config.margin_critical_level),
            text_color, label_size, "Arial", corner);
   curr_y += row_spacing;
   
   CreateLbl(OBJ_PREFIX + "dd_setting", col_x, curr_y,
            StringFormat("Max Drawdown: %.1f%% | Critical: %.1f%%",
                        g_alert_config.max_drawdown_warning,
                        g_alert_config.max_drawdown_critical),
            text_color, label_size, "Arial", corner);
   curr_y += row_spacing;
   
   CreateLbl(OBJ_PREFIX + "streak_setting", col_x, curr_y,
            StringFormat("Win Streak Alert: %d | Loss Streak Alert: %d",
                        g_alert_config.win_streak_threshold,
                        g_alert_config.loss_streak_threshold),
            text_color, label_size, "Arial", corner);
   curr_y += row_spacing;
   
   CreateLbl(OBJ_PREFIX + "limit_setting", col_x, curr_y,
            StringFormat("Daily Loss Limit: $%.0f | Profit Target: $%.0f",
                        g_alert_config.daily_loss_limit,
                        g_alert_config.daily_profit_target),
            text_color, label_size, "Arial", corner);
   
   // Settings button
   CreateBtn(OBJ_PREFIX + "settings_btn", x + width - 200, y + 15, 140, 35,
            "CONFIGURE", text_color, C'55,65,81', corner);
   
   return y + 180;
}

//+------------------------------------------------------------------+
//| Clear Smart Alerts Panel                                          |
//+------------------------------------------------------------------+
void ClearSmartAlertsPanel() {
   const string OBJ_PREFIX = "ALERT_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_SMART_ALERTS_RENDER_MQH
