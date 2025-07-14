# Note: Base image not visible in docker history output
# This appears to be based on Ubuntu (likely ubuntu:22.04 or similar)
# You may need to adjust the FROM instruction based on your specific base image
FROM ubuntu:22.04

# Copy certificate file
COPY ZScalerRootCA.crt /usr/local/share/ca-certificates/hp_root_ca.crt

# Update CA certificates
RUN /bin/sh -c update-ca-certificates

# Set environment variable for non-interactive debian frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install Python and virtualenv
RUN /bin/sh -c apt-get update && apt-get install -y python3.10 virtualenv

# Install R and related dependencies
RUN /bin/sh -c apt-get update && apt-get install --yes software-properties-common apt-transport-https && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && gpg -a --export E298A3A825C0D65DFD57CBB65171661| sudo apt-key add - && add-apt-repository -y "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && apt-get update && apt-get install --yes libssl-dev r-base r-base-dev && add-apt-repository -r "deb [arch=amd64,i386] ht.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && apt-key del E298A3A825C0D65DFD57CBB651716619E084DAB9 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install R packages
RUN /bin/sh -c R -e "options(repos = list(CRAN = 'https://packagemanager.posit.co/cran/latest')); install.packages(c('hwriter', 'TeachingDemos', 'htmltools'))" && R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/hwriterPlus/hwriterPtar.gz', repos=NULL, type='source')" && R -e "install.packages('Rserve', repos='http://rforge.net/')"

# Copy R profile configuration
COPY Rprofile.site /usr/lib/R/etc/Rprofile.site

# Install gdebi and wget
RUN /bin/sh -c apt-get update && apt-get install -y gdebi-core && apt-get install -y wget && apt-get install -y gdebi-core

# Download and install RStudio Server
RUN /bin/sh -c wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2022.12.0-353-amd64.deb && gdebi -n rstudio-server-2022.12.0-353-amd64.deb && rstudio-server version

# Install additional system packages
RUN /bin/sh -c apt-get update && apt-get install -y curl fuse openssh-server && rm -rf /var/lib/apt/lists/*

# Install additional R packages with remotes
RUN /bin/sh -c Rscript -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos='http://cran.us.r-project.org')" && Rscript -e "remotes::install_version('Matrix', '1.6-5', repos = 'https://cran.rstudio.com')" && Rscript -e install_version('cli', '3.6.1', repos = 'https://cran.rstudio.com')" && Rscript -e "remotes::install_github('ebenmichael/augsynth')" && Rscript -e "remotes::install_version('MarketMatching', '1.2.0', dependencies = TRUE, repos = 'https://cran.rstudio.com')" &&  "remotes::install_github('facebookincubator/GeoLift', force = TRUE)"

# Set user environment variable
ENV USER=root