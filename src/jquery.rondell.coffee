###!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 0.8.7
  @date 02/03/2012
  @category jQuery plugin
  @copyright (c) 2009-2012 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  ### Global rondell plugin properties ###
  $.rondell =
    version: '0.9.0-beta'
    name: 'rondell'
    defaults:
      showContainer: true       # When the plugin has finished initializing $.show() will be called on the items container
      resizeableClass: 'resizeable'
      smallClass: 'itemSmall'
      hiddenClass: 'itemHidden'
      currentLayer: 0           # Active layer number in a rondell instance
      container: null           # Container object wrapping the rondell items
      radius:                   # Radius for the default circle function
        x: 250 
        y: 50  
      center:                   # Center where the focused element is displayed
        left: 340 
        top: 160
      size:                     # Defaults to center * 2 on init
        width: null
        height: null
      visibleItems: 'auto'      # How many items should be visible in each direction
      scaling: 2                # Size of focused element
      opacityMin: 0.05          # Min opacity before elements are set to display: none
      fadeTime: 300
      keyDelay: 300             # Min time between key strokes are registered
      zIndex: 1000              # All elements of the rondell will use this z-index and add their depth to it
      itemProperties:           # Default properties for each item
        delay: 100              # Time offset between the animation of each item
        cssClass: 'rondellItem' # Identifier for each item
        size: 
          width: 150
          height: 150
        sizeFocused:
          width: 0
          height: 0
      repeating: true           # Will show first item after last item and so on
      alwaysShowCaption: false  # Don't hide caption on mouseleave
      autoRotation:             # If the cursor leaves the rondell continue spinning
        enabled: false
        paused: false           # Can be used to pause the auto rotation with a play/pause button for example 
        direction: 0            # 0 or 1 means left and right
        once: false             # Will animate until the rondell will be hovered at least once
        delay: 5000
      controls:                 # Buttons to control the rondell
        enabled: true
        fadeTime: 400           # Show/hide animation speed
        margin:     
          x: 130                 # Distance from left and right edge of the container
          y: 270                 # Distance from top and bottom edge of the container
      strings: # String for the controls 
        prev: 'prev'
        next: 'next'
      mousewheel:
        enabled: true
        threshold: 2
        minTimeBetweenShifts: 500
      touch:
        enabled: true
        preventDefaults: true   # Will call event.preventDefault() on touch events
        threshold: 100          # Distance in pixels the "finger" has to swipe to create the touch event      
      randomStart: false
      funcEase: 'easeInOutQuad' # jQuery easing function name for the movement of items
      theme: 'default'          # CSS theme class which gets added to the rondell container
      preset: ''                # Configuration preset
      effect: null              # Special effect function for the focused item, not used currently
      onAfterShift: null
      scrollbar:
        start: 0
        end: 100
        stepSize: 1
        position: 50
        onScroll: undefined
        scrollOnHover: false
        scrollOnDrag: true
        animationDuration: 400
        easing: "easeInOutQuad"
        drag:
          dragging: false
          lastDragEvent: 0
  
  ### Add default easing function for rondell to jQuery if missing ###
  unless $.easing.easeInOutQuad        
    $.easing.easeInOutQuad = (x, t, b, c, d) ->
      if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b
   
  # Rondell class holds all rondell items and functions   
  class Rondell
    @rondellCount: 0            # Globally stores the number of rondells for uuid creation
    @activeRondell: null        # Globally stores the last activated rondell for keyboard interaction
    
    constructor: (options, numItems, initCallback=undefined) ->
      @id = Rondell.rondellCount++
      @items = [] # Holds the items
      @maxItems = numItems
      @loadedItems = 0
      @initCallback = initCallback
      
      # Update rondell properties with new options
      if options?.preset of $.rondell.presets
        $.extend(true, @, $.rondell.defaults, $.rondell.presets[options.preset], options or {})
      else
        $.extend(true, @, $.rondell.defaults, options or {})

      # Init some private variables
      $.extend true, @,
        _lastKeyEvent: 0
        autoRotation:
          _timer: -1              
        controls:
          _lastShift: 0
        touch:
          _start: undefined        
          _end: undefined   
        
      # Compute focused item size if not set
      @itemProperties.sizeFocused =
        width: @itemProperties.sizeFocused.width or @itemProperties.size.width * @scaling
        height: @itemProperties.sizeFocused.height or @itemProperties.size.height * @scaling
      
      # Compute size if not set  
      @size = 
        width: @size.width or @center.left * 2
        height: @size.height or @center.top * 2
    
    # Animation functions, can be different for each rondell
    funcLeft: (layerDiff, rondell, idx) ->
      rondell.center.left - rondell.itemProperties.size.width / 2.0 + Math.sin(layerDiff) * rondell.radius.x
    funcTop: (layerDiff, rondell, idx) ->
      rondell.center.top - rondell.itemProperties.size.height / 2.0 + Math.cos(layerDiff) * rondell.radius.y
    funcDiff: (layerDiff, rondell, idx) ->
      Math.pow(Math.abs(layerDiff) / rondell.maxItems, 0.5) * Math.PI
    funcOpacity: (layerDist, rondell, idx) ->
      if rondell.visibleItems > 1 then Math.max(0, 1.0 - Math.pow(layerDist / rondell.visibleItems, 2)) else 0
    funcSize: (layerDist, rondell, idx) ->
      1
    
    showCaption: (layerNum) => 
      # Restore automatic height and show caption
      $('.rondellCaption.overlay', @_getItem(layerNum).object)
      .css(
        height: 'auto'
        overflow: 'auto'
      ).stop(true).fadeTo(300, 1)
      
    hideCaption: (layerNum) =>
      # Fix height before hiding the caption to avoid jumping text when the item changes its size
      caption = $('.rondellCaption.overlay:visible', @_getItem(layerNum).object) 
      caption.css(
        height: caption.height()
        overflow: 'hidden'
      ).stop(true).fadeTo(200, 0)
      
    _getItem: (layerNum) =>
      @items[layerNum - 1]
      
    _initItem: (layerNum, item) =>
      @items[layerNum - 1] = item
      
      # If item is an img tag, wrap with div
      if item.object[0].nodeName.toLowerCase() is "img"
        item.object.wrap("<div/>")
        item.object = item.object.parent()
        item.icon = $('img:first', item.object)
      
      # Wrap other content as overlay caption
      captionContent = item.icon?.siblings()
      if not (captionContent?.length or item.icon) and item.object.children().length
        captionContent = item.object.children()
        
      # Or use title/alt texts as overlay caption
      unless captionContent?.length 
        caption = item.object.attr('title') or item.icon?.attr('title') or item.icon?.attr('alt')  
        if caption
          captionContent = $("<p>#{caption}</p>")
          item.object.append(captionContent)

      # Create overlay from caption if found
      if captionContent?.length
        captionContainer = $('<div class="rondellCaption"></div>')
        captionContainer.addClass('overlay') if item.icon
        captionContent.wrapAll(captionContainer)

      # Add some private variables
      item.animating = false
        
      # Init click events
      item.object
      .addClass("rondellItemNew #{@itemProperties.cssClass}")
      .css
        opacity: 0
        width: item.sizeSmall.width
        height: item.sizeSmall.height
        left: @center.left - item.sizeFocused.width / 2
        top: @center.top - item.sizeFocused.height / 2
      .bind('mouseenter mouseleave click', (e) =>
        switch e.type
          when 'mouseenter' then @_onMouseEnterItem layerNum
          when 'mouseleave' then @_onMouseLeaveItem layerNum
          when 'click'
            console.log layerNum
            e.preventDefault() if @currentLayer isnt layerNum
            @shiftTo(layerNum) if item.object.is(':visible') and not item.hidden
            return false
      )
      
      @loadedItems += 1
      
      @_start() if @loadedItems is @maxItems

    _onMouseEnterItem: (itemIndex) =>
      item = @_getItem(itemIndex)
      if not item.animating and not item.hidden and item.object.is(':visible')
        item.object.addClass('rondellItemHovered').stop(true).animate
            opacity: 1
          , @fadeTime, @funcEase

    _onMouseLeaveItem: (itemIndex) =>
      item = @_getItem(itemIndex)
      item.object.removeClass('rondellItemHovered')

      if not item.animating and not item.hidden
        item.object.stop(true).animate
            opacity: item.lastTarget.opacity
          , @fadeTime, @funcEase
      
    _onloadItem: (itemIndex, obj, copy=undefined) =>
      icon = if obj.is('img') then obj else $('img:first', obj)
      
      isResizeable = icon.hasClass @resizeableClass
      layerNum = itemIndex
    
      itemSize = @itemProperties.size
      focusedSize = @itemProperties.sizeFocused
      scaling = @scaling
      
      # create size vars for the small and focused size
      foWidth = smWidth = copy?.width() or copy?[0].width or icon[0].width or icon.width()
      foHeight = smHeight = copy?.height() or copy?[0].height or icon[0].height or icon.height()
      
      # Delete copy, not needed anymore
      copy?.remove()
      
      # Return if width and height can't be resolved
      return unless smWidth and smHeight
    
      if isResizeable
        # fit to small width
        smHeight *= itemSize.width / smWidth
        smWidth = itemSize.width
          
        # fit to small height
        if smHeight > itemSize.height
          smWidth *= itemSize.height / smHeight
          smHeight = itemSize.height
        
        # fit to focused width
        foHeight *= focusedSize.width / foWidth
        foWidth = focusedSize.width
        
        # fit to focused height
        if foHeight > focusedSize.height
          foWidth *= focusedSize.height / foHeight
          foHeight = focusedSize.height
      else
        # scale to given sizes
        smWidth = itemSize.width
        smHeight = itemSize.height
        foWidth = focusedSize.width
        foHeight = focusedSize.height
        
      # Set vars in item array
      @_initItem(layerNum, 
        object: obj 
        icon: icon
        small: false 
        hidden: false
        resizeable: isResizeable
        sizeSmall: 
          width: smWidth
          height: smHeight
        sizeFocused: 
          width: foWidth
          height: foHeight
      )
      
    _loadItem: (itemIndex, obj) =>
      icon = if obj.is('img') then obj else $('img:first', obj)

      if icon.width() > 0 or (icon[0].complete and icon[0].width > 0)
        # Image is already loaded (i.e. from cache)
        @_onloadItem(itemIndex, obj) 
      else 
        # Create copy of the image and wait for the copy to load to get the real dimensions
        copy = $("<img style=\"display:none\"/>")
        $('body').append(copy)
        copy.one("load", =>
          @_onloadItem(itemIndex, obj, copy)
        ).attr("src", icon.attr("src"))
      
    _start: =>
      # Set currentlayer to the middle item or leave it be if set before and index exists
      if @randomStart
        @currentLayer = Math.round(Math.random() * (@maxItems - 1))
      else
        @currentLayer = Math.max(0, Math.min(@currentLayer or Math.round(@maxItems / 2), @maxItems))
      
      # Set visibleItems to half the maxItems if set to auto
      @visibleItems = Math.max(2, Math.floor(@maxItems / 2)) if @visibleItems is 'auto'
      
      # Create controls
      controls = @controls
      if controls.enabled
        @controls._shiftLeft = $('<a class="rondellControl rondellShiftLeft" href="#"/>').text(@strings.prev).click(@shiftLeft)
        .css(
          left: controls.margin.x
          top: controls.margin.y
          "z-index": @zIndex + @maxItems + 2
        )
          
        @controls._shiftRight = $('<a class="rondellControl rondellShiftRight" href="#/"/>').text(@strings.next).click(@shiftRight)
        .css(
          right: controls.margin.x
          top: controls.margin.y
          "z-index": @zIndex + @maxItems + 2
        )
          
        @container.append(@controls._shiftLeft, @controls._shiftRight)
        
      # Attach keydown event to document for each rondell instance
      $(document).keydown(@keyDown)
        
      # Enable rondell traveling with mousewheel if plugin is available
      @container.bind('mousewheel', @_onMousewheel) if @mousewheel.enabled and $.fn.mousewheel?
      
      # Use modernizr feature detection to enable touch device support
      if @_onMobile()
        # Enable swiping
        @container.bind('touchstart touchmove touchend', @_onTouch) if @touch.enabled
      else
        # Add hover and touch functions to container when we don't have touch support
        @container.bind('mouseenter mouseleave', @_hover)
        
      @container.removeClass "initializing"
          
      # Fire callback after initialization with rondell instance if callback was provided
      @initCallback?(@)
      
      # Move items to starting positions
      @shiftTo @currentLayer
      
    _onMobile: ->
      ###
      Mobile device detection. 
      Check for touch functionality is currently enough.
      ###
      return Modernizr?.touch
      
    _onMousewheel: (e, d, dx, dy) =>
      ###
      Allows rondell traveling with mousewheel.
      Requires mousewheel plugin for jQuery. 
      ###
      return unless (@mousewheel.enabled and @isFocused())

      now = (new Date()).getTime()
      return if now - @mousewheel._lastShift < @mousewheel.minTimeBetweenShifts
      
      viewport = $ window
      viewportTop = viewport.scrollTop()
      viewportBottom = viewportTop + viewport.height()
      
      selfYCenter = @container.offset().top + @container.outerHeight() / 2
      
      if selfYCenter > viewportTop and selfYCenter < viewportBottom and Math.abs(dx) >= @mousewheel.threshold
        if dx < 0 then @shiftLeft() else @shiftRight()
        @mousewheel._lastShift = now
      
    _onTouch: (e) =>
      return unless @touch.enabled
      
      touch = e.originalEvent.touches[0] or e.originalEvent.changedTouches[0]
      
      switch e.type
        when 'touchstart'
          @touch._start = 
            x: touch.pageX
            y: touch.pageY
        when 'touchmove'
          e.preventDefault() if @touch.preventDefaults
          @touch._end =
            x: touch.pageX
            y: touch.pageY
        when 'touchend'
          if @touch._start and @touch._end
            # Check if delta x is greater than our threshold for swipe detection
            changeX = @touch._end.x - @touch._start.x
            if Math.abs(changeX) > @touch.threshold
              if changeX > 0
                @shiftLeft()
              if changeX < 0
                @shiftRight()
              
            # Reset end position
            @touch._start = @touch._end = undefined
            
      true
      
    _hover: (e) =>
      ###
      Shows/hides rondell controls.
      Starts/pauses autorotation.
      Updates active rondell id.
      ###
      
      # Start or stop auto rotation if enabled
      paused = @autoRotation.paused
      if e.type is 'mouseenter'
        # Set active rondell id if hovered
        Rondell.activeRondell = @id
        
        @hovering = true
        unless paused
          @autoRotation.paused = true
          @showCaption(@currentLayer)
      else
        @hovering = false
        if paused and not @autoRotation.once
          @autoRotation.paused = false
          @_autoShiftInit()
        @hideCaption(@currentLayer) unless @alwaysShowCaption
            
      # Show or hide controls if they exist
      @_refreshControls() if @controls.enabled
      
    layerFadeIn: (layerNum) =>
      item = @_getItem(layerNum)
      item.small = false
      itemFocusedWidth = item.sizeFocused.width
      itemFocusedHeight = item.sizeFocused.height

      newTarget =
        width: itemFocusedWidth
        height: itemFocusedHeight
        left: @center.left - itemFocusedWidth / 2
        top: @center.top - itemFocusedHeight / 2
        opacity: 1
      item.lastTarget = newTarget
      item.animating = true
      
      # Move item to center position and fade in
      item.object.stop(true)
      .css
        zIndex: @zIndex + @maxItems
        display: "block"
      .animate newTarget, @fadeTime, @funcEase, =>
        item.animating = false
        item.object.addClass "rondellItemFocused"
        @_autoShiftInit()
        @showCaption(layerNum) if @hovering or @alwaysShowCaption or @_onMobile()
      
      if item.icon and not item.resizeable
        margin = (@itemProperties.sizeFocused.height - item.icon.height()) / 2
        item.icon.stop(true).animate(
            marginTop: margin
            marginBottom: margin
          , @fadeTime)
          
    layerFadeOut: (layerNum) =>
      item = @_getItem(layerNum)
      
      layerDist = Math.abs(layerNum - @currentLayer)
      layerPos = layerNum
      
      # Find new layer position
      if layerDist > @visibleItems and layerDist > @maxItems / 2 and @repeating
        if layerNum > @currentLayer then layerPos -= @maxItems else layerPos += @maxItems
        layerDist = Math.abs(layerPos - @currentLayer)

      # Get the absolute layer number difference
      layerDiff = @funcDiff(layerPos - @currentLayer, @, layerNum)
      layerDiff *= -1 if layerPos < @currentLayer
      
      itemWidth = item.sizeSmall.width * @funcSize(layerDiff, @)
      itemHeight = item.sizeSmall.height * @funcSize(layerDiff, @)
      newZ = @zIndex + (if layerDiff < 0 then layerPos else -layerPos)
      
      # Modify fading time by items distance to focused item
      fadeTime = @fadeTime + @itemProperties.delay * layerDist
        
      newTarget =
        width: itemWidth
        height: itemHeight
        left: @funcLeft(layerDiff, @, layerNum) + (@itemProperties.size.width - itemWidth) / 2
        top: @funcTop(layerDiff, @, layerNum) + (@itemProperties.size.height - itemHeight) / 2
        opacity: 0
        
      # Smooth animation when item is visible
      if layerDist <= @visibleItems
        @hideCaption layerNum

        newTarget.opacity = @funcOpacity layerDiff, @, layerNum

        lastTarget = item.lastTarget
        return if lastTarget \
          and lastTarget.width is newTarget.width \
          and lastTarget.height is newTarget.height \
          and lastTarget.left is newTarget.left \
          and lastTarget.top is newTarget.top \
          and lastTarget.opacity is newTarget.opacity

        item.lastTarget = newTarget
        item.animating = true

        item.object.removeClass("rondellItemNew rondellItemFocused").stop(true)
        .css
          zIndex: newZ
          display: "block"
        .animate newTarget, fadeTime, @funcEase, =>
          item.animating = false
          if newTarget.opacity < @opacityMin
            item.hidden = true
            item.object.css "display", "none"
          else
            item.hidden = false
            item.object.css "display", "block"
        
        item.hidden = false
        unless item.small
          item.small = true
          if item.icon and not item.resizeable
            margin = (@itemProperties.size.height - item.icon.height()) / 2
            item.icon.stop(true).animate
                marginTop: margin
                marginBottom: margin
              , fadeTime
      else if item.hidden
        # Update position even if out of view to fix animation when reappearing
        item.object.css newTarget
      else
        # Hide items which are moved out of view
        item.hidden = true
        item.animating = true

        item.object.stop(true)
        .css('z-index', newZ)
        .animate newTarget, fadeTime / 2, @funcEase, =>
          item.animating = false
          @hideCaption layerNum

      item.lastTarget = newTarget

    shiftTo: (layerNum) =>
      if @repeating 
        # Update current layer number if carousel reached it's limit
        if layerNum < 1 
          layerNum = @maxItems
        else if layerNum > @maxItems 
          layerNum = 1
      
      if layerNum > 0 and layerNum <= @maxItems
        @currentLayer = layerNum
        
        # Hide all layers except the current layer
        @layerFadeOut(i) for i in [1..@maxItems] when i isnt @currentLayer
        @layerFadeIn(@currentLayer)
        
      @_refreshControls()
      @onAfterShift? layerNum
        
    _refreshControls: =>
      return unless @controls.enabled
      
      @controls._shiftLeft.stop().fadeTo(@controls.fadeTime, if (@currentLayer > 1 or @repeating) and @hovering then 1 else 0)
      @controls._shiftRight.stop().fadeTo(@controls.fadeTime, if (@currentLayer < @maxItems or @repeating) and @hovering then 1 else 0)
      
    shiftLeft: (e) => 
      e?.preventDefault()
      @shiftTo @currentLayer - 1
        
    shiftRight: (e) => 
      e?.preventDefault()
      @shiftTo @currentLayer + 1
        
    _autoShiftInit: =>
      autoRotation = @autoRotation
      if @isActive() and autoRotation.enabled and autoRotation._timer < 0
        # store timer id and delay next shift
        autoRotation._timer = window.setTimeout @_autoShift, autoRotation.delay

    _autoShift: =>
      # Kill timer id and shift if rondell is active
      @autoRotation._timer = -1
      if @isActive() and @isFocused() and not @autoRotation.paused
        if @autoRotation.direction then @shiftRight() else @shiftLeft()
      else
        # Try to autoshift again after a while
        @_autoShiftInit()
        
    isActive: ->
      true
      
    isFocused: =>
      Rondell.activeRondell is @id
    
    keyDown: (e) =>
      # Ignore event if some time has passed since last keyevent
      now = (new Date()).getTime()
      return if @_lastKeyEvent > now - @keyDelay

      if @isActive() and @isFocused()
        # Clear current rotation timer on user interaction
        if @autoRotation._timer >= 0
          window.clearTimeout(@autoRotation._timer) 
          @autoRotation._timer = -1

        @_lastKeyEvent = now
          
        switch e.which
          # arrow left
          when 37 then @shiftLeft(e)
          # arrow right 
          when 39 then @shiftRight(e) 


  class RondellScrollbar
    
    constructor: (container, options) ->
      @id = Wonderbar.wonderbarCount++
      @container = container.addClass "rondell-scrollbar"
      
      $.extend true, @, $.rondell.defaults.scrollbar, options
        
      @_initControls()
        
    _initControls: =>
      @scrollLeftControl = $("<div class=\"wonderbar-scroll-left\"/>")
        .bind "click", @scrollLeft
        
      @scrollRightControl = $("<div class=\"wonderbar-scroll-right\"/>")
        .bind "click", @scrollRight
        
      @scrollControl = $("<div class=\"wonderbar-scroll-control\"/>").css
        left: @container.innerWidth() / 2
        
      @scrollBackground = $("<div class=\"wonderbar-background\"/>")
        
      @container.bind "mousedown mouseup click", @doControl
      window.bind "mousemove", @doWindowControl
        
      @container.append @scrollBackground, @scrollLeftControl, @scrollRightControl, @scrollControl
      
    updatePosition: (position) =>
      return if position < @start or position > @end or position is @position
      
      @position = position
      
      # Fire callback with new position
      @onScroll?(position)
      
    scrollTo: (x, duration=@animationDuration) =>
      innerWidth = @container.innerWidth()
      return if x <= 0 or x >= innerWidth
      
      @scrollControl.stop(true).animate(
        left: x
      , duration, @easing)
      
      # Translate event coordinates to new position between start and end option
      newPosition = Math.round(x / innerWidth * (@end - @start) + @start)
      @updatePosition(newPosition) if newPosition isnt @position
      
    setPosition: (position) =>
      return if position < @start or position > @end or position is @position
      
      @position = position 
      
      # Translate position to new position for control dot in container
      @scrollTo(Math.round((position - @start) / (@end - @start) * @container.innerWidth()))

    doWindowControl: (e) =>
      switch e.type
        when "mousemove"
          return unless @drag.dragging
          @scrollTo(e.offsetX, 0) if e.target is @container[0]
      
    doControl: (e) =>
      e.preventDefault()
      
      switch e.type
        when "mousedown" then @drag.dragging = e.target is @scrollControl[0]
        when "mouseup" then @drag.dragging = false
        when "click" then @scrollTo(e.offsetX) if e.target is @container[0]
      
    scrollLeft: (e) =>
      e.preventDefault()
      @setPosition(@position - @stepSize)
      
    scrollRight: (e) => 
      e.preventDefault() 
      @setPosition(@position + @stepSize)
  
  $.fn.rondell = (options={}, callback=undefined) ->
    # Create new rondell instance
    rondell = new Rondell(options, @length, callback)
    
    # Wrap elements in new container
    rondell.container = @wrapAll($("<div class=\"rondellContainer initializing rondellTheme_#{rondell.theme}\"/>").css(rondell.size)).parent()
      
    # Show items hidden parent container to prevent graphical glitch
    rondell.container.parent().show() if rondell.showContainer
     
    # Setup each item
    @each (idx) ->
      obj = $(@)
      itemIndex = idx + 1
      
      if obj.is('img') or $('img:first', obj).length
        rondell._loadItem(itemIndex, obj)
      else
        # Init item without an icon
        rondell._initItem(itemIndex, 
          object: obj 
          icon: null
          small: false 
          hidden: false
          resizeable: false
          sizeSmall: rondell.itemProperties.size
          sizeFocused: rondell.itemProperties.sizeFocused
        )
        
    # Return rondell instance
    rondell
    
)(jQuery) 
