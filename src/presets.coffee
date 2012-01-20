###!
  Presets for jQuery rondell plugin
  
  @author Sebastian Helzle (sebastian@helzle.net or @sebobo)
  @category jQuery plugin
  @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
  @license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
###

(($) ->
  $.rondell = $.rondell or {}    
  $.rondell.presets =
  
    carousel:
      autoRotation:
        enabled: true
        direction: 1
        once: false
        delay: 5000
      radius: 
        x: 240
      center:
        left: 340 
        top: 160
      controls: 
        margin: 
          x: 130
          y: 260
      randomStart: true
      currentLayer: 1
      funcSize: (layerDiff, rondell) ->
        (rondell.maxItems / Math.abs(layerDiff)) / rondell.maxItems
      
    products:
      repeating: false
      alwaysShowCaption: true
      visibleItems: 4
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
      controls: 
        margin: 
          x: 210
          y: 158
      funcTop: (layerDiff, rondell) ->
        0
      funcDiff: (layerDiff, rondell) ->
        Math.abs(layerDiff) + 1
      funcLeft: (layerDiff, rondell) ->
        rondell.center.left + (layerDiff - 0.5) * rondell.itemProperties.size.width
      funcOpacity: (layerDist, rondell) ->
        0.8
       
    pages:
      radius: 
        x: 0 
        y: 0
      scaling: 1
      visibleItems: 1
      controls:
        margin:
          x: 5
          y: 5
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
      funcTop: (layerDiff, rondell) ->
          rondell.center.top - rondell.itemProperties.size.height / 2
      funcLeft: (layerDiff, rondell) ->
          rondell.center.left + layerDiff * rondell.itemProperties.size.width
      funcDiff: (layerDiff, rondell) ->
          Math.abs(layerDiff) + 0.5
      
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
      funcTop: (layerDiff, rondell) ->
          rondell.center.top - rondell.itemProperties.size.height / 2 + Math.pow(layerDiff / 2, 3) * rondell.radius.x
      funcLeft: (layerDiff, rondell) ->
          rondell.center.left - rondell.itemProperties.size.width / 2 + Math.sin(layerDiff) * rondell.radius.x
      funcSize: (layerDiff, rondell) ->
          Math.pow((Math.PI - Math.abs(layerDiff)) / Math.PI, 3)
          
    gallery:
      visibleItems: 4
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
        delay: 10
        sizeFocused: 
          width: 480
          height: 280
        size:
          width: 100
          height: 100 
      funcTop: (layerDiff, rondell) ->
        rondell.size.height - rondell.itemProperties.size.height - 5
      funcDiff: (layerDiff, rondell) ->
        Math.abs(layerDiff) - 0.5
      funcLeft: (layerDiff, rondell) ->
        rondell.center.left + (layerDiff - 0.5) * (rondell.itemProperties.size.width + 5)
      funcOpacity: (layerDist, rondell) ->
        0.8
        
    slider:
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
      itemProperties:
        sizeFocused:
          width: 600
          height: 300
        size:
          width: 600
          height: 300
      funcTop: (layerDiff, rondell) ->
        0
      funcLeft: (layerDiff, rondell) ->
        0
      funcOpacity: (layerDist, rondell) ->
        0.02
          
)(jQuery) 
