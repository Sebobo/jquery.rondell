###!
  jQuery rondell plugin
  @name jquery.rondell.js
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @version 0.8.3
  @date 11/19/2011
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  # Global rondell stuff
  $.rondell =
    version: '0.8.3'
    name: 'rondell'
    defaults:
      resizeableClass: 'resizeable'
      smallClass: 'itemSmall'
      hiddenClass: 'itemHidden'
      itemCount: 0 # Number of rondell items in a rondell
      currentLayer: 1 # Active layer number
      container: null
      radius: # Radius if the rondell uses a circle function
        x: 300 
        y: 50  
      center: # Center where the focused element is displayed
        left: 400 
        top: 200
      size: # Defaults to center * 2
        width: null
        height: null
      visibleItems: 'auto' # How many items should be visible in each direction
      scaling: 2 # Size of focused element
      opacityMin: 0.05 # Min opacity before elements are set to display: none
      fadeTime: 300
      zIndex: 1000 # All elements of the rondell will use this z-index and add their depth to it
      itemProperties: # Default properties for each item
        delay: 100
        cssClass: 'rondellItem'
        size: 
          width: 150
          height: 150
        sizeFocused:
          width: 0
          height: 0
      repeating: true # Rondell will go forever
      alwaysShowCaption: false
      autoRotation: # If the cursor leaves the rondell continue spinning
        enabled: false
        paused: false
        timer: -1
        direction: 0
        once: false
        delay: 5000
      controls: # Buttons to control the rondell
        enabled: true
        fadeTime: 400
        margin: 
          x: 20
          y: 20
      strings: # String for the controls 
        prev: 'prev'
        next: 'next'
      touch:
        enabled: true
        preventDefaults: true
        threshold: 100
        start: undefined
        end: undefined
      funcEase: 'easeInOutQuad' # Easing function name for the movement of items
      theme: 'default' # CSS theme class which gets added to the rondell container
      preset: '' # Configuration preset
      effect: null # Special effect function for the focused item
  
  # Add default easing function for rondell to jQuery if missing
  unless $.easing.easeInOutQuad        
    $.easing.easeInOutQuad = (x, t, b, c, d) ->
      if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b
   
  # Rondell class   
  class Rondell
    @rondellCount: 0
    @activeRondell: null # Stores the last activated rondell for keyboard interaction
    
    constructor: (options, numItems) ->
      @id = Rondell.rondellCount++
      @items = [] # Holds the items
      @maxItems = numItems
      
      # Update rondell properties with new options
      $.extend(true, @, $.rondell.defaults, options or {})
    
      @itemProperties.sizeFocused =
        width: @itemProperties.sizeFocused.width or @itemProperties.size.width * @scaling
        height: @itemProperties.sizeFocused.height or @itemProperties.size.height * @scaling
        
      @size = 
        width: @size.width or @center.left * 2
        height: @size.height or @center.top * 2
    
    # Animation functions, can be different for each rondell
    funcLeft: (layerDiff, rondell) ->
      rondell.center.left - rondell.itemProperties.size.width / 2.0 + Math.sin(layerDiff) * rondell.radius.x
    funcTop: (layerDiff, rondell) ->
      rondell.center.top - rondell.itemProperties.size.height / 2.0 + Math.cos(layerDiff) * rondell.radius.y
    funcDiff: (layerDiff, rondell) ->
      Math.pow(Math.abs(layerDiff) / rondell.itemCount, 0.5) * Math.PI
    funcOpacity: (layerDist, rondell) ->
      if rondell.visibleItems > 1 then Math.max(0, 1.0 - Math.pow(layerDist / rondell.visibleItems, 2)) else 0
    funcSize: (layerDist, rondell) ->
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
      
      # Wrap other content as overlay caption
      captionContent = item.icon?.siblings()
      if not (captionContent?.length or item.icon) and item.object.children().length
        captionContent = item.object.children()
        
      # Or use title/alt texts as overlay caption
      if not captionContent.length 
        caption = item.object.attr('title') or item.icon?.attr('alt') or item.icon?.attr('title')  
        if caption
          captionContent = $("<p>#{caption}</p>")
          item.object.append(captionContent)

      # Create overlay from caption if found
      if captionContent.length
        captionContainer = $('<div class="rondellCaption"></div>')
        captionContainer.addClass('overlay') if item.icon
        captionContent.wrapAll(captionContainer)
        
      # Init click events
      item.object
      .addClass("rondellItemNew #{@itemProperties.cssClass}")
      .css(
        opacity: 0
        width: item.sizeSmall.width
        height: item.sizeSmall.height
        left: @center.left - item.sizeFocused.width / 2
        top: @center.top - item.sizeFocused.height / 2
      )
      .bind('mouseover mouseout click', (e) =>
        switch e.type
          when 'mouseover'
            item.object.addClass('rondellItemHovered') if item.object.is(':visible') and not item.hidden
          when 'mouseout'
            item.object.removeClass('rondellItemHovered')
          when 'click'
            if item.object.is(':visible') and not (@currentLayer is layerNum or item.hidden)
              @shiftTo(layerNum)
              e.preventDefault()
      )
      
      @_start() if @itemCount is @maxItems
      
    _onloadItem: (obj, copy=undefined) =>
      icon = $('img:first', obj)
      
      isResizeable = icon.hasClass(@resizeableClass)
      layerNum = @itemCount += 1
    
      itemSize = @itemProperties.size
      focusedSize = @itemProperties.sizeFocused
      scaling = @scaling
      
      # create size vars for the small and focused size
      foWidth = smWidth = copy?.width() || copy?[0].width || icon[0].width || icon.width()
      foHeight = smHeight = copy?.height() || copy?[0].height || icon[0].height || icon.height()
      
      # Delete copy, not needed anymore
      copy?.remove()
      
      # Return if width and height can't be resolved
      return unless smWidth and smHeight
    
      if isResizeable
        if smWidth >= smHeight
          # compute smaller side length
          smHeight *= itemSize.width / smWidth
          foHeight *= focusedSize.width / foWidth
          # compute full size length
          smWidth = itemSize.width
          foWidth = focusedSize.width
        else
          # compute smaller side length
          smWidth *= itemSize.height / smHeight
          foWidth *= focusedSize.height / foHeight
          # compute full size length
          smHeight = itemSize.height
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
      
    _loadItem: (obj) =>
      icon = $('img:first', obj)
      if icon[0].complete and icon[0].width
        # Image is already loaded (i.e. from cache)
        @_onloadItem(obj) 
      else 
        # Create copy of the image and wait for the copy to load to get the real dimensions
        copy = $("<img style=\"display:none\"/>")
        $('body').append(copy)
        copy.one("load", =>
          @_onloadItem(obj, copy)
        ).attr("src", icon.attr("src"))
      
    _start: =>
      # Set visibleItems if set to auto
      @currentLayer = Math.round(@itemCount / 2)
      @visibleItems = Math.max(2, Math.floor(@itemCount / 2)) if @visibleItems is 'auto'
      
      # Create controls
      controls = @controls
      if controls.enabled
        shiftLeft = $('<a class="rondellControl rondellShiftLeft" href="#"/>').text(@strings.prev).click(@shiftLeft)
        .css(
          left: controls.margin.x
          top: controls.margin.y
          "z-index": @zIndex + @itemCount + 2
        )
          
        shiftRight = $('<a class="rondellControl rondellShiftRight" href="#/"/>').text(@strings.next).click(@shiftRight)
        .css(
          right: controls.margin.x
          top: controls.margin.y
          "z-index": @zIndex + @itemCount + 2
        )
          
        @container.append(shiftLeft, shiftRight)
        
        
      # Attach keydown event to document for each rondell instance
      $(document).keydown(@keyDown)
      
      # add hover and touch functions to container
      @container.removeClass('initializing').bind('mouseover mouseout', @_hover).bind('touchstart touchmove touchend', @_touch)
      
      # Move items to starting positions
      @shiftTo(@currentLayer)
      
    _touch: (e) =>
      return unless @touch.enabled
      
      touch = e.originalEvent.touches[0] or e.originalEvent.changedTouches[0]
      
      switch e.type
        when 'touchstart'
          @touch.start = 
            x: touch.pageX
            y: touch.pageY
        when 'touchmove'
          e.preventDefault() if @touch.preventDefaults
          @touch.end =
            x: touch.pageX
            y: touch.pageY
        when 'touchend'
          if @touch.start and @touch.end
            changeX = @touch.end.x - @touch.start.x
            if Math.abs(changeX) > @touch.threshold
              if changeX > 0
                @shiftLeft()
              if changeX < 0
                @shiftRight()
              
            # Reset end position
            @touch.start = @touch.end = undefined
            
      true
      
    _hover: (e) =>      
      # Show or hide controls if they exist
      $('.rondellControl', @container).stop().fadeTo(@controls.fadeTime, if e.type is 'mouseover' then 1 else 0)
      
      # Start or stop auto rotation if enabled
      paused = @autoRotation.paused
      if e.type is 'mouseover'
        Rondell.activeRondell = @.id
        @hovering = true
        unless paused
          @autoRotation.paused = true
          @showCaption(@currentLayer)
      else
        @hovering = false
        if paused and not @autoRotation.once
          @autoRotation.paused = false
          @_autoShift()
        @hideCaption(@currentLayer) unless @alwaysShowCaption
      
    layerFadeIn: (layerNum) =>
      item = @_getItem(layerNum)
      item.small = false
      itemFocusedWidth = item.sizeFocused.width
      itemFocusedHeight = item.sizeFocused.height
      
      # Move item to center position and fade in
      item.object.stop(true).show(0)
      .css('z-index', @zIndex + @itemCount)
      .addClass('rondellItemFocused')
      .animate(
          width: itemFocusedWidth
          height: itemFocusedHeight
          left: @center.left - itemFocusedWidth / 2
          top: @center.top - itemFocusedHeight / 2
          opacity: 1
        , @fadeTime, @funcEase, =>
          @_autoShift()
          @showCaption(layerNum) if @hovering or @alwaysShowCaption
      )
      
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
      if layerDist > @visibleItems and @repeating
        if @currentLayer + @visibleItems > @itemCount
          layerPos += @itemCount
        else if @currentLayer - @visibleItems <= @itemCount
          layerPos -= @itemCount
        layerDist = Math.abs(layerPos - @currentLayer)

      # Get the absolute layer number difference
      layerDiff = @funcDiff(layerPos - @currentLayer, @)
      layerDiff *= -1 if layerPos < @currentLayer
      
      itemWidth = item.sizeSmall.width * @funcSize(layerDiff, @)
      itemHeight = item.sizeSmall.height * @funcSize(layerDiff, @)
      
      newX = @funcLeft(layerDiff, @) + (@itemProperties.size.width - itemWidth) / 2
      newY = @funcTop(layerDiff, @) + (@itemProperties.size.height - itemHeight) / 2
      
      newZ = @zIndex + (if layerDiff < 0 then layerPos else -layerPos)
      fadeTime = @fadeTime + @itemProperties.delay * layerDist
      isNew = item.object.hasClass('rondellItemNew')
        
      # Is item visible
      if isNew or layerDist <= @visibleItems
        @hideCaption(layerNum)
        
        newOpacity = @funcOpacity(layerDist, @)
        item.object.show() if newOpacity >= @opacityMin

        item.object.removeClass('rondellItemNew rondellItemFocused').stop(true)
        .css('z-index', newZ)
        .animate(
            width: itemWidth
            height: itemHeight
            left: newX
            top: newY
            opacity: newOpacity 
          , fadeTime, @funcEase, =>
            if item.object.css('opacity') < @opacityMin then item.object.hide() else item.object.show()
        )
        
        item.hidden = false
        unless item.small
          item.small = true
          if item.icon and not item.resizeable
            margin = (itemHeight - item.icon.height()) / 2
            item.icon.stop(true).animate(
                marginTop: margin
                marginBottom: margin
              , fadeTime
            )
      else if item.hidden
        # Update position even if out of view to 
        item.object.css(
          left: newX
          top: newY
          'z-index': newZ
        )
      else
        # Hide items which are moved out of view
        item.hidden = true
        item.object.stop(true)
        .css('z-index', newZ)
        .animate(
            opacity: 0
          , fadeTime / 2, @funcEase, =>
          @hideCaption(layerNum)
        )

    shiftTo: (layerNum) =>
      itemCount = @itemCount
      
      if @repeating 
        # Update current layer
        if layerNum < 1 
          layerNum = itemCount
        else if layerNum > itemCount 
          layerNum = 1
      
      if layerNum > 0 and layerNum <= itemCount
        @currentLayer = currentLayer = layerNum
        
        # Hide all layers except the current layer
        @layerFadeOut(i) for i in [1..itemCount] when i isnt currentLayer
        @layerFadeIn(currentLayer)
         
    shiftLeft: (e) => 
      e?.preventDefault()
      @shiftTo(@currentLayer - 1) 
        
    shiftRight: (e) => 
      e?.preventDefault()
      @shiftTo(@currentLayer + 1) 
        
    _autoShift: =>
      autoRotation = @autoRotation
      if @isActive() and autoRotation.enabled and autoRotation.timer < 0
        # store timer id
        autoRotation.timer = window.setTimeout( =>
            @autoRotation.timer = -1
            if @isActive() and not autoRotation.paused
              if autoRotation.direction then @shiftRight() else @shiftLeft()
          , autoRotation.delay
        )
        
    isActive: ->
      true
    
    keyDown: (e) =>
      if @isActive() and Rondell.activeRondell is @.id
        # Clear current rotation timer on user interaction
        if @autoRotation.timer >= 0
          window.clearTimeout(@autoRotation.timer) 
          @autoRotation.timer = -1
          
        switch e.which
          # arrow left
          when 37 then @shiftLeft(e)
          # arrow right 
          when 39 then @shiftRight(e) 
  
  $.fn.rondell = (options) ->
    # Create new rondell instance
    rondell = new Rondell(options, @length)
    
    # Wrap elements in new container
    @wrapAll($('<div class="rondellContainer initializing"></div>'))
    
    # Set container size  
    rondell.container = @parent().css(rondell.size)
          
    # Setup each item
    @each ->
      obj = $(@)
      
      if $('img:first', obj).length
        rondell._loadItem(obj)
      else
        # Init item without an icon
        layerNum = rondell.itemCount += 1
    
        rondell._initItem(layerNum, 
          object: obj 
          icon: null
          small: false 
          hidden: false
          resizeable: false
          sizeSmall: rondell.itemProperties.size
          sizeFocused: rondell.itemProperties.sizeFocused
        )
        
    rondell
    
)(jQuery) 
