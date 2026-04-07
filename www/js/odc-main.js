/* www/js/odc-main.js  */

$(document).ready(function () {

  /* ── Generic pill handler ─────────────────────────────────── */
  $(document).on('click', '.custom-selector .custom-pill', function () {
    var $c      = $(this).closest('.custom-selector');
    var inpId   = $c.data('shiny-input');
    if (!inpId) return;

    var $allPill = $c.find('.custom-pill[data-val="All"]');
    var isAll    = $(this).data('val') === 'All';

    if (isAll) {
      // Tap "All" → reset everything to All
      $c.find('.custom-pill').removeClass('active');
      $allPill.addClass('active');
      Shiny.setInputValue(inpId, ['All'], { priority: 'event' });
    } else {
      // Tap a specific pill → remove All, toggle this pill
      $allPill.removeClass('active');
      $(this).toggleClass('active');

      var sel = [];
      $c.find('.custom-pill:not([data-val="All"]).active').each(function () {
        sel.push($(this).data('val'));
      });

      if (sel.length === 0) {
        // Nothing selected → back to All
        $allPill.addClass('active');
        Shiny.setInputValue(inpId, ['All'], { priority: 'event' });
      } else {
        Shiny.setInputValue(inpId, sel, { priority: 'event' });
      }
    }
  });

  /* ── Spine "All" button ───────────────────────────────────── */
  $(document).on('click', '#spine-all-btn', function () {
    $('.spine-region').removeClass('active');
    $('#spine-all-btn').addClass('active');
    Shiny.setInputValue('injury_level_custom', ['All'], { priority: 'event' });
  });

  /* ── Spine SVG click ──────────────────────────────────────── */
  $(document).on('click', '.spine-region', function () {
    var level = $(this).data('level');
    $(this).toggleClass('active');
    _pushSpine();
  });

  function _pushSpine() {
    var sel = [];
    $('.spine-region.active').each(function () { sel.push($(this).data('level')); });
    // Deactivate "All" when specific levels selected, reactivate when none
    if (sel.length) {
      $('#spine-all-btn').removeClass('active');
      Shiny.setInputValue('injury_level_custom', sel, { priority: 'event' });
    } else {
      $('#spine-all-btn').addClass('active');
      Shiny.setInputValue('injury_level_custom', ['All'], { priority: 'event' });
    }
  }

  /* ── Spine tooltip ────────────────────────────────────────── */
  $(document).on('mousemove', '.spine-region', function (e) {
    var lbl = {
      cervical: 'Cervical (C1\u2013C7)',
      thoracic: 'Thoracic (T1\u2013T12)',
      lumbar:   'Lumbar (L1\u2013L5)',
      sacral:   'Sacral / Coccygeal'
    }[$(this).data('level')] || '';
    var off = $('#spine-wrapper').offset();
    if (off) {
      $('#spine-tooltip').text(lbl).css({
        left: e.pageX - off.left + 10,
        top:  e.pageY - off.top  - 16,
        opacity: 1
      });
    }
  }).on('mouseleave', '.spine-region', function () {
    $('#spine-tooltip').css('opacity', 0);
  });

  /* ── Pill-filter inline search ───────────────────────────── */
  $(document).on('input', '.pill-search-input', function () {
    var query   = $(this).val().toLowerCase().trim();
    var id      = $(this).data('pills-id') || $(this).attr('data-pills-id');
    var $extras = $('#' + id + ' .pill-extra');

    $extras.each(function () {
      var $p = $(this);
      if ($p.hasClass('active')) {
        $p.css('display', '');
      } else if (!query) {
        $p.css('display', 'none');
      } else if (String($p.data('val') || $p.attr('data-val')).toLowerCase().indexOf(query) !== -1) {
        $p.css('display', '');
      } else {
        $p.css('display', 'none');
      }
    });
  });

  $(document).on('click', '.custom-selector .pill-extra', function () {
    var pillsId = $(this).closest('.custom-selector').attr('id');
    var $search = $('[data-pills-id="' + pillsId + '"].pill-search-input');
    $search.val('').trigger('input');
  });

  /* ── Search bar: clear button visibility ─────────────────── */
  $(document).on('input change', '.search-bar input', function () {
    $(this).closest('.search-bar').find('.search-bar-clear')
      .css('display', this.value.length ? 'block' : 'none');
  });

  $(document).on('click', '.search-bar-clear', function () {
    var $bar   = $(this).closest('.search-bar');
    var $input = $bar.find('input');
    var inpId  = $input.attr('id');
    $input.val('').trigger('input').trigger('change').focus();
    if (inpId) Shiny.setInputValue(inpId, '', { priority: 'event' });
    $(this).css('display', 'none');
  });

  /* ── Native dual-range slider ─────────────────────────────── */
  function _rsUpdate(wrap) {
    var id   = wrap.getAttribute('data-rs-id');
    var lo   = wrap.querySelector('.dual-range-lo');
    var hi   = wrap.querySelector('.dual-range-hi');
    var fill = wrap.querySelector('.dual-range-fill');
    var badgeLo = document.getElementById(id + '-badge-lo');
    var badgeHi = document.getElementById(id + '-badge-hi');
    if (!lo || !hi) return;

    var min  = parseFloat(lo.min);
    var max  = parseFloat(lo.max);
    var loV  = parseFloat(lo.value);
    var hiV  = parseFloat(hi.value);

    // Prevent handles crossing
    if (loV > hiV) {
      if (document.activeElement === lo) { lo.value = hiV; loV = hiV; }
      else                               { hi.value = loV; hiV = loV; }
    }

    // Update fill bar
    var pctLo = (loV - min) / (max - min) * 100;
    var pctHi = (hiV - min) / (max - min) * 100;
    if (fill) {
      fill.style.left  = pctLo + '%';
      fill.style.width = (pctHi - pctLo) + '%';
    }

    // Move badges to follow their thumb
    var thumbW = 18; // px, matches CSS
    if (badgeLo) {
      badgeLo.textContent = Math.round(loV);
      badgeLo.style.left = 'calc(' + pctLo + '% + ' + ((0.5 - pctLo / 100) * thumbW) + 'px)';
    }
    if (badgeHi) {
      badgeHi.textContent = Math.round(hiV);
      badgeHi.style.left = 'calc(' + pctHi + '% + ' + ((0.5 - pctHi / 100) * thumbW) + 'px)';
    }

    // Push to Shiny
    if (typeof Shiny !== 'undefined')
      Shiny.setInputValue(id, [loV, hiV], { priority: 'event' });
  }

  function _rsInit(wrap) {
    if (wrap._rsInitDone) return;
    var lo = wrap.querySelector('.dual-range-lo');
    var hi = wrap.querySelector('.dual-range-hi');
    if (!lo || !hi) return;
    wrap._rsInitDone = true;

    // Seed initial values from data attributes
    var defLo = parseFloat(wrap.getAttribute('data-rs-lo'));
    var defHi = parseFloat(wrap.getAttribute('data-rs-hi'));
    if (!isNaN(defLo)) lo.value = defLo;
    if (!isNaN(defHi)) hi.value = defHi;

    _rsUpdate(wrap);

    lo.addEventListener('input', function() { _rsUpdate(wrap); });
    hi.addEventListener('input', function() { _rsUpdate(wrap); });
  }

  $(document).on('input', '.dual-range-input', function() {
    var wrap = this.closest('.dual-range-wrap');
    if (wrap) _rsUpdate(wrap);
  });

  // Watch for slider wrappers being added to DOM
  var _rsObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mut) {
      mut.addedNodes.forEach(function(node) {
        if (node.nodeType !== 1) return;
        if (node.classList && node.classList.contains('dual-range-wrap')) {
          _rsInit(node);
        } else if (node.querySelectorAll) {
          node.querySelectorAll('.dual-range-wrap').forEach(_rsInit);
        }
      });
    });
  });
  _rsObserver.observe(document.body, { childList: true, subtree: true });

  // Reset from Shiny server
  Shiny.addCustomMessageHandler('rangeReset', function(msg) {
    var wrap = document.querySelector('.dual-range-wrap[data-rs-id="' + msg.id + '"]');
    if (!wrap) return;
    var lo = wrap.querySelector('.dual-range-lo');
    var hi = wrap.querySelector('.dual-range-hi');
    if (lo) lo.value = msg.lo;
    if (hi) hi.value = msg.hi;
    _rsUpdate(wrap);
  });

  /* ── Scroll-to-top helper ─────────────────────────────────── */
  function _scrollTop(behavior) {
    var main = document.querySelector('.bslib-sidebar-layout > .main');
    var opts = { top: 0, behavior: behavior || 'smooth' };
    if (main) {
      try { main.scrollTo(opts); } catch (e) {}
      main.scrollTop = 0;
    }
    try { window.scrollTo(opts); } catch (e) {}
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
  }

  Shiny.addCustomMessageHandler('scrollToResults', function (msg) {
    _scrollTop('smooth');
  });

  $(document).on('shown.bs.tab', function () {
    _scrollTop('instant');
  });


  var _currentTab = null;

  function _setSidebarForAbout(isAbout) {
    var layout = document.querySelector('.bslib-sidebar-layout');
    if (!layout) return;
    layout.setAttribute('data-collapsible-desktop', isAbout ? 'false' : 'true');
    var aside = layout.querySelector(':scope > .sidebar');
    if (aside) {
      aside.style.setProperty('display', isAbout ? 'none' : '', 'important');
    }
    layout.classList.toggle('sidebar-collapsed', !!isAbout);
  }

  // R sends this on every tab change; e.value is the nav_panel value string
  $(document).on('shiny:inputchanged', function (e) {
    if (e.name === 'main_nav') {
      _currentTab = String(e.value);
      _setSidebarForAbout(_currentTab === 'About');
    }
  });

  // Initial state after Shiny connects
  $(document).one('shiny:idle', function () {
    if (_currentTab !== null) _setSidebarForAbout(_currentTab === 'About');
  });

  Shiny.addCustomMessageHandler('setSidebarVisibility', function (msg) {
    _setSidebarForAbout(msg.hidden);
  });

  /* ── Reset all pill filters ─────── */
  Shiny.addCustomMessageHandler('resetAllPills', function (msg) {
    $('.custom-selector').each(function () {
      var $sel  = $(this);
      var inpId = $sel.data('shiny-input');
      $sel.find('.custom-pill').removeClass('active');
      var $all = $sel.find('.custom-pill[data-val="All"]');
      if ($all.length) $all.addClass('active');
      if (inpId) Shiny.setInputValue(inpId, ['All'], { priority: 'event' });
    });
    $('.spine-region').removeClass('active');
    $('#spine-all-btn').addClass('active');
    Shiny.setInputValue('injury_level_custom', ['All'], { priority: 'event' });
    _clearSearchHint();
  });

  /* ── Clear text search input ────── */
  Shiny.addCustomMessageHandler('clearTextSearch', function (msg) {
    var $input = $('#overview-text_search');
    if ($input.length) {
      $input.val('').trigger('input').trigger('change');
      $input.closest('.search-bar').find('.search-bar-clear').css('display', 'none');
    }
    _clearSearchHint();
  });


  /* Single chip colour — matches mark.hl used in result cards (same green family) */
  var _CHIP = { bg: 'rgba(114,192,44,0.13)', border: 'rgba(114,192,44,0.36)', text: '#2d6908' };

  var _DEFAULT_HINT = '';

  function _clearSearchHint() {
    $('.search-hint').html(_DEFAULT_HINT);
  }

  /* ── Card accordion ─────────────────────────────────────────── */
  var _EASE_DUR = 300; // ms — matches CSS transition duration

  var _SKELETON =
    '<div class="df-skeleton">' +
      '<div class="df-sk-group">' +
        '<div class="df-sk-head"></div>' +
        '<div class="df-sk-row"><div class="df-sk-key"></div><div class="df-sk-val"></div></div>' +
        '<div class="df-sk-row"><div class="df-sk-key"></div><div class="df-sk-val df-sk-s"></div></div>' +
        '<div class="df-sk-row"><div class="df-sk-key"></div><div class="df-sk-val df-sk-m"></div></div>' +
      '</div>' +
      '<div class="df-sk-group">' +
        '<div class="df-sk-head"></div>' +
        '<div class="df-sk-row"><div class="df-sk-key"></div><div class="df-sk-val df-sk-m"></div></div>' +
        '<div class="df-sk-row"><div class="df-sk-key"></div><div class="df-sk-val"></div></div>' +
      '</div>' +
    '</div>';

  function _collapseCard($card) {
    var $exp = $card.find('.ov-card-expand');
    // Pin current height first so CSS transition has a from-value
    $exp.css('max-height', $exp[0].scrollHeight + 'px');
    // Force reflow, then animate to 0
    $exp[0].offsetHeight; // jshint ignore:line
    $exp.css('max-height', '0');
    $card.removeClass('ov-card-open');
    // Clear content after transition
    setTimeout(function () { $exp.empty(); }, _EASE_DUR);
  }

  var _expandAllActive = false;

  window._toggleAllCards = function (btnEl) {
    var $btn  = $(btnEl);
    var $open = $('.dataset-card.ov-card-open');
    if ($open.length > 0) {
      // Collapse all open cards
      $open.each(function () { _collapseCard($(this)); });
      $btn.find('.ov-expand-lbl').text(' Expand all');
      return;
    }
    // Expand all — stagger clicks so Shiny isn't flooded
    _expandAllActive = true;
    $btn.find('.ov-expand-lbl').text(' Collapse all');
    var $titles = $('.ov-card-title');
    $titles.each(function (i) {
      var $t = $(this);
      setTimeout(function () { $t.trigger('click'); }, i * 80);
    });
    setTimeout(function () { _expandAllActive = false; }, $titles.length * 80 + 300);
  };

  window._toggleCardDetail = function (expandId) {
    var $exp  = $('#' + expandId);
    if (!$exp.length) return;
    var $card = $exp.closest('.dataset-card');

    if ($card.hasClass('ov-card-open')) {
      _collapseCard($card);
      return;
    }

    // Close any other open card (skip when expand-all is running)
    if (!_expandAllActive) {
      $('.dataset-card.ov-card-open').each(function () { _collapseCard($(this)); });
    }

    // Open: show skeleton while waiting for R
    $card.addClass('ov-card-open');
    $exp.html(_SKELETON);
    // Animate to skeleton height
    var skH = $exp[0].scrollHeight;
    $exp.css('max-height', skH + 'px');
  };

  /* ── Inject accordion content from R ────────────────────────── */
  Shiny.addCustomMessageHandler('injectCardDetail', function (msg) {
    var $exp  = $('#' + msg.div_id);
    if (!$exp.length) return;
    var $card = $exp.closest('.dataset-card');
    if (!$card.hasClass('ov-card-open')) return;

    // Measure skeleton height, then swap in real content (invisible)
    var curH = $exp[0].scrollHeight;
    $exp.css('max-height', curH + 'px');

    var $inner = $('<div class="df-drawer-dynamic">').html(msg.html);
    $inner.css('opacity', 0);
    $exp.html($inner);

    // Smoothly animate from skeleton height to real content height
    requestAnimationFrame(function () {
      var targetH = $exp[0].scrollHeight;
      $exp.css('max-height', targetH + 'px');
      requestAnimationFrame(function () {
        $inner.css({ transition: 'opacity 0.2s ease', opacity: 1 });
      });
    });

    setTimeout(function () {
      if ($card.hasClass('ov-card-open')) $exp.css('max-height', 'none');
    }, _EASE_DUR + 80);
  });

  $(document).on('keydown', function (e) {
    if (e.key === 'Escape') {
      $('.dataset-card.ov-card-open').each(function () { _collapseCard($(this)); });
    }
  });

  /* ── KPI "Other" hover tooltip ───────────────────────────── */
  $('body').append('<div id="kpi-other-tooltip"></div>');

  $(document).on('mouseenter', '.kpi-row-other', function () {
    var raw = $(this).attr('data-other-items');
    if (!raw) return;
    var data;
    try { data = typeof raw === 'string' ? JSON.parse(raw) : raw; } catch (e) { return; }
    var label = data.label || 'Other';
    var items = data.items || [];
    var esc = function (s) { return $('<span>').text(String(s)).html(); };
    var html = '<div class="kpi-tip-header">' + esc(label) + '</div>';
    items.forEach(function (row) {
      html += '<div class="kpi-tip-row">'
        + '<span class="kpi-tip-label">' + esc(row.item) + '</span>'
        + '<span class="kpi-tip-count">' + row.n + '</span>'
        + '</div>';
    });
    var $tip = $('#kpi-other-tooltip').html(html);
    var r    = this.getBoundingClientRect();
    var tipW = 230;
    var left = r.left;
    if (left + tipW > window.innerWidth) left = window.innerWidth - tipW - 8;
    var top  = r.bottom + 6;
    if (top + $tip.outerHeight(true) > window.innerHeight) top = r.top - $tip.outerHeight(true) - 6;
    $tip.css({ left: left + 'px', top: top + 'px' }).addClass('visible');
  });

  $(document).on('mouseleave', '.kpi-row-other', function () {
    $('#kpi-other-tooltip').removeClass('visible');
  });

  /* R sends 'applySearchHighlight' with the list of search terms */
  Shiny.addCustomMessageHandler('applySearchHighlight', function (msg) {
    if (msg.clear) {
      _clearSearchHint();
      return;
    }

    var terms = msg.terms || [];
    if (!terms.length) { _clearSearchHint(); return; }

    var html = '<span style="font-size:0.7rem; color:#6b7280; margin-right:6px; font-weight:500;">Searching:</span>';
    terms.forEach(function (t) {
      html += '<span style="'
        + 'display:inline-flex; align-items:center;'
        + 'background:' + _CHIP.bg + ';'
        + 'border:1px solid ' + _CHIP.border + ';'
        + 'border-radius:10px; padding:1px 9px;'
        + 'margin:1px 2px; font-size:0.73rem; font-weight:700;'
        + 'color:' + _CHIP.text + '; letter-spacing:0.01em;'
        + '">' + $('<span>').text(t).html() + '</span>';
    });
    html += '<span style="font-size:0.68rem; color:#9ca3af; margin-left:7px;">'
          + '&nbsp;&mdash;&nbsp; in title &middot; purpose &middot; lab &middot; ODC&nbsp;ID'
          + '</span>';

    $('.search-hint').html(html);
  });

});
