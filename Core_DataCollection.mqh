//+------------------------------------------------------------------+
//|                                      Core_DataCollection.mqh     |
//|                                     Portfolio Command Center     |
//|                           Data Collection & Analysis Functions   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "5.00"
#property strict

#ifndef CORE_DATA_COLLECTION_MQH
#define CORE_DATA_COLLECTION_MQH

#include "Core_DataStructures.mqh"

// This module requires these globals from main file:
// - algos[], algo_count
// - portfolio
// - market
// - Input parameters: AnalysisPeriodDays, IncludeManualTrades, MinTradesForAnalysis
// - Color constants

//+------------------------------------------------------------------+
//| Collect All Algos                                                 |
//+------------------------------------------------------------------+
void CollectAlgos(AlgoMetrics &algos[], int &algo_count, int AnalysisPeriodDays, 
                  bool IncludeManualTrades, int MinTradesForAnalysis,
                  double SymbolConcentrationLimit, color ColorSuccess, 
                  color ColorProfit, color ColorWarning, color ColorCritical) {
   ArrayResize(algos, 0);
   algo_count = 0;
   
   // Get unique magic numbers
   long magics[];
   ArrayResize(magics, 0);
   
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      bool is_manual = (magic == 0);
      
      if(!IncludeManualTrades && is_manual) continue;
      
      bool found = false;
      for(int j = 0; j < ArraySize(magics); j++) {
         if(magics[j] == magic) {
            found = true;
            break;
         }
      }
      
      if(!found) {
         ArrayResize(magics, ArraySize(magics) + 1);
         magics[ArraySize(magics) - 1] = magic;
      }
   }
   
   algo_count = ArraySize(magics);
   ArrayResize(algos, algo_count);
   
   // Analyze each algo
   for(int m = 0; m < algo_count; m++) {
      AnalyzeAlgo(magics[m], algos[m], AnalysisPeriodDays, MinTradesForAnalysis,
                  SymbolConcentrationLimit, ColorSuccess, ColorProfit, ColorWarning, ColorCritical);
   }
   
   // Sort by performance score
   SortAlgosByScore(algos, algo_count);
}

//+------------------------------------------------------------------+
//| Analyze Single Algo                                               |
//+------------------------------------------------------------------+
void AnalyzeAlgo(long magic, AlgoMetrics &algo, int AnalysisPeriodDays, 
                 int MinTradesForAnalysis, double SymbolConcentrationLimit,
                 color ColorSuccess, color ColorProfit, color ColorWarning, color ColorCritical) {
   // Initialize
   ZeroMemory(algo);
   algo.magic = magic;
   algo.is_manual = (magic == 0);
   algo.name = algo.is_manual ? "MANUAL" : "ALGO-" + IntegerToString(magic);
   
   // Collect positions
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
      
      algo.pos_count++;
      
      double lots = PositionGetDouble(POSITION_VOLUME);
      algo.total_lots += lots;
      
      double profit = PositionGetDouble(POSITION_PROFIT);
      double swap = PositionGetDouble(POSITION_SWAP);
      algo.floating_pl += profit + swap;
      
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type == POSITION_TYPE_BUY) {
         algo.buy_count++;
         algo.buy_lots += lots;
      } else {
         algo.sell_count++;
         algo.sell_lots += lots;
      }
      
      // Track symbols
      string symbol = PositionGetString(POSITION_SYMBOL);
      bool found = false;
      for(int s = 0; s < algo.symbol_count; s++) {
         if(algo.symbols[s] == symbol) {
            algo.symbol_lots[s] += lots;
            found = true;
            break;
         }
      }
      
      if(!found && algo.symbol_count < 20) {
         algo.symbols[algo.symbol_count] = symbol;
         algo.symbol_lots[algo.symbol_count] = lots;
         algo.symbol_count++;
      }
      
      // Track time
      datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
      if(algo.oldest_position == 0 || open_time < algo.oldest_position) {
         algo.oldest_position = open_time;
      }
      if(open_time > algo.newest_position) {
         algo.newest_position = open_time;
      }
   }
   
   // Calculate symbol percentages
   if(algo.total_lots > 0) {
      for(int s = 0; s < algo.symbol_count; s++) {
         algo.symbol_pct[s] = (algo.symbol_lots[s] / algo.total_lots) * 100.0;
         if(algo.symbol_pct[s] > algo.top_symbol_pct) {
            algo.top_symbol_pct = algo.symbol_pct[s];
            algo.top_symbol = algo.symbols[s];
         }
      }
   }
   
   algo.is_profitable = (algo.floating_pl > 0);
   algo.is_overexposed = (algo.top_symbol_pct > SymbolConcentrationLimit);
   
   // Analyze closed trades
   AnalyzeClosedTrades(magic, algo, AnalysisPeriodDays, MinTradesForAnalysis);
   
   // Calculate performance score
   CalculatePerformanceScore(algo, MinTradesForAnalysis, ColorSuccess, 
                             ColorProfit, ColorWarning, ColorCritical);
   
   // Identify issues
   IdentifyAlgoIssues(algo, MinTradesForAnalysis);
}

//+------------------------------------------------------------------+
//| Analyze Closed Trades                                             |
//+------------------------------------------------------------------+
void AnalyzeClosedTrades(long magic, AlgoMetrics &algo, int AnalysisPeriodDays,
                        int MinTradesForAnalysis) {
   datetime cutoff = TimeCurrent() - (AnalysisPeriodDays * 86400);
   HistorySelect(cutoff, TimeCurrent());
   
   double total_win = 0, total_loss = 0;
   double gross_profit = 0, gross_loss = 0;
   
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
      profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      
      algo.trades_closed++;
      algo.realized_pl += profit;
      
      if(profit > 0) {
         algo.wins++;
         total_win += profit;
         gross_profit += profit;
         if(profit > algo.largest_win) algo.largest_win = profit;
      } else if(profit < 0) {
         algo.losses++;
         total_loss += profit;
         gross_loss += MathAbs(profit);
         if(profit < algo.largest_loss) algo.largest_loss = profit;
      }
   }
   
   algo.total_pl = algo.floating_pl + algo.realized_pl;
   
   if(algo.trades_closed > 0) {
      algo.win_rate = ((double)algo.wins / algo.trades_closed) * 100.0;
      if(algo.wins > 0) algo.avg_win = total_win / algo.wins;
      if(algo.losses > 0) algo.avg_loss = total_loss / algo.losses;
      
      if(gross_loss > 0) {
         algo.profit_factor = gross_profit / gross_loss;
      } else {
         algo.profit_factor = (gross_profit > 0) ? 999 : 0;
      }
      
      algo.expectancy = (total_win + total_loss) / algo.trades_closed;
   }
   
   // Calculate average duration
   if(algo.pos_count > 0 && algo.oldest_position > 0) {
      algo.avg_duration_hours = (TimeCurrent() - algo.oldest_position) / 3600.0 / algo.pos_count;
   }
}

//+------------------------------------------------------------------+
//| Calculate Performance Score                                       |
//+------------------------------------------------------------------+
void CalculatePerformanceScore(AlgoMetrics &algo, int MinTradesForAnalysis,
                               color ColorSuccess, color ColorProfit, 
                               color ColorWarning, color ColorCritical) {
   double score = 0;
   
   // Profitability (30 points)
   if(algo.total_pl > 0) {
      score += 30;
   } else if(algo.total_pl > -100) {
      score += 15;
   }
   
   // Win Rate (20 points)
   if(algo.trades_closed >= MinTradesForAnalysis) {
      if(algo.win_rate >= 70) score += 20;
      else if(algo.win_rate >= 60) score += 15;
      else if(algo.win_rate >= 50) score += 10;
      else if(algo.win_rate >= 40) score += 5;
   } else {
      score += 10;  // Not enough data
   }
   
   // Profit Factor (20 points)
   if(algo.trades_closed >= MinTradesForAnalysis) {
      if(algo.profit_factor >= 2.0) score += 20;
      else if(algo.profit_factor >= 1.5) score += 15;
      else if(algo.profit_factor >= 1.2) score += 10;
      else if(algo.profit_factor >= 1.0) score += 5;
   } else {
      score += 10;
   }
   
   // Expectancy (15 points)
   if(algo.trades_closed >= MinTradesForAnalysis) {
      if(algo.expectancy > 50) score += 15;
      else if(algo.expectancy > 0) score += 10;
      else if(algo.expectancy > -50) score += 5;
   } else {
      score += 7;
   }
   
   // Risk Management (15 points)
   if(!algo.is_overexposed) score += 10;
   if(!algo.has_warnings) score += 5;
   
   algo.performance_score = MathMax(0, MathMin(100, score));
   
   // Determine status
   if(algo.performance_score >= 75) {
      algo.status = "EXCELLENT";
      algo.status_color = ColorSuccess;
   } else if(algo.performance_score >= 55) {
      algo.status = "GOOD";
      algo.status_color = ColorProfit;
   } else if(algo.performance_score >= 40) {
      algo.status = "CAUTION";
      algo.status_color = ColorWarning;
      algo.has_warnings = true;
   } else {
      algo.status = "CRITICAL";
      algo.status_color = ColorCritical;
      algo.has_critical_issues = true;
   }
}

//+------------------------------------------------------------------+
//| Identify Algo Issues                                              |
//+------------------------------------------------------------------+
void IdentifyAlgoIssues(AlgoMetrics &algo, int MinTradesForAnalysis) {
   string issues = "";
   
   if(algo.floating_pl < -500) {
      issues += "Large Loss; ";
   }
   
   if(algo.is_overexposed) {
      issues += "Overexposed " + algo.top_symbol + "; ";
   }
   
   if(algo.trades_closed >= MinTradesForAnalysis && algo.profit_factor < 1.0) {
      issues += "Losing Strategy; ";
   }
   
   if(algo.trades_closed >= MinTradesForAnalysis && algo.win_rate < 40) {
      issues += "Low Win Rate; ";
   }
   
   if(issues != "") {
      algo.primary_issue = issues;
      algo.has_warnings = true;
      if(algo.floating_pl < -1000 || algo.profit_factor < 0.5) {
         algo.has_critical_issues = true;
      }
   } else {
      algo.primary_issue = "No issues detected";
   }
}

//+------------------------------------------------------------------+
//| Sort Algos by Score                                               |
//+------------------------------------------------------------------+
void SortAlgosByScore(AlgoMetrics &algos[], int algo_count) {
   for(int i = 0; i < algo_count - 1; i++) {
      for(int j = 0; j < algo_count - i - 1; j++) {
         if(algos[j].performance_score < algos[j + 1].performance_score) {
            AlgoMetrics temp = algos[j];
            algos[j] = algos[j + 1];
            algos[j + 1] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Analyze Portfolio                                                 |
//+------------------------------------------------------------------+
void AnalyzePortfolio(PortfolioMetrics &portfolio, AlgoMetrics &algos[], int algo_count) {
   ZeroMemory(portfolio);
   
   portfolio.total_algos = algo_count;
   portfolio.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   portfolio.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   portfolio.margin_used = AccountInfoDouble(ACCOUNT_MARGIN);
   portfolio.margin_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   if(portfolio.margin_used > 0) {
      portfolio.margin_level = (portfolio.equity / portfolio.margin_used) * 100.0;
   } else {
      portfolio.margin_level = 0;
   }
   
   if(portfolio.balance > 0) {
      portfolio.drawdown_pct = ((portfolio.balance - portfolio.equity) / portfolio.balance) * 100.0;
   }
   
   portfolio.best_pl = -999999;
   portfolio.worst_pl = 999999;
   
   for(int i = 0; i < algo_count; i++) {
      portfolio.total_positions += algos[i].pos_count;
      portfolio.total_lots += algos[i].total_lots;
      portfolio.total_floating_pl += algos[i].floating_pl;
      portfolio.total_realized_pl += algos[i].realized_pl;
      portfolio.total_buy += algos[i].buy_count;
      portfolio.total_sell += algos[i].sell_count;
      
      if(algos[i].pos_count > 0) portfolio.active_algos++;
      
      if(algos[i].total_pl > portfolio.best_pl) {
         portfolio.best_pl = algos[i].total_pl;
         portfolio.best_algo = algos[i].name;
      }
      
      if(algos[i].total_pl < portfolio.worst_pl) {
         portfolio.worst_pl = algos[i].total_pl;
         portfolio.worst_algo = algos[i].name;
      }
      
      if(algos[i].has_critical_issues) portfolio.critical_count++;
      if(algos[i].has_warnings) portfolio.warning_count++;
   }
}

//+------------------------------------------------------------------+
//| Analyze Market Conditions                                         |
//+------------------------------------------------------------------+
void AnalyzeMarketConditions(MarketConditions &market) {
   // Use EURUSD as market proxy
   string symbol = "EURUSD";
   if(!SymbolSelect(symbol, true)) {
      symbol = _Symbol;  // Fallback to current chart
   }
   
   double ma_fast = iMA(symbol, PERIOD_H1, 20, 0, MODE_SMA, PRICE_CLOSE);
   double ma_slow = iMA(symbol, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE);
   double atr_current = iATR(symbol, PERIOD_H1, 14);
   double atr_avg = iATR(symbol, PERIOD_D1, 14);
   
   // Determine trend
   if(ma_fast > ma_slow * 1.001) {
      market.trend_direction = "UP";
      market.trend_strength = MathMin(100, ((ma_fast / ma_slow) - 1) * 10000);
   } else if(ma_fast < ma_slow * 0.999) {
      market.trend_direction = "DOWN";
      market.trend_strength = MathMin(100, ((ma_slow / ma_fast) - 1) * 10000);
   } else {
      market.trend_direction = "RANGE";
      market.trend_strength = 0;
   }
   
   // Volatility
   if(atr_avg > 0) {
      market.atr_change_pct = ((atr_current / atr_avg) - 1) * 100.0;
   }
   
   if(market.atr_change_pct > 30) {
      market.volatility = "HIGH";
   } else if(market.atr_change_pct > -20) {
      market.volatility = "MEDIUM";
   } else {
      market.volatility = "LOW";
   }
   
   // Best strategy for conditions
   if(market.trend_strength > 50) {
      market.best_strategy_type = "TREND FOLLOWING";
      market.worst_strategy_type = "RANGE/GRID";
   } else if(market.trend_strength < 20) {
      market.best_strategy_type = "RANGE/GRID";
      market.worst_strategy_type = "BREAKOUT";
   } else {
      market.best_strategy_type = "BALANCED";
      market.worst_strategy_type = "EXTREME STRATEGIES";
   }
   
   market.market_efficiency = market.trend_strength;
}

//+------------------------------------------------------------------+
//| Calculate Correlations                                            |
//+------------------------------------------------------------------+
void CalculateCorrelations(AlgoMetrics &algos[], int algo_count, 
                          PortfolioMetrics &portfolio, double CorrelationThreshold) {
   // Simple correlation: check symbol overlap
   for(int i = 0; i < algo_count - 1; i++) {
      for(int j = i + 1; j < algo_count; j++) {
         int overlap = 0;
         for(int si = 0; si < algos[i].symbol_count; si++) {
            for(int sj = 0; sj < algos[j].symbol_count; sj++) {
               if(algos[i].symbols[si] == algos[j].symbols[sj]) {
                  overlap++;
                  break;
               }
            }
         }
         
         if(overlap > 0 && algos[i].symbol_count > 0) {
            double overlap_pct = ((double)overlap / algos[i].symbol_count) * 100.0;
            if(overlap_pct >= CorrelationThreshold) {
               algos[i].is_correlated = true;
               algos[j].is_correlated = true;
               portfolio.correlation_risk += overlap_pct;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+

#endif // CORE_DATA_COLLECTION_MQH
