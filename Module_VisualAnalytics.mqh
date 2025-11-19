//+------------------------------------------------------------------+
//|                              Module_VisualAnalytics.mqh          |
//|                        VISUAL ANALYTICS ENGINE                   |
//|                  Chart & Graph Data Generation                   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_VISUAL_ANALYTICS_MQH
#define MODULE_VISUAL_ANALYTICS_MQH

#include "Core_DataStructures.mqh"

//+------------------------------------------------------------------+
//| Equity Curve Data Structure                                       |
//+------------------------------------------------------------------+
struct EquityCurvePoint {
   datetime time;
   double equity;
   double drawdown_pct;
   bool is_underwater;
};

//+------------------------------------------------------------------+
//| Performance Heatmap Data                                          |
//+------------------------------------------------------------------+
struct HeatmapCell {
   int day;
   int week;
   double return_pct;
   color cell_color;
   string tooltip;
};

//+------------------------------------------------------------------+
//| Distribution Bucket                                               |
//+------------------------------------------------------------------+
struct DistributionBucket {
   double min_value;
   double max_value;
   int count;
   double percentage;
   string label;
};

//+------------------------------------------------------------------+
//| Monthly Performance                                               |
//+------------------------------------------------------------------+
struct MonthlyPerformance {
   int year;
   int month;
   double return_pct;
   int trades;
   double win_rate;
   color cell_color;
};

//+------------------------------------------------------------------+
//| Visual Analytics Data                                             |
//+------------------------------------------------------------------+
struct VisualAnalyticsData {
   // Equity curve
   EquityCurvePoint equity_curve[];
   int equity_points;
   double max_equity;
   double min_equity;
   double current_equity;
   
   // Performance heatmap (last 90 days)
   HeatmapCell heatmap[];
   int heatmap_cells;
   double best_day_pct;
   double worst_day_pct;
   
   // Win/Loss distribution
   DistributionBucket win_distribution[10];
   DistributionBucket loss_distribution[10];
   int total_wins;
   int total_losses;
   double avg_win;
   double avg_loss;
   
   // Monthly performance (last 12 months)
   MonthlyPerformance monthly[12];
   int months_count;
   double best_month_pct;
   double worst_month_pct;
   double ytd_return;
};

//+------------------------------------------------------------------+
//| Generate Equity Curve Data                                        |
//+------------------------------------------------------------------+
void GenerateEquityCurve(VisualAnalyticsData &data, int days_back = 90) {
   // Collect historical equity data
   datetime now = TimeCurrent();
   datetime start = now - (days_back * 86400);
   
   // Get account history
   if(!HistorySelect(start, now)) {
      data.equity_points = 0;
      return;
   }
   
   // Temporary arrays for daily aggregation
   datetime daily_times[];
   double daily_equity[];
   ArrayResize(daily_times, days_back);
   ArrayResize(daily_equity, days_back);
   
   double starting_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double current_equity = starting_balance;
   double peak_equity = starting_balance;
   
   // Process deals to build equity curve
   int point_count = 0;
   int deals_total = HistoryDealsTotal();
   
   // Simplified: Use closed trades to estimate equity curve
   for(int i = 0; i < deals_total; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         
         current_equity += profit;
         
         if(point_count < days_back) {
            daily_times[point_count] = deal_time;
            daily_equity[point_count] = current_equity;
            point_count++;
         }
      }
   }
   
   // Build equity curve with drawdown calculation
   ArrayResize(data.equity_curve, point_count);
   data.equity_points = point_count;
   
   peak_equity = starting_balance;
   data.max_equity = starting_balance;
   data.min_equity = starting_balance;
   
   for(int i = 0; i < point_count; i++) {
      data.equity_curve[i].time = daily_times[i];
      data.equity_curve[i].equity = daily_equity[i];
      
      // Update peak
      if(daily_equity[i] > peak_equity) {
         peak_equity = daily_equity[i];
      }
      
      // Calculate drawdown
      double dd = 0;
      if(peak_equity > 0) {
         dd = ((peak_equity - daily_equity[i]) / peak_equity) * 100.0;
      }
      data.equity_curve[i].drawdown_pct = dd;
      data.equity_curve[i].is_underwater = (dd > 0.5);
      
      // Track min/max
      if(daily_equity[i] > data.max_equity) data.max_equity = daily_equity[i];
      if(daily_equity[i] < data.min_equity) data.min_equity = daily_equity[i];
   }
   
   data.current_equity = (point_count > 0) ? daily_equity[point_count-1] : starting_balance;
}

//+------------------------------------------------------------------+
//| Generate Performance Heatmap                                      |
//+------------------------------------------------------------------+
void GeneratePerformanceHeatmap(VisualAnalyticsData &data, int days_back = 90) {
   datetime now = TimeCurrent();
   datetime start = now - (days_back * 86400);
   
   // Daily returns array
   double daily_returns[];
   datetime daily_dates[];
   ArrayResize(daily_returns, days_back);
   ArrayResize(daily_dates, days_back);
   
   // Initialize
   for(int i = 0; i < days_back; i++) {
      daily_returns[i] = 0;
      daily_dates[i] = start + (i * 86400);
   }
   
   // Collect deals and aggregate by day
   if(HistorySelect(start, now)) {
      int deals_total = HistoryDealsTotal();
      
      for(int i = 0; i < deals_total; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket <= 0) continue;
         
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            
            // Find day index
            int day_idx = (int)((deal_time - start) / 86400);
            if(day_idx >= 0 && day_idx < days_back) {
               daily_returns[day_idx] += profit;
            }
         }
      }
   }
   
   // Convert to percentage and create heatmap cells
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   int cell_count = 0;
   data.best_day_pct = -999999;
   data.worst_day_pct = 999999;
   
   ArrayResize(data.heatmap, days_back);
   
   for(int i = 0; i < days_back; i++) {
      double ret_pct = (balance > 0) ? (daily_returns[i] / balance) * 100.0 : 0;
      
      MqlDateTime dt;
      TimeToStruct(daily_dates[i], dt);
      
      data.heatmap[cell_count].day = dt.day_of_week;
      data.heatmap[cell_count].week = i / 7;
      data.heatmap[cell_count].return_pct = ret_pct;
      
      // Color coding
      if(ret_pct > 2.0) {
         data.heatmap[cell_count].cell_color = C'34,139,34';  // Dark green
      } else if(ret_pct > 0.5) {
         data.heatmap[cell_count].cell_color = C'50,205,50';  // Green
      } else if(ret_pct > 0) {
         data.heatmap[cell_count].cell_color = C'144,238,144'; // Light green
      } else if(ret_pct > -0.5) {
         data.heatmap[cell_count].cell_color = C'255,182,193'; // Light red
      } else if(ret_pct > -2.0) {
         data.heatmap[cell_count].cell_color = C'255,69,0';    // Red
      } else {
         data.heatmap[cell_count].cell_color = C'139,0,0';     // Dark red
      }
      
      data.heatmap[cell_count].tooltip = StringFormat("%s: %.2f%%", 
                                         TimeToString(daily_dates[i], TIME_DATE),
                                         ret_pct);
      
      if(ret_pct > data.best_day_pct) data.best_day_pct = ret_pct;
      if(ret_pct < data.worst_day_pct) data.worst_day_pct = ret_pct;
      
      cell_count++;
   }
   
   data.heatmap_cells = cell_count;
}

//+------------------------------------------------------------------+
//| Generate Win/Loss Distribution                                    |
//+------------------------------------------------------------------+
void GenerateWinLossDistribution(VisualAnalyticsData &data, int days_back = 90) {
   datetime now = TimeCurrent();
   datetime start = now - (days_back * 86400);
   
   double wins[];
   double losses[];
   ArrayResize(wins, 1000);
   ArrayResize(losses, 1000);
   
   int win_count = 0;
   int loss_count = 0;
   double win_sum = 0;
   double loss_sum = 0;
   
   // Collect all closed trades
   if(HistorySelect(start, now)) {
      int deals_total = HistoryDealsTotal();
      
      for(int i = 0; i < deals_total; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket <= 0) continue;
         
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            
            if(profit > 0) {
               if(win_count < 1000) {
                  wins[win_count] = profit;
                  win_sum += profit;
                  win_count++;
               }
            } else if(profit < 0) {
               if(loss_count < 1000) {
                  losses[loss_count] = MathAbs(profit);
                  loss_sum += MathAbs(profit);
                  loss_count++;
               }
            }
         }
      }
   }
   
   data.total_wins = win_count;
   data.total_losses = loss_count;
   data.avg_win = (win_count > 0) ? win_sum / win_count : 0;
   data.avg_loss = (loss_count > 0) ? loss_sum / loss_count : 0;
   
   // Create distribution buckets for wins
   double max_win = 0;
   for(int i = 0; i < win_count; i++) {
      if(wins[i] > max_win) max_win = wins[i];
   }
   
   double win_bucket_size = (max_win > 0) ? max_win / 10.0 : 1.0;
   
   for(int b = 0; b < 10; b++) {
      data.win_distribution[b].min_value = b * win_bucket_size;
      data.win_distribution[b].max_value = (b + 1) * win_bucket_size;
      data.win_distribution[b].count = 0;
      data.win_distribution[b].percentage = 0;
      data.win_distribution[b].label = StringFormat("$%.0f-%.0f", 
                                       data.win_distribution[b].min_value,
                                       data.win_distribution[b].max_value);
   }
   
   // Count wins in buckets
   for(int i = 0; i < win_count; i++) {
      int bucket = (int)(wins[i] / win_bucket_size);
      if(bucket >= 10) bucket = 9;
      data.win_distribution[bucket].count++;
   }
   
   // Calculate percentages
   for(int b = 0; b < 10; b++) {
      data.win_distribution[b].percentage = (win_count > 0) ? 
         ((double)data.win_distribution[b].count / win_count) * 100.0 : 0;
   }
   
   // Same for losses
   double max_loss = 0;
   for(int i = 0; i < loss_count; i++) {
      if(losses[i] > max_loss) max_loss = losses[i];
   }
   
   double loss_bucket_size = (max_loss > 0) ? max_loss / 10.0 : 1.0;
   
   for(int b = 0; b < 10; b++) {
      data.loss_distribution[b].min_value = b * loss_bucket_size;
      data.loss_distribution[b].max_value = (b + 1) * loss_bucket_size;
      data.loss_distribution[b].count = 0;
      data.loss_distribution[b].percentage = 0;
      data.loss_distribution[b].label = StringFormat("$%.0f-%.0f",
                                        data.loss_distribution[b].min_value,
                                        data.loss_distribution[b].max_value);
   }
   
   for(int i = 0; i < loss_count; i++) {
      int bucket = (int)(losses[i] / loss_bucket_size);
      if(bucket >= 10) bucket = 9;
      data.loss_distribution[bucket].count++;
   }
   
   for(int b = 0; b < 10; b++) {
      data.loss_distribution[b].percentage = (loss_count > 0) ?
         ((double)data.loss_distribution[b].count / loss_count) * 100.0 : 0;
   }
}

//+------------------------------------------------------------------+
//| Generate Monthly Performance                                      |
//+------------------------------------------------------------------+
void GenerateMonthlyPerformance(VisualAnalyticsData &data) {
   datetime now = TimeCurrent();
   MqlDateTime dt_now;
   TimeToStruct(now, dt_now);
   
   data.months_count = 0;
   data.best_month_pct = -999999;
   data.worst_month_pct = 999999;
   data.ytd_return = 0;
   
   // Go back 12 months
   for(int m = 0; m < 12; m++) {
      int target_month = dt_now.mon - m;
      int target_year = dt_now.year;
      
      while(target_month < 1) {
         target_month += 12;
         target_year--;
      }
      
      // Get month range
      MqlDateTime month_start, month_end;
      month_start.year = target_year;
      month_start.mon = target_month;
      month_start.day = 1;
      month_start.hour = 0;
      month_start.min = 0;
      month_start.sec = 0;
      
      datetime start_time = StructToTime(month_start);
      
      month_end = month_start;
      month_end.mon++;
      if(month_end.mon > 12) {
         month_end.mon = 1;
         month_end.year++;
      }
      datetime end_time = StructToTime(month_end);
      
      // Calculate monthly return
      if(HistorySelect(start_time, end_time)) {
         double month_profit = 0;
         int month_trades = 0;
         int month_wins = 0;
         
         int deals_total = HistoryDealsTotal();
         for(int i = 0; i < deals_total; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket <= 0) continue;
            
            if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
               double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               month_profit += profit;
               month_trades++;
               if(profit > 0) month_wins++;
            }
         }
         
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double return_pct = (balance > 0) ? (month_profit / balance) * 100.0 : 0;
         double win_rate = (month_trades > 0) ? ((double)month_wins / month_trades) * 100.0 : 0;
         
         data.monthly[data.months_count].year = target_year;
         data.monthly[data.months_count].month = target_month;
         data.monthly[data.months_count].return_pct = return_pct;
         data.monthly[data.months_count].trades = month_trades;
         data.monthly[data.months_count].win_rate = win_rate;
         
         // Color coding
         if(return_pct > 5.0) {
            data.monthly[data.months_count].cell_color = C'34,197,94';
         } else if(return_pct > 2.0) {
            data.monthly[data.months_count].cell_color = C'74,222,128';
         } else if(return_pct > 0) {
            data.monthly[data.months_count].cell_color = C'134,239,172';
         } else if(return_pct > -2.0) {
            data.monthly[data.months_count].cell_color = C'252,165,165';
         } else if(return_pct > -5.0) {
            data.monthly[data.months_count].cell_color = C'239,68,68';
         } else {
            data.monthly[data.months_count].cell_color = C'220,38,38';
         }
         
         if(return_pct > data.best_month_pct) data.best_month_pct = return_pct;
         if(return_pct < data.worst_month_pct) data.worst_month_pct = return_pct;
         
         if(target_year == dt_now.year) {
            data.ytd_return += return_pct;
         }
         
         data.months_count++;
      }
   }
}

//+------------------------------------------------------------------+
//| Main Analytics Generation Function                                |
//+------------------------------------------------------------------+
void GenerateVisualAnalytics(VisualAnalyticsData &data, int days_back = 90) {
   ZeroMemory(data);
   
   GenerateEquityCurve(data, days_back);
   GeneratePerformanceHeatmap(data, days_back);
   GenerateWinLossDistribution(data, days_back);
   GenerateMonthlyPerformance(data);
}

//+------------------------------------------------------------------+

#endif // MODULE_VISUAL_ANALYTICS_MQH
