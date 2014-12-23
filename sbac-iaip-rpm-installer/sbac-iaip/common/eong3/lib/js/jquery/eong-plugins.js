/**
 *
 * Color picker
 * Author: Stefan Petre www.eyecon.ro
 * 
 * Dual licensed under the MIT and GPL licenses
 * 
 */
(function ($) {
    var ColorPicker = function () {
        var counter = 0;
        var
            ids = {},
            inAction,
            charMin = 65,
            visible,
            tpl = '<div class="colorpicker"><div class="colorpicker_color"><div><div></div></div></div><div class="colorpicker_hue"><div></div></div><div class="colorpicker_new_color"></div><div class="colorpicker_current_color"></div><div class="colorpicker_hex"><input type="text" maxlength="6" size="6" /></div><div class="colorpicker_rgb_r colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_g colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_rgb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_h colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_s colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_hsb_b colorpicker_field"><input type="text" maxlength="3" size="3" /><span></span></div><div class="colorpicker_submit"></div></div>',
            defaults = {
                eventName: 'click',
                onShow: function () {},
                onBeforeShow: function(){},
                onHide: function () {},
                onChange: function () {},
                onSubmit: function () {},
                color: 'ff0000',
                livePreview: true,
                flat: false
            },
            fillRGBFields = function  (hsb, cal) {
                var rgb = HSBToRGB(hsb);
                $(cal).data('colorpicker').fields
                    .eq(1).val(rgb.r).end()
                    .eq(2).val(rgb.g).end()
                    .eq(3).val(rgb.b).end();
            },
            fillHSBFields = function  (hsb, cal) {
                $(cal).data('colorpicker').fields
                    .eq(4).val(hsb.h).end()
                    .eq(5).val(hsb.s).end()
                    .eq(6).val(hsb.b).end();
            },
            fillHexFields = function (hsb, cal) {
                $(cal).data('colorpicker').fields
                    .eq(0).val(HSBToHex(hsb)).end();
            },
            setSelector = function (hsb, cal) {
                $(cal).data('colorpicker').selector.css('backgroundColor', '#' + HSBToHex({h: hsb.h, s: 100, b: 100}));
                $(cal).data('colorpicker').selectorIndic.css({
                    left: parseInt(150 * hsb.s/100, 10),
                    top: parseInt(150 * (100-hsb.b)/100, 10)
                });
            },
            setHue = function (hsb, cal) {
                $(cal).data('colorpicker').hue.css('top', parseInt(150 - 150 * hsb.h/360, 10));
            },
            setCurrentColor = function (hsb, cal) {
                $(cal).data('colorpicker').currentColor.css('backgroundColor', '#' + HSBToHex(hsb));
            },
            setNewColor = function (hsb, cal) {
                $(cal).data('colorpicker').newColor.css('backgroundColor', '#' + HSBToHex(hsb));
            },
            keyDown = function (ev) {
                var pressedKey = ev.charCode || ev.keyCode || -1;
                if ((pressedKey > charMin && pressedKey <= 90) || pressedKey == 32) {
                    return false;
                }
                var cal = $(this).parent().parent();
                if (cal.data('colorpicker').livePreview === true) {
                    change.apply(this);
                }
            },
            change = function (ev) {
                var cal = $(this).parent().parent(), col;
                if (this.parentNode.className.indexOf('_hex') > 0) {
                    cal.data('colorpicker').color = col = HexToHSB(fixHex(this.value));
                } else if (this.parentNode.className.indexOf('_hsb') > 0) {
                    cal.data('colorpicker').color = col = fixHSB({
                        h: parseInt(cal.data('colorpicker').fields.eq(4).val(), 10),
                        s: parseInt(cal.data('colorpicker').fields.eq(5).val(), 10),
                        b: parseInt(cal.data('colorpicker').fields.eq(6).val(), 10)
                    });
                } else {
                    cal.data('colorpicker').color = col = RGBToHSB(fixRGB({
                        r: parseInt(cal.data('colorpicker').fields.eq(1).val(), 10),
                        g: parseInt(cal.data('colorpicker').fields.eq(2).val(), 10),
                        b: parseInt(cal.data('colorpicker').fields.eq(3).val(), 10)
                    }));
                }
                if (ev) {
                    fillRGBFields(col, cal.get(0));
                    fillHexFields(col, cal.get(0));
                    fillHSBFields(col, cal.get(0));
                }
                setSelector(col, cal.get(0));
                setHue(col, cal.get(0));
                setNewColor(col, cal.get(0));
                cal.data('colorpicker').onChange.apply(cal, [col, HSBToHex(col), HSBToRGB(col)]);
            },
            blur = function (ev) {
                var cal = $(this).parent().parent();
                cal.data('colorpicker').fields.parent().removeClass('colorpicker_focus');
            },
            focus = function () {
                charMin = this.parentNode.className.indexOf('_hex') > 0 ? 70 : 65;
                $(this).parent().parent().data('colorpicker').fields.parent().removeClass('colorpicker_focus');
                $(this).parent().addClass('colorpicker_focus');
            },
            downIncrement = function (ev) {
                var field = $(this).parent().find('input').focus();
                var current = {
                    el: $(this).parent().addClass('colorpicker_slider'),
                    max: this.parentNode.className.indexOf('_hsb_h') > 0 ? 360 : (this.parentNode.className.indexOf('_hsb') > 0 ? 100 : 255),
                    y: ev.pageY,
                    field: field,
                    val: parseInt(field.val(), 10),
                    preview: $(this).parent().parent().data('colorpicker').livePreview                  
                };
                $(document).bind('mouseup', current, upIncrement);
                $(document).bind('mousemove', current, moveIncrement);
            },
            moveIncrement = function (ev) {
                ev.data.field.val(Math.max(0, Math.min(ev.data.max, parseInt(ev.data.val + ev.pageY - ev.data.y, 10))));
                if (ev.data.preview) {
                    change.apply(ev.data.field.get(0), [true]);
                }
                return false;
            },
            upIncrement = function (ev) {
                change.apply(ev.data.field.get(0), [true]);
                ev.data.el.removeClass('colorpicker_slider').find('input').focus();
                $(document).unbind('mouseup', upIncrement);
                $(document).unbind('mousemove', moveIncrement);
                return false;
            },
            downHue = function (ev) {
                var current = {
                    cal: $(this).parent(),
                    y: $(this).offset().top
                };
                current.preview = current.cal.data('colorpicker').livePreview;
                $(document).bind('mouseup', current, upHue);
                $(document).bind('mousemove', current, moveHue);
            },
            moveHue = function (ev) {
                counter++;
                if (counter == 5) {
                    change.apply(
                        ev.data.cal.data('colorpicker')
                            .fields
                            .eq(4)
                            .val(parseInt(360*(150 - Math.max(0,Math.min(150,(ev.pageY - ev.data.y))))/150, 10))
                            .get(0),
                        [ev.data.preview]
                    );
                    counter = 0;
                }
                
                return false;
            },
            clickHue = function (ev) {
                var current = {
                    cal: $(this).parent(),
                    y: $(this).offset().top
                };
                current.preview = current.cal.data('colorpicker').livePreview;
                change.apply(
                    current.cal.data('colorpicker')
                        .fields
                        .eq(4)
                        .val(parseInt(360*(150 - Math.max(0,Math.min(150,(ev.pageY - current.y))))/150, 10))
                        .get(0),
                    [current.preview]
                );
            },
            upHue = function (ev) {
                fillRGBFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
                fillHexFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
                $(document).unbind('mouseup', upHue);
                $(document).unbind('mousemove', moveHue);
                return false;
            },
            downSelector = function (ev) {
                var current = {
                    cal: $(this).parent(),
                    pos: $(this).offset()
                };
                current.preview = current.cal.data('colorpicker').livePreview;
                $(document).bind('mouseup', current, upSelector);
                $(document).bind('mousemove', current, moveSelector);
            },
            moveSelector = function (ev) {
                counter++;
                if (counter == 5) {
                    change.apply(
                    ev.data.cal.data('colorpicker')
                        .fields
                        .eq(6)
                        .val(parseInt(100*(150 - Math.max(0,Math.min(150,(ev.pageY - ev.data.pos.top))))/150, 10))
                        .end()
                        .eq(5)
                        .val(parseInt(100*(Math.max(0,Math.min(150,(ev.pageX - ev.data.pos.left))))/150, 10))
                        .get(0),
                        [ev.data.preview]
                    );
                    counter = 0;
                }
                
                return false;
            },
            clickSelector = function (ev) {
                var current = {
                    cal: $(this).parent(),
                    pos: $(this).offset()
                };
                current.preview = current.cal.data('colorpicker').livePreview;
                change.apply(
                    current.cal.data('colorpicker')
                        .fields
                        .eq(6)
                        .val(parseInt(100*(150 - Math.max(0,Math.min(150,(ev.pageY - current.pos.top))))/150, 10))
                        .end()
                        .eq(5)
                        .val(parseInt(100*(Math.max(0,Math.min(150,(ev.pageX - current.pos.left))))/150, 10))
                        .get(0),
                    [current.preview]
                );
                return false;
            },
            upSelector = function (ev) {
                fillRGBFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
                fillHexFields(ev.data.cal.data('colorpicker').color, ev.data.cal.get(0));
                $(document).unbind('mouseup', upSelector);
                $(document).unbind('mousemove', moveSelector);
                return false;
            },
            enterSubmit = function (ev) {
                $(this).addClass('colorpicker_focus');
            },
            leaveSubmit = function (ev) {
                $(this).removeClass('colorpicker_focus');
            },
            clickSubmit = function (ev) {
                var cal = $(this).parent();
                var col = cal.data('colorpicker').color;
                cal.data('colorpicker').origColor = col;
                setCurrentColor(col, cal.get(0));
                cal.data('colorpicker').onSubmit(col, HSBToHex(col), HSBToRGB(col), cal.data('colorpicker').el);
            },
            show = function (ev) {
                var cal = $('#' + $(this).data('colorpickerId'));
                cal.data('colorpicker').onBeforeShow.apply(this, [cal.get(0)]);
                var pos = $(this).offset();
                var viewPort = getViewport();
                var top = pos.top + this.offsetHeight;
                var left = pos.left;
                if (top + 176 > viewPort.t + viewPort.h) {
                    top -= this.offsetHeight + 176;
                }
                if (left + 356 > viewPort.l + viewPort.w) {
                    left -= 356;
                }
                cal.css({left: left + 'px', top: top + 'px'});
                if (cal.data('colorpicker').onShow.apply(this, [cal.get(0)]) != false) {
                    cal.show();
                }
                $(document).bind('mousedown', {cal: cal}, hide);
                return false;
            },
            hide = function (ev) {
                if (!isChildOf(ev.data.cal.get(0), ev.target, ev.data.cal.get(0))) {
                    if (ev.data.cal.data('colorpicker').onHide.apply(this, [ev.data.cal.get(0)]) != false) {
                        ev.data.cal.hide();
                    }
                    $(document).unbind('mousedown', hide);
                }
            },
            isChildOf = function(parentEl, el, container) {
                if (parentEl == el) {
                    return true;
                }
                if (parentEl.contains) {
                    return parentEl.contains(el);
                }
                if ( parentEl.compareDocumentPosition ) {
                    return !!(parentEl.compareDocumentPosition(el) & 16);
                }
                var prEl = el.parentNode;
                while(prEl && prEl != container) {
                    if (prEl == parentEl)
                        return true;
                    prEl = prEl.parentNode;
                }
                return false;
            },
            getViewport = function () {
                var m = document.compatMode == 'CSS1Compat';
                return {
                    l : window.pageXOffset || (m ? document.documentElement.scrollLeft : document.body.scrollLeft),
                    t : window.pageYOffset || (m ? document.documentElement.scrollTop : document.body.scrollTop),
                    w : window.innerWidth || (m ? document.documentElement.clientWidth : document.body.clientWidth),
                    h : window.innerHeight || (m ? document.documentElement.clientHeight : document.body.clientHeight)
                };
            },
            fixHSB = function (hsb) {
                return {
                    h: Math.min(360, Math.max(0, hsb.h)),
                    s: Math.min(100, Math.max(0, hsb.s)),
                    b: Math.min(100, Math.max(0, hsb.b))
                };
            }, 
            fixRGB = function (rgb) {
                return {
                    r: Math.min(255, Math.max(0, rgb.r)),
                    g: Math.min(255, Math.max(0, rgb.g)),
                    b: Math.min(255, Math.max(0, rgb.b))
                };
            },
            fixHex = function (hex) {
                var len = 6 - hex.length;
                if (len > 0) {
                    var o = [];
                    for (var i=0; i<len; i++) {
                        o.push('0');
                    }
                    o.push(hex);
                    hex = o.join('');
                }
                return hex;
            }, 
            HexToRGB = function (hex) {
                var hex = parseInt(((hex.indexOf('#') > -1) ? hex.substring(1) : hex), 16);
                return {r: hex >> 16, g: (hex & 0x00FF00) >> 8, b: (hex & 0x0000FF)};
            },
            HexToHSB = function (hex) {
                return RGBToHSB(HexToRGB(hex));
            },
            RGBToHSB = function (rgb) {
                var hsb = {
                    h: 0,
                    s: 0,
                    b: 0
                };
                var min = Math.min(rgb.r, rgb.g, rgb.b);
                var max = Math.max(rgb.r, rgb.g, rgb.b);
                var delta = max - min;
                hsb.b = max;
                if (max != 0) {
                    
                }
                hsb.s = max != 0 ? 255 * delta / max : 0;
                if (hsb.s != 0) {
                    if (rgb.r == max) {
                        hsb.h = (rgb.g - rgb.b) / delta;
                    } else if (rgb.g == max) {
                        hsb.h = 2 + (rgb.b - rgb.r) / delta;
                    } else {
                        hsb.h = 4 + (rgb.r - rgb.g) / delta;
                    }
                } else {
                    hsb.h = -1;
                }
                hsb.h *= 60;
                if (hsb.h < 0) {
                    hsb.h += 360;
                }
                hsb.s *= 100/255;
                hsb.b *= 100/255;
                return hsb;
            },
            HSBToRGB = function (hsb) {
                var rgb = {};
                var h = Math.round(hsb.h);
                var s = Math.round(hsb.s*255/100);
                var v = Math.round(hsb.b*255/100);
                if(s == 0) {
                    rgb.r = rgb.g = rgb.b = v;
                } else {
                    var t1 = v;
                    var t2 = (255-s)*v/255;
                    var t3 = (t1-t2)*(h%60)/60;
                    if(h==360) h = 0;
                    if(h<60) {rgb.r=t1; rgb.b=t2; rgb.g=t2+t3}
                    else if(h<120) {rgb.g=t1; rgb.b=t2; rgb.r=t1-t3}
                    else if(h<180) {rgb.g=t1; rgb.r=t2; rgb.b=t2+t3}
                    else if(h<240) {rgb.b=t1; rgb.r=t2; rgb.g=t1-t3}
                    else if(h<300) {rgb.b=t1; rgb.g=t2; rgb.r=t2+t3}
                    else if(h<360) {rgb.r=t1; rgb.g=t2; rgb.b=t1-t3}
                    else {rgb.r=0; rgb.g=0; rgb.b=0}
                }
                return {r:Math.round(rgb.r), g:Math.round(rgb.g), b:Math.round(rgb.b)};
            },
            RGBToHex = function (rgb) {
                var hex = [
                    rgb.r.toString(16),
                    rgb.g.toString(16),
                    rgb.b.toString(16)
                ];
                $.each(hex, function (nr, val) {
                    if (val.length == 1) {
                        hex[nr] = '0' + val;
                    }
                });
                return hex.join('');
            },
            HSBToHex = function (hsb) {
                return RGBToHex(HSBToRGB(hsb));
            },
            restoreOriginal = function () {
                var cal = $(this).parent();
                var col = cal.data('colorpicker').origColor;
                cal.data('colorpicker').color = col;
                fillRGBFields(col, cal.get(0));
                fillHexFields(col, cal.get(0));
                fillHSBFields(col, cal.get(0));
                setSelector(col, cal.get(0));
                setHue(col, cal.get(0));
                setNewColor(col, cal.get(0));
            };
        return {
            init: function (opt) {
                opt = $.extend({}, defaults, opt||{});
                if (typeof opt.color == 'string') {
                    opt.color = HexToHSB(opt.color);
                } else if (opt.color.r != undefined && opt.color.g != undefined && opt.color.b != undefined) {
                    opt.color = RGBToHSB(opt.color);
                } else if (opt.color.h != undefined && opt.color.s != undefined && opt.color.b != undefined) {
                    opt.color = fixHSB(opt.color);
                } else {
                    return this;
                }
                return this.each(function () {
                    if (!$(this).data('colorpickerId')) {
                        var options = $.extend({}, opt);
                        options.origColor = opt.color;
                        var id = 'collorpicker_' + parseInt(Math.random() * 1000);
                        $(this).data('colorpickerId', id);
                        var cal = $(tpl).attr('id', id);
                        if (options.flat) {
                            cal.appendTo(this).show();
                        } else {
                            cal.appendTo(document.body);
                        }
                        options.fields = cal
                                            .find('input')
                                                .bind('keyup', keyDown)
                                                .bind('change', change)
                                                .bind('blur', blur)
                                                .bind('focus', focus);
                        cal
                            .find('span').bind('mousedown', downIncrement).end()
                            .find('>div.colorpicker_current_color').bind('click', restoreOriginal);
                        options.selector = cal.find('div.colorpicker_color').bind('mousedown', downSelector);
                        cal.find('div.colorpicker_color').bind('click', clickSelector);
                        options.selectorIndic = options.selector.find('div div');
                        options.el = this;
                        options.hue = cal.find('div.colorpicker_hue div');
                        cal.find('div.colorpicker_hue').bind('mousedown', downHue);
                        cal.find('div.colorpicker_hue').bind('click', clickHue);
                        options.newColor = cal.find('div.colorpicker_new_color');
                        options.currentColor = cal.find('div.colorpicker_current_color');
                        cal.data('colorpicker', options);
                        cal.find('div.colorpicker_submit')
                            .bind('mouseenter', enterSubmit)
                            .bind('mouseleave', leaveSubmit)
                            .bind('click', clickSubmit);
                        fillRGBFields(options.color, cal.get(0));
                        fillHSBFields(options.color, cal.get(0));
                        fillHexFields(options.color, cal.get(0));
                        setHue(options.color, cal.get(0));
                        setSelector(options.color, cal.get(0));
                        setCurrentColor(options.color, cal.get(0));
                        setNewColor(options.color, cal.get(0));
                        if (options.flat) {
                            cal.css({
                                position: 'relative',
                                display: 'block'
                            });
                        } else {
                            $(this).bind(options.eventName, show);
                        }
                    }
                });
            },
            showPicker: function() {
                return this.each( function () {
                    if ($(this).data('colorpickerId')) {
                        show.apply(this);
                    }
                });
            },
            hidePicker: function() {
                return this.each( function () {
                    if ($(this).data('colorpickerId')) {
                        $('#' + $(this).data('colorpickerId')).hide();
                    }
                });
            },
            setColor: function(col) {
                if (typeof col == 'string') {
                    col = HexToHSB(col);
                } else if (col.r != undefined && col.g != undefined && col.b != undefined) {
                    col = RGBToHSB(col);
                } else if (col.h != undefined && col.s != undefined && col.b != undefined) {
                    col = fixHSB(col);
                } else {
                    return this;
                }
                return this.each(function(){
                    if ($(this).data('colorpickerId')) {
                        var cal = $('#' + $(this).data('colorpickerId'));
                        cal.data('colorpicker').color = col;
                        cal.data('colorpicker').origColor = col;
                        fillRGBFields(col, cal.get(0));
                        fillHSBFields(col, cal.get(0));
                        fillHexFields(col, cal.get(0));
                        setHue(col, cal.get(0));
                        setSelector(col, cal.get(0));
                        setCurrentColor(col, cal.get(0));
                        setNewColor(col, cal.get(0));
                    }
                });
            }
        };
    }();
    $.fn.extend({
        ColorPicker: ColorPicker.init,
        ColorPickerHide: ColorPicker.hidePicker,
        ColorPickerShow: ColorPicker.showPicker,
        ColorPickerSetColor: ColorPicker.setColor
    });
})(jQuery);

/*
 * jQuery JSON Plugin
 * version: 1.0 (2008-04-17)
 *
 * This document is licensed as free software under the terms of the
 * MIT License: http://www.opensource.org/licenses/mit-license.php
 *
 * Brantley Harris technically wrote this plugin, but it is based somewhat
 * on the JSON.org website's http://www.json.org/json2.js, which proclaims:
 * "NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.", a sentiment that
 * I uphold.  I really just cleaned it up.
 *
 * It is also based heavily on MochiKit's serializeJSON, which is 
 * copywrited 2005 by Bob Ippolito.
 */
 
(function($) {   
    function toIntegersAtLease(n) 
    // Format integers to have at least two digits.
    {    
        return n < 10 ? '0' + n : n;
    }

    Date.prototype.toJSON = function(date)
    // Yes, it polutes the Date namespace, but we'll allow it here, as
    // it's damned usefull.
    {
        return this.getUTCFullYear()   + '-' +
             toIntegersAtLease(this.getUTCMonth()) + '-' +
             toIntegersAtLease(this.getUTCDate());
    };

    var escapeable = /["\\\x00-\x1f\x7f-\x9f]/g;
    var meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        };
        
    $.quoteString = function(string)
    // Places quotes around a string, inteligently.
    // If the string contains no control characters, no quote characters, and no
    // backslash characters, then we can safely slap some quotes around it.
    // Otherwise we must also replace the offending characters with safe escape
    // sequences.
    {
        if (escapeable.test(string))
        {
            return '"' + string.replace(escapeable, function (a) 
            {
                var c = meta[a];
                if (typeof c === 'string') {
                    return c;
                }
                c = a.charCodeAt();
                return '\\u00' + Math.floor(c / 16).toString(16) + (c % 16).toString(16);
            }) + '"';
        }
        return '"' + string + '"';
    };
    
    $.toJSON = function(o, compact)
    {
        var type = typeof(o);
        
        if (type == "undefined")
            return "undefined";
        else if (type == "number" || type == "boolean")
            return o + "";
        else if (o === null)
            return "null";
        
        // Is it a string?
        if (type == "string") 
        {
            return $.quoteString(o);
        }
        
        // Does it have a .toJSON function?
        if (type == "object" && typeof o.toJSON == "function") 
            return o.toJSON(compact);
        
        // Is it an array?
        if (type != "function" && typeof(o.length) == "number") 
        {
            var ret = [];
            for (var i = 0; i < o.length; i++) {
                ret.push( $.toJSON(o[i], compact) );
            }
            if (compact)
                return "[" + ret.join(",") + "]";
            else
                return "[" + ret.join(", ") + "]";
        }
        
        // If it's a function, we have to warn somebody!
        if (type == "function") {
            throw new TypeError("Unable to convert object of type 'function' to json.");
        }
        
        // It's probably an object, then.
        var ret = [];
        for (var k in o) {
            var name;
            type = typeof(k);
            
            if (type == "number")
                name = '"' + k + '"';
            else if (type == "string")
                name = $.quoteString(k);
            else
                continue;  //skip non-string or number keys
            
            var val = $.toJSON(o[k], compact);
            if (typeof(val) != "string") {
                // skip non-serializable values
                continue;
            }
            
            if (compact)
                ret.push(name + ":" + val);
            else
                ret.push(name + ": " + val);
        }
        return "{" + ret.join(", ") + "}";
    };
    
    $.compactJSON = function(o)
    {
        return $.toJSON(o, true);
    };
    
    $.evalJSON = function(src)
    // Evals JSON that we know to be safe.
    {
        return eval("(" + src + ")");
    };
    
    $.secureEvalJSON = function(src)
    // Evals JSON in a way that is *more* secure.
    {
        var filtered = src;
        filtered = filtered.replace(/\\["\\\/bfnrtu]/g, '@');
        filtered = filtered.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']');
        filtered = filtered.replace(/(?:^|:|,)(?:\s*\[)+/g, '');
        
        if (/^[\],:{}\s]*$/.test(filtered))
            return eval("(" + src + ")");
        else
            throw new SyntaxError("Error parsing JSON, source is not valid.");
    };
})(jQuery);

/**
* Function : dump()
* Arguments: The data - array,hash(associative array),object
*    The level - OPTIONAL
* Returns  : The textual representation of the array.
* This function was inspired by the print_r function of PHP.
* This will accept some data as the argument and return a
* text that will be a more readable version of the
* array/hash/object that is given.
*/
function dump(arr,level) {
var dumped_text = "";
if(!level) level = 0;

//The padding given at the beginning of the line.
var level_padding = "";
for(var j=0;j<level+1;j++) level_padding += "    ";

if(typeof(arr) == 'object') { //Array/Hashes/Objects
 for(var item in arr) {
  var value = arr[item];
 
  if(typeof(value) == 'object') { //If it is an array,
   dumped_text += level_padding + "'" + item + "' ...\n";
   dumped_text += dump(value,level+1);
  } else {
   dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
  }
 }
} else { //Stings/Chars/Numbers etc.
 dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
}
return dumped_text;
}

/**
 * jQuery.ScrollTo - Easy element scrolling using jQuery.
 * Copyright (c) 2007-2009 Ariel Flesler - aflesler(at)gmail(dot)com | http://flesler.blogspot.com
 * Dual licensed under MIT and GPL.
 * Date: 5/25/2009
 * @author Ariel Flesler
 * @version 1.4.2
 *
 * http://flesler.blogspot.com/2007/10/jqueryscrollto.html
 */
;(function(d){var k=d.scrollTo=function(a,i,e){d(window).scrollTo(a,i,e)};k.defaults={axis:'xy',duration:parseFloat(d.fn.jquery)>=1.3?0:1};k.window=function(a){return d(window)._scrollable()};d.fn._scrollable=function(){return this.map(function(){var a=this,i=!a.nodeName||d.inArray(a.nodeName.toLowerCase(),['iframe','#document','html','body'])!=-1;if(!i)return a;var e=(a.contentWindow||a).document||a.ownerDocument||a;return d.browser.safari||e.compatMode=='BackCompat'?e.body:e.documentElement})};d.fn.scrollTo=function(n,j,b){if(typeof j=='object'){b=j;j=0}if(typeof b=='function')b={onAfter:b};if(n=='max')n=9e9;b=d.extend({},k.defaults,b);j=j||b.speed||b.duration;b.queue=b.queue&&b.axis.length>1;if(b.queue)j/=2;b.offset=p(b.offset);b.over=p(b.over);return this._scrollable().each(function(){var q=this,r=d(q),f=n,s,g={},u=r.is('html,body');switch(typeof f){case'number':case'string':if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(f)){f=p(f);break}f=d(f,this);case'object':if(f.is||f.style)s=(f=d(f)).offset()}d.each(b.axis.split(''),function(a,i){var e=i=='x'?'Left':'Top',h=e.toLowerCase(),c='scroll'+e,l=q[c],m=k.max(q,i);if(s){g[c]=s[h]+(u?0:l-r.offset()[h]);if(b.margin){g[c]-=parseInt(f.css('margin'+e))||0;g[c]-=parseInt(f.css('border'+e+'Width'))||0}g[c]+=b.offset[h]||0;if(b.over[h])g[c]+=f[i=='x'?'width':'height']()*b.over[h]}else{var o=f[h];g[c]=o.slice&&o.slice(-1)=='%'?parseFloat(o)/100*m:o}if(/^\d+$/.test(g[c]))g[c]=g[c]<=0?0:Math.min(g[c],m);if(!a&&b.queue){if(l!=g[c])t(b.onAfterFirst);delete g[c]}});t(b.onAfter);function t(a){r.animate(g,j,b.easing,a&&function(){a.call(this,n,b)})}}).end()};k.max=function(a,i){var e=i=='x'?'Width':'Height',h='scroll'+e;if(!d(a).is('html,body'))return a[h]-d(a)[e.toLowerCase()]();var c='client'+e,l=a.ownerDocument.documentElement,m=a.ownerDocument.body;return Math.max(l[h],m[h])-Math.min(l[c],m[c])};function p(a){return typeof a=='object'?a:{top:a,left:a}}})(jQuery);

/**
2 * jQuery.LocalScroll - Animated scrolling navigation, using anchors.
3 * Copyright (c) 2007-2009 Ariel Flesler - aflesler(at)gmail(dot)com | http://flesler.blogspot.com
4 * Dual licensed under MIT and GPL.
5 * Date: 3/11/2009
6 * @author Ariel Flesler
7 * @version 1.2.7
8 **/
(function($){var l=location.href.replace(/#.*/,'');var g=$.localScroll=function(a){$('body').localScroll(a)};g.defaults={duration:1e3,axis:'y',event:'click',stop:true,target:window,reset:true};g.hash=function(a){if(location.hash){a=$.extend({},g.defaults,a);a.hash=false;if(a.reset){var e=a.duration;delete a.duration;$(a.target).scrollTo(0,a);a.duration=e}i(0,location,a)}};$.fn.localScroll=function(b){b=$.extend({},g.defaults,b);return b.lazy?this.bind(b.event,function(a){var e=$([a.target,a.target.parentNode]).filter(d)[0];if(e)i(a,e,b)}):this.find('a,area').filter(d).bind(b.event,function(a){i(a,this,b)}).end().end();function d(){return!!this.href&&!!this.hash&&this.href.replace(this.hash,'')==l&&(!b.filter||$(this).is(b.filter))}};function i(a,e,b){var d=e.hash.slice(1),f=document.getElementById(d)||document.getElementsByName(d)[0];if(!f)return;if(a)a.preventDefault();var h=$(b.target);if(b.lock&&h.is(':animated')||b.onBefore&&b.onBefore.call(b,a,f,h)===false)return;if(b.stop)h.stop(true);if(b.hash){var j=f.id==d?'id':'name',k=$('<a> </a>').attr(j,d).css({position:'absolute',top:$(window).scrollTop(),left:$(window).scrollLeft()});f[j]='';$('body').prepend(k);location=e.hash;k.remove();f[j]=d}h.scrollTo(f,b).trigger('notify.serialScroll',[f])}})(jQuery);

/*
 * jQuery UI Tooltip @VERSION
 *
 * Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://docs.jquery.com/UI/Tooltip
 *
 * Depends:
 *  jquery.ui.core.js
 *  jquery.ui.widget.js
 *  jquery.ui.position.js
 */
(function($) {

var increments = 0;

$.widget("ui.tooltip", {
    options: {
        tooltipClass: "ui-widget-content",
        content: function() {
            return $(this).attr("title");
        },
        position: "mouseBottom",
        offset: 15,
        autoclosetimeout: 3500,
        directionH: 'right',
        directionV: 'down',
        detectH: true, // do horizontal collision detection  
        detectV: true // do vertical collision detection
    },
    _init: function() {
        var self = this;
        this.tooltip = $("<div style=\"z-index: 1099;\"></div>")
            .attr("id", "ui-tooltip-" + increments++)
            .attr("role", "tooltip")
            .attr("aria-hidden", "true")
            .addClass("ui-tooltip ui-widget ui-corner-all")
            .addClass(this.options.tooltipClass)
            .appendTo(document.body)
            .hide();
        this.tooltipContent = $("<div></div>")
            .addClass("ui-tooltip-content")
            .appendTo(this.tooltip);
        this.opacity = this.tooltip.css("opacity");
        this.element
            .bind("focus.tooltip mouseover.tooltip", function(event) {
                self.show($(event.target), event);
            })
            .bind("blur.tooltip mouseout.tooltip click", function(event) {
                self.close();
            });
    },
    
    enable: function() {
        this.options.disabled = false;
    },
    
    disable: function() {
        this.options.disabled = true;
    },
    
    destroy: function() {
        this.tooltip.remove();
        $.Widget.prototype.destroy.apply(this, arguments);
    },
    
    widget: function() {
        return this.tooltip;
    },
    
    show: function(target, event) {
        // already visible? possible when both focus and mouseover events occur
        if (this.current && this.current[0] == target[0])
            return;
        var self = this;
        this.event = event;
        this.current = target;
        this.currentTitle = target.attr("title");
        var content = this.options.content.call(target[0], function(response) {
            if (self.current == target)
                self.open(target, response);
        });
        if (content) {
            self.open(target, content);
        }
    },
    
    open: function(target, content) {
        var self = this;
        if (!content)
            return;
        
        target.attr("title", "");
        
        if (this.options.disabled)
            return;
            
        this.tooltipContent.html(content);
        
        this.tooltip.position($.extend(this.options.position, {
            of: target
        }));

        
        this.tooltip.attr("aria-hidden", "false");
        target.attr("aria-describedby", this.tooltip.attr("id"));

        this.tooltip.show();

        this._trigger("show", null, { target: target });
        this.setPosition();
        window.setTimeout(function() {
            self.close();
        }, this.options.autoclosetimeout);
    },
    
    close: function() {
        if (!this.current)
            return;
        
        var current = this.current.attr("title", this.currentTitle);
        this.current = null;
        
        if (this.options.disabled)
            return;
        
        current.removeAttr("aria-describedby");
        this.tooltip.attr("aria-hidden", "true");
        
        
        jQuery(".ui-tooltip").hide();
        
    },
    
    setPosition: function(){
        var o = this.options;
        var triggerElement = this.element;
        var toolTipElement = this.tooltip;
        var triggerDims = {
            posX: triggerElement.offset().left,
            posY: triggerElement.offset().top,
            elW: triggerElement.getTotalWidth(),
            elH: triggerElement.getTotalHeight()
        };
        var toolTipDims = {
            posX: toolTipElement.offset().left,
            posY: toolTipElement.offset().top,
            elW: toolTipElement.getTotalWidth(),
            elH: toolTipElement.getTotalHeight()
        };
        var o = o;
        var xVal, yVal, posLeft, posRight, posTop, posBottom;
        var offsetDiag = 0;
        if (o.offset !== undefined && o.offset !== 0) {
            offsetDiag = Math.sqrt((Math.pow(o.offset,2)/2));
        }
        
        var mouseCoordinateX = this.event.pageX;
        var mouseCoordinateY = this.event.pageY;
        
        switch(o.position) {
            case "n": 
                posLeft = (triggerDims.posX + (triggerDims.elW/2)) - (toolTipDims.elW/2);
                posTop = triggerDims.posY - toolTipDims.elH - o.offset;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "ne":
                posLeft = triggerDims.posX + triggerDims.elW + offsetDiag;
                posTop = triggerDims.posY - toolTipDims.elH - offsetDiag;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "e":
                posLeft = triggerDims.posX + triggerDims.elW + o.offset;
                posTop = (triggerDims.posY + (triggerDims.elH/2)) - (toolTipDims.elH/2);
                posBottom = "auto";
                posRight = "auto";
            break;
            case "se":
                posLeft = triggerDims.posX + triggerDims.elW + offsetDiag;
                posTop = triggerDims.posY + triggerDims.elH + offsetDiag;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "s":
                posLeft = (triggerDims.posX + (triggerDims.elW/2)) - (toolTipDims.elW/2);
                posTop = triggerDims.posY + triggerDims.elH + o.offset;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "sw":
                posLeft = triggerDims.posX - toolTipDims.elW - offsetDiag;
                posTop = triggerDims.posY + triggerDims.elH + offsetDiag;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "w":
                posLeft = triggerDims.posX - toolTipDims.elW - o.offset;
                posTop = (triggerDims.posY + (triggerDims.elH/2)) - (toolTipDims.elH/2);
                posBottom = "auto";
                posRight = "auto";
            break;
            case "nw":
                posLeft = triggerDims.posX - toolTipDims.elW - offsetDiag;
                posTop = triggerDims.posY - toolTipDims.elH - offsetDiag;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "mouseTop":
                posLeft = mouseCoordinateX;
                posTop = mouseCoordinateY - toolTipDims.elH - o.offset;
                posBottom = "auto";
                posRight = "auto";
            break;
            case "mouseBottom":
                posLeft = mouseCoordinateX;
                posTop = mouseCoordinateY + o.offset;
                posBottom = "auto";
                posRight = "auto";
            break;
        }


        
        this.tooltip.css({
            position: 'absolute',
            left: posLeft,
            top: posTop,
            bottom: posBottom,
            right: posRight
        });
        
        
    }
});

$.extend($.ui.tooltip, {
    defaults: {
        tooltipClass: "ui-widget-content",
        content: function() {
            return $(this).attr("title");
        },
        position: "mouseBottom",
        offset: 15,
        autoclosetimeout: 3500,
        directionH: 'right',
        directionV: 'down',
        detectH: true, // do horizontal collision detection  
        detectV: true // do vertical collision detection
    }
});

/* Utilities to sort and find viewport dimensions */
    
function sortBigToSmall(a, b) { return b - a; };

jQuery.fn.getTotalWidth = function(){
    return $(this).width() + parseInt($(this).css('paddingRight')) + parseInt($(this).css('paddingLeft')) + parseInt($(this).css('borderRightWidth')) + parseInt($(this).css('borderLeftWidth'));
};

jQuery.fn.getTotalHeight = function(){
    return $(this).height() + parseInt($(this).css('paddingTop')) + parseInt($(this).css('paddingBottom')) + parseInt($(this).css('borderTopWidth')) + parseInt($(this).css('borderBottomWidth'));
};

function getScrollTop(){
    return self.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop;
};

function getScrollLeft(){
    return self.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft;
};

function getWindowHeight(){
    var de = document.documentElement;
    return self.innerHeight || (de && de.clientHeight) || document.body.clientHeight;
};

function getWindowWidth(){
    var de = document.documentElement;
    return self.innerWidth || (de && de.clientWidth) || document.body.clientWidth;
};

/* Utilities to test whether an element will fit in the viewport
    Parameters:
    el = element to position, required
    leftOffset / topOffset = optional parameter if the offset cannot be calculated (i.e., if the object is in the DOM but is set to display: 'none') */
    
function fitHorizontal(el, leftOffset){
    var leftVal = parseInt(leftOffset) || $(el).offset().left;
    return (leftVal + $(el).width() <= getWindowWidth() + getScrollLeft() && leftVal - getScrollLeft() >= 0);
};

function fitVertical(el, topOffset){
    var topVal = parseInt(topOffset) || $(el).offset().top;
    return (topVal + $(el).height() <= getWindowHeight() + getScrollTop() && topVal - getScrollTop() >= 0);
};

})(jQuery);

/*
HTMLEncode - Encode HTML special characters.
Copyright (c) 2006 Thomas Peri, http://www.tumuski.com/

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The Software shall be used for Good, not Evil.

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * HTML-Encode the supplied input
 * 
 * Parameters:
 *
 * (String)  source    The text to be encoded.
 * 
 * (boolean) display   The output is intended for display.
 *
 *                     If true:
 *                     * Tabs will be expanded to the number of spaces 
 *                       indicated by the 'tabs' argument.
 *                     * Line breaks will be converted to <br />.
 *
 *                     If false:
 *                     * Tabs and linebreaks get turned into &#____;
 *                       entities just like all other control characters.
 *
 * (integer) tabs      The number of spaces to expand tabs to.  (Ignored 
 *                     when the 'display' parameter evaluates to false.)
 *
 * v 0.3 - January 4, 2006
 */
function htmlEncode(source, display, tabs)
{
    function special(source)
    {
        var result = '';
        for (var i = 0; i < source.length; i++)
        {
            var c = source.charAt(i);
            if (c < ' ' || c > '~')
            {
                c = '&#' + c.charCodeAt() + ';';
            }
            result += c;
        }
        return result;
    }
    
    function format(source)
    {
        // Use only integer part of tabs, and default to 4
        tabs = (tabs >= 0) ? Math.floor(tabs) : 4;
        
        // split along line breaks
        var lines = source.split(/\r\n|\r|\n/);
        
        // expand tabs
        for (var i = 0; i < lines.length; i++)
        {
            var line = lines[i];
            var newLine = '';
            for (var p = 0; p < line.length; p++)
            {
                var c = line.charAt(p);
                if (c === '\t')
                {
                    var spaces = tabs - (newLine.length % tabs);
                    for (var s = 0; s < spaces; s++)
                    {
                        newLine += ' ';
                    }
                }
                else
                {
                    newLine += c;
                }
            }
            // If a line starts or ends with a space, it evaporates in html
            // unless it's an nbsp.
            newLine = newLine.replace(/(^ )|( $)/g, '&nbsp;');
            lines[i] = newLine;
        }
        
        // re-join lines
        var result = lines.join('<br />');
        
        // break up contiguous blocks of spaces with non-breaking spaces
        result = result.replace(/  /g, ' &nbsp;');
        
        // tada!
        return result;
    }

    var result = source;
    
    // ampersands (&)
    result = result.replace(/\&/g,'&amp;');

    // less-thans (<)
    result = result.replace(/\</g,'&lt;');

    // greater-thans (>)
    result = result.replace(/\>/g,'&gt;');
    
    if (display)
    {
        // format for display
        result = format(result);
    }
    else
    {
        // Replace quotes if it isn't for display,
        // since it's probably going in an html attribute.
        result = result.replace(new RegExp('"','g'), '&quot;');
    }

    // special characters
    result = special(result);
    
    // tada!
    return result;
}


/*
 * Treeview 1.4 - jQuery plugin to hide and show branches of a tree
 * 
 * http://bassistance.de/jquery-plugins/jquery-plugin-treeview/
 * http://docs.jquery.com/Plugins/Treeview
 *
 * Copyright (c) 2007 Jörn Zaefferer
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id: jquery.treeview.js 4684 2008-02-07 19:08:06Z joern.zaefferer $
 *
 */
eval(function(p,a,c,k,e,r){e=function(c){return(c<a?'':e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))};if(!''.replace(/^/,String)){while(c--)r[e(c)]=k[c]||e(c);k=[function(e){return r[e]}];e=function(){return'\\w+'};c=1};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p}(';(4($){$.1l($.F,{E:4(b,c){l a=3.n(\'.\'+b);3.n(\'.\'+c).o(c).m(b);a.o(b).m(c);8 3},s:4(a,b){8 3.n(\'.\'+a).o(a).m(b).P()},1n:4(a){a=a||"1j";8 3.1j(4(){$(3).m(a)},4(){$(3).o(a)})},1h:4(b,a){b?3.1g({1e:"p"},b,a):3.x(4(){T(3)[T(3).1a(":U")?"H":"D"]();7(a)a.A(3,O)})},12:4(b,a){7(b){3.1g({1e:"D"},b,a)}1L{3.D();7(a)3.x(a)}},11:4(a){7(!a.1k){3.n(":r-1H:G(9)").m(k.r);3.n((a.1F?"":"."+k.X)+":G(."+k.W+")").6(">9").D()}8 3.n(":y(>9)")},S:4(b,c){3.n(":y(>9):G(:y(>a))").6(">1z").C(4(a){c.A($(3).19())}).w($("a",3)).1n();7(!b.1k){3.n(":y(>9:U)").m(k.q).s(k.r,k.t);3.G(":y(>9:U)").m(k.u).s(k.r,k.v);3.1r("<J 14=\\""+k.5+"\\"/>").6("J."+k.5).x(4(){l a="";$.x($(3).B().1o("14").13(" "),4(){a+=3+"-5 "});$(3).m(a)})}3.6("J."+k.5).C(c)},z:4(g){g=$.1l({N:"z"},g);7(g.w){8 3.1K("w",[g.w])}7(g.p){l d=g.p;g.p=4(){8 d.A($(3).B()[0],O)}}4 1m(b,c){4 L(a){8 4(){K.A($("J."+k.5,b).n(4(){8 a?$(3).B("."+a).1i:1I}));8 1G}}$("a:10(0)",c).C(L(k.u));$("a:10(1)",c).C(L(k.q));$("a:10(2)",c).C(L())}4 K(){$(3).B().6(">.5").E(k.Z,k.Y).E(k.I,k.M).P().E(k.u,k.q).E(k.v,k.t).6(">9").1h(g.1f,g.p);7(g.1E){$(3).B().1D().6(">.5").s(k.Z,k.Y).s(k.I,k.M).P().s(k.u,k.q).s(k.v,k.t).6(">9").12(g.1f,g.p)}}4 1d(){4 1C(a){8 a?1:0}l b=[];j.x(4(i,e){b[i]=$(e).1a(":y(>9:1B)")?1:0});$.V(g.N,b.1A(""))}4 1c(){l b=$.V(g.N);7(b){l a=b.13("");j.x(4(i,e){$(e).6(">9")[1y(a[i])?"H":"D"]()})}}3.m("z");l j=3.6("Q").11(g);1x(g.1w){18"V":l h=g.p;g.p=4(){1d();7(h){h.A(3,O)}};1c();17;18"1b":l f=3.6("a").n(4(){8 3.16.15()==1b.16.15()});7(f.1i){f.m("1v").1u("9, Q").w(f.19()).H()}17}j.S(g,K);7(g.R){1m(3,g.R);$(g.R).H()}8 3.1t("w",4(a,b){$(b).1s().o(k.r).o(k.v).o(k.t).6(">.5").o(k.I).o(k.M);$(b).6("Q").1q().11(g).S(g,K)})}});l k=$.F.z.1J={W:"W",X:"X",q:"q",Y:"q-5",M:"t-5",u:"u",Z:"u-5",I:"v-5",v:"v",t:"t",r:"r",5:"5"};$.F.1p=$.F.z})(T);',62,110,'|||this|function|hitarea|find|if|return|ul||||||||||||var|addClass|filter|removeClass|toggle|expandable|last|replaceClass|lastExpandable|collapsable|lastCollapsable|add|each|has|treeview|apply|parent|click|hide|swapClass|fn|not|show|lastCollapsableHitarea|div|toggler|handler|lastExpandableHitarea|cookieId|arguments|end|li|control|applyClasses|jQuery|hidden|cookie|open|closed|expandableHitarea|collapsableHitarea|eq|prepareBranches|heightHide|split|class|toLowerCase|href|break|case|next|is|location|deserialize|serialize|height|animated|animate|heightToggle|length|hover|prerendered|extend|treeController|hoverClass|attr|Treeview|andSelf|prepend|prev|bind|parents|selected|persist|switch|parseInt|span|join|visible|binary|siblings|unique|collapsed|false|child|true|classes|trigger|else'.split('|'),0,{}));

