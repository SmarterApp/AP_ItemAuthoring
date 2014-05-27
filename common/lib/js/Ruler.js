Ruler = function(rulerController, rulerContainer) {
    
    this.UPDATE_NOTHING     = 0;
    this.UPDATE_BLOCK       = 1;
    this.UPDATE_PAGE        = 2;
    //this.UPDATE_SCROLLER    = 3;
    this.UPDATE_ALL         = 4;
    
    this.DEFAULT_RULER_UNIT = "cm";
    
    this.DRAG_NONE          = 0;
    this.DRAG_PAGE_LEFT     = 1;
    this.DRAG_PAGE_RIGHT    = 2;
    this.DRAG_BLOCK_LEFT    = 3;
    this.DRAG_BLOCK_RIGHT   = 4;
    
    //===============================
    // Member
    //===============================
    
    //-------------
    // Handler
    //-------------
    
    this.ondragstart;
    
    this.ondragstop;
    
    /* 
     * Copy a local reference to the Ruler object for use in the context of
     * jQuery calls.
     */
    var ruler = this;
    this.rulerController = rulerController;
    
    var rulerUnit = "";
    
    this.rulerStepsPerNumber = 4;
    this.rulerNumberFactor = 1;
    this.rulerStep = -1;
    this.unitConversionFactor = 1;
    this.pageMarginHandlesEnabled = true;
    this.blockMarginHandlesEnabled = true;
    
    var updateLevel = this.UPDATE_ALL;
    
    /* Dots per Inch */
    var dpi = 96;
    
    //page variables (for ruler)
    var pagePositionX = -1;
    var pageMarginLeft = -1;
    var pageMarginRight = -1;
    var pageWidth = -1;
    var zoomFactor = 1;
    
    this.mouseDownX = -1;
    this.draggingMode = this.DRAG_NONE;
    
    // Block variables
    var blockPositionX = -1;
    var blockWidth = -1;
    
    // View Elements
    this.marginLeftHandle = jQuery("<div class=\"blockMarginLeft blockMargin\"></div>");
    this.marginRightHandle = jQuery("<div class=\"blockMarginRight blockMargin\"></div>");
    this.pageMarginLeftElement = jQuery("<div class=\"pageMarginLeft rulerPageMargin\"></div>");
    this.pageMarginLeftHandle = jQuery("<div class=\"pageMarginLeftHandle\"></div>");
    this.pageMarginRightElement = jQuery("<div class=\"pageMarginRight rulerPageMargin\"></div>");
    this.pageMarginRightHandle = jQuery("<div class=\"pageMarginRightHandle\"></div>");
    this.blockContentElement = jQuery("<div class=\"blockContent\"></div>");
    this.rulerDashContainer = jQuery("<div class=\"rulerDashes\"></div>");
    
    rulerContainer.addClass("rulerContainer");
    
    rulerContainer.append(this.pageMarginLeftHandle);
    rulerContainer.append(this.pageMarginRightHandle);
    rulerContainer.append(this.marginRightHandle);
    rulerContainer.append(this.marginLeftHandle);
    rulerContainer.append(this.rulerDashContainer);
    rulerContainer.append(this.pageMarginLeftElement);
    rulerContainer.append(this.pageMarginRightElement);
    rulerContainer.append(this.blockContentElement);
    
    
    // The offset caused by scrolling to the right
    var rulerOffsetX = 0;
    
    //===============================
    // Public Methods
    //===============================
    

    this.init = function(newRulerUnit) {
        if(newRulerUnit != undefined) {
            this._setRulerUnit(newRulerUnit);
        }
        
        // Bind Handles
        rulerContainer.bind("mousedown",function(event) {
            // Is the pressed button the left mouse key?
            
            if(event.which == 1) {
                var target = jQuery(event.target);
                
                if(!target.hasClass("blockMargin")) {
                    if(ruler.pageMarginHandlesEnabled &&
                            (target.hasClass("pageMarginLeftHandle") || 
                            ruler._isEventInside(event, ruler.pageMarginLeftElement))) {
                        ruler.mouseDownX = event.pageX;
                        ruler.pageMarginLeft = ruler.getPageMarginLeft();
                        ruler.blockPosition = ruler.getBlockPosition();
                        ruler.blockWidth = ruler.getBlockWidth();
                        ruler.draggingMode = ruler.DRAG_PAGE_LEFT;
                    }
                    if(ruler.pageMarginHandlesEnabled &&
                            (target.hasClass("pageMarginRightHandle") || 
                            ruler._isEventInside(event, ruler.pageMarginRightElement))) {
                        ruler.mouseDownX = event.pageX;
                        ruler.pageMarginRight = ruler.getPageMarginRight();
                        ruler.blockPosition = ruler.getBlockPosition();
                        ruler.blockWidth = ruler.getBlockWidth();
                        ruler.draggingMode = ruler.DRAG_PAGE_RIGHT;
                    }
                } else {
                    if(ruler.blockMarginHandlesEnabled &&
                            target.hasClass("blockMarginLeft")) {
                        ruler.mouseDownX = event.pageX;
                        ruler.blockPosition = ruler.getBlockPosition();
                        ruler.blockWidth = ruler.getBlockWidth();
                        ruler.draggingMode = ruler.DRAG_BLOCK_LEFT;
                    } else if (ruler.blockMarginHandlesEnabled &&
                            target.hasClass("blockMarginRight")) {
                        ruler.mouseDownX = event.pageX;
                        ruler.blockPosition = ruler.getBlockPosition();
                        ruler.blockWidth = ruler.getBlockWidth();
                        ruler.draggingMode = ruler.DRAG_BLOCK_RIGHT;
                    }
                }
                if(ruler.ondragstart != undefined &&
                    ruler.draggingMode != ruler.DRAG_NONE) {
                    
                        ruler.ondragstart();
                }
                return false;
            }
            
        });
        
        jQuery(document).bind("mousemove", function(event) {
            if(ruler.draggingMode != ruler.DRAG_NONE) {
                
                var delta = (event.pageX - ruler.mouseDownX) / ruler.unitConversionFactor;
                
                switch(ruler.draggingMode) {
                    case ruler.DRAG_PAGE_LEFT : {
                        var marginLeft = ruler.rulerRound(ruler.pageMarginLeft + delta);
                        
                        var blockLeft = ruler.blockPosition + ruler.rulerRound(delta);
                        
                        var blockWidth = ruler.getBlockWidth() + 
                                        ruler.getBlockPosition() - blockLeft;
                        
                        if(blockWidth > (ruler.rulerStep * zoomFactor) && marginLeft >= 0) {
                            ruler.setPageValues(undefined, marginLeft, undefined , undefined);
                            ruler.setBlockValues(blockLeft, blockWidth);
                            ruler.update();
                        }
                        break;
                    }
                    case ruler.DRAG_PAGE_RIGHT : {
                        var marginRight =  ruler.rulerRound(ruler.pageMarginRight - delta);
                        
                        var blockWidth = ruler.rulerRound(ruler.blockWidth + delta);
                        if(blockWidth > 0 && marginRight >= 0) {
                            ruler.setPageValues(undefined, undefined, marginRight, undefined);
                            ruler.setBlockValues(undefined, blockWidth);
                            ruler.update();
                        }
                        break;
                    }
                    case ruler.DRAG_BLOCK_LEFT : {
                        delta = ruler.rulerRound(delta);
                        
                        var blockLeft = Math.max(0,
                                ruler.blockPosition + delta);
                        var blockWidth = ruler.getBlockWidth() + 
                        ruler.getBlockPosition() - blockLeft;
                        if(blockWidth >= ruler.rulerStep) {
                            ruler.setBlockValues(blockLeft, blockWidth);
                            ruler.update();
                        }
                        break;
                    }
                    case ruler.DRAG_BLOCK_RIGHT : {
                        delta = ruler.rulerRound(delta);
                        var maxWidth = parseFloat(rulerContainer[0].style.width) - ruler.blockPosition;
                        var blockWidth = Math.min(maxWidth, 
                                Math.max((ruler.rulerStep * zoomFactor),ruler.blockWidth + delta));
                        
                        ruler.setBlockValues(undefined, blockWidth);
                        ruler.update();
                        
                        break;
                    }
                }
                return false;
            }
        });
        
        jQuery(document).bind("mouseup", function(event) {
            if(ruler.draggingMode != ruler.DRAG_NONE) {
                switch (ruler.draggingMode) {
                    case ruler.DRAG_PAGE_LEFT: {
                        var margin = parseFloat(ruler.pageMarginLeftElement[0].style.width);
                        rulerController.setPageMarginLeft((ruler.rulerRound(margin)/zoomFactor) + rulerUnit);
                        break;
                    }
                    case ruler.DRAG_PAGE_RIGHT: {
                        var margin = parseFloat(ruler.pageMarginRightElement[0].style.width);
                        rulerController.setPageMarginRight((ruler.rulerRound(margin)/zoomFactor) + rulerUnit);
                        break;
                    }
                    case ruler.DRAG_BLOCK_LEFT : {
                        var pixel = ruler.marginLeftHandle.position().left;
                        var usedUnit = pixel / ruler.unitConversionFactor;
                        ruler.marginLeftHandle.css("left", usedUnit + rulerUnit);
                        
                        var delta = Math.round((usedUnit - ruler.blockPosition) /
                                (ruler.rulerStep * zoomFactor)) * (ruler.rulerStep * zoomFactor);
                        rulerController.modifyBlockMarginLeft(delta / zoomFactor);
                        
                        break;
                    }
                    case ruler.DRAG_BLOCK_RIGHT : {
                        var pixel = ruler.marginRightHandle.position().left;
                        var usedUnit = pixel / ruler.unitConversionFactor;
                        ruler.marginRightHandle.css("left", usedUnit  - rulerUnit);
                        
                        var delta = Math.round((usedUnit - ruler.blockPosition - ruler.blockWidth) /
                                (ruler.rulerStep * zoomFactor)) * (ruler.rulerStep * zoomFactor) * -1;
                        rulerController.modifyBlockMarginRight(delta / zoomFactor);
                        
                        break;
                    }
                }
                
                ruler.mouseDownX    = -1;
                ruler.draggingMode  = ruler.DRAG_NONE;
                
                if(ruler.ondragstop != undefined) {
                    ruler.ondragstop();
                }
                
                return false;
            }
        });
    };
    
    this._isEventInside = function(event, object) {
        if((event.pageX >= object.offset().left && 
                event.pageX <= object.offset().left + object.width())) {
            return true;
        }
        var children = object.children();
        for(var i = 0; i < children.length; i++) {
            if(this._isEventInside(event, jQuery(children[i]))) {
                return true;
            }
        }
        
        return false;
    };
    
    this.update = function() {
        if(updateLevel >= this.UPDATE_PAGE) {
            this.pageMarginLeftElement.css("width", (pageMarginLeft) + rulerUnit);
            this.pageMarginLeftHandle.css("left", (pageMarginLeft) + rulerUnit);
            this.pageMarginRightElement.css("width", (pageMarginRight) + rulerUnit);
            this.pageMarginRightHandle.css("right", (pageMarginRight) + rulerUnit);
            rulerContainer.css("width", pageWidth + rulerUnit);
        }
        if(updateLevel >= this.UPDATE_BLOCK) {
            this.blockContentElement.css("left", blockPositionX + rulerUnit);
            this.blockContentElement.css("width", blockWidth + rulerUnit);
            
            this.marginLeftHandle.css("left", (blockPositionX) + rulerUnit);
            this.marginRightHandle.css("left", (blockPositionX + blockWidth)  + rulerUnit);
            
        }
        if(updateLevel >= this.UPDATE_ALL) {
            this._createDashes();
        }
        
        updateLevel = this.UPDATE_NOTHING;
    };
    
    this._createDashes = function(){
        
        var step = this.rulerStep * zoomFactor;
        var stepsPerNumber = this.rulerStepsPerNumber;
        
        var stepInPixel = step * this.unitConversionFactor;
        
        // Level of detail: 0 = maximum, higher = less dashes/numbers
        var lod = 0;
        
        var detailHelp = stepInPixel / 16;
        if(detailHelp < 0.10) {
            lod = 4;
        } else if(detailHelp < 0.2) {
            lod = 3;
        } else if(detailHelp < 0.3) {
            lod = 2;
        } else if(detailHelp < 0.5) {
            lod = 1;
        }
        
        var origin = pageMarginLeft;
        var str_html = "";
        var counter = 0;
        
        for(var i = 0; i*step < pageWidth; i++) {
            if(counter % stepsPerNumber == 0) {
                if(counter != 0) {
                    var number = Math.round(counter / stepsPerNumber);
                    if(lod < 3 || (lod < 4 && number % 2 == 0) || 
                                  (lod < 5 && number % 4 == 0) ) {
                        str_html += "<div class='rulerCount' style='left:" 
                            + (origin + i*step) 
                            + rulerUnit + "'>" + number * this.rulerNumberFactor + "</div>";
                        
                        str_html += "<div class='rulerCount' style='left:" 
                            + (origin - i*step)
                            + rulerUnit + "'>" + number * this.rulerNumberFactor + "</div>";
                    }
                }
            } else {
                var dashClass = "rulerDashSmall";
                var createDash = false;
                if(counter % (stepsPerNumber / 2) == 0) {
                    if(lod < 2) {
                        createDash = true;
                    }
                    dashClass = "rulerDashMedium";
                }
                if(lod < 1) {
                    createDash = true;
                }
                if(createDash) {
                    str_html += "<div class='"+dashClass+"' style='left:" 
                    + (origin + i*step)
                    + rulerUnit + "'></div>";
                    str_html += "<div class='"+dashClass+"' style='left:" 
                    + (origin - i*step)
                    + rulerUnit + "'></div>";
                }
            }
            counter++;
        }
        
        this.rulerDashContainer.html(str_html + "<div id='rulerContent'></div>");
    };
    
    this.setRulerContainerOffset = function(newOffsetX) {
        if (rulerOffsetX != newOffsetX) {
            rulerOffsetX = newOffsetX;
                rulerContainer.css("left", rulerOffsetX );
        }
    };
    
    this.setPageValues = function(offset, marginLeft, marginRight, width) {
        var change = false;
        if(offset != undefined && pagePositionX != offset) {
            pagePositionX = offset;
            rulerContainer.css("left", pagePositionX + "px");
        }
        if(marginLeft != undefined && pageMarginLeft != marginLeft) {
            change = true;
            pageMarginLeft = marginLeft;
            this._increaseUpdateLevel(this.UPDATE_ALL);
        }
        if(marginRight != undefined && pageMarginRight != marginRight) {
            change = true;
            pageMarginRight = marginRight;
        }
        if(width != undefined && pageWidth != width) {
            pageWidth = width;
            rulerContainer.css("width", width + this.getRulerUnit());
            this._increaseUpdateLevel(this.UPDATE_ALL);
        }
        
        if(change) {
            this._increaseUpdateLevel(this.UPDATE_PAGE);
        }
    };
    
    this.getPageMarginLeft = function() {
        return pageMarginLeft;
    };
    
    this.getPageMarginRight = function() {
        return pageMarginRight;
    };
    
    this.setBlockValues = function(offset, width) {
        var change = false;
        if(offset != undefined && blockPositionX != offset) {
            change = true;
            blockPositionX = offset;
        }
        if(width != undefined && blockWidth != width) {
            change = true;
            blockWidth = width;
        }
        if(change) {
            this._increaseUpdateLevel(this.UPDATE_BLOCK);
        }
    };
    
    this.getBlockWidth = function() {
        return blockWidth;
    };

    this.getBlockPosition = function() {
        return blockPositionX;
    };
    
    // Sets the Unit of the Ruler and returns the current Unit.
    this._setRulerUnit = function(newRulerUnit) {
        if (newRulerUnit != undefined) {
            newRulerUnit = newRulerUnit.toLowerCase(); 
            if (rulerUnit != newRulerUnit && (
                    newRulerUnit == "cm" ||
                    newRulerUnit == "in" ||
                    newRulerUnit == "mm" ||
                    newRulerUnit == "px")) {
                        
                        rulerUnit = newRulerUnit;
                        this._increaseUpdateLevel(this.UPDATE_ALL);
                        
                        if(rulerUnit == "cm") {
                            ruler.unitConversionFactor = dpi / 2.54;
                            ruler.rulerStep = 0.25;
                            ruler.rulerStepsPerNumber = 4;
                            ruler.rulerNumberFactor = 1;
                        } else if(rulerUnit == "mm") {
                            ruler.unitConversionFactor = dpi / 25.4;
                            ruler.rulerStep = 2.5;
                            ruler.rulerStepsPerNumber = 8;
                            ruler.rulerNumberFactor = 20;
                        } else if(rulerUnit == "in") {
                            ruler.unitConversionFactor = dpi;
                            ruler.rulerStep = 0.25;
                            ruler.rulerStepsPerNumber = 8;
                            ruler.rulerNumberFactor = 2;
                        } else if(rulerUnit == "px") {
                            ruler.unitConversionFactor = 1;
                            ruler.rulerStep = 10;
                            ruler.rulerStepsPerNumber = 10;
                            ruler.rulerNumberFactor = 100;
                        }
            }
        }
        return rulerUnit;
    };
    
    this.getRulerUnit = function() {
        return rulerUnit;
    };   
    
    this.setZoomFactor = function(newZoomFactor) {
        if(newZoomFactor != undefined && newZoomFactor != zoomFactor && newZoomFactor > 0) {
            // TODO remove this 'if' as soon as the zoomer controls the minimal zoom factor
            if(newZoomFactor >= 0.1 ) {
                zoomFactor = newZoomFactor;
            }
            this._increaseUpdateLevel(this.UPDATE_ALL);
        }
        return zoomFactor;
    };
    
    this.getZoomFactor = function() {
        return zoomFactor;
    };
    
    this.setPageMarginHandlesEnabled = function(enabled) {
        if(this.pageMarginHandlesEnabled != enabled) {
            if(enabled) {
                this.pageMarginLeftHandle.removeClass("handleDisabled");
                this.pageMarginRightHandle.removeClass("handleDisabled");
            } else {
                this.pageMarginLeftHandle.addClass("handleDisabled");
                this.pageMarginRightHandle.addClass("handleDisabled");
            }
            this.pageMarginHandlesEnabled = enabled;
        }
    };
    
    this.setBlockMarginHandlesEnabled = function(enabled) {
        if(this.pageBlockHandlesEnabled != enabled) {
            if(enabled) {
                this.marginLeftHandle.show();
                this.marginRightHandle.show();
            } else {
                this.marginLeftHandle.hide();
                this.marginRightHandle.hide();
            }
            this.pageBlockHandlesEnabled = enabled;
        }
    };
    
    this._increaseUpdateLevel = function(level) {
        if(level != undefined && level > updateLevel) {
            updateLevel = level;
        }
        return updateLevel;
    };
    
    this.rulerRound = function(input, ignoreZoom) {
        var factor;
        if(ignoreZoom != undefined && ignoreZoom) {
            factor = 1;
        } else {
            factor = zoomFactor;
        }
        
        return Math.round(input / (ruler.rulerStep * factor)) * 
            (ruler.rulerStep * factor);
    }
    
    this._setRulerUnit(this.DEFAULT_RULER_UNIT);
};