//+------------------------------------------------------------------+
//|                  PortfolioAnalyticsDashboard_Integrated.mq5      |
//|                    PORTFOLIO COMMAND CENTER v3.0                 |
//|             Premium Trading Intelligence & Risk Analytics        |
//|                                                                   |
//|  "A Dashboard Worthy of the Future" - Premium Edition           |
//|                                                                   |
//|  Features:                                                        |
//|  • Executive Dashboard with Real-Time KPIs                       |
//|  • Advanced Performance Gauges & Risk Indicators                 |
//|  • Beautiful Card-Based UI with Depth & Shadows                  |
//|  • AI-Powered Trading Analytics                                  |
//|  • Multi-Algorithm Portfolio Tracking                            |
//|  • Comprehensive Risk Management Suite                           |
//|  • Professional Grade Visual Design                              |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence • Premium Edition"
#property version   "3.00"
#property indicator_chart_window
#property indicator_plots 0
#property description "Portfolio Command Center - Premium Trading Dashboard"
#property description "Executive Analytics • Real-Time Intelligence • Professional Design"
#property description "Engineered for Professional Traders & Portfolio Managers"

// Include all modules
#include "Core_DataStructures.mqh"
#include "Core_UIHelpers.mqh"
#include "Core_DataCollection.mqh"
#include "Module_AdvancedRisk.mqh"
#include "Module_AdvancedRisk_Render.mqh"
#include "Module_ScenarioSimulator.mqh"
#include "Module_ScenarioSimulator_Render.mqh"
#include "Module_VisualAnalytics.mqh"
#include "Module_VisualAnalytics_Render.mqh"
#include "Module_SmartAlerts.mqh"
#include "Module_SmartAlerts_Render.mqh"
#include "Module_TradeJournal.mqh"
#include "Module_TradeJournal_Render.mqh"
#include "Module_PositionSizing.mqh"
#include "Module_PositionSizing_Render.mqh"
#include "Module_CorrelationMatrix.mqh"
#include "Module_CorrelationMatrix_Render.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input ENUM_BASE_CORNER Corner = CORNER_LEFT_UPPER;
input int PanelX = 20;
input int PanelY = 40;
input int MainPanelWidth = 1400;
input int HeaderFontSize = 28;
input int MetricFontSize = 22;
input int LabelFontSize = 14;
input int AnalysisPeriodDays = 30;
input bool AutoRefresh = true;
input int RefreshSeconds = 5;

//--- Colors
input color ColorHeader = clrGold;
input color ColorGood = C'34,197,94';
input color ColorWarning = C'251,191,36';
input color ColorDanger = C'239,68,68';
input color ColorInfo = C'59,130,246';
input color ColorBg = C'17,24,39';
input color ColorPanel = C'31,41,55';
input color ColorText = C'229,231,235';

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
AlgoMetrics algos[];
int algo_count = 0;
PortfolioMetrics portfolio;
MarketConditions market;
AdvancedRiskMetrics risk;
ScenarioResult scenario;
VisualAnalyticsData visual_data;
AlertMonitorData alert_data;
TradeJournalData journal_data;
PositionSizingData sizing_data;
CorrelationMatrixData correlation_data;

const string PREFIX = "DASH_";
bool is_main_minimized = false;
bool show_risk_panel = false;
bool show_scenario_panel = false;
bool show_visual_panel = false;
bool show_alerts_panel = false;
bool show_journal_panel = false;
bool show_sizing_panel = false;
bool show_correlation_panel = false;
datetime last_update = 0;

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
int OnInit() {
   Print("=== INTEGRATED PORTFOLIO ANALYTICS SYSTEM ===");
   Print("Main Dashboard + Toggleable Modules");
   
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   
   // Initialize alert system
   InitializeAlertConfig();
   ZeroMemory(alert_data);
   alert_data.session_start = TimeCurrent();
   
   if(AutoRefresh) {
      EventSetTimer(RefreshSeconds);
   }
   
   UpdateData();
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   CleanupObjects(PREFIX);
   ClearAdvancedRiskPanel();
   ClearScenarioSimulatorPanel();
   ClearVisualAnalyticsPanel();
   ClearSmartAlertsPanel();
   ClearTradeJournalPanel();
   ClearPositionSizingPanel();
   ClearCorrelationMatrixPanel();
}

//+------------------------------------------------------------------+
//| OnCalculate                                                       |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   return rates_total;
}

//+------------------------------------------------------------------+
//| Timer                                                             |
//+------------------------------------------------------------------+
void OnTimer() {
   if(TimeCurrent() - last_update >= RefreshSeconds) {
      UpdateData();
      RenderDashboard();
   }
}

//+------------------------------------------------------------------+
//| Close All Panels Except One                                       |
//+------------------------------------------------------------------+
void CloseAllPanelsExcept(string keep_panel) {
   if(keep_panel != "risk") {
      show_risk_panel = false;
      ClearAdvancedRiskPanel();
   }
   if(keep_panel != "scenario") {
      show_scenario_panel = false;
      ClearScenarioSimulatorPanel();
   }
   if(keep_panel != "visual") {
      show_visual_panel = false;
      ClearVisualAnalyticsPanel();
   }
   if(keep_panel != "alerts") {
      show_alerts_panel = false;
      ClearSmartAlertsPanel();
   }
   if(keep_panel != "journal") {
      show_journal_panel = false;
      ClearTradeJournalPanel();
   }
   if(keep_panel != "sizing") {
      show_sizing_panel = false;
      ClearPositionSizingPanel();
   }
   if(keep_panel != "correlation") {
      show_correlation_panel = false;
      ClearCorrelationMatrixPanel();
   }
}

//+------------------------------------------------------------------+
//| Chart Event                                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      // Main dashboard controls
      if(StringFind(sparam, PREFIX + "minimize") >= 0 || StringFind(sparam, PREFIX + "maximize") >= 0) {
         is_main_minimized = !is_main_minimized;
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "refresh") >= 0) {
         UpdateData();
         RenderDashboard();
         ResetButton(sparam);
      }
      // Module toggle buttons AND close buttons
      else if(StringFind(sparam, PREFIX + "toggle_risk") >= 0 || StringFind(sparam, "RISK_close") >= 0) {
         show_risk_panel = !show_risk_panel;
         if(!show_risk_panel) {
            ClearAdvancedRiskPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("risk");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_scenario") >= 0 || StringFind(sparam, "SCENARIO_close") >= 0) {
         show_scenario_panel = !show_scenario_panel;
         if(!show_scenario_panel) {
            ClearScenarioSimulatorPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("scenario");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_visual") >= 0 || StringFind(sparam, "VISUAL_close") >= 0) {
         show_visual_panel = !show_visual_panel;
         if(!show_visual_panel) {
            ClearVisualAnalyticsPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("visual");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_alerts") >= 0 || StringFind(sparam, "ALERT_close") >= 0) {
         show_alerts_panel = !show_alerts_panel;
         if(!show_alerts_panel) {
            ClearSmartAlertsPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("alerts");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_journal") >= 0 || StringFind(sparam, "JOURNAL_close") >= 0) {
         show_journal_panel = !show_journal_panel;
         if(!show_journal_panel) {
            ClearTradeJournalPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("journal");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_sizing") >= 0 || StringFind(sparam, "SIZING_close") >= 0) {
         show_sizing_panel = !show_sizing_panel;
         if(!show_sizing_panel) {
            ClearPositionSizingPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("sizing");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_correlation") >= 0 || StringFind(sparam, "CORR_close") >= 0) {
         show_correlation_panel = !show_correlation_panel;
         if(!show_correlation_panel) {
            ClearCorrelationMatrixPanel();
            is_main_minimized = false;  // Restore main dashboard when closing
         } else {
            // Close other panels and minimize main dashboard
            CloseAllPanelsExcept("correlation");
            is_main_minimized = true;  // Minimize main dashboard when opening module
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      
      // Alert panel buttons
      else if(StringFind(sparam, "ALERT_clear_all") >= 0) {
         ClearAcknowledgedAlerts(alert_data);
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, "ALERT_ack_") >= 0) {
         // Extract alert index from button name
         string btn_name = sparam;
         int idx_pos = StringFind(btn_name, "ALERT_ack_");
         if(idx_pos >= 0) {
            string idx_str = StringSubstr(btn_name, idx_pos + 10);
            int alert_idx = (int)StringToInteger(idx_str);
            AcknowledgeAlert(alert_data, alert_idx);
            ResetButton(sparam);
            RenderDashboard();
         }
      }
      // Scenario controls
      else if(StringFind(sparam, "SCENARIO_") >= 0) {
         HandleScenarioEvent(sparam);
      }
   }
}

//+------------------------------------------------------------------+
//| Handle Scenario Events                                            |
//+------------------------------------------------------------------+
void HandleScenarioEvent(string sparam) {
   if(StringFind(sparam, "scenario_close") >= 0) {
      g_selected_scenario = 0;
      RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "scenario_gap") >= 0) {
      g_selected_scenario = 1;
      RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "scenario_all") >= 0) {
      g_selected_scenario = 2;
      RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "scenario_reduce") >= 0) {
      g_selected_scenario = 3;
      RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "algo_next") >= 0) {
      g_selected_algo_idx = (g_selected_algo_idx + 1) % algo_count;
      if(g_selected_scenario == 0) RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "algo_prev") >= 0) {
      g_selected_algo_idx = (g_selected_algo_idx - 1 + algo_count) % algo_count;
      if(g_selected_scenario == 0) RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "gap_up") >= 0) {
      g_gap_pips += 50;
      if(g_selected_scenario == 1) RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "gap_down") >= 0) {
      g_gap_pips = MathMax(50, g_gap_pips - 50);
      if(g_selected_scenario == 1) RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "reduce_up") >= 0) {
      g_reduce_pct = MathMin(100, g_reduce_pct + 10);
      if(g_selected_scenario == 3) RunScenario();
      RenderDashboard();
   }
   else if(StringFind(sparam, "reduce_down") >= 0) {
      g_reduce_pct = MathMax(10, g_reduce_pct - 10);
      if(g_selected_scenario == 3) RunScenario();
      RenderDashboard();
   }
   
   ResetButton(sparam);
}

//+------------------------------------------------------------------+
//| Update Data                                                       |
//+------------------------------------------------------------------+
void UpdateData() {
   CollectAlgos(algos, algo_count, AnalysisPeriodDays, true, 10, 40.0,
                ColorGood, ColorGood, ColorWarning, ColorDanger);
   
   AnalyzePortfolio(portfolio, algos, algo_count);
   
   AnalyzeMarketConditions(market);
   
   // Update advanced risk if panel is shown
   if(show_risk_panel) {
      AnalyzeAdvancedRisk(risk, algos, algo_count, portfolio, AnalysisPeriodDays);
   }
   
   // Update scenario if panel is shown
   if(show_scenario_panel && algo_count > 0) {
      g_selected_algo_idx = MathMin(g_selected_algo_idx, algo_count - 1);
      RunScenario();
   }
   
   // Update visual analytics if panel is shown
   if(show_visual_panel) {
      GenerateVisualAnalytics(visual_data, AnalysisPeriodDays);
   }
   
   // Monitor alerts (always active for real-time monitoring)
   MonitorAlerts(alert_data, algos, algo_count, portfolio, risk);
   
   // Generate trade journal if panel is shown
   if(show_journal_panel) {
      GenerateTradeJournal(journal_data, AnalysisPeriodDays);
   }
   
   // Generate position sizing if panel is shown
   if(show_sizing_panel) {
      if(g_calc_symbol == "") g_calc_symbol = Symbol();
      GeneratePositionSizingRecommendations(sizing_data, g_calc_symbol, 
                                           g_calc_sl_pips, g_calc_tp_pips,
                                           journal_data.overall_stats);
   }
   
   // Generate correlation matrix if panel is shown
   if(show_correlation_panel) {
      GenerateCorrelationMatrix(correlation_data, algos, algo_count, AnalysisPeriodDays);
   }
   
   last_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Run Current Scenario                                              |
//+------------------------------------------------------------------+
void RunScenario() {
   if(algo_count == 0) return;
   
   switch(g_selected_scenario) {
      case 0:
         SimulateCloseAlgo(scenario, algos[g_selected_algo_idx], algos, algo_count, portfolio);
         break;
      case 1:
         SimulateMarketGap(scenario, g_gap_pips, algos, algo_count, portfolio);
         break;
      case 2:
         SimulateCloseAllLosing(scenario, algos, algo_count, portfolio);
         break;
      case 3:
         SimulateReduceSize(scenario, g_reduce_pct, algos, algo_count, portfolio);
         break;
   }
}

//+------------------------------------------------------------------+
//| Render Dashboard                                                  |
//+------------------------------------------------------------------+
void RenderDashboard() {
   CleanupObjects(PREFIX);

   // ========== RENDER MAIN DASHBOARD (FULL OR MINIMIZED) ==========
   if(is_main_minimized) {
      RenderMinimized();
   } else {
      RenderMainDashboard(PanelY);
   }

   // ========== RENDER MODULE PANELS ON TOP (OVERLAPPING) ==========
   // These panels appear as modal overlays on top of the main dashboard
   // Fixed position so they don't push content down
   int modal_y = PanelY + 120;  // Fixed Y position for all modal panels

   // Module panels render on top with OPAQUE backgrounds
   if(show_risk_panel) {
      RenderAdvancedRiskPanel(risk, modal_y, MainPanelWidth, Corner,
                             HeaderFontSize, MetricFontSize, LabelFontSize,
                             ColorHeader, ColorGood, ColorWarning, ColorDanger,
                             ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_scenario_panel) {
      RenderScenarioSimulatorPanel(scenario, algos, algo_count, modal_y, MainPanelWidth, Corner,
                                   HeaderFontSize, MetricFontSize, LabelFontSize,
                                   ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                   ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_visual_panel) {
      RenderVisualAnalyticsPanel(visual_data, modal_y, MainPanelWidth, Corner,
                                 HeaderFontSize, MetricFontSize, LabelFontSize,
                                 ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                 ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_alerts_panel) {
      RenderSmartAlertsPanel(alert_data, modal_y, MainPanelWidth, Corner,
                            HeaderFontSize, MetricFontSize, LabelFontSize,
                            ColorHeader, ColorGood, ColorWarning, ColorDanger,
                            ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_journal_panel) {
      RenderTradeJournalPanel(journal_data, modal_y, MainPanelWidth, Corner,
                             HeaderFontSize, MetricFontSize, LabelFontSize,
                             ColorHeader, ColorGood, ColorWarning, ColorDanger,
                             ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_sizing_panel) {
      RenderPositionSizingPanel(sizing_data, journal_data.overall_stats, modal_y, MainPanelWidth, Corner,
                               HeaderFontSize, MetricFontSize, LabelFontSize,
                               ColorHeader, ColorGood, ColorWarning, ColorDanger,
                               ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   if(show_correlation_panel) {
      RenderCorrelationMatrixPanel(correlation_data, modal_y, MainPanelWidth, Corner,
                                   HeaderFontSize, MetricFontSize, LabelFontSize,
                                   ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                   ColorInfo, ColorBg, ColorPanel, ColorText);
   }

   RenderStatusBar();
}

//+------------------------------------------------------------------+
//| Render Main Dashboard                                             |
//+------------------------------------------------------------------+
int RenderMainDashboard(int start_y) {
   int y = start_y;

   // ========== PREMIUM HEADER ==========
   CreateRect(PREFIX + "header_gradient1", PanelX, y, MainPanelWidth, 90, C'20,30,48', true, Corner);
   CreateRect(PREFIX + "header_gradient2", PanelX, y, MainPanelWidth, 3, ColorHeader, false, Corner);

   // Logo/Icon
   CreateLbl(PREFIX + "logo", PanelX + 25, y + 18, "◆", ColorHeader, 32, "Arial Black", Corner);

   // Title
   CreateLbl(PREFIX + "title", PanelX + 70, y + 18,
            "PORTFOLIO COMMAND CENTER", ColorHeader, 24, "Arial Black", Corner);

   CreateLbl(PREFIX + "subtitle", PanelX + 70, y + 50,
            "Real-Time Trading Intelligence • Professional Analytics",
            C'156,163,175', 10, "Arial", Corner);

   // Live indicator
   CreateRect(PREFIX + "live_dot", PanelX + 70, y + 68, 6, 6, C'34,197,94', false, Corner);
   CreateLbl(PREFIX + "live_text", PanelX + 82, y + 65, "LIVE", C'34,197,94', 9, "Arial Bold", Corner);

   // Control buttons (top right)
   CreateActionBtn(PREFIX + "refresh", PanelX + MainPanelWidth - 280, y + 20, 120, 45,
            "⟳", "REFRESH", C'59,130,246', clrWhite, Corner);

   CreateActionBtn(PREFIX + "minimize", PanelX + MainPanelWidth - 150, y + 20, 120, 45,
            "−", "MINIMIZE", C'55,65,81', ColorText, Corner);

   y += 100;

   // ========== EXECUTIVE METRICS CARDS ==========
   int card_width = 320;
   int card_height = 110;
   int card_spacing = 25;
   int card_y = y;

   // Calculate daily P&L change (mock for now - would need historical data)
   double total_pl = portfolio.total_realized_pl + portfolio.total_floating_pl;
   double pl_change_pct = (portfolio.equity > 0) ? (total_pl / portfolio.equity * 100) : 0;

   // Card 1: Total Equity
   string equity_val = StringFormat("$%.0f", portfolio.equity);
   CreateMetricCard(PREFIX + "card_equity", PanelX + 30, card_y, card_width, card_height,
                   equity_val, "TOTAL EQUITY", ColorInfo, true, pl_change_pct, ColorPanel, Corner);

   // Card 2: Total P&L
   string pl_val = StringFormat("$%.0f", total_pl);
   color pl_color = (total_pl >= 0) ? ColorGood : ColorDanger;
   CreateMetricCard(PREFIX + "card_pl", PanelX + 30 + card_width + card_spacing, card_y,
                   card_width, card_height, pl_val, "TOTAL P&L", pl_color,
                   true, pl_change_pct, ColorPanel, Corner);

   // Card 3: Win Rate
   double avg_win_rate = 0;
   for(int i = 0; i < algo_count; i++) {
      avg_win_rate += algos[i].win_rate;
   }
   if(algo_count > 0) avg_win_rate /= algo_count;
   string wr_val = StringFormat("%.1f%%", avg_win_rate);
   color wr_color = (avg_win_rate >= 50) ? ColorGood : ColorDanger;
   CreateMetricCard(PREFIX + "card_winrate", PanelX + 30 + (card_width + card_spacing) * 2, card_y,
                   card_width, card_height, wr_val, "AVG WIN RATE", wr_color,
                   false, 0, ColorPanel, Corner);

   // Card 4: Active Algos
   string algo_val = IntegerToString(algo_count);
   CreateMetricCard(PREFIX + "card_algos", PanelX + 30 + (card_width + card_spacing) * 3, card_y,
                   card_width, card_height, algo_val, "ACTIVE ALGORITHMS", ColorInfo,
                   false, 0, ColorPanel, Corner);

   y += card_height + 30;

   // ========== KEY STATISTICS ROW ==========
   CreateCard(PREFIX + "stats_card", PanelX + 30, y, MainPanelWidth - 60, 90,
             ColorPanel, C'55,65,81', Corner);

   int stat_x = PanelX + 70;
   int stat_y = y + 20;
   int stat_spacing = 265;  // Increased spacing to prevent overlap

   // Margin Level with risk indicator
   CreateLbl(PREFIX + "margin_label", stat_x, stat_y, "MARGIN LEVEL", C'156,163,175', 10, "Arial", Corner);
   string margin_text = StringFormat("%.0f%%", portfolio.margin_level);
   color margin_color = (portfolio.margin_level > 300) ? ColorGood :
                       (portfolio.margin_level > 200) ? ColorWarning : ColorDanger;
   CreateLbl(PREFIX + "margin_value", stat_x, stat_y + 18, margin_text, margin_color, 24, "Arial Black", Corner);
   string margin_status = (portfolio.margin_level > 300) ? "HEALTHY" : (portfolio.margin_level > 200) ? "CAUTION" : "CRITICAL";
   CreateLbl(PREFIX + "margin_status", stat_x, stat_y + 50, margin_status, margin_color, 9, "Arial Bold", Corner);

   // Total Positions
   CreateLbl(PREFIX + "pos_label", stat_x + stat_spacing, stat_y, "OPEN POSITIONS", C'156,163,175', 10, "Arial", Corner);
   string pos_text = IntegerToString(portfolio.total_positions);
   CreateLbl(PREFIX + "pos_value", stat_x + stat_spacing, stat_y + 18, pos_text, ColorInfo, 24, "Arial Black", Corner);
   string pos_breakdown = StringFormat("↑%d  ↓%d", portfolio.total_buy, portfolio.total_sell);
   CreateLbl(PREFIX + "pos_breakdown", stat_x + stat_spacing, stat_y + 50, pos_breakdown, C'156,163,175', 9, "Arial", Corner);

   // Total Lots
   CreateLbl(PREFIX + "lots_label", stat_x + stat_spacing * 2, stat_y, "TOTAL VOLUME", C'156,163,175', 10, "Arial", Corner);
   string lots_text = StringFormat("%.2f", portfolio.total_lots);
   CreateLbl(PREFIX + "lots_value", stat_x + stat_spacing * 2, stat_y + 18, lots_text, ColorInfo, 24, "Arial Black", Corner);
   CreateLbl(PREFIX + "lots_units", stat_x + stat_spacing * 2, stat_y + 50, "LOTS", C'156,163,175', 9, "Arial Bold", Corner);

   // Drawdown
   CreateLbl(PREFIX + "dd_label", stat_x + stat_spacing * 3, stat_y, "DRAWDOWN", C'156,163,175', 10, "Arial", Corner);
   string dd_text = StringFormat("%.1f%%", portfolio.drawdown_pct);
   color dd_color = (portfolio.drawdown_pct < 5) ? ColorGood :
                   (portfolio.drawdown_pct < 15) ? ColorWarning : ColorDanger;
   CreateLbl(PREFIX + "dd_value", stat_x + stat_spacing * 3, stat_y + 18, dd_text, dd_color, 24, "Arial Black", Corner);
   string dd_status = (portfolio.drawdown_pct < 5) ? "MINIMAL" : (portfolio.drawdown_pct < 15) ? "MODERATE" : "SEVERE";
   CreateLbl(PREFIX + "dd_status", stat_x + stat_spacing * 3, stat_y + 50, dd_status, dd_color, 9, "Arial Bold", Corner);

   // Best Performer
   CreateLbl(PREFIX + "best_label", stat_x + stat_spacing * 4, stat_y, "TOP PERFORMER", C'156,163,175', 10, "Arial", Corner);
   string best_pl_text = StringFormat("+$%.0f", portfolio.best_pl);
   CreateLbl(PREFIX + "best_value", stat_x + stat_spacing * 4, stat_y + 18, best_pl_text, ColorGood, 24, "Arial Black", Corner);
   string best_name = (StringLen(portfolio.best_algo) > 12) ? StringSubstr(portfolio.best_algo, 0, 12) + "..." : portfolio.best_algo;
   CreateLbl(PREFIX + "best_name", stat_x + stat_spacing * 4, stat_y + 50, best_name, C'156,163,175', 9, "Arial Bold", Corner);

   // CRITICAL: Increment Y after stats card!
   y += 100;  // Stats card height (90) + spacing

   // ========== ALGORITHM PERFORMANCE OVERVIEW ==========
   CreateSectionHeader(PREFIX + "algo_header", PanelX + 30, y, MainPanelWidth - 60,
                      "ALGORITHM PERFORMANCE", "▣", ColorHeader, Corner);

   y += 60;

   // Performance Score Legend - split into two lines to prevent overlap
   CreateLbl(PREFIX + "legend_label", PanelX + 50, y,
            "Score Criteria: Win Rate (35%) • Profit Factor (15%) • Drawdown (10%)",
            C'156,163,175', 9, "Arial Italic", Corner);
   CreateLbl(PREFIX + "legend_label2", PanelX + 50, y + 14,
            "Sharpe Ratio (10%) • Expectancy (15%) • Risk Management (15%)",
            C'156,163,175', 9, "Arial Italic", Corner);

   y += 40;  // Increased from 25 to account for two lines

   // Algorithm Performance Cards (Top 5 performers)
   int display_count = MathMin(algo_count, 5);
   if(display_count > 0) {
      int perf_card_height = 70;
      int card_spacing_y = 10;  // Spacing between cards
      int perf_y = y;

      for(int i = 0; i < display_count; i++) {
         CreateCard(PREFIX + "algo_card_" + IntegerToString(i), PanelX + 40, perf_y,
                   MainPanelWidth - 80, perf_card_height, ColorPanel, C'55,65,81', Corner);

         // Rank badge
         color rank_color = (i == 0) ? C'251,191,36' : (i == 1) ? C'209,213,219' :
                           (i == 2) ? C'205,127,50' : C'75,85,99';
         CreateRect(PREFIX + "rank_" + IntegerToString(i), PanelX + 50, perf_y + 24, 30, 22,
                   rank_color, false, Corner);
         CreateLbl(PREFIX + "rank_num_" + IntegerToString(i), PanelX + 60, perf_y + 27,
                  IntegerToString(i + 1), clrWhite, 11, "Arial Black", Corner);

         // Algo name
         string display_name = (StringLen(algos[i].name) > 18) ?
                              StringSubstr(algos[i].name, 0, 18) + "..." : algos[i].name;
         CreateLbl(PREFIX + "algo_name_" + IntegerToString(i), PanelX + 95, perf_y + 8,
                  display_name, ColorText, 13, "Arial Black", Corner);

         // Symbols (ELON'S REQUEST - SHOW ALL SYMBOLS!)
         string symbols_text = "";
         if(algos[i].symbol_count > 0) {
            // Show ALL symbols, comma-separated
            for(int s = 0; s < algos[i].symbol_count; s++) {
               if(s > 0) symbols_text += ", ";
               symbols_text += algos[i].symbols[s];
            }
         }
         CreateLbl(PREFIX + "algo_symbols_" + IntegerToString(i), PanelX + 95, perf_y + 27,
                  "Symbols: " + symbols_text, ColorInfo, 10, "Arial Bold", Corner);

         // Performance Score (what status is based on)
         string score_text = StringFormat("Score: %.0f", algos[i].performance_score);
         CreateLbl(PREFIX + "algo_score_" + IntegerToString(i), PanelX + 95, perf_y + 46,
                  score_text, algos[i].status_color, 10, "Arial Bold", Corner);

         // Status badge
         CreateBadge(PREFIX + "algo_status_" + IntegerToString(i), PanelX + 95 + StringLen(score_text) * 6 + 15, perf_y + 44,
                    algos[i].status, algos[i].status_color, clrWhite, Corner);

         // P&L (BIG AND CLEAR!)
         string pl_text = StringFormat("$%.2f", algos[i].floating_pl);
         color algo_pl_color = (algos[i].floating_pl >= 0) ? ColorGood : ColorDanger;
         CreateLbl(PREFIX + "algo_pl_label_" + IntegerToString(i), PanelX + 550, perf_y + 8,
                  "P&L:", C'156,163,175', 10, "Arial", Corner);
         CreateLbl(PREFIX + "algo_pl_" + IntegerToString(i), PanelX + 550, perf_y + 24,
                  pl_text, algo_pl_color, 18, "Arial Black", Corner);

         // Win Rate
         string wr_text = StringFormat("%.1f%%", algos[i].win_rate);
         color wr_clr = (algos[i].win_rate >= 60) ? ColorGood :
                       (algos[i].win_rate >= 40) ? ColorWarning : ColorDanger;
         CreateLbl(PREFIX + "algo_wr_label_" + IntegerToString(i), PanelX + 720, perf_y + 8,
                  "Win Rate:", C'156,163,175', 10, "Arial", Corner);
         CreateLbl(PREFIX + "algo_wr_" + IntegerToString(i), PanelX + 720, perf_y + 24,
                  wr_text, wr_clr, 14, "Arial Black", Corner);

         // Volume & Positions
         string vol_text = StringFormat("%.2f lots", algos[i].total_lots);
         CreateLbl(PREFIX + "algo_vol_" + IntegerToString(i), PanelX + 850, perf_y + 12,
                  vol_text, C'156,163,175', 10, "Arial", Corner);

         string pos_count = StringFormat("%d pos", algos[i].pos_count);
         CreateLbl(PREFIX + "algo_pos_" + IntegerToString(i), PanelX + 850, perf_y + 30,
                  pos_count, C'156,163,175', 10, "Arial", Corner);

         // Drawdown
         string dd_text = StringFormat("DD: %.1f%%", algos[i].max_dd_pct);
         color dd_clr = (algos[i].max_dd_pct < 10) ? ColorGood :
                       (algos[i].max_dd_pct < 20) ? ColorWarning : ColorDanger;
         CreateLbl(PREFIX + "algo_dd_" + IntegerToString(i), PanelX + 1000, perf_y + 20,
                  dd_text, dd_clr, 11, "Arial Bold", Corner);

         perf_y += perf_card_height + card_spacing_y;
      }

      y = perf_y;
   } else {
      // No algorithms running
      CreateCard(PREFIX + "no_algos", PanelX + 40, y, MainPanelWidth - 80, 80,
                ColorPanel, C'55,65,81', Corner);
      CreateLbl(PREFIX + "no_algos_msg", PanelX + MainPanelWidth/2 - 150, y + 28,
               "No active algorithms detected", C'156,163,175', 14, "Arial", Corner);
      y += 90;
   }

   if(algo_count > 5) {
      CreateLbl(PREFIX + "more_algos", PanelX + 50, y,
               StringFormat("+ %d more algorithms (expand modules for full view)", algo_count - 5),
               C'156,163,175', 10, "Arial Italic", Corner);
      y += 35;
   }

   // ========== MODULE ACCESS CONTROLS ==========
   y += 20;  // More spacing before module buttons
   CreateSectionHeader(PREFIX + "modules_header", PanelX + 30, y, MainPanelWidth - 60,
                      "ADVANCED ANALYTICS MODULES", "☰", ColorInfo, Corner);

   y += 60;

   // Module buttons in a clean grid
   int btn_width = 200;
   int btn_height = 45;
   int btn_spacing_x = 220;
   int btn_spacing_y = 55;
   int btn_start_x = PanelX + 60;
   int btn_y = y;

   // Row 1
   color risk_btn_color = show_risk_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_risk", btn_start_x, btn_y, btn_width, btn_height,
            "🛡", show_risk_panel ? "HIDE RISK" : "SHOW RISK", risk_btn_color, clrWhite, Corner);

   color scenario_btn_color = show_scenario_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_scenario", btn_start_x + btn_spacing_x, btn_y, btn_width, btn_height,
            "⚡", show_scenario_panel ? "HIDE SCENARIO" : "SHOW SCENARIO",
            scenario_btn_color, clrWhite, Corner);

   color visual_btn_color = show_visual_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_visual", btn_start_x + btn_spacing_x * 2, btn_y, btn_width, btn_height,
            "📊", show_visual_panel ? "HIDE VISUAL" : "SHOW VISUAL",
            visual_btn_color, clrWhite, Corner);

   color alerts_btn_color = show_alerts_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_alerts", btn_start_x + btn_spacing_x * 3, btn_y, btn_width, btn_height,
            "🔔", show_alerts_panel ? "HIDE ALERTS" : "SHOW ALERTS",
            alerts_btn_color, clrWhite, Corner);

   // Alert badge if there are active alerts
   if(alert_data.active_count > 0) {
      CreateAlertBadge(PREFIX + "alert_badge", btn_start_x + btn_spacing_x * 3 + btn_width - 10,
                      btn_y - 5, alert_data.active_count, C'239,68,68', Corner);
   }

   // Row 2
   btn_y += btn_spacing_y;

   color journal_btn_color = show_journal_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_journal", btn_start_x, btn_y, btn_width, btn_height,
            "📝", show_journal_panel ? "HIDE JOURNAL" : "SHOW JOURNAL",
            journal_btn_color, clrWhite, Corner);

   color sizing_btn_color = show_sizing_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_sizing", btn_start_x + btn_spacing_x, btn_y, btn_width, btn_height,
            "⚖", show_sizing_panel ? "HIDE SIZING" : "SHOW SIZING",
            sizing_btn_color, clrWhite, Corner);

   color correlation_btn_color = show_correlation_panel ? C'59,130,246' : C'55,65,81';
   CreateActionBtn(PREFIX + "toggle_correlation", btn_start_x + btn_spacing_x * 2, btn_y, btn_width, btn_height,
            "🔗", show_correlation_panel ? "HIDE CORRELATION" : "SHOW CORRELATION",
            correlation_btn_color, clrWhite, Corner);

   return btn_y + btn_height + 40;
}

//+------------------------------------------------------------------+
//| Render Minimized                                                  |
//+------------------------------------------------------------------+
void RenderMinimized() {
   int h = 90;
   int w = 850;

   // Premium minimized bar with depth
   CreateCard(PREFIX + "mini_container", PanelX, PanelY, w, h, C'20,30,48', C'55,65,81', Corner);

   // Top accent line
   CreateRect(PREFIX + "mini_accent", PanelX, PanelY, w, 3, ColorHeader, false, Corner);

   // Icon
   CreateLbl(PREFIX + "mini_icon", PanelX + 20, PanelY + 18, "◆", ColorHeader, 28, "Arial Black", Corner);

   // Title
   CreateLbl(PREFIX + "mini_title", PanelX + 60, PanelY + 18,
            "PORTFOLIO COMMAND CENTER", ColorHeader, 16, "Arial Black", Corner);

   // Live indicator
   CreateRect(PREFIX + "mini_live_dot", PanelX + 60, PanelY + 48, 6, 6, C'34,197,94', false, Corner);
   CreateLbl(PREFIX + "mini_live", PanelX + 72, PanelY + 45, "LIVE", C'34,197,94', 9, "Arial Bold", Corner);

   // Quick stats
   double total_pl = portfolio.total_realized_pl + portfolio.total_floating_pl;
   color pl_color = (total_pl >= 0) ? ColorGood : ColorDanger;
   string pl_arrow = (total_pl >= 0) ? "▲" : "▼";

   string quick_stats = StringFormat("%s $%.0f  •  %d Algos  •  $%.0f Equity  •  %.0f%% Margin",
                                     pl_arrow, MathAbs(total_pl), algo_count,
                                     portfolio.equity, portfolio.margin_level);

   CreateLbl(PREFIX + "mini_stats", PanelX + 60, PanelY + 62,
            quick_stats, ColorText, 11, "Arial", Corner);

   // Maximize button
   CreateActionBtn(PREFIX + "maximize", PanelX + w - 140, PanelY + 25, 120, 45,
            "+", "EXPAND", C'59,130,246', clrWhite, Corner);
}

//+------------------------------------------------------------------+
//| Status Bar                                                         |
//+------------------------------------------------------------------+
void RenderStatusBar() {
   int bar_height = 40;
   int y = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) - bar_height - 5;

   // Premium status bar
   CreateCard(PREFIX + "status_bar", PanelX, y, MainPanelWidth, bar_height,
             C'20,30,48', C'55,65,81', Corner);

   // Timestamp with icon
   CreateLbl(PREFIX + "status_icon", PanelX + 20, y + 12, "⟳", C'34,197,94', 14, "Arial Black", Corner);
   string time_text = StringFormat("Last Update: %s", TimeToString(last_update, TIME_SECONDS));
   CreateLbl(PREFIX + "status_time", PanelX + 45, y + 13, time_text, C'156,163,175', 11, "Arial", Corner);

   // Module indicators with dots
   int indicator_x = PanelX + 300;
   int dot_spacing = 140;

   // Risk
   color risk_dot = show_risk_panel ? C'34,197,94' : C'55,65,81';
   CreateRect(PREFIX + "risk_dot", indicator_x, y + 16, 8, 8, risk_dot, false, Corner);
   CreateLbl(PREFIX + "risk_status", indicator_x + 15, y + 13, "RISK", C'156,163,175', 10, "Arial", Corner);

   // Scenario
   color scenario_dot = show_scenario_panel ? C'34,197,94' : C'55,65,81';
   CreateRect(PREFIX + "scenario_dot", indicator_x + dot_spacing, y + 16, 8, 8, scenario_dot, false, Corner);
   CreateLbl(PREFIX + "scenario_status", indicator_x + dot_spacing + 15, y + 13, "SCENARIO", C'156,163,175', 10, "Arial", Corner);

   // Visual
   color visual_dot = show_visual_panel ? C'34,197,94' : C'55,65,81';
   CreateRect(PREFIX + "visual_dot", indicator_x + dot_spacing * 2, y + 16, 8, 8, visual_dot, false, Corner);
   CreateLbl(PREFIX + "visual_status", indicator_x + dot_spacing * 2 + 15, y + 13, "VISUAL", C'156,163,175', 10, "Arial", Corner);

   // Alerts
   color alerts_dot = show_alerts_panel ? C'34,197,94' : C'55,65,81';
   CreateRect(PREFIX + "alerts_dot", indicator_x + dot_spacing * 3, y + 16, 8, 8, alerts_dot, false, Corner);
   CreateLbl(PREFIX + "alerts_status", indicator_x + dot_spacing * 3 + 15, y + 13, "ALERTS", C'156,163,175', 10, "Arial", Corner);

   // System health indicator
   double system_health = (portfolio.health_score + portfolio.performance_score) / 2.0;
   color health_color = (system_health >= 70) ? C'34,197,94' :
                       (system_health >= 40) ? C'251,191,36' : C'239,68,68';
   string health_text = (system_health >= 70) ? "OPTIMAL" :
                       (system_health >= 40) ? "STABLE" : "ATTENTION";

   CreateLbl(PREFIX + "health_label", PanelX + MainPanelWidth - 180, y + 8,
            "SYSTEM STATUS", C'156,163,175', 9, "Arial", Corner);
   CreateLbl(PREFIX + "health_value", PanelX + MainPanelWidth - 180, y + 22,
            health_text, health_color, 11, "Arial Black", Corner);

   // Version indicator
   CreateLbl(PREFIX + "version", PanelX + MainPanelWidth - 60, y + 13,
            "v3.0", C'75,85,99', 9, "Arial", Corner);
}

//+------------------------------------------------------------------+
