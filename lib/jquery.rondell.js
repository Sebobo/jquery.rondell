/*!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 0.8.1
  @date 11/02/2011
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
*/
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
(function($) {
  var Rondell;
  $.rondell = {
    version: '0.8.1',
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
        y: 300
      },
      center: {
        left: 400,
        top: 350
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
        },
        topMargin: 20
      },
      repeating: true,
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
      funcEase: 'easeInOutQuad'
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
    function Rondell(options) {
      this.keyDown = __bind(this.keyDown, this);
      this._autoShift = __bind(this._autoShift, this);
      this.shiftRight = __bind(this.shiftRight, this);
      this.shiftLeft = __bind(this.shiftLeft, this);
      this.shiftTo = __bind(this.shiftTo, this);
      this.layerFadeOut = __bind(this.layerFadeOut, this);
      this.layerFadeIn = __bind(this.layerFadeIn, this);
      this._hover = __bind(this._hover, this);
      this._start = __bind(this._start, this);
      this._initItem = __bind(this._initItem, this);
      this._getItem = __bind(this._getItem, this);
      this.hideCaption = __bind(this.hideCaption, this);
      this.showCaption = __bind(this.showCaption, this);      this.id = Rondell.rondellCount++;
      this.items = [];
      $.extend(true, this, $.rondell.defaults, options || {});
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
      var captionContainer, captionContent, _ref, _ref2;
      this.items[layerNum - 1] = item;
      captionContent = (_ref = item.icon) != null ? _ref.siblings() : void 0;
      if (!((captionContent != null ? captionContent.length : void 0) || item.icon) && item.object.children().length) {
        captionContent = item.object.children();
      }
      if (!captionContent.length && ((_ref2 = item.icon) != null ? _ref2.attr('title') : void 0)) {
        captionContent = $("<p>" + (item.icon.attr('title')) + "</p>");
        item.object.append(captionContent);
      }
      if (captionContent.length) {
        captionContainer = $('<div class="rondellCaption"></div>');
        if (item.icon) {
          captionContainer.addClass('overlay');
        }
        captionContent.wrapAll(captionContainer);
      }
      return item.object.addClass("new " + this.itemProperties.cssClass).css({
        opacity: 0,
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
    };
    Rondell.prototype._start = function() {
      var controls, shiftLeft, shiftRight;
      this.currentLayer = Math.round(this.itemCount / 2);
      if (this.visibleItems === 'auto') {
        this.visibleItems = Math.max(2, Math.round(this.itemCount / 4));
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
      this.container.removeClass('initializing').bind('mouseover mouseout', this._hover);
      return this.shiftTo(this.currentLayer);
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
        return this.hideCaption(this.currentLayer);
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
        if (this.hovering) {
          return this.showCaption(layerNum);
        }
      }, this));
      if (item.icon && !item.resizeable) {
        margin = (this.itemProperties.size.height - item.icon.height()) / 2;
        return item.icon.stop(true).animate({
          marginTop: margin,
          marginBottom: margin
        }, this.fadeTime);
      }
    };
    Rondell.prototype.layerFadeOut = function(layerNum) {
      var fadeTime, isNew, item, layerDiff, layerDist, layerPos, margin, newOpacity, newX, newY, newZ;
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
      newX = this.funcLeft(layerDiff, this) + (this.itemProperties.size.width - item.sizeSmall.width) / 2;
      newY = this.funcTop(layerDiff, this) + (this.itemProperties.size.height - item.sizeSmall.height) / 2;
      newZ = this.zIndex + (layerDiff < 0 ? layerPos : -layerPos);
      fadeTime = this.fadeTime + this.itemProperties.delay * layerDist;
      isNew = item.object.hasClass('new');
      if (layerDist <= this.visibleItems || isNew) {
        this.hideCaption(layerNum);
        newOpacity = this.funcOpacity(layerDist, this);
        if (newOpacity >= this.opacityMin) {
          item.object.show();
        }
        item.object.removeClass('new rondellItemFocused').stop(true).css('z-index', newZ).animate({
          width: item.sizeSmall.width,
          height: item.sizeSmall.height,
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
      if (e) {
        e.preventDefault();
      }
      return this.shiftTo(this.currentLayer - 1);
    };
    Rondell.prototype.shiftRight = function(e) {
      if (e) {
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
    var center, container, containerHeight, containerWidth, focusedHeight, focusedWidth, itemHeight, itemProperties, itemWidth, maxItems, radius, rondell, scaling;
    rondell = new Rondell(options);
    itemProperties = rondell.itemProperties;
    itemWidth = itemProperties.size.width;
    itemHeight = itemProperties.size.height;
    scaling = rondell.scaling;
    center = rondell.center;
    radius = rondell.radius;
    containerWidth = rondell.size.width |= center.left * 2;
    containerHeight = rondell.size.height |= center.top * 2;
    focusedWidth = itemProperties.sizeFocused.width || itemWidth * scaling;
    focusedHeight = itemProperties.sizeFocused.height || itemHeight * scaling;
    maxItems = this.length;
    this.wrapAll($('<div class="rondellContainer initializing"></div>'));
    container = rondell.container = this.parent().css({
      width: containerWidth,
      height: containerHeight
    });
    this.each(function() {
      var layerNum, obj, objIcon;
      obj = $(this);
      objIcon = $('img:first', obj);
      if (objIcon.length) {
        return objIcon.load(function() {
          var foHeight, foWidth, icon, isResizeable, layerNum, smHeight, smWidth;
          icon = $(this);
          isResizeable = icon.hasClass(rondell.resizeableClass);
          layerNum = rondell.itemCount += 1;
          foWidth = smWidth = icon.width();
          foHeight = smHeight = icon.height();
          if (isResizeable) {
            if (smWidth >= smHeight) {
              smHeight *= itemWidth / smWidth;
              foHeight *= focusedWidth / foWidth;
              smWidth = itemWidth;
              foWidth = focusedWidth;
            } else {
              smWidth *= itemHeight / smHeight;
              foWidth *= focusedHeight / foHeight;
              smHeight = itemHeight;
              foHeight = focusedHeight;
            }
          } else {
            smWidth = itemWidth;
            smHeight = itemHeight;
            foWidth = focusedWidth;
            foHeight = focusedHeight;
          }
          rondell._initItem(layerNum, {
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
          if (rondell.itemCount === maxItems) {
            return rondell._start();
          }
        });
      } else {
        layerNum = rondell.itemCount += 1;
        rondell._initItem(layerNum, {
          object: obj,
          icon: null,
          small: false,
          hidden: false,
          resizeable: false,
          sizeSmall: {
            width: itemWidth,
            height: itemHeight
          },
          sizeFocused: {
            width: focusedWidth,
            height: focusedHeight
          }
        });
        if (rondell.items.length === maxItems) {
          return rondell._start();
        }
      }
    });
    return $(this);
  };
})(jQuery);