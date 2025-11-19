//+------------------------------------------------------------------+
//|                              Module_SmartAlerts.mqh              |
//|                      SMART ALERTS & MONITORING                   |
//|                  Proactive Risk & Performance Alerts             |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_SMART_ALERTS_MQH
#define MODULE_SMART_ALERTS_MQH

// Include required structures
#include "Core_DataStructures.mqh"
#include "Module_AdvancedRisk.mqh"

//+------------------------------------------------------------------+
//| Alert Priority Levels                                             |
//+------------------------------------------------------------------+
enum ALERT_PRIORITY {
   PRIORITY_INFO,      // Informational
   PRIORITY_WARNING,   // Warning - attention needed
   PRIORITY_CRITICAL   // Critical - immediate action required
};

//+------------------------------------------------------------------+
//| Alert Types                                                       |
//+------------------------------------------------------------------+
enum ALERT_TYPE {
   ALERT_MARGIN_LOW,           // Margin level below threshold
   ALERT_MARGIN_CRITICAL,      // Margin level critically low
   ALERT_DRAWDOWN_HIGH,        // Drawdown exceeded threshold
   ALERT_DRAWDOWN_RECORD,      // New record drawdown
   ALERT_EXPOSURE_HIGH,        // Portfolio exposure too high
   ALERT_WIN_STREAK,           // Consecutive wins
   ALERT_LOSS_STREAK,          // Consecutive losses
   ALERT_DAILY_LOSS_LIMIT,     // Daily loss limit reached
   ALERT_PROFIT_TARGET,        // Profit target achieved
   ALERT_CORRELATION_HIGH,     // High correlation detected
   ALERT_ALGO_STOPPED,         // Algorithm stopped trading
   ALERT_UNUSUAL_ACTIVITY      // Unusual trading activity
};

//+------------------------------------------------------------------+
//| Alert Structure                                                   |
//+------------------------------------------------------------------+
struct AlertItem {
   ALERT_TYPE type;
   ALERT_PRIORITY priority;
   datetime timestamp;
   string message;
   string details;
   double value;
   double threshold;
   bool is_active;
   bool acknowledged;
   color alert_color;
};

//+------------------------------------------------------------------+
//| Alert Configuration                                               |
//+------------------------------------------------------------------+
struct AlertConfig {
   // Margin alerts
   bool enable_margin_alerts;
   double margin_warning_level;      // e.g., 200%
   double margin_critical_level;     // e.g., 150%
   
   // Drawdown alerts
   bool enable_drawdown_alerts;
   double max_drawdown_warning;      // e.g., 10%
   double max_drawdown_critical;     // e.g., 15%
   
   // Exposure alerts
   bool enable_exposure_alerts;
   double max_exposure_pct;          // e.g., 5% of equity per position
   
   // Streak alerts
   bool enable_streak_alerts;
   int win_streak_threshold;         // e.g., 5 consecutive wins
   int loss_streak_threshold;        // e.g., 3 consecutive losses
   
   // Daily limits
   bool enable_daily_limits;
   double daily_loss_limit;          // e.g., -$500
   double daily_profit_target;       // e.g., +$1000
   
   // Correlation alerts
   bool enable_correlation_alerts;
   double high_correlation_threshold; // e.g., 0.8
   
   // Sound/popup
   bool enable_sound;
   bool enable_popup;
   bool enable_email;
};

//+------------------------------------------------------------------+
//| Alert Monitor Data                                                |
//+------------------------------------------------------------------+
struct AlertMonitorData {
   AlertItem active_alerts[50];
   int active_count;
   
   AlertItem alert_history[100];
   int history_count;
   
   // Monitoring state
   int current_win_streak;
   int current_loss_streak;
   int max_win_streak_today;
   int max_loss_streak_today;
   
   datetime last_trade_time;
   double daily_starting_balance;
   double daily_pl;
   
   datetime session_start;
   int total_alerts_today;
   int critical_alerts_today;
   
   // Statistics
   double avg_time_to_acknowledge;
   int alerts_triggered_today;
   int most_common_alert_type;
};

// Global configuration
AlertConfig g_alert_config;

//+------------------------------------------------------------------+
//| Initialize Alert Configuration with Defaults                     |
//+------------------------------------------------------------------+
void InitializeAlertConfig() {
   g_alert_config.enable_margin_alerts = true;
   g_alert_config.margin_warning_level = 300.0;
   g_alert_config.margin_critical_level = 200.0;
   
   g_alert_config.enable_drawdown_alerts = true;
   g_alert_config.max_drawdown_warning = 10.0;
   g_alert_config.max_drawdown_critical = 15.0;
   
   g_alert_config.enable_exposure_alerts = true;
   g_alert_config.max_exposure_pct = 5.0;
   
   g_alert_config.enable_streak_alerts = true;
   g_alert_config.win_streak_threshold = 5;
   g_alert_config.loss_streak_threshold = 3;
   
   g_alert_config.enable_daily_limits = true;
   g_alert_config.daily_loss_limit = -500.0;
   g_alert_config.daily_profit_target = 1000.0;
   
   g_alert_config.enable_correlation_alerts = true;
   g_alert_config.high_correlation_threshold = 0.8;
   
   g_alert_config.enable_sound = true;
   g_alert_config.enable_popup = false;
   g_alert_config.enable_email = false;
}

//+------------------------------------------------------------------+
//| Add Alert to System                                               |
//+------------------------------------------------------------------+
void AddAlert(AlertMonitorData &data, ALERT_TYPE type, ALERT_PRIORITY priority,
              string message, string details, double value, double threshold) {
   
   // Check if similar alert already active
   for(int i = 0; i < data.active_count; i++) {
      if(data.active_alerts[i].type == type && data.active_alerts[i].is_active) {
         return; // Don't duplicate
      }
   }
   
   if(data.active_count >= 50) {
      // Remove oldest acknowledged alert
      for(int i = 0; i < data.active_count; i++) {
         if(data.active_alerts[i].acknowledged) {
            // Shift array
            for(int j = i; j < data.active_count - 1; j++) {
               data.active_alerts[j] = data.active_alerts[j + 1];
            }
            data.active_count--;
            break;
         }
      }
   }
   
   if(data.active_count < 50) {
      AlertItem alert;
      alert.type = type;
      alert.priority = priority;
      alert.timestamp = TimeCurrent();
      alert.message = message;
      alert.details = details;
      alert.value = value;
      alert.threshold = threshold;
      alert.is_active = true;
      alert.acknowledged = false;
      
      // Set color based on priority
      switch(priority) {
         case PRIORITY_INFO:
            alert.alert_color = C'59,130,246'; // Blue
            break;
         case PRIORITY_WARNING:
            alert.alert_color = C'251,191,36'; // Orange
            break;
         case PRIORITY_CRITICAL:
            alert.alert_color = C'239,68,68'; // Red
            break;
      }
      
      data.active_alerts[data.active_count] = alert;
      data.active_count++;
      
      data.alerts_triggered_today++;
      if(priority == PRIORITY_CRITICAL) {
         data.critical_alerts_today++;
      }
      
      // Trigger notification
      if(g_alert_config.enable_sound) {
         if(priority == PRIORITY_CRITICAL) {
            Alert("CRITICAL: " + message);
         }
      }
      
      if(g_alert_config.enable_popup) {
         MessageBox(message + "\n" + details, "Trading Alert", MB_OK | MB_ICONWARNING);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Margin Alerts                                               |
//+------------------------------------------------------------------+
void CheckMarginAlerts(AlertMonitorData &data, PortfolioMetrics &portfolioData) {
   if(!g_alert_config.enable_margin_alerts) return;
   
   if(portfolioData.margin_level < g_alert_config.margin_critical_level) {
      AddAlert(data, ALERT_MARGIN_CRITICAL, PRIORITY_CRITICAL,
              "MARGIN LEVEL CRITICAL",
              StringFormat("Margin: %.0f%% | Critical Level: %.0f%%",
                          portfolioData.margin_level, g_alert_config.margin_critical_level),
              portfolioData.margin_level, g_alert_config.margin_critical_level);
   }
   else if(portfolioData.margin_level < g_alert_config.margin_warning_level) {
      AddAlert(data, ALERT_MARGIN_LOW, PRIORITY_WARNING,
              "Low Margin Level",
              StringFormat("Margin: %.0f%% | Warning Level: %.0f%%",
                          portfolioData.margin_level, g_alert_config.margin_warning_level),
              portfolioData.margin_level, g_alert_config.margin_warning_level);
   }
}

//+------------------------------------------------------------------+
//| Check Drawdown Alerts                                             |
//+------------------------------------------------------------------+
void CheckDrawdownAlerts(AlertMonitorData &data, AdvancedRiskMetrics &riskData) {
   if(!g_alert_config.enable_drawdown_alerts) return;
   
   if(riskData.current_dd > g_alert_config.max_drawdown_critical) {
      AddAlert(data, ALERT_DRAWDOWN_HIGH, PRIORITY_CRITICAL,
              "CRITICAL DRAWDOWN",
              StringFormat("Current DD: %.2f%% | Critical: %.2f%%",
                          riskData.current_dd, g_alert_config.max_drawdown_critical),
              riskData.current_dd, g_alert_config.max_drawdown_critical);
   }
   else if(riskData.current_dd > g_alert_config.max_drawdown_warning) {
      AddAlert(data, ALERT_DRAWDOWN_HIGH, PRIORITY_WARNING,
              "High Drawdown",
              StringFormat("Current DD: %.2f%% | Warning: %.2f%%",
                          riskData.current_dd, g_alert_config.max_drawdown_warning),
              riskData.current_dd, g_alert_config.max_drawdown_warning);
   }
   
   // Check for record drawdown
   if(riskData.current_dd > riskData.max_dd * 0.95) {
      AddAlert(data, ALERT_DRAWDOWN_RECORD, PRIORITY_WARNING,
              "Near Record Drawdown",
              StringFormat("Current: %.2f%% | Record: %.2f%%",
                          riskData.current_dd, riskData.max_dd),
              riskData.current_dd, riskData.max_dd);
   }
}

//+------------------------------------------------------------------+
//| Check Exposure Alerts                                             |
//+------------------------------------------------------------------+
void CheckExposureAlerts(AlertMonitorData &data, AlgoMetrics &algoList[], int algoCount) {
   if(!g_alert_config.enable_exposure_alerts) return;
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0) return;
   
   for(int i = 0; i < algoCount; i++) {
      // Calculate exposure as percentage of equity
      // Using absolute floating P/L as proxy for exposure value
      double exposure_value = MathAbs(algoList[i].floating_pl);
      double exposure_pct = (exposure_value / equity) * 100.0;
      
      if(exposure_pct > g_alert_config.max_exposure_pct) {
         AddAlert(data, ALERT_EXPOSURE_HIGH, PRIORITY_WARNING,
                 "High Position Exposure",
                 StringFormat("%s: %.2f%% | Max: %.2f%%",
                             algoList[i].name, exposure_pct, g_alert_config.max_exposure_pct),
                 exposure_pct, g_alert_config.max_exposure_pct);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Streak Alerts                                               |
//+------------------------------------------------------------------+
void CheckStreakAlerts(AlertMonitorData &data) {
   if(!g_alert_config.enable_streak_alerts) return;
   
   // Check win streak
   if(data.current_win_streak >= g_alert_config.win_streak_threshold) {
      AddAlert(data, ALERT_WIN_STREAK, PRIORITY_INFO,
              "Win Streak Detected",
              StringFormat("%d consecutive winning trades", data.current_win_streak),
              data.current_win_streak, g_alert_config.win_streak_threshold);
   }
   
   // Check loss streak
   if(data.current_loss_streak >= g_alert_config.loss_streak_threshold) {
      AddAlert(data, ALERT_LOSS_STREAK, PRIORITY_WARNING,
              "Loss Streak Alert",
              StringFormat("%d consecutive losing trades", data.current_loss_streak),
              data.current_loss_streak, g_alert_config.loss_streak_threshold);
   }
}

//+------------------------------------------------------------------+
//| Check Daily Limit Alerts                                          |
//+------------------------------------------------------------------+
void CheckDailyLimitAlerts(AlertMonitorData &data, PortfolioMetrics &portfolioData) {
   if(!g_alert_config.enable_daily_limits) return;
   
   // Calculate daily P&L from current equity vs starting balance
   data.daily_pl = portfolioData.equity - data.daily_starting_balance;
   
   // Check loss limit
   if(data.daily_pl < g_alert_config.daily_loss_limit) {
      AddAlert(data, ALERT_DAILY_LOSS_LIMIT, PRIORITY_CRITICAL,
              "DAILY LOSS LIMIT REACHED",
              StringFormat("Daily P&L: $%.2f | Limit: $%.2f",
                          data.daily_pl, g_alert_config.daily_loss_limit),
              data.daily_pl, g_alert_config.daily_loss_limit);
   }
   
   // Check profit target
   if(data.daily_pl > g_alert_config.daily_profit_target) {
      AddAlert(data, ALERT_PROFIT_TARGET, PRIORITY_INFO,
              "Daily Profit Target Achieved!",
              StringFormat("Daily P&L: $%.2f | Target: $%.2f",
                          data.daily_pl, g_alert_config.daily_profit_target),
              data.daily_pl, g_alert_config.daily_profit_target);
   }
}

//+------------------------------------------------------------------+
//| Update Streak Tracking                                            |
//+------------------------------------------------------------------+
void UpdateStreakTracking(AlertMonitorData &data) {
   // Check recent history for streaks
   if(!HistorySelect(TimeCurrent() - 86400, TimeCurrent())) return;
   
   int deals = HistoryDealsTotal();
   if(deals == 0) return;
   
   int current_streak = 0;
   bool is_win_streak = true;
   bool first_deal = true;
   
   for(int i = deals - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         
         if(first_deal) {
            is_win_streak = (profit > 0);
            current_streak = 1;
            first_deal = false;
         } else {
            if((is_win_streak && profit > 0) || (!is_win_streak && profit < 0)) {
               current_streak++;
            } else {
               break;
            }
         }
      }
   }
   
   if(is_win_streak) {
      data.current_win_streak = current_streak;
      data.current_loss_streak = 0;
      if(current_streak > data.max_win_streak_today) {
         data.max_win_streak_today = current_streak;
      }
   } else {
      data.current_loss_streak = current_streak;
      data.current_win_streak = 0;
      if(current_streak > data.max_loss_streak_today) {
         data.max_loss_streak_today = current_streak;
      }
   }
}

//+------------------------------------------------------------------+
//| Main Alert Monitoring Function                                    |
//+------------------------------------------------------------------+
void MonitorAlerts(AlertMonitorData &data, 
                   AlgoMetrics &algoList[], 
                   int algoCount,
                   PortfolioMetrics &portfolioData,
                   AdvancedRiskMetrics &riskData) {
   
   // Reset daily counters if new day
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour == 0 && dt.min == 0) {
      data.daily_starting_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      data.total_alerts_today = 0;
      data.critical_alerts_today = 0;
      data.max_win_streak_today = 0;
      data.max_loss_streak_today = 0;
   }
   
   // Update streak tracking
   UpdateStreakTracking(data);
   
   // Run all alert checks
   CheckMarginAlerts(data, portfolioData);
   CheckDrawdownAlerts(data, riskData);
   CheckExposureAlerts(data, algoList, algoCount);
   CheckStreakAlerts(data);
   CheckDailyLimitAlerts(data, portfolioData);
   
   // Auto-clear resolved alerts
   for(int i = 0; i < data.active_count; i++) {
      if(data.active_alerts[i].is_active && !data.active_alerts[i].acknowledged) {
         // Check if condition resolved
         bool should_clear = false;
         
         switch(data.active_alerts[i].type) {
            case ALERT_MARGIN_LOW:
            case ALERT_MARGIN_CRITICAL:
               if(portfolioData.margin_level > data.active_alerts[i].threshold + 50) {
                  should_clear = true;
               }
               break;
               
            case ALERT_DRAWDOWN_HIGH:
               if(riskData.current_dd < data.active_alerts[i].threshold - 2) {
                  should_clear = true;
               }
               break;
         }
         
         if(should_clear) {
            data.active_alerts[i].is_active = false;
            data.active_alerts[i].acknowledged = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Acknowledge Alert                                                 |
//+------------------------------------------------------------------+
void AcknowledgeAlert(AlertMonitorData &data, int index) {
   if(index >= 0 && index < data.active_count) {
      data.active_alerts[index].acknowledged = true;
      data.active_alerts[index].is_active = false;
   }
}

//+------------------------------------------------------------------+
//| Clear All Acknowledged Alerts                                     |
//+------------------------------------------------------------------+
void ClearAcknowledgedAlerts(AlertMonitorData &data) {
   int new_count = 0;
   for(int i = 0; i < data.active_count; i++) {
      if(!data.active_alerts[i].acknowledged) {
         data.active_alerts[new_count] = data.active_alerts[i];
         new_count++;
      }
   }
   data.active_count = new_count;
}

//+------------------------------------------------------------------+

#endif // MODULE_SMART_ALERTS_MQH
