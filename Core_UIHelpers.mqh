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

#endif // CORE_UI_HELPERS_MQH
