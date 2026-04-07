FROM rocker/shiny:4.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

RUN install2.r --error \
    shiny \
    bslib \
    plotly \
    DT \
    dplyr \
    stringr \
    bsicons \
    writexl \
    jsonlite \
    ggplot2 \
    scales \
    htmltools \
    htmlwidgets \
    && rm -rf /tmp/downloaded_packages

RUN useradd -m -u 1000 user
WORKDIR /home/user/app

COPY --chown=user . .

RUN test -f data/public_data.csv && test -f data/dict_data.csv \
    || (echo 'Missing data/*.csv — Space needs tracked CSVs in repo' && exit 1)

RUN rm -rf renv renv.lock .Rprofile .Rproj.user .git rsconnect .claude

RUN mkdir -p data \
    && chown -R user:user /home/user/app

USER user

EXPOSE 7860

CMD ["R", "-e", "shiny::runApp('.', host='0.0.0.0', port=7860)"]
