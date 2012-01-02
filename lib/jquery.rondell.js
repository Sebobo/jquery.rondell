/*!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 0.8.4
  @date 12/21/2011
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
*/
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

(function($) {
  /* Global rondell plugin properties
  */
  var Rondell;
  $.rondell = {
    version: '0.8.4',
    name: 'rondell',
    defaults: {
      showContainer: true,
      resizeableClass: 'resizeable',
      smallClass: 'itemSmall',
      hiddenClass: 'itemHidden',
      currentLayer: 0,
      container: null,
      radius: {
        x: 300,
        y: 50
      },
      center: {
        left: 400,
        top: 200
      },
      size: {
        width: null,
        height: null
      },
      visibleItems: 'auto',
      scaling: 2,
      opacityMin: 0.05,
      fadeTime: 300,
      zIndex: 1000,
      itemProperties: {
        delay: 100,
        cssClass: 'rondellItem',
        size: {
          width: 150,
          height: 150
        },
        sizeFocused: {
          width: 0,
          height: 0
        }
      },
      repeating: true,
      alwaysShowCaption: false,
      autoRotation: {
        enabled: false,
        paused: false,
        _timer: -1,
        direction: 0,
        once: false,
        delay: 5000
      },
      controls: {
        enabled: true,
        fadeTime: 400,
        margin: {
          x: 20,
          y: 20
        }
      },
      strings: {
        prev: 'prev',
        next: 'next'
      },
      mousewheel: {
        enabled: true,
        threshold: 5,
        minTimeBetweenShifts: 300,
        _lastShift: 0
      },
      touch: {
        enabled: true,
        preventDefaults: true,
        threshold: 100,
        _start: void 0,
        _end: void 0
      },
      funcEase: 'easeInOutQuad',
      theme: 'default',
      preset: '',
      effect: null
    }
  };
  /* Add default easing function for rondell to jQuery if missing
  */
  if (!$.easing.easeInOutQuad) {
    $.easing.easeInOutQuad = function(x, t, b, c, d) {
      if ((t /= d / 2) < 1) {
        return c / 2 * t * t + b;
      } else {
        return -c / 2 * ((--t) * (t - 2) - 1) + b;
      }
    };
  }
  Rondell = (function() {

    Rondell.rondellCount = 0;

    Rondell.activeRondell = null;

    function Rondell(options, numItems, initCallback) {
      if (initCallback == null) initCallback = void 0;
      this.keyDown = __bind(this.keyDown, this);
      this.isFocused = __bind(this.isFocused, this);
      this._autoShift = __bind(this._autoShift, this);
      this.shiftRight = __bind(this.shiftRight, this);
      this.shiftLeft = __bind(this.shiftLeft, this);
      this._refreshControls = __bind(this._refreshControls, this);
      this.shiftTo = __bind(this.shiftTo, this);
      this.layerFadeOut = __bind(this.layerFadeOut, this);
      this.layerFadeIn = __bind(this.layerFadeIn, this);
      this._hover = __bind(this._hover, this);
      this._onTouch = __bind(this._onTouch, this);
      this._onMousewheel = __bind(this._onMousewheel, this);
      this._start = __bind(this._start, this);
      this._loadItem = __bind(this._loadItem, this);
      this._onloadItem = __bind(this._onloadItem, this);
      this._initItem = __bind(this._initItem, this);
      this._getItem = __bind(this._getItem, this);
      this.hideCaption = __bind(this.hideCaption, this);
      this.showCaption = __bind(this.showCaption, this);
      this.id = Rondell.rondellCount++;
      this.items = [];
      this.maxItems = numItems;
      this.loadedItems = 0;
      this.initCallback = initCallback;
      if ((options != null ? options.preset : void 0) in $.rondell.presets) {
        $.extend(true, this, $.rondell.defaults, $.rondell.presets[options.preset], options || {});
      } else {
        $.extend(true, this, $.rondell.defaults, options || {});
      }
      this.itemProperties.sizeFocused = {
        width: this.itemProperties.sizeFocused.width || this.itemProperties.size.width * this.scaling,
        height: this.itemProperties.sizeFocused.height || this.itemProperties.size.height * this.scaling
      };
      this.size = {
        width: this.size.width || this.center.left * 2,
        height: this.size.height || this.center.top * 2
      };
    }

    Rondell.prototype.funcLeft = function(layerDiff, rondell) {
      return rondell.center.left - rondell.itemProperties.size.width / 2.0 + Math.sin(layerDiff) * rondell.radius.x;
    };

    Rondell.prototype.funcTop = function(layerDiff, rondell) {
      return rondell.center.top - rondell.itemProperties.size.height / 2.0 + Math.cos(layerDiff) * rondell.radius.y;
    };

    Rondell.prototype.funcDiff = function(layerDiff, rondell) {
      return Math.pow(Math.abs(layerDiff) / rondell.maxItems, 0.5) * Math.PI;
    };

    Rondell.prototype.funcOpacity = function(layerDist, rondell) {
      if (rondell.visibleItems > 1) {
        return Math.max(0, 1.0 - Math.pow(layerDist / rondell.visibleItems, 2));
      } else {
        return 0;
      }
    };

    Rondell.prototype.funcSize = function(layerDist, rondell) {
      return 1;
    };

    Rondell.prototype.showCaption = function(layerNum) {
      return $('.rondellCaption.overlay', this._getItem(layerNum).object).css({
        height: 'auto',
        overflow: 'auto'
      }).stop(true).fadeTo(300, 1);
    };

    Rondell.prototype.hideCaption = function(layerNum) {
      var caption;
      caption = $('.rondellCaption.overlay:visible', this._getItem(layerNum).object);
      return caption.css({
        height: caption.height(),
        overflow: 'hidden'
      }).stop(true).fadeTo(200, 0);
    };

    Rondell.prototype._getItem = function(layerNum) {
      return this.items[layerNum - 1];
    };

    Rondell.prototype._initItem = function(layerNum, item) {
      var caption, captionContainer, captionContent, _ref, _ref2, _ref3,
        _this = this;
      this.items[layerNum - 1] = item;
      captionContent = (_ref = item.icon) != null ? _ref.siblings() : void 0;
      if (!((captionContent != null ? captionContent.length : void 0) || item.icon) && item.object.children().length) {
        captionContent = item.object.children();
      }
      if (!captionContent.length) {
        caption = item.object.attr('title') || ((_ref2 = item.icon) != null ? _ref2.attr('alt') : void 0) || ((_ref3 = item.icon) != null ? _ref3.attr('title') : void 0);
        if (caption) {
          captionContent = $("<p>" + caption + "</p>");
          item.object.append(captionContent);
        }
      }
      if (captionContent.length) {
        captionContainer = $('<div class="rondellCaption"></div>');
        if (item.icon) captionContainer.addClass('overlay');
        captionContent.wrapAll(captionContainer);
      }
      item.object.addClass("rondellItemNew " + this.itemProperties.cssClass).css({
        opacity: 0,
        width: item.sizeSmall.width,
        height: item.sizeSmall.height,
        left: this.center.left - item.sizeFocused.width / 2,
        top: this.center.top - item.sizeFocused.height / 2
      }).bind('mouseover mouseout click', function(e) {
        switch (e.type) {
          case 'mouseover':
            if (item.object.is(':visible') && !item.hidden) {
              return item.object.addClass('rondellItemHovered');
            }
            break;
          case 'mouseout':
            return item.object.removeClass('rondellItemHovered');
          case 'click':
            if (_this.currentLayer !== layerNum) e.preventDefault();
            if (item.object.is(':visible') && !item.hidden) {
              return _this.shiftTo(layerNum);
            }
        }
      });
      this.loadedItems += 1;
      if (this.loadedItems === this.maxItems) return this._start();
    };

    Rondell.prototype._onloadItem = function(itemIndex, obj, copy) {
      var foHeight, foWidth, focusedSize, icon, isResizeable, itemSize, layerNum, scaling, smHeight, smWidth;
      if (copy == null) copy = void 0;
      icon = $('img:first', obj);
      isResizeable = icon.hasClass(this.resizeableClass);
      layerNum = itemIndex;
      itemSize = this.itemProperties.size;
      focusedSize = this.itemProperties.sizeFocused;
      scaling = this.scaling;
      foWidth = smWidth = (copy != null ? copy.width() : void 0) || (copy != null ? copy[0].width : void 0) || icon[0].width || icon.width();
      foHeight = smHeight = (copy != null ? copy.height() : void 0) || (copy != null ? copy[0].height : void 0) || icon[0].height || icon.height();
      if (copy != null) copy.remove();
      if (!(smWidth && smHeight)) return;
      if (isResizeable) {
        smHeight *= itemSize.width / smWidth;
        smWidth = itemSize.width;
        if (smHeight > itemSize.height) {
          smWidth *= itemSize.height / smHeight;
          smHeight = itemSize.height;
        }
        foHeight *= focusedSize.width / foWidth;
        foWidth = focusedSize.width;
        if (foHeight > focusedSize.height) {
          foWidth *= focusedSize.height / foHeight;
          foHeight = focusedSize.height;
        }
      } else {
        smWidth = itemSize.width;
        smHeight = itemSize.height;
        foWidth = focusedSize.width;
        foHeight = focusedSize.height;
      }
      return this._initItem(layerNum, {
        object: obj,
        icon: icon,
        small: false,
        hidden: false,
        resizeable: isResizeable,
        sizeSmall: {
          width: smWidth,
          height: smHeight
        },
        sizeFocused: {
          width: foWidth,
          height: foHeight
        }
      });
    };

    Rondell.prototype._loadItem = function(itemIndex, obj) {
      var copy, icon,
        _this = this;
      icon = $('img:first', obj);
      if (icon.width() > 0 || (icon[0].complete && icon[0].width > 0)) {
        return this._onloadItem(itemIndex, obj);
      } else {
        copy = $("<img style=\"display:none\"/>");
        $('body').append(copy);
        return copy.one("load", function() {
          return _this._onloadItem(itemIndex, obj, copy);
        }).attr("src", icon.attr("src"));
      }
    };

    Rondell.prototype._start = function() {
      var controls;
      this.currentLayer = Math.max(0, Math.min(this.currentLayer || Math.round(this.maxItems / 2), this.maxItems));
      if (this.visibleItems === 'auto') {
        this.visibleItems = Math.max(2, Math.floor(this.maxItems / 2));
      }
      controls = this.controls;
      if (controls.enabled) {
        this.controls._shiftLeft = $('<a class="rondellControl rondellShiftLeft" href="#"/>').text(this.strings.prev).click(this.shiftLeft).css({
          left: controls.margin.x,
          top: controls.margin.y,
          "z-index": this.zIndex + this.maxItems + 2
        });
        this.controls._shiftRight = $('<a class="rondellControl rondellShiftRight" href="#/"/>').text(this.strings.next).click(this.shiftRight).css({
          right: controls.margin.x,
          top: controls.margin.y,
          "z-index": this.zIndex + this.maxItems + 2
        });
        this.container.append(this.controls._shiftLeft, this.controls._shiftRight);
      }
      $(document).keydown(this.keyDown);
      if (this.mousewheel.enabled && ($.fn.mousewheel != null)) {
        this.container.bind('mousewheel', this._onMousewheel);
      }
      if (this._onMobile()) {
        if (this.touch.enabled) {
          this.container.bind('touchstart touchmove touchend', this._onTouch);
        }
      } else {
        this.container.bind('mouseover mouseout', this._hover);
      }
      this.container.removeClass('initializing');
      if (typeof this.initCallback === "function") this.initCallback(this);
      return this.shiftTo(this.currentLayer);
    };

    Rondell.prototype._onMobile = function() {
      /*
            Mobile device detection. 
            Check for touch functionality is currently enough.
      */      return typeof Modernizr !== "undefined" && Modernizr !== null ? Modernizr.touch : void 0;
    };

    Rondell.prototype._onMousewheel = function(e, d, dx, dy) {
      /*
            Allows rondell traveling with mousewheel.
            Requires mousewheel plugin for jQuery.
      */
      var now, selfYCenter, viewport, viewportBottom, viewportTop;
      if (!(this.mousewheel.enabled && this.isFocused())) return;
      now = (new Date()).getTime();
      if (now - this.mousewheel._lastShift < this.mousewheel.minTimeBetweenShifts) {
        return;
      }
      viewport = $(window);
      viewportTop = viewport.scrollTop();
      viewportBottom = viewportTop + viewport.height();
      selfYCenter = this.container.offset().top + this.container.outerHeight() / 2;
      if (selfYCenter > viewportTop && selfYCenter < viewportBottom && Math.abs(dx) >= this.mousewheel.threshold) {
        if (dx < 0) {
          this.shiftLeft();
        } else {
          this.shiftRight();
        }
        return this.mousewheel._lastShift = now;
      }
    };

    Rondell.prototype._onTouch = function(e) {
      var changeX, touch;
      if (!this.touch.enabled) return;
      touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
      switch (e.type) {
        case 'touchstart':
          this.touch._start = {
            x: touch.pageX,
            y: touch.pageY
          };
          break;
        case 'touchmove':
          if (this.touch.preventDefaults) e.preventDefault();
          this.touch._end = {
            x: touch.pageX,
            y: touch.pageY
          };
          break;
        case 'touchend':
          if (this.touch._start && this.touch._end) {
            changeX = this.touch._end.x - this.touch._start.x;
            if (Math.abs(changeX) > this.touch.threshold) {
              if (changeX > 0) this.shiftLeft();
              if (changeX < 0) this.shiftRight();
            }
            this.touch._start = this.touch._end = void 0;
          }
      }
      return true;
    };

    Rondell.prototype._hover = function(e) {
      /*
            Shows/hides rondell controls.
            Starts/pauses autorotation.
            Updates active rondell id.
      */
      var paused;
      paused = this.autoRotation.paused;
      if (e.type === 'mouseover') {
        Rondell.activeRondell = this.id;
        this.hovering = true;
        if (!paused) {
          this.autoRotation.paused = true;
          this.showCaption(this.currentLayer);
        }
      } else {
        this.hovering = false;
        if (paused && !this.autoRotation.once) {
          this.autoRotation.paused = false;
          this._autoShift();
        }
        if (!this.alwaysShowCaption) this.hideCaption(this.currentLayer);
      }
      if (this.controls.enabled) return this._refreshControls();
    };

    Rondell.prototype.layerFadeIn = function(layerNum) {
      var item, itemFocusedHeight, itemFocusedWidth, margin,
        _this = this;
      item = this._getItem(layerNum);
      item.small = false;
      itemFocusedWidth = item.sizeFocused.width;
      itemFocusedHeight = item.sizeFocused.height;
      item.object.stop(true).show(0).css('z-index', this.zIndex + this.maxItems).addClass('rondellItemFocused').animate({
        width: itemFocusedWidth,
        height: itemFocusedHeight,
        left: this.center.left - itemFocusedWidth / 2,
        top: this.center.top - itemFocusedHeight / 2,
        opacity: 1
      }, this.fadeTime, this.funcEase, function() {
        _this._autoShift();
        if (_this.hovering || _this.alwaysShowCaption || _this._onMobile()) {
          return _this.showCaption(layerNum);
        }
      });
      if (item.icon && !item.resizeable) {
        margin = (this.itemProperties.sizeFocused.height - item.icon.height()) / 2;
        return item.icon.stop(true).animate({
          marginTop: margin,
          marginBottom: margin
        }, this.fadeTime);
      }
    };

    Rondell.prototype.layerFadeOut = function(layerNum) {
      var fadeTime, isNew, item, itemHeight, itemWidth, layerDiff, layerDist, layerPos, margin, newOpacity, newX, newY, newZ,
        _this = this;
      item = this._getItem(layerNum);
      layerDist = Math.abs(layerNum - this.currentLayer);
      layerPos = layerNum;
      if (layerDist > this.visibleItems && layerDist > this.maxItems / 2 && this.repeating) {
        if (layerNum > this.currentLayer) {
          layerPos -= this.maxItems;
        } else {
          layerPos += this.maxItems;
        }
        layerDist = Math.abs(layerPos - this.currentLayer);
      }
      layerDiff = this.funcDiff(layerPos - this.currentLayer, this);
      if (layerPos < this.currentLayer) layerDiff *= -1;
      itemWidth = item.sizeSmall.width * this.funcSize(layerDiff, this);
      itemHeight = item.sizeSmall.height * this.funcSize(layerDiff, this);
      newX = this.funcLeft(layerDiff, this) + (this.itemProperties.size.width - itemWidth) / 2;
      newY = this.funcTop(layerDiff, this) + (this.itemProperties.size.height - itemHeight) / 2;
      newZ = this.zIndex + (layerDiff < 0 ? layerPos : -layerPos);
      fadeTime = this.fadeTime + this.itemProperties.delay * layerDist;
      isNew = item.object.hasClass('rondellItemNew');
      if (isNew || layerDist <= this.visibleItems) {
        this.hideCaption(layerNum);
        newOpacity = this.funcOpacity(layerDist, this);
        if (newOpacity >= this.opacityMin) item.object.show();
        item.object.removeClass('rondellItemNew rondellItemFocused').stop(true).css('z-index', newZ).animate({
          width: itemWidth,
          height: itemHeight,
          left: newX,
          top: newY,
          opacity: newOpacity
        }, fadeTime, this.funcEase, function() {
          if (item.object.css('opacity') < _this.opacityMin) {
            return item.object.hide();
          } else {
            return item.object.show();
          }
        });
        item.hidden = false;
        if (!item.small) {
          item.small = true;
          if (item.icon && !item.resizeable) {
            margin = (this.itemProperties.size.height - item.icon.height()) / 2;
            return item.icon.stop(true).animate({
              marginTop: margin,
              marginBottom: margin
            }, fadeTime);
          }
        }
      } else if (item.hidden) {
        return item.object.css({
          left: newX,
          top: newY,
          'z-index': newZ
        });
      } else {
        item.hidden = true;
        return item.object.stop(true).css('z-index', newZ).animate({
          opacity: 0
        }, fadeTime / 2, this.funcEase, function() {}, this.hideCaption(layerNum));
      }
    };

    Rondell.prototype.shiftTo = function(layerNum) {
      var i, _ref;
      if (this.repeating) {
        if (layerNum < 1) {
          layerNum = this.maxItems;
        } else if (layerNum > this.maxItems) {
          layerNum = 1;
        }
      }
      if (layerNum > 0 && layerNum <= this.maxItems) {
        this.currentLayer = layerNum;
        for (i = 1, _ref = this.maxItems; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
          if (i !== this.currentLayer) this.layerFadeOut(i);
        }
        this.layerFadeIn(this.currentLayer);
      }
      return this._refreshControls();
    };

    Rondell.prototype._refreshControls = function() {
      if (!this.controls.enabled) return;
      this.controls._shiftLeft.stop().fadeTo(this.controls.fadeTime, (this.currentLayer > 1 || this.repeating) && this.hovering ? 1 : 0);
      return this.controls._shiftRight.stop().fadeTo(this.controls.fadeTime, (this.currentLayer < this.maxItems || this.repeating) && this.hovering ? 1 : 0);
    };

    Rondell.prototype.shiftLeft = function(e) {
      if (e != null) e.preventDefault();
      return this.shiftTo(this.currentLayer - 1);
    };

    Rondell.prototype.shiftRight = function(e) {
      if (e != null) e.preventDefault();
      return this.shiftTo(this.currentLayer + 1);
    };

    Rondell.prototype._autoShift = function() {
      var autoRotation,
        _this = this;
      autoRotation = this.autoRotation;
      if (this.isActive() && autoRotation.enabled && autoRotation._timer < 0) {
        return autoRotation._timer = window.setTimeout(function() {
          _this.autoRotation._timer = -1;
          if (_this.isActive() && !autoRotation.paused) {
            if (autoRotation.direction) {
              return _this.shiftRight();
            } else {
              return _this.shiftLeft();
            }
          }
        }, autoRotation.delay);
      }
    };

    Rondell.prototype.isActive = function() {
      return true;
    };

    Rondell.prototype.isFocused = function() {
      return Rondell.activeRondell === this.id;
    };

    Rondell.prototype.keyDown = function(e) {
      if (this.isActive() && this.isFocused()) {
        if (this.autoRotation._timer >= 0) {
          window.clearTimeout(this.autoRotation._timer);
          this.autoRotation._timer = -1;
        }
        switch (e.which) {
          case 37:
            return this.shiftLeft(e);
          case 39:
            return this.shiftRight(e);
        }
      }
    };

    return Rondell;

  })();
  return $.fn.rondell = function(options, callback) {
    var rondell;
    if (options == null) options = {};
    if (callback == null) callback = void 0;
    rondell = new Rondell(options, this.length, callback);
    rondell.container = this.wrapAll($("<div class=\"rondellContainer initializing rondellTheme_" + rondell.theme + "\"/>").css(rondell.size)).parent();
    if (rondell.showContainer) rondell.container.parent().show();
    this.each(function(idx) {
      var itemIndex, obj;
      obj = $(this);
      itemIndex = idx + 1;
      if ($('img:first', obj).length) {
        return rondell._loadItem(itemIndex, obj);
      } else {
        return rondell._initItem(itemIndex, {
          object: obj,
          icon: null,
          small: false,
          hidden: false,
          resizeable: false,
          sizeSmall: rondell.itemProperties.size,
          sizeFocused: rondell.itemProperties.sizeFocused
        });
      }
    });
    return rondell;
  };
})(jQuery);

/*!
  Presets for jQuery rondell plugin
  
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
*/

(function($) {
  $.rondell = $.rondell || {};
  return $.rondell.presets = {
    carousel: {
      autoRotation: {
        enabled: true,
        direction: 1,
        once: false,
        delay: 5000
      },
      radius: {
        x: 220
      },
      controls: {
        margin: {
          x: 20,
          y: 190
        }
      },
      currentLayer: 1,
      funcSize: function(layerDiff, rondell) {
        return (rondell.maxItems / Math.abs(layerDiff)) / rondell.maxItems;
      }
    },
    products: {
      repeating: false,
      alwaysShowCaption: true,
      visibleItems: 4,
      itemProperties: {
        delay: 0,
        size: {
          width: 100,
          height: 200
        },
        sizeFocused: {
          width: 300,
          height: 200
        }
      },
      center: {
        left: 400,
        top: 100
      },
      controls: {
        margin: {
          x: 210,
          y: 158
        }
      },
      funcTop: function(layerDiff, rondell) {
        return 0;
      },
      funcDiff: function(layerDiff, rondell) {
        return Math.abs(layerDiff) + 1;
      },
      funcLeft: function(layerDiff, rondell) {
        return rondell.center.left + (layerDiff - 0.5) * rondell.itemProperties.size.width;
      },
      funcOpacity: function(layerDist, rondell) {
        return 0.8;
      }
    },
    pages: {
      radius: {
        x: 0,
        y: 0
      },
      scaling: 1,
      visibleItems: 1,
      controls: {
        enabled: false
      },
      center: {
        left: 200,
        top: 200
      },
      itemProperties: {
        size: {
          width: 400,
          height: 400
        }
      },
      funcTop: function(layerDiff, rondell) {
        return rondell.center.top - rondell.itemProperties.size.height / 2;
      },
      funcLeft: function(layerDiff, rondell) {
        return rondell.center.left + layerDiff * rondell.itemProperties.size.width;
      },
      funcDiff: function(layerDiff, rondell) {
        return Math.abs(layerDiff) + 0.5;
      }
    },
    cubic: {
      center: {
        left: 400,
        top: 200
      },
      visibleItems: 5,
      itemProperties: {
        size: {
          width: 350,
          height: 350
        },
        sizeFocused: {
          width: 350,
          height: 350
        }
      },
      controls: {
        margin: {
          x: 10,
          y: 190
        }
      },
      funcTop: function(layerDiff, rondell) {
        return rondell.center.top - rondell.itemProperties.size.height / 2 + Math.pow(layerDiff / 2, 3) * rondell.radius.x;
      },
      funcLeft: function(layerDiff, rondell) {
        return rondell.center.left - rondell.itemProperties.size.width / 2 + Math.sin(layerDiff) * rondell.radius.x;
      },
      funcSize: function(layerDiff, rondell) {
        return Math.pow((Math.PI - Math.abs(layerDiff)) / Math.PI, 3);
      }
    },
    gallery: {
      visibleItems: 4,
      controls: {
        enabled: false
      },
      center: {
        top: 145,
        left: 250
      },
      size: {
        height: 400,
        width: 500
      },
      itemProperties: {
        delay: 10,
        sizeFocused: {
          width: 480,
          height: 280
        },
        size: {
          width: 100,
          height: 100
        }
      },
      funcTop: function(layerDiff, rondell) {
        return rondell.size.height - rondell.itemProperties.size.height - 5;
      },
      funcDiff: function(layerDiff, rondell) {
        return Math.abs(layerDiff) - 0.5;
      },
      funcLeft: function(layerDiff, rondell) {
        return rondell.center.left + (layerDiff - 0.5) * (rondell.itemProperties.size.width + 5);
      },
      funcOpacity: function(layerDist, rondell) {
        return 0.8;
      }
    }
  };
})(jQuery);
