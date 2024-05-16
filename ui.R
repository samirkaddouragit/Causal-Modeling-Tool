#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#
?is.not
library(shiny)
library(DT)
library(bslib)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  theme=bs_theme(bootswatch='darkly'),
  titlePanel('Causal Modeling Tool'),
  sidebarLayout(
  sidebarPanel(
  fileInput('file',label='Please upload a CSV file',accept=c('text/csv','text/comma-separated-values','.csv')),
  selectInput('dep_var',label='Choose an outcome variable (Only continuous variables)',''),
  selectInput('treat_var',label='Choose a treatment variable (Only numerical variables)',''),
  selectInput('controls',label='Select your control variables (Minimum 2 if running a Causal Forest)',choices='',multiple = TRUE),
  selectInput('model',label='Choose a model to run (Warning: Matching and Causal Forest may take a while)',choices = list('Regression Adjustment','Matching','Instrumental Variable Regression','Causal Forest')),
  selectInput('IV',label='If IV regression chosen, please choose an instrumental variable',choices=''),
  actionButton('button','Run model')),
  mainPanel(
  textOutput('finaltext'),
  conditionalPanel(condition="input.model=='Causal Forest'",
  tableOutput('finalframe')),
  plotOutput('finalplot')))
  
)
)
