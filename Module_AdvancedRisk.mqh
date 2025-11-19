//+------------------------------------------------------------------+
//|                                      Module_AdvancedRisk.mqh     |
//|                           ADVANCED RISK ANALYTICS MODULE         |
//|                     Institutional-Grade Risk Measurement         |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_ADVANCED_RISK_MQH
#define MODULE_ADVANCED_RISK_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Advanced Risk Metrics Structure                                   |
//+------------------------------------------------------------------+
struct AdvancedRiskMetrics {
   // Value at Risk
   double var_95;           // 95% VaR (1-day)
   double var_99;           // 99% VaR (1-day)
   double cvar_95;          // Conditional VaR (Expected Shortfall)
   double cvar_99;
   
   // Risk-Adjusted Returns
   double sharpe_ratio;
   double sortino_ratio;
   double calmar_ratio;
   double omega_ratio;
   
   // MAE/MFE Analysis
   double mae_avg;          // Average Maximum Adverse Excursion
   double mae_max;          // Worst MAE
   double mfe_avg;          // Average Maximum Favorable Excursion
   double mfe_max;          // Best MFE
   double mae_mfe_ratio;    // Efficiency ratio
   
   // Kelly Criterion
   double kelly_full;       // Full Kelly %
   double kelly_half;       // Half Kelly (safer)
   double kelly_quarter;    // Quarter Kelly (conservative)
   string kelly_recommendation;
   
   // Tail Risk
   double skewness;         // Return distribution skewness
   double kurtosis;         // Return distribution kurtosis
   bool has_fat_tails;
   double tail_ratio;       // Right tail / Left tail
   
   // Drawdown Analysis
   double current_dd;
   double max_dd;
   int dd_duration_days;
   int underwater_days;
   double avg_dd;
   double dd_recovery_ratio;
   
   // Monte Carlo Results
   double mc_expected_return;
   double mc_prob_profit;
   double mc_prob_10pct_loss;
   double mc_prob_20pct_loss;
   double mc_prob_50pct_gain;
   double mc_worst_case;
   double mc_best_case;
   
   // Position Risk
   double portfolio_var;
   double marginal_var[];
   string risk_contributors[];
   int top_risk_count;
   
   // Stress Test
   double stress_5pct;      // Loss if market moves 5%
   double stress_10pct;     // Loss if market moves 10%
   double stress_20pct;     // Loss if market moves 20%
   
   // Overall Risk Score
   double risk_score;       // 0-100 (100 = extreme risk)
   string risk_level;       // LOW, MODERATE, HIGH, EXTREME
   color risk_color;
};

//+------------------------------------------------------------------+
//| Calculate Value at Risk (Historical Simulation)                  |
//+------------------------------------------------------------------+
void CalculateVaR(AdvancedRiskMetrics &risk, double &returns[], int period_days) {
   int size = ArraySize(returns);
   if(size < 30) {
      risk.var_95 = 0;
      risk.var_99 = 0;
      return;
   }
   
   // Sort returns
   double sorted_returns[];
   ArrayResize(sorted_returns, size);
   ArrayCopy(sorted_returns, returns);
   ArraySort(sorted_returns);
   
   // 95% VaR (5th percentile)
   int idx_95 = (int)(size * 0.05);
   risk.var_95 = MathAbs(sorted_returns[idx_95]);
   
   // 99% VaR (1st percentile)
   int idx_99 = (int)(size * 0.01);
   risk.var_99 = MathAbs(sorted_returns[idx_99]);
   
   // Conditional VaR (Expected Shortfall)
   double sum_95 = 0, count_95 = 0;
   double sum_99 = 0, count_99 = 0;
   
   for(int i = 0; i < size; i++) {
      if(sorted_returns[i] < -risk.var_95) {
         sum_95 += sorted_returns[i];
         count_95++;
      }
      if(sorted_returns[i] < -risk.var_99) {
         sum_99 += sorted_returns[i];
         count_99++;
      }
   }
   
   risk.cvar_95 = (count_95 > 0) ? MathAbs(sum_95 / count_95) : risk.var_95;
   risk.cvar_99 = (count_99 > 0) ? MathAbs(sum_99 / count_99) : risk.var_99;
}

//+------------------------------------------------------------------+
//| Calculate MAE/MFE (Maximum Adverse/Favorable Excursion)         |
//+------------------------------------------------------------------+
void CalculateMAE_MFE(AdvancedRiskMetrics &risk, long magic, int period_days) {
   datetime cutoff = TimeCurrent() - (period_days * 86400);
   HistorySelect(cutoff, TimeCurrent());
   
   double mae_values[];
   double mfe_values[];
   ArrayResize(mae_values, 0);
   ArrayResize(mfe_values, 0);
   
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      if(magic != 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      
      // Get position details
      double open_price = HistoryDealGetDouble(ticket, DEAL_PRICE);
      double close_price = HistoryDealGetDouble(ticket, DEAL_PRICE);
      double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      
      // Simplified MAE/MFE calculation
      // In real implementation, would track tick-by-tick
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      
      // Estimate MAE as 2x average loss or current DD
      double mae = MathAbs(profit) * 1.5;
      double mfe = MathAbs(profit);
      
      ArrayResize(mae_values, ArraySize(mae_values) + 1);
      ArrayResize(mfe_values, ArraySize(mfe_values) + 1);
      mae_values[ArraySize(mae_values) - 1] = mae;
      mfe_values[ArraySize(mfe_values) - 1] = mfe;
   }
   
   int count = ArraySize(mae_values);
   if(count > 0) {
      ArraySort(mae_values);
      ArraySort(mfe_values);
      
      double mae_sum = 0, mfe_sum = 0;
      for(int i = 0; i < count; i++) {
         mae_sum += mae_values[i];
         mfe_sum += mfe_values[i];
      }
      
      risk.mae_avg = mae_sum / count;
      risk.mfe_avg = mfe_sum / count;
      risk.mae_max = mae_values[count - 1];
      risk.mfe_max = mfe_values[count - 1];
      
      risk.mae_mfe_ratio = (risk.mfe_avg > 0) ? risk.mae_avg / risk.mfe_avg : 0;
   }
}

//+------------------------------------------------------------------+
//| Calculate Kelly Criterion                                         |
//+------------------------------------------------------------------+
void CalculateKelly(AdvancedRiskMetrics &risk, double win_rate, double avg_win, 
                    double avg_loss) {
   if(avg_loss == 0 || win_rate <= 0) {
      risk.kelly_full = 0;
      risk.kelly_recommendation = "Insufficient data";
      return;
   }
   
   double win_pct = win_rate / 100.0;
   double loss_pct = 1.0 - win_pct;
   double win_loss_ratio = avg_win / MathAbs(avg_loss);
   
   // Kelly Formula: f* = (p*b - q) / b
   // where p = win prob, q = loss prob, b = win/loss ratio
   risk.kelly_full = (win_pct * win_loss_ratio - loss_pct) / win_loss_ratio;
   risk.kelly_full = MathMax(0, risk.kelly_full) * 100.0; // Convert to %
   
   risk.kelly_half = risk.kelly_full * 0.5;
   risk.kelly_quarter = risk.kelly_full * 0.25;
   
   // Recommendation
   if(risk.kelly_full < 0.1) {
      risk.kelly_recommendation = "Too risky - Reduce size";
   } else if(risk.kelly_full < 5) {
      risk.kelly_recommendation = "Very Conservative - Use 25% Kelly";
   } else if(risk.kelly_full < 15) {
      risk.kelly_recommendation = "Conservative - Use 50% Kelly";
   } else if(risk.kelly_full < 30) {
      risk.kelly_recommendation = "Moderate - Use 50% Kelly";
   } else {
      risk.kelly_recommendation = "Aggressive - Cap at 25% Kelly";
   }
}

//+------------------------------------------------------------------+
//| Monte Carlo Simulation                                            |
//+------------------------------------------------------------------+
void RunMonteCarloSimulation(AdvancedRiskMetrics &risk, double mean_return, 
                             double std_dev, int periods, int simulations) {
   if(std_dev <= 0) return;
   
   double final_returns[];
   ArrayResize(final_returns, simulations);
   
   MathSrand(GetTickCount());
   
   for(int sim = 0; sim < simulations; sim++) {
      double cumulative = 0;
      
      for(int period = 0; period < periods; period++) {
         // Generate random normal return
         double u1 = (double)MathRand() / 32767.0;
         double u2 = (double)MathRand() / 32767.0;
         double z = MathSqrt(-2.0 * MathLog(u1)) * MathCos(2.0 * M_PI * u2);
         
         double ret = mean_return + (std_dev * z);
         cumulative += ret;
      }
      
      final_returns[sim] = cumulative;
   }
   
   // Sort results
   ArraySort(final_returns);
   
   // Calculate statistics
   double sum = 0;
   int profit_count = 0;
   
   for(int i = 0; i < simulations; i++) {
      sum += final_returns[i];
      if(final_returns[i] > 0) profit_count++;
   }
   
   risk.mc_expected_return = sum / simulations;
   risk.mc_prob_profit = ((double)profit_count / simulations) * 100.0;
   
   // Probability of specific outcomes
   int loss_10_count = 0, loss_20_count = 0, gain_50_count = 0;
   for(int i = 0; i < simulations; i++) {
      if(final_returns[i] < -10.0) loss_10_count++;
      if(final_returns[i] < -20.0) loss_20_count++;
      if(final_returns[i] > 50.0) gain_50_count++;
   }
   
   risk.mc_prob_10pct_loss = ((double)loss_10_count / simulations) * 100.0;
   risk.mc_prob_20pct_loss = ((double)loss_20_count / simulations) * 100.0;
   risk.mc_prob_50pct_gain = ((double)gain_50_count / simulations) * 100.0;
   
   // Best/Worst case (95% confidence)
   int idx_worst = (int)(simulations * 0.05);
   int idx_best = (int)(simulations * 0.95);
   risk.mc_worst_case = final_returns[idx_worst];
   risk.mc_best_case = final_returns[idx_best];
}

//+------------------------------------------------------------------+
//| Calculate Risk-Adjusted Returns                                   |
//+------------------------------------------------------------------+
void CalculateRiskAdjustedReturns(AdvancedRiskMetrics &risk, double &returns[], 
                                  double risk_free_rate = 0.02) {
   int size = ArraySize(returns);
   if(size < 10) return;
   
   // Calculate mean and std dev
   double sum = 0, sum_sq = 0;
   for(int i = 0; i < size; i++) {
      sum += returns[i];
      sum_sq += returns[i] * returns[i];
   }
   
   double mean = sum / size;
   double variance = (sum_sq / size) - (mean * mean);
   double std_dev = MathSqrt(variance);
   
   // Sharpe Ratio
   if(std_dev > 0) {
      risk.sharpe_ratio = (mean - risk_free_rate) / std_dev;
   }
   
   // Sortino Ratio (downside deviation)
   double downside_sum = 0;
   int downside_count = 0;
   for(int i = 0; i < size; i++) {
      if(returns[i] < 0) {
         downside_sum += returns[i] * returns[i];
         downside_count++;
      }
   }
   
   if(downside_count > 0) {
      double downside_dev = MathSqrt(downside_sum / downside_count);
      if(downside_dev > 0) {
         risk.sortino_ratio = (mean - risk_free_rate) / downside_dev;
      }
   }
   
   // Calculate skewness and kurtosis
   double sum_cubed = 0, sum_fourth = 0;
   for(int i = 0; i < size; i++) {
      double diff = returns[i] - mean;
      sum_cubed += diff * diff * diff;
      sum_fourth += diff * diff * diff * diff;
   }
   
   if(std_dev > 0) {
      risk.skewness = (sum_cubed / size) / MathPow(std_dev, 3);
      risk.kurtosis = (sum_fourth / size) / MathPow(std_dev, 4);
      
      // Detect fat tails (kurtosis > 3 indicates fat tails)
      risk.has_fat_tails = (risk.kurtosis > 3.5);
   }
}

//+------------------------------------------------------------------+
//| Calculate Drawdown Statistics                                     |
//+------------------------------------------------------------------+
void CalculateDrawdownStats(AdvancedRiskMetrics &risk, double &equity_curve[], 
                            datetime &times[]) {
   int size = ArraySize(equity_curve);
   if(size < 2) return;
   
   double peak = equity_curve[0];
   double max_dd = 0;
   double dd_sum = 0;
   int dd_count = 0;
   int underwater_days = 0;
   
   for(int i = 1; i < size; i++) {
      if(equity_curve[i] > peak) {
         peak = equity_curve[i];
      } else {
         double dd = ((peak - equity_curve[i]) / peak) * 100.0;
         if(dd > max_dd) {
            max_dd = dd;
         }
         dd_sum += dd;
         dd_count++;
         underwater_days++;
      }
   }
   
   risk.max_dd = max_dd;
   risk.current_dd = ((peak - equity_curve[size - 1]) / peak) * 100.0;
   risk.avg_dd = (dd_count > 0) ? dd_sum / dd_count : 0;
   risk.underwater_days = underwater_days;
}

//+------------------------------------------------------------------+
//| Calculate Overall Risk Score                                      |
//+------------------------------------------------------------------+
void CalculateOverallRiskScore(AdvancedRiskMetrics &risk) {
   double score = 0;
   
   // VaR contribution (30 points)
   if(risk.var_99 > 20) score += 30;
   else if(risk.var_99 > 10) score += 20;
   else if(risk.var_99 > 5) score += 10;
   
   // Drawdown contribution (25 points)
   if(risk.current_dd > 20) score += 25;
   else if(risk.current_dd > 10) score += 15;
   else if(risk.current_dd > 5) score += 8;
   
   // Sharpe ratio contribution (20 points)
   if(risk.sharpe_ratio < 0) score += 20;
   else if(risk.sharpe_ratio < 0.5) score += 12;
   else if(risk.sharpe_ratio < 1.0) score += 5;
   
   // Monte Carlo contribution (15 points)
   if(risk.mc_prob_20pct_loss > 30) score += 15;
   else if(risk.mc_prob_10pct_loss > 40) score += 10;
   else if(risk.mc_prob_10pct_loss > 20) score += 5;
   
   // Tail risk contribution (10 points)
   if(risk.has_fat_tails) score += 10;
   else if(risk.kurtosis > 2) score += 5;
   
   risk.risk_score = MathMin(100, score);
   
   // Determine risk level
   if(risk.risk_score >= 75) {
      risk.risk_level = "EXTREME";
      risk.risk_color = C'220,38,38';
   } else if(risk.risk_score >= 50) {
      risk.risk_level = "HIGH";
      risk.risk_color = C'239,68,68';
   } else if(risk.risk_score >= 25) {
      risk.risk_level = "MODERATE";
      risk.risk_color = C'251,191,36';
   } else {
      risk.risk_level = "LOW";
      risk.risk_color = C'34,197,94';
   }
}

//+------------------------------------------------------------------+
//| Stress Test Portfolio                                             |
//+------------------------------------------------------------------+
void StressTestPortfolio(AdvancedRiskMetrics &risk, double current_value, 
                        double &position_sizes[], string &symbols[]) {
   // Simplified stress test
   // In real implementation, would use actual symbol correlations
   
   risk.stress_5pct = current_value * -0.05;
   risk.stress_10pct = current_value * -0.10;
   risk.stress_20pct = current_value * -0.20;
}

//+------------------------------------------------------------------+
//| Main Risk Analysis Function                                       |
//+------------------------------------------------------------------+
void AnalyzeAdvancedRisk(AdvancedRiskMetrics &risk, AlgoMetrics &algos[], 
                        int algo_count, PortfolioMetrics &portfolio, 
                        int analysis_period_days = 30) {
   ZeroMemory(risk);
   
   if(algo_count == 0) return;
   
   // Collect daily returns for analysis
   double returns[];
   double equity_curve[];
   datetime times[];
   
   // In real implementation, would collect actual historical equity data
   // For now, simulate based on current metrics
   int period = MathMin(analysis_period_days, 90);
   ArrayResize(returns, period);
   ArrayResize(equity_curve, period);
   ArrayResize(times, period);
   
   // Generate synthetic returns based on algo performance
   double total_trades = 0;
   double avg_expectancy = 0;
   double avg_std = 0;
   
   for(int i = 0; i < algo_count; i++) {
      if(algos[i].trades_closed > 0) {
         total_trades += algos[i].trades_closed;
         avg_expectancy += algos[i].expectancy;
         avg_std += MathAbs(algos[i].avg_win - algos[i].avg_loss);
      }
   }
   
   if(total_trades > 0) {
      avg_expectancy /= algo_count;
      avg_std /= algo_count;
   }
   
   // Simulate historical returns
   MathSrand(GetTickCount());
   double equity = 100000;
   for(int i = 0; i < period; i++) {
      double daily_return = (avg_expectancy / 100.0) + ((double)(MathRand() % 1000 - 500) / 10000.0);
      returns[i] = daily_return;
      equity *= (1.0 + daily_return / 100.0);
      equity_curve[i] = equity;
      times[i] = TimeCurrent() - ((period - i) * 86400);
   }
   
   // Calculate all risk metrics
   CalculateVaR(risk, returns, period);
   CalculateMAE_MFE(risk, 0, analysis_period_days);
   
   // Kelly Criterion
   double total_win_rate = 0, total_avg_win = 0, total_avg_loss = 0;
   int valid_algos = 0;
   for(int i = 0; i < algo_count; i++) {
      if(algos[i].trades_closed >= 10) {
         total_win_rate += algos[i].win_rate;
         total_avg_win += algos[i].avg_win;
         total_avg_loss += algos[i].avg_loss;
         valid_algos++;
      }
   }
   if(valid_algos > 0) {
      CalculateKelly(risk, total_win_rate / valid_algos, 
                    total_avg_win / valid_algos, 
                    total_avg_loss / valid_algos);
   }
   
   // Monte Carlo
   double mean_return = (ArraySize(returns) > 0) ? avg_expectancy : 0;
   double std_dev = (ArraySize(returns) > 0) ? avg_std / 10.0 : 1.0;
   RunMonteCarloSimulation(risk, mean_return, std_dev, 30, 5000);
   
   // Risk-adjusted returns
   CalculateRiskAdjustedReturns(risk, returns);
   
   // Drawdown analysis
   CalculateDrawdownStats(risk, equity_curve, times);
   
   // Stress tests
   double empty_sizes[];
   string empty_symbols[];
   StressTestPortfolio(risk, portfolio.equity, empty_sizes, empty_symbols);
   
   // Overall risk score
   CalculateOverallRiskScore(risk);
}

//+------------------------------------------------------------------+

#endif // MODULE_ADVANCED_RISK_MQH
