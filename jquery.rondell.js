/*
 * jQuery rondell plugin
 * @name jquery.rondell.js
 * @author Sebastian Helzle
 * @version 0.7.1
 * @date Feb 28, 2011
 * @category jQuery plugin
 * @copyright (c) 2009-2011 Sebastian Helzle (www.sebastianhelzle.net)
 * @license CC Attribution 3.0 - http://creativecommons.org/licenses/by/3.0/deed.en
 */

jQuery.rondell = {
	version: '0.7.1',
    name: 'rondell',
    layer_count: 0,
    current_layer: 1,
    radius: {x: 300, y: 300},  
    center: {left: 400, top: 350},
    size: {width: undefined, height: undefined},
    visible_items: 'auto',
    scaling: 2,
    opacity_min: 0.01, 
    fade_time: 300,
    item_delay: 100,
    item_class: 'rondell_item',
    resizeable_class: 'resizeable',
    small_class: 'item_small',
    hidden_class: 'item_hidden',
    item_size: {width: 150, height: 150},
    item_size_focus: {width: 0, height: 0},
    item_top_margin: 20, 
    items: [],
    repeating: true,
    auto_rotation: false,
    auto_rotation_paused: false,
    auto_rotation_timer: -1,
    auto_rotation_direction: 0,
    auto_rotation_once: false,
    auto_rotation_delay: 5000,
    controls_enabled: true,
    controls_fade_time: 400,
    controls_margin: {x: 20, y: 20},
    strings: {prev: 'prev', next: 'next'},
    func_left: function(layer_diff, options) {
        return options.center.left - options.item_size.width / 2.0 + Math.sin(layer_diff) * options.radius.x
    },
    func_top: function(layer_diff, options) {
        return options.center.top - options.item_size.height / 2.0 + Math.cos(layer_diff) * options.radius.y
    },
    func_diff: function(layer_diff, options) {
        return Math.pow(Math.abs(layer_diff) / options.layer_count, 0.5) * Math.PI
    },
    func_ease: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t + b;
		return -c/2 * ((--t)*(t-2) - 1) + b
	},
	func_opacity: function (layer_dist, options) {
		return options.opacity_min + (1.0 - options.opacity_min) * (1.0 - Math.pow(layer_dist / options.visible_items, 2))
	},
    show_caption: function(layer_num, options) { options.items[options.current_layer].object.find('.rondell_caption.overlay').stop().fadeTo(300, 1); },
    hide_captions: function(options) { $('.rondell_caption.overlay').stop().fadeTo(200, 0); },
    event: {
        layer_fadein: function(layer_num, options) {
            var item = options.items[layer_num];
            item.small = false;
            item.object
            .animate({
                width: item.size_focus.width + 'px',
                height: item.size_focus.height + 'px',
                left: options.center.left - item.size_focus.width / 2.0 + 'px',
                top: options.center.top - item.size_focus.height / 2.0 + 'px',
                opacity: "1.0"
            }, options.fade_time, options.func_ease, options.event.auto_shift(options))
            .css('z-index', 6000)
           	.addClass('rondell_item_focused');
            if (item.icon && !item.resizeable)
                item.icon.animate({marginTop: options.item_top_margin + (options.item_size.height - item.icon.height()) / 2 + 'px'}, options.fade_time)
        },
        layer_fadeout: function(layer_num, options) {
            var item = options.items[layer_num];
	        var layer_dist = Math.abs(layer_num - options.current_layer);
            if (layer_dist > options.visible_items && options.repeating) {
                if (options.current_layer + options.visible_items > options.layer_count)
                    layer_num += options.layer_count
                else if (options.current_layer - options.visible_items <= options.layer_count)
                    layer_num -= options.layer_count
                layer_dist = Math.abs(layer_num - options.current_layer);
            }
            // get the absolute layer number difference
            var layer_diff = options.func_diff(layer_num - options.current_layer, options);
            if (layer_num < options.current_layer)
                layer_diff *= -1;
            // is item visible
            if (layer_dist <= options.visible_items) {
                item.object.animate({
                    width:   item.size_small.width + 'px',
                    height:  item.size_small.height + 'px',
                    left:    options.func_left(layer_diff, options) + (options.item_size.width - item.size_small.width) / 2 + 'px',
                    top:     options.func_top(layer_diff, options) + (options.item_size.height - item.size_small.height) / 2 + 'px',
                    opacity: options.opacity_min != 1 ? options.func_opacity(layer_dist, options) : 1
                }, options.fade_time + options.item_delay * layer_dist, options.func_ease);
                if (item.hidden)
                    item.hidden = false
                if (!item.small) {
                    item.small = true
                    if (!item.resizeable) {
                        var margin = (options.item_size.height - item.icon.height()) / 2 + 'px';
                        item.icon.animate({marginTop: margin, marginBottom: margin}, options.fade_time)
                    }
                }
                // create correct z-order
                item.object.css('z-index', layer_diff < 0 ? 5000 + layer_num : 5000 - layer_num)
            	.removeClass('rondell_item_focused');
            } else if (!item.hidden) {
                // hide the items which are moved out of view
                item.hidden = true;
                item.object.fadeTo(options.fade_time / 2 + options.item_delay * layer_dist, 0)
            }
        },
        shift_to: function(layer_num, options) {
            if ((layer_num > 0 && layer_num <= options.layer_count) || options.repeating) {
                if (layer_num < 1) layer_num = options.layer_count;
                else if (layer_num > options.layer_count) layer_num = 1;
                options.current_layer = layer_num;
                for (var i = 1; i <= options.layer_count; i++) {
                    if (i != options.current_layer)
                        options.event.layer_fadeout(i, options);
                }
                options.event.layer_fadein(options.current_layer, options)
            }
			options.hide_captions(options);
			if (options.hovering) options.show_caption(options.current_layer, options); 
        },
        shift_left: function(options) { 
		    options.event.shift_to(options.current_layer - 1, options); 
			options.hide_captions(options);
			if (options.hovering) options.show_caption(options.current_layer, options);  
		},
        shift_right: function(options) { 
		    options.event.shift_to(options.current_layer + 1, options); 
			options.hide_captions(options) 
            if (options.hovering) options.show_caption(options.current_layer, options);
		},
		auto_shift: function(options) {  
			if (options.auto_rotation && options.auto_rotation_timer == -1) {
				// store timer id
				options.auto_rotation_timer = window.setTimeout(function() {
					options.auto_rotation_timer = -1;
					if (!options.auto_rotation_paused) {
						if (options.auto_rotation_direction == 0)
							options.event.shift_left(options);
						else
							options.event.shift_right(options);
					}
				}, options.auto_rotation_delay);
			}
		},
        // key controls
        key_down: function(key, options) {
        	switch (key) {
        	case 37: // arrow left
        		options.event.shift_left(options);
        		break;
        	case 39: // arrow right
        		options.event.shift_right(options);
        	}
        }
    }
};

jQuery.fn.rondell = function(options) {
    options = jQuery.extend(
        jQuery.rondell,
        options || {}
    );
	
	options.size.width  = options.size.width || (options.center.left + 1.5 * options.item_size.width + options.radius.x / 2);
	options.size.height = options.size.height || (options.center.top + options.item_size.height + options.radius.y / 2);
	
    // setup each item
    this.each(function() {
        var obj = jQuery(this);
        options.layer_count += 1;
        var layer_num = options.layer_count;
        var icon = obj.find('img:first');
        var is_resizeable = icon.hasClass(options.resizeable_class);
        // create size vars for the small and focused size
        var sm_width = icon.width();
        var sm_height = icon.height();
        var fo_width = sm_width;
        var fo_height = sm_height;
        if (is_resizeable) {
            if (sm_width >= sm_height) {
                // compute smaller side length
                sm_height *= options.item_size.width / sm_width;
                fo_height *= options.item_size_focus.width / fo_width;
                // compute full size length
                sm_width = options.item_size.width;
                fo_width = options.item_size_focus.width;
            } else {
                // compute smaller side length
                sm_width *= options.item_size.height / sm_height;
                fo_width *= options.item_size_focus.height / fo_height;
                // compute full size length
                sm_height = options.item_size.height;
                fo_height = options.item_size_focus.height;
            }
        } else {
            // scale to given sizes
            sm_width = options.item_size.width;
            sm_height = options.item_size.height;
            fo_width = options.item_size_focus.width > 0 ? options.item_size_focus.width : sm_width * options.scaling;
            fo_height = options.item_size_focus.height > 0 ? options.item_size_focus.height : sm_height * options.scaling;    
        }
        // set vars in item array
        options.items[layer_num] = {
            object: obj, 
            icon: icon, 
            small: false, 
            hidden: false, 
            resizeable: is_resizeable,
            size_small: {width: sm_width, height: sm_height},
            size_focus: {width: fo_width, height: fo_height}
        };
		// Wrap other content as overlay caption
		var caption_content = icon.length ? icon.siblings() : obj.children();
		if (caption_content.length) {
		    caption_content.wrapAll('<div class="rondell_caption"></div>');
			if (icon.length) {
				// Rearrange caption after icon
				obj.append(caption_content.parent().remove());
				obj.find('.rondell_caption').addClass('overlay');
			}
		}
        // init click events
        obj.addClass(options.item_class)
        .click(function(){ 
            if (options.current_layer != layer_num) {
                options.event.shift_to(layer_num, options);
                return false;
            }
        });
    });
    // wrap the elements with a block div to have a fixed height
    this.wrapAll('<div class="rondell_container"></div>');
    // get container
    var container = this.parent();
	container.css({
		overflow: 'hidden',
		width: options.size.width,
		display: 'block', 
		position: 'relative',
		height: options.size.height
	});

	// add hover function to container
	container.hover(function() {
        options.hovering = true;
		if (!options.auto_rotation_paused)
			options.auto_rotation_paused = true;
        options.show_caption(options.current_layer, options);
	}, function() {
        options.hovering = false;
		if (options.auto_rotation_paused && !options.auto_rotation_once) {
			options.auto_rotation_paused = false;
			options.event.auto_shift(options);
		}
        options.hide_captions(options);
	});

    // create controls
    if (options.controls_enabled) {
		var c_container = jQuery('<div class="rondell_controls"><a href="/" class="rondell_control rondell_shift_left">' + options.strings.prev + '</a><a href="/" class="rondell_control rondell_shift_right">' + options.strings.next + '</a></div>');
		container.append(c_container);

        // attach hover events to container
	    container.hover(function() {
	    	c_container.find('.rondell_control').stop().fadeTo(options.controls_fade_time, 1)
	        }, function() {
	    	c_container.find('.rondell_control').stop().fadeTo(options.controls_fade_time, 0)
	    });
	    c_container.children().fadeTo(0, 0);
	    
	    var c_shift_left = c_container.find('.rondell_shift_left');
	    var c_shift_right = c_container.find('.rondell_shift_right');
	    
        var focus_width = options.item_size_focus.width > 0 ? options.item_size_focus.width : options.item_size.width * options.scaling;
        var focus_height = options.item_size_focus.height > 0 ? options.item_size_focus.height : options.item_size.height * options.scaling;
	    c_container.css({
	        left: options.controls_margin.x,
	        top: options.controls_margin.y,
	        width: options.size.width - options.controls_margin.x * 2});
	        
	    c_shift_left.click(function() { options.event.shift_left(options); return false });
	    c_shift_right.click(function() { options.event.shift_right(options); return false });
    }
    
    // attach keydown event to document
    jQuery(document).keydown(function(e) { options.event.key_down(e.which, options) });
    
    // set visible_items if set to auto
    if (options.visible_items == 'auto')
        options.visible_items = options.current_layer;
        
    // move items to starting positions
    for (var i = 1; i <= options.layer_count; i++)
        options.event.layer_fadeout(i, options);
    
    options.event.layer_fadein(options.current_layer, options);
        
    container.children().css('visibility', 'visible');
    return jQuery(this);
};