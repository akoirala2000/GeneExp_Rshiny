
library(shiny)
library(ggplot2)
library(dplyr)
library(ggsignif)

# Define the UI
ui <- fluidPage(
  titlePanel("Gene Expression Analysis"),
  sidebarLayout(
    sidebarPanel(
      fileInput("expression_file", "Expression Dataset (CSV)"),
      fileInput("clinical_file", "Clinical Dataset (CSV)"),
      selectInput("gene_name", "Gene Name", choices= NULL),
      selectInput("clinical_variable", "Clinical Variable", choices = NULL),
      textInput("NA_char_input", "NA Characters (separated by commas)", value = "NA,N/A,N.A,N.A."),
      actionButton("plot_button", "Plot",),
      downloadButton("download_plot", "Download Plot")
    ),
    mainPanel(
      plotOutput("gene_plot")
    )
  )
)

# Define the server
server <- function(input, output, session) {
  # Read the expression and clinical datasets
  source("geneExpression.R", local = TRUE)
  gene_expression_data <- reactive({
    req(input$expression_file)
    read.csv(input$expression_file$datapath, header = TRUE, row.names = 1)
  })
  
  clinical_data <- reactive({
    req(input$clinical_file)
    read.csv(input$clinical_file$datapath, header = TRUE, row.names = 1)
  })
  # Update the gene choices based on the selected expression data
  observeEvent(gene_expression_data(), {
    updateSelectInput(
      session,
      "gene_name",
      choices = row.names(gene_expression_data())
    )
  })
  
  # Update the clinical variable choices based on the selected clinical dataset
  observeEvent(clinical_data(), {
    updateSelectInput(
      session,
      "clinical_variable",
      choices = colnames(clinical_data())
    )
  })
  # Plot the gene expression and display the plot
  output$gene_plot <- renderPlot({
    req(input$plot_button, gene_expression_data(), clinical_data(), input$gene_name, input$clinical_variable)
    
    # Call the plot_gene_expression function with the provided inputs
    plot <- plot_gene_expression(
      expression_file = input$expression_file$datapath,
      clinical_file = input$clinical_file$datapath,
      gene_name = input$gene_name,
      clinical_variable = input$clinical_variable,
      NA_char = strsplit(input$NA_char_input, ",")[[1]]
    )
  print(plot)
  })
  
  # Download the plot as PNG when the download button is clicked
  output$download_plot <- downloadHandler(
    filename = function() {
      paste("gene_expression_plot_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      ggsave(file, plot_gene_expression(
        expression_file = input$expression_file$datapath,
        clinical_file = input$clinical_file$datapath,
        gene_name = input$gene_name,
        clinical_variable = input$clinical_variable,
        NA_char = strsplit(input$NA_char_input, ",")[[1]]
      ), device = "png", dpi = 300)
    }
  )
  
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
