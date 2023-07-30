
plot_gene_expression <- function(expression_file, clinical_file, gene_name, clinical_variable, NA_char=c("NA", "N/A", "N.A", "N.A.")) {
  library(ggplot2)
  library(dplyr)
  library(ggsignif)
  library(ggpubr)
  
  
  # Read the expression dataset
  expression_data <- read.csv(expression_file, header = TRUE, row.names = 1, na.strings = NA_char)
  
  # Read the clinical dataset
  clinical_data <- read.csv(clinical_file, header = TRUE, row.names = 1, na.strings = NA_char)
  
  # Transpose the expression data
  expression_data <- t(expression_data)
  
  # Check if the gene name exists in the expression dataset
  if (!gene_name %in% colnames(expression_data)) {
    stop("Gene '", gene_name, "' not found in the expression dataset.")
  }
  
  # Check if the clinical variable name exists in the clinical dataset
  if (!clinical_variable %in% colnames(clinical_data)) {
    stop("Clinical variable '", clinical_variable, "' not found in the clinical dataset.")
  }
  
  # Merge the expression and clinical datasets
  merged_data <- merge(expression_data, clinical_data, by = "row.names")
  
  # Rename the merged dataset columns
  colnames(merged_data)[1] <- "Sample"
  
  # Select the gene of interest and the clinical variable
  selected_data <- merged_data %>% select(Sample, gene_name, clinical_variable)
  
  #change all character to factor
    selected_data <- mutate_if(selected_data, is.character, as.factor)

  # Check the type of the clinical variable
  variable_type <- class(selected_data[[clinical_variable]])
  
  # Plot the gene expression based on the clinical variable type
  if (variable_type == "factor") {
       p <- ggplot(selected_data, aes_string(x = clinical_variable, y = gene_name)) +
      geom_violin() +
      geom_boxplot(width = 0.2, fill = "white", alpha = 0) +
      labs(x = clinical_variable, y = paste("Expression of", gene_name)) +
      ggtitle("Violin Plot")+
         theme_classic()
  
     #add median labels
     median_labels <- selected_data %>%
       group_by(.data[[clinical_variable]] ) %>%
       summarise(median_value = median(.data[[gene_name]])) %>%
       mutate(median_label = paste0("Median: ", round(median_value, 2)))

     p <- p + geom_text(data = median_labels,
                        aes(label = median_label),
                        y = max(selected_data[[gene_name]]) + 0.3,
                        size = 3)
    
    
    #print(p)
  } else if (variable_type == "numeric") {
  p <- ggplot(selected_data, aes_string(x = clinical_variable, y = gene_name)) +
      geom_point() +
      geom_smooth(method = "lm", se = TRUE) +
      labs(x = clinical_variable, y = paste("Expression of", gene_name)) +
      ggtitle("Scatter Plot with Regression Line and Confidence Interval")+
    theme_classic()
    
    # Add correlation coefficient and p-value to the title
    corr_coef <- cor(selected_data[[gene_name]], selected_data[[clinical_variable]])
    p_value <- cor.test(selected_data[[gene_name]], selected_data[[clinical_variable]])$p.value
    title_text <- paste("Scatter Plot with Regression Line and Confidence Interval\n",
                        "Correlation Coefficient:", round(corr_coef, 2), "\n",
                        "p-value:", format(p_value, scientific = TRUE, digits = 2))
    p <- p + labs(title = title_text)
    #print(p)
  } else {
    stop("Clinical variable '", clinical_variable, "' must be either a factor or numeric.")
  }
  return(p)
}


# expression_file <- "/Users/amritkoirala/Library/CloudStorage/OneDrive-BaylorCollegeofMedicine/Amrit_projects/GI-Metabiome/WGS_Results/12202022/inputs/Omics/metaphlan3.bacteria.relab.csv"
# 
# clinical_file <- "/Users/amritkoirala/Library/CloudStorage/OneDrive-BaylorCollegeofMedicine/Amrit_projects/GI-Metabiome/WGS_Results/12202022/inputs/metadata/Metadata_filtered_AK08212022.csv"  
# 
# gene_name <- "Dorea_formicigenerans"
# #clinical_variable <- "Viral.GE"
# clinical_variable <- "Serum.IgA"
# 
# plot_gene_expression(expression_file, clinical_file, gene_name, clinical_variable, NA_char = c("NT"))
