/* ============================================================================
 *
 * (c) 2005-2006 Sxoop Technologies Ltd. All rights reserved.
 *
 * For support contact support@sxoop.com
 *
 * These function handle sliders as used by some of the 
 * tool configuration panels.
 */
var PXN8 = PXN8 || {};
PXN8.slide = {};
/**
 * Turn a regular HTML div element into a slide
 */
PXN8.slide.bind = function(slideElement,inputElementId,startRange,rangeSize,initValue)
{
    slideElement.className = "pxn8_slide";
    slideElement.onmousedown = function(event){
        if (!event) event = window.event;
        PXN8.slide.onmousedown(slideElement,event,inputElementId,startRange,rangeSize);
    };
    var slider = document.createElement("span");
    slider.className = "pxn8_slider";
    slideElement.appendChild(slider);
    slider.style.left = (3 + (((initValue-startRange) / rangeSize) * 117)) + "px";
    
};

/**
 * This method is called when the user mousedowns on a div of class 'pxn8_slide'
 * Every div of class pxn8_slide should have a child div of class 'pxn8_slider'
 * The slide is the horizontal area through which the slider moves. The slider is the
 * bar indicator which indicates where the current position is in the slide.
 * 
 * |--------------------| slide
 *                 ^      slider
 * 
 * -- param slide The slide div
 * -- param event The mouse event which triggered this call (need to obtain position)
 * -- param inputId An input element whose value must be updated whenever the slider is moved
 * -- param start The start value (lowest possible value that can appear in the input element
 *          (basically the lowest in the range)
 * -- param size The range of values that can appear in the input element.
 */
PXN8.slide.onmousedown = function(slide,event,inputId,start,size)
{
    var kids = slide.getElementsByTagName("*");
    var slider = undefined;
    for (var i = 0; i < kids.length; i++){
        if (kids[i].className == "pxn8_slider"){
            slider = kids[i];
            break;
        }
    }
    slider.onmousemove = null;
    var inputElement = document.getElementById(inputId);
    
    slide.onmousemove = function(evt){ 
        return PXN8.slide.update(slider,
                                 inputElement,
                                 slide,
                                 evt,
                                 start,
                                 size);
    };
    slide.onmouseup = function(){ 
        slide.onmousemove = null; 
    };
    
    PXN8.slide.update(slider,inputElement,slide,event,start,size);    
};
/**
 *
 */
PXN8.slide.update = function(slider,inputElement,slide, evt,start,size)
{ 
    evt = (evt)?evt:window.event;
    var px = PXN8.slide.position(slide);
    var nx = evt.clientX - px;
    if (nx <= 120 && nx >= 3){
        slider.style.left = (nx-3) + "px";
        var iv = start + (((nx-3) / 117 ) * size);
        inputElement.value = Math.round(iv,2);
    }
};
/**
 * get the X position of an element relative to it's parent
 */
PXN8.slide.position = function (obj)
{
    var curleft = 0;
    if (obj.offsetParent)
    {
        while (obj.offsetParent)
        {
            curleft += obj.offsetLeft
                obj = obj.offsetParent;
        }
    }
    else if (obj.x)
        curleft += obj.x;
    return curleft;
};
