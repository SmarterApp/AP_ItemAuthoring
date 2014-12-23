/* ============================================================================
 *
 * (c) Copyright SXOOP Technologies Ltd. 2005-2006
 * All rights reserved.
 *
 * This file contains code which handles event managment
 *
 */
var PXN8 = PXN8 || {};

PXN8.event = {
    /**
     * Add a new event handler 
     */
    addListener: function(el,eventstr,func){
        if (el.addEventListener){
            el.addEventListener(eventstr,func,true);
        }else if (el.attachEvent){
            el.attachEvent("on" + eventstr,func);
        }
    },
    /**
     * remove an event handler 
     */
    removeListener: function(el,eventstr,func){
        if (el.removeEventListener){
            el.removeEventListener(eventstr,func,true);
        }else if (el.detachEvent){
            el.detachEvent("on" + eventstr,func);
        }
    },
	
    /**
     * PXN8.event.closure creates an event closure 
     * Parameters: object The object to be baked into the event handler
     * func - The event handler (a function)
     * The closure returned will take 4 parameters...
     * object: The object that has been baked in.
     * source: The HTML element that triggered the event
     * event: The event which triggered the function call.
     * caller: The closure itself - this will not be the same as the function passed into PXN8.event.closure.
     */
    closure: function(object,func){
        return function(event){
            event = event || window.event;
            var source = (window.event) ? event.srcElement : event.target;
            func(event,object,source,arguments.callee);
        };
    },
    /**
     * Creates an event handler where the source, and event are guaranteed to be present and correct
     * It does things like normalizing the event (removing IE & firefox discrepancies)
     */
    normalize: function(func){
        return function(event){
            event = event || window.event;
            var source = (window.event) ? event.srcElement : event.target;
            func(event,source,arguments.callee);
        };
    }
};

/**
 * Bind event-handling behaviour to all elements of a particular class
 */
PXN8.behaviour = {
    
    bind: function(className,behaviourObject){
        var elements = PXN8.dom.clz(className);
        for (var i = 0;i < elements.length; i++)
        {
            for (var j in behaviourObject){
                PXN8.event.addListener(elements[i],j,behaviourObject[j]);
            }
        }
    }
};
