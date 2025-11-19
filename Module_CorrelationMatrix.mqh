//+------------------------------------------------------------------+
//|                              Module_CorrelationMatrix.mqh        |
//|                        CORRELATION MATRIX                        |
//|                  Portfolio Correlation Analysis                  |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_CORRELATION_MATRIX_MQH
#define MODULE_CORRELATION_MATRIX_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Correlation Pair Structure                                        |
//+------------------------------------------------------------------+
struct CorrelationPair {
   string name1;
   string name2;
   double correlation;
   color cell_color;
   string interpretation;
   bool is_problematic;  // High correlation = lack of diversification
};

//+------------------------------------------------------------------+
//| Correlation Matrix Data                                           |
//+------------------------------------------------------------------+
struct CorrelationMatrixData {
   // Algo correlations
   CorrelationPair algo_pairs[50];
   int algo_pair_count;
   string algo_names[10];
   int algo_count;
   
   // Symbol correlations
   CorrelationPair symbol_pairs[50];
   int symbol_pair_count;
   string symbol_names[10];
   int symbol_count;
   
   // Portfolio metrics
   double avg_correlation;
   double max_correlation;
   double min_correlation;
   int high_correlation_count;  // Pairs with correlation > 0.7
   
   // Diversification score
   double diversification_score;  // 0-100, higher = better diversified
   string diversification_rating;
   color diversification_color;
   
   // Recommendations
   string recommendations[5];
   int recommendation_count;
   
   // Risk concentration
   double concentration_risk;  // 0-100, higher = more concentrated
   bool needs_rebalancing;
};

//+------------------------------------------------------------------+
//| Calculate Correlation Between Two Series                         |
//+------------------------------------------------------------------+
double CalculateCorrelation(double &series1[], double &series2[], int count) {
   if(count < 2) return 0;
   
   // Calculate means
   double mean1 = 0, mean2 = 0;
   for(int i = 0; i < count; i++) {
      mean1 += series1[i];
      mean2 += series2[i];
   }
   mean1 /= count;
   mean2 /= count;
   
   // Calculate correlation
   double numerator = 0;
   double sum1_sq = 0;
   double sum2_sq = 0;
   
   for(int i = 0; i < count; i++) {
      double diff1 = series1[i] - mean1;
      double diff2 = series2[i] - mean2;
      numerator += diff1 * diff2;
      sum1_sq += diff1 * diff1;
      sum2_sq += diff2 * diff2;
   }
   
   double denominator = MathSqrt(sum1_sq * sum2_sq);
   if(denominator == 0) return 0;
   
   return numerator / denominator;
}

//+------------------------------------------------------------------+
//| Get Algo Performance Series                                       |
//+------------------------------------------------------------------+
bool GetAlgoPerformanceSeries(long magic, double &returns[], int days_back) {
   datetime start = TimeCurrent() - (days_back * 86400);
   datetime now = TimeCurrent();
   
   if(!HistorySelect(start, now)) return false;
   
   // Collect daily returns
   double daily_pl[];
   datetime daily_dates[];
   ArrayResize(daily_pl, days_back);
   ArrayResize(daily_dates, days_back);
   
   for(int i = 0; i < days_back; i++) {
      daily_pl[i] = 0;
      daily_dates[i] = start + (i * 86400);
   }
   
   // Sum P&L by day
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == magic &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         
         int day_idx = (int)((deal_time - start) / 86400);
         if(day_idx >= 0 && day_idx < days_back) {
            daily_pl[day_idx] += profit;
         }
      }
   }
   
   ArrayResize(returns, days_back);
   ArrayCopy(returns, daily_pl);
   
   return true;
}

//+------------------------------------------------------------------+
//| Get Symbol Performance Series                                     |
//+------------------------------------------------------------------+
bool GetSymbolPerformanceSeries(string symbol, double &returns[], int days_back) {
   datetime start = TimeCurrent() - (days_back * 86400);
   datetime now = TimeCurrent();
   
   if(!HistorySelect(start, now)) return false;
   
   double daily_pl[];
   ArrayResize(daily_pl, days_back);
   ArrayInitialize(daily_pl, 0);
   
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) == symbol &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         
         int day_idx = (int)((deal_time - start) / 86400);
         if(day_idx >= 0 && day_idx < days_back) {
            daily_pl[day_idx] += profit;
         }
      }
   }
   
   ArrayResize(returns, days_back);
   ArrayCopy(returns, daily_pl);
   
   return true;
}

//+------------------------------------------------------------------+
//| Interpret Correlation Value                                       |
//+------------------------------------------------------------------+
string InterpretCorrelation(double corr) {
   double abs_corr = MathAbs(corr);
   
   if(abs_corr > 0.9) return "Very Strong";
   if(abs_corr > 0.7) return "Strong";
   if(abs_corr > 0.5) return "Moderate";
   if(abs_corr > 0.3) return "Weak";
   return "Very Weak";
}

//+------------------------------------------------------------------+
//| Get Color for Correlation                                         |
//+------------------------------------------------------------------+
color GetCorrelationColor(double corr) {
   double abs_corr = MathAbs(corr);
   
   if(abs_corr > 0.8) return C'220,38,38';    // Dark red - problematic
   if(abs_corr > 0.6) return C'239,68,68';    // Red
   if(abs_corr > 0.4) return C'251,191,36';   // Orange
   if(abs_corr > 0.2) return C'34,197,94';    // Green
   return C'74,222,128';                      // Light green - best
}

//+------------------------------------------------------------------+
//| Calculate Algo Correlations                                       |
//+------------------------------------------------------------------+
void CalculateAlgoCorrelations(CorrelationMatrixData &data, AlgoMetrics &algoList[], 
                               int algoCount, int days_back = 30) {
   data.algo_count = 0;
   data.algo_pair_count = 0;
   
   // Collect algo names
   for(int i = 0; i < algoCount && i < 10; i++) {
      data.algo_names[data.algo_count++] = algoList[i].name;
   }
   
   if(data.algo_count < 2) return;
   
   // Calculate pairwise correlations
   for(int i = 0; i < data.algo_count; i++) {
      for(int j = i + 1; j < data.algo_count; j++) {
         double returns1[], returns2[];
         
         if(GetAlgoPerformanceSeries(algoList[i].magic, returns1, days_back) &&
            GetAlgoPerformanceSeries(algoList[j].magic, returns2, days_back)) {
            
            double corr = CalculateCorrelation(returns1, returns2, days_back);
            
            CorrelationPair pair;
            pair.name1 = algoList[i].name;
            pair.name2 = algoList[j].name;
            pair.correlation = corr;
            pair.interpretation = InterpretCorrelation(corr);
            pair.cell_color = GetCorrelationColor(corr);
            pair.is_problematic = (MathAbs(corr) > 0.7);
            
            data.algo_pairs[data.algo_pair_count++] = pair;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Symbol Correlations                                     |
//+------------------------------------------------------------------+
void CalculateSymbolCorrelations(CorrelationMatrixData &data, int days_back = 30) {
   data.symbol_count = 0;
   data.symbol_pair_count = 0;
   
   // Collect active symbols from positions
   string symbols[];
   ArrayResize(symbols, 10);
   
   for(int i = 0; i < PositionsTotal() && data.symbol_count < 10; i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      string sym = PositionGetString(POSITION_SYMBOL);
      
      // Check if symbol already in list
      bool found = false;
      for(int j = 0; j < data.symbol_count; j++) {
         if(symbols[j] == sym) {
            found = true;
            break;
         }
      }
      
      if(!found) {
         symbols[data.symbol_count] = sym;
         data.symbol_names[data.symbol_count] = sym;
         data.symbol_count++;
      }
   }
   
   if(data.symbol_count < 2) return;
   
   // Calculate pairwise correlations
   for(int i = 0; i < data.symbol_count; i++) {
      for(int j = i + 1; j < data.symbol_count; j++) {
         double returns1[], returns2[];
         
         if(GetSymbolPerformanceSeries(symbols[i], returns1, days_back) &&
            GetSymbolPerformanceSeries(symbols[j], returns2, days_back)) {
            
            double corr = CalculateCorrelation(returns1, returns2, days_back);
            
            CorrelationPair pair;
            pair.name1 = symbols[i];
            pair.name2 = symbols[j];
            pair.correlation = corr;
            pair.interpretation = InterpretCorrelation(corr);
            pair.cell_color = GetCorrelationColor(corr);
            pair.is_problematic = (MathAbs(corr) > 0.7);
            
            data.symbol_pairs[data.symbol_pair_count++] = pair;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Portfolio Metrics                                       |
//+------------------------------------------------------------------+
void CalculatePortfolioMetrics(CorrelationMatrixData &data) {
   data.avg_correlation = 0;
   data.max_correlation = -1;
   data.min_correlation = 1;
   data.high_correlation_count = 0;
   
   int total_pairs = data.algo_pair_count + data.symbol_pair_count;
   if(total_pairs == 0) return;
   
   double sum = 0;
   
   // Process algo correlations
   for(int i = 0; i < data.algo_pair_count; i++) {
      double corr = MathAbs(data.algo_pairs[i].correlation);
      sum += corr;
      
      if(corr > data.max_correlation) data.max_correlation = corr;
      if(corr < data.min_correlation) data.min_correlation = corr;
      if(corr > 0.7) data.high_correlation_count++;
   }
   
   // Process symbol correlations
   for(int i = 0; i < data.symbol_pair_count; i++) {
      double corr = MathAbs(data.symbol_pairs[i].correlation);
      sum += corr;
      
      if(corr > data.max_correlation) data.max_correlation = corr;
      if(corr < data.min_correlation) data.min_correlation = corr;
      if(corr > 0.7) data.high_correlation_count++;
   }
   
   data.avg_correlation = sum / total_pairs;
   
   // Calculate diversification score (0-100)
   // Lower average correlation = better diversification
   data.diversification_score = (1.0 - data.avg_correlation) * 100.0;
   
   // Penalty for high correlation pairs
   double penalty = (double)data.high_correlation_count / total_pairs * 30.0;
   data.diversification_score -= penalty;
   
   if(data.diversification_score < 0) data.diversification_score = 0;
   if(data.diversification_score > 100) data.diversification_score = 100;
   
   // Rating
   if(data.diversification_score >= 80) {
      data.diversification_rating = "Excellent";
      data.diversification_color = C'34,197,94';
   } else if(data.diversification_score >= 60) {
      data.diversification_rating = "Good";
      data.diversification_color = C'74,222,128';
   } else if(data.diversification_score >= 40) {
      data.diversification_rating = "Fair";
      data.diversification_color = C'251,191,36';
   } else {
      data.diversification_rating = "Poor";
      data.diversification_color = C'239,68,68';
   }
   
   // Concentration risk
   data.concentration_risk = 100.0 - data.diversification_score;
   data.needs_rebalancing = (data.high_correlation_count > 0 || 
                            data.diversification_score < 50);
}

//+------------------------------------------------------------------+
//| Generate Recommendations                                          |
//+------------------------------------------------------------------+
void GenerateRecommendations(CorrelationMatrixData &data) {
   data.recommendation_count = 0;
   
   if(data.diversification_score >= 80) {
      data.recommendations[data.recommendation_count++] = 
         "✓ Excellent diversification - portfolio is well-balanced";
   }
   
   if(data.high_correlation_count > 0) {
      data.recommendations[data.recommendation_count++] = 
         StringFormat("⚠ %d highly correlated pairs detected - consider reducing overlap",
                     data.high_correlation_count);
   }
   
   if(data.avg_correlation > 0.5) {
      data.recommendations[data.recommendation_count++] = 
         "⚠ Average correlation is high - add uncorrelated strategies";
   }
   
   if(data.algo_count < 3) {
      data.recommendations[data.recommendation_count++] = 
         "💡 Run more algorithms to improve diversification";
   }
   
   if(data.symbol_count < 3) {
      data.recommendations[data.recommendation_count++] = 
         "💡 Trade more symbols to reduce concentration risk";
   }
   
   if(data.needs_rebalancing) {
      data.recommendations[data.recommendation_count++] = 
         "🔄 Portfolio rebalancing recommended";
   }
   
   if(data.recommendation_count == 0) {
      data.recommendations[data.recommendation_count++] = 
         "✓ Portfolio structure is optimal - maintain current allocation";
   }
}

//+------------------------------------------------------------------+
//| Main Correlation Analysis Function                                |
//+------------------------------------------------------------------+
void GenerateCorrelationMatrix(CorrelationMatrixData &data, 
                               AlgoMetrics &algoList[], 
                               int algoCount,
                               int days_back = 30) {
   ZeroMemory(data);
   
   CalculateAlgoCorrelations(data, algoList, algoCount, days_back);
   CalculateSymbolCorrelations(data, days_back);
   CalculatePortfolioMetrics(data);
   GenerateRecommendations(data);
}

//+------------------------------------------------------------------+

#endif // MODULE_CORRELATION_MATRIX_MQH
