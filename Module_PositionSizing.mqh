//+------------------------------------------------------------------+
//|                              Module_PositionSizing.mqh           |
//|                      POSITION SIZING CALCULATOR                  |
//|                  Dynamic Position Size Recommendations           |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_POSITION_SIZING_MQH
#define MODULE_POSITION_SIZING_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Position Sizing Method                                            |
//+------------------------------------------------------------------+
enum SIZING_METHOD {
   SIZING_FIXED_LOT,        // Fixed lot size
   SIZING_FIXED_RISK,       // Fixed risk percentage
   SIZING_KELLY,            // Kelly Criterion
   SIZING_OPTIMAL_F,        // Optimal F
   SIZING_PERCENT_EQUITY,   // Percentage of equity
   SIZING_VOLATILITY_BASED, // Based on ATR/volatility
   SIZING_RISK_REWARD       // Based on risk/reward ratio
};

//+------------------------------------------------------------------+
//| Position Size Recommendation                                      |
//+------------------------------------------------------------------+
struct SizeRecommendation {
   SIZING_METHOD method;
   string method_name;
   double recommended_lots;
   double risk_amount;
   double risk_percent;
   double potential_profit;
   double potential_loss;
   string explanation;
   color recommendation_color;
   int confidence_score;  // 0-100
};

//+------------------------------------------------------------------+
//| Position Sizing Data                                              |
//+------------------------------------------------------------------+
struct PositionSizingData {
   // Current account state
   double equity;
   double balance;
   double free_margin;
   double margin_level;
   double used_margin_pct;
   
   // Recommendations by method
   SizeRecommendation recommendations[7];
   int recommendation_count;
   
   // Suggested optimal size
   double optimal_size;
   string optimal_method;
   string optimal_explanation;
   
   // Risk metrics
   double max_position_size;
   double conservative_size;
   double moderate_size;
   double aggressive_size;
   
   // Portfolio heat
   double current_heat;        // % of equity at risk
   double remaining_heat;      // % of equity still available for risk
   double heat_after_trade;    // Heat if trade is taken
   
   // Symbol-specific data
   string symbol;
   double symbol_point;
   double symbol_tick_value;
   double symbol_min_lot;
   double symbol_max_lot;
   double symbol_lot_step;
   double symbol_atr;
   double stop_loss_pips;
   double take_profit_pips;
};

//+------------------------------------------------------------------+
//| Calculate Fixed Risk Size                                         |
//+------------------------------------------------------------------+
double CalculateFixedRiskSize(double equity, double risk_pct, double sl_pips, 
                             string symbol, double &risk_amount) {
   risk_amount = equity * (risk_pct / 100.0);
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(sl_pips <= 0 || point <= 0 || tick_value <= 0) return 0;
   
   double pip_value = tick_value / point;
   double lots = risk_amount / (sl_pips * pip_value * 10.0);
   
   // Round to lot step
   double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / lot_step) * lot_step;
   
   // Apply limits
   double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(lots < min_lot) lots = min_lot;
   if(lots > max_lot) lots = max_lot;
   
   return lots;
}

//+------------------------------------------------------------------+
//| Calculate Kelly Criterion Size                                    |
//+------------------------------------------------------------------+
double CalculateKellySize(double equity, double win_rate, double avg_win, 
                         double avg_loss, double sl_pips, string symbol) {
   if(avg_loss <= 0 || win_rate <= 0) return 0;
   
   double win_prob = win_rate / 100.0;
   double loss_prob = 1.0 - win_prob;
   
   // Kelly formula: f = (p*b - q) / b
   // where p = win probability, q = loss probability, b = win/loss ratio
   double b = avg_win / avg_loss;
   double kelly_pct = ((win_prob * b) - loss_prob) / b;
   
   // Use half-Kelly for safety
   kelly_pct = kelly_pct / 2.0;
   
   if(kelly_pct <= 0) return 0;
   if(kelly_pct > 0.1) kelly_pct = 0.1;  // Cap at 10%
   
   double risk_amount = 0;
   return CalculateFixedRiskSize(equity, kelly_pct * 100.0, sl_pips, symbol, risk_amount);
}

//+------------------------------------------------------------------+
//| Calculate Volatility-Based Size                                   |
//+------------------------------------------------------------------+
double CalculateVolatilitySize(double equity, double atr, double risk_pct, 
                              string symbol, double &risk_amount) {
   risk_amount = equity * (risk_pct / 100.0);
   
   if(atr <= 0) return 0;
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   // Use 2x ATR as stop loss
   double sl_pips = (atr / point) / 10.0;
   
   return CalculateFixedRiskSize(equity, risk_pct, sl_pips, symbol, risk_amount);
}

//+------------------------------------------------------------------+
//| Calculate Portfolio Heat                                          |
//+------------------------------------------------------------------+
void CalculatePortfolioHeat(PositionSizingData &data) {
   data.current_heat = 0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(equity <= 0) return;
   
   // Calculate current heat from open positions
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      double position_risk = 0;
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      
      if(sl > 0) {
         double sl_pips = MathAbs(open_price - sl) / SymbolInfoDouble(data.symbol, SYMBOL_POINT);
         position_risk = sl_pips * volume * SymbolInfoDouble(data.symbol, SYMBOL_TRADE_TICK_VALUE);
      }
      
      data.current_heat += (position_risk / equity) * 100.0;
   }
   
   data.remaining_heat = MathMax(0, 10.0 - data.current_heat);  // Assume 10% max heat
}

//+------------------------------------------------------------------+
//| Generate Position Size Recommendations                            |
//+------------------------------------------------------------------+
void GeneratePositionSizingRecommendations(PositionSizingData &data, 
                                          string symbol,
                                          double sl_pips,
                                          double tp_pips,
                                          TradeStats &stats) {
   ZeroMemory(data);
   
   data.symbol = symbol;
   data.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   data.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   data.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   data.margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   
   data.symbol_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   data.symbol_tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   data.symbol_min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   data.symbol_max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   data.symbol_lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   data.stop_loss_pips = sl_pips;
   data.take_profit_pips = tp_pips;
   
   // Calculate ATR
   int atr_handle = iATR(symbol, PERIOD_H1, 14);
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0) {
      data.symbol_atr = atr_buffer[0];
   }
   IndicatorRelease(atr_handle);
   
   CalculatePortfolioHeat(data);
   
   data.recommendation_count = 0;
   
   // Method 1: Fixed 1% Risk
   SizeRecommendation rec1;
   rec1.method = SIZING_FIXED_RISK;
   rec1.method_name = "Fixed 1% Risk";
   double risk_amt = 0;
   rec1.recommended_lots = CalculateFixedRiskSize(data.equity, 1.0, sl_pips, symbol, risk_amt);
   rec1.risk_amount = risk_amt;
   rec1.risk_percent = 1.0;
   rec1.potential_loss = risk_amt;
   rec1.potential_profit = (tp_pips / sl_pips) * risk_amt;
   rec1.explanation = "Conservative: Risk 1% of equity per trade";
   rec1.recommendation_color = C'34,197,94';
   rec1.confidence_score = 85;
   data.recommendations[data.recommendation_count++] = rec1;
   
   // Method 2: Fixed 2% Risk
   SizeRecommendation rec2;
   rec2.method = SIZING_FIXED_RISK;
   rec2.method_name = "Fixed 2% Risk";
   rec2.recommended_lots = CalculateFixedRiskSize(data.equity, 2.0, sl_pips, symbol, risk_amt);
   rec2.risk_amount = risk_amt;
   rec2.risk_percent = 2.0;
   rec2.potential_loss = risk_amt;
   rec2.potential_profit = (tp_pips / sl_pips) * risk_amt;
   rec2.explanation = "Moderate: Risk 2% of equity per trade";
   rec2.recommendation_color = C'251,191,36';
   rec2.confidence_score = 70;
   data.recommendations[data.recommendation_count++] = rec2;
   
   // Method 3: Kelly Criterion
   if(stats.total_trades > 10) {
      SizeRecommendation rec3;
      rec3.method = SIZING_KELLY;
      rec3.method_name = "Kelly Criterion";
      rec3.recommended_lots = CalculateKellySize(data.equity, stats.win_rate, 
                                                  stats.avg_win, stats.avg_loss, 
                                                  sl_pips, symbol);
      // Calculate risk for Kelly size
      double kelly_risk = rec3.recommended_lots * sl_pips * 
                         (data.symbol_tick_value / data.symbol_point) * 10.0;
      rec3.risk_amount = kelly_risk;
      rec3.risk_percent = (kelly_risk / data.equity) * 100.0;
      rec3.potential_loss = kelly_risk;
      rec3.potential_profit = (tp_pips / sl_pips) * kelly_risk;
      rec3.explanation = "Optimal: Based on historical win rate and avg win/loss";
      rec3.recommendation_color = C'59,130,246';
      rec3.confidence_score = 75;
      data.recommendations[data.recommendation_count++] = rec3;
   }
   
   // Method 4: Volatility-Based (ATR)
   if(data.symbol_atr > 0) {
      SizeRecommendation rec4;
      rec4.method = SIZING_VOLATILITY_BASED;
      rec4.method_name = "Volatility-Based";
      rec4.recommended_lots = CalculateVolatilitySize(data.equity, data.symbol_atr, 
                                                       1.5, symbol, risk_amt);
      rec4.risk_amount = risk_amt;
      rec4.risk_percent = 1.5;
      rec4.potential_loss = risk_amt;
      rec4.potential_profit = (tp_pips / sl_pips) * risk_amt;
      rec4.explanation = "Adaptive: Position size adjusts with market volatility (ATR)";
      rec4.recommendation_color = C'168,85,247';
      rec4.confidence_score = 80;
      data.recommendations[data.recommendation_count++] = rec4;
   }
   
   // Method 5: Percent of Equity
   SizeRecommendation rec5;
   rec5.method = SIZING_PERCENT_EQUITY;
   rec5.method_name = "5% of Equity";
   double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   rec5.recommended_lots = (data.equity * 0.05) / contract_size;
   rec5.recommended_lots = MathFloor(rec5.recommended_lots / data.symbol_lot_step) * data.symbol_lot_step;
   if(rec5.recommended_lots < data.symbol_min_lot) rec5.recommended_lots = data.symbol_min_lot;
   if(rec5.recommended_lots > data.symbol_max_lot) rec5.recommended_lots = data.symbol_max_lot;
   double equity_risk = rec5.recommended_lots * sl_pips * 
                       (data.symbol_tick_value / data.symbol_point) * 10.0;
   rec5.risk_amount = equity_risk;
   rec5.risk_percent = (equity_risk / data.equity) * 100.0;
   rec5.potential_loss = equity_risk;
   rec5.potential_profit = (tp_pips / sl_pips) * equity_risk;
   rec5.explanation = "Simple: Use 5% of equity as position size";
   rec5.recommendation_color = C'156,163,175';
   rec5.confidence_score = 60;
   data.recommendations[data.recommendation_count++] = rec5;
   
   // Determine optimal recommendation
   int best_idx = 0;
   int best_score = 0;
   
   for(int i = 0; i < data.recommendation_count; i++) {
      // Prefer methods with good confidence and reasonable risk
      int score = data.recommendations[i].confidence_score;
      if(data.recommendations[i].risk_percent > 0 && data.recommendations[i].risk_percent < 2.5) {
         score += 20;  // Bonus for being in safe range
      }
      
      if(score > best_score) {
         best_score = score;
         best_idx = i;
      }
   }
   
   data.optimal_size = data.recommendations[best_idx].recommended_lots;
   data.optimal_method = data.recommendations[best_idx].method_name;
   data.optimal_explanation = data.recommendations[best_idx].explanation;
   
   // Calculate risk levels
   data.conservative_size = data.recommendations[0].recommended_lots;  // 1% risk
   data.moderate_size = (data.recommendation_count > 1) ? 
                        data.recommendations[1].recommended_lots : data.conservative_size;
   data.aggressive_size = data.optimal_size;
   
   // Calculate portfolio heat impact
   if(data.optimal_size > 0 && sl_pips > 0) {
      double trade_risk = data.optimal_size * sl_pips * 
                         (data.symbol_tick_value / data.symbol_point) * 10.0;
      data.heat_after_trade = data.current_heat + ((trade_risk / data.equity) * 100.0);
   }
}

//+------------------------------------------------------------------+
//| Quick Position Size Calculator                                    |
//+------------------------------------------------------------------+
double QuickCalculateSize(string symbol, double risk_pct, double sl_pips) {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = 0;
   return CalculateFixedRiskSize(equity, risk_pct, sl_pips, symbol, risk_amount);
}

//+------------------------------------------------------------------+

#endif // MODULE_POSITION_SIZING_MQH
