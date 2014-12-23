/*
 * Copyright (C) 2005 - 2011 Jaspersoft Corporation. All rights reserved.
 * http://www.jaspersoft.com.
 *
 * Unless you have purchased  a commercial license agreement from Jaspersoft,
 * the following license terms  apply:
 *
 * This program is free software: you can redistribute it and/or  modify
 * it under the terms of the GNU Affero General Public License  as
 * published by the Free Software Foundation, either version 3 of  the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero  General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public  License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

var charts = {};

Report.toolbarActionMap = {
    'asyncCancel' : "Report.cancelReportAsyncExecution",
    'back' : "Report.goBack",
    'ICDialog' : "Controls.show",
    'export': "doNothing",
    'undo': "Report.undo",
    'redo': "Report.redo",
    'undoAll': "Report.undoAll"
};

Report.initialize = function() {
    this.commonInit();

    Report.exportForm = $(Report.EXPORT_ACTION_FORM);
    this.nothingToDisplay = $('nothingToDisplay');
    
    if ($(Report.DATA_REFRESH_BUTTON)) {
    	$(Report.DATA_REFRESH_BUTTON).observe('click', function() {
    		this.rerunReport({freshData: true});
    	}.bindAsEventListener(this));
    }
    
    /**
     *  Init toolbar
     */
    if (window.toolbarButtonModule) {
        toolbarButtonModule.ACTION_MODEL_TAG = Report.TOOLBAR_SUBMENU;
        toolbarButtonModule.initialize(Report.toolbarActionMap);
    }

    if ($(Report.PAGINATION_PAGE_CURRENT)) { // observe page navigation input
        $(Report.PAGINATION_PAGE_CURRENT).observe('change', function(e) {
            this.goToPage($(Report.PAGINATION_PAGE_CURRENT).getValue());
            e.stop();
        }.bindAsEventListener(this));


        // observe page navigation buttons
        $(this.PAGINATION_CONTAINER).observe('click', function(e) {
            var elem = e.element();
            e.stop();

            for (var pattern in this.pageActions) {
                if (matchAny(elem, [pattern], true)) {
                    this.navigateToReportPage(this.pageActions[pattern]);
                    return;
                }
            }
        }.bindAsEventListener(this));
    }

    if (document.location.href.indexOf("noReturn=true") > 0) {
//         jQuery('#back > span.wrap').html('Close');
        buttonManager.disable($('back'))
    }

    if (Report.areInputControlsEnabled()) {
        Controls.initialize.bind(Controls)(Report.refreshReport);
    } else {
        Report.refreshReport();
    }
};

Report.rerunReport = function(urlParams, options) {
	// run the report with current input control values
	if (Report.areInputControlsEnabled()) {
        var selectedData = Controls.viewModel.get('selection');
        this.refreshReport(urlParams, options, ControlsBase.buildSelectedDataUri(selectedData));
	} else {
		this.refreshReport(urlParams, options);
	}
};

Report.areInputControlsEnabled = function() {
    return (typeof Controls !== "undefined");
};

Report.showNothingToDisplayPanel = function() {
    if (Report.nothingToDisplay) {
        Report.nothingToDisplay.removeClassName(layoutModule.HIDDEN_CLASS);
        centerElement(Report.nothingToDisplay, {horz: true, vert: true});
        jQuery("#" + Report.DATA_REFRESH_BUTTON).attr(layoutModule.DISABLED_ATTR_NAME, layoutModule.DISABLED_ATTR_NAME);
    }
};

Report.isNothingToDisplayShown = function() {
    if (Report.nothingToDisplay) {
        return !Report.nothingToDisplay.hasClassName(layoutModule.HIDDEN_CLASS);
    }
    return false;
};

Report.hideNothingToDisplay = function() {
    if (Report.nothingToDisplay) {
        Report.nothingToDisplay.addClassName(layoutModule.HIDDEN_CLASS);
        jQuery("#" + Report.DATA_REFRESH_BUTTON).removeAttr(layoutModule.DISABLED_ATTR_NAME);
    }
};

Report.refreshExporters = function() {
    (Report.exportersList.length > 0 && Report.reportSuccess()) 
    	? buttonManager.enable($('export'))
    	: buttonManager.disable($('export'));
}

Report.refreshSave = function() {
	// overridden in Pro
};

Report.refreshPagination = function(silentUpdate) {
	if (this.lastPageIndex != null) {
		this.reportRunning = false;
	}
	
    if (this.emptyReport || (this.lastPageIndex != null && this.lastPageIndex <= 0)) {
        buttonManager.disable($(Report.PAGINATION_PAGE_FIRST));
        buttonManager.disable($(Report.PAGINATION_PAGE_PREV));
        buttonManager.disable($(Report.PAGINATION_PAGE_CURRENT));
        buttonManager.disable($(Report.PAGINATION_PAGE_NEXT));
        buttonManager.disable($(Report.PAGINATION_PAGE_LAST));
        if ($(Report.PAGINATION_PAGE_CURRENT)) {
            $(Report.PAGINATION_PAGE_CURRENT).setValue("");
            $(Report.PAGINATION_PAGE_TOTAL).update("");
        }
        return;
    }

    if (this.pageIndex > 0) {
        buttonManager.enable($(Report.PAGINATION_PAGE_FIRST));
        buttonManager.enable($(Report.PAGINATION_PAGE_PREV));
    } else {
        buttonManager.disable($(Report.PAGINATION_PAGE_FIRST));
        buttonManager.disable($(Report.PAGINATION_PAGE_PREV));
    }

	if (this.lastPageIndex == null) {
		if (this.lastPartialPageIndex == null || this.pageIndex < this.lastPartialPageIndex) {
	        buttonManager.enable($(Report.PAGINATION_PAGE_NEXT));
		} else {
	        buttonManager.disable($(Report.PAGINATION_PAGE_NEXT));
		}
        buttonManager.disable($(Report.PAGINATION_PAGE_LAST));
	} else if (this.pageIndex < this.lastPageIndex) {
        buttonManager.enable($(Report.PAGINATION_PAGE_NEXT));
        buttonManager.enable($(Report.PAGINATION_PAGE_LAST));
    } else {
        buttonManager.disable($(Report.PAGINATION_PAGE_NEXT));
        buttonManager.disable($(Report.PAGINATION_PAGE_LAST));
    }

    buttonManager.enable($(Report.PAGINATION_PAGE_CURRENT));
    if ($(Report.PAGINATION_PAGE_CURRENT)) {
    	if (!silentUpdate) {
	        $(Report.PAGINATION_PAGE_CURRENT).setValue(this.pageIndex + 1);
    	}

        if (this.lastPageIndex == null) {
            $(Report.PAGINATION_PAGE_TOTAL).update("");
        } else {
	        $(Report.PAGINATION_PAGE_TOTAL).update(this.getMessage("jasper.report.view.page.of") + (this.lastPageIndex + 1));
        }
    }


    this.pageActions = {
        'button#page_first': 0,
        'button#page_prev': this.pageIndex - 1,
        'button#page_next': this.pageIndex + 1
    };
    
    if (this.lastPageIndex != null) {
    	this.pageActions['button#page_last'] = this.lastPageIndex;
    }
}

Report.refreshPartialLastPage = function() {
	if (this.lastPartialPageIndex != null) {
		if (this.pageIndex < this.lastPartialPageIndex) {
    	    buttonManager.enable($(Report.PAGINATION_PAGE_NEXT));
    	} else {
        	buttonManager.disable($(Report.PAGINATION_PAGE_NEXT));
    	}
	}
}

Report.reportDone = function() {
	return !this.reportRunning || this.lastPageIndex != null;
}

Report.reportSuccess = function() {
	return this.lastPageIndex != null;
}

Report.pageUpdateCheckRequired = function() {
	// check for updates if the report is not finished
	return !this.reportDone() && this.jasperPrintName;
}

Report.scheduleCheckPageUpdated = function() {
	if (this.pageUpdateCheckRequired()) {
		var self = this;
		var pageUpdatedCall = function() {
			self.checkPageUpdated();
		};
		
		var delay = Report.updateDelay;
		if (delay > 5000) {
			delay = 5000;
		} else {
			Report.updateDelay += Report.updateDelayIncrement;
			Report.updateDelayIncrement += 1000;
		}
		
		this.checkPageUpdatedTimeoutId = window.setTimeout(pageUpdatedCall, delay);
	}
}

Report.cancelCheckPageUpdated = function() {
	if (this.checkPageUpdatedTimeoutId != null) {
		window.clearTimeout(this.checkPageUpdatedTimeoutId);
		this.checkPageUpdatedTimeoutId = null;
	}
}

Report.jsonErrorHandler = function(ajaxAgent) {
	if (!Report.isValidJsonResponse(ajaxAgent)) {
		var handled = baseErrorHandler(ajaxAgent);
		if (!handled) {
			// this shouldn't normally happen
			alert("Unexpected response");
		}
		return true;
	}
	return false;
}

Report.jsonReportStatusErrorHandler = function(ajaxAgent, nonReportErrorHandler) {
	if (!Report.isValidJsonResponse(ajaxAgent)) {
		// see if it's a report execution error
		if (ajaxAgent.getResponseHeader("reportError")) {
			Report.reportRunning = false;
			Report.refreshAsyncCancel();
			if (ajaxAgent.getResponseHeader("lastPartialPageIndex")) {
				Report.lastPartialPageIndex = ajaxAgent.getResponseHeader("lastPartialPageIndex");
				Report.refreshPartialLastPage();
			}
				
			// report execution error, show the popup
			var handled = baseErrorHandler(ajaxAgent);
			if (!handled) {
				// this shouldn't normally happen
				alert("Unexpected response");
			}
			return true;
		} else {
			// other type of error
			return nonReportErrorHandler(ajaxAgent);
		}
	}
	return false;
}

Report.jsonReportStatusCallback = function(jsonResponse) {
	if (Report.reportDone()) {
		// report completion was already processed, nothing to do
		return;
	}
	
	if (jsonResponse.result.lastPartialPageIndex) {
		Report.lastPartialPageIndex = jsonResponse.result.lastPartialPageIndex;
		Report.refreshPartialLastPage();
	}

	var status = jsonResponse.result.status;
	if (status == "canceled") {
		if (Report.reportRunning) {
			Report.reportRunning = false;
			Report.refreshAsyncCancel();
			dialogs.systemConfirm.show(Report.getMessage("jasper.report.view.report.canceled"), 5000);
		}
		return;
	} else if (status == "error") {
		// should not get here
		alert("Report execution error: " + jsonResponse.result.errorMessage);
	} else {
		if (jsonResponse.result.lastPageIndex) {
			Report.lastPageIndex = jsonResponse.result.lastPageIndex;
		}
				
		if (jsonResponse.result.snapshotSaveStatus) {
			Report.snapshotSaveStatus = jsonResponse.result.snapshotSaveStatus;
		}
			
		Report.refreshPagination(true);
		Report.refreshExporters();
		Report.refreshSave();
		Report.refreshAsyncCancel();
		Report.scheduleCheckPageUpdated();
	}
}

Report.isValidJsonResponse = function(ajaxAgent) {
	var responseType = ajaxAgent.getResponseHeader("Content-Type");
	return ajaxAgent.status == 200 && responseType != null && responseType.indexOf("application/json") >= 0;
}

Report.checkPageUpdated = function() {
	this.cancelCheckPageUpdated();
	
	if (!this.pageUpdateCheckRequired()) {
		// final page, total page count known -> no update check required
		return;
	}
	
	var params = {
		jasperPrintName: this.jasperPrintName
	};
	
	if (this.pageTimestamp != null) {
		// the page is not final, check for updates
		params.pageIndex = this.pageIndex;
		params.pageTimestamp = this.pageTimestamp;
	}
	
	var url = 'viewReportPageUpdateCheck.html?' + Object.toQueryString(params);
	
	var options = {
		mode: AjaxRequester.prototype.EVAL_JSON,
		silent: true,//silent
		errorHandler: function(ajaxAgent) {
			return Report.jsonReportStatusErrorHandler(ajaxAgent, function(ajaxAgent) {
				// don't do anything, but schedule a new update refresh
				Report.scheduleCheckPageUpdated();
				return true;
			});
		},
		callback: function(jsonResponse) {
			Report.jsonReportStatusCallback(jsonResponse);

			if (jsonResponse.result.pageModified) {
				// refresh the current page
				Report.navigateToReportPage(Report.pageIndex, true, true);
			}
		}
	};

	ajaxTargettedUpdate(url, options);
};

Report.cancelReportAsyncExecution = function() {
	if (!Report.jasperPrintName) {
		return;
	}
	
	// cancel the update check
	Report.cancelCheckPageUpdated();

	Report.asyncCanceled = true;
	buttonManager.disable($('asyncCancel'));// only disable for now, it will hide in the callback
	
	var url = 'viewReportAsyncCancel.html?' + Object.toQueryString({jasperPrintName: Report.jasperPrintName});
	var options = {
		mode: AjaxRequester.prototype.EVAL_JSON,
		errorHandler: function(ajaxAgent) {
			return Report.jsonReportStatusErrorHandler(ajaxAgent, function(ajaxAgent) {
				// schedule a new update refresh
				Report.scheduleCheckPageUpdated();
				
				// default error handling
				baseErrorHandler(ajaxAgent);
				return true;
			});
		},
		callback: function(jsonResponse) {
			Report.jsonReportStatusCallback(jsonResponse);
			
			// it's possible that the report had finished before clicking cancel.
			// in that case, if we have an incomplete page refresh it
			if (jsonResponse.result.status == "finished" && Report.pageTimestamp != null) {
				Report.navigateToReportPage(Report.pageIndex, true, true);
			}
		}
	};

	ajaxTargettedUpdate(url, options);
}

Report.reportPageRefreshed = function(silentUpdate) {
	var fr,r;

    /*
     * Adding following line to force Google chrome to display ajax content
     * injected into #reportContainer. Bug fix 23988.
     */
    if(typeof JRS !== 'undefined' && JRS.fid){
        fr = jQuery('#'+JRS.fid, window.parent.document);
    	r = fr.contents().find('#reportContainer');
    	fr.removeClass('hidden').show();   	
    	/*
    	var img_cnt = r.find('img').each(function(){
    		jQuery(this).css('z-index',99999);
    	});
    	*/
        if(!isIPad()) fr.parent().parent().css('background-image','none');  
        var h = r.height(); 
        var w = r.width();
        if(isSupportsTouch()){
        	new TouchController(r.get(0),fr.get(0).parentNode.parentNode,{
        		use2Fingers:true,
        		showBorders:true,
        		noInit3d:true
        	});
        	
            r.children('div').bind({
            	'touchstart':function(){
            		fr.parent().parent().siblings().removeClass('over');
            		fr.parent().parent().addClass('over');
            	}
            })
        }
    	r.show(); 
    } else {
    	var ic = $(ControlsBase.INPUT_CONTROLS_FORM);
    	if(isSupportsTouch()){
    		if(this.touchController){
    			this.touchController.reset();
    		} else {
    			var scrollWrapper =  jQuery('#reportContainer').parent().parent();
                var contentWidth = jQuery('#reportContainer > div').width();
                (scrollWrapper.width() < contentWidth) && (scrollWrapper.css('width', contentWidth + 'px'));
                this.touchController = new TouchController(scrollWrapper[0],scrollWrapper.parent()[0],{
                    noInit3d:true,
                    scrollbars: true
                });
    		} 		
    		var bm = jQuery('#' + ControlsBase.INPUT_CONTROLS_FORM + ' > button.minimize');
    		if(ic && bm && bm.is(":visible")){
    			var m = ic.hasClassName('minimized');
        		layoutModule.maximize(ic);
        		m && layoutModule.minimize(ic); 	
    		}
    	}
		jQuery('#reportContainer').show().height();
    }
    
    Report.hideNothingToDisplay();

    //TODO: this needs to be removed
    //only few _evalScript are lest in jsp and they could be removed with
    //div elements which can contain custom data- attributes
    //similarly as in Report.updatePageForNonEmptyReport() implementation
    ControlsBase.evalScripts();

    Report.updatePageForNonEmptyReport();
    Report.updatePageForEmptyReport();
    Report.refreshPagination(silentUpdate);
    Report.refreshExporters();
    Report.refreshSave();
	Report.refreshAsyncCancel();

	if (this.dataTimestampMessage && $(Report.DATA_TIMESTAMP_SPAN)) {
		$(Report.DATA_TIMESTAMP_SPAN).update(this.dataTimestampMessage);
	}
	
    Report.scheduleCheckPageUpdated();
}

Report.initUpdateCheckDelay = function() {
    Report.updateDelay = 1000;
    Report.updateDelayIncrement = 0;
}

Report.updatePageForNonEmptyReport = function() {
    var paginationState = jQuery("#paginationIndexHolder");
    if (paginationState && paginationState.length > 0) {
        var lastPageIndex = paginationState.attr("data-lastPageIndex");
        jQuery("#emptyReportID").addClass('hidden');

        if (lastPageIndex === "0") {
            jQuery("#pagination").addClass('hidden');
        } else {
            jQuery("#pagination").removeClass('hidden');
        }
    }
}

Report.updatePageForEmptyReport = function() {
    var emptyReportState = jQuery("#emptyReportMessageHolder");
    if (emptyReportState && emptyReportState.length > 0) {
        var emptyReportMessage = emptyReportState.html();

        jQuery("#pagination").addClass('hidden');
        jQuery(jQuery("#emptyReportID p.message")[1]).html(emptyReportMessage);
        jQuery("#emptyReportID").removeClass('hidden');
        centerElement(jQuery("#emptyReportID"), {horz: true, vert: true});
    }
}

Report.reportRefreshed = function() {
    Report.reportRunning = true;
    Report.asyncCanceled = false;
    Report.snapshotSaveStatus = null;
    Report.initUpdateCheckDelay();
	Report.reportPageRefreshed();
}

Report.refreshAsyncCancel = function() {
    if ($('asyncCancel')) {
        if (!this.reportDone() && !Report.asyncCanceled && this.jasperPrintName) {
            buttonManager.enable('asyncCancel');
        	$('asyncIndicator').removeClassName(layoutModule.HIDDEN_CLASS);
        } else {
        	$('asyncIndicator').addClassName(layoutModule.HIDDEN_CLASS);
            buttonManager.disable('asyncCancel');
        }
    }
}

Report.exportReport = function(type, formAction) {
    var exportForm = Report.exportForm;

    jQuery(exportForm).empty();

    exportForm.method = "post";
    exportForm.target='_blank';

    var genericParams = {
        _eventId: "export",
        _flowExecutionKey: Report.reportExecutionKey(),
        output: "" + type
    };
    var postData = _.extend(genericParams, Controls.viewModel.get('selection'));

    addDataToForm(exportForm, postData);

    var timeoutForm = "Report.exportForm.target='_self';";
    if (formAction)
    {
        timeoutForm += "Report.exportForm.action='" + exportForm.action + "';";
        exportForm.action = formAction;
    }
    setTimeout(timeoutForm, 500);

    exportForm.submit();
}

Report.goBack = function() {
	if (!Report.confirmExit()) {
		return;
	}

    // disable back button after first click
    buttonManager.disable($('back'));

    // exportForm is used here to leave the page
    Report.exportForm._eventId.value = "close";
    Report.exportForm._flowExecutionKey.value = Report.reportExecutionKey();
    Report.exportForm.submit();
}

Report.open = function() {
    alert("Not implemented yet: open report")
}

Report.save = function() {
    alert("Report saving is not available in community edition");
}

Report.saveAs = function() {
    alert("Report saving is not available in community edition");
}

Report.undo = function() {
	jasperreports.reportviewertoolbar.undo();
}

Report.redo = function() {
	jasperreports.reportviewertoolbar.redo();
}

Report.undoAll = function() {
	jasperreports.reportviewertoolbar.undoAll();
}

document.observe('dom:loaded', Report.initialize.bind(Report));

