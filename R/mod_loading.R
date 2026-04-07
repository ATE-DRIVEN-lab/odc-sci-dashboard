# R/mod_loading.R

loading_overlay_ui <- function() {
  tagList(
    div(
      id = "odc-loading-overlay",
      div(
        style = "text-align: center;",
        div(
          class = "odc-app-logo-splash-wrap",
          tags$img(
            class = "odc-app-logo odc-app-logo--splash",
            src   = LOGO_SRC,
            alt   = ""
          )
        ),
        div(
          style = "color:#fff; font-size:2.09rem; font-weight:800; letter-spacing:-0.8px; margin-bottom:6px;",
          "ODC\u2013SCI"
        ),
        div(
          style = "color:rgba(255,255,255,0.65); font-size:0.99rem; margin-bottom:36px;",
          "Open Data Commons for Spinal Cord Injury"
        ),
        div(
          class = "odc-loader-dots",
          tags$span(), tags$span(), tags$span()
        ),
        div(
          style = "color:rgba(255,255,255,0.5); font-size:0.88rem; margin-top:14px; font-weight:600;",
          "Loading data\u2026"
        )
      )
    ),

    tags$script(HTML("
      (function(){
        var el = document.getElementById('odc-loading-overlay');
        var hidden = false;

        function hide() {
          if (hidden) return;
          hidden = true;
          if (el) el.classList.add('hidden');
        }

        function tryHide() {
          if (hidden) return;
          var ready =
            document.querySelector('.dual-range-wrap') !== null &&
            document.querySelector('.custom-selector') !== null;
          if (ready) hide();
          // else stay visible; next shiny:idle will call tryHide() again
        }

        $(document).on('shiny:idle', tryHide);
        setTimeout(hide, 25000); // hard fallback — never hang forever
      })();
    "))
  )
}
