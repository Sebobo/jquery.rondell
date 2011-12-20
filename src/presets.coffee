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
      funcSize: (layerDiff, rondell) ->
        (rondell.maxItems / Math.abs(layerDiff)) / rondell.maxItems
      
    products:
      repeating: false
      alwaysShowCaption: true
      visibleItems: 4
      itemProperties:
        delay: 0
      center:
        left: 400 
        top: 100
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
        enabled: false
      funcTop: (layerDiff, rondell) ->
          rondell.center.top - rondell.itemProperties.size.height / 2
      funcLeft: (layerDiff, rondell) ->
          rondell.center.left + layerDiff * rondell.itemProperties.size.width
      funcDiff: (layerDiff, rondell) ->
          Math.abs(layerDiff) + 0.5
      
    cubic:
      funcTop: (layerDiff, rondell) ->
          rondell.center.top - rondell.itemProperties.size.height / 2 + Math.pow(layerDiff / 2, 3) * rondell.radius.x
      funcLeft: (layerDiff, rondell) ->
          rondell.center.left - rondell.itemProperties.size.width / 2 + Math.sin(layerDiff) * rondell.radius.x
      funcSize: (layerDiff, rondell) ->
          Math.pow((Math.PI - Math.abs(layerDiff)) / Math.PI, 3)
          
)(jQuery) 
