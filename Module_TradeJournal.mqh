//+------------------------------------------------------------------+
//|                              Module_TradeJournal.mqh             |
//|                        TRADE JOURNAL & ANALYSIS                  |
//|                  Detailed Trade Logging & Pattern Recognition    |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_TRADE_JOURNAL_MQH
#define MODULE_TRADE_JOURNAL_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Trade Entry Structure                                             |
//+------------------------------------------------------------------+
struct TradeEntry {
   ulong ticket;
   long magic;
   string algo_name;
   datetime open_time;
   datetime close_time;
   string symbol;
   int type;  // ORDER_TYPE_BUY or ORDER_TYPE_SELL
   double volume;
   double open_price;
   double close_price;
   double sl;
   double tp;
   double profit;
   double swap;
   double commission;
   double duration_hours;
   double mae;  // Maximum Adverse Excursion
   double mfe;  // Maximum Favorable Excursion
   string tags;
   string notes;
   int pattern_id;  // For pattern recognition
   color entry_color;
};

//+------------------------------------------------------------------+
//| Trade Statistics Structure                                        |
//+------------------------------------------------------------------+
struct TradeStats {
   int total_trades;
   int winning_trades;
   int losing_trades;
   double win_rate;
   double avg_win;
   double avg_loss;
   double avg_profit;
   double profit_factor;
   double largest_win;
   double largest_loss;
   double expectancy;
   double avg_duration_hours;
   double best_day;
   double worst_day;
};

//+------------------------------------------------------------------+
//| Pattern Recognition Structure                                     |
//+------------------------------------------------------------------+
struct TradePattern {
   int pattern_id;
   string pattern_name;
   string description;
   int occurrences;
   int wins;
   int losses;
   double win_rate;
   double avg_profit;
   double total_profit;
   bool is_profitable;
   string recommendation;
};

//+------------------------------------------------------------------+
//| Trade Journal Data                                                |
//+------------------------------------------------------------------+
struct TradeJournalData {
   TradeEntry recent_trades[100];
   int trade_count;
   
   TradeStats overall_stats;
   TradeStats long_stats;
   TradeStats short_stats;
   TradeStats today_stats;
   TradeStats week_stats;
   
   TradePattern patterns[20];
   int pattern_count;
   
   // Best/Worst Analysis
   TradeEntry best_trade;
   TradeEntry worst_trade;
   TradeEntry longest_trade;
   TradeEntry shortest_trade;
   
   // Time Analysis
   int trades_by_hour[24];
   double profit_by_hour[24];
   int best_trading_hour;
   int worst_trading_hour;
   
   // Symbol Analysis
   string top_symbols[10];
   double symbol_profits[10];
   int symbol_counts[10];
   int symbol_list_count;
};

//+------------------------------------------------------------------+
//| Collect Trade History                                             |
//+------------------------------------------------------------------+
void CollectTradeHistory(TradeJournalData &data, int days_back = 30) {
   datetime start = TimeCurrent() - (days_back * 86400);
   datetime now = TimeCurrent();
   
   if(!HistorySelect(start, now)) return;
   
   data.trade_count = 0;
   
   // Collect all closed trades
   int deals = HistoryDealsTotal();
   
   for(int i = deals - 1; i >= 0 && data.trade_count < 100; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         TradeEntry trade;
         
         trade.ticket = ticket;
         trade.magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         trade.close_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         trade.symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         trade.type = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
         trade.volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         trade.close_price = HistoryDealGetDouble(ticket, DEAL_PRICE);
         trade.profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         trade.swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
         trade.commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         
         // Get algo name
         trade.algo_name = GetAlgoName(trade.magic);
         
         // Find opening deal
         ulong position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         for(int j = 0; j < deals; j++) {
            ulong open_ticket = HistoryDealGetTicket(j);
            if(HistoryDealGetInteger(open_ticket, DEAL_POSITION_ID) == position_id &&
               HistoryDealGetInteger(open_ticket, DEAL_ENTRY) == DEAL_ENTRY_IN) {
               trade.open_time = (datetime)HistoryDealGetInteger(open_ticket, DEAL_TIME);
               trade.open_price = HistoryDealGetDouble(open_ticket, DEAL_PRICE);
               break;
            }
         }
         
         // Calculate duration
         if(trade.open_time > 0) {
            trade.duration_hours = (double)(trade.close_time - trade.open_time) / 3600.0;
         }
         
         // Color coding
         if(trade.profit > 0) {
            trade.entry_color = C'34,197,94';  // Green
         } else if(trade.profit < 0) {
            trade.entry_color = C'239,68,68';  // Red
         } else {
            trade.entry_color = C'156,163,175';  // Gray
         }
         
         trade.tags = "";
         trade.notes = "";
         trade.pattern_id = -1;
         
         data.recent_trades[data.trade_count] = trade;
         data.trade_count++;
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Trade Statistics                                        |
//+------------------------------------------------------------------+
void CalculateTradeStats(TradeStats &stats, TradeEntry &trades[], int count, int type_filter = -1) {
   ZeroMemory(stats);
   
   double total_profit = 0;
   double total_loss = 0;
   double total_duration = 0;
   int trades_counted = 0;
   
   for(int i = 0; i < count; i++) {
      // Apply type filter
      if(type_filter >= 0 && trades[i].type != type_filter) continue;
      
      trades_counted++;
      total_duration += trades[i].duration_hours;
      
      if(trades[i].profit > 0) {
         stats.winning_trades++;
         total_profit += trades[i].profit;
         if(trades[i].profit > stats.largest_win) {
            stats.largest_win = trades[i].profit;
         }
      } else if(trades[i].profit < 0) {
         stats.losing_trades++;
         total_loss += MathAbs(trades[i].profit);
         if(trades[i].profit < stats.largest_loss) {
            stats.largest_loss = trades[i].profit;
         }
      }
   }
   
   stats.total_trades = trades_counted;
   stats.win_rate = (stats.total_trades > 0) ? 
                    ((double)stats.winning_trades / stats.total_trades) * 100.0 : 0;
   stats.avg_win = (stats.winning_trades > 0) ? total_profit / stats.winning_trades : 0;
   stats.avg_loss = (stats.losing_trades > 0) ? total_loss / stats.losing_trades : 0;
   stats.avg_profit = (stats.total_trades > 0) ? 
                      (total_profit - total_loss) / stats.total_trades : 0;
   stats.profit_factor = (total_loss > 0) ? total_profit / total_loss : 0;
   stats.expectancy = (stats.win_rate / 100.0) * stats.avg_win - 
                     ((100.0 - stats.win_rate) / 100.0) * stats.avg_loss;
   stats.avg_duration_hours = (stats.total_trades > 0) ? 
                              total_duration / stats.total_trades : 0;
}

//+------------------------------------------------------------------+
//| Analyze Trading Patterns                                          |
//+------------------------------------------------------------------+
void AnalyzeTradingPatterns(TradeJournalData &data) {
   data.pattern_count = 0;
   
   // Pattern 1: Quick wins (< 1 hour, profitable)
   TradePattern quick_wins;
   quick_wins.pattern_id = 1;
   quick_wins.pattern_name = "Quick Win";
   quick_wins.description = "Trades closed in <1hr with profit";
   quick_wins.occurrences = 0;
   quick_wins.wins = 0;
   quick_wins.total_profit = 0;
   
   for(int i = 0; i < data.trade_count; i++) {
      if(data.recent_trades[i].duration_hours < 1.0 && data.recent_trades[i].profit > 0) {
         quick_wins.occurrences++;
         quick_wins.wins++;
         quick_wins.total_profit += data.recent_trades[i].profit;
         data.recent_trades[i].pattern_id = 1;
      }
   }
   quick_wins.win_rate = 100.0;
   quick_wins.avg_profit = (quick_wins.occurrences > 0) ? 
                           quick_wins.total_profit / quick_wins.occurrences : 0;
   quick_wins.is_profitable = (quick_wins.avg_profit > 0);
   quick_wins.recommendation = quick_wins.is_profitable ? 
                               "Excellent - Continue this pattern" : "Review strategy";
   if(quick_wins.occurrences > 0) {
      data.patterns[data.pattern_count++] = quick_wins;
   }
   
   // Pattern 2: Long holds (> 24 hours)
   TradePattern long_holds;
   long_holds.pattern_id = 2;
   long_holds.pattern_name = "Long Hold";
   long_holds.description = "Trades held >24hrs";
   long_holds.occurrences = 0;
   long_holds.wins = 0;
   long_holds.losses = 0;
   long_holds.total_profit = 0;
   
   for(int i = 0; i < data.trade_count; i++) {
      if(data.recent_trades[i].duration_hours > 24.0) {
         long_holds.occurrences++;
         if(data.recent_trades[i].profit > 0) {
            long_holds.wins++;
         } else {
            long_holds.losses++;
         }
         long_holds.total_profit += data.recent_trades[i].profit;
         if(data.recent_trades[i].pattern_id < 0) {
            data.recent_trades[i].pattern_id = 2;
         }
      }
   }
   long_holds.win_rate = (long_holds.occurrences > 0) ?
                         ((double)long_holds.wins / long_holds.occurrences) * 100.0 : 0;
   long_holds.avg_profit = (long_holds.occurrences > 0) ?
                           long_holds.total_profit / long_holds.occurrences : 0;
   long_holds.is_profitable = (long_holds.avg_profit > 0);
   long_holds.recommendation = long_holds.is_profitable ?
                               "Good patience paying off" : "Consider shorter timeframes";
   if(long_holds.occurrences > 0) {
      data.patterns[data.pattern_count++] = long_holds;
   }
   
   // Pattern 3: Weekend trades
   TradePattern weekend_trades;
   weekend_trades.pattern_id = 3;
   weekend_trades.pattern_name = "Weekend Trade";
   weekend_trades.description = "Trades opened on weekend";
   weekend_trades.occurrences = 0;
   weekend_trades.wins = 0;
   weekend_trades.losses = 0;
   weekend_trades.total_profit = 0;
   
   for(int i = 0; i < data.trade_count; i++) {
      MqlDateTime dt;
      TimeToStruct(data.recent_trades[i].open_time, dt);
      if(dt.day_of_week == 0 || dt.day_of_week == 6) {  // Sunday or Saturday
         weekend_trades.occurrences++;
         if(data.recent_trades[i].profit > 0) {
            weekend_trades.wins++;
         } else {
            weekend_trades.losses++;
         }
         weekend_trades.total_profit += data.recent_trades[i].profit;
         if(data.recent_trades[i].pattern_id < 0) {
            data.recent_trades[i].pattern_id = 3;
         }
      }
   }
   weekend_trades.win_rate = (weekend_trades.occurrences > 0) ?
                             ((double)weekend_trades.wins / weekend_trades.occurrences) * 100.0 : 0;
   weekend_trades.avg_profit = (weekend_trades.occurrences > 0) ?
                               weekend_trades.total_profit / weekend_trades.occurrences : 0;
   weekend_trades.is_profitable = (weekend_trades.avg_profit > 0);
   weekend_trades.recommendation = weekend_trades.is_profitable ?
                                   "Weekend strategy working" : "Avoid weekend entries";
   if(weekend_trades.occurrences > 0) {
      data.patterns[data.pattern_count++] = weekend_trades;
   }
   
   // Pattern 4: Large positions (> 1.0 lot)
   TradePattern large_positions;
   large_positions.pattern_id = 4;
   large_positions.pattern_name = "Large Size";
   large_positions.description = "Positions >1.0 lot";
   large_positions.occurrences = 0;
   large_positions.wins = 0;
   large_positions.losses = 0;
   large_positions.total_profit = 0;
   
   for(int i = 0; i < data.trade_count; i++) {
      if(data.recent_trades[i].volume > 1.0) {
         large_positions.occurrences++;
         if(data.recent_trades[i].profit > 0) {
            large_positions.wins++;
         } else {
            large_positions.losses++;
         }
         large_positions.total_profit += data.recent_trades[i].profit;
         if(data.recent_trades[i].pattern_id < 0) {
            data.recent_trades[i].pattern_id = 4;
         }
      }
   }
   large_positions.win_rate = (large_positions.occurrences > 0) ?
                              ((double)large_positions.wins / large_positions.occurrences) * 100.0 : 0;
   large_positions.avg_profit = (large_positions.occurrences > 0) ?
                                large_positions.total_profit / large_positions.occurrences : 0;
   large_positions.is_profitable = (large_positions.avg_profit > 0);
   large_positions.recommendation = large_positions.is_profitable ?
                                    "Size management good" : "Reduce position sizes";
   if(large_positions.occurrences > 0) {
      data.patterns[data.pattern_count++] = large_positions;
   }
}

//+------------------------------------------------------------------+
//| Analyze Trading Hours                                             |
//+------------------------------------------------------------------+
void AnalyzeTradingHours(TradeJournalData &data) {
   // Reset arrays
   for(int h = 0; h < 24; h++) {
      data.trades_by_hour[h] = 0;
      data.profit_by_hour[h] = 0;
   }
   
   // Count trades and profit by hour
   for(int i = 0; i < data.trade_count; i++) {
      MqlDateTime dt;
      TimeToStruct(data.recent_trades[i].open_time, dt);
      int hour = dt.hour;
      
      data.trades_by_hour[hour]++;
      data.profit_by_hour[hour] += data.recent_trades[i].profit;
   }
   
   // Find best and worst hours
   double best_profit = -999999;
   double worst_profit = 999999;
   
   for(int h = 0; h < 24; h++) {
      if(data.trades_by_hour[h] > 0) {
         if(data.profit_by_hour[h] > best_profit) {
            best_profit = data.profit_by_hour[h];
            data.best_trading_hour = h;
         }
         if(data.profit_by_hour[h] < worst_profit) {
            worst_profit = data.profit_by_hour[h];
            data.worst_trading_hour = h;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Find Best and Worst Trades                                        |
//+------------------------------------------------------------------+
void FindBestWorstTrades(TradeJournalData &data) {
   if(data.trade_count == 0) return;
   
   data.best_trade = data.recent_trades[0];
   data.worst_trade = data.recent_trades[0];
   data.longest_trade = data.recent_trades[0];
   data.shortest_trade = data.recent_trades[0];
   
   for(int i = 1; i < data.trade_count; i++) {
      if(data.recent_trades[i].profit > data.best_trade.profit) {
         data.best_trade = data.recent_trades[i];
      }
      if(data.recent_trades[i].profit < data.worst_trade.profit) {
         data.worst_trade = data.recent_trades[i];
      }
      if(data.recent_trades[i].duration_hours > data.longest_trade.duration_hours) {
         data.longest_trade = data.recent_trades[i];
      }
      if(data.recent_trades[i].duration_hours < data.shortest_trade.duration_hours) {
         data.shortest_trade = data.recent_trades[i];
      }
   }
}

//+------------------------------------------------------------------+
//| Get Algo Name from Magic Number                                   |
//+------------------------------------------------------------------+
string GetAlgoName(long magic) {
   if(magic == 0) return "Manual";
   return "ALGO-" + IntegerToString(magic);
}

//+------------------------------------------------------------------+
//| Main Trade Journal Generation                                     |
//+------------------------------------------------------------------+
void GenerateTradeJournal(TradeJournalData &data, int days_back = 30) {
   ZeroMemory(data);
   
   CollectTradeHistory(data, days_back);
   
   if(data.trade_count > 0) {
      CalculateTradeStats(data.overall_stats, data.recent_trades, data.trade_count);
      CalculateTradeStats(data.long_stats, data.recent_trades, data.trade_count, ORDER_TYPE_BUY);
      CalculateTradeStats(data.short_stats, data.recent_trades, data.trade_count, ORDER_TYPE_SELL);
      
      AnalyzeTradingPatterns(data);
      AnalyzeTradingHours(data);
      FindBestWorstTrades(data);
   }
}

//+------------------------------------------------------------------+

#endif // MODULE_TRADE_JOURNAL_MQH
