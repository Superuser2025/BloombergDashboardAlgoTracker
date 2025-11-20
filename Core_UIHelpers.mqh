//+------------------------------------------------------------------+
//|                                           Core_UIHelpers.mqh     |
//|                                     Portfolio Command Center     |
//|                               UI Primitives & Helper Functions   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "5.00"
#property strict

#ifndef CORE_UI_HELPERS_MQH
#define CORE_UI_HELPERS_MQH

//+------------------------------------------------------------------+
//| Create Label                                                      |
//+------------------------------------------------------------------+
void CreateLbl(string name, int x, int y, string text, color clr, int size, string font, 
               ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Create Rectangle (FULLY OPAQUE - Alpha 255)                      |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int w, int h, color clr, bool back,
                ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   // CRITICAL: No alpha parameter - always fully opaque (255)
}

//+------------------------------------------------------------------+
//| Create Button                                                     |
//+------------------------------------------------------------------+
void CreateBtn(string name, int x, int y, int w, int h, string text, 
               color txt_clr, color bg_clr, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt_clr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

//+------------------------------------------------------------------+
//| Create Feature Button (Larger, styled)                           |
//+------------------------------------------------------------------+
void CreateFeatureBtn(string name, int x, int y, int w, int h, string text,
                      bool is_active, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   color bg = is_active ? C'16,185,129' : C'55,65,81';  // Green if active, gray if inactive
   color txt = is_active ? C'255,255,255' : C'156,163,175';
   
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, is_active ? C'34,197,94' : C'75,85,99');
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

//+------------------------------------------------------------------+
//| Create Separator Line                                            |
//+------------------------------------------------------------------+
void CreateLine(string name, int x, int y, int width, color clr,
                ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 2);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Update Label Text                                                 |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text) {
   if(ObjectFind(0, name) >= 0) {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   }
}

//+------------------------------------------------------------------+
//| Update Label Color                                                |
//+------------------------------------------------------------------+
void UpdateLabelColor(string name, color clr) {
   if(ObjectFind(0, name) >= 0) {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

//+------------------------------------------------------------------+
//| Update Button State                                               |
//+------------------------------------------------------------------+
void UpdateButtonState(string name, bool pressed) {
   if(ObjectFind(0, name) >= 0) {
      ObjectSetInteger(0, name, OBJPROP_STATE, pressed);
   }
}

//+------------------------------------------------------------------+
//| Cleanup Objects by Prefix                                         |
//+------------------------------------------------------------------+
void CleanupObjects(string prefix) {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, prefix) == 0) {
         ObjectDelete(0, name);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if Button is Pressed                                        |
//+------------------------------------------------------------------+
bool IsButtonPressed(string name) {
   if(ObjectFind(0, name) >= 0) {
      return (bool)ObjectGetInteger(0, name, OBJPROP_STATE);
   }
   return false;
}

//+------------------------------------------------------------------+
//| Reset Button                                                       |
//+------------------------------------------------------------------+
void ResetButton(string name) {
   if(ObjectFind(0, name) >= 0) {
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
   }
}

//+------------------------------------------------------------------+
//| Create Status Indicator                                           |
//+------------------------------------------------------------------+
void CreateStatusIndicator(string name, int x, int y, bool is_good, string label,
                           ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   color indicator_color = is_good ? C'34,197,94' : C'239,68,68';
   
   // Create circle indicator
   CreateRect(name + "_dot", x, y, 12, 12, indicator_color, false, corner);
   
   // Create label
   CreateLbl(name + "_lbl", x + 20, y - 2, label, C'229,231,235', 11, "Arial", corner);
}

//+------------------------------------------------------------------+
//| Create Progress Bar                                               |
//+------------------------------------------------------------------+
void CreateProgressBar(string name, int x, int y, int w, int h, double percentage,
                       color bar_color, color bg_color, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   // Background
   CreateRect(name + "_bg", x, y, w, h, bg_color, true, corner);
   
   // Progress fill
   int fill_width = (int)(w * MathMin(percentage, 100.0) / 100.0);
   if(fill_width > 0) {
      CreateRect(name + "_fill", x, y, fill_width, h, bar_color, false, corner);
   }
   
   // Border
   CreateRect(name + "_border", x, y, w, h, C'107,114,128', false, corner);
}

//+------------------------------------------------------------------+
//| Create Badge (Small colored label)                                |
//+------------------------------------------------------------------+
void CreateBadge(string name, int x, int y, string text, color bg_color, color txt_color,
                 ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   int badge_width = StringLen(text) * 8 + 16;
   int badge_height = 22;

   CreateRect(name + "_bg", x, y, badge_width, badge_height, bg_color, false, corner);
   CreateLbl(name + "_txt", x + 8, y + 3, text, txt_color, 10, "Arial Bold", corner);
}

//+------------------------------------------------------------------+
//| Create Card with Depth (Modern UI)                               |
//+------------------------------------------------------------------+
void CreateCard(string name, int x, int y, int w, int h, color bg_color, color border_color,
                ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   // Subtle shadow effect (darker layer beneath)
   CreateRect(name + "_shadow", x + 3, y + 3, w, h, C'10,15,25', true, corner);

   // Main card background
   CreateRect(name + "_bg", x, y, w, h, bg_color, true, corner);

   // Border (thin overlay)
   CreateRect(name + "_border_top", x, y, w, 1, border_color, false, corner);
   CreateRect(name + "_border_bottom", x, y + h - 1, w, 1, border_color, false, corner);
   CreateRect(name + "_border_left", x, y, 1, h, border_color, false, corner);
   CreateRect(name + "_border_right", x + w - 1, y, 1, h, border_color, false, corner);
}

//+------------------------------------------------------------------+
//| Create Metric Card (Number + Label + Trend)                      |
//+------------------------------------------------------------------+
void CreateMetricCard(string name, int x, int y, int w, int h, string value, string label,
                      color value_color, bool show_trend, double trend_pct, color bg_color,
                      ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   // Card with depth
   CreateCard(name, x, y, w, h, bg_color, C'55,65,81', corner);

   // Label at top (small, subtle) - MORE SPACE
   CreateLbl(name + "_label", x + 20, y + 15, label, C'156,163,175', 10, "Arial", corner);

   // Large value in center - INCREASED SPACING
   CreateLbl(name + "_value", x + 20, y + 42, value, value_color, 26, "Arial Black", corner);

   // Trend indicator at bottom - MUCH MORE SPACE
   if(show_trend) {
      string trend_text = StringFormat("%+.1f%%", trend_pct);
      color trend_color = (trend_pct >= 0) ? C'34,197,94' : C'239,68,68';
      string arrow = (trend_pct >= 0) ? "▲ " : "▼ ";
      CreateLbl(name + "_trend", x + 20, y + 82, arrow + trend_text, trend_color, 10, "Arial Bold", corner);
   }
}

//+------------------------------------------------------------------+
//| Create Circular Gauge (0-100 score)                              |
//+------------------------------------------------------------------+
void CreateGauge(string name, int x, int y, double value, string label, color good_clr,
                 color warn_clr, color danger_clr, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   int gauge_size = 80;
   int bar_count = 20;
   int bar_height = 4;

   // Background circle
   CreateRect(name + "_bg", x, y, gauge_size, gauge_size, C'31,41,55', false, corner);

   // Draw gauge bars in semi-circle
   for(int i = 0; i < bar_count; i++) {
      double pct = (double)i / bar_count * 100.0;
      color bar_color;

      if(pct <= value) {
         if(value >= 70) bar_color = good_clr;
         else if(value >= 40) bar_color = warn_clr;
         else bar_color = danger_clr;
      } else {
         bar_color = C'55,65,81';  // Inactive
      }

      // Simple horizontal bars stacked vertically for gauge effect
      int bar_y = y + gauge_size - 10 - (i * 3);
      int bar_width = (int)(gauge_size * 0.8);
      CreateRect(name + "_bar_" + IntegerToString(i), x + 8, bar_y, bar_width, 2, bar_color, false, corner);
   }

   // Value in center
   string value_text = StringFormat("%.0f", value);
   CreateLbl(name + "_value", x + gauge_size/2 - 15, y + gauge_size/2 - 10, value_text,
             C'229,231,235', 24, "Arial Black", corner);

   // Label below
   CreateLbl(name + "_label", x + 10, y + gauge_size + 5, label, C'156,163,175', 10, "Arial", corner);
}

//+------------------------------------------------------------------+
//| Create Mini Sparkline (Simple trend visualization)               |
//+------------------------------------------------------------------+
void CreateSparkline(string name, int x, int y, int width, double &values[], int count,
                     color line_color, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   if(count < 2) return;

   int height = 30;
   double max_val = values[0];
   double min_val = values[0];

   // Find range
   for(int i = 0; i < count; i++) {
      if(values[i] > max_val) max_val = values[i];
      if(values[i] < min_val) min_val = values[i];
   }

   double range = max_val - min_val;
   if(range == 0) range = 1;

   // Draw simple bars
   int bar_width = width / count;
   for(int i = 0; i < count; i++) {
      int bar_height = (int)((values[i] - min_val) / range * height);
      int bar_x = x + (i * bar_width);
      int bar_y = y + height - bar_height;

      CreateRect(name + "_bar_" + IntegerToString(i), bar_x, bar_y, bar_width - 1, bar_height,
                line_color, false, corner);
   }
}

//+------------------------------------------------------------------+
//| Create Risk Heat Map Cell                                        |
//+------------------------------------------------------------------+
void CreateHeatCell(string name, int x, int y, int size, double value, double max_value,
                    ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   // Color based on intensity (0 = green, max = red)
   double intensity = MathMin(value / max_value, 1.0);

   color cell_color;
   if(intensity < 0.33)
      cell_color = C'34,197,94';   // Green
   else if(intensity < 0.66)
      cell_color = C'251,191,36';  // Yellow
   else
      cell_color = C'239,68,68';   // Red

   CreateRect(name, x, y, size, size, cell_color, false, corner);
}

//+------------------------------------------------------------------+
//| Create Stylish Header with Icon                                  |
//+------------------------------------------------------------------+
void CreateSectionHeader(string name, int x, int y, int width, string title, string icon,
                        color title_color, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   // Header background with gradient effect (using layered rectangles)
   CreateRect(name + "_bg1", x, y, width, 50, C'31,41,55', true, corner);
   CreateRect(name + "_bg2", x, y, width, 2, title_color, false, corner);

   // Icon
   CreateLbl(name + "_icon", x + 15, y + 12, icon, title_color, 20, "Arial Black", corner);

   // Title
   CreateLbl(name + "_title", x + 50, y + 15, title, title_color, 18, "Arial Black", corner);

   // Bottom border
   CreateRect(name + "_border", x, y + 49, width, 1, C'55,65,81', false, corner);
}

//+------------------------------------------------------------------+
//| Create Alert Badge with Pulse Effect                             |
//+------------------------------------------------------------------+
void CreateAlertBadge(string name, int x, int y, int count, color alert_color,
                     ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   if(count == 0) return;

   int size = 24;

   // Outer glow
   CreateRect(name + "_glow", x - 2, y - 2, size + 4, size + 4, alert_color, true, corner);

   // Main circle
   CreateRect(name + "_bg", x, y, size, size, alert_color, false, corner);

   // Count
   string count_text = (count > 99) ? "99+" : IntegerToString(count);
   CreateLbl(name + "_count", x + 6, y + 4, count_text, clrWhite, 11, "Arial Black", corner);
}

//+------------------------------------------------------------------+
//| Create Performance Attribution Bar                               |
//+------------------------------------------------------------------+
void CreateAttributionBar(string name, int x, int y, int width, string algo_name,
                         double contribution_pct, color bar_color,
                         ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   int bar_height = 30;
   int bar_width = (int)(width * MathAbs(contribution_pct) / 100.0);

   // Background
   CreateRect(name + "_bg", x, y, width, bar_height, C'31,41,55', true, corner);

   // Bar
   if(contribution_pct >= 0) {
      CreateRect(name + "_bar", x + width/2, y + 5, bar_width, bar_height - 10, bar_color, false, corner);
   } else {
      CreateRect(name + "_bar", x + width/2 - bar_width, y + 5, bar_width, bar_height - 10, bar_color, false, corner);
   }

   // Label
   CreateLbl(name + "_label", x + 10, y + 8, algo_name, C'229,231,235', 11, "Arial", corner);

   // Percentage
   string pct_text = StringFormat("%+.1f%%", contribution_pct);
   CreateLbl(name + "_pct", x + width - 60, y + 8, pct_text, bar_color, 11, "Arial Bold", corner);
}

//+------------------------------------------------------------------+
//| Create Action Button with Icon                                   |
//+------------------------------------------------------------------+
void CreateActionBtn(string name, int x, int y, int w, int h, string icon, string text,
                    color bg_color, color text_color, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, icon + " " + text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'75,85,99');
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

//+------------------------------------------------------------------+
//| Create Risk Score Indicator                                      |
//+------------------------------------------------------------------+
void CreateRiskIndicator(string name, int x, int y, double risk_score, string label,
                        ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   color risk_color;
   string risk_text;

   if(risk_score <= 30) {
      risk_color = C'34,197,94';
      risk_text = "LOW";
   } else if(risk_score <= 60) {
      risk_color = C'251,191,36';
      risk_text = "MODERATE";
   } else {
      risk_color = C'239,68,68';
      risk_text = "HIGH";
   }

   int badge_width = 100;
   CreateRect(name + "_bg", x, y, badge_width, 28, risk_color, false, corner);
   CreateLbl(name + "_text", x + 10, y + 6, risk_text, clrWhite, 12, "Arial Black", corner);
   CreateLbl(name + "_label", x + badge_width + 10, y + 8, label, C'156,163,175', 11, "Arial", corner);
}

//+------------------------------------------------------------------+
//| Create Close Button (X) for Modal Panels                         |
//+------------------------------------------------------------------+
void CreateCloseButton(string name, int panel_x, int panel_y, int panel_width,
                      ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
   int btn_size = 40;
   int btn_x = panel_x + panel_width - btn_size - 15;
   int btn_y = panel_y + 15;

   // Create actual BUTTON object (clickable)
   // name already has trailing underscore (e.g., "VISUAL_"), so just add "close_bg"
   ObjectCreate(0, name + "close_bg", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_XDISTANCE, btn_x);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_YDISTANCE, btn_y);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_XSIZE, btn_size);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_YSIZE, btn_size);
   ObjectSetString(0, name + "close_bg", OBJPROP_TEXT, "✕");
   ObjectSetInteger(0, name + "close_bg", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name + "close_bg", OBJPROP_BGCOLOR, C'239,68,68');
   ObjectSetInteger(0, name + "close_bg", OBJPROP_BORDER_COLOR, C'220,50,50');
   ObjectSetInteger(0, name + "close_bg", OBJPROP_FONTSIZE, 20);
   ObjectSetString(0, name + "close_bg", OBJPROP_FONT, "Arial Black");
}

//+------------------------------------------------------------------+

#endif // CORE_UI_HELPERS_MQH
