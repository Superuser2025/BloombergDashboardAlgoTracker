//+------------------------------------------------------------------+
//|                      Module_VisualAnalytics_Render.mqh           |
//|                   VISUAL ANALYTICS RENDERING                     |
//|                  Chart & Graph Display Functions                 |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
////#property strict

#ifndef MODULE_VISUAL_ANALYTICS_RENDER_MQH
#define MODULE_VISUAL_ANALYTICS_RENDER_MQH

#include "Module_VisualAnalytics.mqh"
#include "Core_UIHelpers.mqh"

//+------------------------------------------------------------------+
//| Render Visual Analytics Panel                                     |
//+------------------------------------------------------------------+
void RenderVisualAnalyticsPanel(VisualAnalyticsData &data,
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
   
   const string OBJ_PREFIX = "VISUAL_";
   int panel_x = 20;
   int y = start_y;
   
   // Main background
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, 1200, bg_color, true, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "VISUAL ANALYTICS", header_color, header_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            "Equity Curve | Performance Heatmap | Distribution Analysis",
            info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Equity Curve
   y = RenderEquityCurve(data, panel_x, y, panel_width, corner, header_color, 
                        good_color, danger_color, info_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Performance Heatmap
   y = RenderPerformanceHeatmap(data, panel_x, y, panel_width, corner, header_color,
                                panel_color, text_color, label_size);
   
   y += 20;
   
   // Win/Loss Distribution
   y = RenderWinLossDistribution(data, panel_x, y, panel_width, corner, header_color,
                                 good_color, danger_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Monthly Performance Grid
   RenderMonthlyPerformance(data, panel_x, y, panel_width, corner, header_color,
                           panel_color, text_color, label_size);
}

//+------------------------------------------------------------------+
//| Render Equity Curve                                               |
//+------------------------------------------------------------------+
int RenderEquityCurve(VisualAnalyticsData &data, int x, int y, int width,
                      ENUM_BASE_CORNER corner, color header_color, color good_color,
                      color danger_color, color info_color, color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "VISUAL_";
   int chart_width = width - 100;
   int chart_height = 220;
   
   CreateRect(OBJ_PREFIX + "eq_panel", x + 20, y, width - 40, chart_height + 80,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "eq_title", x + 40, curr_y,
            "EQUITY CURVE", header_color, label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   if(data.equity_points < 2) {
      CreateLbl(OBJ_PREFIX + "eq_nodata", x + 40, curr_y,
               "Insufficient data - need more trading history", text_color, label_size, "Arial", corner);
      return y + chart_height + 80;
   }
   
   // Chart area
   int chart_x = x + 60;
   int chart_y = curr_y;
   
   CreateRect(OBJ_PREFIX + "eq_chart_bg", chart_x, chart_y, chart_width, chart_height,
              C'25,30,40', true, corner);
   
   // Draw equity line
   double range = data.max_equity - data.min_equity;
   if(range < 1) range = 1;
   
   double x_step = (double)chart_width / (data.equity_points - 1);
   
   for(int i = 0; i < data.equity_points - 1; i++) {
      int x1 = chart_x + (int)(i * x_step);
      int x2 = chart_x + (int)((i + 1) * x_step);
      
      double y1_pct = (data.equity_curve[i].equity - data.min_equity) / range;
      double y2_pct = (data.equity_curve[i+1].equity - data.min_equity) / range;
      
      int y1 = chart_y + chart_height - (int)(y1_pct * chart_height);
      int y2 = chart_y + chart_height - (int)(y2_pct * chart_height);
      
      string line_name = OBJ_PREFIX + "eq_line_" + IntegerToString(i);
      ObjectCreate(0, line_name, OBJ_TREND, 0, 0, 0);
      ObjectSetInteger(0, line_name, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, line_name, OBJPROP_XDISTANCE, x1);
      ObjectSetInteger(0, line_name, OBJPROP_YDISTANCE, y1);
      ObjectSetInteger(0, line_name, OBJPROP_XSIZE, x2 - x1);
      ObjectSetInteger(0, line_name, OBJPROP_YSIZE, y2 - y1);
      ObjectSetInteger(0, line_name, OBJPROP_COLOR, info_color);
      ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, line_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, line_name, OBJPROP_HIDDEN, true);
      
      // Shade drawdown area
      if(data.equity_curve[i].is_underwater) {
         int shade_y = chart_y + chart_height - (int)(y1_pct * chart_height);
         int shade_h = chart_height - shade_y + chart_y;
         
         CreateRect(OBJ_PREFIX + "eq_dd_" + IntegerToString(i), x1, shade_y,
                   (int)x_step, shade_h, C'139,0,0,30', true, corner);
      }
   }
   
   // Stats
   curr_y = chart_y + chart_height + 15;
   
   string stats = StringFormat("Current: $%.2f | Peak: $%.2f | Range: $%.2f",
                              data.current_equity, data.max_equity, range);
   CreateLbl(OBJ_PREFIX + "eq_stats", x + 60, curr_y,
            stats, text_color, label_size, "Arial", corner);
   
   return y + chart_height + 80;
}

//+------------------------------------------------------------------+
//| Render Performance Heatmap                                        |
//+------------------------------------------------------------------+
int RenderPerformanceHeatmap(VisualAnalyticsData &data, int x, int y, int width,
                             ENUM_BASE_CORNER corner, color header_color,
                             color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "VISUAL_";
   int panel_height = 280;
   
   CreateRect(OBJ_PREFIX + "heat_panel", x + 20, y, width - 40, panel_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "heat_title", x + 40, curr_y,
            "PERFORMANCE HEATMAP (Last 90 Days)", header_color, label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   if(data.heatmap_cells < 7) {
      CreateLbl(OBJ_PREFIX + "heat_nodata", x + 40, curr_y,
               "Insufficient data", text_color, label_size, "Arial", corner);
      return y + panel_height;
   }
   
   // Heatmap grid (13 weeks x 7 days)
   int cell_size = 15;
   int cell_spacing = 2;
   int grid_x = x + 100;
   int grid_y = curr_y;
   
   // Day labels
   string days[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
   for(int d = 0; d < 7; d++) {
      CreateLbl(OBJ_PREFIX + "heat_day_" + IntegerToString(d), x + 50, 
               grid_y + (d * (cell_size + cell_spacing)), days[d],
               text_color, label_size - 2, "Arial", corner);
   }
   
   // Draw cells
   int displayed = MathMin(data.heatmap_cells, 91); // 13 weeks
   for(int i = 0; i < displayed; i++) {
      int week = i / 7;
      int day = i % 7;
      
      int cell_x = grid_x + (week * (cell_size + cell_spacing));
      int cell_y = grid_y + (day * (cell_size + cell_spacing));
      
      CreateRect(OBJ_PREFIX + "heat_cell_" + IntegerToString(i), cell_x, cell_y,
                cell_size, cell_size, data.heatmap[i].cell_color, true, corner);
   }
   
   // Legend
   curr_y = grid_y + (7 * (cell_size + cell_spacing)) + 20;
   
   string legend = StringFormat("Best Day: +%.2f%% | Worst Day: %.2f%%",
                               data.best_day_pct, data.worst_day_pct);
   CreateLbl(OBJ_PREFIX + "heat_legend", x + 40, curr_y,
            legend, text_color, label_size, "Arial", corner);
   
   return y + panel_height;
}

//+------------------------------------------------------------------+
//| Render Win/Loss Distribution                                      |
//+------------------------------------------------------------------+
int RenderWinLossDistribution(VisualAnalyticsData &data, int x, int y, int width,
                               ENUM_BASE_CORNER corner, color header_color,
                               color good_color, color danger_color,
                               color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "VISUAL_";
   int panel_height = 280;
   
   CreateRect(OBJ_PREFIX + "dist_panel", x + 20, y, width - 40, panel_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "dist_title", x + 40, curr_y,
            "WIN/LOSS DISTRIBUTION", header_color, label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Stats summary
   string stats = StringFormat("Wins: %d (Avg: $%.2f) | Losses: %d (Avg: $%.2f)",
                              data.total_wins, data.avg_win,
                              data.total_losses, data.avg_loss);
   CreateLbl(OBJ_PREFIX + "dist_stats", x + 40, curr_y,
            stats, text_color, label_size, "Arial", corner);
   curr_y += label_size + 20;
   
   // Histogram bars
   int bar_width = 50;
   int bar_spacing = 8;
   int max_bar_height = 100;
   
   // Find max percentage for scaling
   double max_pct = 0;
   for(int i = 0; i < 10; i++) {
      if(data.win_distribution[i].percentage > max_pct) 
         max_pct = data.win_distribution[i].percentage;
      if(data.loss_distribution[i].percentage > max_pct)
         max_pct = data.loss_distribution[i].percentage;
   }
   
   if(max_pct < 1) max_pct = 1;
   
   // Draw win bars (top 5 buckets)
   int bar_x = x + 60;
   int bar_y = curr_y + 10;
   
   for(int i = 0; i < 5; i++) {
      double pct = data.win_distribution[i].percentage;
      int bar_h = (int)((pct / max_pct) * max_bar_height);
      
      if(bar_h > 0) {
         CreateRect(OBJ_PREFIX + "dist_win_" + IntegerToString(i),
                   bar_x, bar_y + max_bar_height - bar_h,
                   bar_width, bar_h, good_color, true, corner);
      }
      
      bar_x += bar_width + bar_spacing;
   }
   
   // Draw loss bars (top 5 buckets)
   bar_x = x + 60 + (6 * (bar_width + bar_spacing));
   
   for(int i = 0; i < 5; i++) {
      double pct = data.loss_distribution[i].percentage;
      int bar_h = (int)((pct / max_pct) * max_bar_height);
      
      if(bar_h > 0) {
         CreateRect(OBJ_PREFIX + "dist_loss_" + IntegerToString(i),
                   bar_x, bar_y + max_bar_height - bar_h,
                   bar_width, bar_h, danger_color, true, corner);
      }
      
      bar_x += bar_width + bar_spacing;
   }
   
   return y + panel_height;
}

//+------------------------------------------------------------------+
//| Render Monthly Performance Grid                                   |
//+------------------------------------------------------------------+
int RenderMonthlyPerformance(VisualAnalyticsData &data, int x, int y, int width,
                             ENUM_BASE_CORNER corner, color header_color,
                             color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "VISUAL_";
   int panel_height = 220;
   
   CreateRect(OBJ_PREFIX + "month_panel", x + 20, y, width - 40, panel_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "month_title", x + 40, curr_y,
            "MONTHLY PERFORMANCE (Last 12 Months)", header_color, label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Summary
   string summary = StringFormat("YTD: %.2f%% | Best Month: +%.2f%% | Worst Month: %.2f%%",
                                data.ytd_return, data.best_month_pct, data.worst_month_pct);
   CreateLbl(OBJ_PREFIX + "month_summary", x + 40, curr_y,
            summary, text_color, label_size, "Arial", corner);
   curr_y += label_size + 20;
   
   // Month grid (3 rows x 4 cols)
   int cell_w = 150;
   int cell_h = 35;
   int cell_spacing = 10;
   
   string months[] = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
   
   for(int i = 0; i < MathMin(data.months_count, 12); i++) {
      int row = i / 4;
      int col = i % 4;
      
      int cell_x = x + 40 + (col * (cell_w + cell_spacing));
      int cell_y = curr_y + (row * (cell_h + cell_spacing));
      
      CreateRect(OBJ_PREFIX + "month_cell_" + IntegerToString(i), cell_x, cell_y,
                cell_w, cell_h, data.monthly[i].cell_color, true, corner);
      
      string month_text = StringFormat("%s %d: %.2f%%",
                                      months[data.monthly[i].month],
                                      data.monthly[i].year,
                                      data.monthly[i].return_pct);
      
      CreateLbl(OBJ_PREFIX + "month_text_" + IntegerToString(i), cell_x + 8, cell_y + 8,
               month_text, text_color, label_size - 1, "Arial Bold", corner);
   }
   
   return y + panel_height;
}

//+------------------------------------------------------------------+
//| Clear Visual Analytics Panel                                      |
//+------------------------------------------------------------------+
void ClearVisualAnalyticsPanel() {
   const string OBJ_PREFIX = "VISUAL_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_VISUAL_ANALYTICS_RENDER_MQH
