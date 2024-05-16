#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(DT)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(ivreg)
library(grf)
library(MatchIt)
library(marginaleffects)
library(chk)
library(plotly)
library(ggsignif)
library(ggdag)
library(forcats)
library(dagitty)
library(ggthemes)

Final_tool<-function(data,dep_var,treat_var,control_vars,chosen_model=0,iv=0){
  set.seed(9)
  data<-data[,c(dep_var,treat_var,control_vars,iv)]
  finaltext<-''
  
  
  if(chosen_model=='Regression Adjustment'){
    f<-as.formula(paste(dep_var,'~',treat_var,'+',paste(control_vars,collapse='+')))
    model<-lm(formula=f,data=data)
    if((length(table(data[treat_var]))==2)|(length(table(data[treat_var]))==1)){
      finaltext<-paste(finaltext,paste('Binary treatment chosen, Treatment effect interpreted as follows: if treatment in place, outcome changes by',round(model$coefficients[2],6),' units. '))
    }
    else{
      finaltext<-paste(finaltext,paste('Continous treatment chosen, Treatment effect interpreted as follows: if treatment increases by one unit, outcome changes by',round(model$coefficients[2],6),' units. '))
    }
    if(summary(model)$coefficients[2,4]>0.05){
      finaltext<-paste(finaltext,'Treatment not statistically significant however, please assume a value of 0. ')  
      return(finaltext)
    }
    else if((length(table(data[treat_var]))==2)|(length(table(data[treat_var]))==1)){
      finaltext<-paste(finaltext,'Treatment statistically significant. You may assume the given value. ')
      raplot<-ggplot(data=data,aes(x=data[,treat_var],y=data[,dep_var],group=data[,treat_var]))+geom_boxplot()+ggtitle('Boxplot of the outcome for each group')+theme_economist()+scale_color_economist()+facet_wrap(~data[,treat_var])+xlab(treat_var)+ylab(dep_var)
      return(list(finaltext,raplot))
    }
    else{
      finaltext<-paste(finaltext,'Treatment statistically significant. You may assume the given value. ')
      finalplot<-ggplot(data=data,aes(x=data[,treat_var],y=data[,dep_var]))+geom_smooth(method='lm')+ggtitle(paste('Linear plot of the effect of', treat_var,'on',dep_var,'holding everything else constant'))+xlab(treat_var)+ylab(dep_var)+theme_economist()+scale_color_economist()
      return(list(finaltext,finalplot))
    }
  }
 
  
  
  if(chosen_model=='Matching'){
    if(length(table(data[treat_var]))==2|length(table(data[treat_var]))==1){
      if(nrow(data)>=10000){
        data=sample_n(data,10000)
        finaltext<-paste(finaltext,'large dataset inputted, sample of 10000 taken for computational purposes. ')
      }
      matcher<-matchit(formula=data[,2]~.,data=data,method='full',distance='mahalanobis',estimand='ATE')
      matchdata<-match.data(matcher)
      matchplot<-ggplot(data=matchdata,aes(x=matchdata[,treat_var],y=matchdata[,dep_var],group=matchdata[,treat_var]))+geom_boxplot()+ggtitle('Boxplot of the outcome for each group')+theme_economist()+scale_color_economist()+facet_wrap(~matchdata[,treat_var])+xlab(treat_var)+ylab(dep_var)
      matchermodel<-lm(matchdata[,1]~.,data=matchdata[,-1],weights=weights)
      result<-avg_comparisons(matchermodel,variables=treat_var,wts='weights',newdata=matchdata,vcov = ~subclass)
      finaltext<-paste(finaltext,paste('Average treatment effect estimated, interpreted as follows: If treatment in place, outcome changes by ',round(result$estimate,6),' units. '))
      if(result$p.value>=0.05){
        finaltext<-paste(finaltext,'Treatment not statistically significant however, please assume a value of 0. ')
      }
      else{
        finaltext<-paste(finaltext,'Treatment statistically significant. You may assume the given value. ')  
      }
      return(list(finaltext,matchplot))
    }
    else{
      finaltext<-paste(finaltext,'Matching not available for continuous treatment, please try another model, or choose a binary treatment. ')
      return(finaltext)
    }
  }
  
  
  if(chosen_model=='Instrumental Variable Regression'){
    iv_data<-data[,c(dep_var,treat_var,control_vars,iv)]
    linear_baseline<-summary(lm(data[,1]~.,data=data[,-1]))
    f1<-as.formula(paste(dep_var,'~',treat_var,'+omitted_variables'))
    f2<-as.formula(paste(treat_var,'~',iv,'+omitted_variables'))
    dag<-ggdag(dagify(f1,f2),layout='circle',text_col = 'red')+ggtitle('Instrumental variable DAG')+xlab('')+ylab('')+theme_economist()+scale_color_economist()+theme(axis.line = element_blank(),
                                                                                                                                                                      axis.text.x  = element_blank(),
                                                                                                                                                                      axis.text.y  = element_blank(),
                                                                                                                                                                      axis.ticks= element_blank(),
                                                                                                                                                                      axis.title.x =  element_blank(),
                                                                                                                                                                      axis.title.y=element_blank()
                                                                                                                                                                     )
    finaltext<-paste(finaltext,'Please refer to the DAG to see if this relationship holds, and if your IV is good. You want the IV to be directly related to treatment, related to outcome only through treatment, and unrelated to potentially omitted variables.')
    print(dag)
    if(abs(cov(iv_data[iv],linear_baseline$residuals))<1){
      finaltext<-paste(finaltext,'Exclusion justified. ')
    }
    else{
      finaltext<-paste(finaltext,'Exclusion likely not justified. ')
    }
    if(abs(cov(iv_data[iv],iv_data[treat_var]))>5){
      finaltext<-paste(finaltext,'Relevance justified. ')
    }
    else{
      finaltext<-paste(finaltext,'Relevance likely not justified. ')
    }
    if((abs(cov(iv_data[iv],linear_baseline$residuals))<1)&(abs(cov(iv_data[iv],iv_data[treat_var]))>5)){
      finaltext<-paste(finaltext,'IV potentially a good choice.')
    }
    else{
      finaltext<-paste(finaltext,'IV not recommended.')  
    }
    f<-as.formula(paste(dep_var,'~',treat_var,'+',paste(control_vars,collapse='+'),'|',iv,'+',paste(control_vars,collapse='+')))
    ivmodel<-summary(ivreg(f,data=iv_data))
    if(ivmodel$diagnostics[1,4]>=0.05){
      finaltext<-paste(finaltext,'Instrument weak, please choose another one. ')
    }
    else{
      finaltext<-paste(finaltext,'Strong instrument chosen. ')
    }
    if(ivmodel$diagnostics[2,4]>=0.05){
      finaltext<-paste(finaltext,'No endogeneity problem, no need for an instrumental variable. ')
      if(length(table(data[,treat_var]))==1|length(table(data[,treat_var]))==2){
        finaltext<-paste(finaltext,paste('Binary treatment chosen, interpret as follows: When treatment active, outcome changes by',round(linear_baseline$coefficients[2,1],6),' units. '))  
      }
      else{
        finaltext<-paste(finaltext,paste('Continous treatment chosen, interpret as follows: Every unit increase in the treatment corresponds to an change in the outcome of',round(linear_baseline$coefficients[2,1],6),' units. '))   
      }
    }
    else{
      finaltext<-paste(finaltext,'Use of IV justified. ')
      if(length(table(iv_data[,iv]))==1|length(table(iv_data[,iv]))==2){
        finaltext<-paste(finaltext,paste('Binary treatment chosen, interpret as follows: When treatment active, outcome changes by',round(ivmodel$coefficients[2,1],6),' units.'))  
      }
      else{
        finaltext<-paste(finaltext,paste('Continous treatment chosen, interpret as follows: Every unit increase in the treatment corresponds to a change in the outcome of',round(ivmodel$coefficients[2,1],6),' units.'))   
      }
    }
    return(finaltext)
  }
  
  
  if(chosen_model=='Causal Forest'){
    if(length(table(data[treat_var]))==2|length(table(data[treat_var]))==1){
      sample<-sample.int(n=nrow(data),size=floor(.8*nrow(data)),replace=F)
      train<-data[sample,]
      test<-data[-sample,]
      f<-as.formula(paste(dep_var,'~',treat_var,'+',paste(control_vars,collapse = '+')))
      Xtrain<-model.matrix(lm(data=train,formula=f))[,-c(1,2)]
      Xtest<-model.matrix(lm(data=test,formula=f))[,-c(1,2)]
      causal_train<-causal_forest(X=as.matrix(Xtrain),Y=as.numeric(train[,dep_var]),W=as.numeric(train[,treat_var]),num.trees = 4000)
      importance<-variable_importance(causal_train)
      rownames(importance)<-colnames(Xtrain)
      important_vars<-rownames(importance)[importance>median(importance)]
      tau.hat<-predict(causal_train,X=data.frame(Xtest))$predictions
      causal_test<-causal_forest(X=as.data.frame(Xtest[,important_vars]),Y=as.numeric(test[,dep_var]),W=as.numeric(test[,treat_var]),num.trees = 4000)
      ATE<-average_treatment_effect(causal_test)
      lin_proj<-best_linear_projection(causal_train,A=as.data.frame(Xtrain[,important_vars]),vcov.type ='HC3')
      finaltext<-paste(finaltext,'Top 50% most important variables chosen.')
      Conditions<-list()
      Estimates<-list()
      for(i in 2:length(lin_proj[,1])){
        if(lin_proj[i,4]<0.05){
          Conditions<-append(Conditions,important_vars[i-1])
          Estimates<-append(Estimates,lin_proj[i,1])
        }
      }
      Conditions<-unlist(Conditions)
      Estimates<-unlist(Estimates)
      CATE<-data.frame(Conditions,Estimates)
      if(length(CATE)!=0){
        finaltext<-paste(finaltext,paste('Returning Conditional Average Treatment Effect (CATE). Treatment changes outcome by a minimum of',round(summary(tau.hat)[1],6),'units and a maximum',round(summary(tau.hat)[6],6),'units, with an average of',round(summary(tau.hat)[4],6),'units. '))
        finaltext<-paste(finaltext,'Every unit increase in the following variables changes the treatment effect by their corresponding coefficients. ')
        importanceframe<-data.frame(control_vars,importance)
        importanceplot<-ggplot(data=importanceframe,aes(x=fct_reorder(control_vars,importance),y=importance))+geom_col(fill='blue')+ggtitle('Importance of controls in affecting the CATE')+xlab('Controls')+theme_economist()+scale_color_economist()
        return(list(finaltext,importanceplot,CATE))
      }
      else{
        
        finaltext<-paste(finaltext,paste('Treatment effect not conditional. We estimate on average that treatment will change outcome by',round(ATE[1],6),'units. '))
        return(finaltext)
      }
    }
    else{
      finaltext<-paste(finaltext,'Causal Forest not available for continuous treatment, please try another model, or choose a binary treatment. ')
    }
  }
  
  
}

# Define server logic required to draw a histogram
function(input, output, session) {
  data<-reactive({
    req(input$file)
    data<-read.csv(input$file$datapath)
  })
  observe({
    updateSelectInput(
      session,
      'dep_var',
      choices=names(data())
    )
  })
  observe({
    updateSelectInput(
      session,
      'treat_var',
      choices=names(data())
    )
  })
  observe({
    updateSelectInput(session,'controls',choices=names(data()))
  })
  observe({
    updateSelectInput(
      session,
      'IV',
      choices=names(data())
    )
  })
  finaltext<-eventReactive(input$button,{unlist(Final_tool(data(),input$dep_var,input$treat_var,input$controls,input$model,input$IV)[1])})
  finalplot<-eventReactive(input$button,{Final_tool(data(),input$dep_var,input$treat_var,input$controls,input$model,input$IV)[2]})
  finalframe<-eventReactive(input$button,{data.frame(Final_tool(data(),input$dep_var,input$treat_var,input$controls,input$model,input$IV)[3])})
  output$finaltext<-renderText({finaltext()})
  output$finalplot<-renderPlot({finalplot()})
  output$finalframe<-renderTable({finalframe()})

}

