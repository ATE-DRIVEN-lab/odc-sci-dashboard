
        $(function(){
          function _setNavbarDark() {
            var nav = document.querySelector('nav.navbar');
            if (nav) nav.setAttribute('data-bs-theme', 'dark');
          }
          _setNavbarDark();
          $(document).one('shiny:idle', _setNavbarDark);
        });
