###!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 1.1.0
  @date 10/27/2013
  @category jQuery plugin
  @copyright (c) 2009-2013 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($, win, doc) ->
  # Cache some jQuery selectors
  $window = $ win
  $document = $ doc

  rondellBaseClass = 'rondell'
  classInstance = "#{rondellBaseClass}-instance"
  classContainer = "#{rondellBaseClass}-container"
  classInitializing = "#{rondellBaseClass}-initializing"
  classThemePrefix = "#{rondellBaseClass}-theme"
  classCaption = "#{rondellBaseClass}-caption"
  classControl = "#{rondellBaseClass}-control"
  classShiftLeft = "#{rondellBaseClass}-shift-left"
  classShiftRight = "#{rondellBaseClass}-shift-right"
  classNoScale = "#{rondellBaseClass}-no-scale"

  classItem = "#{rondellBaseClass}-item"
  classItemImage = "#{classItem}-image"
  classItemResizeable = "#{classItem}-resizeable"
  classItemSmall = "#{classItem}-small"
  classItemHidden = "#{classItem}-hidden"
  classItemLoading = "#{classItem}-loading"
  classItemHovered = "#{classItem}-hovered"
  classItemOverlay = "#{classItem}-overlay"
  classItemFocused = "#{classItem}-focused"
  classItemCrop = "#{classItem}-crop"
  classItemError = "#{classItem}-error"

  classLightbox = "#{rondellBaseClass}-lightbox"
  classLightboxOverlay = "#{classLightbox}-overlay"
  classLightboxContent = "#{classLightbox}-content"
  classLightboxInner = "#{classLightbox}-inner"
  classLightboxClose = "#{classLightbox}-close"
  classLightboxPrev = "#{classLightbox}-prev"
  classLightboxPosition = "#{classLightbox}-position"
  classLightboxNext = "#{classLightbox}-next"

  classScrollbar = "#{rondellBaseClass}-scrollbar"
  classScrollbarControl = "#{classScrollbar}-control"
  classScrollbarDragging = "#{classScrollbar}-dragging"
  classScrollbarBackground = "#{classScrollbar}-background"
  classScrollbarLeft = "#{classScrollbar}-left"
  classScrollbarRight = "#{classScrollbar}-right"
  classScrollbarInner = "#{classScrollbar}-inner"

  eventClick = "click.#{rondellBaseClass}"
  eventResize = "resize.#{rondellBaseClass}"
  eventMousewheel = "mousewheel.#{rondellBaseClass}"

  ### Global rondell plugin properties ###
  $.rondell ||=
    version: '1.1.0'
    name: 'rondell'
    lightbox:
      instance: undefined
      template: $.trim "
        <div class='#{classLightbox}'>
          <div class='#{classLightboxOverlay}'>&nbsp;</div>
          <div class='#{classLightboxContent}'>
            <div class='#{classLightboxInner}'/>
            <div class='#{classLightboxClose}'>&Chi;</div>
            <div class='#{classLightboxPrev}'>&nbsp;</div>
            <div class='#{classLightboxPosition}'>1</div>
            <div class='#{classLightboxNext}'>&nbsp;</div>
          </div>
        </div>"
    defaults:
      showContainer: true       # When the plugin has finished initializing $.show() will be called on the items container
      currentLayer: 0           # Active layer number in a rondell instance
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
      onUpdateLightbox: null
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

  ### Add default easing function for rondell to jQuery if missing ###
  $.easing.easeInOutQuad ||= (x, t, b, c, d) ->
    if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b

  # Custom set timeout call
  delayCall = (delay, callback) -> setTimeout callback, delay

  # Rondell class holds all rondell items and functions
  class Rondell
    # Globally stores the number of rondells for uuid creation
    @rondellCount: 0
    # Globally stores the last activated rondell for keyboard interaction
    @activeRondell: null

    constructor: (@container, options, @initCallback=undefined) ->
      @id = ++Rondell.rondellCount
      @items = [] # Holds the items which will be instanced later
      children = container.children()
      @maxItems = children.length

      # First rondell should be active at the start
      Rondell.activeRondell = @id if @id is 1

      # Update rondell properties with new options
      presetOptions = if options?.preset of $.rondell.presets then $.rondell.presets[options.preset] else {}
      $.extend true, @, $.rondell.defaults, presetOptions, options or {}

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
      @container
        .data(rondellBaseClass, @)
        .css(@size)
        .addClass("#{classInitializing} #{classContainer} #{classThemePrefix}-#{@theme} #{classInstance}-#{@id}")

      # Create scrollbar
      if @scrollbar.enabled
        scrollbarContainer = $ '<div/>'
        @container.append scrollbarContainer

        $.extend true, @scrollbar,
          onScroll: @shiftTo
          end: @maxItems
          position: @currentLayer
          repeating: @repeating

        @scrollbar._instance = new RondellScrollbar scrollbarContainer, @scrollbar

      # Setup each item
      @_loadItem $(item) for item in children

      # Show items hidden parent container to prevent graphical glitch
      @container.show() if @showContainer

    update: (options) =>
      $.extend true, @, options || {}
      @shiftTo @currentLayer

    clear: =>
      @container
        .data(rondellBaseClass, @)
        .removeClass("#{@lassInitializing} #{classContainer} #{classThemePrefix}-#{@theme} #{classInstance}-#{@id}")
        .find(".#{classControl}").remove()
      @container.children(".#{classItem}").removeClass classItem
      @container.rondell = null

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
      if r.visibleItems > 1
        Math.max(0, 1.0 - Math.pow(l / r.visibleItems, 2))
      else if r.visibleItems == 1 then 1 else 0

    funcSize: (l, r, i) ->
      1

    # Resizes the rondell to fit it's parent and tries to keep all ratios
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

    _loadItem: (obj) =>
      # Create new rondell item and store a reference
      idx = @items.length + 1
      @_itemIndices[idx] = idx
      @items.push new RondellItem(idx, obj, @).init()

      # Start rondell after adding the last item
      @_start() if idx is @maxItems

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
      @visibleItems = Math.max(2, ~~(@maxItems / 2)) if @visibleItems is "auto"

      # Create controls
      controls = @controls
      if controls.enabled
        @controls._shiftLeft = $("<a href=\"#/\"/>")
          .addClass("#{classControl} #{classShiftLeft}")
          .html(@strings.prev)
          .click(@shiftLeft)
          .css
            left: controls.margin.x
            top: controls.margin.y
            zIndex: @zIndex + @maxItems + 2

        @controls._shiftRight = $("<a href=\"#/\"/>")
          .addClass("#{classControl} #{classShiftRight}")
          .html(@strings.next)
          .click(@shiftRight)
          .css
            right: controls.margin.x
            top: controls.margin.y
            zIndex: @zIndex + @maxItems + 2

        @container.append @controls._shiftLeft, @controls._shiftRight

      @bindEvents()

      @container.removeClass classInitializing

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
        @container.bind "mousewheel.#{rondellBaseClass}", @_onMousewheel

      # Use modernizr feature detection to enable touch device support
      if @_onMobile()
        # Enable swiping
        if @touch.enabled
          @container.bind("touchstart.#{rondellBaseClass} touchmove.#{rondellBaseClass} touchend.#{rondellBaseClass}", @_onTouch)
      else
        # Add hover and touch functions to container when we don't have touch support
        @container.bind "mouseenter.#{rondellBaseClass} mouseleave.#{rondellBaseClass}", @_hover

      rondell = @

      # Delegate click and mouse events events to rondell items
      @container
      .delegate ".#{classItem}", "click.#{rondellBaseClass}", (e) ->
        item = $(@).data "item"
        if rondell._focusedItem.id is item.id
          if rondell.lightbox.enabled
            e.preventDefault()
            rondell.showLightbox()
        else
          e.preventDefault()
          if not item.hidden and item.object.is ":visible"
            rondell.shiftTo item.currentSlot
      .delegate ".#{classItem}", "mouseenter.#{rondellBaseClass} mouseleave.#{rondellBaseClass}", (e) ->
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
      lightboxContent = $ ".#{classLightboxContent}", lightbox

      # Display lightbox but hide content at first
      unless lightboxIsVisible()
        lightbox.add(lightboxContent).css 'visibility', 'hidden'

      # Hide content then update lightbox
      lightboxContent
        .stop().fadeTo 100, 0, =>
          # Update content and remove style parameters
          content = $(".#{classLightboxInner}", lightboxContent).html @_focusedItem.object.html()

          # Update position text
          $(".#{classLightboxPosition}")
            .text "#{@currentLayer} | #{@maxItems}"

          # Remove overlay style
          $(".#{classItemOverlay}", content).style = ''

          # Add link to source if item is link
          if @_focusedItem.isLink
            linkUrl = @_focusedItem.object.attr 'href'
            linkTarget = @_focusedItem.object.attr 'target'

            $(".#{classCaption}", content)
              .append("<a href='#{linkUrl}' target='#{linkTarget}'>#{@strings.more}</a>")
              .attr('style', '')

          icon = $ ".#{classItemImage}", content

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
    return $(".#{classInstance}-#{Rondell.activeRondell}").data 'rondell'

  # Resize the lightbox to fit the current viewport
  resizeTimer = 0
  resizeLightbox = ->
    clearTimeout resizeTimer
    if lightboxIsVisible()
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
      $(".#{classLightboxOverlay}, .#{classLightboxClose}", lightbox)
        .bind eventClick, closeLightbox

      # Bind events to controls
      $(".#{classLightboxPrev}", lightbox)
        .bind eventClick, -> getActiveRondell().shiftLeft()

      $(".#{classLightboxNext}", lightbox)
        .bind eventClick, -> getActiveRondell().shiftRight()

      # Add resize event to window for updating the overlay size
      $window.bind eventResize, resizeLightbox

      # Add mousewheel event to lightbox and delegate to currently active rondell
      lightbox.bind eventMousewheel, (e, d, dx, dy) ->
        getActiveRondell()._onMousewheel e, d, dx, dy

    $.rondell.lightbox.instance

  # Private function to refresh the lightbox,
  # called by showLightbox within a rondell
  updateLightbox = ->
    $lightbox = getLightbox()
    $lightboxContent = $ ".#{classLightboxContent}", $lightbox
    winWidth = $window.innerWidth()
    winHeight = $window.innerHeight()
    windowPadding = 20

    activeRondell = getActiveRondell()
    focusedItem = activeRondell._focusedItem

    $lightbox.css 'display', 'block'

    # Get original and scaled image size for lightbox
    image = $ 'img:first', $lightboxContent
    if image.length
      # Store original image size
      unless focusedItem.lightboxImageWidth
        focusedItem.lightboxImageWidth = image[0].width
        focusedItem.lightboxImageHeight = image[0].height

        image
          .attr('width', focusedItem.lightboxImageWidth)
          .attr('height', focusedItem.lightboxImageHeight)

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

      image.css
        width: imageWidth
        height: imageHeight

    $lightbox.add($lightboxContent)
      .css 'visibility', 'visible'

    newWidth = $lightboxContent.outerWidth()
    newHeight = $lightboxContent.outerHeight()

    newProps =
      marginLeft: - newWidth / 2
      top: Math.max((winHeight - newHeight) / 2, 20)

    updateCallback = ->
      activeRondell.onUpdateLightbox? focusedItem

    if $lightboxContent.css('opacity') < 1
      $lightboxContent.css(newProps).fadeTo 200, 1, updateCallback
    else
      newProps.opacity = 1
      $lightboxContent.animate newProps, 200, updateCallback

    $lightbox.stop().fadeTo 150, 1

  class RondellItem

    constructor: (@id, @object, @rondell) ->
      @currentSlot = @id

      # Create some defaults for the item
      @focused = @hidden = @animating = false
      @isNew = @resizeable = true
      @icon = @iconCopy = @referencedImage = null

      @croppedSize = @rondell.itemProperties.size
      @sizeSmall = @rondell.itemProperties.size
      @sizeFocused = @rondell.itemProperties.sizeFocused

      @objectCSSTarget = {}
      @objectAnimationTarget = {}
      @lastObjectAnimationTarget = {}
      @iconAnimationTarget = {}
      @lastIconAnimationTarget = {}
      @animationSpeed = @rondell.fadeTime

      @isLink = @object.is 'a'


    init: =>
      # Wrap item if it's an image
      @object = @object.wrap("<div/>").parent() if @object.is 'img'
      @object
      .addClass(classItem)
      .data('item', @)
      .css
        opacity: 0
        width: @sizeSmall.width
        height: @sizeSmall.height
        left: @rondell.center.left - @sizeFocused.width / 2
        top: @rondell.center.top - @sizeFocused.height / 2

      if @isLink and @rondell.lightbox.displayReferencedImages
        linkUrl = @object.attr 'href'
        linkType = @_getFiletype linkUrl
        for filetype in @rondell.imageFiletypes when linkType is filetype
          @referencedImage = linkUrl
          break

      # Check whether item has an icon and load it asynchronous
      icon = @object.find 'img:first'
      if icon.length
        @icon = icon
        @resizeable = not icon.hasClass classNoScale

        @icon.addClass classItemImage

        # Add loading class
        @object.addClass classItemLoading

        if icon.width() > 0 or (icon[0].complete and icon[0].width > 0)
          # Image is already loaded (i.e. from cache)
          window.setTimeout @onIconLoad, 10
        else
          # Create copy of the image and wait for the copy to load to get the real dimensions
          @iconCopy = $ "<img style=\"display:none\"/>"
          $('body').append @iconCopy

          @iconCopy
            .one('load', @onIconLoad)
            .one('error', @onError)
            .attr('src', icon.attr('src'))
      else
        delayCall 0, @finalize
      @

    _getFiletype: (filename) ->
      filename.substr(filename.lastIndexOf('.') + 1).toLowerCase()

    refreshDimensions: =>
      # Get icon dimensions
      iconWidth = @iconCopy?.width() or @iconCopy?[0].width or @icon[0].width or @icon.width()
      iconHeight = @iconCopy?.height() or @iconCopy?[0].height or @icon[0].height or @icon.height()

      # Create size vars for the small and focused size
      foWidth = smWidth = iconWidth
      foHeight = smHeight = iconHeight

      itemSize = @rondell.itemProperties.size
      focusedSize = @rondell.itemProperties.sizeFocused
      croppedSize = itemSize

      # Delete copy, not needed anymore
      @iconCopy?.remove()

      # Return if width and height can't be resolved
      return unless iconWidth and iconHeight

      if @resizeable
        @icon.addClass classItemResizeable

        # Fit to small width
        smHeight *= itemSize.width / smWidth
        smWidth = itemSize.width

        # Fit to small height
        if smHeight > itemSize.height
          smWidth *= itemSize.height / smHeight
          smHeight = itemSize.height

        # Cropping will fill the thumbnail size in both dimensions
        if @rondell.cropThumbnails
          unless @icon.parent().hasClass classItemResizeable
            @icon.wrap $("<div>").addClass classItemCrop

          croppedSize =
            width: itemSize.width
            height: itemSize.width / smWidth * smHeight
          if croppedSize.height < itemSize.height
            croppedSize =
              width: itemSize.height / croppedSize.height * croppedSize.width
              height: itemSize.height

          smWidth = itemSize.width
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

      # Update item with new size values and properties
      @croppedSize = croppedSize
      @iconWidth = iconWidth
      @iconHeight = iconHeight
      @sizeSmall =
        width: Math.round smWidth
        height: Math.round smHeight
      @sizeFocused =
        width: Math.round foWidth
        height: Math.round foHeight

    onIconLoad: =>
      # Get dimensions from icon
      @refreshDimensions()

      # Finally init item
      @finalize()

    onError: =>
      # Create error message with image url
      errorString = @rondell.strings.loadingError.replace "%s", @icon.attr("src")

      # Remove broken icon
      @icon.remove()
      @iconCopy?.remove()

      # Display error message in item
      @object
      .removeClass(classItemLoading)
      .addClass(classItemError)
      .html "<p>#{errorString}</p>"

    finalize: =>
      @object.removeClass classItemLoading

      if @rondell.captionsEnabled
        # Wrap other content after the icon as overlay caption
        captionContent = null

        # If cropping is enabled use the siblings of the crop div as possible caption
        if @rondell.cropThumbnails
          captionContent = @icon?.closest(".#{@classItemCrop}").siblings()
        else
          captionContent = @icon?.siblings()

        if not (captionContent?.length or @icon) and @object.children().length
          captionContent = @object.children()

        # Or use title/alt texts as overlay caption
        unless captionContent?.length
          caption = @object.attr("title") or @icon?.attr("title") or @icon?.attr("alt")
          if caption
            # Create caption block
            captionContent = $ "<p>#{caption}</p>"
            @object.append captionContent

        # Create overlay from caption if found
        if captionContent?.length
          captionWrap = (captionContent.wrapAll("<div/>")).parent().addClass classCaption
          @overlay = captionWrap.addClass(classItemOverlay) if @icon

      # Tell the rondell, that the item finished initializing
      @rondell.onItemInit @id

    onMouseEnter: =>
      if not @animating and not @hidden and @object.is ":visible"
        @object.addClass(@rondell.itemHoveredClass).stop(true).animate
            opacity: 1
          , @rondell.fadeTime, @rondell.funcEase

    onMouseLeave: =>
      @object.removeClass classItemHovered

      unless @animating or @hidden
        @object.stop(true).animate
            opacity: @objectAnimationTarget.opacity
          , @rondell.fadeTime, @rondell.funcEase

    showCaption: =>
      if @rondell.captionsEnabled and @overlay?
        # Restore automatic height and show caption
        @overlay.stop(true).css
          height: "auto"
          overflow: "auto"
        .fadeTo 300, 1

    hideCaption: =>
      if @rondell.captionsEnabled and @overlay?.is ":visible"
        # Fix height before hiding the caption to avoid jumping
        # text when the item changes its size
        @overlay.stop(true).css
          height: @overlay.height()
          overflow: "hidden"
        .fadeTo 200, 0

    prepareFadeIn: =>
      @focused = true
      @hidden = false

      itemFocusedWidth = @sizeFocused.width
      itemFocusedHeight = @sizeFocused.height

      # Create new target at the rondells center
      @lastObjectAnimationTarget = @objectAnimationTarget
      @objectAnimationTarget =
        width: itemFocusedWidth
        height: itemFocusedHeight
        left: @rondell.center.left - itemFocusedWidth / 2
        top: @rondell.center.top - itemFocusedHeight / 2
        opacity: 1

      @objectCSSTarget =
        zIndex: @rondell.zIndex + @rondell.maxItems
        display: "block"

      @animationSpeed = @rondell.fadeTime

      # If icon isn't resizeable animate margins
      if @icon
        @lastIconAnimationTarget = @iconAnimationTarget

        iconMarginLeft = 0
        iconMarginTop = 0
        unless @resizeable
          iconMarginTop = (@rondell.itemProperties.sizeFocused.height - @iconHeight) / 2
          iconMarginLeft = (@rondell.itemProperties.sizeFocused.width - @iconWidth) / 2
          @iconAnimationTarget.marginTop = iconMarginTop
          @iconAnimationTarget.marginLeft = iconMarginLeft

        # Icon is animated separately if cropping is enabled
        if @rondell.cropThumbnails
          @iconAnimationTarget =
            marginTop: iconMarginTop
            marginLeft: iconMarginLeft
            width: itemFocusedWidth
            height: itemFocusedHeight

    prepareFadeOut: =>
      # Recenter icon unless it's resizeable
      @focused = false

      # Replace the items index with the actual slot the item is in
      idx = @currentSlot
      rondellItemProperties = @rondell.itemProperties
      itemSize = rondellItemProperties.size

      # Get the distance and relative index in relation to the focused element
      [layerDist, layerPos] = @rondell.getRelativeItemPosition idx

      # Get the absolute layer number difference
      layerDiff = @rondell.funcDiff(layerPos - @rondell.currentLayer, @rondell, idx)
      layerDiff *= -1 if layerPos < @rondell.currentLayer

      relativeSize = @rondell.funcSize(layerDiff, @rondell)
      itemWidth = @sizeSmall.width * relativeSize
      itemHeight = @sizeSmall.height * relativeSize
      newZ = @rondell.zIndex - layerDist

      # Modify fading time by items distance to focused item
      @animationSpeed = @rondell.fadeTime + rondellItemProperties.delay * layerDist

      # Get new target for animation
      newTarget =
        width: itemWidth
        height: itemHeight
        left: @rondell.funcLeft(layerDiff, @rondell, idx) + (itemSize.width - itemWidth) / 2
        top: @rondell.funcTop(layerDiff, @rondell, idx) + (itemSize.height - itemHeight) / 2
        opacity: 0

      @objectCSSTarget =
        zIndex: newZ
        display: "block"

      # Compute some stuff only when the item is really visible
      if layerDist <= @rondell.visibleItems
        newTarget.opacity = @rondell.funcOpacity layerDiff, @rondell, idx
        @hidden = false

        if @icon
          @lastIconAnimationTarget = @iconAnimationTarget

          if @rondell.cropThumbnails
            @iconAnimationTarget =
              marginTop: (itemSize.height - @croppedSize.height) / 2
              marginLeft: (itemSize.width - @croppedSize.width) / 2
              width: @croppedSize.width
              height: @croppedSize.height

          unless @resizeable
            @iconAnimationTarget =
              marginTop: (itemSize.height - @iconHeight) / 2
              marginLeft: (itemSize.width - @iconWidth) / 2

      else if @hidden
        # Move item directly to new position instead of animating it
        $.extend @objectCSSTarget, newTarget

      # Store last target for this item
      @lastObjectAnimationTarget = @objectAnimationTarget
      @objectAnimationTarget = newTarget

    onAnimationFinished: =>
      @animating = false

      if @focused
        # Add special class for focused style
        @object.addClass classItemFocused
        # show caption if rondell is hovered
        if @rondell.hovering or @rondell.alwaysShowCaption or @rondell._onMobile()
          @showCaption()
      else
        # Hide item if it isn't visible anymore
        if @objectAnimationTarget.opacity < @rondell.opacityMin
          @hidden = true
          @object.css "display", "none"
        else
          @hidden = false
          @object.css "display", "block"

    runAnimation: (force=false) =>
      # Move to new position
      @object.css @objectCSSTarget

      unless @hidden
        # Animate the icon
        if (force or @iconAnimationTarget) and @icon and (@focused or not @rondell.equals @iconAnimationTarget, @lastIconAnimationTarget)
          @icon.stop(true).animate @iconAnimationTarget, @animationSpeed, @rondell.funcEase

        # Animate the whole object
        if (force or @objectAnimationTarget?) and (@focused or not @rondell.equals @objectAnimationTarget, @lastObjectAnimationTarget)
          @animating = true

          @object.stop(true)
          .animate @objectAnimationTarget, @animationSpeed, @rondell.funcEase, @onAnimationFinished

          unless @focused
            # Remove focused class
            @object.removeClass classItemFocused
            # Hide caption when item isn't focused
            @hideCaption()
        else
          # Animation was skipped
          @onAnimationFinished()

  class RondellScrollbar

    constructor: (container, options) ->
      $.extend true, @, $.rondell.defaults.scrollbar, options

      @container = container.addClass classScrollbar

      @_drag =
        _dragging: false
        _lastDragEvent: 0

      @container.addClass("#{classScrollbar}-#{@orientation}").css @style

      @_initControls()

      scrollControlWidth = @scrollControl.outerWidth()
      @_minX = @padding + @scrollLeftControl.outerWidth() + scrollControlWidth / 2
      @_maxX = @container.innerWidth() - @padding - @scrollRightControl.outerWidth() - scrollControlWidth / 2

      @setPosition @position, false, true

    _initControls: =>
      scrollControlTemplate = "<div><span class=\"#{classScrollbarInner}\">&nbsp;</span></div>"

      @scrollLeftControl = $(scrollControlTemplate)
      .addClass(classScrollbarLeft)
      .click @scrollLeft

      @scrollRightControl = $(scrollControlTemplate)
      .addClass(classScrollbarRight)
      .click @scrollRight

      @scrollControl = $("<div class=\"#{classScrollbarControl}\">&nbsp;</div>")
      .css("left", @container.innerWidth() / 2)
      .mousedown @onDragStart

      @scrollBackground = $ "<div class=\"#{classScrollbarBackground}\"/>"

      # Append scrollbar controls to dom
      @container.append @scrollBackground, @scrollLeftControl, @scrollRightControl, @scrollControl

      # Attach scrollbar click event
      @container.add(@scrollBackground).click @onScrollbarClick

    updatePosition: (position, fireCallback=true) =>
      return if not position or position is @position or position < @start or position > @end

      @position = position

      # Fire callback with new position
      @onScroll? position, true if fireCallback

    scrollTo: (x, animate=true, fireCallback=true) =>
      return if x < @_minX or x > @_maxX

      @scrollControl.stop(true).css 'left', x

      # Translate event coordinates to new position between start and end option
      newPosition = Math.round((x - @_minX) / (@_maxX - @_minX) * (@end - @start)) + @start
      @updatePosition(newPosition, fireCallback) if newPosition isnt @position

    setPosition: (position, fireCallback=true, force=false) =>
      if @repeating
        position = @end if position < @start
        position = @start if position > @end

      return if not force and (position < @start or position > @end or position is @position)

      # Translate position to new position for control dot in container
      newX = Math.round((position - @start) / (@end - @start) * (@_maxX - @_minX)) + @_minX
      @scrollTo newX, true, fireCallback

    onDrag: (e) =>
      e.preventDefault()
      return unless @_drag._dragging

      if e.type is "mouseup"
        # Release drag on mouseup
        @_drag._dragging = false
        @scrollControl.removeClass classScrollbarDragging
        # Bind mouse events to window for dragging
        $(window).unbind "mousemove mouseup", @onDrag
      else
        # Move scroll dot to new position
        newX = 0
        if @orientation in ["top", "bottom"]
          newX = e.pageX - @container.offset().left
        else
          newX = e.pageY - @container.offset().top
        newX = Math.max(@_minX, Math.min(@_maxX, newX))

        @scrollTo newX, false

    onDragStart: (e) =>
      e.preventDefault()
      # Start drag event
      @_drag._dragging = true
      @scrollControl.addClass classScrollbarDragging
      # Bind mouse events to window for dragging
      $(window).bind "mousemove mouseup", @onDrag

    onScrollbarClick: (e) =>
      # Jump to new position when clicking scroller background
      @scrollTo e.pageX - @container.offset().left

    scrollLeft: (e) =>
      e.preventDefault()
      newPosition = @position - @stepSize
      if @keepStepOrder and @stepSize > 1
        if newPosition >= @start
          newPosition -= (newPosition - @start) % @stepSize
        else if @repeating
          # Move to max position if new position is smaller than start
          newPosition = @start + Math.floor((@end - @start) / @stepSize) * @stepSize
      @setPosition newPosition

    scrollRight: (e) =>
      e.preventDefault()
      newPosition = @position + @stepSize
      if @keepStepOrder and @stepSize > 1
        newPosition -= (newPosition - @start) % @stepSize
        if @repeating and newPosition > @end
          newPosition = @start
      @setPosition newPosition

  # Add rondell to jQuery
  $.fn.rondell = (options={}, callback=undefined) ->
    self = $ @
    if @length > 1
      @each -> self.rondell options, callback
    else if self.data('rondell') is undefined
      new Rondell @, options, callback
    else
      self.data('rondell').update options
    @

)(jQuery, window, document)
