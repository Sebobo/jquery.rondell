###!
  RondellItem for jQuery rondell plugin

  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @category jQuery plugin
  @copyright (c) 2009-2012 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  $.rondell ||= {}

  class $.rondell.RondellItem

    constructor: (@id, @object, @rondell) ->
      @currentSlot = @id

      # Create some defaults for the item
      @focused = false
      @hidden = false
      @animating = false
      @isNew = true
      @icon = null
      @resizeable = true
      @iconCopy = null
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
      @referencedImage = null

    init: =>
      # Wrap item if it's an image
      @object = @object.wrap("<div/>").parent() if @object.is 'img'
      @object
      .addClass("#{@rondell.classes.item}")
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
        @resizeable = not icon.hasClass @rondell.classes.noScale

        @icon.addClass @rondell.classes.image

        # Add loading class
        @object.addClass @rondell.classes.loading

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
        @finalize()

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
        @icon.addClass @rondell.classes.resizeable

        # Fit to small width
        smHeight *= itemSize.width / smWidth
        smWidth = itemSize.width

        # Fit to small height
        if smHeight > itemSize.height
          smWidth *= itemSize.height / smHeight
          smHeight = itemSize.height

        # Cropping will fill the thumbnail size in both dimensions
        if @rondell.cropThumbnails
          unless @icon.parent().hasClass @rondell.classes.crop
            @icon.wrap $("<div>").addClass @rondell.classes.crop

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
      .removeClass(@rondell.classes.loading)
      .addClass(@rondell.classes.error)
      .html "<p>#{errorString}</p>"

    finalize: =>
      @object.removeClass @rondell.classes.loading

      if @rondell.captionsEnabled
        # Wrap other content after the icon as overlay caption
        captionContent = null

        # If cropping is enabled use the siblings of the crop div as possible caption
        if @rondell.cropThumbnails
          captionContent = @icon?.closest(".#{@rondell.classes.crop}").siblings()
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
          captionWrap = (captionContent.wrapAll("<div/>")).parent().addClass @rondell.classes.caption
          @overlay = captionWrap.addClass(@rondell.classes.overlay) if @icon

      # Tell the rondell, that the item finished initializing
      @rondell.onItemInit @id

    onMouseEnter: =>
      if not @animating and not @hidden and @object.is ":visible"
        @object.addClass(@rondell.itemHoveredClass).stop(true).animate
            opacity: 1
          , @rondell.fadeTime, @rondell.funcEase

    onMouseLeave: =>
      @object.removeClass @rondell.classes.hovered

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

      # Get the distance and relative index in relation to the focused element
      [layerDist, layerPos] = @rondell.getRelativeItemPosition idx

      # Get the absolute layer number difference
      layerDiff = @rondell.funcDiff(layerPos - @rondell.currentLayer, @rondell, idx)
      layerDiff *= -1 if layerPos < @rondell.currentLayer

      itemWidth = @sizeSmall.width * @rondell.funcSize(layerDiff, @rondell)
      itemHeight = @sizeSmall.height * @rondell.funcSize(layerDiff, @rondell)
      newZ = @rondell.zIndex - layerDist

      # Modify fading time by items distance to focused item
      @animationSpeed = @rondell.fadeTime + @rondell.itemProperties.delay * layerDist

      # Get new target for animation
      newTarget =
        width: itemWidth
        height: itemHeight
        left: @rondell.funcLeft(layerDiff, @rondell, idx) + (@rondell.itemProperties.size.width - itemWidth) / 2
        top: @rondell.funcTop(layerDiff, @rondell, idx) + (@rondell.itemProperties.size.height - itemHeight) / 2
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
              marginTop: (@rondell.itemProperties.size.height - @croppedSize.height) / 2
              marginLeft: (@rondell.itemProperties.size.width - @croppedSize.width) / 2
              width: @croppedSize.width
              height: @croppedSize.height

          unless @resizeable
            @iconAnimationTarget =
              marginTop: (@rondell.itemProperties.size.height - @iconHeight) / 2
              marginLeft: (@rondell.itemProperties.size.width - @iconWidth) / 2

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
        @object.addClass @rondell.classes.focused
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
            @object.removeClass @rondell.classes.focused
            # Hide caption when item isn't focused
            @hideCaption()
        else
          # Animation was skipped
          @onAnimationFinished()

)(jQuery)
