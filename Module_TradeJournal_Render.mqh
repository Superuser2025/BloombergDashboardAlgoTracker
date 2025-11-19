//+------------------------------------------------------------------+
//|                      Module_TradeJournal_Render.mqh              |
//|                   TRADE JOURNAL RENDERING                        |
//|                  Trade Journal Display Functions                 |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
////#property strict

#ifndef MODULE_TRADE_JOURNAL_RENDER_MQH
#define MODULE_TRADE_JOURNAL_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_TradeJournal.mqh"
#include "Core_UIHelpers.mqh"

//+------------------------------------------------------------------+
//| Render Trade Journal Panel                                        |
//+------------------------------------------------------------------+
void RenderTradeJournalPanel(TradeJournalData &data,
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
   
   const string OBJ_PREFIX = "JOURNAL_";
   int panel_x = 20;
   int y = start_y;
   
   int total_height = 1400;
   
   // Main background
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, total_height, bg_color, true, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "TRADE JOURNAL & ANALYSIS", header_color, header_size, "Arial Black", corner);
   
   string subtitle = StringFormat("Performance Analysis | %d Trades | Last 30 Days", data.trade_count);
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            subtitle, info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Overall Statistics
   y = RenderOverallStats(data, panel_x, y, panel_width, corner, header_color,
                         good_color, warning_color, danger_color, info_color, panel_color, text_color, label_size, metric_size);
   
   y += 20;
   
   // Pattern Recognition
   y = RenderPatterns(data, panel_x, y, panel_width, corner, header_color,
                     good_color, danger_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Best/Worst Trades
   y = RenderBestWorst(data, panel_x, y, panel_width, corner, header_color,
                      good_color, danger_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Recent Trades List
   RenderRecentTrades(data, panel_x, y, panel_width, corner, header_color,
                     panel_color, text_color, label_size);
}

//+------------------------------------------------------------------+
//| Render Overall Statistics                                         |
//+------------------------------------------------------------------+
int RenderOverallStats(TradeJournalData &data, int x, int y, int width,
                       ENUM_BASE_CORNER corner, color header_color,
                       color good_color, color warning_color, color danger_color, color info_color,
                       color panel_color, color text_color, int label_size, int metric_size) {
   
   const string OBJ_PREFIX = "JOURNAL_";
   
   CreateRect(OBJ_PREFIX + "stats_bg", x + 20, y, width - 40, 220,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "stats_title", x + 40, curr_y,
            "PERFORMANCE SUMMARY", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Row 1: Basic stats
   int col1 = x + 60;
   int col2 = x + 260;
   int col3 = x + 460;
   int col4 = x + 660;
   int col5 = x + 860;
   
   CreateLbl(OBJ_PREFIX + "total_lbl", col1, curr_y,
            "Total Trades:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "total_val", col1, curr_y + label_size + 5,
            IntegerToString(data.overall_stats.total_trades), info_color, metric_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "wins_lbl", col2, curr_y,
            "Wins:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "wins_val", col2, curr_y + label_size + 5,
            IntegerToString(data.overall_stats.winning_trades), good_color, metric_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "losses_lbl", col3, curr_y,
            "Losses:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "losses_val", col3, curr_y + label_size + 5,
            IntegerToString(data.overall_stats.losing_trades), danger_color, metric_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "wr_lbl", col4, curr_y,
            "Win Rate:", text_color, label_size, "Arial", corner);
   color wr_color = (data.overall_stats.win_rate >= 50) ? good_color : warning_color;
   CreateLbl(OBJ_PREFIX + "wr_val", col4, curr_y + label_size + 5,
            StringFormat("%.1f%%", data.overall_stats.win_rate), wr_color, metric_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "pf_lbl", col5, curr_y,
            "Profit Factor:", text_color, label_size, "Arial", corner);
   color pf_color = (data.overall_stats.profit_factor >= 1.5) ? good_color : 
                    (data.overall_stats.profit_factor >= 1.0) ? warning_color : danger_color;
   CreateLbl(OBJ_PREFIX + "pf_val", col5, curr_y + label_size + 5,
            StringFormat("%.2f", data.overall_stats.profit_factor), pf_color, metric_size, "Arial Black", corner);
   
   curr_y += metric_size + 30;
   
   // Row 2: Avg win/loss and expectancy
   CreateLbl(OBJ_PREFIX + "avgwin_lbl", col1, curr_y,
            "Avg Win:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "avgwin_val", col1, curr_y + label_size + 5,
            StringFormat("$%.2f", data.overall_stats.avg_win), good_color, label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "avgloss_lbl", col2, curr_y,
            "Avg Loss:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "avgloss_val", col2, curr_y + label_size + 5,
            StringFormat("$%.2f", data.overall_stats.avg_loss), danger_color, label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "expect_lbl", col3, curr_y,
            "Expectancy:", text_color, label_size, "Arial", corner);
   color exp_color = (data.overall_stats.expectancy > 0) ? good_color : danger_color;
   CreateLbl(OBJ_PREFIX + "expect_val", col3, curr_y + label_size + 5,
            StringFormat("$%.2f", data.overall_stats.expectancy), exp_color, label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "duration_lbl", col4, curr_y,
            "Avg Duration:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "duration_val", col4, curr_y + label_size + 5,
            StringFormat("%.1fh", data.overall_stats.avg_duration_hours), text_color, label_size + 2, "Arial Bold", corner);
   
   curr_y += label_size + 35;
   
   // Row 3: Long vs Short comparison
   CreateRect(OBJ_PREFIX + "long_bg", x + 60, curr_y, 450, 60, C'25,30,40', true, corner);
   CreateLbl(OBJ_PREFIX + "long_title", x + 80, curr_y + 10,
            "LONG TRADES", good_color, label_size + 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "long_stats", x + 80, curr_y + 32,
            StringFormat("%d trades | %.1f%% WR | PF: %.2f",
                        data.long_stats.total_trades,
                        data.long_stats.win_rate,
                        data.long_stats.profit_factor),
            text_color, label_size, "Arial", corner);
   
   CreateRect(OBJ_PREFIX + "short_bg", x + 530, curr_y, 450, 60, C'25,30,40', true, corner);
   CreateLbl(OBJ_PREFIX + "short_title", x + 550, curr_y + 10,
            "SHORT TRADES", danger_color, label_size + 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "short_stats", x + 550, curr_y + 32,
            StringFormat("%d trades | %.1f%% WR | PF: %.2f",
                        data.short_stats.total_trades,
                        data.short_stats.win_rate,
                        data.short_stats.profit_factor),
            text_color, label_size, "Arial", corner);
   
   return y + 220;
}

//+------------------------------------------------------------------+
//| Render Pattern Recognition                                        |
//+------------------------------------------------------------------+
int RenderPatterns(TradeJournalData &data, int x, int y, int width,
                   ENUM_BASE_CORNER corner, color header_color,
                   color good_color, color danger_color,
                   color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "JOURNAL_";
   
   CreateRect(OBJ_PREFIX + "patterns_bg", x + 20, y, width - 40, 200,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "patterns_title", x + 40, curr_y,
            "PATTERN RECOGNITION", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   if(data.pattern_count == 0) {
      CreateLbl(OBJ_PREFIX + "no_patterns", x + 40, curr_y,
               "Not enough data for pattern analysis", text_color, label_size, "Arial", corner);
      return y + 200;
   }
   
   // Display top 4 patterns
   int displayed = MathMin(data.pattern_count, 4);
   int pattern_width = (width - 100) / 2;
   
   for(int i = 0; i < displayed; i++) {
      int row = i / 2;
      int col = i % 2;
      
      int pattern_x = x + 40 + (col * (pattern_width + 20));
      int pattern_y = curr_y + (row * 75);
      
      color bg_color = data.patterns[i].is_profitable ? C'34,197,94,40' : C'239,68,68,40';
      CreateRect(OBJ_PREFIX + "pattern_" + IntegerToString(i), pattern_x, pattern_y,
                pattern_width, 65, bg_color, true, corner);
      
      CreateLbl(OBJ_PREFIX + "pattern_name_" + IntegerToString(i), pattern_x + 15, pattern_y + 8,
               data.patterns[i].pattern_name, header_color, label_size + 1, "Arial Bold", corner);
      
      CreateLbl(OBJ_PREFIX + "pattern_desc_" + IntegerToString(i), pattern_x + 15, pattern_y + 28,
               data.patterns[i].description, text_color, label_size - 1, "Arial", corner);
      
      string stats = StringFormat("%d trades | %.1f%% WR | $%.2f avg",
                                  data.patterns[i].occurrences,
                                  data.patterns[i].win_rate,
                                  data.patterns[i].avg_profit);
      CreateLbl(OBJ_PREFIX + "pattern_stats_" + IntegerToString(i), pattern_x + 15, pattern_y + 45,
               stats, text_color, label_size - 1, "Arial", corner);
   }
   
   return y + 200;
}

//+------------------------------------------------------------------+
//| Render Best/Worst Trades                                          |
//+------------------------------------------------------------------+
int RenderBestWorst(TradeJournalData &data, int x, int y, int width,
                    ENUM_BASE_CORNER corner, color header_color,
                    color good_color, color danger_color,
                    color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "JOURNAL_";
   
   CreateRect(OBJ_PREFIX + "bw_bg", x + 20, y, width - 40, 180,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "bw_title", x + 40, curr_y,
            "BEST & WORST TRADES", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   if(data.trade_count == 0) {
      CreateLbl(OBJ_PREFIX + "no_trades", x + 40, curr_y,
               "No trades to analyze", text_color, label_size, "Arial", corner);
      return y + 180;
   }
   
   // Best Trade
   int col1 = x + 60;
   CreateRect(OBJ_PREFIX + "best_card", col1, curr_y, 460, 100, C'34,197,94,30', true, corner);
   
   CreateLbl(OBJ_PREFIX + "best_label", col1 + 15, curr_y + 10,
            "🏆 BEST TRADE", good_color, label_size + 2, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "best_profit", col1 + 15, curr_y + 35,
            StringFormat("$%.2f", data.best_trade.profit), good_color, label_size + 6, "Arial Black", corner);
   
   string best_details = StringFormat("%s | %s | %.2f lots | %.1fh",
                                      data.best_trade.algo_name,
                                      data.best_trade.symbol,
                                      data.best_trade.volume,
                                      data.best_trade.duration_hours);
   CreateLbl(OBJ_PREFIX + "best_details", col1 + 15, curr_y + 75,
            best_details, text_color, label_size - 1, "Arial", corner);
   
   // Worst Trade
   int col2 = x + 540;
   CreateRect(OBJ_PREFIX + "worst_card", col2, curr_y, 460, 100, C'239,68,68,30', true, corner);
   
   CreateLbl(OBJ_PREFIX + "worst_label", col2 + 15, curr_y + 10,
            "💥 WORST TRADE", danger_color, label_size + 2, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "worst_profit", col2 + 15, curr_y + 35,
            StringFormat("$%.2f", data.worst_trade.profit), danger_color, label_size + 6, "Arial Black", corner);
   
   string worst_details = StringFormat("%s | %s | %.2f lots | %.1fh",
                                       data.worst_trade.algo_name,
                                       data.worst_trade.symbol,
                                       data.worst_trade.volume,
                                       data.worst_trade.duration_hours);
   CreateLbl(OBJ_PREFIX + "worst_details", col2 + 15, curr_y + 75,
            worst_details, text_color, label_size - 1, "Arial", corner);
   
   return y + 180;
}

//+------------------------------------------------------------------+
//| Render Recent Trades List                                         |
//+------------------------------------------------------------------+
int RenderRecentTrades(TradeJournalData &data, int x, int y, int width,
                       ENUM_BASE_CORNER corner, color header_color,
                       color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "JOURNAL_";
   
   int list_height = 500;
   
   CreateRect(OBJ_PREFIX + "list_bg", x + 20, y, width - 40, list_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "list_title", x + 40, curr_y,
            "RECENT TRADES", header_color, label_size + 3, "Arial Black", corner);
   
   // Export button
   CreateBtn(OBJ_PREFIX + "export_btn", x + width - 200, curr_y - 5, 140, 35,
            "EXPORT CSV", text_color, C'55,65,81', corner);
   
   curr_y += label_size + 25;
   
   // Table header
   CreateRect(OBJ_PREFIX + "header_row", x + 40, curr_y, width - 100, 30, C'25,30,40', true, corner);
   
   CreateLbl(OBJ_PREFIX + "hdr_time", x + 55, curr_y + 7,
            "Time", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_algo", x + 155, curr_y + 7,
            "Algo", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_symbol", x + 305, curr_y + 7,
            "Symbol", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_type", x + 405, curr_y + 7,
            "Type", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_lots", x + 485, curr_y + 7,
            "Lots", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_profit", x + 575, curr_y + 7,
            "Profit", text_color, label_size - 1, "Arial Bold", corner);
   CreateLbl(OBJ_PREFIX + "hdr_duration", x + 685, curr_y + 7,
            "Duration", text_color, label_size - 1, "Arial Bold", corner);
   
   curr_y += 35;
   
   // Display trades (up to 10)
   int displayed = MathMin(data.trade_count, 10);
   
   for(int i = 0; i < displayed; i++) {
      TradeEntry trade = data.recent_trades[i];
      
      // Alternate row color
      if(i % 2 == 0) {
         CreateRect(OBJ_PREFIX + "row_" + IntegerToString(i), x + 40, curr_y, 
                   width - 100, 30, C'31,41,55', true, corner);
      }
      
      CreateLbl(OBJ_PREFIX + "time_" + IntegerToString(i), x + 55, curr_y + 7,
               TimeToString(trade.close_time, TIME_DATE | TIME_MINUTES),
               text_color, label_size - 2, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "algo_" + IntegerToString(i), x + 155, curr_y + 7,
               trade.algo_name, text_color, label_size - 2, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "symbol_" + IntegerToString(i), x + 305, curr_y + 7,
               trade.symbol, text_color, label_size - 2, "Arial", corner);
      
      string type_str = (trade.type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
      CreateLbl(OBJ_PREFIX + "type_" + IntegerToString(i), x + 405, curr_y + 7,
               type_str, text_color, label_size - 2, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "lots_" + IntegerToString(i), x + 485, curr_y + 7,
               StringFormat("%.2f", trade.volume), text_color, label_size - 2, "Arial", corner);
      
      CreateLbl(OBJ_PREFIX + "profit_" + IntegerToString(i), x + 575, curr_y + 7,
               StringFormat("$%.2f", trade.profit), trade.entry_color, 
               label_size - 1, "Arial Bold", corner);
      
      CreateLbl(OBJ_PREFIX + "duration_" + IntegerToString(i), x + 685, curr_y + 7,
               StringFormat("%.1fh", trade.duration_hours), text_color, label_size - 2, "Arial", corner);
      
      curr_y += 32;
   }
   
   if(data.trade_count > 10) {
      CreateLbl(OBJ_PREFIX + "more_trades", x + 40, curr_y,
               StringFormat("+ %d more trades...", data.trade_count - 10),
               text_color, label_size - 1, "Arial Italic", corner);
   }
   
   return y + list_height;
}

//+------------------------------------------------------------------+
//| Clear Trade Journal Panel                                         |
//+------------------------------------------------------------------+
void ClearTradeJournalPanel() {
   const string OBJ_PREFIX = "JOURNAL_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_TRADE_JOURNAL_RENDER_MQH
