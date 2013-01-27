###!
  Presets for jQuery rondell plugin

  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @category jQuery plugin
  @copyright (c) 2009-2013 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  $.rondell ||= {}
  $.rondell.presets =

    carousel:
      autoRotation:
        enabled: true
        direction: 1
        once: false
        delay: 5000
      radius:
        x: 240
        y: 50
      center:
        left: 340
        top: 160
      controls:
        margin:
          x: 130
          y: 260
      randomStart: true
      currentLayer: 1
      funcSize: (l, r, i) ->
        1 / Math.abs(l)

    scroller:
      repeating: false
      alwaysShowCaption: true
      visibleItems: 4
      theme: "dark"
      lightbox:
        enabled: false
      itemProperties:
        delay: 0
        size:
          width: 100
          height: 200
        sizeFocused:
          width: 300
          height: 200
      center:
        left: 400
        top: 100
      size:
        width: 800
        height: 200
      controls:
        margin:
          x: 210
          y: 158
      funcTop: (l, r, i) ->
        0
      funcDiff: (d, r, i) ->
        Math.abs(d) + 1
      funcLeft: (l, r, i) ->
        r.center.left + (l - 0.5) * r.itemProperties.size.width
      funcOpacity: (l, r, i) ->
        0.8

    pages:
      radius:
        x: 0
        y: 0
      lightbox:
        enabled: false
      scaling: 1
      theme: "page"
      visibleItems: 1
      controls:
        margin:
          x: 0
          y: 0
      strings:
        prev: ' '
        next: ' '
      center:
        left: 200
        top: 200
      itemProperties:
        size:
          width: 400
          height: 400
      funcTop: (l, r, i) ->
          r.center.top - r.itemProperties.size.height / 2
      funcLeft: (l, r, i) ->
          r.center.left + l * r.itemProperties.size.width
      funcDiff: (l, r, i) ->
          Math.abs(l) + 0.5

    cubic:
      center:
        left: 300
        top: 200
      visibleItems: 5
      itemProperties:
        size:
          width: 350
          height: 350
        sizeFocused:
          width: 350
          height: 350
      controls:
        margin:
          x: 70
          y: 330
      funcTop: (l, r, i) ->
          r.center.top - r.itemProperties.size.height / 2 + Math.pow(l / 2, 3) * r.radius.x
      funcLeft: (l, r, i) ->
          r.center.left - r.itemProperties.size.width / 2 + Math.sin(l) * r.radius.x
      funcSize: (l, r, i) ->
          Math.pow((Math.PI - Math.abs(l)) / Math.PI, 3)

    gallery:
      # Custom options
      special:
        itemPadding: 2
      # Standard rondell options
      visibleItems: 5
      theme: "dark"
      cropThumbnails: true
      center:
        top: 145
        left: 250
      size:
        height: 400
        width: 500
      controls:
        margin:
          x: 10
          y: 255
      itemProperties:
        delay: 0
        sizeFocused:
          width: 480
          height: 280
        size:
          width: 80
          height: 100
      funcTop: (l, r, i) ->
        r.size.height - r.itemProperties.size.height - r.special.itemPadding
      funcDiff: (d, r, i) ->
        Math.abs(d) - 0.5
      funcLeft: (l, r, i) ->
        r.center.left + (l - 0.5) * (r.itemProperties.size.width + r.special.itemPadding)
      funcOpacity: (l, r, i) ->
        0.8

    thumbGallery:
      # Custom options
      special:
        columns: 3
        rows: 3
        groupSize: 9
        itemPadding: 5
        thumbsOffset:
          x: 500
          y: 0
      # Standard rondell options
      visibleItems: 9
      wrapIndices: false
      currentLayer: 1
      switchIndices: true
      cropThumbnails: true
      center:
        top: 215
        left: 250
      size:
        height: 430
        width: 800
      controls:
        enabled: false
        margin:
          x: 10
          y: 255
      itemProperties:
        delay: 40
        sizeFocused:
          width: 480
          height: 420
        size:
          width: 94
          height: 126
      scrollbar:
        enabled: true
        stepSize: 9 # Should be same as group size in special options
        start: 2
        style:
          width: 292
          right: 3
          bottom: 5

      funcDiff: (d, r, i) ->
        Math.abs d

      funcOpacity: (l, r, i) ->
        # Find current layers index for group comparison
        currentLayerIndex = if r.currentLayer > r._focusedItem.currentSlot \
            then r.currentLayer - 1 else r.currentLayer
        # Modify items indices right of the selected slot to remove empty slot
        i-- if i > r._focusedItem.currentSlot
        # Show items in the same group as the focused one
        if Math.floor((i - 1) / r.special.groupSize) is \
          Math.floor((currentLayerIndex - 1) / r.special.groupSize) then 0.8 else 0

      funcTop: (l, r, i) ->
        # Modify items indices right of the selected slot to remove empty slot
        i-- if i > r._focusedItem.currentSlot
        # Compute items vertical offset
        r.special.thumbsOffset.y + r.special.itemPadding \
          + Math.floor(((i - 1) % r.special.groupSize) / r.special.rows) \
          * (r.itemProperties.size.height + r.special.itemPadding)

      funcLeft: (l, r, i) ->
        # Find current layers index for group comparison
        currentLayerIndex = if r.currentLayer > r._focusedItem.currentSlot \
            then r.currentLayer - 1 else r.currentLayer
        # Modify items indices right of the selected slot to remove empty slot
        i-- if i > r._focusedItem.currentSlot
        # Get items column
        column = ((i - 1) % r.special.groupSize) % r.special.columns
        # Get the group difference
        groupOffset = Math.floor((i - 1) / r.special.groupSize) \
          - Math.floor((currentLayerIndex - 1) / r.special.groupSize)
        # Compute final column positioning
        r.special.thumbsOffset.x + r.special.itemPadding \
          + (column + r.special.columns * groupOffset) \
          * (r.itemProperties.size.width + r.special.itemPadding)

    slider:
      theme: 'slider'
      visibleItems: 1
      fadeTime: 1000
      opacityMin: 0.01
      autoRotation:
        enabled: true
      center:
        top: 150
        left: 300
      size:
        height: 300
        width: 600
      controls:
        margin:
          x: -1
          y: 135
      strings:
        prev: '<span>&nbsp;</span>'
        next: '<span>&nbsp;</span>'
      itemProperties:
        sizeFocused:
          width: 600
          height: 300
        size:
          width: 600
          height: 300
      funcTop: (l, r, i) ->
        0
      funcLeft: (l, r, i) ->
        0
      funcOpacity: (l, r, i) ->
        0.02

)(jQuery)
