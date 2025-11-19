//+------------------------------------------------------------------+
//|                                        Core_DataStructures.mqh   |
//|                                     Portfolio Command Center     |
//|                                All Data Structure Definitions    |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "5.00"
#property strict

#ifndef CORE_DATA_STRUCTURES_MQH
#define CORE_DATA_STRUCTURES_MQH

//+------------------------------------------------------------------+
//| Algo Performance Metrics                                          |
//+------------------------------------------------------------------+
struct AlgoMetrics {
   long magic;
   string name;
   bool is_manual;
   
   // Positions
   int pos_count;
   int buy_count;
   int sell_count;
   double total_lots;
   double buy_lots;
   double sell_lots;
   
   // P&L
   double floating_pl;
   double realized_pl;
   double total_pl;
   
   // Symbols
   string symbols[20];
   double symbol_lots[20];
   double symbol_pct[20];
   int symbol_count;
   string top_symbol;
   double top_symbol_pct;
   
   // Performance (30 days)
   int trades_closed;
   int wins;
   int losses;
   double win_rate;
   double profit_factor;
   double avg_win;
   double avg_loss;
   double expectancy;
   double largest_win;
   double largest_loss;
   
   // Risk
   double sharpe_ratio;
   double max_dd_pct;
   double current_dd_pct;
   
   // Time Analysis
   datetime oldest_position;
   datetime newest_position;
   double avg_duration_hours;
   int best_hour;
   int worst_hour;
   double best_hour_pl;
   double worst_hour_pl;
   
   // Scoring
   double performance_score;  // 0-100
   string status;
   color status_color;
   
   // Flags
   bool is_profitable;
   bool has_critical_issues;
   bool has_warnings;
   bool is_overexposed;
   bool is_correlated;
   bool against_trend;
   
   // Intelligence
   string primary_issue;
   string recommendation;
   double recovery_target;
   int priority_to_close;  // 1=close first, 5=keep
};

//+------------------------------------------------------------------+
//| Portfolio Aggregate Metrics                                       |
//+------------------------------------------------------------------+
struct PortfolioMetrics {
   // Overview
   int total_algos;
   int active_algos;
   int total_positions;
   double total_lots;
   double total_floating_pl;
   double total_realized_pl;
   
   // Account
   double balance;
   double equity;
   double margin_used;
   double margin_free;
   double margin_level;
   double drawdown_pct;
   
   // Stats
   int total_buy;
   int total_sell;
   string best_algo;
   double best_pl;
   string worst_algo;
   double worst_pl;
   
   // Risk
   int critical_count;
   int warning_count;
   double max_risk_exposure;
   double correlation_risk;
   
   // Health
   double health_score;  // 0-100
   double diversification_score;
   double risk_score;
   double performance_score;
   double alignment_score;
};

//+------------------------------------------------------------------+
//| Market Condition Analysis                                         |
//+------------------------------------------------------------------+
struct MarketConditions {
   string trend_direction;      // UP, DOWN, RANGE
   double trend_strength;        // 0-100
   string volatility;           // LOW, MEDIUM, HIGH
   double atr_change_pct;       // vs average
   string best_strategy_type;   // TREND, RANGE, BREAKOUT
   string worst_strategy_type;
   double market_efficiency;    // 0-100
};

//+------------------------------------------------------------------+
//| Trade Recommendations                                             |
//+------------------------------------------------------------------+
struct TradeRecommendation {
   string action;              // HEDGE, CLOSE, DIVERSIFY, WAIT
   string symbol;
   string direction;           // BUY, SELL
   double size;
   string reason;
   double expected_benefit;
   int priority;              // 1=urgent, 5=optional
   color action_color;
};

//+------------------------------------------------------------------+
//| Recovery Strategy Plans                                           |
//+------------------------------------------------------------------+
struct RecoveryPlan {
   long target_magic;
   string algo_name;
   double current_loss;
   double breakeven_target;
   string strategies[5];
   int strategy_count;
   string expected_timeframe;
   double risk_reduction_pct;
};

//+------------------------------------------------------------------+
//| UI State Management                                               |
//+------------------------------------------------------------------+
struct UIState {
   bool minimized;
   bool show_help;
   int font_base;
   int font_header;
   int font_large;
   int font_mega;
   string status_msg;
   int active_tab;           // 0=overview, 1=recommendations, 2=analysis
   int expanded_algo;
   datetime last_render;
   
   // Module states
   bool module_risk_active;
   bool module_scenario_active;
   bool module_visual_active;
   bool module_time_active;
   bool module_efficiency_active;
   bool module_regime_active;
   bool module_predictive_active;
   bool module_benchmark_active;
   bool module_alerts_active;
   bool module_optimizer_active;
};

//+------------------------------------------------------------------+
//| Feature Module State                                              |
//+------------------------------------------------------------------+
struct FeatureModule {
   string name;
   string display_name;
   bool is_active;
   bool is_minimized;
   long chart_id;           // Chart window ID where module is attached
   color button_color;
   string description;
};

//+------------------------------------------------------------------+

#endif // CORE_DATA_STRUCTURES_MQH
