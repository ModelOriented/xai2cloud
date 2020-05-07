# Modified code from plumber package to ensure newest R installation with apprioprate packages
# nocov start

checkAnalogSea <- function(){
  if (!requireNamespace("analogsea", quietly = TRUE)) {
    stop("The analogsea package is not available but is required in order to use the provisioning functions. Please install analogsea.",
         call. = FALSE)
  }
}

#' Provision a modified DigitalOcean plumber server
#'
#' Create (if required), install the necessary prerequisites with all
#' corresponding packages needed to deploy an explainer.
#' Deploy a sample plumber application on a DigitalOcean virtual machine.
#' You may sign up for a Digital Ocean account [here](https://m.do.co/c/add0b50f54c4).
#' This command is idempotent, so feel free to run it on a single server multiple times.
#' This command is a modified version of plumber's do_provision() which installs newer R
#' version and packages needed for deploying an explainer with xai2cloud.
#' @param droplet The DigitalOcean droplet that you want to provision (see [analogsea::droplet()]). If empty, a new DigitalOcean server will be created.
#' @param model_package Name of package used to build the model, eg: "randomForest", "gbm".
#' @param unstable If `FALSE`, will install plumber from CRAN. If `TRUE`, will install the unstable version of plumber from GitHub.
#' @param example If `TRUE`, will deploy an example API named `hello` to the server on port 8000.
#' @param ... Arguments passed into the [analogsea::droplet_create()] function.
#' @details Provisions a Ubuntu 16.04-x64 droplet with the following customizations:
#'  - A recent version of R installed (3.6.3)
#'  - plumber installed globally in the system library
#'  - all necesarry packages to ensure correct explainer plumbing
#'  - An example plumber API deployed at `/var/plumber`
#'  - A systemd definition for the above plumber API which will ensure that the plumber
#'    API is started on machine boot and respawned if the R process ever crashes. On the
#'    server you can use commands like `systemctl restart plumber` to manage your API, or
#'    `journalctl -u plumber` to see the logs associated with your plumber process.
#'  - The `nginx`` web server installed to route web traffic from port 80 (HTTP) to your plumber
#'    process.
#'  - `ufw` installed as a firewall to restrict access on the server. By default it only
#'    allows incoming traffic on port 22 (SSH) and port 80 (HTTP).
#'  - A 4GB swap file is created to ensure that machines with little RAM (the default) are
#'    able to get through the necessary R package compilations.
#' @export
do_setup <- function(droplet, model_package, unstable=FALSE, example=TRUE, ...){
  checkAnalogSea()

  if (missing(droplet)){
    # No droplet provided; create a new server
    message("THIS ACTION COSTS YOU MONEY!")
    message("Provisioning a new server for which you will get a bill from DigitalOcean.")

    createArgs <- list(...)
    createArgs$tags <- c(createArgs$tags, "plumber")
    createArgs$image <- "ubuntu-16-04-x64"

    droplet <- do.call(analogsea::droplet_create, createArgs)

    # Wait for the droplet to come online
    analogsea::droplet_wait(droplet)

    # I often still get a closed port after droplet_wait returns. Buffer for just a bit
    Sys.sleep(25)

    # Refresh the droplet; sometimes the original one doesn't yet have a network interface.
    droplet <- analogsea::droplet(id=droplet$id)
  }

  # Provision
  lines <- droplet_capture(droplet, 'swapon | grep "/swapfile" | wc -l')
  if (lines != "1"){
    analogsea::debian_add_swap(droplet)
  }
  install_new_r(droplet)
  install_plumber(droplet, unstable)
  install_packages(droplet, model_package)
  install_api(droplet)
  install_nginx(droplet)
  install_firewall(droplet)
  if (example){
    do_deploy_api(droplet, "hello", system.file("examples", "10-welcome", package="plumber"), port=8000, forward=TRUE)
  }
  message("Droplet setup succesful.\nYou can now use deploy_explainer() function with this droplet's id.")
  invisible(droplet)
}

install_plumber <- function(droplet, unstable){
  # Satisfy sodium's requirements
  analogsea::debian_apt_get_install(droplet, "libsodium-dev")
  analogsea::debian_apt_get_install(droplet, "libcurl4-openssl-dev")
  analogsea::debian_apt_get_install(droplet, "libgit2-dev")
  analogsea::debian_apt_get_install(droplet, "libssl-dev")
  analogsea::debian_apt_get_install(droplet, "libxml2-dev")
  analogsea::install_r_package(droplet, "devtools", repo="https://cran.rstudio.com")
  # install github development version of plumber
  analogsea::droplet_ssh(droplet, "Rscript -e \"devtools::install_github('rstudio/plumber')\"")
}

install_packages <- function(droplet, model_package){
  # install cran versions of required packages
  analogsea::install_r_package(droplet, "DALEX")
  analogsea::install_r_package(droplet, "iBreakDown")
  analogsea::install_r_package(droplet, "ingredients")
  analogsea::install_r_package(droplet, "ggplot2")
  # install cran version of package used to create model
  analogsea::install_r_package(droplet, model_package)
}

#' Captures the output from running some command via SSH
#' @noRd
droplet_capture <- function(droplet, command){
  tf <- tempdir()
  randName <- paste(sample(c(letters, LETTERS), size=10, replace=TRUE), collapse="")
  tff <- file.path(tf, randName)
  on.exit({
    if (file.exists(tff)) {
      file.remove(tff)
    }
  })
  analogsea::droplet_ssh(droplet, paste0(command, " > /tmp/", randName))
  analogsea::droplet_download(droplet, paste0("/tmp/", randName), tf)
  analogsea::droplet_ssh(droplet, paste0("rm /tmp/", randName))
  lin <- readLines(tff)
  lin
}

install_api <- function(droplet){
  analogsea::droplet_ssh(droplet, "mkdir -p /var/plumber")
  example_plumber_file <- system.file("examples", "10-welcome", "plumber.R", package="plumber")
  if (nchar(example_plumber_file) < 1) {
    stop("Could not find example 10-welcome plumber file", call. = FALSE)
  }
  analogsea::droplet_upload(
    droplet,
    local = example_plumber_file,
    remote = "/var/plumber/",
    verbose = TRUE)
}

install_firewall <- function(droplet){
  analogsea::droplet_ssh(droplet, "ufw allow http")
  analogsea::droplet_ssh(droplet, "ufw allow ssh")
  analogsea::droplet_ssh(droplet, "ufw -f enable")
}

install_nginx <- function(droplet){
  analogsea::debian_apt_get_install(droplet, "nginx")
  analogsea::droplet_ssh(droplet, "rm -f /etc/nginx/sites-enabled/default") # Disable the default site
  analogsea::droplet_ssh(droplet, "mkdir -p /var/certbot")
  analogsea::droplet_ssh(droplet, "mkdir -p /etc/nginx/sites-available/plumber-apis/")
  analogsea::droplet_upload(droplet, local=system.file("server", "nginx.conf", package="plumber"),
                            remote="/etc/nginx/sites-available/plumber")
  analogsea::droplet_ssh(droplet, "ln -sf /etc/nginx/sites-available/plumber /etc/nginx/sites-enabled/")
  analogsea::droplet_ssh(droplet, "systemctl reload nginx")
}

install_new_r <- function(droplet){
  analogsea::droplet_ssh(droplet, "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9")
  analogsea::droplet_ssh(droplet, "echo 'deb https://cran.rstudio.com/bin/linux/ubuntu xenial-cran35/' >> /etc/apt/sources.list.d/cran.list")
  # TODO: use the analogsea version once https://github.com/sckott/analogsea/issues/139 is resolved
  #analogsea::debian_apt_get_update(droplet)
  analogsea::droplet_ssh(droplet, "sudo apt-get update -qq")
  analogsea::droplet_ssh(droplet, 'sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade')

  analogsea::debian_install_r(droplet)
}
# nocov end
