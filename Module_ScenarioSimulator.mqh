//+------------------------------------------------------------------+
//|                                   Module_ScenarioSimulator.mqh   |
//|                         LIVE SCENARIO SIMULATION ENGINE          |
//|                    What-If Analysis | Decision Support           |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_SCENARIO_SIMULATOR_MQH
#define MODULE_SCENARIO_SIMULATOR_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Scenario Types                                                    |
//+------------------------------------------------------------------+
enum SCENARIO_TYPE {
   SCENARIO_CLOSE_ALGO,        // Close specific algo
   SCENARIO_CLOSE_WORST,       // Close worst performing algo
   SCENARIO_CLOSE_ALL_LOSING,  // Close all losing positions
   SCENARIO_HEDGE_USD,         // Hedge USD exposure
   SCENARIO_HEDGE_EUR,         // Hedge EUR exposure
   SCENARIO_MARKET_GAP_UP,     // Market gaps up
   SCENARIO_MARKET_GAP_DOWN,   // Market gaps down
   SCENARIO_REDUCE_SIZE,       // Reduce position sizes by %
   SCENARIO_ADD_POSITION       // Add new position
};

//+------------------------------------------------------------------+
//| Scenario Result Structure                                         |
//+------------------------------------------------------------------+
struct ScenarioResult {
   // Before state
   double before_equity;
   double before_margin_level;
   double before_floating_pl;
   double before_total_lots;
   int before_position_count;
   double before_exposure;
   double before_risk_score;
   
   // After state
   double after_equity;
   double after_margin_level;
   double after_floating_pl;
   double after_total_lots;
   int after_position_count;
   double after_exposure;
   double after_risk_score;
   
   // Impact
   double equity_change;
   double margin_level_change;
   double pl_change;
   double lots_change;
   int positions_closed;
   double exposure_reduction;
   double risk_reduction;
   
   // Recommendation
   string recommendation;
   color recommendation_color;
   double confidence_score;  // 0-100
   
   // Details
   string action_description;
   string impact_summary;
   string warnings[10];  // Fixed size array
   int warning_count;
   string benefits[10];   // Fixed size array
   int benefit_count;
};

//+------------------------------------------------------------------+
//| Simulate Closing Algo                                             |
//+------------------------------------------------------------------+
void SimulateCloseAlgo(ScenarioResult &result, AlgoMetrics &target_algo,
                       AlgoMetrics &algos[], int algo_count,
                       PortfolioMetrics &current_portfolio) {
   
   ZeroMemory(result);
   
   // Capture before state
   result.before_equity = current_portfolio.equity;
   result.before_margin_level = current_portfolio.margin_level;
   result.before_floating_pl = current_portfolio.total_floating_pl;
   result.before_total_lots = current_portfolio.total_lots;
   result.before_position_count = current_portfolio.total_positions;
   result.before_risk_score = 50; // Simplified
   
   // Simulate closing this algo
   result.after_equity = result.before_equity + target_algo.floating_pl;
   result.after_floating_pl = result.before_floating_pl - target_algo.floating_pl;
   result.after_total_lots = result.before_total_lots - target_algo.total_lots;
   result.after_position_count = result.before_position_count - target_algo.pos_count;
   
   // Calculate new margin level (simplified)
   double closed_margin = current_portfolio.margin_used * (target_algo.total_lots / result.before_total_lots);
   double new_margin_used = current_portfolio.margin_used - closed_margin;
   
   if(new_margin_used > 0) {
      result.after_margin_level = (result.after_equity / new_margin_used) * 100.0;
   } else {
      result.after_margin_level = 0; // No positions = no margin
   }
   
   result.after_margin_level = MathMax(result.after_margin_level, result.before_margin_level);
   
   // Calculate impacts
   result.equity_change = result.after_equity - result.before_equity;
   result.margin_level_change = result.after_margin_level - result.before_margin_level;
   result.pl_change = target_algo.floating_pl;
   result.lots_change = -target_algo.total_lots;
   result.positions_closed = target_algo.pos_count;
   
   // Risk reduction (simplified)
   result.risk_reduction = (target_algo.total_lots / result.before_total_lots) * 30.0;
   result.after_risk_score = result.before_risk_score - result.risk_reduction;
   
   // Build description
   result.action_description = StringFormat("Close %s (%d positions, %.2f lots)",
                                           target_algo.name,
                                           target_algo.pos_count,
                                           target_algo.total_lots);
   
   // Impact summary
   string pl_text = (result.equity_change >= 0) ? "gain" : "loss";
   result.impact_summary = StringFormat("%.2f %s | Margin level: %.1f%% → %.1f%% | Risk: %.0f → %.0f",
                                       MathAbs(result.equity_change),
                                       pl_text,
                                       result.before_margin_level,
                                       result.after_margin_level,
                                       result.before_risk_score,
                                       result.after_risk_score);
   
   // Generate warnings
   result.warning_count = 0;
   
   if(target_algo.floating_pl < -100) {
      result.warnings[result.warning_count] = "Closing at significant loss";
      result.warning_count++;
   }
   
   if(target_algo.trades_closed >= 10 && target_algo.win_rate > 55) {
      result.warnings[result.warning_count] = "Algo has positive track record - consider keeping";
      result.warning_count++;
   }
   
   // Generate benefits
   result.benefit_count = 0;
   
   if(result.margin_level_change > 10) {
      result.benefits[result.benefit_count] = "Significantly improves margin level";
      result.benefit_count++;
   }
   
   if(result.risk_reduction > 10) {
      result.benefits[result.benefit_count] = "Reduces portfolio risk";
      result.benefit_count++;
   }
   
   if(target_algo.floating_pl < 0 && result.after_margin_level > result.before_margin_level) {
      result.benefits[result.benefit_count] = "Stops bleeding - cuts losing position";
      result.benefit_count++;
   }
   
   // Generate recommendation
   result.confidence_score = 50;
   
   if(target_algo.floating_pl < -500) {
      result.recommendation = "STRONGLY RECOMMEND CLOSING";
      result.recommendation_color = C'239,68,68';
      result.confidence_score = 85;
   } else if(target_algo.floating_pl < 0 && target_algo.trades_closed >= 10 && target_algo.profit_factor < 1.0) {
      result.recommendation = "RECOMMEND CLOSING - Poor performance";
      result.recommendation_color = C'251,191,36';
      result.confidence_score = 70;
   } else if(target_algo.floating_pl > 100 && target_algo.win_rate > 60) {
      result.recommendation = "DO NOT CLOSE - Strong performer";
      result.recommendation_color = C'34,197,94';
      result.confidence_score = 75;
   } else if(result.before_margin_level < 200 && result.margin_level_change > 20) {
      result.recommendation = "CONSIDER CLOSING - Margin relief needed";
      result.recommendation_color = C'251,191,36';
      result.confidence_score = 65;
   } else {
      result.recommendation = "NEUTRAL - Monitor situation";
      result.recommendation_color = C'59,130,246';
      result.confidence_score = 50;
   }
}

//+------------------------------------------------------------------+
//| Simulate Market Gap                                               |
//+------------------------------------------------------------------+
void SimulateMarketGap(ScenarioResult &result, double gap_pips,
                      AlgoMetrics &algos[], int algo_count,
                      PortfolioMetrics &current_portfolio) {
   
   ZeroMemory(result);
   
   // Capture before state
   result.before_equity = current_portfolio.equity;
   result.before_margin_level = current_portfolio.margin_level;
   result.before_floating_pl = current_portfolio.total_floating_pl;
   result.before_total_lots = current_portfolio.total_lots;
   result.before_position_count = current_portfolio.total_positions;
   
   // Calculate impact
   double pip_value = 10.0; // Simplified - assume $10/pip per lot
   double estimated_impact = 0;
   
   for(int i = 0; i < algo_count; i++) {
      // Long positions lose on gap down, gain on gap up
      double long_impact = algos[i].buy_lots * gap_pips * pip_value;
      // Short positions gain on gap down, lose on gap up
      double short_impact = algos[i].sell_lots * (-gap_pips) * pip_value;
      
      estimated_impact += long_impact + short_impact;
   }
   
   // After state
   result.after_equity = result.before_equity + estimated_impact;
   result.after_floating_pl = result.before_floating_pl + estimated_impact;
   result.after_total_lots = result.before_total_lots;
   result.after_position_count = result.before_position_count;
   
   // Margin level changes
   if(current_portfolio.margin_used > 0) {
      result.after_margin_level = (result.after_equity / current_portfolio.margin_used) * 100.0;
   } else {
      result.after_margin_level = result.before_margin_level;
   }
   
   // Calculate impacts
   result.equity_change = estimated_impact;
   result.margin_level_change = result.after_margin_level - result.before_margin_level;
   result.pl_change = estimated_impact;
   
   // Description
   string direction = (gap_pips > 0) ? "UP" : "DOWN";
   result.action_description = StringFormat("Market gaps %s by %.0f pips", direction, MathAbs(gap_pips));
   
   // Impact summary
   result.impact_summary = StringFormat("Estimated impact: $%.2f | New equity: $%.2f | Margin level: %.1f%%",
                                       estimated_impact,
                                       result.after_equity,
                                       result.after_margin_level);
   
   // Warnings
   result.warning_count = 0;
   
   if(result.after_margin_level < 150) {
      result.warnings[result.warning_count] = "CRITICAL: Margin call risk!";
      result.warning_count++;
   } else if(result.after_margin_level < 200) {
      result.warnings[result.warning_count] = "WARNING: Low margin level";
      result.warning_count++;
   }
   
   if(result.equity_change < -1000) {
      result.warnings[result.warning_count] = "Severe portfolio impact - hedge recommended";
      result.warning_count++;
   }
   
   // Recommendation
   if(result.after_margin_level < 150) {
      result.recommendation = "URGENT: Close positions or add funds";
      result.recommendation_color = C'220,38,38';
      result.confidence_score = 95;
   } else if(result.equity_change < -500) {
      result.recommendation = "HIGH RISK: Consider hedging exposure";
      result.recommendation_color = C'239,68,68';
      result.confidence_score = 80;
   } else if(result.equity_change > 500) {
      result.recommendation = "Favorable scenario - monitor for profit taking";
      result.recommendation_color = C'34,197,94';
      result.confidence_score = 70;
   } else {
      result.recommendation = "Manageable impact - continue monitoring";
      result.recommendation_color = C'59,130,246';
      result.confidence_score = 60;
   }
}

//+------------------------------------------------------------------+
//| Simulate Closing All Losing Positions                             |
//+------------------------------------------------------------------+
void SimulateCloseAllLosing(ScenarioResult &result,
                           AlgoMetrics &algos[], int algo_count,
                           PortfolioMetrics &current_portfolio) {
   
   ZeroMemory(result);
   
   // Capture before state
   result.before_equity = current_portfolio.equity;
   result.before_margin_level = current_portfolio.margin_level;
   result.before_floating_pl = current_portfolio.total_floating_pl;
   result.before_total_lots = current_portfolio.total_lots;
   result.before_position_count = current_portfolio.total_positions;
   
   // Calculate impact of closing all losing algos
   double total_loss_realized = 0;
   double lots_closed = 0;
   int positions_closed = 0;
   int algos_closed = 0;
   
   for(int i = 0; i < algo_count; i++) {
      if(algos[i].floating_pl < 0) {
         total_loss_realized += algos[i].floating_pl;
         lots_closed += algos[i].total_lots;
         positions_closed += algos[i].pos_count;
         algos_closed++;
      }
   }
   
   // After state
   result.after_equity = result.before_equity + total_loss_realized;
   result.after_floating_pl = result.before_floating_pl - total_loss_realized;
   result.after_total_lots = result.before_total_lots - lots_closed;
   result.after_position_count = result.before_position_count - positions_closed;
   
   // New margin level
   if(lots_closed > 0 && current_portfolio.margin_used > 0) {
      double closed_margin = current_portfolio.margin_used * (lots_closed / result.before_total_lots);
      double new_margin_used = current_portfolio.margin_used - closed_margin;
      
      if(new_margin_used > 0) {
         result.after_margin_level = (result.after_equity / new_margin_used) * 100.0;
      } else {
         result.after_margin_level = 0;
      }
   } else {
      result.after_margin_level = result.before_margin_level;
   }
   
   // Impacts
   result.equity_change = total_loss_realized;
   result.margin_level_change = result.after_margin_level - result.before_margin_level;
   result.pl_change = total_loss_realized;
   result.lots_change = -lots_closed;
   result.positions_closed = positions_closed;
   
   // Description
   result.action_description = StringFormat("Close ALL losing positions (%d algos, %d positions, %.2f lots)",
                                           algos_closed, positions_closed, lots_closed);
   
   result.impact_summary = StringFormat("Total loss: $%.2f | Margin: %.1f%% → %.1f%% | Positions: %d → %d",
                                       MathAbs(total_loss_realized),
                                       result.before_margin_level,
                                       result.after_margin_level,
                                       result.before_position_count,
                                       result.after_position_count);
   
   // Warnings
   result.warning_count = 0;
   
   if(MathAbs(total_loss_realized) > 1000) {
      result.warnings[result.warning_count] = "Large realized loss - significant equity hit";
      result.warning_count++;
   }
   
   if(positions_closed > result.before_position_count * 0.5) {
      result.warnings[result.warning_count] = "Closes majority of portfolio - reduces diversification";
      result.warning_count++;
   }
   
   // Benefits
   result.benefit_count = 0;
   
   result.benefits[result.benefit_count] = "Stops all ongoing losses immediately";
   result.benefit_count++;
   
   if(result.margin_level_change > 20) {
      result.benefits[result.benefit_count] = "Significantly improves margin safety";
      result.benefit_count++;
   }
   
   // Recommendation
   if(result.before_margin_level < 200 && result.margin_level_change > 30) {
      result.recommendation = "STRONGLY RECOMMEND - Margin relief critical";
      result.recommendation_color = C'239,68,68';
      result.confidence_score = 85;
   } else if(MathAbs(total_loss_realized) > 500) {
      result.recommendation = "CAUTION - Large loss but may prevent further bleeding";
      result.recommendation_color = C'251,191,36';
      result.confidence_score = 65;
   } else {
      result.recommendation = "CONSIDER - Clean slate approach";
      result.recommendation_color = C'59,130,246';
      result.confidence_score = 60;
   }
}

//+------------------------------------------------------------------+
//| Simulate Reducing Position Sizes                                  |
//+------------------------------------------------------------------+
void SimulateReduceSize(ScenarioResult &result, double reduction_pct,
                       AlgoMetrics &algos[], int algo_count,
                       PortfolioMetrics &current_portfolio) {
   
   ZeroMemory(result);
   
   // Capture before state
   result.before_equity = current_portfolio.equity;
   result.before_margin_level = current_portfolio.margin_level;
   result.before_floating_pl = current_portfolio.total_floating_pl;
   result.before_total_lots = current_portfolio.total_lots;
   result.before_position_count = current_portfolio.total_positions;
   
   // Calculate reduction impact
   double reduction_factor = reduction_pct / 100.0;
   double pl_realized = current_portfolio.total_floating_pl * reduction_factor;
   double lots_reduced = current_portfolio.total_lots * reduction_factor;
   
   // After state
   result.after_equity = result.before_equity + pl_realized;
   result.after_floating_pl = result.before_floating_pl * (1.0 - reduction_factor);
   result.after_total_lots = result.before_total_lots * (1.0 - reduction_factor);
   result.after_position_count = result.before_position_count; // Still have positions, just smaller
   
   // New margin
   double new_margin_used = current_portfolio.margin_used * (1.0 - reduction_factor);
   if(new_margin_used > 0) {
      result.after_margin_level = (result.after_equity / new_margin_used) * 100.0;
   } else {
      result.after_margin_level = result.before_margin_level;
   }
   
   // Impacts
   result.equity_change = pl_realized;
   result.margin_level_change = result.after_margin_level - result.before_margin_level;
   result.pl_change = pl_realized;
   result.lots_change = -lots_reduced;
   result.risk_reduction = reduction_pct * 0.3; // Simplified risk reduction
   
   // Description
   result.action_description = StringFormat("Reduce ALL position sizes by %.0f%%", reduction_pct);
   
   result.impact_summary = StringFormat("Realize $%.2f | Lots: %.2f → %.2f | Margin: %.1f%% → %.1f%%",
                                       pl_realized,
                                       result.before_total_lots,
                                       result.after_total_lots,
                                       result.before_margin_level,
                                       result.after_margin_level);
   
   // Benefits
   result.benefit_count = 0;
   
   result.benefits[result.benefit_count] = StringFormat("Reduces risk exposure by %.0f%%", reduction_pct);
   result.benefit_count++;
   
   result.benefits[result.benefit_count] = "Keeps all strategies active - just smaller";
   result.benefit_count++;
   
   if(result.margin_level_change > 15) {
      result.benefits[result.benefit_count] = "Improves margin safety cushion";
      result.benefit_count++;
   }
   
   // Recommendation
   result.recommendation = "BALANCED APPROACH - Reduces risk while maintaining strategies";
   result.recommendation_color = C'59,130,246';
   result.confidence_score = 70;
}

//+------------------------------------------------------------------+

#endif // MODULE_SCENARIO_SIMULATOR_MQH
