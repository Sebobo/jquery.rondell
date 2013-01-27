###!
  Scrollbar for jQuery rondell plugin
  
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @category jQuery plugin
  @copyright (c) 2009-2012 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  $.rondell ||= {}

  class $.rondell.RondellScrollbar
    
    constructor: (container, options) ->
      $.extend true, @, $.rondell.defaults.scrollbar, options

      @container = container.addClass @classes.container
      
      @_drag =
        _dragging: false
        _lastDragEvent: 0

      @container.addClass("#{@classes.container}-#{@orientation}").css @style
        
      @_initControls()

      @_minX = @padding + @scrollLeftControl.outerWidth() + @scrollControl.outerWidth() / 2
      @_maxX = @container.innerWidth() - @padding - @scrollRightControl.outerWidth() - @scrollControl.outerWidth() / 2

      @setPosition @position, false, true

    _initControls: =>
      scrollControlTemplate = "<div><span class=\"#{@classes.scrollInner}\">&nbsp;</span></div>"

      @scrollLeftControl = $(scrollControlTemplate)
      .addClass(@classes.scrollLeft)
      .click @scrollLeft
        
      @scrollRightControl = $(scrollControlTemplate)
      .addClass(@classes.scrollRight)
      .click @scrollRight
        
      @scrollControl = $("<div class=\"#{@classes.control}\">&nbsp;</div>")
      .css("left", @container.innerWidth() / 2)
      .mousedown @onDragStart
        
      @scrollBackground = $ "<div class=\"#{@classes.background}\"/>"
        
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
      
      scroller = @scrollControl.stop true
      target =
        left: x

      if animate
        scroller.animate target, @animationDuration, @easing
      else
        scroller.css target

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
        @scrollControl.removeClass @classes.dragging
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
      @scrollControl.addClass @classes.dragging
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

)(jQuery) 
