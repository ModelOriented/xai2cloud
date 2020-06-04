# xai2cloud

<!-- badges: start -->
  [![Travis build status](https://travis-ci.org/ModelOriented/xai2cloud.svg?branch=master)](https://travis-ci.org/ModelOriented/xai2cloud)
[![Codecov test coverage](https://codecov.io/gh/ModelOriented/xai2cloud/branch/master/graph/badge.svg)](https://codecov.io/gh/ModelOriented/xai2cloud?branch=master)
[![R build status](https://github.com/ModelOriented/xai2cloud/workflows/R-CMD-check/badge.svg)](https://github.com/ModelOriented/xai2cloud/actions?query=workflow%3AR-CMD-check)
<!-- badges: end -->

## Overview

The `xai2cloud` package **automates the process of deploying model explainers to the cloud**. Create a web API from an DALEX explainer and deploy it with just one R function. Deployment can be done either locally or directly to the **DigitalOcean's cloud**, which can be achievied after a quick setup. The whole step by step guide can be found below.

## Examples

- [x] [Titanic (Random Forest) explainer](http://167.172.203.24/titanic_explainer/__swagger__/)
- [x] [Apartments (Linear Model) explainer](http://167.172.203.24/apartments_explainer/__swagger__/)
- [x] [Covid-19 (gbm) explainer](http://167.71.120.77/covid19_explainer/__swagger__/)

## Installation

```
# Install the development version from GitHub:
devtools::install_github("ModelOriented/xai2cloud")
```

## Functionality

The main function is called **deploy_explainer** which creates a REST API and a swagger for it based on the explainer. If you have an *DigitalOcean* account and a droplet with installed R 3.5+ it can also deploy the model directly to the cloud. At the time it supports five post/get functionalities:

- Predict a result
- Break Down plot
- SHAP values plot
- Ceteris Paribus plot
- Break Down description
- Ceteris Paribus description

## How to use?

If you already have a *DigitalOcean's* droplet with an appropriate R version (3.5+) or just want to plumb the explainer locally, skip the first section below.

### How to create a new *DigitalOcean* droplet?

1. If you don't have an account on *DigitalOcean*, create one [here.](https://m.do.co/c/c07558eaca11)
2. Install development version of **plumber** R package by using ```devtools::install_github("trestletech/plumber")```
3. Install **analogsea** R package by using ```install.packages("analogsea")```
4. Install **ssh** R package by using ```install.packages("ssh")```
5. [Create an SSH key](https://help.github.com/en/enterprise/2.17/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?fbclid=IwAR3E66nCkq5cS6BSSHvgv-tzFa9MjWL37bUgRz3DKwglTO8Zn_t6tmKwvRo)
6. [Deploy the SSH key to DigitalOcean](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/to-account/)
6. Run ```analogsea::droplets()``` to check the connection to your *DigitalOcean's* account.
7. Run ```xai2cloud::do_setup(model_package = "name of package used to create the model - eg. randomForest, gbm, stats")```. This will start a virtual machine (a new droplet) and install R with develompent version of *plumber* and all needed packages: DALEX, iBreakDown, ingredients, ggplot2 and the package specified in **model_package** parameter.
8. Access port 8000 on your droplet's IP. If you see a response from *plumber*, everything works so far.


### How to plumb the explainer?

Now you are ready to use the function **deploy_explainer**. It requires only two parameters to deploy locally:
- **exp_name** - name of an *.rda* file containing an explainer in your working directory or an explainer object.
- **model_package** - name of the package used to create the explained model. The name must be accurate, letter case is important.

In order to deploy the explainer directly to the cloud, set up:
- **droplet** - numeric - your *DigitalOcean's* droplet number (check it by typing ```analogsea::droplets```). If you wish to plumb it locally, set it to ```NA```.
- **port** - numeric - port that you would like to deploy your explainer to.

Additional parameters:
- **deploy** - boolean telling whether the plumber file is run on set port. If set to false, plumber file will be created but not run.
- **title** - title to be seen in Swagger.

#### *DigitalOcean*
After using the **deploy_explainer** function with appropriate droplet's ID, you can access the web API at:
your_droplet_ip/your_explainers_name/__swagger__/

#### *Local*
If you didn't put your droplet's number, you have started the plumber's swagger locally. You can access it at:
http://127.0.0.1:port/__swagger__/

