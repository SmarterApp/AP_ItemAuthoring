/*
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 */
PXN8 = PXN8 || {};
/**
 * NAMESPACE
 */
PXN8.tools.ui = {};
/**
 * NO-OP function
 */
PXN8.tools.ui.nop = function(){return false;};

/* ===========================================================================
 * BLUR RELATED FUNCTIONS
 */
PXN8.tools.ui.blur = function()
{
    var dom = PXN8.dom;
    
    var radius = dom.id("blurRadius").value;

    if (isNaN(radius) || radius < 1 || radius > 8){
        alert(PXN8.strings.BLUR_RANGE);
        return false;
    }

    var sel = PXN8.getSelection();

    sel.radius = radius;
    
    PXN8.tools.blur(sel);
    
    return true;
};

/*
 * Configure the blur tool panel 
 */
PXN8.tools.ui.config_blur = function(element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.blur;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.blur(); 
        return false;
    };

    dom.cl(dom.id("pxn8_config_title")).appendChild(dom.tx(PXN8.strings.CONFIG_BLUR_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    
    if (configContent == null){
        alert (PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    dom.cl(configContent);

    var form = dom.ac(configContent,dom.ce("form",{onsubmit: function(){PXN8.tools.ui.blur();return false;}}));

    var radiusInput = dom.ce("input",{className: "pxn8_small_field",
                                      type: "text",
                                      id: "blurRadius",value: 2,
                                      name: "blurRadius"});
    
    var table = dom.table([[PXN8.strings.RADIUS_LABEL,radiusInput]],{width: "100%"});
                          
    dom.ac(form,table);

    radiusInput.onfocus = function(){radiusInput.select();};
 
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.ac(dom.cl(helpArea),dom.tx(PXN8.strings.BLUR_PROMPT));
    
    radiusInput.focus();
};

/* ===========================================================================
 * RESIZE RELATED FUNCTIONS
 */

/*
 * Resize the image
 */
PXN8.tools.ui.resize = function()
{
    var dom = PXN8.dom;

    var newWidth = dom.id("resizeWidth").value;
    var newHeight = dom.id("resizeHeight").value;

    if (newWidth == PXN8.image.width &&
        newHeight == PXN8.image.height){
        return false;
    }
    if (isNaN(newWidth) || isNaN(newHeight)){
        alert(PXN8.strings.NUMERIC_WIDTH_HEIGHT);
        return false;
    }
    if (newWidth.match(/[0-9]+/) && newHeight.match(/[0-9]+/)){
        /* OK */
    }else{
        alert(PXN8.strings.NUMERIC_WIDTH_HEIGHT);
        return false;
    }
    if (newWidth > PXN8.resizelimit.width || newHeight > PXN8.resizelimit.height){
        alert(PXN8.strings.LIMIT_SIZE + PXN8.resizelimit.width + "x" + PXN8.resizelimit.height);
        return false;
    }
    PXN8.unselect();
    PXN8.tools.resize(newWidth,newHeight);

    return true;
};
/**
 *
 */
PXN8.tools.ui.config_resize = function(element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.resize;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.resize(); 
        return false;
    };

    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_RESIZE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    dom.cl(configContent);
    
	 var form = dom.ac(configContent,dom.ce("form"));
    form.onsubmit = function(){ 
        PXN8.tools.ui.resize(); 
        return false;
    };

    var preserveRatioCheckbox = dom.ce("input",{type: "checkbox", 
                                                id: "preserve", 
                                                value: true, 
                                                defaultChecked: true});
	 preserveRatioCheckbox.onclick = function(){ 
        preserveRatio(preserveRatioCheckbox);
    };
    
    var iwidth = dom.ce("input",{className: "pxn8_small_field", 
                                 type: "text", 
                                 value: PXN8.image.width,
                                 id: "resizeWidth", 
                                 name: "resizeWidth"});
    iwidth.onfocus = function (){ 
        iwidth.select();
    };
    iwidth.onblur = function(){ 
        changeDim('width');
    };
    var iheight  = dom.ce("input",{className: "pxn8_small_field", 
                                   type: "text", 
                                   value: PXN8.image.height,
                                   id: "resizeHeight", 
                                   name: "resizeHeight"});
    iheight.onfocus = function (){ 
        iheight.select();
    };
    iheight.onblur = function(){ 
        changeDim('height');
    };
    
    var resizeToSelectedArea = dom.ce("a",{href: "javascript:void(0)"});
    dom.ac(resizeToSelectedArea,dom.tx(PXN8.strings.RESIZE_SELECT_LABEL ));
    resizeToSelectedArea.onclick = function(){
        var sel = PXN8.getSelection();
        if (sel.width <= 0 || sel.height <= 0){
            PXN8.show.alert(PXN8.strings.RESIZE_SELECT_AREA);
            return false;
        }
        PXN8.unselect();
        PXN8.tools.resize(sel.width,sel.height);
        return false;
    };
    
    var table = dom.table([[PXN8.strings.ASPECT_LABEL, preserveRatioCheckbox],
                           [PXN8.strings.WIDTH_LABEL,  iwidth],
                           [PXN8.strings.HEIGHT_LABEL, iheight],
                           [resizeToSelectedArea] ]);
    dom.ac(form,table);
    
    iwidth.focus();

    /**
     * default to 75% of image size
     */
    PXN8.sx = 0;
    PXN8.sy = 0;
    PXN8.ex = PXN8.image.width * 0.75;
    PXN8.ey = PXN8.image.height * 0.75;
    PXN8.selectArea();

    iwidth.setAttribute('value', PXN8.image.width);
    iheight.setAttribute('value', PXN8.image.height);
    
};

/**
 * Change the brightness, hue and saturation
 */
PXN8.tools.ui.bsh = function()
{ 

    var dom = PXN8.dom;

    var bright = dom.id("brightness");
    var sat = dom.id("saturation");
    var h = dom.id("hue");
    var contrast = dom.id("contrast");
    var contrastValue = contrast.options[contrast.selectedIndex];
    
        
    if (isNaN(bright.value) || bright.value < 0 || bright.value.match(/\S+/) == null){
        alert(PXN8.strings.BRIGHTNESS_RANGE);
        return false;
    }
    if (isNaN(h.value) || h.value < 0 || h.value > 200 || h.value.match(/\S+/) == null){
      alert (PXN8.strings.HUE_RANGE);
      return false;
    }
    if (isNaN(sat.value) || sat.value < 0 || sat.value.match(/\S+/) == null){
        alert(PXN8.strings.SATURATION_RANGE);
        return false;
    }
    
    if (bright.value == 100 && h.value == 100 && sat.value == 100 && contrastValue.value == 0){
        return false;
    }

    PXN8.tools.colors ({brightness: bright.value,
                        hue: h.value,
                        saturation: sat.value, 
                        contrast: contrastValue.value});
    return true;
   
};


/*
 * ----------------------------------------------------------------
 * Setup the Tool configuration panel for Brightness/Hue/Saturation
 * ----------------------------------------------------------------
 */
PXN8.tools.ui.config_bsh = function(element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.bsh;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.bsh(); 
        return false;
    };
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    
    dom.cl(dom.id("pxn8_config_title")).appendChild(dom.tx(PXN8.strings.CONFIG_COLOR_TOOL));

    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert (PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var form = dom.ac(dom.cl(configContent),dom.ce("form",{onsubmit: function(){
        PXN8.tools.ui.bsh();
        return false;
    }}));

    /**
     * Construct a slider control to control the brightness
     */
    var brdiv = dom.ce("div");
    // make it a slide 
    PXN8.slide.bind(brdiv,'brightness',0,200,100);
    dom.ac(brdiv,dom.tx(PXN8.strings.BRIGHTNESS_LABEL));
    
    var brdiv2 =   dom.ce("input",{className: "pxn8_slidervalue", 
                                   type: "text", 
                                   name: "brightness", 
                                   id: "brightness", value: 100});
    /**
     * Construct a slider control to control the saturation
     */
    var satdiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(satdiv,'saturation',0,200,100);
    dom.ac(satdiv,dom.tx(PXN8.strings.SATURATION_LABEL));

    var sat2 = dom.ce("input",{className: "pxn8_slidervalue", 
                               type: "text", 
                               name: "saturation", 
                               onkeypress: brdiv2.onkeypress,
                               id: "saturation", 
                               value: 100});

    /**
     * Construct a slider control to control the HUE
     */
    var huediv =  dom.ce("div");
    // make it a slide
    PXN8.slide.bind(huediv,'hue',0,200,100);
    
    dom.ac(huediv,dom.tx(PXN8.strings.HUE_LABEL));

    var hue2 = dom.ce("input",{className: "pxn8_slidervalue", 
                               type: "text", 
                               name: "hue", 
                               onkeypress: brdiv2.onkeypress,
                               id: "hue", 
                               value: 100});
    /**
     * Construct a 'contrast' dropdown combobox
     */
    var sel = dom.ce("select",{name: "contrast", 
                               id: "contrast",
                               onkeypress: brdiv2.onkeypress });
    var options = {"-3": "-3", "-2": "-2", "-1": "-1", "0": PXN8.strings.CONTRAST_NORMAL, "1": "+1", "2": "+2", "3": "+3"};
    var j  = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i],i);
    }
    sel.selectedIndex = 3;

    var table = dom.table([[ brdiv,     brdiv2,   "%"],
                           [ satdiv,    sat2,     "%"],
                           [ huediv,    hue2,     "%"],
                           [ PXN8.strings.CONTRAST_LABEL, sel]],{width: "90%"});
    dom.ac(form,table);
    
    var cells = table.getElementsByTagName("td");
    for (var i = 0 ; i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }
    
    var br = dom.id("brightness");
    br.focus();
    br.select();
};

/*
 * -------------------------------------------------------------------------
 * CROP RELATED FUNCTIONS
 * -------------------------------------------------------------------------
 */

/*
 * perform crop operation
 */
PXN8.tools.ui.crop = function()
{
    var dom = PXN8.dom;

    var sel = PXN8.getSelection();
    
    if (sel.width <= 0 || sel.height <= 0){
        PXN8.show.alert(PXN8.strings.CROP_SELECT_AREA);
        return false;
    }
    
    PXN8.tools.crop(sel);
    
    PXN8.unselect();
    
    PXN8.aspectRatio.width = 0;
    PXN8.aspectRatio.height = 0;
    
    return true;
};

/*
 * Configure the Crop tool panel
 */
PXN8.tools.ui.config_crop = function(element,event)
{  
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.crop(); 
        return false;
    };
    

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,function(){
        /* change the aspect ratio back to 'free select' */
        PXN8.aspectRatio.width = 0;
        PXN8.aspectRatio.height = 0;
        return false;
    });
    
        
    
    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_CROP_TOOL));

    var configContent = dom.id("pxn8_config_content");

    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    
    var theImg = dom.id("pxn8_image");
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));


    var form = dom.ac(dom.cl(configContent),dom.ce("form"));

    form.onsubmit =  function(){ 
        PXN8.tools.ui.crop(); 
        return false;
    };

    var sel = dom.ce("select",{id: "aspect_ratio", name: "aspect_ratio"});
    sel.onchange = function() {
        changeAspectRatio();
    };
    var options = {"free": PXN8.strings.CROP_FREE,
                   "1x1" : PXN8.strings.CROP_SQUARE,
                   "4x6" : "4x6",
                   "5x7" : "5x7",
                   "8x10": "8x10",
                   "6x8" : "6x8"};
    var j = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i],i);
    }   
    /**
     * Portrait orientation
     */
    var op = dom.ce("div",{className: "pxn8_checked", id: "portrait"});
    op.onclick = function(){ 
        changeOrientation(PXN8.PORTRAIT);
        op.className = "pxn8_checked";
        var ol = dom.id("landscape");
        ol.className = "pxn8_unchecked";
    };
    op.style.cursor = "pointer";
    dom.ac(op,dom.tx(PXN8.strings.ORIENTATION_PORTRAIT));
    /**
     * Landscape orientation
     */ 
    var ol = dom.ce("div",{className: "pxn8_unchecked", id: "landscape"});
    ol.onclick = function(){ 
        changeOrientation(PXN8.LANDSCAPE);
        ol.className = "pxn8_checked";
        var op = dom.id("portrait");
        op.className = "pxn8_unchecked";
   
    };
    ol.style.cursor = "pointer";
    dom.ac(ol,dom.tx(PXN8.strings.ORIENTATION_LANDSCAPE));

    /**
     * Preview Crop link
     */
    var prevCropLink = dom.ce("a",{href: "javascript:void(0);",onclick: previewCrop});
    dom.ac(prevCropLink,dom.tx("preview"));

    var table = dom.table([
                           [PXN8.strings.ASPECT_CROP_LABEL, sel],
                           [PXN8.strings.ORIENTATION_LABEL, op],
                           ["",                             ol],
                           [prevCropLink                      ]],
        {width: "100%"});

    dom.ac(form,table);
    
    sel.focus();

    /**
     * Setup initial orientaition radio selection
     */
    var portrait = dom.id("portrait");
    var landscape = dom.id("landscape");

    if (theImg.height > theImg.width){
        portrait.className = "pxn8_checked";
        landscape.className = "pxn8_unchecked";
        changeOrientation(PXN8.PORTRAIT);
    }else{
        portrait.className = "pxn8_unchecked";
        landscape.className = "pxn8_checked";
        changeOrientation(PXN8.LANDSCAPE);
    }    

};

/*
 * Called during crop tool configuration  and when the orientation
 * radiobox is clicked
 */
function changeOrientation(orientation,width,height)
{
    PXN8.orientation = orientation;
	 if (width != null){
        changeAspectRatio(width,height);
    }else{
        changeAspectRatio();
    }
};

/*
 * Called when the user chooses a value from the aspect ratio dropdown
 * and also called when the orientation (portrait,landscape) has changed.
 */
function changeAspectRatio(width,height)
{
    var dom = PXN8.dom;

    if (width != null){
        PXN8.aspectRatio.width = width;
        PXN8.aspectRatio.height = height;
    }else{
        var aspectRatio = dom.id("aspect_ratio");
        if (aspectRatio != null){
            
            var selected = aspectRatio.options[aspectRatio.selectedIndex];
            var pair = /^([0-9]+)x([0-9]+)/;
            var match = selected.value.match(pair);
            if (match != null){
                if (PXN8.orientation == PXN8.LANDSCAPE){
                    PXN8.aspectRatio.width = match[2];
                    PXN8.aspectRatio.height = match[1];
                }else{
                    PXN8.aspectRatio.width = match[1];
                    PXN8.aspectRatio.height = match[2];
                }
            }else{
                PXN8.aspectRatio.width = 0;
                PXN8.aspectRatio.height = 0;
                return;
            }
        }
    }
    if (PXN8.aspectRatio.width == 0 &&
        PXN8.aspectRatio.height == 0){
        return;
    }

    var topRect = dom.id("pxn8_top_rect");
    topRect.style.borderWidth = "1px";
    
    var leftRect = dom.id("pxn8_left_rect");
    leftRect.style.borderWidth = "0px";
            
    PXN8.sx = 0;
    PXN8.sy = 0;
    
    var t1 = PXN8.image.width / PXN8.aspectRatio.width ;
    var t2 = PXN8.image.height / PXN8.aspectRatio.height ;
    if (t2 < t1){
        PXN8.ey = PXN8.image.height;
        PXN8.ex = Math.round(PXN8.ey / PXN8.aspectRatio.height * PXN8.aspectRatio.width);
    }else{
        PXN8.ex = PXN8.image.width;
        PXN8.ey = Math.round(PXN8.ex / PXN8.aspectRatio.width * PXN8.aspectRatio.height);
    }
    PXN8.sx = Math.round((PXN8.image.width - PXN8.ex) / 2);
    PXN8.sy = Math.round((PXN8.image.height - PXN8.ey) / 2);
    PXN8.ex += PXN8.sx;
    PXN8.ey += PXN8.sy;
    
    PXN8.selectArea();
};
/* ===========================================================================
 * FILTER RELATED FUNCTIONS
 * ===========================================================================
 */

/*
 * Add a lens filter to the image
 */
PXN8.tools.ui.filter = function(x,y)
{
    var dom = PXN8.dom;

    var applyBtn  = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    
    PXN8.tools.filter({"top": y,
                       "color": dom.id("filter_color").value,
                       "opacity" : dom.id("filter_opacity").value }
                      );
    return true;
};

/*
 *
 */
PXN8.tools.ui.config_filter = function (element, event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    
    applyBtn.style.display = "none";
    
    var canvas = dom.id("pxn8_canvas");
    var oldonmousedown = canvas.onmousedown;
    
    var onImageUpdated = null;
    onImageUpdated = function(){
        applyBtn.style.display = "inline";
        var pin1 = dom.id("left_pin");
        if (pin1){
            pin1.style.display = "none";
        }
        canvas.onmousedown = oldonmousedown;
    };
    PXN8.listener.onceOnly(PXN8.ON_IMAGE_CHANGE,onImageUpdated);
   

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,onImageUpdated);
    
    var configTitle = dom.cl(dom.id("pxn8_config_title"));
	 dom.ac(configTitle,dom.tx(PXN8.strings.CONFIG_FILTER_TOOL));

    PXN8.unselect();
    var configContent = dom.id("pxn8_config_content");

    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }
    var colorInput = dom.ce("input",{name: "filter_color", 
                                     className: "pxn8_small_field", 
                                     id: "filter_color",
                                     value: "#FFA500"
    });
    var table = PXN8.colors.picker("#FFA500",function(color){
        colorInput.value = color;
    });
    
	 dom.ac(dom.cl(configContent),table);

    /**
     * Construct a slider control to control opacity
     */
    var opacitySliderDiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opacitySliderDiv,'filter_opacity',0,100,100);
    dom.ac(opacitySliderDiv,dom.tx(PXN8.strings.OPACITY_LABEL));

    var opacityInput = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type: "text", 
         name: "filter_opacity", 
         id: "filter_opacity", 
         value: 100});

    var table2 = dom.table([
                            [PXN8.strings.COLOR_LABEL, colorInput],
                            [opacitySliderDiv,         opacityInput]
                            ]);

    dom.ac(configContent,table2);

    var cells = table2.getElementsByTagName("td");
    for (var i = 0;i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }
    
    dom.ac(dom.cl(dom.id("pxn8_tool_prompt")),dom.tx(PXN8.strings.FILTER_PROMPT));
    
    var newonmousedown = function(event){

        if (!event) event = window.event;
        var cursorPos = PXN8.dom.cursorPos(event);
   
        var imagePoint = PXN8.mousePointToElementPoint(cursorPos.x,cursorPos.y);

        canvas.onmousedown = oldonmousedown;
        // show pin 
        var pin1 = dom.id("left_pin");
        if (pin1 == null){
            pin1 = PXN8.createPin("left_pin", PXN8.root + "/images/bluepin.gif");
            document.body.appendChild(pin1);
        }
        
        pin1.style.display = "block";
        pin1.style.left = "" + (cursorPos.x -7) + "px";
        pin1.style.top = "" + (cursorPos.y - 24) + "px";
        
        PXN8.tools.ui.filter(imagePoint.x,imagePoint.y);
        return true;
    };
    canvas.onmousedown = newonmousedown;
    
};

/* ===========================================================================
 * INTERLACE RELATED FUNCTIONS
 * ===========================================================================
 */


/*
 * Setup the configuration panel for the interlace effect
 */
PXN8.tools.ui.config_interlace = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.interlace;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.interlace(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_INTERLACE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var interlaceColor = dom.ce("input",{name: "interlace_color", 
                                         className: "pxn8_small_field", 
                                         id: "interlace_color",
                                         value: "#000000"
    });
    

    var picker = PXN8.colors.picker("#000000",function(color){
        interlaceColor.value = color;
    });
    
    dom.ac(dom.cl(configContent),picker);

    /**
     * Construct a slider control to control opacity
     */
    var opacitySliderDiv = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opacitySliderDiv,'interlace_opacity',0,100,20);
    dom.ac(opacitySliderDiv,dom.tx(PXN8.strings.OPACITY_LABEL));

    var opacityInput = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type: "text", 
         name: "interlace_opacity", 
         id: "interlace_opacity", 
         value: 20});

    dom.ac(configContent,
           dom.table([
                      [PXN8.strings.COLOR_LABEL,interlaceColor],
                      [opacitySliderDiv,        opacityInput]],
           {width: "100%"}));
    
    
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.cl(helpArea);
    helpArea.appendChild(dom.tx(PXN8.strings.INTERLACE_PROMPT));
    
    opacityInput.focus();

};

/*
 * Add an interlace effect to the image
 */
PXN8.tools.ui.interlace = function()
{
    
    var dom = PXN8.dom;

    var lineColor = dom.id("interlace_color").value;
    if (lineColor.match(/#[a-fA-F0-9]{6}/)){
        /* it's OK */
    }else{
        alert(PXN8.strings.INVALID_HEX_VALUE);
        return false;
    }
    var sel = PXN8.getSelection();
    var opacityVal = dom.id("interlace_opacity").value;

    sel.opacity = opacityVal;
    sel.color = lineColor;
    
    PXN8.tools.interlace(sel);
        
    return true;
};

/* ===========================================================================
 * LOMO RELATED FUNCTIONS
 * ===========================================================================
 */
/* 
 * Configure the lomo tool panel
 */
PXN8.tools.ui.config_lomo = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.lomo(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_LOMO_TOOL));
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));
    helpArea.appendChild(dom.tx(PXN8.strings.OPACITY_PROMPT));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

	 dom.cl(configContent);
	var form = dom.ce("form",{name: "lomoform"});
	configContent.appendChild(form);    
    //var form = dom.ac(dom.cl(configContent),dom.ce("form",{name: "lomoform"}));
	
    form.onsubmit = function(){
        PXN8.tools.ui.lomo();
        return false;
    };

    /**
     * Construct a slider control to control opacity
     */
	 var opslide = dom.ce("div");
    // make it a slide
    PXN8.slide.bind(opslide,'opacity',0,100,60);
	 var opacity_label = dom.tx(PXN8.strings.OPACITY_LABEL);
	 opslide.appendChild(opacity_label);
    //dom.ac(opslide,);

    var opacityField = dom.ce("input",
        {className: "pxn8_slidervalue", 
         type:"text", 
         name:"opacity", 
         id:"opacity", 
         value:60});

    var saturateCheckbox = dom.ce("input",
        {type:"checkbox",
         name: "saturate", 
         defaultChecked: true, 
         id:"saturate"});

    var table = dom.table([[opslide,                     [opacityField,"%"]],
                           [PXN8.strings.SATURATE_LABEL, saturateCheckbox]
                           ],{width: "100%"});



	 form.appendChild(table);
    //dom.ac(form,table);
    var cells = table.getElementsByTagName("td");
    for (var i = 0; i < cells.length; i++){
        cells[i].vAlign = "bottom";
    }

    opacityField.focus();
	
};


/*
 * Add a lomo effect to the image
 */
PXN8.tools.ui.lomo = function()
{
    var dom = PXN8.dom;

    var opacity = dom.id("opacity");
    var saturate = dom.id("saturate");
    
    if (isNaN(opacity.value) || opacity.value <0 || opacity.value > 100){
        alert(PXN8.strings.OPACITY_RANGE);
        return false;
    }
    
    PXN8.tools.lomo({ "opacity": opacity.value, "saturate": saturate.checked });
    
    return true;
};


/*
 * whiten teeth
 */
PXN8.tools.ui.whiten = function()
{
    
    var selection = PXN8.getSelection();
    if (selection.width == 0 || selection.height == 0){
        PXN8.show.alert(PXN8.strings.WHITEN_SELECT_AREA);
        return false;
    } 
    
    if (selection.width * selection.height > 16000){
        PXN8.show.alert (PXN8.strings.SELECT_SMALLER_AREA);
        return false;
    } 
    
    PXN8.tools.whiten(selection);
    
    
    return true;
};


/*
 * -------------------------------------------------------------------------
 * RED EYE RELATED FUNCTIONS
 * -------------------------------------------------------------------------
 */
/*
 * Fix red eye 
 */
PXN8.tools.ui.redeye = function ()
{
    var selection = PXN8.getSelection();
    if (selection.width == 0 || selection.height == 0){
        alert(PXN8.strings.REDEYE_SELECT_AREA);
        return false;
    } 
    if (selection.width > 100 || selection.height > 100){
        alert (PXN8.strings.REDEYE_SMALLER_AREA);
        return false;
    } 

    PXN8.tools.fixredeye(selection);
    
    PXN8.aspectRatio.width = 0;
    PXN8.aspectRatio.height = 0;

    PXN8.unselect();
    return true;
};

/*
 * Configure the red eye tool panel
 */
PXN8.tools.ui.config_redeye = function (element,event)
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.redeye;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.redeye(); 
        return false;
    };

    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,function(){
        PXN8.aspectRatio.width = 0;
        PXN8.aspectRatio.height = 0;
    });
    
                           

    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_REDEYE_TOOL));
    
    var configContent = dom.id("pxn8_config_content");
    if (configContent == null){
        alert(PXN8.strings.NO_CONFIG_CONTENT);
        return false;
    }

    var table = dom.table([[PXN8.strings.REDEYE_PROMPT]],{width: "100%"});
    dom.ac(dom.cl(configContent),table);
    
    dom.cl(dom.id("pxn8_tool_prompt"));
    
    PXN8.aspectRatio.width = 1;
    PXN8.aspectRatio.height = 1;
};


/*
 *  handler for when the 'preserve ratio' button is clicked
 */
function preserveRatio(element){
   if (element.checked){
       matchHeightToWidth();
   }
   return true;
}

/*
 *
 */
function matchHeightToWidth(){

    var dom = PXN8.dom;

    var width = dom.id("resizeWidth").value;
    var heightInput = dom.id("resizeHeight");
    
    var expr = /^([0-9]+)(%*)$/;
    var match = width.match(expr);
    if (match != null){
        if (match[2] == '%'){
            heightInput.value = Math.round(PXN8.image.height *  (match[1] / 100));
        }else{
            heightInput.value = Math.round(PXN8.image.height * (width / PXN8.image.width));
        }
    }
}
/*
 *
 */
function matchWidthToHeight(){
    var dom = PXN8.dom;

    var height = dom.id("resizeHeight").value;
    var widthInput = dom.id("resizeWidth");
    
    var expr = /^([0-9]+)(%*)$/;
    var match = height.match(expr);
    if (match != null){
        if (match[2] == '%'){
            widthInput.value = Math.round(PXN8.image.width *  (match[1] / 100));
        }else{
            widthInput.value = Math.round(PXN8.image.width * (height / PXN8.image.height));
        }
    }
}
/*
 *
 */
function changeDim(axis){
    var dom = PXN8.dom;

    var preserve = dom.id("preserve");
    if (preserve.checked){
        if (axis == 'width'){
            matchHeightToWidth();
        }else{
            matchWidthToHeight();
        }
    }
    return true;
};

/* ===========================================================================
 * ROTATE RELATED FUNCTIONS
 */

/*
 *
 */
PXN8.tools.ui.rotate = function ()
{
    var dom = PXN8.dom;

    var angleCombo = dom.id("angle");
    var angle = angleCombo.options[angleCombo.selectedIndex].value;
    var flipVt = dom.id("flipvt").checked;
    var flipHz = dom.id("fliphz").checked;
    
    if (angle == 0 &&
        flipVt == false &&
        flipHz == false ){
        alert(PXN8.strings.PROMPT_ROTATE_CHOICE);
        return false;
    }

    PXN8.tools.rotate({"angle": angle, 
                       "flipvt": flipVt, 
                       "fliphz": flipHz});
    
    return false;
};

/*
 * ROTATE IMAGE
 */
PXN8.tools.ui.config_rotate = function (element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.rotate;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.rotate(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_ROTATE_TOOL));
    
    PXN8.unselect();
    var configContent = dom.cl(dom.id("pxn8_config_content"));
    
    var helpArea = dom.cl(dom.id("pxn8_tool_prompt"));
    
    var form = dom.ac(configContent, dom.ce("form"));
    form.onsubmit =  function(){ 
        PXN8.tools.ui.rotate(); 
        return false;
    };

	 var flipvt = dom.ce("input", {type: "checkbox",
                                  name:"flipvt",
                                  id:"flipvt"});

    var fliphz = dom.ce("input", {type: "checkbox", 
                                  name: "fliphz", 
                                  id: "fliphz"});

    var sel = dom.ce("select",{name: "angle", 
                               id: "angle", 
                               className: "pxn8_small_field"});
    
    var options = {"0": "   ", "90": "90", "180": "180", "270": "270  "};
    var j = 0;
    for (var i in options){
        sel.options[j++] = new Option(options[i], i);
    }

    var table = dom.table([[PXN8.strings.FLIPVT_LABEL, flipvt],
                           [PXN8.strings.FLIPHZ_LABEL, fliphz],
                           [PXN8.strings.ANGLE_LABEL,  sel ]
                           ], 
        {width: "100%"});
    

	dom.ac(form,table);
    flipvt.focus();
};


/*
 * Called when the user clicks the 'spirit-level' checkbox
 */
function spiritlevelmode ()
{
    var dom = PXN8.dom;
    
    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "none";
    
    var oldOnImageUpdated = PXN8.onImageUpdated;
    
    var tidyup = function(){
		
        var dom = PXN8.dom;

        var blackout= dom.id("blackout");
        if (blackout){
            document.body.removeChild(blackout);
        }
        var prompt = dom.id("prompt");
        if (prompt){
            document.body.removeChild(prompt);
        }
        /**
         * muy importante !
         */
        PXN8.initializeCanvas();
        /**
         * ^^^^^^^^^^^^^^^
         */
        var pin1 = dom.id("left_pin");
        if (pin1){
            pin1.style.display = "none";
        }
        var pin2 = dom.id("right_pin");
        if (pin2){
            pin2.style.display = "none";
        }
        
    };
   
    var cancelBtn = dom.id("pxn8_cancel");
    PXN8.dom.onceOnlyClickEvent(cancelBtn,tidyup);
    
    var onImageUpdated = null;
    
    PXN8.listener.onceOnly(PXN8.ON_IMAGE_CHANGE,tidyup);
    
    var blackout = document.createElement("div");
    blackout.id = "blackout";
    
    var imgBounds = dom.eb(dom.id("pxn8_image"));
    PXN8.unselect();
    blackout.style.position = "absolute";
    blackout.style.backgroundColor = "black";
    dom.opacity(blackout,0.7);
    
    blackout.style.top = imgBounds.y + "px";
    blackout.style.left = imgBounds.x + (imgBounds.width/2) + "px";
    blackout.style.width = (imgBounds.width/2)+"px";
    blackout.style.height = imgBounds.height + "px";
    document.body.appendChild(blackout);

    var prompt = document.createElement("div");
    prompt.id = "prompt";
    prompt.style.position = "absolute";
    prompt.style.backgroundColor = "white";
    prompt.style.padding = "4px";
        
    prompt.style.top = imgBounds.y + 10 + "px";
    prompt.style.left = imgBounds.x + 10 + "px";
    prompt.style.width = (imgBounds.width/2)- 20 + "px";
    prompt.style.overflow = "auto";
        
    dom.ac(dom.cl(prompt),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT1));
        
    document.body.appendChild(prompt);
        

    var configContent = dom.id("pxn8_config_content");
    dom.ac(dom.cl(configContent),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT1));
    
    dom.ac(dom.cl(dom.id("pxn8_config_title")),dom.tx(PXN8.strings.CONFIG_SPIRITLVL_TOOL));
    
    var instructionIndex = 0;
    var points = { left: {x: 0, y: 0},
                   right: {x: 0, y: 0}};
        
    dom.cl(dom.id("pxn8_tool_prompt"));

    var canvas = dom.id("pxn8_canvas");
    canvas.onmousedown = function (event){
        var dom = PXN8.dom;

        event = (event)?event:window.event;
        dom.ac(dom.cl(configContent),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT2));
            
        // show pin 
        var pin1 = dom.id("left_pin");
        if (pin1 == null){
            pin1 = PXN8.createPin("left_pin",PXN8.root + "/images/bluepin.gif");
            document.body.appendChild(pin1);
        }
        
        pin1.style.display = "block";
        var cursorPos = PXN8.dom.cursorPos(event);
        pin1.style.left = "" + (cursorPos.x -7) + "px";
        pin1.style.top = "" + (cursorPos.y - 24) + "px";
        
        points.left.x = PXN8.position.x;
        points.left.y = PXN8.position.y;

        blackout.style.left = imgBounds.x + "px";

        prompt.style.left = (imgBounds.x + (imgBounds.width/2)) + 10 + "px";
        dom.ac(dom.cl(prompt),dom.tx(PXN8.strings.SPIRIT_LEVEL_PROMPT2));

        canvas.onmousedown = function (event){
            var dom = PXN8.dom;

            event = (event)?event:window.event;
                
            points.right.x = PXN8.position.x;
            points.right.y = PXN8.position.y;
            // show pin 
            var pin2 = dom.id("right_pin");
            if (pin2 == null){
                pin2 = PXN8.createPin("right_pin",PXN8.root + "/images/redpin.gif");
                document.body.appendChild(pin2);
            }
            pin2.style.display = "block";
            var cursorPos = PXN8.dom.cursorPos(event); 
            pin2.style.left = "" + (cursorPos.x -7) + "px";
            pin2.style.top = "" + (cursorPos.y - 24) + "px";
                
            PXN8.initializeCanvas();

            var blackout= dom.id("blackout");
            if (blackout){
                document.body.removeChild(blackout);
            }
            var prompt = dom.id("prompt");
            if (prompt){
                document.body.removeChild(prompt);
            }

            PXN8.tools.spiritlevel(points.left.x,
                                   points.left.y,
                                   points.right.x,
                                   points.right.y);
                
        };

    };
}


/* ===========================================================================
 * ROUNDED_CORNERS RELATED FUNCTIONS
 * ===========================================================================
 */

/*
 * Configure the rounded-corners tool panel
 */
PXN8.tools.ui.config_roundedcorners = function(element,event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
    //applyBtn.onclick = PXN8.tools.ui.roundedcorners;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.roundedcorners(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_ROUNDED_TOOL));
    
    
    var helpArea = dom.id("pxn8_tool_prompt");
    dom.cl(helpArea);
    
    var configContent = dom.id("pxn8_config_content");
    
    dom.cl(configContent);
    var colorInput = dom.ce("input",{name: "corner_color", 
                                     className: "pxn8_small_field", 
                                     id: "corner_color",
                                     value: "#FFFFFF"
    });
    
    var picker = PXN8.colors.picker("#FFFFFF",function(color){
        colorInput.value = color;
    });
    
    configContent.appendChild(picker);
    
    var input = dom.ce("input", {className: "pxn8_small_field", 
                                 type: "text", 
                                 name: "radius",
                                 id: "radius",
                                 value: "32"});

    var table = dom.table([[PXN8.strings.COLOR_LABEL, colorInput],
                           [PXN8.strings.RADIUS_LABEL, input]]);

    dom.ac(configContent,table);
    
    colorInput.focus();

};

/*
 * Add rounded corners to the image
 */
PXN8.tools.ui.roundedcorners = function ()
{
    var dom = PXN8.dom;

    var color = dom.id("corner_color");
    var radius = dom.id("radius");
    
    PXN8.tools.roundedcorners(color.value, radius.value);
    
    return true;
};

/*
 * Make the image sepia tone or black&white
 */
PXN8.tools.ui.sepia = function()
{
    var dom = PXN8.dom;

   /*
    * n.b. the order in which the grayscale/sepia elements are declared is important.
    * for the following line to work since it uses an index - not a name (can't use 
    * name because they're radio buttons )
    */
   //var operation = document.forms["sepia"].elements[1].checked?"grayscale":"sepia";

    var operation = "sepia";
    var gs = dom.id("gs");
    if (gs.className == "pxn8_checked"){
        operation = "grayscale";
    }
    
    if (operation == "sepia"){
        PXN8.tools.sepia(dom.id("sepia_color").value);
    }else{
        PXN8.tools.grayscale();
    }
    
    return true;
};

/* ===========================================================================
 * SEPIA + B&W RELATED FUNCTIONS
 * ===========================================================================
 */


/*
 * Configure the sepia/black & white tool panel
 */
PXN8.tools.ui.config_sepia = function(element, event)
{
    var dom = PXN8.dom;

    var applyBtn = dom.id("pxn8_apply");
    applyBtn.style.display = "inline";
   
    //applyBtn.onclick = sepiaTone;
    //         
    // apply   button is a link and therefore it's onclick
    // must return false to work correctly in IE
    //
    applyBtn.onclick = function(){ 
        PXN8.tools.ui.sepia(); 
        return false;
    };

    var configTitle = dom.cl(dom.id("pxn8_config_title"));
    configTitle.appendChild(dom.tx(PXN8.strings.CONFIG_BW_TOOL));
    
    var configContent = dom.cl(dom.id("pxn8_config_content"));

    var colorInput = dom.ce("input",{name: "sepia_color", 
                                     className: "pxn8_small_field", 
                                     id: "sepia_color",
                                     value: "#A28A65"
    });
    
    var picker = PXN8.colors.picker("#A28A65",function(color){
        colorInput.value = color;
    });

    dom.ac(dom.cl(configContent),picker);

    dom.ac(configContent,
           dom.table([[PXN8.strings.COLOR_LABEL, colorInput]],{width: "100%"}));
    
    var form2 = dom.ac(configContent,dom.ce("form", {name: "sepia"}));

    form2.onsubmit = function(){ 
        PXN8.tools.ui.sepia(); 
        return false;
    };
    /**
     * Sepia radio button
     */
    var d1 = dom.ce("div",{className:"pxn8_checked", id: "sep"});
    dom.ac(d1,dom.tx(PXN8.strings.SEPIA_LABEL));

    d1.onclick = function(){
        var dom = PXN8.dom;

        d1.className = "pxn8_checked";
        var gs = dom.id("gs");
        gs.className = "pxn8_unchecked";
        dom.opacity(picker,1.0);
    };
    d1.style.cursor = "pointer";
    /**
     * Grayscale radio button
     */
    var d2 = dom.ce("div",{className:"pxn8_unchecked", id: "gs"});
    dom.ac(d2,dom.tx(PXN8.strings.GRAYSCALE_LABEL));
    d2.onclick = function(){
        var dom = PXN8.dom;
        d2.className = "pxn8_checked";
        var sep = dom.id("sep");
        sep.className = "pxn8_unchecked";
        dom.opacity(picker,0.5);
        return true;
    };
    d2.style.cursor = "pointer";

    var table = dom.table([[d1],
                           [d2]],
        {width: "100%"});

    dom.ac(form2,table);
    
    dom.ac(dom.cl(dom.id("pxn8_tool_prompt")),dom.tx(PXN8.strings.BW_PROMPT));
    
    var cf = dom.id("sepia_color");
    cf.focus();
};


function restoreAfterPreview()
{
    var dom = PXN8.dom;
    var rects = ["left","right","top","bottom"];
    for (var i  = 0;i < rects.length; i++){
        var rect = dom.id("pxn8_" + rects[i] + "_rect");
        rect.style.backgroundColor = PXN8.style.notSelected.color;
        dom.opacity(rect,PXN8.style.notSelected.opacity);
    }
    for (var i in PXN8.resize.handles){
        var handle = dom.id( i + "_handle");
        dom.opacity(handle,1.00);
    }

};
/**
 * A nice feature to have: preview a crop operation before doing it.
 */
function previewCrop()
{
    var dom = PXN8.dom;
    var rects = ["left","right","top","bottom"];
    for (var i  = 0;i < rects.length; i++){
        var rect = dom.id("pxn8_" + rects[i] + "_rect");
        rect.style.backgroundColor = "white";
        dom.opacity(rect,1.00);
    }
    for (var i in PXN8.resize.handles){
        var handle = dom.id( i + "_handle");
        dom.opacity(handle,0);
    }
    
    setTimeout(restoreAfterPreview,3500);
};
