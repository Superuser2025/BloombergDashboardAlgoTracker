//+------------------------------------------------------------------+
//|                      Module_CorrelationMatrix_Render.mqh         |
//|                   CORRELATION MATRIX RENDERING                   |
//|                  Correlation Display Functions                   |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Intelligence"
#property version   "1.00"
#property strict

#ifndef MODULE_CORRELATION_MATRIX_RENDER_MQH
#define MODULE_CORRELATION_MATRIX_RENDER_MQH

#include "Core_DataStructures.mqh"
#include "Module_CorrelationMatrix.mqh"
#include "Core_UIHelpers.mqh"

//+------------------------------------------------------------------+
//| Render Correlation Matrix Panel                                   |
//+------------------------------------------------------------------+
void RenderCorrelationMatrixPanel(CorrelationMatrixData &data,
                                  int start_y,
                                  int panel_width,
                                  ENUM_BASE_CORNER corner,
                                  int header_size,
                                  int metric_size,
                                  int label_size,
                                  color header_color,
                                  color good_color,
                                  color warning_color,
                                  color danger_color,
                                  color info_color,
                                  color bg_color,
                                  color panel_color,
                                  color text_color) {
   
   const string OBJ_PREFIX = "CORR_";
   int panel_x = 20;
   int y = start_y;
   
   int total_height = 1200;
   
   // Main background
   CreateRect(OBJ_PREFIX + "main_bg", panel_x, y, panel_width, total_height, bg_color, true, corner);
   
   // Header
   CreateRect(OBJ_PREFIX + "header_bg", panel_x, y, panel_width, 70, panel_color, true, corner);
   
   CreateLbl(OBJ_PREFIX + "title", panel_x + 20, y + 15,
            "CORRELATION MATRIX", header_color, header_size, "Arial Black", corner);
   
   CreateLbl(OBJ_PREFIX + "subtitle", panel_x + 20, y + 45,
            "Portfolio Diversification Analysis | Algo & Symbol Correlations",
            info_color, label_size, "Arial", corner);
   
   y += 80;
   
   // Diversification Score
   y = RenderDiversificationScore(data, panel_x, y, panel_width, corner,
                                  header_color, good_color, warning_color, 
                                  danger_color, panel_color, text_color, 
                                  label_size, metric_size);
   
   y += 20;
   
   // Portfolio Metrics
   y = RenderPortfolioMetrics(data, panel_x, y, panel_width, corner,
                              header_color, panel_color, text_color, label_size);
   
   y += 20;
   
   // Algo Correlation Matrix
   if(data.algo_count >= 2) {
      y = RenderAlgoMatrix(data, panel_x, y, panel_width, corner,
                          header_color, panel_color, text_color, label_size);
      y += 20;
   }
   
   // Symbol Correlation Matrix
   if(data.symbol_count >= 2) {
      y = RenderSymbolMatrix(data, panel_x, y, panel_width, corner,
                            header_color, panel_color, text_color, label_size);
      y += 20;
   }
   
   // Recommendations
   RenderRecommendations(data, panel_x, y, panel_width, corner,
                        header_color, good_color, warning_color, danger_color,
                        panel_color, text_color, label_size);
}

//+------------------------------------------------------------------+
//| Render Diversification Score                                      |
//+------------------------------------------------------------------+
int RenderDiversificationScore(CorrelationMatrixData &data, int x, int y, int width,
                               ENUM_BASE_CORNER corner, color header_color,
                               color good_color, color warning_color, color danger_color,
                               color panel_color, color text_color, int label_size, int metric_size) {
   
   const string OBJ_PREFIX = "CORR_";
   
   CreateRect(OBJ_PREFIX + "score_bg", x + 20, y, width - 40, 160,
              data.diversification_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "score_title", x + 40, curr_y,
            "DIVERSIFICATION SCORE", C'255,255,255', label_size + 4, "Arial Black", corner);
   curr_y += label_size + 25;
   
   // Large score display
   CreateLbl(OBJ_PREFIX + "score_value", x + 60, curr_y,
            StringFormat("%.0f / 100", data.diversification_score), C'255,255,255',
            metric_size + 10, "Arial Black", corner);
   
   curr_y += metric_size + 20;
   
   // Rating
   CreateLbl(OBJ_PREFIX + "score_rating", x + 60, curr_y,
            "Rating: " + data.diversification_rating, C'255,255,255',
            label_size + 3, "Arial Bold", corner);
   
   curr_y += label_size + 15;
   
   // Status
   string status = data.needs_rebalancing ? 
                  "⚠ Rebalancing Recommended" : "✓ Well Diversified";
   CreateLbl(OBJ_PREFIX + "score_status", x + 60, curr_y,
            status, C'255,255,255', label_size + 1, "Arial", corner);
   
   return y + 160;
}

//+------------------------------------------------------------------+
//| Render Portfolio Metrics                                          |
//+------------------------------------------------------------------+
int RenderPortfolioMetrics(CorrelationMatrixData &data, int x, int y, int width,
                          ENUM_BASE_CORNER corner, color header_color,
                          color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "CORR_";
   
   CreateRect(OBJ_PREFIX + "metrics_bg", x + 20, y, width - 40, 100,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "metrics_title", x + 40, curr_y,
            "CORRELATION METRICS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   int col1 = x + 80;
   int col2 = x + 350;
   int col3 = x + 620;
   int col4 = x + 890;
   
   CreateLbl(OBJ_PREFIX + "avg_lbl", col1, curr_y,
            "Avg Correlation:", text_color, label_size, "Arial", corner);
   CreateLbl(OBJ_PREFIX + "avg_val", col1, curr_y + label_size + 5,
            StringFormat("%.3f", data.avg_correlation), header_color, 
            label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "max_lbl", col2, curr_y,
            "Max Correlation:", text_color, label_size, "Arial", corner);
   color max_color = (data.max_correlation > 0.7) ? C'239,68,68' : C'34,197,94';
   CreateLbl(OBJ_PREFIX + "max_val", col2, curr_y + label_size + 5,
            StringFormat("%.3f", data.max_correlation), max_color,
            label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "high_lbl", col3, curr_y,
            "High Corr Pairs:", text_color, label_size, "Arial", corner);
   color high_color = (data.high_correlation_count > 0) ? C'239,68,68' : C'34,197,94';
   CreateLbl(OBJ_PREFIX + "high_val", col3, curr_y + label_size + 5,
            IntegerToString(data.high_correlation_count), high_color,
            label_size + 2, "Arial Bold", corner);
   
   CreateLbl(OBJ_PREFIX + "conc_lbl", col4, curr_y,
            "Concentration Risk:", text_color, label_size, "Arial", corner);
   color conc_color = (data.concentration_risk > 50) ? C'239,68,68' : C'34,197,94';
   CreateLbl(OBJ_PREFIX + "conc_val", col4, curr_y + label_size + 5,
            StringFormat("%.0f%%", data.concentration_risk), conc_color,
            label_size + 2, "Arial Bold", corner);
   
   return y + 100;
}

//+------------------------------------------------------------------+
//| Render Algo Correlation Matrix                                    |
//+------------------------------------------------------------------+
int RenderAlgoMatrix(CorrelationMatrixData &data, int x, int y, int width,
                    ENUM_BASE_CORNER corner, color header_color,
                    color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "CORR_";
   
   int matrix_size = data.algo_count;
   int cell_size = 80;
   int matrix_height = 100 + (matrix_size * cell_size);
   
   CreateRect(OBJ_PREFIX + "algo_bg", x + 20, y, width - 40, matrix_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "algo_title", x + 40, curr_y,
            "ALGORITHM CORRELATIONS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 30;
   
   int matrix_x = x + 200;
   int matrix_y = curr_y;
   
   // Column headers
   for(int i = 0; i < matrix_size; i++) {
      CreateLbl(OBJ_PREFIX + "algo_hdr_" + IntegerToString(i), 
               matrix_x + (i * cell_size) + 10, matrix_y - 20,
               data.algo_names[i], text_color, label_size - 2, "Arial Bold", corner);
   }
   
   // Row headers and cells
   for(int i = 0; i < matrix_size; i++) {
      // Row header
      CreateLbl(OBJ_PREFIX + "algo_row_" + IntegerToString(i),
               x + 60, matrix_y + (i * cell_size) + 25,
               data.algo_names[i], text_color, label_size - 1, "Arial Bold", corner);
      
      for(int j = 0; j < matrix_size; j++) {
         int cell_x = matrix_x + (j * cell_size);
         int cell_y = matrix_y + (i * cell_size);
         
         if(i == j) {
            // Diagonal - always 1.0
            CreateRect(OBJ_PREFIX + "algo_cell_" + IntegerToString(i) + "_" + IntegerToString(j),
                      cell_x, cell_y, cell_size - 2, cell_size - 2,
                      C'74,222,128', true, corner);
            CreateLbl(OBJ_PREFIX + "algo_val_" + IntegerToString(i) + "_" + IntegerToString(j),
                     cell_x + 20, cell_y + 28, "1.00", text_color,
                     label_size, "Arial Bold", corner);
         } else {
            // Find correlation pair
            double corr = 0;
            color cell_color = C'25,30,40';
            
            for(int p = 0; p < data.algo_pair_count; p++) {
               if((data.algo_pairs[p].name1 == data.algo_names[i] && 
                   data.algo_pairs[p].name2 == data.algo_names[j]) ||
                  (data.algo_pairs[p].name1 == data.algo_names[j] && 
                   data.algo_pairs[p].name2 == data.algo_names[i])) {
                  corr = data.algo_pairs[p].correlation;
                  cell_color = data.algo_pairs[p].cell_color;
                  break;
               }
            }
            
            CreateRect(OBJ_PREFIX + "algo_cell_" + IntegerToString(i) + "_" + IntegerToString(j),
                      cell_x, cell_y, cell_size - 2, cell_size - 2,
                      cell_color, true, corner);
            CreateLbl(OBJ_PREFIX + "algo_val_" + IntegerToString(i) + "_" + IntegerToString(j),
                     cell_x + 15, cell_y + 28, StringFormat("%.2f", corr),
                     text_color, label_size - 1, "Arial Bold", corner);
         }
      }
   }
   
   return y + matrix_height;
}

//+------------------------------------------------------------------+
//| Render Symbol Correlation Matrix                                  |
//+------------------------------------------------------------------+
int RenderSymbolMatrix(CorrelationMatrixData &data, int x, int y, int width,
                      ENUM_BASE_CORNER corner, color header_color,
                      color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "CORR_";
   
   int matrix_size = data.symbol_count;
   int cell_size = 80;
   int matrix_height = 100 + (matrix_size * cell_size);
   
   CreateRect(OBJ_PREFIX + "sym_bg", x + 20, y, width - 40, matrix_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "sym_title", x + 40, curr_y,
            "SYMBOL CORRELATIONS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 30;
   
   int matrix_x = x + 200;
   int matrix_y = curr_y;
   
   // Column headers
   for(int i = 0; i < matrix_size; i++) {
      CreateLbl(OBJ_PREFIX + "sym_hdr_" + IntegerToString(i),
               matrix_x + (i * cell_size) + 10, matrix_y - 20,
               data.symbol_names[i], text_color, label_size - 2, "Arial Bold", corner);
   }
   
   // Row headers and cells
   for(int i = 0; i < matrix_size; i++) {
      CreateLbl(OBJ_PREFIX + "sym_row_" + IntegerToString(i),
               x + 60, matrix_y + (i * cell_size) + 25,
               data.symbol_names[i], text_color, label_size - 1, "Arial Bold", corner);
      
      for(int j = 0; j < matrix_size; j++) {
         int cell_x = matrix_x + (j * cell_size);
         int cell_y = matrix_y + (i * cell_size);
         
         if(i == j) {
            CreateRect(OBJ_PREFIX + "sym_cell_" + IntegerToString(i) + "_" + IntegerToString(j),
                      cell_x, cell_y, cell_size - 2, cell_size - 2,
                      C'74,222,128', true, corner);
            CreateLbl(OBJ_PREFIX + "sym_val_" + IntegerToString(i) + "_" + IntegerToString(j),
                     cell_x + 20, cell_y + 28, "1.00", text_color,
                     label_size, "Arial Bold", corner);
         } else {
            double corr = 0;
            color cell_color = C'25,30,40';
            
            for(int p = 0; p < data.symbol_pair_count; p++) {
               if((data.symbol_pairs[p].name1 == data.symbol_names[i] && 
                   data.symbol_pairs[p].name2 == data.symbol_names[j]) ||
                  (data.symbol_pairs[p].name1 == data.symbol_names[j] && 
                   data.symbol_pairs[p].name2 == data.symbol_names[i])) {
                  corr = data.symbol_pairs[p].correlation;
                  cell_color = data.symbol_pairs[p].cell_color;
                  break;
               }
            }
            
            CreateRect(OBJ_PREFIX + "sym_cell_" + IntegerToString(i) + "_" + IntegerToString(j),
                      cell_x, cell_y, cell_size - 2, cell_size - 2,
                      cell_color, true, corner);
            CreateLbl(OBJ_PREFIX + "sym_val_" + IntegerToString(i) + "_" + IntegerToString(j),
                     cell_x + 15, cell_y + 28, StringFormat("%.2f", corr),
                     text_color, label_size - 1, "Arial Bold", corner);
         }
      }
   }
   
   return y + matrix_height;
}

//+------------------------------------------------------------------+
//| Render Recommendations                                            |
//+------------------------------------------------------------------+
int RenderRecommendations(CorrelationMatrixData &data, int x, int y, int width,
                         ENUM_BASE_CORNER corner, color header_color,
                         color good_color, color warning_color, color danger_color,
                         color panel_color, color text_color, int label_size) {
   
   const string OBJ_PREFIX = "CORR_";
   
   int panel_height = 80 + (data.recommendation_count * 35);
   
   CreateRect(OBJ_PREFIX + "rec_bg", x + 20, y, width - 40, panel_height,
              panel_color, true, corner);
   
   int curr_y = y + 15;
   CreateLbl(OBJ_PREFIX + "rec_title", x + 40, curr_y,
            "RECOMMENDATIONS", header_color, label_size + 3, "Arial Black", corner);
   curr_y += label_size + 25;
   
   for(int i = 0; i < data.recommendation_count; i++) {
      string rec = data.recommendations[i];
      
      color rec_color = text_color;
      if(StringFind(rec, "✓") >= 0) rec_color = good_color;
      if(StringFind(rec, "⚠") >= 0) rec_color = warning_color;
      if(StringFind(rec, "🔄") >= 0) rec_color = warning_color;
      if(StringFind(rec, "💡") >= 0) rec_color = C'59,130,246';
      
      CreateLbl(OBJ_PREFIX + "rec_" + IntegerToString(i), x + 60, curr_y,
               rec, rec_color, label_size + 1, "Arial", corner);
      curr_y += 30;
   }
   
   return y + panel_height;
}

//+------------------------------------------------------------------+
//| Clear Correlation Matrix Panel                                    |
//+------------------------------------------------------------------+
void ClearCorrelationMatrixPanel() {
   const string OBJ_PREFIX = "CORR_";
   CleanupObjects(OBJ_PREFIX);
}

//+------------------------------------------------------------------+

#endif // MODULE_CORRELATION_MATRIX_RENDER_MQH
