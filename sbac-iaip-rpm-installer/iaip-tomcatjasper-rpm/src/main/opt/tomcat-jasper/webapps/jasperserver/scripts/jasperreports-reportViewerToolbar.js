/**
 * Defines 'viewertoolbar' module  in jasperreports namespace
 */
(function(global) {
	if (typeof global.jasperreports.reportviewertoolbar !== 'undefined') {
		return;
	}
	
	var jvt = {
				stateStack: {
					counter: 0,
					states: new Array(),
					position: -1
				},
				PARAM_ACTION: 'jr.action'
	};
	
	jvt.stateStack.newState = function() {
		if (this.position + 2 < this.states.length) {
			this.states.splice(this.position + 2, this.states.length - this.position - 2);
		}
		
		++this.position;
		++this.counter;
		this.states[this.position] = this.counter;
	}
	
	jvt.stateStack.prevState = function() {
		if (this.position > 0) {
			--this.position;
		}
	}
	
	jvt.stateStack.firstState = function() {
		this.position = 0;
	}
	
	jvt.stateStack.nextState = function() {
		if (this.position + 1 < this.states.length) {
			++this.position;
		}
	}
	
	jvt.stateStack.hasPrevious = function() {
		return this.position > 0;
	}
	
	jvt.stateStack.hasNext = function() {
		return this.position + 1 < this.states.length;
	}
	
	jvt.stateStack.currentState = function() {
		return this.states[this.position];
	}
	
	jvt.currentState = function() {
		return jvt.stateStack.currentState();
	}
	
	jvt.performAction = function () {
		jvt.stateStack.newState();
		
		buttonManager.enable($('undo'));
		buttonManager.enable($('undoAll'));

		buttonManager.disable($('redo'));
	};
	
	jvt.performUndo = function () {
		jvt.stateStack.prevState();
		
		buttonManager.enable($('redo'));
		
		if (!jvt.stateStack.hasPrevious()) {
			buttonManager.disable($('undo'));
			buttonManager.disable($('undoAll'));
		}
	};

	jvt.performUndoAll = function () {
		jvt.stateStack.firstState();
		
		buttonManager.enable($('redo'));
		
		buttonManager.disable($('undo'));
		buttonManager.disable($('undoAll'));
	};
	
	jvt.performRedo = function () {
		jvt.stateStack.nextState();
		
		buttonManager.enable($('undo'));
		buttonManager.enable($('undoAll'));
		
		if (!jvt.stateStack.hasNext()) {
			buttonManager.disable($('redo'));
		}
	};

	jvt.runReport = function(selectedColumn, actionData, callback, arrCallbackArgs, isJSON) {
		var	gm = global.jasperreports.global,
			params = selectedColumn.actionBaseData,
			callback = callback || jvt.performAction,
			arrCallbackArgs = arrCallbackArgs || [];
		
		if (typeof actionData === 'object') {
			actionData = gm.toJsonString(actionData);
		}
		
		params[jvt.PARAM_ACTION] = actionData;
		
		
		var options = {
				callback: function() {
					Report.reportRefreshed();
					if (callback) {
						callback.apply(null, arrCallbackArgs);
					}
				}
		};
		
		Report.rerunReport(params, options);
	};
	
	jvt.undo = function() {
		jive.runAction({actionName: "undo"}, null, jvt.performUndo);
	};
	
	jvt.redo = function() {
		jive.runAction({actionName: "redo"}, null, jvt.performRedo);
	};
	
	jvt.undoAll = function() {
		jive.runAction({actionName: "undoAll"}, null, jvt.performUndoAll);
	};
	
	// add an initial state
	jvt.stateStack.newState();

	global.jasperreports.reportviewertoolbar = jvt;
	
} (this));
