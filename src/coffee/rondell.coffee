###!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 1.0.2
  @date 04/01/2013
  @category jQuery plugin
  @copyright (c) 2009-2013 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  ### Global rondell plugin properties ###
  $.rondell ||=
    version: '1.0.2'
    name: 'rondell'
    lightbox:
      instance: undefined
      template: $.trim '
        <div class="rondell-lightbox">
          <div class="rondell-lightbox-overlay">&nbsp;</div>
          <div class="rondell-lightbox-content">
            <div class="rondell-lightbox-inner"/>
            <div class="rondell-lightbox-close">&Chi;</div>
            <div class="rondell-lightbox-prev">&nbsp;</div>
            <div class="rondell-lightbox-position">1</div>
            <div class="rondell-lightbox-next">&nbsp;</div>
          </div>
        </div>'
    defaults:
      showContainer: true       # When the plugin has finished initializing $.show() will be called on the items container
      classes:
        container: "rondell-container"
        initializing: "rondell-initializing"
        themePrefix: "rondell-theme"
        caption: "rondell-caption"
        noScale: "no-scale"
        item: "rondell-item"
        image: "rondell-item-image"
        resizeable: "rondell-item-resizeable"
        small: "rondell-item-small"
        hidden: "rondell-item-hidden"
        loading: "rondell-item-loading"
        hovered: "rondell-item-hovered"
        overlay: "rondell-item-overlay"
        focused: "rondell-item-focused"
        crop: "rondell-item-crop"
        error: "rondell-item-error"
        control: "rondell-control"
        shiftLeft: "rondell-shift-left"
        shiftRight: "rondell-shift-right"
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
        size:
          width: 150
          height: 150
        sizeFocused:
          width: 0
          height: 0
      lightbox:
        enabled: true
        displayReferencedImages: true
      imageFiletypes: [
        'png'
        'jpg'
        'jpeg'
        'gif'
        'bmp'
      ]
      repeating: true           # Will show first item after last item and so on
      wrapIndices: true         # Will modify relative item indices to fix positioning when repeating
      switchIndices: false      # After a shift the last focused item and the new one will switch indices
      alwaysShowCaption: false  # Don't hide caption on mouseleave
      captionsEnabled: true
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
        loadingError: 'An error occured while loading <b>%s</b>'
        more: 'More...'
      mousewheel:
        enabled: true
        threshold: 0
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
      cropThumbnails: false
      scrollbar:
        enabled: false
        orientation: "bottom"
        start: 1
        end: 100
        stepSize: 1
        keepStepOrder: true
        position: 1
        padding: 10
        style:
          width: "100%"
          height: 20
          left: "auto"
          right: "auto"
          top: "auto"
          bottom: "auto"
        repeating: false
        onScroll: undefined
        scrollOnHover: false
        scrollOnDrag: true
        animationDuration: 300
        easing: "easeInOutQuad"
        classes:
          container: "rondell-scrollbar"
          control: "rondell-scrollbar-control"
          dragging: "rondell-scrollbar-dragging"
          background: "rondell-scrollbar-background"
          scrollLeft: "rondell-scrollbar-left"
          scrollRight: "rondell-scrollbar-right"
          scrollInner: "rondell-scrollbar-inner"

  ### Add default easing function for rondell to jQuery if missing ###
  $.easing.easeInOutQuad ||= (x, t, b, c, d) ->
    if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b

  # Custom set timeout call
  delayCall = (delay, callback) -> setTimeout callback, delay

  # Cache some jQuery selectors
  $window = $ window
  $document = $ document

  # Rondell class holds all rondell items and functions
  class Rondell
    # Globally stores the number of rondells for uuid creation
    @rondellCount: 0
    # Globally stores the last activated rondell for keyboard interaction
    @activeRondell: null

    constructor: (items, options, numItems, initCallback=undefined) ->
      @id = ++Rondell.rondellCount
      @items = [] # Holds the items
      @maxItems = numItems
      @loadedItems = 0
      @initCallback = initCallback

      # First rondell should be active at the start
      Rondell.activeRondell = @id if @id is 1

      # Update rondell properties with new options
      if options?.preset of $.rondell.presets
        $.extend true, @, $.rondell.defaults, $.rondell.presets[options.preset], options or {}
      else
        $.extend true, @, $.rondell.defaults, options or {}

      # Init some private variables
      $.extend true, @,
        _dimensions:
          computed: false
        _lastKeyEvent: 0
        _windowFocused: true
        _focusedIndex: @currentLayer
        _itemIndices: { 0: 0 }
        autoRotation:
          _timer: -1
        controls:
          _lastShift: 0
        touch:
          _start: undefined
          _end: undefined
        scrollbar:
          _instance: null

      # Compute focused item size if not set
      @itemProperties.sizeFocused =
       width: @itemProperties.sizeFocused.width or @itemProperties.size.width * @scaling
       height: @itemProperties.sizeFocused.height or @itemProperties.size.height * @scaling

      # Compute size if not set
      @size =
        width: @size.width or @center.left * 2
        height: @size.height or @center.top * 2

      # Wrap elements in new container and add some css
      containerWrap = $("<div/>")
        .css(@size)
        .addClass("#{@classes.initializing} #{@classes.container} #{@classes.themePrefix}-#{@theme}")

      @container = items.wrapAll(containerWrap).parent()
        .addClass("rondell-instance-#{@id}")
        .data('api', @)

      # Show items hidden parent container to prevent graphical glitch
      @container.parent().show() if @showContainer

      # Create scrollbar
      if @scrollbar.enabled
        scrollbarContainer = $ '<div/>'
        @container.append scrollbarContainer

        $.extend true, @scrollbar,
          onScroll: @shiftTo
          end: @maxItems
          position: @currentLayer
          repeating: @repeating

        @scrollbar._instance = new $.rondell.RondellScrollbar(scrollbarContainer, @scrollbar)

    log: (msg) ->
      console?.log msg

    equals: (objA, objB) ->
      return false for key, value of objA when objB[key] isnt value
      return false for key, value of objB when objA[key] isnt value
      true

    # Animation functions, can be different for each rondell
    funcLeft: (l, r, i) ->
      r.center.left - r.itemProperties.size.width / 2.0 + Math.sin(l) * r.radius.x
    funcTop: (l, r, i) ->
      r.center.top - r.itemProperties.size.height / 2.0 + Math.cos(l) * r.radius.y
    funcDiff: (d, r, i) ->
      Math.pow(Math.abs(d) / r.maxItems, 0.5) * Math.PI
    funcOpacity: (l, r, i) ->
      if r.visibleItems > 1 then Math.max(0, 1.0 - Math.pow(l / r.visibleItems, 2)) else 0
    funcSize: (l, r, i) ->
      1

    fitToContainer: =>
      # Get new max size
      parentContainer = @container.parent()
      newWidth = parentContainer.innerWidth()
      newHeight = parentContainer.innerHeight()

      # Check if size relations have been stored before and create them if not
      unless @_dimensions.computed
        oldWidth = @size.width
        oldHeight = @size.height

        $.extend true, @_dimensions,
          computed: true
          center:
            left: @center.left / oldWidth
            top: @center.top / oldHeight
          radius:
            x: @radius.x / oldWidth
            y: @radius.y / oldHeight
          controls:
            margin:
              x: @controls.margin.x / oldWidth
              y: @controls.margin.y / oldHeight
          itemProperties:
            size:
              width: @itemProperties.size.width / oldWidth
              height: @itemProperties.size.height / oldHeight
            sizeFocused:
              width: @itemProperties.sizeFocused.width / oldWidth
              height: @itemProperties.sizeFocused.height / oldHeight

      # Update rondell dimensions
      $.extend true, @,
        size:
          width: newWidth
          height: newHeight
        center:
          left: @_dimensions.center.left * newWidth
          top: @_dimensions.center.top * newHeight
        radius:
          x: @_dimensions.radius.x * newWidth
          y: @_dimensions.radius.y * newHeight
        controls:
          margin:
            x: @_dimensions.controls.margin.x * newWidth
            y: @_dimensions.controls.margin.y * newHeight
        itemProperties:
          size:
            width: @_dimensions.itemProperties.size.width * newWidth
            height: @_dimensions.itemProperties.size.height * newHeight
          sizeFocused:
            width: @_dimensions.itemProperties.sizeFocused.width * newWidth
            height: @_dimensions.itemProperties.sizeFocused.height * newHeight

      # Fit container
      @container.css @size

      # Move everything to a new position
      @shiftTo @currentLayer

    _onMouseEnterItem: (idx) =>
      @_getItem(idx).onMouseEnter()

    _onMouseLeaveItem: (idx) =>
      @_getItem(idx).onMouseLeave()

    _getItem: (idx) =>
      @items[idx - 1]

    _loadItem: (idx, obj) =>
      # Create new rondell item and store a reference
      item = new $.rondell.RondellItem(idx, obj, @)
      @items[idx - 1] = item
      @_itemIndices[idx] = idx

      # Initialize item
      item.init()

      # Start rondell after adding the last item
      @_start() if ++@loadedItems is @maxItems

    onItemInit: (idx) =>
      item = @_getItem idx
      # Move item to initial position
      if idx is @currentLayer
        item.prepareFadeIn()
      else
        item.prepareFadeOut()
      item.runAnimation true

    _start: =>
      # Set currentlayer to the middle item or leave it be if set before and index exists
      if @randomStart
        @currentLayer = Math.round(Math.random() * (@maxItems - 1))
      else
        @currentLayer = Math.max(0, Math.min(@currentLayer or Math.round(@maxItems / 2), @maxItems))

      # Set visibleItems to half the maxItems if set to auto
      @visibleItems = Math.max(2, Math.floor(@maxItems / 2)) if @visibleItems is "auto"

      # Create controls
      controls = @controls
      if controls.enabled
        @controls._shiftLeft = $("<a href=\"#/\"/>")
          .addClass("#{@classes.control} #{@classes.shiftLeft}")
          .html(@strings.prev)
          .click(@shiftLeft)
          .css
            left: controls.margin.x
            top: controls.margin.y
            zIndex: @zIndex + @maxItems + 2

        @controls._shiftRight = $("<a href=\"#/\"/>")
          .addClass("#{@classes.control} #{@classes.shiftRight}")
          .html(@strings.next)
          .click(@shiftRight)
          .css
            right: controls.margin.x
            top: controls.margin.y
            zIndex: @zIndex + @maxItems + 2

        @container.append @controls._shiftLeft, @controls._shiftRight

      @bindEvents()

      @container.removeClass @classes.initializing

      # Fire callback after initialization with rondell instance if callback was provided
      @initCallback?(@)

      # Move items to starting positions
      @_focusedItem ?= @_getItem @currentLayer
      @shiftTo @currentLayer

    bindEvents: =>
      # Attach keydown event to document for each rondell instance
      $document.keydown @keyDown

      # Attach window focus event to window do disable rondell when window is inactive
      $window
        .blur(@onWindowBlur)
        .focus(@onWindowFocus)

      $document
        .focusout(@onWindowBlur)
        .focusin(@onWindowFocus)

      # Enable rondell traveling with mousewheel if plugin is available
      if @mousewheel.enabled and $.fn.mousewheel?
        @container.bind "mousewheel.rondell", @_onMousewheel

      # Use modernizr feature detection to enable touch device support
      if @_onMobile()
        # Enable swiping
        if @touch.enabled
          @container.bind("touchstart.rondell touchmove.rondell touchend.rondell", @_onTouch)
      else
        # Add hover and touch functions to container when we don't have touch support
        @container.bind "mouseenter.rondell mouseleave.rondell", @_hover

      rondell = @

      # Delegate click and mouse events events to rondell items
      @container
      .delegate ".#{@classes.item}", "click.rondell", (e) ->
        item = $(@).data "item"
        if rondell._focusedItem.id is item.id
          if rondell.lightbox.enabled
            e.preventDefault()
            rondell.showLightbox()
        else
          e.preventDefault()
          if not item.hidden and item.object.is ":visible"
            rondell.shiftTo item.currentSlot
      .delegate ".#{@classes.item}", "mouseenter.rondell mouseleave.rondell", (e) ->
          item = $(@).data "item"
          if e.type is "mouseenter"
            rondell._onMouseEnterItem item.id
          else
            rondell._onMouseLeaveItem item.id

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
      return unless @mousewheel.enabled and @isFocused()

      now = (new Date()).getTime()
      return if now - @mousewheel._lastShift < @mousewheel.minTimeBetweenShifts

      viewportTop = $window.scrollTop()
      viewportBottom = viewportTop + $window.height()

      selfYCenter = @container.offset().top + @container.outerHeight() / 2

      if selfYCenter > viewportTop and selfYCenter < viewportBottom and Math.abs(dx) > @mousewheel.threshold
        e.preventDefault()
        if dx < 0 then @shiftLeft() else @shiftRight()
        @mousewheel._lastShift = now

    _onTouch: (e) =>
      return unless @touch.enabled

      touch = e.originalEvent.touches[0] or e.originalEvent.changedTouches[0]

      switch e.type
        when "touchstart"
          @touch._start =
            x: touch.pageX
            y: touch.pageY
        when "touchmove"
          e.preventDefault() if @touch.preventDefaults
          @touch._end =
            x: touch.pageX
            y: touch.pageY
        when "touchend"
          if @touch._start and @touch._end
            # Check if delta x is greater than our threshold for swipe detection
            changeX = @touch._end.x - @touch._start.x
            if Math.abs(changeX) > @touch.threshold
              if changeX > 0
                @shiftLeft()
              else if changeX < 0
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
      if e.type is "mouseenter"
        # Set active rondell id if hovered
        Rondell.activeRondell = @id

        @hovering = true
        unless paused
          @autoRotation.paused = true
          @_focusedItem.showCaption()
      else
        @hovering = false
        if paused and not @autoRotation.once
          @autoRotation.paused = false
          @_autoShiftInit()
        @_focusedItem.hideCaption() unless @alwaysShowCaption

      # Show or hide controls if they exist
      @_refreshControls() if @controls.enabled

    shiftTo: (idx, keepOrder=false) =>
      return unless idx?

      # Modify layer number when using index switch because
      # we have to ignore the slot which was initially focused
      if not keepOrder and @switchIndices and idx isnt @currentLayer and @getIndexInRange(idx) is @_focusedItem.currentSlot
        # Get items relative distance
        [distance, relativeIndex] = @getRelativeItemPosition idx, true
        if relativeIndex > @currentLayer then idx++ else idx--

      # Fix new layer number depending on the repeating option
      idx = @getIndexInRange idx

      # Get the items id in the selected layer slot
      newItemIndex = @_itemIndices[idx]
      newItem = @_getItem newItemIndex

      # Switch item indices if flag is set
      if @switchIndices
        # Switch indices in list
        @_itemIndices[idx] = @_focusedItem.id
        @_itemIndices[@_focusedItem.currentSlot] = newItemIndex

        # Tell items about their new slots
        newItem.currentSlot = @_focusedItem.currentSlot
        @_focusedItem.currentSlot = idx

      # Set new focused item
      @_focusedItem = newItem

      # Store the now active layer index
      @currentLayer = idx

      # Prepare animation targets for all items
      @_focusedItem.prepareFadeIn()
      item.prepareFadeOut() for item in @items when item isnt @_focusedItem

      # Run all animations
      item.runAnimation() for item in @items

      # Prepare next shift
      @_autoShiftInit()

      # Update buttons e.g. fadein/out
      @_refreshControls()

      # Update lightbox if enabled
      if @lightbox.enabled and lightboxIsVisible()
        @showLightbox()

      # Update scrollbar with unmodified idx to prevent jumps
      if @scrollbar.enabled
        scrollbarIdx = idx
        # Fix scrollbar index position for unreachable focus item index
        if idx is @_focusedItem.currentSlot
          scrollbarIdx =  @_focusedItem.currentSlot + 1
        @scrollbar._instance.setPosition(scrollbarIdx, false)

      # Fire shift callback
      @onAfterShift? idx

    getRelativeItemPosition: (idx, wrapIndices=@wrapIndices) =>
      distance = Math.abs(idx - @currentLayer)
      relativeIndex = idx

      # Find new layer position if rondell is repeating and indices are wrapped
      if distance > @visibleItems and distance > @maxItems / 2 and @repeating and wrapIndices
        if idx > @currentLayer
          relativeIndex -= @maxItems
        else
          relativeIndex += @maxItems
        distance = Math.abs(relativeIndex - @currentLayer)

      [distance, relativeIndex]

    getIndexInRange: (idx) =>
      if @repeating
        if idx < 1
          idx += @maxItems
        else if idx > @maxItems
          idx -= @maxItems
      else
        if idx < 1
          idx = 1
        else if idx > @maxItems
          idx = @maxItems
      idx

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
      if @isActive() and @isFocused() and not lightboxIsVisible() and not @autoRotation.paused
        if @autoRotation.direction then @shiftRight() else @shiftLeft()
      else
        # Try to autoshift again after a while
        @_autoShiftInit()

    onWindowFocus: =>
      @_windowFocused = true

    onWindowBlur: =>
      @_windowFocused = false

    isActive: ->
      true

    isFocused: =>
      @_windowFocused and Rondell.activeRondell is @id

    keyDown: (e) =>
      return unless @isActive() and @isFocused()

      # Ignore event if some time has passed since last keyevent
      now = (new Date()).getTime()
      return if @_lastKeyEvent > now - @keyDelay

      # Clear current rotation timer on user interaction
      if @autoRotation._timer >= 0
        window.clearTimeout @autoRotation._timer
        @autoRotation._timer = -1

      @_lastKeyEvent = now

      # IE uses keyCode
      keyCode = e.which or e.keyCode

      switch keyCode
        # arrow left to shift left
        when 37 then @shiftLeft(e)
        # arrow right to shift right
        when 39 then @shiftRight(e)
        # escape hides lightbox
        when 27 then closeLightbox()

    showLightbox: =>
      lightbox = getLightbox()
      lightboxContent = $ '.rondell-lightbox-content', lightbox

      # Display lightbox but hide content at first
      unless lightboxIsVisible()
        lightbox.add(lightboxContent).css 'display', 'none'

      # Hide content then update lightbox
      lightboxContent
        .stop().fadeTo 100, 0, =>
          # Update content and remove style parameters
          content = $('.rondell-lightbox-inner', lightboxContent).html @_focusedItem.object.html()

          # Update position text
          $('.rondell-lightbox-position')
            .text "#{@currentLayer} | #{@maxItems}"

          # Remove overlay style
          $(".#{@classes.overlay}", content).style = ''

          # Add link to source if item is link
          if @_focusedItem.isLink
            linkUrl = @_focusedItem.object.attr 'href'
            linkTarget = @_focusedItem.object.attr 'target'

            $(".#{@classes.caption}", content)
              .append("<a href='#{linkUrl}' target='#{linkTarget}'>#{@strings.more}</a>")
              .attr('style', '')

          icon = $ ".#{@classes.image}", content

          # Use referenced image if given
          if icon and @_focusedItem.referencedImage
            # Call removeAttr for each attribute to support jQuery < 1.7
            icon.removeAttr(attr) for attr in ['style', 'width', 'height']
            # Set new src for the icon
            icon[0].src = @_focusedItem.referencedImage

          if icon and not icon[0].complete
            # Create copy of the image and wait for the copy to load to get the real dimensions
            iconCopy = $ "<img style=\"display:none\"/>"
            lightboxContent.append @iconCopy

            iconCopy.one('load', updateLightbox)[0].src = @_focusedItem.referencedImage
          else
            # Async call to update the lightbox to allow the layout to update
            setTimeout updateLightbox, 0

  # Get api for active rondell instance
  getActiveRondell = ->
    return $(".rondell-instance-#{Rondell.activeRondell}").data 'api'

  # Resize the lightbox to fit the current viewport
  resizeTimer = 0
  resizeLightbox = ->
    clearTimeout resizeTimer
    resizeTimer = setTimeout updateLightbox, 200

  # Checks if lightbox is visible
  lightboxIsVisible = ->
    $.rondell.lightbox.instance?.is(':visible');

  # Private function to hide the lightbox
  closeLightbox = ->
    if lightboxIsVisible()
      getLightbox().stop().fadeOut 150

  # Private function for getting the lightbox within the rondell
  getLightbox = ->
    unless $.rondell.lightbox.instance
      # Add lightbox to dom when required
      lightbox = $.rondell.lightbox.instance = $($.rondell.lightbox.template)
        .appendTo($('body'))

      # Add click event to lightbox overlay to hide lightbox
      $('.rondell-lightbox-overlay, .rondell-lightbox-close', lightbox)
        .bind 'click.rondell', closeLightbox

      # Bind events to controls
      $('.rondell-lightbox-prev', lightbox)
        .bind 'click.rondell', ->
          getActiveRondell().shiftLeft()

      $('.rondell-lightbox-next', lightbox)
        .bind 'click.rondell', ->
          getActiveRondell().shiftRight()

      # Add resize event to window for updating the overlay size
      $window.bind 'resize.rondell', resizeLightbox

      # Add mousewheel event to lightbox and delegate to currently active rondell
      lightbox.bind "mousewheel.rondell", (e, d, dx, dy) ->
        getActiveRondell()._onMousewheel e, d, dx, dy

    $.rondell.lightbox.instance

  # Private function to refresh the lightbox,
  # called by showLightbox within a rondell
  updateLightbox = ->
    $lightbox = getLightbox()
    $lightboxContent = $ '.rondell-lightbox-content', $lightbox
    winWidth = $window.innerWidth()
    winHeight = $window.innerHeight()
    windowPadding = 20

    focusedItem = getActiveRondell()._focusedItem

    image = $ 'img:first', $lightboxContent
    if image.length
      # Store original image size
      unless focusedItem.lightboxImageWidth
        focusedItem.lightboxImageWidth = image[0].width
        focusedItem.lightboxImageHeight = image[0].height

      imageWidth = focusedItem.lightboxImageWidth
      imageHeight = focusedItem.lightboxImageHeight
      imageDimension = imageWidth / imageHeight

      maxWidth = winWidth - windowPadding * 2
      maxHeight = winHeight - windowPadding * 2

      if imageWidth > maxWidth
        imageWidth = maxWidth
        imageHeight = imageWidth / imageDimension

      if imageHeight > maxHeight
        imageHeight = maxHeight
        imageWidth = imageHeight * imageDimension

      image
        .attr('width', imageWidth)
        .attr('height', imageHeight)

    $lightbox.css 'display', 'block'
    newWidth = $lightboxContent.outerWidth()
    newHeight = $lightboxContent.outerHeight()

    newProps =
      marginLeft: - newWidth / 2
      top: Math.max((winHeight - newHeight) / 2, 20)

    if $lightboxContent.css('opacity') < 1
      $lightboxContent.css(newProps).fadeTo 200, 1
    else
      newProps.opacity = 1
      $lightboxContent.animate newProps, 200
    $lightbox.stop().fadeTo 150, 1

  # Add rondell to jQuery
  $.fn.rondell = (options={}, callback=undefined) ->
    # Create new rondell instance
    rondell = new Rondell(@, options, @length, callback)

    # Setup each item
    @each (idx) ->
      rondell._loadItem idx + 1, $(@)

    # Return rondell instance
    rondell

)(jQuery)
