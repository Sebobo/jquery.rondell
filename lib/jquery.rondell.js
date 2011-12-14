/*!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 0.8.3
  @date 11/19/2011
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
*/
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
(function($) {
  var Rondell;
  $.rondell = {
    version: '0.8.3',
    name: 'rondell',
    defaults: {
      resizeableClass: 'resizeable',
      smallClass: 'itemSmall',
      hiddenClass: 'itemHidden',
      itemCount: 0,
      currentLayer: 1,
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
        timer: -1,
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
      touch: {
        enabled: true,
        preventDefaults: true,
        threshold: 100,
        start: void 0,
        end: void 0
      },
      funcEase: 'easeInOutQuad',
      theme: 'default',
      preset: '',
      effect: null
    }
  };
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
    function Rondell(options, numItems) {
      this.keyDown = __bind(this.keyDown, this);
      this._autoShift = __bind(this._autoShift, this);
      this.shiftRight = __bind(this.shiftRight, this);
      this.shiftLeft = __bind(this.shiftLeft, this);
      this.shiftTo = __bind(this.shiftTo, this);
      this.layerFadeOut = __bind(this.layerFadeOut, this);
      this.layerFadeIn = __bind(this.layerFadeIn, this);
      this._hover = __bind(this._hover, this);
      this._touch = __bind(this._touch, this);
      this._start = __bind(this._start, this);
      this._loadItem = __bind(this._loadItem, this);
      this._onloadItem = __bind(this._onloadItem, this);
      this._initItem = __bind(this._initItem, this);
      this._getItem = __bind(this._getItem, this);
      this.hideCaption = __bind(this.hideCaption, this);
      this.showCaption = __bind(this.showCaption, this);      this.id = Rondell.rondellCount++;
      this.items = [];
      this.maxItems = numItems;
      $.extend(true, this, $.rondell.defaults, options || {});
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
      return Math.pow(Math.abs(layerDiff) / rondell.itemCount, 0.5) * Math.PI;
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
      var caption, captionContainer, captionContent, _ref, _ref2, _ref3;
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
        if (item.icon) {
          captionContainer.addClass('overlay');
        }
        captionContent.wrapAll(captionContainer);
      }
      item.object.addClass("rondellItemNew " + this.itemProperties.cssClass).css({
        opacity: 0,
        width: item.sizeSmall.width,
        height: item.sizeSmall.height,
        left: this.center.left - item.sizeFocused.width / 2,
        top: this.center.top - item.sizeFocused.height / 2
      }).bind('mouseover mouseout click', __bind(function(e) {
        switch (e.type) {
          case 'mouseover':
            if (item.object.is(':visible') && !item.hidden) {
              return item.object.addClass('rondellItemHovered');
            }
            break;
          case 'mouseout':
            return item.object.removeClass('rondellItemHovered');
          case 'click':
            if (item.object.is(':visible') && !(this.currentLayer === layerNum || item.hidden)) {
              this.shiftTo(layerNum);
              return e.preventDefault();
            }
        }
      }, this));
      if (this.itemCount === this.maxItems) {
        return this._start();
      }
    };
    Rondell.prototype._onloadItem = function(obj, copy) {
      var foHeight, foWidth, focusedSize, icon, isResizeable, itemSize, layerNum, scaling, smHeight, smWidth;
      if (copy == null) {
        copy = void 0;
      }
      icon = $('img:first', obj);
      isResizeable = icon.hasClass(this.resizeableClass);
      layerNum = this.itemCount += 1;
      itemSize = this.itemProperties.size;
      focusedSize = this.itemProperties.sizeFocused;
      scaling = this.scaling;
      foWidth = smWidth = (copy != null ? copy.width() : void 0) || (copy != null ? copy[0].width : void 0) || icon[0].width || icon.width();
      foHeight = smHeight = (copy != null ? copy.height() : void 0) || (copy != null ? copy[0].height : void 0) || icon[0].height || icon.height();
      if (copy != null) {
        copy.remove();
      }
      if (!(smWidth && smHeight)) {
        return;
      }
      if (isResizeable) {
        if (smWidth >= smHeight) {
          smHeight *= itemSize.width / smWidth;
          foHeight *= focusedSize.width / foWidth;
          smWidth = itemSize.width;
          foWidth = focusedSize.width;
        } else {
          smWidth *= itemSize.height / smHeight;
          foWidth *= focusedSize.height / foHeight;
          smHeight = itemSize.height;
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
    Rondell.prototype._loadItem = function(obj) {
      var copy, icon;
      icon = $('img:first', obj);
      if (icon[0].complete && icon[0].width) {
        return this._onloadItem(obj);
      } else {
        copy = $("<img style=\"display:none\"/>");
        $('body').append(copy);
        return copy.one("load", __bind(function() {
          return this._onloadItem(obj, copy);
        }, this)).attr("src", icon.attr("src"));
      }
    };
    Rondell.prototype._start = function() {
      var controls, shiftLeft, shiftRight;
      this.currentLayer = Math.round(this.itemCount / 2);
      if (this.visibleItems === 'auto') {
        this.visibleItems = Math.max(2, Math.floor(this.itemCount / 2));
      }
      controls = this.controls;
      if (controls.enabled) {
        shiftLeft = $('<a class="rondellControl rondellShiftLeft" href="#"/>').text(this.strings.prev).click(this.shiftLeft).css({
          left: controls.margin.x,
          top: controls.margin.y,
          "z-index": this.zIndex + this.itemCount + 2
        });
        shiftRight = $('<a class="rondellControl rondellShiftRight" href="#/"/>').text(this.strings.next).click(this.shiftRight).css({
          right: controls.margin.x,
          top: controls.margin.y,
          "z-index": this.zIndex + this.itemCount + 2
        });
        this.container.append(shiftLeft, shiftRight);
      }
      $(document).keydown(this.keyDown);
      this.container.removeClass('initializing').bind('mouseover mouseout', this._hover).bind('touchstart touchmove touchend', this._touch);
      return this.shiftTo(this.currentLayer);
    };
    Rondell.prototype._touch = function(e) {
      var changeX, touch;
      if (!this.touch.enabled) {
        return;
      }
      touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
      switch (e.type) {
        case 'touchstart':
          this.touch.start = {
            x: touch.pageX,
            y: touch.pageY
          };
          break;
        case 'touchmove':
          if (this.touch.preventDefaults) {
            e.preventDefault();
          }
          this.touch.end = {
            x: touch.pageX,
            y: touch.pageY
          };
          break;
        case 'touchend':
          if (this.touch.start && this.touch.end) {
            changeX = this.touch.end.x - this.touch.start.x;
            if (Math.abs(changeX) > this.touch.threshold) {
              if (changeX > 0) {
                this.shiftLeft();
              }
              if (changeX < 0) {
                this.shiftRight();
              }
            }
            this.touch.start = this.touch.end = void 0;
          }
      }
      return true;
    };
    Rondell.prototype._hover = function(e) {
      var paused;
      $('.rondellControl', this.container).stop().fadeTo(this.controls.fadeTime, e.type === 'mouseover' ? 1 : 0);
      paused = this.autoRotation.paused;
      if (e.type === 'mouseover') {
        Rondell.activeRondell = this.id;
        this.hovering = true;
        if (!paused) {
          this.autoRotation.paused = true;
          return this.showCaption(this.currentLayer);
        }
      } else {
        this.hovering = false;
        if (paused && !this.autoRotation.once) {
          this.autoRotation.paused = false;
          this._autoShift();
        }
        if (!this.alwaysShowCaption) {
          return this.hideCaption(this.currentLayer);
        }
      }
    };
    Rondell.prototype.layerFadeIn = function(layerNum) {
      var item, itemFocusedHeight, itemFocusedWidth, margin;
      item = this._getItem(layerNum);
      item.small = false;
      itemFocusedWidth = item.sizeFocused.width;
      itemFocusedHeight = item.sizeFocused.height;
      item.object.stop(true).show(0).css('z-index', this.zIndex + this.itemCount).addClass('rondellItemFocused').animate({
        width: itemFocusedWidth,
        height: itemFocusedHeight,
        left: this.center.left - itemFocusedWidth / 2,
        top: this.center.top - itemFocusedHeight / 2,
        opacity: 1
      }, this.fadeTime, this.funcEase, __bind(function() {
        this._autoShift();
        if (this.hovering || this.alwaysShowCaption) {
          return this.showCaption(layerNum);
        }
      }, this));
      if (item.icon && !item.resizeable) {
        margin = (this.itemProperties.sizeFocused.height - item.icon.height()) / 2;
        return item.icon.stop(true).animate({
          marginTop: margin,
          marginBottom: margin
        }, this.fadeTime);
      }
    };
    Rondell.prototype.layerFadeOut = function(layerNum) {
      var fadeTime, isNew, item, itemHeight, itemWidth, layerDiff, layerDist, layerPos, margin, newOpacity, newX, newY, newZ;
      item = this._getItem(layerNum);
      layerDist = Math.abs(layerNum - this.currentLayer);
      layerPos = layerNum;
      if (layerDist > this.visibleItems && this.repeating) {
        if (this.currentLayer + this.visibleItems > this.itemCount) {
          layerPos += this.itemCount;
        } else if (this.currentLayer - this.visibleItems <= this.itemCount) {
          layerPos -= this.itemCount;
        }
        layerDist = Math.abs(layerPos - this.currentLayer);
      }
      layerDiff = this.funcDiff(layerPos - this.currentLayer, this);
      if (layerPos < this.currentLayer) {
        layerDiff *= -1;
      }
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
        if (newOpacity >= this.opacityMin) {
          item.object.show();
        }
        item.object.removeClass('rondellItemNew rondellItemFocused').stop(true).css('z-index', newZ).animate({
          width: itemWidth,
          height: itemHeight,
          left: newX,
          top: newY,
          opacity: newOpacity
        }, fadeTime, this.funcEase, __bind(function() {
          if (item.object.css('opacity') < this.opacityMin) {
            return item.object.hide();
          } else {
            return item.object.show();
          }
        }, this));
        item.hidden = false;
        if (!item.small) {
          item.small = true;
          if (item.icon && !item.resizeable) {
            margin = (itemHeight - item.icon.height()) / 2;
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
        }, fadeTime / 2, this.funcEase, __bind(function() {}, this), this.hideCaption(layerNum));
      }
    };
    Rondell.prototype.shiftTo = function(layerNum) {
      var currentLayer, i, itemCount;
      itemCount = this.itemCount;
      if (this.repeating) {
        if (layerNum < 1) {
          layerNum = itemCount;
        } else if (layerNum > itemCount) {
          layerNum = 1;
        }
      }
      if (layerNum > 0 && layerNum <= itemCount) {
        this.currentLayer = currentLayer = layerNum;
        for (i = 1; 1 <= itemCount ? i <= itemCount : i >= itemCount; 1 <= itemCount ? i++ : i--) {
          if (i !== currentLayer) {
            this.layerFadeOut(i);
          }
        }
        return this.layerFadeIn(currentLayer);
      }
    };
    Rondell.prototype.shiftLeft = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      return this.shiftTo(this.currentLayer - 1);
    };
    Rondell.prototype.shiftRight = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      return this.shiftTo(this.currentLayer + 1);
    };
    Rondell.prototype._autoShift = function() {
      var autoRotation;
      autoRotation = this.autoRotation;
      if (this.isActive() && autoRotation.enabled && autoRotation.timer < 0) {
        return autoRotation.timer = window.setTimeout(__bind(function() {
          this.autoRotation.timer = -1;
          if (this.isActive() && !autoRotation.paused) {
            if (autoRotation.direction) {
              return this.shiftRight();
            } else {
              return this.shiftLeft();
            }
          }
        }, this), autoRotation.delay);
      }
    };
    Rondell.prototype.isActive = function() {
      return true;
    };
    Rondell.prototype.keyDown = function(e) {
      if (this.isActive() && Rondell.activeRondell === this.id) {
        if (this.autoRotation.timer >= 0) {
          window.clearTimeout(this.autoRotation.timer);
          this.autoRotation.timer = -1;
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
  return $.fn.rondell = function(options) {
    var rondell;
    rondell = new Rondell(options, this.length);
    this.wrapAll($('<div class="rondellContainer initializing"></div>'));
    rondell.container = this.parent().css(rondell.size);
    this.each(function() {
      var layerNum, obj;
      obj = $(this);
      if ($('img:first', obj).length) {
        return rondell._loadItem(obj);
      } else {
        layerNum = rondell.itemCount += 1;
        return rondell._initItem(layerNum, {
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