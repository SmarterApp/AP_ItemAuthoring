RulerController = function(apiObject) {
    
    var rulerController = this;
    
    var editorReplaced = false;
    
    this.ruler;
    this.rulerContainer;
    
    this.currentBlockMarginLeft = 0;
    this.currentBlockMarginRight = 0;
    
    /**
     * Creates and initializes the visible ruler.
     */
    this.init = function(container, unit) {
        if(unit == undefined) {
            unit = "cm";
        }
        
        var ieSelectionFix = "";
        
        if(apiObject.Helper.isMSIE) {
            ieSelectionFix = "onselectstart=\"return false;\"";
        }
        
        this.rulerContainer = jQuery("<div " + ieSelectionFix + "></div>");
        container.prepend(this.rulerContainer);
        
        this.ruler = new Ruler(this, this.rulerContainer);
        this.ruler.init(unit);
        this.ruler.setPageValues(0, 0, 0, 0);
        this.ruler.setBlockValues(0, 0);
        
        this.ruler.update();
        
        // Apply workaround for Internet Explorer 7
        if(apiObject.Helper.isMSIE && parseInt(eong.Helper.BrowserVersion) == 7) {
            this._ie7fix();
        }
        
        // Set focus on the applet when releasing a drag handle
        this.ruler.ondragstop = function() {
            apiObject.requestFocus();
        };
    };
    
    /**
     * Updates the ruler with a data object from the applet.
     */
    this.updateRuler = function(updateObj) {
        
        if(updateObj != undefined) {
            var zoomFactor = updateObj["zoom"];
            rulerController.setZoomFactor(zoomFactor);
            
            rulerController.currentBlockMarginLeft  = updateObj["block-margin-left"];
            rulerController.currentBlockMarginRight = updateObj["block-margin-right"];
            
            var blockOffset = updateObj["block-offset-x"] + 
                                rulerController.currentBlockMarginLeft * zoomFactor;
            var blockWidth  = updateObj["block-width"] - 
                            rulerController.currentBlockMarginLeft * zoomFactor - 
                            rulerController.currentBlockMarginRight * zoomFactor;
            rulerController.ruler.setBlockValues(blockOffset, blockWidth);
            
            var pagedMode = updateObj["paged-mode"];
            rulerController.ruler.setPageMarginHandlesEnabled(pagedMode);
            
            
            var rulerBorderLeftWidth = 0;
            
            if(rulerController.rulerContainer.css("border-left-style") != "none") {
                rulerBorderLeftWidth = rulerController._resolveBorderWidth(
                        rulerController.rulerContainer.css("border-left-width"));
            }
            
            var pageOffset = updateObj["page-offset-x"];
            var pageWidth  = pagedMode ? updateObj["page-width"] : updateObj["page-width"] / zoomFactor;
            var pageMarginLeft  = updateObj["page-margin-left"] * zoomFactor;
            var pageMarginRight = updateObj["page-margin-right"] * zoomFactor;
            var scrollX = updateObj["horizontal-scrollbar"];
            
            rulerController.ruler.setPageValues(pageOffset - rulerBorderLeftWidth - scrollX,
                    pageMarginLeft, pageMarginRight, pageWidth);
            
            
            rulerController.ruler.update();
            
            //updateObj["css-pixel"];
        }
    };
    
    /**
     * Sets a new left page margin in the document.
     */
    this.setPageMarginLeft = function(margin) {
        apiObject.getObj().setPageMarginLeft(margin);
    };
    
    /**
     * Sets a new right page margin in the document.
     */
    this.setPageMarginRight = function(margin) {
        apiObject.getObj().setPageMarginRight(margin);
    };
    
    /**
     * Modifies the left margin of the current block by the given value.
     */
    this.modifyBlockMarginLeft = function(margin) {
        var oldLength = this.ruler.rulerRound(this.currentBlockMarginLeft, true);
        if(oldLength != undefined) {
            margin = oldLength + margin;
        }
        if(Math.abs(margin) < this.ruler.rulerStep / 2) {
            margin = 0;
        }
        
        apiObject.getObj().setUsedBlockMarginLeft(margin + this.ruler.getRulerUnit());
    };
    
    /**
     * Modifies the right margin of the current block by the given value.
     */
    this.modifyBlockMarginRight = function(margin) {
        var oldLength = this.ruler.rulerRound(this.currentBlockMarginRight, true);
        if(oldLength != undefined) {
            margin = oldLength + margin;
        }
        if(Math.abs(margin) < this.ruler.rulerStep / 2) {
            margin = 0;
        }
        
        apiObject.getObj().setUsedBlockMarginRight(margin + this.ruler.getRulerUnit());
    };
    
    /**
     * Returns the current zoom factor of the ruler.
     */
    this.getZoomFactor = function() {
        if(this.ruler){
            return this.ruler.getZoomFactor();
        }
        return 1;
    };
    
    /**
     * Sets a new zoom factor for the ruler.
     */
    this.setZoomFactor = function(factor) {
        this.ruler.setZoomFactor(factor);
        this.ruler.update();
    };
    
    this._resolveBorderWidth = function(width) {
        var thinBorder = 1;
        var mediumBorder = 3;
        var thickBorder = 5;
        var borderWidth = 0;
        
        switch (width) {
        case "thin":
            borderWidth = thinBorder;
            break;
        case "medium":
            borderWidth = mediumBorder;
            break;
        case "thick":
            borderWidth = thickBorder;
            break;
        default:
            borderWidth = Math.round(parseFloat(leftBorderWidth));
            break;
        }
        return borderWidth;
    }
    
    /**
     * Fixes an z-index issue in Internet Explorer 7 that causes the ruler
     * marks to be covered by other elements (e.g. the white content area).
     */
    this._ie7fix = function() {
        var zIndexFix = 1000;
        jQuery('.rulerContainer, .rulerContainer > div').each(function() {
            jQuery(this).css('zIndex', zIndexFix);
            zIndexFix -= 10;
        });
    }
};