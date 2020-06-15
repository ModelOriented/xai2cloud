---
title: 'xai2cloud: the R package for automated cloud deployment of machine learning models with XAI REST API'
tags:
  - Cloud
  - eXplainable Artificial Intelligence
  - Interpretable Machine Learning
  - predictive modelling
  - model deployment
authors:
  - name: Adam Rydelek
    orcid: 0000-0002-4805-9015
    affiliation: 1
  - name: Przemyslaw Biecek
    orcid: 0000-0001-8423-1823
    affiliation: 1
    
affiliations:
 - name: Faculty of Mathematics and Information Science, Warsaw University of Technology
   index: 1
date: 21 May 2020
bibliography: paper.bib
---

# Introduction

Machine learning models are utilized in nearly every field of science and business. 
The growing number of excellent libraries for R and Python simplify and automate the process of building of  ML models. It is becoming easier and easier to build a model locally, but sharing the model is still a challenge. Model deployment is an essential part of the life cycle of any machine learning model [@crisp10]. The goal of the `xai2cloud` library is to automate the last mile of model life-cycle. The library works in a model-agnostic fashion, independently of the internal model structure. It transforms any predictive model into a RESTfull service automatically deployed in the cloud.

Created API allows not only to query the model on new points but also generates instance-level explanations of the reasons behind the value of a specific prediction.
With the arising interest in eXplainable Artificial Intelligence (XAI) many tools for exploring machine learning models emerged. Among the most popular solutions `SHAP` [@Lundberg:2017], `DALEX` [@Biecek:2018] or the `What-If` [@Wexler:2019]. These libraries are very useful for building or debugging a model, but they are not integrated with the model deployment on production. The `xai2cloud` package treats explainability as an integral component of model functioning, offering the most popular XAI methods available with the same interface as model predictions.

There are also other libraries in R to explore the model, such as `modelStudio` [@Baniecki:2019] (for precalculated statistics for serverless exploration), `archivist` [@Archivist:2017] (a database of meta-features of objects allowing for easier model searching and governance), `trackr` [@Becker] (focused on the reproducibility of models), `modelDown` [@Romaszko2019] (automatically generated documentation for the model in HTML static page), `workflowr` (automation of model construction) and many others. 
But `xai2could` is the only package that allows you to interact with a live model and share models that are not frozen copies but working functions that can be combined with other cloud-based solutions.


# The xai2cloud package

The `xai2cloud` is built on top of the `plumber` [@Plumber:2020] and `analogsea` [@Analogsea:2020] R packages. Those tools are combined with the tools for model exploration and explanation such as `ingredients` [@Biecek:2020] and `iBreakDown` [@Gosiewska:2019]. It is easier to explore results visually than by raw numbers [@Alexandra:2010] so the `xai2could` API generates also visual summaries.

The `xai2cloud` package is developed for R [@R:2020] but the proposed architecture can also be replicated in other languages. 

Despite cloud-based solutions being commonly associated with difficult setup and high entry threshold, xai2cloud is created with simplicity in mind. Configuration of the cloud environment is a one-time activity that is thoroughly explained at the package's [website](https://modeloriented.github.io/xai2cloud/). 

The solution used for cloud computing is [DigitalOcean](https://www.digitalocean.com/). The platform is affordable and presents an intuitive website interface to keep track of all currently running droplets. Droplet is a name given by DigitalOcean for their Linux servers running on top of cloud-based hardware. Configuration of a new server is done entirely through R using the setup feature of the `xai2cloud` package which creates a new droplet with R version 3.6.3 and all the required packages already installed.

After the initial setup, the deployment process is instant and intuitive. The package can deploy any model wrapped into an explainer with one R function. Explainers are adapters available for predictive models created using the DALEX package. Deployed model is subsequently available on the server with XAI features enabling thorough exploration.

![Architecture of two main functions in `xai2cloud` package. `do_setup` configures new cloud environment, `deploy_explainer` adds model to the configured droplet.](xai2cloud_diagram.png)

# Deployment example

The `xai2cloud` R package can be installed from GitHub using devtools with:

`devtools::install_github('ModelOriented/xai2cloud')`

Droplet setup is needed to start working with model deployment. The quick setup guide is available at the package's [website](https://modeloriented.github.io/xai2cloud/). Assuming the configuration has been completed, the deployment of any predictive models is rapid and effortless. Below is a code sample attached which produces an [example](http://167.172.203.24/exp_name/__swagger__/).

* 1. Create a model
```r
library("ranger")
library("DALEX")
model <- ranger(survived~., data = titanic_imputed)
```

* 2. Wrap it into a DALEX explainer
```r
exp_name <- explain(model, 
                    data = titanic_imputed[,-8],
                    y = titanic_imputed$survived)
```

* 3. Check droplet's ID
```r
library("analogsea")
my_droplets <- droplets()
```

* 4. Choose the correct droplets name - 'xai2cloudExamples' in this case
```r
specific_droplet <- my_droplets$xai2cloudExamples
droplet_id <- specific_droplet$id
```

* 5. Deploy the explainer to the selected droplet
```r
library("xai2cloud")
deploy_explainer(exp_name, model_package = 'ranger',
                 droplet=droplet_id, port=8070, title="JOSS Example")
```


# Features overview

The deployed explainer is active as an application compliant to the representational state transfer architecture operating on the droplet's server [@REST:2000]. It hosts five POST and GET hooks in total enabling the user to explore the model and its predictions. The features provided include not only a basic prediction of inputted data but also local model explanations:

![An example of Break Down (1), SHAP (2) and Ceteris Paribus (3) plots generated by the API for a Titanic ranger model \label{fig:plots}](plots2.png)

\newpage

* The most basic feature provided by the API is the prediction hook. It returns an instant model's answer for any given observation.

* SHAP [@Lundberg:2017] plots offer another way of explaining the output of machine learning models by using classic Shapley values from game theory. The hook creates a plot enabling the user to take a look at each variable's contribution with a broader perspective.

* Break Down [@Gosiewska:2019] plots present the contribution of each variable to the prediction. There are two hooks associated with this feature, one creates the plot and returns it as an image, the other one is a description consisting of crucial information that can be gathered from the Break-Down plot and is returned as a string.

* Ceteris Paribus plots from the `ingredients` package [@Biecek:2018] present model responses around a single point in the feature space. It enables the user to view possible changes in model predictions allowing for changes in a single variable while keeping all other features constant. The results are also available as both a chart and a text description summing up crucial conclusions.

# Usage

![Basic illustration of Swagger UI created for an example Titanic model using xai2cloud \label{fig:swagger}](api2.png)

The RESTful API created by xai2cloud can be utilized in various ways. There is a built-in Swagger User Interface (\autoref{fig:swagger}) available at the droplet's server. Swagger is a set of open-source tools that enhance REST application building process. One of the tools available is Swagger UI which presents interactive API documentation. Therefore it can be used as a basic standalone solution for sharing predictive models results. It can be then easily used in much more complex projects. The xai2cloud package can deploy multiple models on one droplet without any further configuration enables the users to create applications gathering model data from the whole organization. The package is built in a way to encourage using it as an external data source for projects concerning predictive modelling.

# Summary

The `xai2cloud` package offers a new perspective on sharing the predictive model's. It enables cloud deployment of artificial intelligence solutions while reducing the setup technological entry threshold to the minimum. Enabling users to view and understand the predictive model is the end goal of explainable artificial intelligence. This objective can be achieved using built-in local explanation features and plots from the `xai2cloud` package. The package is in constant development and the features list is going to expand over time. Updates and more examples can be found on [GitHub ModelOriented/xai2cloud repository](https://github.com/ModelOriented/xai2cloud) of the project and the [modeloriented.github.io/xai2cloud website](https://modeloriented.github.io/xai2cloud/).


# Acknowledgements

Work on this package was financially supported by the NCBR Grant POIR.01.01.01-00-0328/17.

# References
