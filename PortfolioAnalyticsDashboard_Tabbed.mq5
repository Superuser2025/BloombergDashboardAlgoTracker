//+------------------------------------------------------------------+
//|                  PortfolioAnalyticsDashboard_Integrated.mq5      |
//|                INTEGRATED PORTFOLIO ANALYTICS SYSTEM             |
//|          Main Dashboard + Toggleable Modules (One Indicator)     |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "2.00"
#property indicator_chart_window
#property indicator_plots 0
#property description "Integrated Portfolio Analytics Dashboard"
#property description "Main Dashboard + Advanced Risk + Scenario Simulator"

// Include all modules
#include "Core_DataStructures.mqh"
#include "Core_UIHelpers.mqh"
#include "Core_DataCollection.mqh"
#include "Core_ResponsiveLayout.mqh"
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
input bool UseTabbedLayout = true;
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
   // Initialize responsive layout
   InitResponsiveLayout();
   if(UseTabbedLayout) {
      g_layout.use_tabs = true;
   }

   
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
//| Chart Event                                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   // Handle tab clicks (object-based) when using tabbed layout
   if(id == CHARTEVENT_OBJECT_CLICK && UseTabbedLayout && g_layout.use_tabs) {
      // Tabs are rendered as objects with names like: TAB_btn_0_bg / TAB_btn_0_lbl
      if(StringFind(sparam, "TAB_btn_") == 0) {
         string idx_str = "";
         int start = 8; // length of "TAB_btn_"
         int name_len = (int)StringLen(sparam);
         for(int i = start; i < name_len; i++) {
            string ch = StringSubstr(sparam, i, 1);
            if(ch >= "0" && ch <= "9") {
               idx_str += ch;
            } else {
               break;
            }
         }
         int tab_index = (int)StringToInteger(idx_str);
         SwitchTab(tab_index);
         RenderDashboard();
         return;
      }
   }

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
      // Module toggle buttons
      else if(StringFind(sparam, PREFIX + "toggle_risk") >= 0) {
         show_risk_panel = !show_risk_panel;
         if(!show_risk_panel) {
            ClearAdvancedRiskPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_scenario") >= 0) {
         show_scenario_panel = !show_scenario_panel;
         if(!show_scenario_panel) {
            ClearScenarioSimulatorPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_visual") >= 0) {
         show_visual_panel = !show_visual_panel;
         if(!show_visual_panel) {
            ClearVisualAnalyticsPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_alerts") >= 0) {
         show_alerts_panel = !show_alerts_panel;
         if(!show_alerts_panel) {
            ClearSmartAlertsPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_journal") >= 0) {
         show_journal_panel = !show_journal_panel;
         if(!show_journal_panel) {
            ClearTradeJournalPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_sizing") >= 0) {
         show_sizing_panel = !show_sizing_panel;
         if(!show_sizing_panel) {
            ClearPositionSizingPanel();
         }
         ResetButton(sparam);
         RenderDashboard();
      }
      else if(StringFind(sparam, PREFIX + "toggle_correlation") >= 0) {
         show_correlation_panel = !show_correlation_panel;
         if(!show_correlation_panel) {
            ClearCorrelationMatrixPanel();
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
   // Collect and analyze base portfolio data
   CollectAlgos(algos, algo_count, AnalysisPeriodDays, true, 10, 40.0,
                ColorGood, ColorGood, ColorWarning, ColorDanger);

   AnalyzePortfolio(portfolio, algos, algo_count);
   AnalyzeMarketConditions(market);

   // Always compute advanced risk metrics (safe when algo_count == 0)
   AnalyzeAdvancedRisk(risk, algos, algo_count, portfolio, AnalysisPeriodDays);

   // Always keep scenario data in sync when there are algos
   if(algo_count > 0) {
      g_selected_algo_idx = MathMin(g_selected_algo_idx, algo_count - 1);
      RunScenario();
   }

   // Visual analytics (equity curve, heatmap, distributions, etc.)
   GenerateVisualAnalytics(visual_data, AnalysisPeriodDays);

   // Alerts monitoring is always active
   MonitorAlerts(alert_data, algos, algo_count, portfolio, risk);

   // Trade journal
   GenerateTradeJournal(journal_data, AnalysisPeriodDays);

   // Position sizing recommendations (requires journal stats)
   if(g_calc_symbol == "") 
      g_calc_symbol = Symbol();
   GeneratePositionSizingRecommendations(sizing_data, g_calc_symbol, 
                                         g_calc_sl_pips, g_calc_tp_pips,
                                         journal_data.overall_stats);

   // Correlation matrix across algos
   GenerateCorrelationMatrix(correlation_data, algos, algo_count, AnalysisPeriodDays);

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


//+------------------------------------------------------------------+
//| Clear ALL dashboard panels (for tab switches / layout changes)   |
//+------------------------------------------------------------------+
void ClearAllPanels() {
   // Clear main dashboard objects
   CleanupObjects(PREFIX);

   // Clear each module's objects (they use their own prefixes)
   ClearAdvancedRiskPanel();
   ClearScenarioSimulatorPanel();
   ClearVisualAnalyticsPanel();
   ClearSmartAlertsPanel();
   ClearTradeJournalPanel();
   ClearPositionSizingPanel();
   ClearCorrelationMatrixPanel();
}

//+------------------------------------------------------------------+
void RenderDashboard() {
   ClearAllPanels();

   if(is_main_minimized) {
      RenderMinimized();
      return;
   }

   // Modern tabbed layout: one focused module at a time
   if(UseTabbedLayout && g_layout.use_tabs) {
      // Adapt to current screen and render global tab bar
      UpdateScreenSize();
      RenderTabBar(Corner, ColorPanel, ColorInfo, C'55,65,81', ColorText);

      int content_y = GetContentStartY();
      int panel_width = g_layout.panel_width;

      int active_tab = GetActiveTab();

      switch(active_tab) {
         case 0: // PORTFOLIO OVERVIEW
            RenderMainDashboard(content_y);
            break;
         case 1: // RISK
            RenderAdvancedRiskPanel(risk, content_y, panel_width, Corner,
                                   HeaderFontSize, MetricFontSize, LabelFontSize,
                                   ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                   ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
         case 2: // SCENARIO
            RenderScenarioSimulatorPanel(scenario, algos, algo_count, content_y, panel_width, Corner,
                                         HeaderFontSize, MetricFontSize, LabelFontSize,
                                         ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                         ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
         case 3: // VISUAL
            RenderVisualAnalyticsPanel(visual_data, content_y, panel_width, Corner,
                                       HeaderFontSize, MetricFontSize, LabelFontSize,
                                       ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                       ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
         case 4: // ALERTS
            RenderSmartAlertsPanel(alert_data, content_y, panel_width, Corner,
                                   HeaderFontSize, MetricFontSize, LabelFontSize,
                                   ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                   ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
         case 5: // JOURNAL
            RenderTradeJournalPanel(journal_data, content_y, panel_width, Corner,
                                    HeaderFontSize, MetricFontSize, LabelFontSize,
                                    ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                    ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
         case 6: // SIZING
            RenderPositionSizingPanel(sizing_data, journal_data.overall_stats, content_y, panel_width, Corner,
                                      HeaderFontSize, MetricFontSize, LabelFontSize,
                                      ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                      ColorInfo, ColorBg, ColorPanel, ColorText);
            break;
      }

      RenderStatusBar();
      return;
   }

   // Legacy stacked layout (all modules under main panel)
   int y = PanelY;

   // Main Dashboard
   y = RenderMainDashboard(y);

   // Module panels below main dashboard
   if(show_risk_panel) {
      y += 20;
      RenderAdvancedRiskPanel(risk, y, MainPanelWidth, Corner,
                             HeaderFontSize, MetricFontSize, LabelFontSize,
                             ColorHeader, ColorGood, ColorWarning, ColorDanger,
                             ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 1120;
   }
   
   if(show_scenario_panel) {
      y += 20;
      RenderScenarioSimulatorPanel(scenario, algos, algo_count, y, MainPanelWidth, Corner,
                                   HeaderFontSize, MetricFontSize, LabelFontSize,
                                   ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                   ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 970;
   }
   
   if(show_visual_panel) {
      y += 20;
      RenderVisualAnalyticsPanel(visual_data, y, MainPanelWidth, Corner,
                                 HeaderFontSize, MetricFontSize, LabelFontSize,
                                 ColorHeader, ColorGood, ColorWarning, ColorDanger,
                                 ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 1200;
   }
   
   if(show_alerts_panel) {
      y += 20;
      RenderSmartAlertsPanel(alert_data, y, MainPanelWidth, Corner,
                            HeaderFontSize, MetricFontSize, LabelFontSize,
                            ColorHeader, ColorGood, ColorWarning, ColorDanger,
                            ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 800;
   }
   
   if(show_journal_panel) {
      y += 20;
      RenderTradeJournalPanel(journal_data, y, MainPanelWidth, Corner,
                             HeaderFontSize, MetricFontSize, LabelFontSize,
                             ColorHeader, ColorGood, ColorWarning, ColorDanger,
                             ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 1400;
   }
   
   if(show_sizing_panel) {
      y += 20;
      RenderPositionSizingPanel(sizing_data, journal_data.overall_stats, y, MainPanelWidth, Corner,
                               HeaderFontSize, MetricFontSize, LabelFontSize,
                               ColorHeader, ColorGood, ColorWarning, ColorDanger,
                               ColorInfo, ColorBg, ColorPanel, ColorText);
      y += 1100;
   }
   
   if(show_correlation_panel) {
      y += 20;
      RenderCorrelationMatrixPanel(correlation_data, y, MainPanelWidth, Corner,
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
   
   // Main background
   CreateRect(PREFIX + "main_bg", PanelX, y, MainPanelWidth, 600, ColorBg, true, Corner);
   
   // Header
   CreateRect(PREFIX + "header_bg", PanelX, y, MainPanelWidth, 90, ColorPanel, true, Corner);
   
   CreateLbl(PREFIX + "title", PanelX + 30, y + 20,
            "PORTFOLIO ANALYTICS DASHBOARD", ColorHeader, HeaderFontSize, "Arial Black", Corner);
   
   CreateLbl(PREFIX + "subtitle", PanelX + 30, y + 58,
            "Integrated System | Real-Time Analysis | Professional Grade",
            ColorInfo, LabelFontSize, "Arial", Corner);
   
   // Control buttons
   CreateBtn(PREFIX + "refresh", PanelX + MainPanelWidth - 430, y + 25, 120, 40,
            "REFRESH", ColorText, C'55,65,81', Corner);
   
   CreateBtn(PREFIX + "minimize", PanelX + MainPanelWidth - 300, y + 25, 120, 40,
            "MINIMIZE", ColorText, C'55,65,81', Corner);
   
   // Module toggle buttons
   color risk_btn_color = show_risk_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_risk", PanelX + MainPanelWidth - 170, y + 25, 140, 40,
            show_risk_panel ? "HIDE RISK" : "SHOW RISK", ColorText, risk_btn_color, Corner);
   
   y += 100;
   
   color scenario_btn_color = show_scenario_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_scenario", PanelX + 30, y, 200, 40,
            show_scenario_panel ? "HIDE SCENARIO" : "SHOW SCENARIO", 
            ColorText, scenario_btn_color, Corner);
   
   color visual_btn_color = show_visual_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_visual", PanelX + 250, y, 200, 40,
            show_visual_panel ? "HIDE VISUAL" : "SHOW VISUAL",
            ColorText, visual_btn_color, Corner);
   
   color alerts_btn_color = show_alerts_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_alerts", PanelX + 470, y, 200, 40,
            show_alerts_panel ? "HIDE ALERTS" : "SHOW ALERTS",
            ColorText, alerts_btn_color, Corner);
   
   y += 50;
   
   // Second row of module buttons
   color journal_btn_color = show_journal_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_journal", PanelX + 30, y, 200, 40,
            show_journal_panel ? "HIDE JOURNAL" : "SHOW JOURNAL",
            ColorText, journal_btn_color, Corner);
   
   color sizing_btn_color = show_sizing_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_sizing", PanelX + 250, y, 200, 40,
            show_sizing_panel ? "HIDE SIZING" : "SHOW SIZING",
            ColorText, sizing_btn_color, Corner);
   
   color correlation_btn_color = show_correlation_panel ? ColorInfo : C'55,65,81';
   CreateBtn(PREFIX + "toggle_correlation", PanelX + 470, y, 200, 40,
            show_correlation_panel ? "HIDE CORRELATION" : "SHOW CORRELATION",
            ColorText, correlation_btn_color, Corner);
   
   y += 50;
   
   // Portfolio Summary
   CreateRect(PREFIX + "summary_bg", PanelX + 30, y, MainPanelWidth - 60, 140,
              ColorPanel, true, Corner);
   
   int curr_y = y + 20;
   CreateLbl(PREFIX + "summary_title", PanelX + 50, curr_y,
            "PORTFOLIO SUMMARY", ColorHeader, MetricFontSize, "Arial Black", Corner);
   curr_y += MetricFontSize + 25;
   
   int col1 = PanelX + 70;
   int col2 = PanelX + 400;
   int col3 = PanelX + 730;
   int col4 = PanelX + 1060;
   
   // Equity
   CreateLbl(PREFIX + "equity_label", col1, curr_y,
            "Equity:", ColorText, LabelFontSize, "Arial", Corner);
   string equity_text = StringFormat("$%.2f", portfolio.equity);
   CreateLbl(PREFIX + "equity_value", col1, curr_y + LabelFontSize + 5,
            equity_text, ColorInfo, LabelFontSize + 8, "Arial Black", Corner);
   
   // Total P&L
   CreateLbl(PREFIX + "pl_label", col2, curr_y,
            "Total P&L:", ColorText, LabelFontSize, "Arial", Corner);
   string pl_text = StringFormat("$%.2f", portfolio.total_realized_pl + portfolio.total_floating_pl);
   color pl_color = (portfolio.total_realized_pl + portfolio.total_floating_pl >= 0) ? ColorGood : ColorDanger;
   CreateLbl(PREFIX + "pl_value", col2, curr_y + LabelFontSize + 5,
            pl_text, pl_color, LabelFontSize + 8, "Arial Black", Corner);
   
   // Margin Level
   CreateLbl(PREFIX + "margin_label", col3, curr_y,
            "Margin Level:", ColorText, LabelFontSize, "Arial", Corner);
   string margin_text = StringFormat("%.1f%%", portfolio.margin_level);
   color margin_color = (portfolio.margin_level > 300) ? ColorGood :
                       (portfolio.margin_level > 200) ? ColorWarning : ColorDanger;
   CreateLbl(PREFIX + "margin_value", col3, curr_y + LabelFontSize + 5,
            margin_text, margin_color, LabelFontSize + 8, "Arial Black", Corner);
   
   // Active Algos
   CreateLbl(PREFIX + "algos_label", col4, curr_y,
            "Active Algos:", ColorText, LabelFontSize, "Arial", Corner);
   string algos_text = IntegerToString(algo_count);
   CreateLbl(PREFIX + "algos_value", col4, curr_y + LabelFontSize + 5,
            algos_text, ColorInfo, LabelFontSize + 8, "Arial Black", Corner);
   
   y += 150;
   
   // Algo List (compact)
   CreateRect(PREFIX + "algos_bg", PanelX + 30, y, MainPanelWidth - 60, 280,
              ColorPanel, true, Corner);
   
   curr_y = y + 15;
   CreateLbl(PREFIX + "algos_title", PanelX + 50, curr_y,
            "ACTIVE ALGORITHMS", ColorHeader, LabelFontSize + 4, "Arial Black", Corner);
   curr_y += LabelFontSize + 20;
   
   // Show top algos (max 6)
   int display_count = MathMin(algo_count, 6);
   for(int i = 0; i < display_count; i++) {
      string algo_line = StringFormat("%s | %.2f lots | P&L: $%.2f | Win: %.1f%%",
                                     algos[i].name,
                                     algos[i].total_lots,
                                     algos[i].floating_pl,
                                     algos[i].win_rate);
      
      color line_color = (algos[i].floating_pl >= 0) ? ColorGood : ColorDanger;
      CreateLbl(PREFIX + "algo_" + IntegerToString(i), PanelX + 60, curr_y,
               algo_line, line_color, LabelFontSize, "Arial", Corner);
      curr_y += LabelFontSize + 8;
   }
   
   if(algo_count > 6) {
      CreateLbl(PREFIX + "more_algos", PanelX + 60, curr_y,
               StringFormat("... and %d more algos", algo_count - 6),
               C'156,163,175', LabelFontSize - 1, "Arial", Corner);
   }
   
   return y + 290;
}

//+------------------------------------------------------------------+
//| Render Minimized                                                  |
//+------------------------------------------------------------------+
void RenderMinimized() {
   int h = 80;
   CreateRect(PREFIX + "mini_bg", PanelX, PanelY, 650, h, ColorPanel, true, Corner);
   
   CreateLbl(PREFIX + "mini_title", PanelX + 20, PanelY + 15,
            "PORTFOLIO ANALYTICS", ColorHeader, LabelFontSize + 4, "Arial Black", Corner);
   
   string status = StringFormat("%.0f algos | Equity: $%.2f | P&L: $%.2f",
                               algo_count, portfolio.equity,
                               portfolio.total_realized_pl + portfolio.total_floating_pl);
   CreateLbl(PREFIX + "mini_status", PanelX + 20, PanelY + 45,
            status, ColorText, LabelFontSize + 2, "Arial", Corner);
   
   CreateBtn(PREFIX + "maximize", PanelX + 500, PanelY + 20, 130, 40,
            "MAXIMIZE", ColorText, C'55,65,81', Corner);
}

//+------------------------------------------------------------------+
//| Status Bar                                                         |
//+------------------------------------------------------------------+
void RenderStatusBar() {
   int y = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) - 35;
   string status = StringFormat("Last Update: %s | Risk: %s | Scenario: %s | Visual: %s | Alerts: %s | Journal: %s | Sizing: %s | Correlation: %s",
                               TimeToString(last_update, TIME_SECONDS),
                               show_risk_panel ? "ON" : "OFF",
                               show_scenario_panel ? "ON" : "OFF",
                               show_visual_panel ? "ON" : "OFF",
                               show_alerts_panel ? "ON" : "OFF",
                               show_journal_panel ? "ON" : "OFF",
                               show_sizing_panel ? "ON" : "OFF",
                               show_correlation_panel ? "ON" : "OFF");
   CreateLbl(PREFIX + "status", PanelX + 30, y,
            "> " + status, ColorInfo, LabelFontSize, "Arial", Corner);
}

//+------------------------------------------------------------------+
