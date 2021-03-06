eongApplication = function(width, height, appletName, id, eongobj, debug,
		loadUI, noConflict) {
	this.noConflict = noConflict;
	if (noConflict === undefined || noConflict) {
		jQuery.noConflict();
	}
	var devLoad = false;
	if (debug === undefined || !debug) {
		relPath = getRelativePath();
		if (loadUI === undefined || loadUI) {
			jQuery.ajax({
				url : relPath + "jquery/jquery-ui.min.js",
				async : false,
				dataType : "script"
			});
		}
		jQuery.ajax({
			url : relPath + "jquery/ui.romenu.js",
			async : false,
			dataType : "script"
		});
		jQuery.ajax({
			url : relPath + "jquery/jquery.layout.min.js",
			async : false,
			dataType : "script"
		});
		jQuery.ajax({
			url : relPath + "jquery/eong-plugins.js",
			async : false,
			dataType : "script"
		});
		if (devLoad) {
			jQuery.ajax({
				url : relPath + "Helper.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "Action.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "Logger.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "Toolbar.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "Ruler.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "RulerController.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "DOMElements.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "CustomJSActions.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "ActionMap.js",
				async : false,
				dataType : "script"
			});
			jQuery.ajax({
				url : relPath + "DialogMap.js",
				async : false,
				dataType : "script"
			});
		}
	}
	this.Helper = new eongApplication.Helper(width, height, appletName, id,
			eongobj, this);
	this.Helper.getOSInfo();
	this.Logger = new eongApplication.Logger(this.Helper);
	this.DOMElements = new eongApplication.DOMElements(this.Helper, this.Logger);
	this.CustomJSActions = new eongApplication.customJSActions(this);
	this.ActionMap = new eongApplication.actionMap();
	this.DialogMap = new eongApplication.dialogMap();
	this.RulerController = new RulerController(this);
	this.toolkitInternal = new eongApplication.ToolkitInternal(this);
	this.locale = this.Helper;
	this.config;
	this.methodQueue = [];
	this.Logger.log("eongApplication instance initialized", "INFO", this);
	this.startFullscreen = function(fullscreen) {
		this.Helper.isStartFullscreen = fullscreen;
	}
	this.loadEditor = function() {
		this.Logger.log("[loadEditor]: Started", "FINER", this);
		this.Logger.log("[loadEditor]: Getting OS info", "FINEST", this);
		this.Helper.getOSInfo();
		if (this.isMSIE) {
			this.Helper.setParam("REPLACEIMAGESIZE", "30000");
		} else {
			this.Helper.setParam("REPLACEIMAGESIZE", "500000");
		}
		this.Logger.log("[loadEditor]: setting locale object in Helper",
				"FINEST", this);
		this.Helper.setLocaleObject();
		this.Logger.log("[loadEditor]: setting locale object as PARAM",
				"FINEST", this);
		json = jQuery.toJSON(this.Helper.LocaleObject);
		json = json.replace(/\r/g, '');
		json = json.replace(/\n/g, '');
		json = json.replace(/\t/g, '');
		json = this.Helper.escapeSingleQuotes(json);
		this.Helper.setParam("LOCALE", json);
		this.Logger.log("[loadEditor]: setting action map", "FINEST", this);
		this.Helper.setActionMap();
		this.Helper.setDialogMap();
		this.Logger.log("[loadEditor]: setting archive", "FINEST", this);
		this.Helper.setParam('archive', this.Helper.archive);
		this.Helper.setParam("progressbar", "true");
		this.Helper.setParam("boxmessage", "");
		this.Logger.log("[loadEditor]: assembling DOM", "FINEST", this);
		var tmpWidth = String(this.Helper.editorWidth);
		if (tmpWidth.indexOf("%") != -1) {
			this.Helper.editorWidth = tmpWidth.replace(/%/g, "");
			var widthProportion = parseInt(this.Helper.editorWidth) / 100;
			var parentWidth = jQuery("#" + this.Helper.containerId).parent()
					.width();
			this.Helper.editorWidth = parseInt(parentWidth * widthProportion);
			this.Helper.containerWidth = parseInt(parentWidth * widthProportion);
		}
		var tmpHeight = String(this.Helper.editorHeight);
		if (tmpHeight.indexOf("%") != -1) {
			this.Helper.editorHeight = tmpHeight.replace(/%/g, "");
			var heightProportion = parseInt(this.Helper.editorHeight) / 100;
			var parentHeight = jQuery("#" + this.Helper.containerId).parent()
					.height();
			this.Helper.editorHeight = parseInt(parentHeight * heightProportion);
			this.Helper.containerHeight = parseInt(parentHeight
					* heightProportion);
		}
		this.DOMElements.assembleDOM();
		this.Logger.log("[loadEditor]: Finished", "FINER", this);
	};
	this.preloadJVM = function() {
		this.Helper.code = "com.realobjects.preloadJvm";
		this.Helper.archive = "preload.jar";
		this.Helper.setParam('archive', this.Helper.archive);
		this.DOMElements.assembleDOMPreload();
	};
	this.addArchive = function(sArc, sVer) {
		this.Logger.log("[addArchive]: Started", "FINER", this);
		this.Logger
				.log("[addArchive]: Adding archive: " + sArc, "CONFIG", this);
		try {
			this.Helper.archive = this.Helper.archive + ", " + sArc;
		} catch (err) {
			this.Logger.log("[addArchive]: Failed to add archive", "SEVERE",
					this);
		}
		this.Logger.log("[addArchive]: Finished", "FINER", this);
	};
	this.addEmbeddedStyles = function(styles) {
		this.Logger.log("[addEmbeddedStyles]: Started", "FINER", this);
		this.Logger.log("[addEmbeddedStyles]: Adding embedded styles: "
				+ styles, "FINEST", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().addEmbeddedStyles(styles);
			} else {
				this.delayMethodCall("addEmbeddedStyles", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[addEmbeddedStyles]: Failed to add embedded styles: "
							+ styles + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[addEmbeddedStyles]: Finished", "FINER", this);
	};
	this.addUserAgentStyles = function() {
		this.Logger.log("[addUserAgentStyles]: Started", "FINER", this);
		try {
			json = {};
			json.content = arguments[0];
			if (arguments.length == 3) {
				json.media = arguments[1];
				json.title = arguments[2];
			}
			this.Logger.log("[addUserAgentStyles]: Adding user agent styles: "
					+ json, "FINE", this);
			json = jQuery.toJSON(json);
			if (this.Helper.initialized) {
				this.getObj().addUserAgentStyles(json);
			} else {
				this.delayMethodCall("addUserAgentStyles", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[addUserAgentStyles]: Failed adding user agent styles: "
							+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[addUserAgentStyles]: Finished", "FINER", this);
	};
	this.addUserAgentStylesFromURL = function() {
		this.Logger.log("[addUserAgentStylesFromURL]: Started", "FINER", this);
		try {
			json = {};
			json.href = arguments[0];
			if (arguments.length == 3) {
				json.media = arguments[1];
				json.title = arguments[2];
			}
			this.Logger.log(
					"[addUserAgentStylesFromURL]: Adding user agent styles: "
							+ json, "FINE", this);
			json = jQuery.toJSON(json);
			if (this.Helper.initialized) {
				this.getObj().addUserAgentStyles(json);
			} else {
				this.delayMethodCall("addUserAgentStylesFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[addUserAgentStylesFromURL]: Failed adding user agent styles: "
							+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[addUserAgentStylesFromURL]: Finished", "FINER", this);
	};
	this.addUserStyles = function() {
		this.Logger.log("[addUserStyles]: Started", "FINER", this);
		try {
			json = {};
			json.content = arguments[0];
			if (arguments.length == 3) {
				json.media = arguments[1];
				json.title = arguments[2];
			}
			this.Logger.log("[addUserStyles]: Adding user styles: " + json,
					"FINE", this);
			json = jQuery.toJSON(json);
			if (this.Helper.initialized) {
				this.getObj().addUserStyles(json);
			} else {
				this.delayMethodCall("addUserStyles", arguments);
			}
		} catch (err) {
			this.Logger.log("[addUserStyles]: Failed adding user styles: "
					+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[addUserStyles]: Finished", "FINER", this);
	};
	this.addUserStylesFromURL = function() {
		this.Logger.log("[addUserStylesFromURL]: Started", "FINER", this);
		try {
			json = {};
			json.href = arguments[0];
			if (arguments.length == 3) {
				json.media = arguments[1];
				json.title = arguments[2];
			}
			this.Logger.log("[addUserStylesFromURL]: Adding user styles: "
					+ json, "FINE", this);
			json = jQuery.toJSON(json);
			if (this.Helper.initialized) {
				this.getObj().addUserStyles(json);
			} else {
				this.delayMethodCall("addUserStylesFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[addUserStylesFromURL]: Failed adding user styles: "
							+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[addUserStylesFromURL]: Finished", "FINER", this);
	};
	this.setHeaderFooterEditorStyleURL = function() {
		this.Logger.log("[setHeaderFooterEditorStyleURL]: Started", "FINER",
				this);
		try {
			this.CustomJSActions.headerFooterStyleURL = arguments[0];
		} catch (err) {
			this.Logger.log(
					"[setHeaderFooterEditorStyleURL]: Failed setting header fotter editor styles: "
							+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setHeaderFooterEditorStyleURL]: Finished", "FINER",
				this);
	};
	this.clear = function() {
		this.Logger.log("[clear]: Started", "FINER", this);
		this.invokeAction("new-document", null);
		this.Logger.log("[clear]: Started", "FINER", this);
	};
	this.clearUserPreferences = function() {
		this.Logger.log("[clearUserPreferences]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.Helper.clearUserPreferences();
			} else {
				this.delayMethodCall("clearUserPreferences", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[clearUserPreferences]: Failed to clear user preferences with "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[clearUserPreferences]: Finished", "FINER", this);
	};
	this.clearUserAgentStyles = function() {
		this.Logger.log("[clearUserAgentStyles]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().clearUserAgentStyles();
			} else {
				this.delayMethodCall("clearUserAgentStyles", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[clearUserAgentStyles]: Failed to clear user agent styles with "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[clearUserAgentStyles]: Finished", "FINER", this);
	};
	this.clearUserStyles = function() {
		this.Logger.log("[clearUserStyles]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().clearUserStyles();
			} else {
				this.delayMethodCall("clearUserStyles", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[clearUserStyles]: Failed to clear user styles with "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[clearUserStyles]: Finished", "FINER", this);
	};
	this.compareDocumentsFromURL = function(uriOldDoc, uriNewDoc, sBaseURL) {
		this.Logger.log("[compareDocumentsFromURL]: Started", "FINER", this);
		this.Logger.log("[compareDocumentsFromURL]: Comparing documents: "
				+ uriOldDoc + ", " + uriNewDoc, "FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().compareDocumentsFromURL(uriOldDoc, uriNewDoc);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().compareDocumentsFromURL(uriOldDoc, uriNewDoc,
							sBaseURL);
				}
			} else {
				this.delayMethodCall("compareDocumentsFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[compareDocumentsFromURL]: Failed to compare documents: "
							+ uriOldDoc + ", " + uriNewDoc + " with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[compareDocumentsFromURL]: Finished", "FINER", this);
	};
	this.compareDocumentsFromContent = function(oldDoc, newDoc, sBaseURL) {
		this.Logger
				.log("[compareDocumentsFromContent]: Started", "FINER", this);
		this.Logger.log("[compareDocumentsFromContent]: Comparing documents: "
				+ oldDoc + ", " + newDoc, "FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().compareDocumentsFromContent(oldDoc, newDoc);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().compareDocumentsFromContent(oldDoc, newDoc,
							sBaseURL);
				}
			} else {
				this.delayMethodCall("compareDocumentsFromContent", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[compareDocumentsFromContent]: Failed to compare documents: "
							+ oldDoc + ", " + newDoc + " with error: " + err,
					"SEVERE", this);
		}
		this.Logger.log("[compareDocumentsFromContent]: Finished", "FINER",
				this);
	};
	this.compareDocumentURLToEditorContent = function(uriOldDoc, sBaseURL) {
		this.Logger.log("[compareDocumentURLToEditorContent]: Started",
				"FINER", this);
		this.Logger.log(
				"[compareDocumentURLToEditorContent]: Comparing document to editor content: "
						+ uriOldDoc, "FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().compareDocumentURLToEditorContent(uriOldDoc);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().compareDocumentURLToEditorContent(uriOldDoc,
							sBaseURL);
				}
			} else {
				this.delayMethodCall("compareDocumentURLToEditorContent",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[compareDocumentURLToEditorContent]: Failed to compare documents: "
									+ uriOldDoc + " with error: " + err,
							"SEVERE", this);
		}
		this.Logger.log("[compareDocumentURLToEditorContent]: Finished",
				"FINER", this);
	};
	this.compareDocumentContentToEditorContent = function(oldDoc, sBaseURL) {
		this.Logger.log("[compareDocumentContentToEditorContent]: Started",
				"FINER", this);
		this.Logger
				.log(
						"[compareDocumentContentToEditorContent]: Comparing document content to editor content: "
								+ oldDoc, "FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().compareDocumentContentToEditorContent(oldDoc);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().compareDocumentContentToEditorContent(oldDoc,
							sBaseURL);
				}
			} else {
				this.delayMethodCall("compareDocumentContentToEditorContent",
						arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[compareDocumentContentToEditorContent]: Failed to compare documents: "
							+ oldDoc + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[compareDocumentContentToEditorContent]: Finished",
				"FINER", this);
	};
	this.importLegacyDocument = function(content, sBaseURL) {
		this.Logger.log("[importLegacyDocument]: Started", "FINER", this);
		this.Logger.log("[importLegacyDocument]: Importing document: "
				+ content, "FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().importLegacyDocument(content);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().importLegacyDocument(content, sBaseURL);
				}
			} else {
				this.delayMethodCall("importLegacyDocument", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[importLegacyDocument]: Failed to import document: "
							+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[importLegacyDocument]: Finished", "FINER", this);
	};
	this.importLegacyDocumentFromURL = function(sURL, sBaseURL) {
		this.Logger
				.log("[importLegacyDocumentFromURL]: Started", "FINER", this);
		try {
			this.Logger.log(
					"[importLegacyDocumentFromURL]: Importing document from URL:"
							+ sURL, "FINE", this);
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().importLegacyDocumentFromURL(sURL);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().importLegacyDocumentFromURL(sURL, sBaseURL);
				}
			} else {
				this.delayMethodCall("importLegacyDocumentFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[importLegacyDocumentFromURL]: Failed to import legacy document from URL: "
							+ sURL + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[importDocumentFromURL]: Finished", "FINER", this);
	};
	this.insertContent = function(content) {
		this.Logger.log("[insertContent]: Started", "FINER", this);
		this.Logger.log("[insertContent]: Inserting content: " + content,
				"FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().insertContent(content);
			} else {
				this.delayMethodCall("insertContent", arguments);
			}
		} catch (err) {
			this.Logger.log("[insertContent]: Failed to insert content: "
					+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[insertContent]: Finished", "FINER", this);
	};
	this.insertAnnotation = function(annotation) {
		this.Logger.log("[insertAnnotation]: Started", "FINER", this);
		this.Logger.log("[insertAnnotation]: Inserting annotation: "
				+ annotation, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.invokeAction("insert-annotation", annotation);
			} else {
				this.delayMethodCall("insertAnnotation", arguments);
			}
		} catch (err) {
			this.Logger.log("[insertAnnotation]: Failed to insert annotation: "
					+ annotation + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[insertAnnotation]: Finished", "FINER", this);
	};
	this.insertImage = function(source, alt, width, height, border, widthUnit,
			heightUnit, borderWidthUnit) {
		this.Logger.log("[insertImage]: Started", "FINER", this);
		this.Logger.log("[insertImage]: Inserting image: " + source + ", "
				+ width + ", " + height + ", " + border + ", " + alt, "FINE",
				this);
		try {
			if (this.Helper.initialized) {
				var params = {};
				if (source !== undefined && alt !== undefined) {
					params["imageSource"] = source;
					params["imageAlt"] = alt;
					if (width !== undefined)
						params["imageWidth"] = width;
					if (height !== undefined)
						params["imageHeight"] = height;
					if (border !== undefined)
						params["imageBorderWidth"] = border;
					if (borderWidthUnit !== undefined)
						params["imageBorderWidthUnit"] = borderWidthUnit;
					if (widthUnit !== undefined)
						params["imageWidthUnit"] = widthUnit;
					if (heightUnit !== undefined)
						params["imageHeightUnit"] = heightUnit;
					this.invokeAction("insert-image", jQuery.toJSON(params));
				} else {
					this.Logger
							.log(
									"[insertImage]: Failed to insert image: \"source\" or \"alt\" argument missing.",
									"WARNING", this);
				}
			} else {
				this.delayMethodCall("insertImage", arguments);
			}
		} catch (err) {
			this.Logger.log("[insertImage]: Failed to insert image: " + width
					+ ", " + height + ", " + border + ", " + alt
					+ " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[insertImage]: Finished", "FINER", this);
	};
	this.insertContentFromURL = function(url) {
		this.Logger.log("[insertContentFromURL]: Started", "FINER", this);
		this.Logger.log("[insertContentFromURL]: Inserting URL: " + url,
				"FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().insertContentFromURL(url);
			} else {
				this.delayMethodCall("insertContentFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log("[insertContentFromURL]: Failed to insert URL: "
					+ url + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[insertContentFromURL]: Finished", "FINER", this);
	};
	this.invokeAction = function(actionConst, actionCommand) {
		this.Logger.log("[invokeAction]: Started", "FINER", this);
		try {
			this.Logger.log("[invokeAction]: invokeAction (" + actionConst
					+ ", " + actionCommand + ")", "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().invokeAction(actionConst, actionCommand);
			} else {
				this.delayMethodCall("invokeAction", arguments);
			}
		} catch (err) {
			this.Logger.log("[invokeAction]: Failed to execute invokeAction ("
					+ actionConst + ", " + actionCommand + ") with error: "
					+ err, "SEVERE", this);
		}
		this.Logger.log("[invokeAction]: Finished", "FINER", this);
	};
	this.loadDocument = function(content, sBaseURL) {
		this.Logger.log("[loadDocument]: Started", "FINER", this);
		this.Logger.log("[loadDocument]: Setting document to: " + content,
				"FINE", this);
		try {
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().loadDocument(content);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().loadDocument(content, sBaseURL);
				}
			} else {
				this.delayMethodCall("loadDocument", arguments);
			}
		} catch (err) {
			this.Logger.log("[loadDocument]: Failed to set document to: "
					+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[loadDocument]: Finished", "FINER", this);
	};
	this.loadDocumentFromURL = function(sURL, sBaseURL) {
		this.Logger.log("[loadDocumentFromURL]: Started", "FINER", this);
		try {
			this.Logger.log("[loadDocumentFromURL]: Loading document from URL:"
					+ sURL, "FINE", this);
			if (this.Helper.initialized) {
				if (sBaseURL === undefined) {
					this.getObj().loadDocumentFromURL(sURL);
				} else {
					if (sBaseURL === "")
						sBaseURL = null;
					this.getObj().loadDocumentFromURL(sURL, sBaseURL);
				}
			} else {
				this.delayMethodCall("loadDocumentFromURL", arguments);
			}
		} catch (err) {
			this.Logger.log("[loadDocumentFromURL]: Failed to load URL: "
					+ sURL + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[loadDocumentFromURL]: Finished", "FINER", this);
	};
	this.loadContextMenuStyleSheet = function(path) {
		this.Logger.log("[loadContextMenuStyleSheet]: Started", "FINER", this);
		this.Helper.setParam("CONTEXTMENUSTYLESHEET", path);
		this.Logger.log("[loadContextMenuStyleSheet]: Finished", "FINER", this);
	};
	this.loadHeaderFooterPlaceholderStyleSheet = function(path) {
		this.Logger.log("[loadHeaderFooterPlaceholderStyleSheet]: Started",
				"FINER", this);
		this.Helper.setParam("HEADERFOOTERPLACEHOLDERSTYLESHEET", path);
		this.Logger.log("[loadHeaderFooterPlaceholderStyleSheet]: Finished",
				"FINER", this);
	};
	this.loadCrossReferencesStyleSheet = function(path) {
		this.Logger.log("[loadCrossReferencesStyleSheet]: Started", "FINER",
				this);
		this.Helper.setParam("CROSSREFERENCESSTYLESHEET", path);
		this.Logger.log("[loadCrossReferencesStyleSheet]: Finished", "FINER",
				this);
	};
	this.loadInplaceToolbarStyleSheet = function(path) {
		this.Logger.log("[loadInplaceToolbarStyleSheet]: Started", "FINER",
				this);
		this.Helper.setParam("INPLACETOOLBARSTYLESHEET", path);
		this.Logger.log("[loadInplaceToolbarStyleSheet]: Finished", "FINER",
				this);
	};
	this.loadInplaceToolbarIcons = function(path) {
		this.Logger.log("[loadInplaceToolbarIcon]: Started", "FINER", this);
		this.loadCustomJavaIcons(path);
		this.Logger.log("[loadInplaceToolbarIcon]: Finished", "FINER", this);
	};
	this.loadCustomJavaIcons = function(path) {
		this.Logger.log("[loadCustomJavaIcons]: Started", "FINER", this);
		this.Helper.setParam("CUSTOMJAVAICON", path);
		this.Logger.log("[loadCustomJavaIcons]: Finished", "FINER", this);
	};
	this.moveToBookmark = function(bookmarkName) {
		this.Logger.log("[moveToBookmark]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveToBookmark(bookmarkName);
			} else {
				this.delayMethodCall("moveToBookmark", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveToBookmark]: Failed to select bookmark with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveToBookmark]: Finished", "FINER", this);
	};
	this.moveToNextBookmark = function() {
		this.Logger.log("[moveToNextBookmark]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveToNextBookmark();
			} else {
				this.delayMethodCall("moveToNextBookmark", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveToNextBookmark]: Failed to select next bookmark with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveToNextBookmark]: Finished", "FINER", this);
	};
	this.moveToPreviousBookmark = function() {
		this.Logger.log("[moveToPreviousBookmark]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveToPreviousBookmark();
			} else {
				this.delayMethodCall("moveToPreviousBookmark", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveToPreviousBookmark]: Failed to select previous bookmark with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveToPreviousBookmark]: Finished", "FINER", this);
	};
	this.moveCaret = function() {
		var expression = arguments[0];
		var end = arguments[1] === undefined ? false : arguments[1];
		var dismissSelection = arguments[2] === undefined ? false
				: arguments[2];
		this.Logger.log("[moveCaret]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				return this.getObj().moveCaret(expression, end,
						dismissSelection);
			} else {
				this.delayMethodCall("moveCaret", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveCaret]: Failed to move caret to the specified position with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaret]: Finished", "FINER", this);
	}
	this.moveCaretToDocumentEnd = function() {
		this.Logger.log("[moveCaretToDocumentEnd]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToDocumentEnd();
			} else {
				this.delayMethodCall("moveCaretToDocumentEnd", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveCaretToDocumentEnd]: Failed to move caret to document end with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToDocumentEnd]: Finished", "FINER", this);
	};
	this.moveCaretToDocumentStart = function() {
		this.Logger.log("[moveCaretToDocumentStart]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToDocumentStart();
			} else {
				this.delayMethodCall("moveCaretToDocumentStart", arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[moveCaretToDocumentStart]: Failed to move caret to document start with error "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToDocumentStart]: Finished", "FINER", this);
	};
	this.moveCaretToNextBlock = function() {
		this.Logger.log("[moveCaretToNextBlock]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToNextBlock();
			} else {
				this.delayMethodCall("moveCaretToNextBlock", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveCaretToNextBlock]: Failed to move caret to next block with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToNextBlock]: Finished", "FINER", this);
	};
	this.moveCaretToNextPage = function() {
		this.Logger.log("[moveCaretToNextPage]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToNextPage();
			} else {
				this.delayMethodCall("moveCaretToNextPage", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveCaretToNextPage]: Failed to move caret to next page with error "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToNextPage]: Finished", "FINER", this);
	};
	this.moveCaretToPreviousBlock = function() {
		this.Logger.log("[moveCaretToPreviousBlock]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToPreviousBlock();
			} else {
				this.delayMethodCall("moveCaretToPreviousBlock", arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[moveCaretToPreviousBlock]: Failed to move caret to previous block with error "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToPreviousBlock]: Finished", "FINER", this);
	};
	this.moveCaretToPreviousPage = function() {
		this.Logger.log("[moveCaretToPreviousPage]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().moveCaretToPreviousPage();
			} else {
				this.delayMethodCall("moveCaretToPreviousPage", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[moveCaretToPreviousPage]: Failed to move caret to previous page with error "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[moveCaretToPreviousPage]: Finished", "FINER", this);
	};
	this.requestFocus = function() {
		this.Logger.log("[requestFocus]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().requestFocus();
			} else {
				this.delayMethodCall("requestFocus", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[requestFocus]: Failed to request focus with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[requestFocus]: Finished", "FINER", this);
	}
	this.registerEventHandler = function(eventHandler, jsFunc) {
		this.Logger.log("[registerEventHandler]: Started", "FINER", this);
		this.Helper.setParam(eventHandler, jsFunc);
		this.Logger.log("[registerEventHandler]: Finished", "FINER", this);
	}
	this.removeCurrentTableColumnCellAttributes = function() {
		this.Logger.log("[removeCurrentTableColumnCellAttributes]: Started",
				"FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().removeCurrentTableColumnCellAttributes();
			} else {
				this.delayMethodCall("removeCurrentTableColumnCellAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[removeCurrentTableColumnCellAttributes]: Failed to remove cell attributes (table column) with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[removeCurrentTableColumnCellAttributes]: Finished",
				"FINER", this);
	};
	this.removeCurrentTableRowCellAttributes = function() {
		this.Logger.log("[removeCurrentTableRowCellAttributes]: Started",
				"FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().removeCurrentTableRowCellAttributes();
			} else {
				this.delayMethodCall("removeCurrentTableRowCellAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[removeCurrentTableRowCellAttributes]: Failed to remove cell attributes (table row) with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[removeCurrentTableRowCellAttributes]: Finished",
				"FINER", this);
	};
	this.removeParentElementByNameAttributes = function(ancestorName) {
		this.Logger.log("[removeParentElementByNameAttributes]: Started",
				"FINER", this);
		this.Logger.log(
				"[removeParentElementByNameAttributes]: Remove attributes from: "
						+ ancestorName, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().removeParentElementByNameAttributes(ancestorName);
			} else {
				this.delayMethodCall("removeParentElementByNameAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[removeParentElementByNameAttributes]: Failed to remove attributes from: "
							+ ancestorName + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[removeParentElementByNameAttributes]: Finished",
				"FINER", this);
	};
	this.setArchive = function(archive) {
		this.Helper.archive = archive;
	};
	this.setDefaultBaseURL = function(defaultBaseURL) {
		this.Logger.log("[setDefaultBaseURL]: Started", "FINER", this);
		if (!this.Helper.initialized) {
			this.Logger
					.log(
							"[setDefaultBaseURL]: Editor not initialized, setting defaultBaseURL as PARAM",
							"CONFIG", this);
			this.Helper.setParam("DEFAULTBASEURL", defaultBaseURL);
		} else {
			try {
				this.Logger.log("[setDefaultBaseURL]: Setting defaultBaseURL: "
						+ defaultBaseURL, "CONFIG", this);
				this.getObj().setDefaultBaseURL(defaultBaseURL);
			} catch (err) {
				this.Logger.log(
						"[setDefaultBaseURL]: Failed to set defaultBaseURL URL: "
								+ defaultBaseURL + " with error: " + err,
						"SEVERE", this);
			}
			this.Logger.log("[setDefaultBaseURL]: Finished", "FINER", this);
		}
	};
	this.setBlockElementAttributes = function(attributes) {
		this.Logger.log("[setBlockElementAttributes]: Started", "FINER", this);
		try {
			json = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setBlockElementAttributes]: Setting block element attributes: "
							+ json, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setBlockElementAttributes(json);
			} else {
				this.delayMethodCall("setBlockElementAttributes", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setBlockElementAttributes]: Failed setting block element attributes: "
							+ json + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setBlockElementAttributes]: Finished", "FINER", this);
	};
	this.setBodyFragment = function(content) {
		this.Logger.log("[setBodyFragment]: Started", "FINER", this);
		this.Logger.log("[setBodyFragment]: Setting body content to: "
				+ content, "FINER", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setBodyFragment(content);
			} else {
				this.delayMethodCall("setBodyFragment", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setBodyFragment]: Failed to set body content to: "
							+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setBodyFragment]: Finished", "FINER", this);
	};
	this.setCodebase = function(sCodebase) {
		this.Logger.log("[setCodeBase]: Started", "FINER", this);
		try {
			codebase = this.Helper.resolveURLAgainstDocBase(sCodebase, true)
			this.Logger.log("[setCodeBase]: Setting code base: " + codebase
					+ "   ( " + sCodebase + " )", "CONFIG", this);
			this.Helper.codebase = codebase;
		} catch (err) {
			this.Logger.log("[setCodeBase]: Failed to set code base: "
					+ sCodebase + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setCodeBase]: Finished", "FINER", this);
	};
	this.setConfig = function(jsonString) {
		this.Logger.log("[setConfig]: Started", "FINER", this);
		try {
			this.Logger.log("[setConfig]: Setting config from JSON string: "
					+ jsonString, "CONFIG", this);
			jsonString = this.Helper.checkConfig(jsonString);
			json = jsonString.replace(/\r/g, '');
			json = json.replace(/\n/g, '');
			json = json.replace(/\t/g, '');
			json = this.Helper.escapeSingleQuotes(json);
			this.Helper.setParam("CONFIG", json);
			this.Helper.config = jQuery.secureEvalJSON(jsonString);
			this.config = this.Helper.config;
		} catch (err) {
			this.Logger.log(
					"[setConfig]: Failed to set config from JSON string: "
							+ jsonString + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[setConfig]: Finished", "FINER", this);
	};
	this.setConfigURL = function(configURL) {
		configURL = this.Helper.resolveURL(configURL);
		this.Logger.log("[setConfigURL]: Started", "FINER", this);
		try {
			this.Logger.log("[setConfigURL]: Setting config URL " + configURL,
					"CONFIG", this);
			var jsObj = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : configURL,
				success : function(json) {
					try {
						json = jsObj.Helper.checkConfig(json);
						json = json.replace(/\r/g, '');
						json = json.replace(/\n/g, '');
						json = json.replace(/\t/g, '');
						json = jsObj.Helper.escapeSingleQuotes(json);
						jsObj.Helper.setParam("CONFIG", json);
						jsObj.Helper.config = jQuery.secureEvalJSON(json);
						jsObj.config = jsObj.Helper.config;
					} catch (err) {
						jsObj.Logger.log(
								"[setConfigURL]: Failed to set the config URL: "
										+ configURL + " with error: " + err,
								"SEVERE", this);
					}
				},
				error : function(errormsg) {
					jsObj.Logger.log(
							"[setConfigURL]: Failed to load config from: "
									+ configURL + " with error: " + errormsg,
							"SEVERE", this);
				}
			});
		} catch (err) {
			this.Logger.log("[setConfigURL]: Failed to set the config URL: "
					+ configURL + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setConfigURL]: Finished", "FINER", this);
	};
	this.setContentCaching = function(cacheStatus) {
		this.Logger.log("[setContentCaching]: Started", "FINER", this);
		if (cacheStatus) {
			try {
				if (this.Helper.initialized) {
					this.getObj().setContentCacheKey(
							this.Helper.generateKey("cache_contents_"));
				} else {
					this.delayMethodCall("setContentCaching", arguments);
					this.Helper.setParam("CONTENTCACHING", cacheStatus);
				}
			} catch (err) {
				this.Logger.log(
						"[setContentCaching]: Failed to activate ContentCaching with error: "
								+ err, "SEVERE", this);
			}
		}
		this.Logger.log("[setContentCaching]: Finished", "FINER", this);
	};
	this.setActionExtensionURL = function(actionExtensionURL) {
		this.Logger.log("[setActionExtensionURL]: Started", "FINER", this);
		this.Logger.log(
				"[setActionExtensionURL]: Setting action extension URL: "
						+ actionExtensionURL, "CONFIG", this);
		try {
			this.Helper.actionExtensionURL = actionExtensionURL;
		} catch (err) {
			this.Logger.log(
					"[setActionExtensionURL]: Failed to set action extension URL: "
							+ actionExtensionURL + " with error: " + err,
					"SEVERE", this);
		}
		this.Logger.log("[setActionExtensionURL]: Finished", "FINER", this);
	};
	this.setDialogExtensionURL = function(dialogExtensionURL) {
		this.Logger.log("[setDialogExtensionURL]: Started", "FINER", this);
		this.Logger.log(
				"[setDialogExtensionURL]: Setting dialog extension URL: "
						+ dialogExtensionURL, "CONFIG", this);
		try {
			this.Helper.dialogExtensionURL = dialogExtensionURL;
		} catch (err) {
			this.Logger.log(
					"[setDialogExtensionURL]: Failed to set dialog extension URL: "
							+ dialogExtensionURL + " with error: " + err,
					"SEVERE", this);
		}
		this.Logger.log("[setDialogExtensionURL]: Finished", "FINER", this);
	};
	this.addLocaleExtensionURL = function(localeCode, localeExtensionURL) {
		this.Logger.log("[addLocaleExtensionURL]: Started", "FINER", this);
		this.Logger.log(
				"[addLocaleExtensionURL]: Adding locale extension URL: "
						+ localeExtensionURL + " for locale code: "
						+ localeCode, "CONFIG", this);
		try {
			this.Helper.localeExtensionObject[localeCode] = localeExtensionURL;
		} catch (err) {
			this.Logger.log(
					"[addLocaleExtensionURL]: Failed to add locale extension URL: "
							+ localeExtensionURL + " for locale code "
							+ localeCode + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[addLocaleExtensionURL]: Finished", "FINER", this);
	};
	this.setUserAttributes = function() {
		this.Logger.log("[setUserAttributes]: Started", "FINER", this);
		try {
			if (!this.Helper.initialized) {
				this.Logger.log("[setUserAttributes]: Set user attributes: "
						+ arguments, "FINE", this);
				this.setParam("AUTHOR", arguments[0]);
				if (arguments.length >= 2) {
					this.setParam("UIDPREFIX", arguments[1]);
				}
			}
		} catch (err) {
			this.Logger.log(
					"[setUserAttributes]: Failed setting user attributes with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[setUserAttributes]: Finished", "FINER", this);
	};
	this.setCurrentElementContent = function(content) {
		this.Logger.log("[setCurrentElementContent]: Started", "FINER", this);
		this.Logger.log(
				"[setCurrentElementContent]: Setting current element content to: "
						+ content, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setCurrentElementContent(content);
			} else {
				this.delayMethodCall("setCurrentElementContent", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setCurrentElementContent]: Failed to set current element content to: "
							+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setCurrentElementContent]: Finished", "FINER", this);
	};
	this.setCurrentTableColumnCellAttributes = function(attributes) {
		this.Logger.log("[setCurrentTableColumnCellAttributes]: Started",
				"FINER", this);
		var cellAttributes;
		try {
			cellAttributes = jQuery.toJSON(attributes);
			this.Logger
					.log(
							"[setCurrentTableColumnCellAttributes]: Setting cell attributes (table column): "
									+ cellAttributes, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setCurrentTableColumnCellAttributes(
						cellAttributes);
			} else {
				this.delayMethodCall("setCurrentTableColumnCellAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[setCurrentTableColumnCellAttributes]: Failed to set cell attributes (table column): "
									+ cellAttributes + " with error: " + err,
							"SEVERE", this);
		}
		this.Logger.log("[setCurrentTableColumnCellAttributes]: Finished",
				"FINER", this);
	};
	this.setCurrentTableRowCellAttributes = function(attributes) {
		this.Logger.log("[setCurrentTableRowCellAttributes]: Started", "FINER",
				this);
		var cellAttributes;
		try {
			cellAttributes = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setCurrentTableRowCellAttributes]: Setting cell attributes (table row): "
							+ cellAttributes, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setCurrentTableRowCellAttributes(cellAttributes);
			} else {
				this.delayMethodCall("setCurrentTableRowCellAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[setCurrentTableRowCellAttributes]: Failed to set cell attributes (table row): "
									+ cellAttributes + " with error: " + err,
							"SEVERE", this);
		}
		this.Logger.log("[setCurrentTableRowCellAttributes]: Finished",
				"FINER", this);
	};
	this.setElementAttributes = function(attributes) {
		this.Logger.log("[setElementAttributes]: Started", "FINER", this);
		try {
			json = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setElementAttributes]: Setting element attributes: "
							+ json, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setElementAttributes(json);
			} else {
				this.delayMethodCall("setElementAttributes", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setElementAttributes]: Failed to set element attributes: "
							+ attributes + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[setElementAttributes]: Finished", "FINER", this);
	};
	this.setElementListAttributes = function() {
		var expression = arguments[0];
		var attributes = arguments[1];
		var dismissSelection = arguments[2] === undefined ? false
				: arguments[2];
		this.Logger.log("[setElementListAttributes]: Started", "FINER", this);
		try {
			var json = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setElementListAttributes]: Setting element list attributes: "
							+ json, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setElementListAttributes(expression, json,
						dismissSelection);
			} else {
				this.delayMethodCall("setElementListAttributes", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setElementListAttributes]: Failed to set element list attributes: "
							+ attributes + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[setElementListAttributes]: Finished", "FINER", this);
	}
	this.getElementListAttributes = function() {
		var expression = arguments[0];
		var dismissSelection = arguments[1] === undefined ? false
				: arguments[1];
		this.Logger.log("[getElementListAttributes]: Started", "FINER", this);
		var elements = [];
		try {
			elements = this.getObj().getElementListAttributes(expression,
					dismissSelection);
			if (elements !== "") {
				eval("elements = " + elements);
			}
		} catch (err) {
			this.Logger.log(
					"[getElementListAttributes]: Failed to element list with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getElementListAttributes]: Finished", "FINER", this);
		return elements;
	}
	this.setEmbeddedStyles = function(styles) {
		this.Logger.log("[setEmbeddedStyles]: Started", "FINER", this);
		this.Logger.log("[setEmbeddedStyles]: Setting embedded styles: "
				+ styles, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setEmbeddedStyles(styles);
			} else {
				this.delayMethodCall("setEmbeddedStyles", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setEmbeddedStyles]: Failed to set embedded styles: "
							+ styles + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setEmbeddedStyles]: Finished", "FINER", this);
	};
	this.setEnabled = function(enabled) {
		this.Logger.log("[setEnabled]: Started", "FINER", this);
		this.Logger.log("[setEnabled]: Setting enabled property: " + enabled,
				"FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setEnabled(enabled);
			} else {
				this.delayMethodCall("setEnabled", arguments);
			}
		} catch (err) {
			this.Logger.log("[setEnabled]: Failed to set enabled property: "
					+ enabled + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setEnabled]: Finished", "FINER", this);
	};
	this.setEventHandler = function(eventHandler, method) {
		this.setParam(eventHandler, method);
	}
	this.setExtensionDirectoryURL = function(directoryURL) {
		this.Logger.log("[setExtensionDirectoryURL]: Started", "FINER", this);
		this.Logger.log(
				"[setExtensionDirectoryURL]: Setting extension directory URL: "
						+ directoryURL, "CONFIG", this);
		try {
			this.Helper.extensionDirectoryURL = directoryURL;
		} catch (err) {
			this.Logger.log(
					"[setExtensionDirectoryURL]: Failed to set extension directory URL: "
							+ directoryURL + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[setExtensionDirectoryURL]: Finished", "FINER", this);
	};
	this.setHeadElementContent = function(content) {
		this.Logger.log("[setHeadElementContent]: Started", "FINER", this);
		this.Logger.log("[setHeadElementContent]: Set head element content: "
				+ content, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setHeadElementContent(content);
			} else {
				this.delayMethodCall("setHeadElementContent", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setHeadElementContent]: Failed to set head element content: "
							+ content + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setHeadElementContent]: Finished", "FINER", this);
	};
	this.setIntrusiveJSLogging = function(debug) {
		this.Helper.intrusiveJSLogging = debug;
	}
	this.setIconRepository = function(repositoryURL) {
		this.Logger.log("[setIconRepository]: Started", "FINER", this);
		this.Logger.log("[setIconRepository]: Setting icon repository: "
				+ repositoryURL, "INFO", this);
		try {
			this.Helper.iconRepositoryURL = repositoryURL;
		} catch (err) {
			this.Logger.log(
					"[setIconRepository]: Failed to set icon repository: "
							+ repositoryURL + " with error: " + err, "SEVERE",
					this);
		}
		this.Logger.log("[setIconRepository]: Finished", "FINER", this);
	};
	this.setJSLogLevel = function(logLevel) {
		this.Logger.log("[setJSLogLevel]: Started", "FINER", this);
		this.Logger.log("[setJSLogLevel]: Setting JS log level: " + logLevel,
				"CONFIG", this);
		try {
			this.Logger.setJSLogLevel(logLevel);
		} catch (err) {
			this.Logger.log("[setJSLogLevel]: Failed to set JS log level: "
					+ logLevel + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setJSLogLevel]: Finished", "FINER", this);
	};
	this.setLicenseKeyURL = function(licenseKeyURL) {
		this.Logger.log("[setLicenseKeyURL]: Started", "FINER", this);
		this.Helper.setParam("LICENSEKEY", licenseKeyURL);
		this.CustomJSActions.licenseKeyURL = licenseKeyURL;
		this.Logger.log("[setLicenseKeyURL]: Finished", "FINER", this);
	}
	this.setLocaleCode = function(localeCode) {
		this.Logger.log("[setLocaleCode]: Started", "FINER", this);
		this.Logger.log("[setLocaleCode]: Setting locale code: " + localeCode,
				"CONFIG", this);
		try {
			this.Helper.localeCode = localeCode;
		} catch (err) {
			this.Logger.log("[setLocaleCode]: Failed to set locale code: "
					+ localeCode + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setLocaleCode]: Finished", "FINER", this);
	};
	this.setLocaleURL = function(localeURL) {
		this.Logger.log("[setLocaleURL]: Started", "FINER", this);
		this.Logger.log(
				"[setLocaleURL]: Setting locale code URL: " + localeURL,
				"CONFIG", this);
		try {
			this.Helper.localeURL = localeURL;
		} catch (err) {
			this.Logger.log("[setLocaleURL]: Failed to set locale URL: "
					+ localeURL + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setLocaleURL]: Finished", "FINER", this);
	};
	this.setLogLevel = function(logLevel) {
		this.Logger.log("[setLogLevel]: Started", "FINER", this);
		this.Logger.log("[setLogLevel]: Setting Java log level: " + logLevel,
				"CONFIG", this);
		try {
			this.Helper.setParam("loglevel", logLevel);
		} catch (err) {
			this.Logger.log("[setLogLevel]: Failed to set Java log level: "
					+ logLevel + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setLogLevel]: Finished", "FINER", this);
	};
	this.setMaxMemory = function(maxMemory) {
		this.Logger.log("[setMaxMemory]: Started", "FINER", this);
		this.Logger.log("[setMaxMemory]: Setting max memory: " + maxMemory,
				"CONFIG", this);
		try {
			this.Helper.maxMemory = "-Xmx" + maxMemory + "m";
		} catch (err) {
			this.Logger.log("[setMaxMemory]: Failed to set max memory: "
					+ maxMemory + " with error: " + err, "SEVERE", this);
		}
		this.Logger.log("[setMaxMemory]: Finished", "FINER", this);
	};
	this.setPack200 = function(enablePack200) {
		this.Logger.log("[setPack200]: Started", "FINER", this);
		this.Logger.log("[setPack200]: Setting pack200: " + enablePack200,
				"CONFIG", this);
		try {
			this.Helper.enablePack200 = enablePack200;
		} catch (err) {
			this.Logger.log("[setPack200]: Failed to set pack200: "
					+ enablePack200 + " with error: " + err, "FINER", this);
		}
		this.Logger.log("[setPack200]: Finished", "FINER", this);
	};
	this.setParam = function(paramName, paramValue) {
		this.Logger.log("[setParam]: Started", "FINER", this);
		this.Logger.log("[setParam]: Setting param: " + paramName + ": "
				+ paramValue, "CONFIG", this);
		try {
			this.Helper.setParam(paramName, this.Helper
					.escapeSingleQuotes(paramValue));
		} catch (err) {
			this.Logger.log("[setParam]: Failed to set param: " + paramName
					+ ": " + paramValue + " with error: " + err, "FINER", this);
		}
		this.Logger.log("[setParam]: Finished", "FINER", this);
	};
	this.setParentElementByNameAttributes = function(ancestorName, attributes) {
		this.Logger.log("[setParentElementByNameAttributes]: Started", "FINER",
				this);
		try {
			json = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setParentElementByNameAttributes]: Setting parent element attributes: "
							+ json + " of: " + ancestorName, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setParentElementByNameAttributes(ancestorName,
						json);
			} else {
				this.delayMethodCall("setParentElementByNameAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setParentElementByNameAttributes]: Failed to set parent element attributes: "
							+ json + " on: " + ancestorName + " with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[setParentElementByNameAttributes]: Finished",
				"FINER", this);
	};
	this.setParentElementByNameContent = function(ancestorName, content) {
		this.Logger.log("[setParentElementByNameContent]: Started", "FINER",
				this);
		this.Logger.log(
				"[setParentElementByNameContent]: Setting parent element content: "
						+ content + " of: " + ancestorName, "FINE", this);
		try {
			if (this.Helper.initialized) {
				this.getObj().setParentElementByNameContent(ancestorName,
						content);
			} else {
				this
						.delayMethodCall("setParentElementByNameContent",
								arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[setParentElementByNameContent]: Failed to set parent element content: "
							+ content + " on: " + ancestorName, "SEVERE", this);
		}
		this.Logger.log("[setParentElementByNameContent]: Finished", "FINER",
				this);
	};
	this.setSelectedColumnsCellAttributes = function(attributes) {
		this.Logger.log("[setSelectedColumnsCellAttributes]: Started", "FINER",
				this);
		var cellAttributes;
		try {
			cellAttributes = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setSelectedColumnsCellAttributes]: Setting cell attributes (table column): "
							+ cellAttributes, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setSelectedColumnsCellAttributes(cellAttributes);
			} else {
				this.delayMethodCall("setSelectedColumnsCellAttributes",
						arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[setSelectedColumnsCellAttributes]: Failed to set cell attributes (table column): "
									+ cellAttributes + " with error: " + err,
							"SEVERE", this);
		}
		this.Logger.log("[setSelectedColumnsCellAttributes]: Finished",
				"FINER", this);
	};
	this.setSelectedRowsCellAttributes = function(attributes) {
		this.Logger.log("[setSelectedRowsCellAttributes]: Started", "FINER",
				this);
		var cellAttributes;
		try {
			cellAttributes = jQuery.toJSON(attributes);
			this.Logger.log(
					"[setSelectedRowsCellAttributes]: Setting cell attributes (table column): "
							+ cellAttributes, "FINE", this);
			if (this.Helper.initialized) {
				this.getObj().setSelectedRowsCellAttributes(cellAttributes);
			} else {
				this
						.delayMethodCall("setSelectedRowsCellAttributes",
								arguments);
			}
		} catch (err) {
			this.Logger
					.log(
							"[setSelectedRowsCellAttributes]: Failed to set cell attributes (table column): "
									+ cellAttributes + " with error: " + err,
							"SEVERE", this);
		}
		this.Logger.log("[setSelectedRowsCellAttributes]: Finished", "FINER",
				this);
	};
	this.setTemplate = function(template) {
		this.Logger.log("[setTemplate]: Started", "FINER", this);
		if (!this.Helper.initialized) {
			this.Logger.log(
					"[setTemplate]: Editor not initialized, setting template: "
							+ template + " as PARAM", "CONFIG", this);
			this.Helper
					.setParam("TEMPLATE", this.Helper.formatString(template));
		}
		this.Logger.log("[setTemplate]: Setting template: " + template, "FINE",
				this);
		this.Logger.log("[setTemplate]: Finished", "FINER", this);
	};
	this.setTemplateURL = function(url, baseURL) {
		this.Logger.log("[setTemplateURL]: Started", "FINER", this);
		if (!this.Helper.initialized) {
			this.Logger.log(
					"[setTemplateURL]: Editor not initialized, setting template URL: "
							+ url + " as PARAM", "CONFIG", this);
			this.Helper.setParam("TEMPLATEURL", url);
			if (baseURL !== undefined) {
				if (baseURL === null)
					baseURL = "null";
				this.Helper.setParam("TEMPLATEURLBASEURL", baseURL);
			}
		}
		this.Logger.log("[setTemplateURL]: Setting template URL: " + url,
				"FINE", this);
		this.Logger.log("[setTemplateURL]: Finished", "FINER", this);
	};
	this.setUIConfig = function(jsonString, version) {
		if (version === undefined) {
			version = 1;
		}
		this.Helper.uiVersion = version;
		this.Logger.log("[setUIConfig]: Started", "FINER", this);
		this.Logger.log("[setUIConfig]: Setting uiconfig: " + jsonString,
				"FINE", this);
		try {
			var jsonUiConfig;
			if (jsonString !== undefined && jsonString.length > 0) {
				jsonUiConfig = jQuery.secureEvalJSON(jsonString);
			} else {
				jsonUiConfig = "";
				this.Logger
						.log(
								"Could not set uiconfig: the user interface configuration passed to the editor was empty.",
								"SEVERE", this);
			}
			this.Helper.setParam("UICONFIG", "{"
					+ this.Helper.serializeJSON(jsonUiConfig) + "}");
			this.Helper.uiconfig = jsonUiConfig;
		} catch (err) {
			this.Logger.log("[setUIConfig]: Failed to set uiconfig: "
					+ jsonString + " with error: " + err, "FINER", this);
		}
		this.Logger.log("[setUIConfig]: Finished", "FINER", this);
	};
	this.setUIConfigURL = function(uiconfigURL, version) {
		if (version === undefined) {
			version = 1;
		}
		this.Helper.uiVersion = version;
		uiconfigURL = this.Helper.resolveURL(uiconfigURL);
		this.Logger.log("[setUIConfigURL]: Started", "FINER", this);
		var obj = this;
		jQuery
				.ajax({
					dataType : "text",
					async : false,
					url : uiconfigURL,
					success : function(json) {
						json = json.replace(/\r/g, '');
						json = json.replace(/\n/g, '');
						json = json.replace(/\t/g, '');
						obj.Logger.log(
								"[setUIConfigURL]: Setting uiconfig from URL: "
										+ uiconfigURL, "FINER", this);
						try {
							var jsonUiConfig;
							if (json !== undefined && json.length > 0) {
								jsonUiConfig = jQuery.secureEvalJSON(json);
							} else {
								jsonUiConfig = "";
								obj.Logger
										.log(
												"Could not set uiconfig: the user interface configuration passed to the editor was empty.",
												"SEVERE", this);
							}
							obj.Helper.setParam("UICONFIG", "{"
									+ obj.Helper.serializeJSON(jsonUiConfig)
									+ "}");
							obj.Helper.uiconfig = jsonUiConfig;
						} catch (err) {
							obj.Logger.log(
									"[setUIConfigURL]: Failed to set uiconfig from URL: "
											+ uiconfigURL + " with error: "
											+ err, "SEVERE", this);
						}
					},
					error : function(request, err, exception) {
						obj.Logger.log(
								"[setUIConfigURL]: Failed to load uiconfig from URL: "
										+ uiconfigURL + " with error: " + err,
								"SEVERE", this);
					}
				});
		this.Logger.log("[setUIConfigURL]: Finished", "FINER", this);
	};
	this.setStructureTemplateConfigURL = function(structureTemplateConfigURL) {
		structureTemplateConfigURL = this.Helper
				.resolveURL(structureTemplateConfigURL);
		this.Logger.log("[setStructureTemplateConfigURL]: Started", "FINER",
				this);
		var obj = this;
		jQuery
				.ajax({
					dataType : "text",
					async : false,
					url : structureTemplateConfigURL,
					success : function(json) {
						json = json.replace(/\r/g, '');
						json = json.replace(/\n/g, '');
						json = json.replace(/\t/g, '');
						obj.Logger.log(
								"[setStructureTemplateConfigURL]: Setting structureTemplateConfig from URL: "
										+ structureTemplateConfigURL, "FINER",
								this);
						try {
							obj.Helper.structureTemplateConfig = jQuery
									.secureEvalJSON(json);
						} catch (err) {
							obj.Logger
									.log(
											"[setStructureTemplateConfigURL]: Failed to set structureTemplateConfig from URL: "
													+ structureTemplateConfigURL
													+ " with error: " + err,
											"SEVERE", this);
						}
					},
					error : function(request, err, exception) {
						obj.Logger
								.log(
										"[setStructureTemplateConfigURL]: Failed to load structureTemplateConfig from URL: "
												+ structureTemplateConfig
												+ " with error: " + err,
										"SEVERE", this);
					}
				});
		this.Logger.log("[setStructureTemplateConfigURL]: Finished", "FINER",
				this);
	};
	this.getDocumentBaseURL = function() {
		var baseURL = "";
		this.Logger.log("[getDocumentBaseURL]: Started", "FINER", this);
		this.Logger.log("[getDocumentBaseURL]: Getting base URL", "FINE", this);
		try {
			baseURL = this.getObj().getDocumentBaseURL();
		} catch (err) {
			this.Logger.log(
					"[getDocumentBaseURL]: Failed to get document base URL with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getDocumentBaseURL]: Finished", "FINER", this);
		return String(baseURL);
	};
	this.getDefaultBaseURL = function() {
		var baseURL = "";
		this.Logger.log("[getDefaultBaseURL]: Started", "FINER", this);
		this.Logger.log("[getDefaultBaseURL]: Getting base URL", "FINE", this);
		try {
			baseURL = this.getObj().getDefaultBaseURL();
		} catch (err) {
			this.Logger.log(
					"[getDefaultBaseURL]: Failed to get default base URL with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getDefaultBaseURL]: Finished", "FINER", this);
		return String(baseURL);
	};
	this.getBlockElementAttributes = function() {
		this.Logger.log("[getBlockElementAttributes]: Started", "FINER", this);
		this.Logger
				.log(
						"[getBlockElementAttributes]: Getting block element attributes",
						"FINE", this);
		var attributes = {};
		try {
			json = this.getObj().getBlockElementAttributes();
			if (json !== "") {
				eval("var json = " + json);
				for (i = 0; i < json.length; i++) {
					key = json[i][0];
					value = json[i][1];
					attributes[key] = value;
				}
			} else {
				attributes = null;
			}
		} catch (err) {
			this.Logger
					.log(
							"[getBlockElementAttributes]: Failed to get block element attributes with error: "
									+ err, "SEVERE", this);
			attributes = null;
		}
		this.Logger.log("[getBlockElementAttributes]: Finished", "FINER", this);
		return attributes;
	};
	this.getBodyFragment = function() {
		var content = null;
		this.Logger.log("[getBodyFragment]: Started", "FINER", this);
		this.Logger.log("[getBodyFragment]: Getting document body fragment",
				"FINE", this);
		try {
			
			try{
			content = this.getObj().getBodyFragment();
			}catch(err)
			{
				if(typeof(oEdit1) != 'undefined') {
					oEdit1.setBodyFragment(document.getElementById('hdnEditor').value);
				}
			}
			if (content != "") {
				return String(content);
			}
		} catch (err) {
			this.Logger.log(
					"[getBodyFragment]: Failed to get document body fragment with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getBodyFragment]: Finished", "FINER", this);
		return content;
	};
	this.getBookmarkList = function() {
		this.Logger.log("[getBookmarkList]: Started", "FINER", this);
		this.Logger.log("[getBookmarkList]: Getting list of bookmarks", "FINE",
				this);
		try {
			bookmarkList = this.getObj().getBookmarkList();
			if (bookmarkList !== undefined && bookmarkList !== "") {
				bookmarkList = jQuery.evalJSON(bookmarkList);
			} else {
				bookmarkList = null;
			}
		} catch (err) {
			this.Logger.log(
					"[getBookmarkList]: Failed to getting list of bookmarks: "
							+ err, "SEVERE", this);
			bookmarkList = null;
		}
		this.Logger.log("[getBookmarkList]: Finished", "FINER", this);
		return bookmarkList;
	};
	this.getCaretPosition = function() {
		var caretPos = [];
		this.Logger.log("[getCaretPosition]: Started", "FINER", this);
		this.Logger.log("[getCaretPosition]: Getting caret position", "FINE",
				this);
		try {
			caretPos = this.getObj().getCaretPosition();
		} catch (err) {
			this.Logger.log(
					"[getCaretPosition]: Failed to get caret position with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getCurrentElement]: Finished", "FINER", this);
		return eval(caretPos);
	}
	this.getCurrentElement = function() {
		var element = "";
		this.Logger.log("[getCurrentElement]: Started", "FINER", this);
		this.Logger.log("[getCurrentElement]: Getting current element", "FINE",
				this);
		try {
			element = this.getObj().getCurrentElement();
		} catch (err) {
			this.Logger.log(
					"[getCurrentElement]: Failed to get current element with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getCurrentElement]: Finished", "FINER", this);
		return String(element);
	};
	this.getCurrentElementContent = function() {
		var elementContent = "";
		this.Logger.log("[getCurrentElementContent]: Started", "FINER", this);
		this.Logger.log(
				"[getCurrentElementContent]: Getting current element content",
				"FINE", this);
		try {
			elementContent = this.getObj().getCurrentElementContent();
		} catch (err) {
			this.Logger
					.log(
							"[getCurrentElementContent]: Failed to get current element content with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[getCurrentElementContent]: Finished", "FINER", this);
		return String(elementContent);
	};
	this.getCurrentTableColumnCellAttributes = function() {
		var cells = [];
		var cellAttributesJSON;
		this.Logger.log("[getCurrentTableColumnCellAttributes]: Started",
				"FINER", this);
		this.Logger
				.log(
						"[getCurrentTableColumnCellAttributes]: Getting cell attributes (table column)",
						"FINE", this);
		try {
			cellAttributesJSON = this.getObj()
					.getCurrentTableColumnCellAttributes();
			if (cellAttributesJSON !== "") {
				eval("var cellAttributesJSON = " + cellAttributesJSON);
				jQuery
						.each(
								cellAttributesJSON,
								function(cellIndex, cellValue) {
									cells[cellIndex] = {};
									if (cellValue !== undefined
											&& cellValue !== null) {
										jQuery
												.each(
														cellValue,
														function(
																attributeIndex,
																attributeArray) {
															cells[cellIndex][attributeArray[0]] = attributeArray[1];
														});
									}
								});
			}
		} catch (err) {
			this.Logger
					.log(
							"[getCurrentTableColumnCellAttributes]: Failed to get cell attributes (table column) with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[getCurrentTableColumnCellAttributes]: Finished",
				"FINER", this);
		return cells;
	};
	this.getCurrentTableRowCellAttributes = function() {
		var cells = [];
		var cellAttributesJSON;
		this.Logger.log("[getCurrentTableRowCellAttributes]: Started", "FINER",
				this);
		this.Logger
				.log(
						"[getCurrentTableRowCellAttributes]: Getting cell attributes (table row)",
						"FINE", this);
		try {
			var cellAttributesJSON = this.getObj()
					.getCurrentTableRowCellAttributes();
			if (cellAttributesJSON !== "") {
				eval("var cellAttributesJSON = " + cellAttributesJSON);
				jQuery
						.each(
								cellAttributesJSON,
								function(cellIndex, cellValue) {
									cells[cellIndex] = {};
									if (cellValue !== undefined
											&& cellValue !== null) {
										jQuery
												.each(
														cellValue,
														function(
																attributeIndex,
																attributeArray) {
															cells[cellIndex][attributeArray[0]] = attributeArray[1];
														});
									}
								});
			}
		} catch (err) {
			this.Logger
					.log(
							"[getCurrentTableRowCellAttributes]: Failed to get cell attributes (table row) with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[getCurrentTableRowCellAttributes]: Finished",
				"FINER", this);
		return cells;
	};
	this.getElementAttributes = function() {
		var attributes = null;
		this.Logger.log("[getElementAttributes]: Started", "FINER", this);
		this.Logger.log("[getElementAttributes]: Getting element attributes",
				"FINE", this);
		try {
			json = this.getObj().getElementAttributes();
			if (json !== "") {
				eval("var json = " + json);
				attributes = {};
				for (i = 0; i < json.length; i++) {
					key = json[i][0];
					value = json[i][1];
					attributes[key] = value;
				}
			}
		} catch (err) {
			this.Logger.log(
					"[getElementAttributes]: Failed to get element attributes",
					"SEVERE", this);
		}
		this.Logger.log("[getElementAttributes]: Finished", "FINER", this);
		return attributes;
	};
	this.getEmbeddedStyles = function() {
		var embeddedStyles = "";
		this.Logger.log("[getEmbeddedStyles]: Started", "FINER", this);
		this.Logger.log("[getEmbeddedStyles]: Getting embedded styles", "FINE",
				this);
		try {
			embeddedStyles = String(this.getObj().getEmbeddedStyles());
		} catch (err) {
			this.Logger.log(
					"[getEmbeddedStyles]: Failed to get embedded styles",
					"SEVERE", this);
		}
		this.Logger.log("[getEmbeddedStyles]: Finished", "FINER", this);
		return embeddedStyles;
	};
	this.getDocument = function() {
		var content = "";
		this.Logger.log("[getDocument]: Started", "FINER", this);
		this.Logger
				.log("[getDocument]: Getting document content", "FINE", this);
		try {
			content = String(this.getObj().getDocument());
		} catch (err) {
			this.Logger.log(
					"[getDocument]: Failed to get document content with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getDocument]: Finished", "FINER", this);
		return content;
	};
	this.getHeadElementContent = function() {
		var content = "";
		this.Logger.log("[getHeadElementContent]: Started", "FINER", this);
		this.Logger.log(
				"[getHeadElementContent]: Getting head element content",
				"FINE", this);
		try {
			content = String(this.getObj().getHeadElementContent());
		} catch (err) {
			this.Logger.log(
					"[getHeadElementContent]: Failed to get head element content with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getHeadElementContent]: Finished", "FINER", this);
		return content;
	};
	this.getNumberOfCharacters = function(countSpaces) {
		var characters = 0;
		this.Logger.log("[getNumberOfCharacters]: Started", "FINER", this);
		this.Logger.log(
				"[getNumberOfCharacters]: Getting number of characters",
				"FINE", this);
		try {
			characters = Number(this.getObj()
					.getNumberOfCharacters(countSpaces));
		} catch (err) {
			this.Logger.log(
					"[getNumberOfCharacters]: Failed to get number of characters with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getNumberOfCharacters]: Finished", "FINER", this);
		return characters;
	};
	this.getNumberOfImages = function() {
		var images = 0;
		this.Logger.log("[getNumberOfImages]: Started", "FINER", this);
		this.Logger.log("[getNumberOfImages]: Getting number of images",
				"FINE", this);
		try {
			images = Number(this.getObj().getNumberOfImages());
		} catch (err) {
			this.Logger.log(
					"[getNumberOfImages]: Failed to get number of images with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getNumberOfImages]: Finished", "FINER", this);
		return images;
	};
	this.getNumberOfParagraphs = function() {
		var paragraphs = 0;
		this.Logger.log("[getNumberOfParagraphs]: Started", "FINER", this);
		this.Logger.log(
				"[getNumberOfParagraphs]: Getting number of paragraphs",
				"FINE", this);
		try {
			paragraphs = Number(this.getObj().getNumberOfParagraphs());
		} catch (err) {
			this.Logger.log(
					"[getNumberOfParagraphs]: Failed to get number of paragraphs with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getNumberOfParagraphs]: Finished", "FINER", this);
		return paragraphs;
	};
	this.getNumberOfWords = function() {
		var words = 0;
		this.Logger.log("[getNumberOfWords]: Started", "FINER", this);
		this.Logger.log("[getNumberOfWords]: Getting number of word", "FINE",
				this);
		try {
			words = Number(this.getObj().getNumberOfWords());
		} catch (err) {
			this.Logger.log(
					"[getNumberOfWords]: Failed to get number of word with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getNumberOfWords]: Finished", "FINER", this);
		return words;
	};
	this.getDocumentLanguage = function() {
		var documentLanguage = "";
		this.Logger.log("[getDocumentLanguage]: Started", "FINER", this);
		this.Logger.log("[getDocumentLanguage]: Getting document language",
				"FINE", this);
		try {
			documentLanguage = String(this.getObj().getDocumentLanguage());
		} catch (err) {
			this.Logger.log(
					"[getDocumentLanguage]: Failed to get document language with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getDocumentLanguage]: Finished", "FINER", this);
		return documentLanguage;
	};
	this.getFragmentLanguage = function() {
		var fragmentLanguage = "";
		this.Logger.log("[getFragmentLanguage]: Started", "FINER", this);
		this.Logger.log("[getFragmentLanguage]: Getting fragment language",
				"FINE", this);
		try {
			fragmentLanguage = String(this.getObj().getFragmentLanguage());
		} catch (err) {
			this.Logger.log(
					"[getFragmentLanguage]: Failed to get fragment language with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getFragmentLanguage]: Finished", "FINER", this);
		return fragmentLanguage;
	};
	this.getParentElementByName = function(ancestorName) {
		this.Logger.log("[getParentElementByName]: Started", "FINER", this);
		this.Logger.log("[getParentElementByName]: Getting parent element",
				"FINE", this);
		var element = "";
		try {
			element = String(this.getObj().getParentElementByName(ancestorName));
		} catch (err) {
			this.Logger.log(
					"[getParentElementByName]: Failed to get parent element with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getParentElementByName]: Finished", "FINER", this);
		return element;
	};
	this.getParentElementByNameAttributes = function(ancestorName) {
		this.Logger.log("[getParentElementByNameAttributes]: Started", "FINER",
				this);
		this.Logger
				.log(
						"[getParentElementByNameAttributes]: Getting parent element attributes",
						"FINE", this);
		var json = null;
		try {
			json = this.getObj().getParentElementByNameAttributes(ancestorName);
			if (json !== "") {
				eval("var json = " + json);
				var attributes = {};
				for (i = 0; i < json.length; i++) {
					key = json[i][0];
					value = json[i][1];
					attributes[key] = value;
				}
				return attributes;
			}
		} catch (err) {
			this.Logger
					.log(
							"[getParentElementByNameAttributes]: Failed to get parent element attributes with error: "
									+ err, "SEVERE", this);
		}
		return json;
	};
	this.getParentElementByNameContent = function(ancestorName) {
		this.Logger.log("[getParentElementByNameContent]: Started", "FINER",
				this);
		this.Logger
				.log(
						"[getParentElementByNameContent]: Getting parent element content",
						"FINE", this);
		var content = "";
		try {
			content = String(this.getObj().getParentElementByNameContent(
					ancestorName));
		} catch (err) {
			this.Logger
					.log(
							"[getParentElementByNameContent]: Failed to get parent element content with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[getParentElementByNameContent]: Finished", "FINER",
				this);
		return content;
	};
	this.getPlainText = function() {
		this.Logger.log("[getPlainText]: Started", "FINER", this);
		this.Logger.log("[getPlainText]: Getting plain text content", "FINE",
				this);
		var text = "";
		try {
			text = String(this.getObj().getPlainText());
		} catch (err) {
			this.Logger.log(
					"[getPlainText]: Failed to get plain text content with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getPlainText]: Finished", "FINER", this);
		return text;
	};
	this.getSelectedRowsCellAttributes = function() {
		var attributes = null;
		this.Logger.log("[getSelectedRowsCellAttributes]: Started", "FINER",
				this);
		this.Logger
				.log(
						"[getSelectedRowsCellAttributes]: Getting the attributes of all cells in the selected rows",
						"FINE", this);
		try {
			attributes = this.getObj().getSelectedRowsCellAttributes();
			if (attributes !== "") {
				eval("var attributes = " + attributes);
			}
		} catch (err) {
			this.Logger
					.log(
							"[getSelectedRowsCellAttributes]: Failed to get element attributes",
							"SEVERE", this);
		}
		this.Logger.log("[getSelectedRowsCellAttributes]: Finished", "FINER",
				this);
		return attributes;
	};
	this.getSelectedColumnsCellAttributes = function() {
		var attributes = null;
		this.Logger.log("[getSelectedColumnsCellAttributes]: Started", "FINER",
				this);
		this.Logger
				.log(
						"[getSelectedColumnsCellAttributes]: Getting the attributes of all cells in the selected columns",
						"FINE", this);
		try {
			attributes = this.getObj().getSelectedColumnsCellAttributes();
			if (attributes !== "") {
				eval("var attributes = " + attributes);
			}
		} catch (err) {
			this.Logger
					.log(
							"[getSelectedColumnsCellAttributes]: Failed to get element attributes",
							"SEVERE", this);
		}
		this.Logger.log("[getSelectedColumnsCellAttributes]: Finished",
				"FINER", this);
		return attributes;
	};
	this.getSelectionContent = function() {
		this.Logger.log("[getSelectionContent]: Started", "FINER", this);
		this.Logger.log("[getSelectionContent]: Getting selection content",
				"FINE", this);
		var content = "";
		try {
			content = String(this.getObj().getSelectionContent());
		} catch (err) {
			this.Logger.log(
					"[getSelectionContent]: Failed to get selection content with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[getSelectionContent]: Finished", "FINER", this);
		return content;
	};
	this.getSelectionPlainText = function() {
		this.Logger.log("[getSelectionPlainText]: Started", "FINER", this);
		this.Logger
				.log(
						"[getSelectionPlainText]: Getting selection content as plain text",
						"FINE", this);
		var content = "";
		try {
			content = String(this.getObj().getSelectionPlainText());
		} catch (err) {
			this.Logger
					.log(
							"[getSelectionPlainText]: Failed to get selection content as plain text with error: "
									+ err, "SEVERE", this);
		}
		this.Logger.log("[getSelectionPlainText]: Finished", "FINER", this);
		return content;
	};
	this.hasContentChanged = function() {
		return this.getObj().hasContentChanged();
	};
	this.isActionEnabled = function(actionID) {
		return this.getObj().isActionEnabled(actionID);
	};
	this.isComparisonMode = function() {
		return this.getObj().isComparisonMode();
	};
	this.isEditable = function() {
		this.Logger.log(
				"[isEditable]: Retrieving the value of the editable property",
				"FINE", this);
		return this.getObj().isEditable();
	};
	this.isEnabled = function() {
		this.Logger.log(
				"[isEnabled]: Retrieving the value of the enabled property",
				"FINE", this);
		return this.getObj().isEnabled();
	};
	this.resizeEditor = function(width, height) {
		jQuery("#" + this.Helper.containerId).width(width).height(height);
		this.Logger.log("[resizeUI called from resizeEditor]", "INFO", this);
		if (this.Helper.isMSIE && parseInt(this.Helper.BrowserVersion) < 7) {
			this.Helper.resizeUI(false, width, height);
		} else {
			this.Helper.resizeUI();
		}
	}
	this.applyStyleTemplate = function(templateName, groupName) {
		this.getObj().applyStyleTemplate(templateName, groupName);
	};
	this.attachEventToElement = function(elem, obj) {
		var actionName = elem.name;
		var elemParent = jQuery(elem).parent();
		var Helper = this.Helper;
		if (!this.Helper.actions[actionName]) {
			this.Helper.actions[actionName] = new eongApplication.Action(
					actionName, this.Logger, Helper);
		}
		var elemObj = {
			"elem" : elem,
			"elemParent" : elemParent
		};
		var action = this.Helper.actions[actionName];
		action.controllers.push(elemObj);
		if (elem.tagName.toLowerCase() !== "input") {
			jQuery(elemParent).bind('click', function() {
				if (!jQuery(this).hasClass("disabled")) {
					tmpName = elem.name;
					obj.invokeAction(tmpName, null);
				}
			});
		}
	};
	this.createCustomJavaAction = function(actionId, customclass, element,
			require) {
		element = jQuery.toJSON(element);
		this.getObj().createCustomJavaAction(actionId, customclass, element,
				require);
	};
	this.createJavaScriptAction = function(actionId, path, element,
			functionName, require) {
		element = jQuery.toJSON(element);
		this.getObj().createJavaScriptAction(actionId, path, element,
				functionName, require);
	};
	this.delayMethodCall = function() {
		method = {};
		method[0] = arguments[0];
		method[1] = arguments[1];
		if (arguments[2] !== null) {
			method[2] = arguments[2];
		}
		this.methodQueue.push(method);
	};
	this.getObj = function() {
		return this.Helper.jsWrapperObj;
	};
	this.initializeToolbar = function(userPreferences) {
		var eongObj = this;
		var loggerObj = this.Logger;
		var Helper = this.Helper;
		this.Helper.initialUserPreferences = userPreferences;
		this.openPanel = function(size) {
			this.Helper.editorLayout.open("west");
			this.Helper.editorLayout.sizePane("west", size);
		};
		if (this.Helper.config.saveuistate !== undefined
				&& this.Helper.config.saveuistate == "true") {
			var uiversion = 1;
			this.Helper.uiversionOrig = this.Helper
					.getInitialUserPreferences("uiversion");
			if (this.Helper.uiversionOrig !== null) {
				uiversion = this.Helper.uiversionOrig[this.Helper.getLocation()];
			} else {
				this.Helper.uiversionOrig = {};
			}
			if (this.Helper.uiVersion <= uiversion) {
				userUI = this.Helper.getUserDefinedToolbar();
				if (userUI !== undefined && userUI !== null && userUI !== "") {
					this.Helper.uiconfig.toolbar.ribbons.elements = jQuery
							.evalJSON(userUI);
				}
			} else {
				this.Helper.uistate = this.Helper
						.getInitialUserPreferences("toolbarstate");
				if (this.Helper.uistate !== null) {
					this.Helper.uistate[this.Helper.getLocation()] = null;
				}
			}
			this.DOMElements.createToolbar(false);
			upSidebar = this.Helper.getInitialUserPreferences("sidebarstate");
			var stpanel = "userdefined";
			if (this.Helper.config.openstyletemplatepanel !== undefined) {
				stpanel = this.Helper.config.openstyletemplatepanel;
			}
			if (stpanel === "always") {
				this.openPanel(145);
			} else if (upSidebar !== null) {
				if (upSidebar[this.Helper.getLocation()] !== undefined) {
					if (upSidebar[this.Helper.getLocation()][this.Helper.containerId] !== undefined) {
						initClosed = upSidebar[this.Helper.getLocation()][this.Helper.containerId]["initClosed"];
						size = upSidebar[this.Helper.getLocation()][this.Helper.containerId]["size"];
						if (stpanel === "userdefined" && initClosed === "false") {
							this.openPanel(size);
						}
					}
				}
			}
			this.Helper.uiversionOrig[this.Helper.getLocation()] = this.Helper.uiVersion;
		}
		this.Helper.resizeUI(true);
	};
	this.initializeJavaScriptActions = function() {
		var eongObj = this;
		var loggerObj = this.Logger;
		var Helper = this.Helper;
		var require = "";
		jQuery.each(this.Helper.ActionMap, function(index, value) {
			loggerObj.log("[createJSAction]: Started", "FINER", this);
			require = "CARET_OR_SELECTION";
			var path = "";
			if (value.require != undefined) {
				require = value.require;
			}
			if (value.actionPath != undefined) {
				path = value.actionPath;
			}
			try {
				if (value.type == "js") {
					try {
						elementNames = value.elementNames;
						if (elementNames === undefined || elementNames === "") {
							elementNames = [ "*" ];
						}
					} catch (err6) {
						elementNames = [ "*" ];
					}
					if (path == "CustomJSActions") {
						loggerObj.log("[createJSAction]: calling with " + index
								+ ", " + Helper.jsObjName + "." + path + ", "
								+ elementNames + ", " + value.functionName,
								"FINEST", this);
						eongObj.createJavaScriptAction(index, Helper.jsObjName
								+ "." + path, elementNames, value.functionName,
								require);
					} else {
						loggerObj.log("[createJSAction]: calling with " + index
								+ ", " + path + ", " + elementNames + ", "
								+ value.functionName, "FINEST", this);
						eongObj.createJavaScriptAction(index, path,
								elementNames, value.functionName, require);
					}
				}
				if (value.type === "javaCustom") {
					try {
						elementNames = value.elementNames;
						if (elementNames === undefined || elementNames === "") {
							elementNames = [ "*" ];
						}
					} catch (err7) {
						elementNames = [ "*" ];
					}
					loggerObj.log("[createCustomJavaAction]: calling with "
							+ index + ", " + value.javaClass + ", "
							+ elementNames, "FINEST", this);
					eongObj.createCustomJavaAction(index, value.javaClass,
							elementNames, require);
				}
			} catch (err) {
				loggerObj.log("[createJSAction]: creating " + index + ", "
						+ path + ", " + elementNames + " with error: " + err,
						"SEVERE", this);
			}
			loggerObj.log("[createJSAction]: Finished", "FINER", this);
		});
	};
	this.initializeJS = function(jsWrapperRef) {
		this.setObj(jsWrapperRef);
		this.Helper.initialized = true;
		this.Helper.setUserPreferences({
			"uiversion" : this.Helper.uiversionOrig
		});
		if (this.Helper.uistate !== undefined) {
			this.Helper.setUserPreferences({
				"toolbarstate" : this.Helper.uistate
			});
		}
		this.initializeJavaScriptActions();
		this.getObj().createActionMap();
		this.performMethodCalls();
		this.DOMElements.enableToolbar();
		this.Helper.loadDialogHTML();
		this.Helper.assembleFontDropDownList();
		this.initializeRuler();
	};
	this.initializeRuler = function() {
		var rulerContainer = jQuery("#" + appletName + "_ruler");
		if (rulerContainer.length > 0) {
			this.RulerController.init(rulerContainer,
					this.Helper.config.rulerunit);
		}
	}
	this.callEventHandler = function(args) {
		this.Logger.log("[callEventHandler]: Started", "FINER", this);
		this.Logger.log("[callEventHandler]: Call integrator's event handler",
				"FINE", this);
		try {
			var handlerName = args[0];
			var callMethod = handlerName + "(this";
			for (i = 1; i < args.length; i++) {
				if (typeof args[i] == "string") {
					var doc = args[i];
					doc = doc.replace(/"/g, "\\\"");
					callMethod += ", \"" + doc + "\"";
				} else if (jQuery.isArray(args[i])) {
					callMethod += ", " + jQuery.toJSON(args[i]);
				} else {
					callMethod += ", " + args[i];
				}
			}
			callMethod += ")";
			callMethod = callMethod.replace(/\r/g, '');
			callMethod = callMethod.replace(/\n/g, '');
			callMethod = callMethod.replace(/\t/g, '');
			return eval(callMethod);
		} catch (err) {
			this.Logger
					.log(
							"[callEventHandler]: Failed to call integrator's event handler",
							"SEVERE", this);
		}
		return "";
	}
	this.performMethodCalls = function() {
		if (this.methodQueue !== null) {
			args = [];
			for (prop in this.methodQueue) {
				method = this.methodQueue[prop];
				methodName = method[0];
				if (method[1] !== null && method[1] !== undefined)
					args = method[1];
				if (methodName !== undefined && methodName !== null) {
					this.Helper.jsObj[methodName](args[0], args[1], args[2],
							args[3], args[4]);
				}
			}
		}
	};
	this.resize = function(obj, width, height) {
		if (this.Helper.detachableUI.enabled !== undefined
				&& (this.Helper.detachableUI.enabled === "true" || this.Helper.detachableUI.enabled === true)) {
			applicationHeight = height;
		} else {
			toolbarHeight = jQuery("#" + this.Helper.containerId + "_toolbar")
					.height();
			statusBarHeight = jQuery(
					"#" + this.Helper.containerId + "_statusbar").height();
			applicationHeight = height + toolbarHeight + statusBarHeight;
		}
		jQuery("#" + this.Helper.id).css({
			"width" : width,
			"height" : height
		});
		jQuery("#" + this.Helper.id).attr({
			"width" : width,
			"height" : height
		});
		jQuery("#" + this.Helper.containerId).css({
			"height" : applicationHeight
		});
		jQuery("#" + this.Helper.containerId + "_div").css({
			"height" : height
		});
		jQuery(
				"#applicationContainer_" + this.Helper.containerId
						+ " .ui-layout-resizer").height(height);
		jQuery("#" + this.Helper.containerId + "_sidebar").height(height - 1);
		jQuery(
				"#" + this.Helper.containerId + "_sidebar #"
						+ this.Helper.containerId + "_sidebar_content").height(
				height - (37));
		jQuery("#applicationContainer_" + this.Helper.containerId).css({
			"height" : height
		});
		jQuery("#replacementImage_" + this.Helper.containerId).css({
			width : width,
			height : height
		});
	}
	this.select = function(expression) {
		var expression = arguments[0];
		var dismissSelection = arguments[1] === undefined ? false
				: arguments[1];
		this.Logger.log("[select]: Started", "FINER", this);
		try {
			if (this.Helper.initialized) {
				return this.getObj().select(expression, dismissSelection);
			} else {
				this.delayMethodCall("moveCaretToDocumentEnd", arguments);
			}
		} catch (err) {
			this.Logger.log(
					"[select]: Failed to select the specified nodes with error: "
							+ err, "SEVERE", this);
		}
		this.Logger.log("[select]: Finished", "FINER", this);
	}
	this.selectDocumentPaletteIndex = function() {
		this.Logger.log("[selectDocumentPaletteIndex]: Started", "FINER", this);
		if (arguments.length == 1) {
			try {
				this.Logger.log("[selectDocumentPaletteIndex]: Arguments[0]: "
						+ arguments[0], "FINE", this);
				this.getObj().selectDocumentPaletteIndex(arguments[0]);
			} catch (err) {
				this.Logger.log("[selectDocumentPalette]: " + arguments[0]
						+ " with error: " + err, "SEVERE", this);
			}
		} else {
			this.Logger.log("[selectDocumentPaletteIndex]: Arguments[0]: "
					+ arguments[0] + ", Arguments[1]: " + arguments[1], "FINE",
					this);
			try {
				this.getObj().selectDocumentPaletteIndex(arguments[0],
						arguments[1]);
			} catch (err2) {
				this.Logger.log("[selectDocumentPalette]: " + arguments[0]
						+ ", " + arguments[1] + " with error: " + err2,
						"SEVERE", this);
			}
		}
		this.Logger
				.log("[selectDocumentPaletteIndex]: Finished", "FINER", this);
	};
	this.setObj = function(jsWrapperObj) {
		this.Helper.jsWrapperObj = jsWrapperObj;
	};
	this.setReplacementImage = function(obj, base64Img) {
		if (this.Helper.isMSIE && parseInt(this.Helper.BrowserVersion) < 8) {
		} else {
			jQuery("#replacementImage_" + this.Helper.containerId).attr("src",
					base64Img);
		}
	};
	this.updateAction = function(actionId, propertyName, propertyValue) {
		this.Logger.log("[updateAction]: Started (" + actionId + ", "
				+ propertyName + "," + propertyValue + ")", "FINEST");
		actionId = actionId + '';
		propertyName = propertyName + '';
		propertyValue = propertyValue + '';
		if (actionId === "zoom"
				&& propertyName === "StringState"
				&& (this.Helper.config.enablestatusbar === undefined
						|| this.Helper.config.enablestatusbar == "true" || this.Helper.config.enablestatusbar === true)
				&& (this.Helper.config.enablezoomarea === undefined || this.Helper.config.enablezoomarea == "true")) {
			newPropertyValue = parseInt(propertyValue);
			if (newPropertyValue <= 100) {
				newPropertyValue = newPropertyValue * 5;
			} else {
				newPropertyValue = 1.25 * (newPropertyValue + 300);
			}
			jQuery("#" + this.Helper.containerId + "_statusbar .zoomSlider")
					.slider('value', parseInt(newPropertyValue));
		}
		if (actionId === "page-mode-continuous"
				&& propertyName === "SelectedState" && propertyValue === "true") {
			jQuery("#" + this.Helper.containerId + "_statusbar .pageCounter")
					.html(this.Helper.LocaleObject["L_PAGE"] + ": &#8734;");
		}
		if (this.Helper.actions[actionId]
				&& this.Helper.actions[actionId]['set' + propertyName]) {
			try {
				this.Logger.log("[updateAction]: " + actionId
						+ " invoking in Actions.js", "FINEST");
				this.Helper.actions[actionId]['set' + propertyName]
						(propertyValue);
			} catch (err) {
				this.Logger.log("[updateAction]: Calling (" + actionId + ", "
						+ propertyName + "," + propertyValue
						+ ") on action object failed with: " + err, "SEVERE");
			}
		}
	};
	this.updateDocumentPalette = function(obj, args) {
		this.Logger.log("[updateDocumentPalette]: Started", "FINEST");
		var obj = this;
		if (this.Helper.config.enabledocumentpalette === undefined
				|| this.Helper.config.enabledocumentpalette == "true") {
			if (args === "") {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteContainer").html(
						"");
			} else {
				this.Helper.currentPaletteScrollValue = 0;
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteContainer")
						.scrollTo(0, 0);
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteContainer")
						.html(
								"<table cellspacing=\"0\" class=\"documentPaletteList\"><tr></tr></table>");
				jQuery
						.each(
								args,
								function(i, val) {
									if (i === 0 || (i % 2) === 0) {
										var spacerContent = [];
										jQuery.each(val, function(k, valk) {
											var itemValues = [];
											itemValues.push(i + "_" + k);
											itemValues.push(valk);
											spacerContent.push(itemValues);
										});
										jQuery(
												"#"
														+ obj.Helper.containerId
														+ "_statusbar .documentPaletteContainer tr")
												.append(
														"<td class=\"documentPaletteListSpacer\" id=\"documentPaletteSpacerContainer_"
																+ i
																+ "_"
																+ obj.Helper.containerId
																+ "\"></td>");
										jQuery(
												"#documentPaletteSpacerContainer_"
														+ i
														+ "_"
														+ obj.Helper.containerId)
												.romenu(
														{
															content : spacerContent,
															contentType : "json",
															showSpeed : 200,
															height : 100,
															dropdownWidth : 100,
															directionV : "up",
															iconDirection : "right",
															onSelect : function() {
																var indexAttr = jQuery(
																		this)
																		.attr(
																				"alt");
																indexAttr = indexAttr
																		.split("_");
																obj
																		.selectDocumentPaletteIndex(
																				indexAttr[0],
																				indexAttr[1]);
															},
															onShowDropDown : function() {
																obj.Helper
																		.replaceEditor(true);
															},
															onCloseDropDown : function() {
																obj.Helper
																		.replaceEditor(false);
															}
														});
									} else {
										jQuery(
												"#"
														+ obj.Helper.containerId
														+ "_statusbar .documentPaletteContainer tr")
												.append(
														"<td class=\"documentPaletteListElement\">"
																+ "<span class=\"ui-corner-all documentPaletteElement\" id=\"documentPaletteElement_"
																+ i
																+ "_"
																+ obj.Helper.containerId
																+ "\">"
																+ "<span>"
																+ val
																+ "</span>"
																+ "</span>"
																+ "</td>");
										jQuery(".documentPaletteElement").bind(
												'mouseover',
												function(e) {
													jQuery(this).addClass(
															"ui-state-hover");
												});
										jQuery(".documentPaletteElement").bind(
												'mouseout',
												function(e) {
													jQuery(this).removeClass(
															"ui-state-hover");
												});
										jQuery(
												"#documentPaletteElement_"
														+ i
														+ "_"
														+ obj.Helper.containerId)
												.bind(
														'click',
														function(e) {
															obj
																	.selectDocumentPaletteIndex(i);
														});
									}
								});
				this.toggleNav();
				jQuery(
						"#" + obj.Helper.containerId
								+ "_statusbar .documentPaletteNavRight")
						.mouseover(
								function(event) {
									if (obj.paletteNavInterval === undefined
											|| obj.paletteNavInterval === null) {
										obj.paletteNavInterval = window
												.setInterval(
														obj.Helper.jsObjName
																+ ".scrollRight()",
														10);
									}
								});
				jQuery(
						"#" + obj.Helper.containerId
								+ "_statusbar .documentPaletteNavRight").bind(
						"mouseout", function() {
							window.clearInterval(obj.paletteNavInterval);
							obj.paletteNavInterval = null;
						});
				jQuery(
						"#" + obj.Helper.containerId
								+ "_statusbar .documentPaletteNavLeft")
						.mouseover(
								function(event) {
									if (obj.paletteNavInterval === undefined
											|| obj.paletteNavInterval === null) {
										obj.paletteNavInterval = window
												.setInterval(
														obj.Helper.jsObjName
																+ ".scrollLeft()",
														10);
									}
								});
				jQuery(
						"#" + obj.Helper.containerId
								+ "_statusbar .documentPaletteNavLeft").bind(
						"mouseout", function() {
							window.clearInterval(obj.paletteNavInterval);
							obj.paletteNavInterval = null;
						});
				jQuery(
						"#" + obj.Helper.containerId
								+ "_statusbar .documentPaletteNavRight, #"
								+ obj.Helper.containerId
								+ "_statusbar .documentPaletteNavLeft").bind(
						"mousedown", function() {
							obj.Helper.scrollSpeed = 10;
						});
				jQuery("*").bind("mouseup", function() {
					obj.Helper.scrollSpeed = 1;
				});
			}
		}
	};
	this.updateDocumentCounter = function(obj, args) {
		if (this.Helper.config.charactercounter !== undefined
				&& this.Helper.config.charactercounter.enabled !== undefined
				&& this.Helper.config.charactercounter.enabled === "true") {
			if (this.Helper.config.charactercounter !== undefined
					&& this.Helper.config.charactercounter.limit !== undefined
					&& parseInt(this.Helper.config.charactercounter.limit) < parseInt(args)) {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentCounterDisplay").css({
					"color" : "red"
				});
			} else {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentCounterDisplay").css({
					"color" : "black"
				});
			}
			var counterStr = "";
			if (this.Helper.config.charactercounter !== undefined
					&& this.Helper.config.charactercounter.limit !== undefined) {
				counterStr = args + " / "
						+ this.Helper.config.charactercounter.limit;
			} else {
				counterStr = args + ""
			}
			jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .documentCounterDisplay").html(
					counterStr);
			var statusBarReduceWidth = jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .buttonContainer").outerWidth(true) + 6;
			statusBarReduceWidth += ((jQuery("#" + this.Helper.containerId
					+ "_statusbar .buttonContainer td").length + 1) * 2) + 2;
			if (this.Helper.config.enablezoomarea === undefined
					|| this.Helper.config.enablezoomarea == "true") {
				statusBarReduceWidth += 246;
			}
			if (this.Helper.config.charactercounter !== undefined
					&& this.Helper.config.charactercounter.enabled !== undefined
					&& this.Helper.config.charactercounter.enabled === "true") {
				statusBarReduceWidth += jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentCounterArea")
						.outerWidth(true) + 6;
			}
			if (this.Helper.config.resizable !== undefined
					&& this.Helper.config.resizable == "true") {
				statusBarReduceWidth += jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .resizerContainer").outerWidth(
						true) + 6;
			}
			if (this.Helper.config.languagebar !== undefined
					&& this.Helper.config.languagebar.enabled !== undefined
					&& this.Helper.config.languagebar.enabled === "true") {
				statusBarReduceWidth += jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .languageBar").outerWidth(true) + 6;
			}
			if (this.Helper.config.enablepagecountarea !== undefined
					&& this.Helper.config.enablepagecountarea == "true") {
				statusBarReduceWidth += jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .pageCounter").outerWidth(true) + 6;
			} else {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .pageCounter").parent("td").css({
					"display" : "none"
				});
			}
			statusBarReduceWidth += 40;
			var width = jQuery("#" + this.Helper.containerId).width();
			jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .documentPaletteContainer").width(
					width - statusBarReduceWidth);
		}
	}
	this.scrollRight = function() {
		if (this.Helper.currentPaletteScrollValue < this.Helper.maxScrollValue) {
			this.Helper.currentPaletteScrollValue += 1 * this.Helper.scrollSpeed;
			jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .documentPaletteContainer").scrollTo(
					this.Helper.currentPaletteScrollValue, 0);
			this.toggleNav();
		}
	}
	this.scrollLeft = function() {
		if (this.Helper.currentPaletteScrollValue > 0) {
			this.Helper.currentPaletteScrollValue -= 1 * this.Helper.scrollSpeed;
			if (this.Helper.currentPaletteScrollValue > 0) {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteContainer")
						.scrollTo(this.Helper.currentPaletteScrollValue, 0);
				this.toggleNav();
			} else {
				this.Helper.currentPaletteScrollValue = 0;
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteContainer")
						.scrollTo(this.Helper.currentPaletteScrollValue, 0);
				this.toggleNav();
			}
		}
	}
	this.scrollToHelper = function(args) {
		var amount = args[0];
		amount = Math.abs(amount);
		var dir = args[1];
		var prefix = "+=";
		if (dir == "up") {
			prefix = "-=";
		}
		var expression = prefix + amount + "px";
		jQuery.scrollTo(expression, {
			axis : "y"
		});
	}
	this.toggleNav = function() {
		if (this.Helper.config.enabledocumentpalette !== undefined
				&& this.Helper.config.enabledocumentpalette === "true") {
			var listWidth = jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .documentPaletteList").width();
			var containerWidth = jQuery(
					"#" + this.Helper.containerId
							+ "_statusbar .documentPaletteContainer").width();
			var maxScrollValue = listWidth - containerWidth;
			this.Helper.maxScrollValue = maxScrollValue;
			if (maxScrollValue <= 0) {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteNavLeft").css({
					"visibility" : "hidden"
				});
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteNavRight").css({
					"visibility" : "hidden"
				});
			} else {
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteNavLeft").css({
					"visibility" : "visible"
				});
				jQuery(
						"#" + this.Helper.containerId
								+ "_statusbar .documentPaletteNavRight").css({
					"visibility" : "visible"
				});
				if (this.Helper.currentPaletteScrollValue <= 0) {
					jQuery(
							"#" + this.Helper.containerId
									+ "_statusbar .documentPaletteNavLeft span")
							.addClass("ui-state-disabled");
				} else {
					jQuery(
							"#" + this.Helper.containerId
									+ "_statusbar .documentPaletteNavLeft span")
							.removeClass("ui-state-disabled");
				}
				if (this.Helper.currentPaletteScrollValue >= maxScrollValue) {
					jQuery(
							"#"
									+ this.Helper.containerId
									+ "_statusbar .documentPaletteNavRight span")
							.addClass("ui-state-disabled");
				} else {
					jQuery(
							"#"
									+ this.Helper.containerId
									+ "_statusbar .documentPaletteNavRight span")
							.removeClass("ui-state-disabled");
				}
			}
		}
	};
	this.updateFileChooserInput = function(element, value) {
		jQuery(element).val(unescape(value));
	};
	this.updatePageCount = function(pageJSON) {
		jQuery("#" + this.Helper.containerId + "_statusbar .pageCounter").html(
				this.Helper.LocaleObject["L_PAGE"] + ": " + pageJSON[0] + " / "
						+ pageJSON[1]);
		this.Helper.resizeUI(true);
	}
	this.addStyleTemplateGroup = function(obj, sideBarContent, groupName,
			displayGroupName) {
		var containerId = obj.Helper.containerId;
		var groupContainer = jQuery("<div></div>").addClass(
				"styleGroupOuterContainer").attr("id",
				groupName + "_" + containerId);
		var groupTitleContainer = jQuery(
				"<div>"
						+ displayGroupName
						+ "<div class='groupTitleContainerVisibility ui-icon'></div></div>")
				.addClass("ui-widget-header").addClass("styleGroup");
		groupContainer.append(groupTitleContainer);
		var groupTemplatesContainer = jQuery("<div></div>").addClass(
				"ui-widget-content").attr("id",
				groupName + "_" + containerId + "_stylecontainer");
		if (groupTemplatesContainer.css("display") === "none") {
			groupTitleContainer.children(".groupTitleContainerVisibility")
					.addClass("ui-icon-triangle-1-s");
		} else {
			groupTitleContainer.children(".groupTitleContainerVisibility")
					.addClass("ui-icon-triangle-1-n");
		}
		groupTitleContainer.children(".groupTitleContainerVisibility").click(
				function() {
					if (jQuery(this).hasClass("ui-icon-triangle-1-s")) {
						jQuery(this).removeClass("ui-icon-triangle-1-s");
						jQuery(this).addClass("ui-icon-triangle-1-n");
					} else {
						jQuery(this).addClass("ui-icon-triangle-1-s");
						jQuery(this).removeClass("ui-icon-triangle-1-n");
					}
					jQuery(groupTemplatesContainer).toggle();
				});
		groupContainer.append(groupTemplatesContainer);
		sideBarContent.append(groupContainer);
	}
	this.removeStyleTemplateGroup = function(obj, sideBarContent, groupName) {
		sideBarContent.find("div#" + groupName + "_" + obj.Helper.containerId)
				.remove();
	}
	this.removeStyleTemplate = function(obj, sideBarContent, groupName,
			actionId) {
		var containerId = obj.Helper.containerId;
		var group = sideBarContent.find("div#" + groupName + "_" + containerId
				+ "_stylecontainer");
		if (group != null && group.length > 0) {
			sideBarContent.find("div#" + actionId + "_" + containerId).remove();
			if (group.length <= 0) {
				obj.removeStyleTemplateGroup(obj, sideBarContent, groupName);
			}
		}
	}
	this.addStyleTemplate = function(obj, sideBarContent, groupName,
			displayGroupName, actionId, actionIdOrig, styleName) {
		var group = sideBarContent.find("div#" + groupName + "_"
				+ obj.Helper.containerId + "_stylecontainer");
		if (group.length <= 0) {
			obj.addStyleTemplateGroup(obj, sideBarContent, groupName,
					displayGroupName);
			group = sideBarContent.find("div#" + groupName + "_"
					+ obj.Helper.containerId + "_stylecontainer");
		}
		var actionContainerId = actionId + "_" + obj.Helper.containerId;
		var actionEntry = group.find("div#" + actionContainerId);
		if (actionEntry != null && actionEntry.attr("id") == actionContainerId) {
			obj.removeStyleTemplate(obj, sideBarContent, groupName, actionId);
		}
		var actionContainer = jQuery("<div>" + styleName + "</div>").addClass(
				"styleTemplateContainer").addClass("transparent-border")
				.addClass("ui-corner-all").attr("id", actionContainerId).bind(
						'click', function() {
							obj.invokeAction(actionIdOrig, null);
						}).bind(
						'mouseover',
						function() {
							jQuery(this).addClass("ui-state-hover")
									.removeClass("transparent-border");
						}).bind(
						'mouseout',
						function() {
							jQuery(this).removeClass("ui-state-hover")
									.addClass("transparent-border");
						});
		group.append(actionContainer);
	}
	this.refreshStyleTemplateStates = function(obj, sideBarContent, groupName,
			container, selectedState, enabledState) {
		if (container != null) {
			if (selectedState === true) {
				container.addClass("ui-state-active");
			} else {
				container.removeClass("ui-state-active");
			}
			if (enabledState === true) {
				container.addClass("styleTemplateVisible").removeClass(
						"styleTemplateHidden");
			} else {
				container.addClass("styleTemplateHidden").removeClass(
						"styleTemplateVisible");
			}
		}
		if (groupName != null) {
			if (sideBarContent.find(
					"#" + groupName + "_" + obj.Helper.containerId
							+ "_stylecontainer").children(
					"div.styleTemplateVisible").length > 1) {
				sideBarContent.find(
						"#" + groupName + "_" + obj.Helper.containerId).css({
					"display" : "block"
				});
			} else {
				sideBarContent.find(
						"#" + groupName + "_" + obj.Helper.containerId).css({
					"display" : "none"
				});
			}
		}
	}
	this.initializeStyleTemplates = function(obj, args) {
		var obj = this;
		styletemplateenabled = this.Helper.config.enablestyletemplatepanel;
		if (styletemplateenabled === undefined
				|| styletemplateenabled == "true"
				|| styletemplateenabled === true) {
			jQuery("#SafariFixToolbar").html("&nbsp;");
			var cId = obj.Helper.containerId;
			var sideBar = jQuery("#" + cId + "_sidebar");
			var sideBarContent = sideBar.find("#" + cId + "_sidebar_content");
			sideBarContent.detach();
			sideBarContent.empty();
			jQuery
					.each(
							args,
							function(i, val) {
								var actionId = String(val[0]);
								var styleName = val[1];
								var groupName = String(val[2]);
								var enabledState = val[3];
								var selectedState = val[4];
								var changeType = val[5];
								var localizedName = obj.Helper.LocaleObject[styleName];
								if (localizedName != undefined) {
									styleName = localizedName;
								}
								var displayGroupName = groupName;
								var localizedGroupName = obj.Helper.LocaleObject[displayGroupName];
								if (localizedGroupName != undefined) {
									displayGroupName = localizedGroupName;
								}
								groupName = groupName.replace(/ /g, "_");
								var actionIdOrig = actionId;
								actionId = actionIdOrig.replace(/ /g, "_");
								obj.addStyleTemplate(obj, sideBarContent,
										groupName, displayGroupName, actionId,
										actionIdOrig, styleName);
								var container = sideBarContent.find("#"
										+ actionId + "_"
										+ obj.Helper.containerId);
								obj.refreshStyleTemplateStates(obj,
										sideBarContent, groupName, container,
										selectedState, enabledState);
							});
			sideBar.append(sideBarContent);
			jQuery("#SafariFixToolbar").html("");
		}
	}
	this.updateStyleTemplates = function(obj, args) {
		this.Logger.log("[updateStyleTemplates]: Started", "FINEST");
		var obj = this;
		styletemplateenabled = this.Helper.config.enablestyletemplatepanel;
		if (styletemplateenabled === undefined
				|| styletemplateenabled == "true"
				|| styletemplateenabled === true) {
			var cId = obj.Helper.containerId;
			var sideBar = jQuery("#" + cId + "_sidebar");
			var sideBarContent = sideBar.find("#" + cId + "_sidebar_content");
			sideBarContent.detach();
			jQuery
					.each(
							args,
							function(i, val) {
								var actionId = String(val[0]);
								var styleName = val[1];
								var groupName = String(val[2]);
								var enabledState = val[3];
								var selectedState = val[4];
								var changeType = val[5];
								groupName = groupName.replace(/ /g, "_");
								var actionIdOrig = actionId;
								actionId = actionIdOrig.replace(/ /g, "_");
								var container = sideBarContent.find("#"
										+ actionId + "_" + cId);
								if (changeType != 0) {
									var localizedName = obj.Helper.LocaleObject[styleName];
									if (localizedName != undefined) {
										styleName = localizedName;
									}
									var displayGroupName = groupName;
									var localizedGroupName = obj.Helper.LocaleObject[displayGroupName];
									if (localizedGroupName != undefined) {
										displayGroupName = localizedGroupName;
									}
									if (changeType == -1 && container != null) {
										obj.removeStyleTemplate(obj,
												sideBarContent, groupName,
												actionId);
									} else if (changeType == 1) {
										obj.addStyleTemplate(obj,
												sideBarContent, groupName,
												displayGroupName, actionId,
												actionIdOrig, styleName);
									}
								}
								container = sideBarContent.find("#" + actionId
										+ "_" + cId);
								obj.refreshStyleTemplateStates(obj,
										sideBarContent, groupName, container,
										selectedState, enabledState);
							});
			sideBar.append(sideBarContent);
		}
	}
	this.updateStyleTemplateStates = function(obj, args) {
		this.Logger.log("[updateStyleTemplateStates]: Started", "FINEST");
		var obj = this;
		styletemplateenabled = this.Helper.config.enablestyletemplatepanel;
		if (styletemplateenabled === undefined
				|| styletemplateenabled == "true"
				|| styletemplateenabled === true) {
			var cId = obj.Helper.containerId;
			var sideBar = jQuery("#" + cId + "_sidebar");
			var sideBarContent = sideBar.find("#" + cId + "_sidebar_content")
					.detach();
			jQuery.each(args, function(i, val) {
				var actionId = String(val[0]);
				var styleName = val[1];
				var groupName = String(val[2]);
				var enabledState = val[3];
				var selectedState = val[4];
				var changeType = val[5];
				groupName = groupName.replace(/ /g, "_");
				var actionIdOrig = actionId;
				actionId = actionIdOrig.replace(/ /g, "_");
				if (changeType == 0) {
					var container = sideBarContent.find("#" + actionId + "_"
							+ cId);
					obj.refreshStyleTemplateStates(obj, sideBarContent,
							groupName, container, selectedState, enabledState);
				}
			});
			sideBar.append(sideBarContent);
		}
	}
	this.updateVirtualCaret = function(posX, posY, caretWidth, caretHeight) {
		if (!this.Helper.disableVirtualCaret) {
			offset = jQuery("#" + this.Helper.containerId + "_eong").offset();
			offsetY = offset.top + parseInt(posY) - 15;
			offsetX = offset.left + parseInt(posX);
			jQuery("#" + this.Helper.containerId + "_virtualCaret").css({
				top : offsetY,
				left : offsetX,
				width : caretWidth,
				height : caretHeight
			});
			try {
				this.Helper.scrollToViewPort("#" + this.Helper.containerId
						+ "_virtualCaret");
			} catch (err) {
				this.Logger.log(
						"[updateVirtualCaret]: Scrolling to viewport failed: "
								+ err, "SEVERE", this);
			}
		}
	};
	this.updateWebdavChooserInput = function(element, value) {
		jQuery(element).val(unescape(value));
	};
};
eongApplication.ToolkitInternal = function(apiObject) {
	this._getPageProperties = function() {
		var props = apiObject.getObj().getPageProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._setPageProperties = function(json) {
		apiObject.getObj().setPageProperties(json);
	};
	this._isIdValidAndAvailable = function(text) {
		return apiObject.getObj().isIdValidAndAvailable(text);
	};
	this._getBookmarkProperties = function() {
		var props = apiObject.getObj().getBookmarkProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getHyperlinkProperties = function() {
		var props = apiObject.getObj().getHyperlinkProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._isCrossReferenceSelected = function() {
		return apiObject.getObj().isCrossReferenceSelected();
	};
	this._getCrossReferenceBlockList = function() {
		var props = apiObject.getObj().getCrossReferenceBlockList();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getCurrentCrossReferenceProperties = function() {
		var props = apiObject.getObj().getCurrentCrossReferenceProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._insertCrossReference = function(data) {
		apiObject.getObj().insertCrossReference(data);
	};
	this._editCrossReference = function(data) {
		apiObject.getObj().editCrossReference(data);
	};
	this._compareDocumentsFromURL = function(url1, url2) {
		apiObject.getObj().compareDocumentsFromURL(url1, url2);
	};
	this._getImageProperties = function() {
		var props = apiObject.getObj().getImageProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getUserPreferences = function(up) {
		return apiObject.Helper.getUserPreferences(up);
	};
	this._setUserPreferences = function(obj) {
		apiObject.Helper.setUserPreferences(obj);
	};
	this._getTableProperties = function() {
		var props = apiObject.getObj().getTableProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getRowProperties = function() {
		var props = apiObject.getObj().getRowProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getColumnProperties = function() {
		var props = apiObject.getObj().getColumnProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getCellProperties = function() {
		var props = apiObject.getObj().getCellProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._initializeInsertAnnotationHelper = function() {
		apiObject.getObj().initializeInsertAnnotationHelper();
	};
	this._getInsertAnnotationProperties = function() {
		var props = apiObject.getObj().getInsertAnnotationProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._initializeEditAnnotationHelper = function() {
		apiObject.getObj().initializeEditAnnotationHelper();
	};
	this._getEditAnnotationProperties = function() {
		var props = apiObject.getObj().getEditAnnotationProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getObjectProperties = function() {
		var props = apiObject.getObj().getObjectProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._getLanguageNames = function() {
		return jQuery.secureEvalJSON(apiObject.getObj().getLanguageNames());
	};
	this._getLanguageCodes = function() {
		return jQuery.secureEvalJSON(apiObject.getObj().getLanguageCodes());
	};
	this._getDocumentProperties = function() {
		var props = apiObject.getObj().getDocumentProperties();
		if (props !== "")
			props = jQuery.evalJSON(props);
		return props;
	};
	this._setDocumentProperties = function(properties) {
		apiObject.getObj().setDocumentProperties(properties);
	};
	this._updateRuler = function() {
		if (arguments.length > 0 && arguments[0] != undefined) {
			var updateJSON = arguments[0][0];
			apiObject.RulerController.updateRuler(updateJSON);
		}
	}
};
function EONG_callMethod(jsonArray, jsWrapperRef) {
	try {
		eval("var json = " + jsonArray.toString());
	} catch (err1) {
		alert("[SEVERE][CallMethod]: Error in evaluating jsonArray: " + err1);
	}
	var eongobj = json[0];
	this.Logger = eval(eongobj + ".Logger");
	this.Logger.log("[CallMethod]: Started, eval'd jsonArray", "FINEST", this);
	var func = json[1];
	var args = json[2];
	if (func == eongobj + ".updateVirtualCaret") {
		this.Logger.log("[CallMethod][updateVirtualCaret]: Started", "FINEST",
				this);
		loggerHelper = this.Logger;
		args = json[2];
		try {
			eval(eongobj
					+ ".updateVirtualCaret(args[0], args[1], args[2], args[3])");
		} catch (err10) {
		}
		this.Logger.log("[CallMethod][updateFileChooserInput]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateFileChooserInput") {
		this.Logger.log("[CallMethod][updateFileChooserInput]: Started",
				"FINEST", this);
		loggerHelper = this.Logger;
		args = json[2];
		args[1] = escape(args[1]);
		try {
			eval(eongobj + ".updateFileChooserInput(args[0], args[1])");
		} catch (err2) {
			loggerHelper.log(
					"[CallMethod][updateFileChooserInput]: calling failed with ("
							+ val[0] + ", " + val[1] + "), Error: " + err2,
					"SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateFileChooserInput]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateWebdavChooserInput") {
		this.Logger.log("[CallMethod][updateWebdavChooserInput]: Started",
				"FINEST", this);
		loggerHelper = this.Logger;
		args = json[2];
		args[1] = escape(args[1]);
		try {
			eval(eongobj + ".updateWebdavChooserInput(args[0], args[1])");
		} catch (err3) {
			loggerHelper.log(
					"[CallMethod][updateWebdavChooserInput]: calling failed with ("
							+ val[0] + ", " + val[1] + "), Error: " + err3,
					"SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateWebdavChooserInput]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateAction") {
		this.Logger.log("[CallMethod][updateAction]: Started", "FINEST", this);
		loggerHelper = this.Logger;
		jQuery.each(json[2], function(i, val) {
			try {
				eval(eongobj + ".updateAction(val[0], val[1], val[2])");
			} catch (err4) {
				loggerHelper.log(
						"[CallMethod][updateAction]: calling failed with ("
								+ val[0] + ", " + val[1] + "," + val[2]
								+ "), Error: " + err4, "SEVERE", this);
			}
		});
		this.Logger.log("[CallMethod][updateAction]: Finished", "FINEST", this);
	} else if (func == eongobj + ".initializeStyleTemplates") {
		this.Logger.log("[CallMethod][initializeStyleTemplates]: Started",
				"FINEST", this);
		try {
			eval(eongobj + ".initializeStyleTemplates(eongobj,args)");
		} catch (err5) {
			this.Logger.log(
					"[CallMethod][initializeStyleTemplates]: calling failed with ("
							+ args + "), Error: " + err5, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][initializeStyleTemplates]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateStyleTemplates") {
		this.Logger.log("[CallMethod][updateStyleTemplates]: Started",
				"FINEST", this);
		try {
			eval(eongobj + ".updateStyleTemplates(eongobj,args)");
		} catch (err5) {
			this.Logger.log(
					"[CallMethod][updateStyleTemplates]: calling failed with ("
							+ args + "), Error: " + err5, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateStyleTemplates]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateStyleTemplateStates") {
		this.Logger.log("[CallMethod][updateStyleTemplateStates]: Started",
				"FINEST", this);
		try {
			eval(eongobj + ".updateStyleTemplateStates(eongobj,args)");
		} catch (err5) {
			this.Logger.log(
					"[CallMethod][updateStyleTemplateStates]: calling failed with ("
							+ args + "), Error: " + err5, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateStyleTemplateStates]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".updateDocumentPalette") {
		this.Logger.log("[CallMethod][updateDocumentPalette]: Started",
				"FINEST", this);
		try {
			eval(eongobj + ".updateDocumentPalette(eongobj,args)");
		} catch (err6) {
			this.Logger.log(
					"[CallMethod][updateDocumentPalette]: calling failed with ("
							+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateDocumentPalette]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".setReplacementImage") {
		this.Logger.log("[CallMethod][setReplacementImage]: Started", "FINEST",
				this);
		try {
			eval(eongobj + ".setReplacementImage(eongobj,args)");
		} catch (err7) {
			this.Logger.log(
					"[CallMethod][setReplacementImage]: calling failed with ("
							+ args + "), Error: " + err7, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][setReplacementImage]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".initializeToolbar") {
		this.Logger.log("[CallMethod][initializeToolbar]: Started", "FINEST",
				this);
		try {
			eval(eongobj + ".initializeToolbar(args)");
		} catch (err9) {
			this.Logger.log(
					"[CallMethod][initializeToolbar]: calling failed with ("
							+ args + "), Error: " + err9, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][initializeToolbar]: Finished", "FINEST",
				this);
	} else if (func == eongobj + ".initializeJS") {
		this.Logger.log("[CallMethod][initializeJS]: Started", "FINEST", this);
		try {
			eval(eongobj + ".initializeJS(jsWrapperRef)");
		} catch (err9) {
			this.Logger.log("[CallMethod][initializeJS]: calling failed with ("
					+ args + "), Error: " + err9, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][initializeJS]: Finished", "FINEST", this);
	} else if (func == eongobj + ".callEventHandler") {
		this.Logger.log("[CallMethod][callEventHandler]: Started", "FINEST",
				this);
		try {
			return eval(eongobj + ".callEventHandler(args)");
		} catch (err9) {
			this.Logger.log(
					"[CallMethod][callEventHandler]: calling failed with ("
							+ args + "), Error: " + err9, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][callEventHandler]: Finished", "FINEST",
				this);
	} else if (func == eongobj + ".updateDocumentCounter") {
		this.Logger.log("[CallMethod][updateDocumentCounter]: Started",
				"FINEST", this);
		try {
			if (args !== null) {
				var characters = args[0];
				var isUpdate = args[1];
				var eventHandler = args[2];
				if (eventHandler !== null) {
					params = [];
					params[0] = eventHandler;
					params[1] = characters;
					eval(eongobj + ".callEventHandler(params)");
				}
				if (isUpdate) {
					eval(eongobj + ".updateDocumentCounter(eongobj,characters)");
				}
			}
		} catch (err6) {
			this.Logger.log(
					"[CallMethod][updateDocumentCounter]: calling failed with ("
							+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][updateDocumentCounter]: Finished",
				"FINEST", this);
	} else if (func == eongobj + ".invokeAction") {
		this.Logger.log("[CallMethod][invokeAction]: Started", "FINEST", this);
		try {
			eval(eongobj + ".invokeAction(args)");
		} catch (err6) {
			this.Logger.log("[CallMethod][invokeAction]: calling failed with ("
					+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][invokeAction]: Finished", "FINEST", this);
	} else if (func == eongobj + ".scrollToHelper") {
		this.Logger
				.log("[CallMethod][scrollToHelper]: Started", "FINEST", this);
		try {
			eval(eongobj + ".scrollToHelper(args)");
		} catch (err6) {
			this.Logger.log(
					"[CallMethod][scrollToHelper]: calling failed with ("
							+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][scrollToHelper]: Finished", "FINEST",
				this);
	} else if (func == eongobj + ".updatePageCount") {
		this.Logger.log("[CallMethod][updatePageCount]: Started", "FINEST",
				this);
		try {
			eval(eongobj + ".updatePageCount(args)");
		} catch (err6) {
			this.Logger.log(
					"[CallMethod][updatePageCount]: calling failed with ("
							+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][updatePageCount]: Finished", "FINEST",
				this);
	} else if (func == eongobj + ".toolkitInternal._updateRuler") {
		this.Logger.log("[CallMethod][_updateRuler]: Started", "FINEST", this);
		try {
			eval(eongobj + ".toolkitInternal._updateRuler(args)");
		} catch (err6) {
			this.Logger.log("[CallMethod][_updateRuler]: calling failed with ("
					+ args + "), Error: " + err6, "SEVERE", this);
		}
		this.Logger.log("[CallMethod][_updateRuler]: Finished", "FINEST", this);
	} else if (func !== null) {
		var params = "(" + eongobj;
		if (args !== null) {
			params += ", " + args;
		}
		params += ")";
		sHandler = func + params;
		try {
			this.Logger.log("[CallMethod][Generic function]: calling  " + func
					+ " with (" + params + ")", "FINEST", this);
			eval(sHandler);
		} catch (err8) {
			this.Logger.log("[CallMethod][Generic function]: calling " + func
					+ " failed with (" + args + "). Error: " + err8, "SEVERE",
					this);
		}
	}
	this.Logger.log("[CallMethod]: Finished", "FINEST", this);
};
function getRelativePath() {
	var myName = /(^|[\/\\])edit-on-ng.js(\?|$)/;
	var scripts = document.getElementsByTagName("script");
	for (var i = 0; i < scripts.length; i++) {
		var src;
		src = scripts[i].getAttribute("src");
		if (src !== undefined && src !== null) {
			if (src.match(myName)) {
				result = src.replace(/edit-on-ng.js/, "");
				return result;
			}
		}
	}
	return "";
};
eongApplication.Action = function(actionId, actionLogger, Helper) {
	this.actionId = actionId;
	this.enabled = null;
	this.SelectedState = null;
	this.StringState = null;
	this.controllers = [];
	this.Helper = Helper;
	this.setenabled = function(paramValue) {
		actionLogger.log("[Action][SetEnabled - " + this.actionId
				+ "]: Started", "FINEST", this);
		this.enabled = paramValue;
		var enabled = (paramValue.toString() === 'true');
		actionLogger.log("[Action][SetEnabled]: Enabled: " + enabled, "ALL",
				this);
		jQuery
				.each(
						this.controllers,
						function(i, elem) {
							elem["elem"].disabled = !enabled;
							actionLogger.log(
									"[Action][SetEnabled - Controllers]: i: "
											+ i + ", Elem.disabled: "
											+ elem.disabled, "ALL", this);
							if (enabled) {
								jQuery(elem["elem"]).addClass("enabled");
								jQuery(elem["elemParent"]).addClass("enabled");
							} else {
								jQuery(elem["elem"]).removeClass("enabled");
								jQuery(elem["elemParent"]).removeClass(
										"enabled");
							}
							actionLogger
									.log(
											"[Action][SetEnabled]: Enabled ? addClass(enabled) : removeClass(enabled)",
											"ALL", this);
							if (!enabled) {
								jQuery(elem["elem"]).addClass("disabled");
								jQuery(elem["elemParent"]).addClass("disabled");
							} else {
								jQuery(elem["elem"]).removeClass("disabled");
								jQuery(elem["elemParent"]).removeClass(
										"disabled");
							}
							actionLogger
									.log(
											"[Action][SetEnabled]: Not Enabled ? addClass(disabled) : removeClass(disabled)",
											"ALL", this);
						});
		actionLogger.log("[Action][SetEnabled - " + this.actionId
				+ "]: Finished", "FINEST", this);
	};
	this.setSelectedState = function(paramValue) {
		actionLogger.log("[Action][SetSelectedState - " + this.actionId
				+ "]: Started", "FINEST", this);
		this.SelectedState = paramValue;
		var enabled = (paramValue.toString() === 'true');
		actionLogger.log("[Action][SetSelectedState enabled: " + enabled,
				"ALL", this);
		jQuery
				.each(
						this.controllers,
						function(i, elem) {
							actionLogger.log(
									"[Action][SetSelectedState - Controllers]: i: "
											+ i + ", Enabled: " + enabled,
									"ALL", this);
							if (enabled) {
								actionLogger
										.log(
												"[Action][SetSelectedState]: Enabled: Setting highlight",
												"ALL", this);
								jQuery(elem["elemParent"]).addClass(
										"highlight ui-state-active");
							} else {
								actionLogger
										.log(
												"[Action][SetSelectedState]: Not Enabled: Removing highlight",
												"ALL", this);
								jQuery(elem["elemParent"]).removeClass(
										"highlight ui-state-active");
							}
						});
		actionLogger.log("[Action][SetSelectedState - " + this.actionId
				+ "]: Finished", "FINEST", this);
	};
	this.setStringState = function(paramValue) {
		actionLogger.log("[Action][SetStringState - " + this.actionId
				+ "]: Started", "FINEST", this);
		this.StringState = paramValue;
		var stringState = paramValue;
		if (stringState === "null" || stringState === null) {
			stringState = "";
		}
		if (this.Helper.config.fontsettings !== undefined
				&& this.Helper.config.fontsettings.fontlist !== undefined) {
			jQuery.each(this.Helper.config.fontsettings.fontlist, function(
					index, value) {
				if (value.family === stringState) {
					stringState = value.displayname;
					return false;
				}
			});
		}
		actionLogger.log("[Action][SetStringState[" + this.actionId + "]: "
				+ stringState, "FINEST", this);
		jQuery.each(this.controllers, function(i, elem) {
			if (elem["elem"].tagName.toLowerCase() === "input") {
				jQuery(elem["elem"]).attr("value", stringState);
				jQuery(elem["elem"]).attr("alt", "");
			}
		});
		actionLogger.log("[Action][SetStringState - " + this.actionId
				+ "]: Finished", "FINEST", this);
	};
};
eongApplication.actionMap = function() {
	this.actionMap = {
		"insert-structure-template-dialog" : {
			"type" : "js",
			"functionName" : "insertStructureTemplateDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_STRUCTURE_TEMPLATE_DIALOG",
			"iconText" : "L_INSERT_STRUCTURE_TEMPLATE_DIALOG_TEXT"
		},
		"load-url-dialog" : {
			"type" : "js",
			"functionName" : "loadURLDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_LOAD_URL_DIALOG",
			"iconText" : "L_LOAD_URL_DIALOG_TEXT"
		},
		"load-document-dialog" : {
			"type" : "java",
			"title" : "L_LOAD_DOCUMENT_FILE_DIALOG",
			"iconText" : "L_LOAD_DOCUMENT_FILE_DIALOG_TEXT"
		},
		"insert-image-dialog" : {
			"type" : "js",
			"functionName" : "insertImageDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_IMAGE_DIALOG",
			"iconText" : "L_INSERT_IMAGE_DIALOG_TEXT"
		},
		"image-properties-dialog" : {
			"type" : "js",
			"functionName" : "imagePropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_IMAGE_PROPERTIES_DIALOG",
			"iconText" : "L_IMAGE_PROPERTIES_DIALOG_TEXT"
		},
		"image-properties" : {
			"type" : "java",
			"title" : "L_IMAGE_PROPERTIES_DIALOG",
			"iconText" : "L_IMAGE_PROPERTIES_DIALOG_TEXT"
		},
		"abbr" : {
			"type" : "java",
			"title" : "L_ABBR",
			"iconText" : "L_ABBR_TEXT"
		},
		"acronym" : {
			"type" : "java",
			"title" : "L_ACRONYM",
			"iconText" : "L_ACRONYM_TEXT"
		},
		"cite" : {
			"type" : "java",
			"title" : "L_CITE",
			"iconText" : "L_CITE_TEXT"
		},
		"code" : {
			"type" : "java",
			"title" : "L_CODE",
			"iconText" : "L_CODE_TEXT"
		},
		"dfn" : {
			"type" : "java",
			"title" : "L_DFN",
			"iconText" : "L_DFN_TEXT"
		},
		"em" : {
			"type" : "java",
			"title" : "L_EM",
			"iconText" : "L_EM_TEXT"
		},
		"kbd" : {
			"type" : "java",
			"title" : "L_KBD",
			"iconText" : "L_KBD_TEXT"
		},
		"samp" : {
			"type" : "java",
			"title" : "L_SAMP",
			"iconText" : "L_SAMP_TEXT"
		},
		"strong" : {
			"type" : "java",
			"title" : "L_STRONG",
			"iconText" : "L_STRONG_TEXT"
		},
		"var" : {
			"type" : "java",
			"title" : "L_VAR",
			"iconText" : "L_VAR_TEXT"
		},
		"q" : {
			"type" : "java",
			"title" : "L_Q",
			"iconText" : "L_Q_TEXT"
		},
		"insert-image" : {
			"type" : "java",
			"title" : "L_INSERT_IMAGE",
			"iconText" : "L_INSERT_IMAGE_TEXT"
		},
		"insert-object" : {
			"type" : "java",
			"title" : "L_INSERT_OBJECT",
			"iconText" : "L_INSERT_OBJECT_TEXT"
		},
		"insert-bookmark" : {
			"type" : "java",
			"title" : "L_INSERT_BOOKMARK",
			"iconText" : "L_INSERT_BOOKMARK_TEXT"
		},
		"change-bookmark" : {
			"type" : "java",
			"title" : "L_CHANGE_BOOKMARK",
			"iconText" : "L_CHANGE_BOOKMARK_TEXT"
		},
		"move-to-next-bookmark" : {
			"type" : "java",
			"title" : "L_MOVE_TO_NEXT_BOOKMARK",
			"iconText" : "L_MOVE_TO_NEXT_BOOKMARK_TEXT"
		},
		"move-to-previous-bookmark" : {
			"type" : "java",
			"title" : "L_MOVE_TO_PREVIOUS_BOOKMARK",
			"iconText" : "L_MOVE_TO_PREVIOUS_BOOKMARK_TEXT"
		},
		"move-to-bookmark" : {
			"type" : "java",
			"title" : "L_MOVE_TO_BOOKMARK",
			"iconText" : "L_MOVE_TO_BOOKMARK_TEXT"
		},
		"remove-bookmark" : {
			"type" : "java",
			"title" : "L_REMOVE_BOOKMARK",
			"iconText" : "L_REMOVE_BOOKMARK_TEXT"
		},
		"remove-hyperlink" : {
			"type" : "java",
			"title" : "L_REMOVE_HYPERLINK",
			"iconText" : "L_REMOVE_HYPERLINK_TEXT"
		},
		"insert-bookmark-dialog" : {
			"type" : "js",
			"functionName" : "insertBookmarkDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_BOOKMARK_DIALOG",
			"iconText" : "L_INSERT_BOOKMARK_DIALOG_TEXT"
		},
		"bookmark-properties-dialog" : {
			"type" : "js",
			"functionName" : "bookmarkPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_BOOKMARK_PROPERTIES_DIALOG",
			"iconText" : "L_BOOKMARK_PROPERTIES_DIALOG_TEXT"
		},
		"insert-hyperlink-dialog" : {
			"type" : "js",
			"functionName" : "insertHyperlinkDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_HYPERLINK_DIALOG",
			"iconText" : "L_INSERT_HYPERLINK_DIALOG_TEXT"
		},
		"hyperlink-properties-dialog" : {
			"type" : "js",
			"functionName" : "linkPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_HYPERLINK_PROPERTIES_DIALOG",
			"iconText" : "L_HYPERLINK_PROPERTIES_DIALOG_TEXT"
		},
		"horizontal-line-properties" : {
			"type" : "java",
			"title" : "L_HORIZONTAL_LINE_PROPERTIES_DIALOG",
			"iconText" : "L_HORIZONTAL_LINE_PROPERTIES_DIALOG_TEXT"
		},
		"horizontal-line-properties-dialog" : {
			"type" : "js",
			"functionName" : "horizontalLinePropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_HORIZONTAL_LINE_PROPERTIES_DIALOG",
			"elementNames" : [ "hr" ],
			"iconText" : "L_HORIZONTAL_LINE_PROPERTIES_DIALOG_TEXT"
		},
		"insert-object-dialog" : {
			"type" : "js",
			"functionName" : "insertObjectDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_OBJECT_DIALOG",
			"iconText" : "L_INSERT_OBJECT_DIALOG_TEXT"
		},
		"object-properties-dialog" : {
			"type" : "js",
			"functionName" : "objectPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_OBJECT_PROPERTIES_DIALOG",
			"elementNames" : [ "object" ],
			"iconText" : "L_OBJECT_PROPERTIES_DIALOG_TEXT"
		},
		"object-properties" : {
			"type" : "java",
			"title" : "L_OBJECT_PROPERTIES_DIALOG",
			"iconText" : "L_OBJECT_PROPERTIES_DIALOG_TEXT"
		},
		"insert-table" : {
			"type" : "java",
			"title" : "L_INSERT_TABLE",
			"iconText" : "L_INSERT_TABLE_TEXT"
		},
		"insert-table-dialog" : {
			"type" : "js",
			"functionName" : "insertTableDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_TABLE_DIALOG",
			"iconText" : "L_INSERT_TABLE_DIALOG_TEXT"
		},
		"insert-special-character-dialog" : {
			"type" : "java",
			"title" : "L_INSERT_SPECIAL_CHARACTER_DIALOG",
			"iconText" : "L_INSERT_SPECIAL_CHARACTER_DIALOG_TEXT"
		},
		"cell-properties" : {
			"type" : "java",
			"title" : "L_CELL_PROPERTIES",
			"iconText" : "L_CELL_PROPERTIES_TEXT"
		},
		"table-properties" : {
			"type" : "java",
			"title" : "L_TABLE_PROPERTIES",
			"iconText" : "L_TABLE_PROPERTIES_TEXT"
		},
		"cell-properties-dialog" : {
			"type" : "js",
			"functionName" : "cellPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_CELL_PROPERTIES_DIALOG",
			"elementNames" : [ "table", "td", "th", "tr" ],
			"iconText" : "L_CELL_PROPERTIES_DIALOG_TEXT"
		},
		"row-properties-dialog" : {
			"type" : "js",
			"functionName" : "rowPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_ROW_PROPERTIES_DIALOG",
			"elementNames" : [ "table", "td", "th", "tr" ],
			"iconText" : "L_ROW_PROPERTIES_DIALOG_TEXT"
		},
		"column-properties" : {
			"type" : "java",
			"title" : "L_COLUMN_PROPERTIES",
			"iconText" : "L_COLUMN_PROPERTIES_TEXT"
		},
		"column-properties-dialog" : {
			"type" : "js",
			"functionName" : "columnPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_COLUMN_PROPERTIES_DIALOG",
			"elementNames" : [ "table", "td", "th", "tr" ],
			"iconText" : "L_COLUMN_PROPERTIES_DIALOG_TEXT"
		},
		"table-properties-dialog" : {
			"type" : "js",
			"functionName" : "tablePropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_TABLE_PROPERTIES_DIALOG",
			"elementNames" : [ "table", "td", "th", "tr" ],
			"iconText" : "L_TABLE_PROPERTIES_DIALOG_TEXT"
		},
		"document-statistics-dialog" : {
			"type" : "js",
			"functionName" : "documentStatisticsDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_DOCUMENT_STATISTICS_DIALOG",
			"iconText" : "L_DOCUMENT_STATISTICS_DIALOG_TEXT"
		},
		"change-case-dialog" : {
			"type" : "js",
			"functionName" : "changeCaseDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_CHANGE_CASE_DIALOG",
			"iconText" : "L_CHANGE_CASE_DIALOG_TEXT"
		},
		"insert-annotation-dialog" : {
			"type" : "js",
			"functionName" : "insertAnnotationDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_ANNOTATION_DIALOG",
			"iconText" : "L_INSERT_ANNOTATION_DIALOG_TEXT"
		},
		"edit-annotation-dialog" : {
			"type" : "js",
			"functionName" : "editAnnotationDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_EDIT_ANNOTATION_DIALOG",
			"elementNames" : [ "annotation" ],
			"iconText" : "L_EDIT_ANNOTATION_DIALOG_TEXT"
		},
		"color-dialog" : {
			"type" : "js",
			"functionName" : "textColorDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_COLOR_DIALOG",
			"iconText" : "L_COLOR_DIALOG_TEXT"
		},
		"backgroundcolor-dialog" : {
			"type" : "js",
			"functionName" : "backgroundColorDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_BACKGROUNDCOLOR_DIALOG",
			"iconText" : "L_BACKGROUNDCOLOR_DIALOG_TEXT"
		},
		"split-cell-dialog" : {
			"type" : "js",
			"functionName" : "splitCellDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_SPLIT_CELL_DIALOG",
			"elementNames" : [ "table", "td", "th", "tr" ],
			"iconText" : "L_SPLIT_CELL_DIALOG_TEXT"
		},
		"change-language-dialog" : {
			"type" : "js",
			"functionName" : "changeLanguageDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_CHANGE_LANGUAGE_DIALOG",
			"iconText" : "L_CHANGE_LANGUAGE_DIALOG_TEXT"
		},
		"document-properties-dialog" : {
			"type" : "js",
			"functionName" : "documentPropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_DOCUMENT_PROPERTIES_DIALOG",
			"iconText" : "L_DOCUMENT_PROPERTIES_DIALOG_TEXT"
		},
		"insert-crossreference-dialog" : {
			"type" : "js",
			"functionName" : "insertCrossreferenceDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_INSERT_CROSSREFERENCE_DIALOG",
			"iconText" : "L_INSERT_CROSSREFERENCE_DIALOG_TEXT"
		},
		"edit-crossreference-dialog" : {
			"type" : "js",
			"functionName" : "editCrossreferenceDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_EDIT_CROSSREFERENCE_DIALOG",
			"elementNames" : [ "crossreference" ],
			"iconText" : "L_EDIT_CROSSREFERENCE_DIALOG_TEXT"
		},
		"information-dialog" : {
			"type" : "java",
			"title" : "L_INFORMATION_DIALOG",
			"iconText" : "L_INFORMATION_DIALOG_TEXT"
		},
		"move-up" : {
			"type" : "java",
			"title" : "L_MOVE_UP",
			"shortcut" : "UP",
			"iconText" : "L_MOVE_UP_TEXT"
		},
		"move-down" : {
			"type" : "java",
			"title" : "L_MOVE_DOWN",
			"shortcut" : "DOWN",
			"iconText" : "L_MOVE_DOWN_TEXT"
		},
		"move-left" : {
			"type" : "java",
			"title" : "L_MOVE_LEFT",
			"shortcut" : "LEFT",
			"iconText" : "L_MOVE_LEFT_TEXT"
		},
		"move-right" : {
			"type" : "java",
			"title" : "L_MOVE_RIGHT",
			"shortcut" : "RIGHT",
			"iconText" : "L_MOVE_RIGHT_TEXT"
		},
		"move-word-left" : {
			"type" : "java",
			"title" : "L_MOVE_WORD_LEFT",
			"shortcut" : "msck LEFT",
			"macShortcut" : "alt LEFT",
			"iconText" : "L_MOVE_WORD_LEFT_TEXT"
		},
		"move-word-right" : {
			"type" : "java",
			"title" : "L_MOVE_WORD_RIGHT",
			"shortcut" : "msck RIGHT",
			"macShortcut" : "alt RIGHT",
			"iconText" : "L_MOVE_WORD_RIGHT_TEXT"
		},
		"move-next-word" : {
			"type" : "java",
			"title" : "L_MOVE_NEXT_WORD",
			"iconText" : "L_MOVE_NEXT_WORD_TEXT"
		},
		"move-previous-word" : {
			"type" : "java",
			"title" : "L_MOVE_PREVIOUS_WORD",
			"iconText" : "L_MOVE_PREVIOUS_WORD_TEXT"
		},
		"move-next-block" : {
			"type" : "java",
			"title" : "L_MOVE_NEXT_BLOCK",
			"shortcut" : "msck DOWN",
			"iconText" : "L_MOVE_NEXT_BLOCK_TEXT"
		},
		"move-previous-block" : {
			"type" : "java",
			"title" : "L_MOVE_PREVIOUS_BLOCK",
			"shortcut" : "msck UP",
			"iconText" : "L_MOVE_PREVIOUS_BLOCK_TEXT"
		},
		"move-next-page" : {
			"type" : "java",
			"title" : "L_MOVE_NEXT_PAGE",
			"shortcut" : "msck PAGE_DOWN",
			"iconText" : "L_MOVE_NEXT_PAGE_TEXT"
		},
		"move-previous-page" : {
			"type" : "java",
			"title" : "L_MOVE_PREVIOUS_PAGE",
			"shortcut" : "msck PAGE_UP",
			"iconText" : "L_MOVE_PREVIOUS_PAGE_TEXT"
		},
		"move-page-start" : {
			"type" : "java",
			"title" : "L_MOVE_PAGE_START",
			"iconText" : "L_MOVE_PAGE_START_TEXT"
		},
		"move-page-end" : {
			"type" : "java",
			"title" : "L_MOVE_PAGE_END",
			"iconText" : "L_MOVE_PAGE_END_TEXT"
		},
		"move-page-up" : {
			"type" : "java",
			"title" : "L_MOVE_PAGE_UP",
			"shortcut" : "PAGE_UP",
			"iconText" : "L_MOVE_PAGE_UP_TEXT"
		},
		"move-page-down" : {
			"type" : "java",
			"title" : "L_MOVE_PAGE_DOWN",
			"shortcut" : "PAGE_DOWN",
			"iconText" : "L_MOVE_PAGE_DOWN_TEXT"
		},
		"move-line-start" : {
			"type" : "java",
			"title" : "L_MOVE_LINE_START",
			"shortcut" : "HOME",
			"macShortcut" : "meta LEFT",
			"iconText" : "L_MOVE_LINE_START_TEXT"
		},
		"move-line-end" : {
			"type" : "java",
			"title" : "L_MOVE_LINE_END",
			"shortcut" : "END",
			"macShortcut" : "meta RIGHT",
			"iconText" : "L_MOVE_LINE_END_TEXT"
		},
		"move-document-start" : {
			"type" : "java",
			"title" : "L_MOVE_DOCUMENT_START",
			"shortcut" : "msck HOME",
			"iconText" : "L_MOVE_DOCUMENT_START_TEXT"
		},
		"move-document-end" : {
			"type" : "java",
			"title" : "L_MOVE_DOCUMENT_END",
			"shortcut" : "msck END",
			"iconText" : "L_MOVE_DOCUMENT_END_TEXT"
		},
		"move-next-table-cell" : {
			"type" : "java",
			"title" : "L_MOVE_NEXT_TABLE_CELL",
			"iconText" : "L_MOVE_NEXT_TABLE_CELL_TEXT"
		},
		"move-previous-table-cell" : {
			"type" : "java",
			"title" : "L_MOVE_PREVIOUS_TABLE_CELL",
			"iconText" : "L_MOVE_PREVIOUS_TABLE_CELL_TEXT"
		},
		"row-properties" : {
			"type" : "java",
			"title" : "L_ROW_PROPERTIES",
			"iconText" : "L_ROW_PROPERTIES_TEXT"
		},
		"select-up" : {
			"type" : "java",
			"title" : "L_SELECT_UP",
			"shortcut" : "shift UP",
			"iconText" : "L_SELECT_UP_TEXT"
		},
		"select-down" : {
			"type" : "java",
			"title" : "L_SELECT_DOWN",
			"shortcut" : "shift DOWN",
			"iconText" : "L_SELECT_DOWN_TEXT"
		},
		"select-left" : {
			"type" : "java",
			"title" : "L_SELECT_LEFT",
			"shortcut" : "shift LEFT",
			"iconText" : "L_SELECT_LEFT_TEXT"
		},
		"select-right" : {
			"type" : "java",
			"title" : "L_SELECT_RIGHT",
			"shortcut" : "shift RIGHT",
			"iconText" : "L_SELECT_RIGHT_TEXT"
		},
		"select-line" : {
			"type" : "java",
			"title" : "L_SELECT_LINE",
			"iconText" : "L_SELECT_LINE_TEXT"
		},
		"select-line-start" : {
			"type" : "java",
			"title" : "L_SELECT_LINE_START",
			"shortcut" : "shift HOME",
			"macShortcut" : "shift meta LEFT",
			"iconText" : "L_SELECT_LINE_START_TEXT"
		},
		"select-line-end" : {
			"type" : "java",
			"title" : "L_SELECT_LINE_END",
			"shortcut" : "shift END",
			"macShortcut" : "shift meta RIGHT",
			"iconText" : "L_SELECT_LINE_END_TEXT"
		},
		"select-page" : {
			"type" : "java",
			"title" : "L_SELECT_PAGE",
			"iconText" : "L_SELECT_PAGE_TEXT"
		},
		"select-page-start" : {
			"type" : "java",
			"title" : "L_SELECT_PAGE_START",
			"iconText" : "L_SELECT_PAGE_START_TEXT"
		},
		"select-page-end" : {
			"type" : "java",
			"title" : "L_SELECT_PAGE_END",
			"iconText" : "L_SELECT_PAGE_END_TEXT"
		},
		"select-next-page" : {
			"type" : "java",
			"title" : "L_SELECT_NEXT_PAGE",
			"shortcut" : "msck shift PAGE_DOWN",
			"iconText" : "L_SELECT_NEXT_PAGE_TEXT"
		},
		"select-previous-page" : {
			"type" : "java",
			"title" : "L_SELECT_PREVIOUS_PAGE",
			"shortcut" : "msck shift PAGE_UP",
			"iconText" : "L_SELECT_PREVIOUS_PAGE_TEXT"
		},
		"select-page-up" : {
			"type" : "java",
			"title" : "L_SELECT_PAGE_UP",
			"shortcut" : "shift PAGE_UP",
			"iconText" : "L_SELECT_PAGE_UP_TEXT"
		},
		"select-page-down" : {
			"type" : "java",
			"title" : "L_SELECT_PAGE_DOWN",
			"shortcut" : "shift PAGE_DOWN",
			"iconText" : "L_SELECT_PAGE_DOWN_TEXT"
		},
		"select-document-start" : {
			"type" : "java",
			"title" : "L_SELECT_DOCUMENT_START",
			"shortcut" : "msck shift HOME",
			"macShortcut" : "shift HOME",
			"iconText" : "L_SELECT_DOCUMENT_START_TEXT"
		},
		"select-document-end" : {
			"type" : "java",
			"title" : "L_SELECT_DOCUMENT_END",
			"shortcut" : "msck shift END",
			"macShortcut" : "shift END",
			"iconText" : "L_SELECT_DOCUMENT_END_TEXT"
		},
		"select-word" : {
			"type" : "java",
			"title" : "L_SELECT_WORD",
			"iconText" : "L_SELECT_WORD_TEXT"
		},
		"select-word-left" : {
			"type" : "java",
			"title" : "L_SELECT_WORD_LEFT",
			"shortcut" : "msck shift LEFT",
			"macShortcut" : "shift alt LEFT",
			"iconText" : "L_SELECT_WORD_LEFT_TEXT"
		},
		"select-word-right" : {
			"type" : "java",
			"title" : "L_SELECT_WORD_RIGHT",
			"shortcut" : "msck shift RIGHT",
			"macShortcut" : "shift alt RIGHT",
			"iconText" : "L_SELECT_WORD_RIGHT_TEXT"
		},
		"select-next-word" : {
			"type" : "java",
			"title" : "L_SELECT_NEXT_WORD",
			"iconText" : "L_SELECT_NEXT_WORD_TEXT"
		},
		"select-previous-word" : {
			"type" : "java",
			"title" : "L_SELECT_PREVIOUS_WORD",
			"iconText" : "L_SELECT_PREVIOUS_WORD_TEXT"
		},
		"select-sentence" : {
			"type" : "java",
			"title" : "L_SELECT_SENTENCE",
			"iconText" : "L_SELECT_SENTENCE_TEXT"
		},
		"select-block" : {
			"type" : "java",
			"title" : "L_SELECT_BLOCK",
			"iconText" : "L_SELECT_BLOCK_TEXT"
		},
		"select-next-block" : {
			"type" : "java",
			"title" : "L_SELECT_NEXT_BLOCK",
			"shortcut" : "msck shift DOWN",
			"macShortcut" : "shift alt DOWN",
			"iconText" : "L_SELECT_NEXT_BLOCK_TEXT"
		},
		"select-previous-block" : {
			"type" : "java",
			"title" : "L_SELECT_PREVIOUS_BLOCK",
			"shortcut" : "msck shift UP",
			"macShortcut" : "shift alt UP",
			"iconText" : "L_SELECT_PREVIOUS_BLOCK_TEXT"
		},
		"select-list" : {
			"type" : "java",
			"title" : "L_SELECT_LIST",
			"iconText" : "L_SELECT_LIST_TEXT"
		},
		"select-list-item" : {
			"type" : "java",
			"title" : "L_SELECT_LIST_ITEM",
			"iconText" : "L_SELECT_LIST_ITEM_TEXT"
		},
		"select-table" : {
			"type" : "java",
			"title" : "L_SELECT_TABLE",
			"iconText" : "L_SELECT_TABLE_TEXT"
		},
		"select-table-caption" : {
			"type" : "java",
			"title" : "L_SELECT_TABLE_CAPTION",
			"iconText" : "L_SELECT_TABLE_CAPTION_TEXT"
		},
		"select-table-row" : {
			"type" : "java",
			"title" : "L_SELECT_TABLE_ROW",
			"iconText" : "L_SELECT_TABLE_ROW_TEXT"
		},
		"select-table-column" : {
			"type" : "java",
			"title" : "L_SELECT_TABLE_COLUMN",
			"iconText" : "L_SELECT_TABLE_COLUMN_TEXT"
		},
		"select-table-cell" : {
			"type" : "java",
			"title" : "L_SELECT_TABLE_CELL",
			"iconText" : "L_SELECT_TABLE_CELL_TEXT"
		},
		"select-all" : {
			"type" : "java",
			"title" : "L_SELECT_ALL",
			"shortcut" : "msck A",
			"iconText" : "L_SELECT_ALL_TEXT"
		},
		"scroll-up" : {
			"type" : "java",
			"title" : "L_SCROLL_UP",
			"shortcut" : "msck alt UP",
			"iconText" : "L_SCROLL_UP_TEXT"
		},
		"scroll-down" : {
			"type" : "java",
			"title" : "L_SCROLL_DOWN",
			"shortcut" : "msck alt DOWN",
			"iconText" : "L_SCROLL_DOWN_TEXT"
		},
		"scroll-left" : {
			"type" : "java",
			"title" : "L_SCROLL_LEFT",
			"iconText" : "L_SCROLL_LEFT_TEXT"
		},
		"scroll-right" : {
			"type" : "java",
			"title" : "L_SCROLL_RIGHT",
			"iconText" : "L_SCROLL_RIGHT_TEXT"
		},
		"return-key" : {
			"type" : "java",
			"title" : "L_RETURN_KEY",
			"shortcut" : "ENTER",
			"iconText" : "L_RETURN_KEY_TEXT"
		},
		"delete-backward" : {
			"type" : "java",
			"title" : "L_BACKSPACE_KEY",
			"shortcut" : "BACK_SPACE",
			"iconText" : "L_BACKSPACE_KEY_TEXT"
		},
		"delete-forward" : {
			"type" : "java",
			"title" : "L_DELETE_KEY",
			"shortcut" : "DELETE",
			"iconText" : "L_DELETE_KEY_TEXT"
		},
		"tab-key" : {
			"type" : "java",
			"title" : "L_TAB_KEY",
			"shortcut" : "TAB",
			"iconText" : "L_TAB_KEY_TEXT"
		},
		"shift-tab-key" : {
			"type" : "java",
			"title" : "L_SHIFT_TAB_KEY",
			"shortcut" : "shift TAB",
			"iconText" : "L_SHIFT_TAB_KEY_TEXT"
		},
		"delete-selection" : {
			"type" : "java",
			"title" : "L_DELETE_SELECTION",
			"iconText" : "L_DELETE_SELECTION_TEXT"
		},
		"delete-selection-special" : {
			"type" : "java",
			"title" : "L_DELETE_SELECTION_SPECIAL",
			"iconText" : "L_DELETE_SELECTION_SPECIAL_TEXT"
		},
		"delete-tab" : {
			"type" : "java",
			"title" : "L_DELETE_TABULATOR",
			"iconText" : "L_DELETE_TABULATOR_TEXT"
		},
		"delete-next-character" : {
			"type" : "java",
			"title" : "L_DELETE_NEXT_CHARACTER",
			"iconText" : "L_DELETE_NEXT_CHARACTER_TEXT"
		},
		"delete-previous-character" : {
			"type" : "java",
			"title" : "L_DELETE_PREVIOUS_CHARACTER",
			"iconText" : "L_DELETE_PREVIOUS_CHARACTER_TEXT"
		},
		"delete-next-paragraph-break" : {
			"type" : "java",
			"title" : "L_DELETE_NEXT_PARAGRAPH_BREAK",
			"iconText" : "L_DELETE_NEXT_PARAGRAPH_BREAK_TEXT"
		},
		"delete-previous-paragraph-break" : {
			"type" : "java",
			"title" : "L_DELETE_PREVIOUS_PARAGRAPH_BREAK",
			"iconText" : "L_DELETE_PREVIOUS_PARAGRAPH_BREAK_TEXT"
		},
		"delete-block" : {
			"type" : "java",
			"title" : "L_DELETE_BLOCK",
			"iconText" : "L_DELETE_BLOCK_TEXT"
		},
		"insert-tab" : {
			"type" : "java",
			"title" : "L_INSERT_TABULATOR",
			"iconText" : "L_INSERT_TABULATOR_TEXT"
		},
		"insert-paragraph-break" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_BREAK",
			"iconText" : "L_INSERT_PARAGRAPH_BREAK_TEXT"
		},
		"insert-list-item-break" : {
			"type" : "java",
			"title" : "L_INSERT_LIST_ITEM_BREAK",
			"iconText" : "L_INSERT_LIST_ITEM_BREAK_TEXT"
		},
		"insert-next-element-template" : {
			"type" : "java",
			"title" : "L_INSERT_NEXT_ELEMENT_TEMPLATE",
			"iconText" : "L_INSERT_NEXT_ELEMENT_TEMPLATE_TEXT"
		},
		"insert-paragraph-before-block" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_BEFORE_BLOCK",
			"iconText" : "L_INSERT_PARAGRAPH_BEFORE_BLOCK_TEXT"
		},
		"insert-paragraph-after-block" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_AFTER_BLOCK",
			"iconText" : "L_INSERT_PARAGRAPH_AFTER_BLOCK_TEXT"
		},
		"insert-paragraph-before-container" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_BEFORE_CONTAINER",
			"iconText" : "L_INSERT_PARAGRAPH_BEFORE_CONTAINER_TEXT"
		},
		"insert-paragraph-after-container" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_AFTER_CONTAINER",
			"iconText" : "L_INSERT_PARAGRAPH_AFTER_CONTAINER_TEXT"
		},
		"insert-paragraph-before-list" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_BEFORE_LIST",
			"iconText" : "L_INSERT_PARAGRAPH_BEFORE_LIST_TEXT"
		},
		"insert-paragraph-after-list" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_AFTER_LIST",
			"iconText" : "L_INSERT_PARAGRAPH_AFTER_LIST_TEXT"
		},
		"insert-paragraph-before-table" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_BEFORE_TABLE",
			"iconText" : "L_INSERT_PARAGRAPH_BEFORE_TABLE_TEXT"
		},
		"insert-paragraph-after-table" : {
			"type" : "java",
			"title" : "L_INSERT_PARAGRAPH_AFTER_TABLE",
			"iconText" : "L_INSERT_PARAGRAPH_AFTER_TABLE_TEXT"
		},
		"cut" : {
			"type" : "java",
			"title" : "L_CUT",
			"shortcut" : "msck X",
			"iconText" : "L_CUT_TEXT"
		},
		"copy" : {
			"type" : "java",
			"title" : "L_COPY",
			"shortcut" : "msck C",
			"iconText" : "L_COPY_TEXT"
		},
		"paste" : {
			"type" : "java",
			"title" : "L_PASTE",
			"shortcut" : "msck V",
			"iconText" : "L_PASTE_TEXT"
		},
		"canvas-background" : {
			"type" : "java",
			"title" : "L_CANVAS_BACKGROUND",
			"iconText" : "L_CANVAS_BACKGROUND_TEXT"
		},
		"toggle-show-semantic-elements" : {
			"type" : "java",
			"title" : "L_TOGGLE_SHOW_SEMANTIC_ELEMENTS",
			"iconText" : "L_TOGGLE_SHOW_SEMANTIC_ELEMENTS_TEXT"
		},
		"toggle-show-marks" : {
			"type" : "java",
			"title" : "L_TOGGLE_SHOW_MARKS",
			"iconText" : "L_TOGGLE_SHOW_MARKS_TEXT"
		},
		"toggle-show-table-grid" : {
			"type" : "java",
			"title" : "L_TOGGLE_SHOW_TABLE_GRID",
			"iconText" : "L_TOGGLE_SHOW_TABLE_GRID_TEXT"
		},
		"toggle-show-container-grid" : {
			"type" : "java",
			"title" : "L_TOGGLE_SHOW_CONTAINER_GRID",
			"iconText" : "L_TOGGLE_SHOW_CONTAINER_GRID_TEXT"
		},
		"zoom" : {
			"type" : "java",
			"title" : "L_ZOOM",
			"iconText" : "L_ZOOM_TEXT"
		},
		"zoom-10" : {
			"type" : "java",
			"title" : "L_ZOOM_10",
			"iconText" : "L_ZOOM_10_TEXT"
		},
		"zoom-25" : {
			"type" : "java",
			"title" : "L_ZOOM_25",
			"iconText" : "L_ZOOM_25_TEXT"
		},
		"zoom-50" : {
			"type" : "java",
			"title" : "L_ZOOM_50",
			"iconText" : "L_ZOOM_50_TEXT"
		},
		"zoom-75" : {
			"type" : "java",
			"title" : "L_ZOOM_75",
			"iconText" : "L_ZOOM_75_TEXT"
		},
		"zoom-100" : {
			"type" : "java",
			"title" : "L_ZOOM_100",
			"shortcut" : "msck NUMPAD0",
			"iconText" : "L_ZOOM_100_TEXT"
		},
		"zoom-125" : {
			"type" : "java",
			"title" : "L_ZOOM_125",
			"iconText" : "L_ZOOM_125_TEXT"
		},
		"zoom-150" : {
			"type" : "java",
			"title" : "L_ZOOM_150",
			"iconText" : "L_ZOOM_150_TEXT"
		},
		"zoom-175" : {
			"type" : "java",
			"title" : "L_ZOOM_175",
			"iconText" : "L_ZOOM_175_TEXT"
		},
		"zoom-200" : {
			"type" : "java",
			"title" : "L_ZOOM_200",
			"iconText" : "L_ZOOM_200_TEXT"
		},
		"zoom-300" : {
			"type" : "java",
			"title" : "L_ZOOM_300",
			"iconText" : "L_ZOOM_300_TEXT"
		},
		"zoom-400" : {
			"type" : "java",
			"title" : "L_ZOOM_400",
			"iconText" : "L_ZOOM_400_TEXT"
		},
		"zoom-500" : {
			"type" : "java",
			"title" : "L_ZOOM_500",
			"iconText" : "L_ZOOM_500_TEXT"
		},
		"increase-zoom" : {
			"type" : "java",
			"title" : "L_INCREASE_ZOOM",
			"shortcut" : "msck ADD",
			"macShortcut" : "meta QUOTE",
			"iconText" : "L_INCREASE_ZOOM_TEXT"
		},
		"decrease-zoom" : {
			"type" : "java",
			"title" : "L_DECREASE_ZOOM",
			"shortcut" : "msck SUBTRACT",
			"macShortcut" : "meta SEMICOLON",
			"iconText" : "L_DECREASE_ZOOM_TEXT"
		},
		"zoom-mode" : {
			"type" : "java",
			"title" : "L_ZOOM_MODE",
			"iconText" : "L_ZOOM_MODE_TEXT"
		},
		"zoom-mode-user-defined" : {
			"type" : "java",
			"title" : "L_ZOOM_MODE_USER_DEFINED",
			"iconText" : "L_ZOOM_MODE_USER_DEFINED_TEXT"
		},
		"zoom-mode-window-width" : {
			"type" : "java",
			"title" : "L_ZOOM_MODE_WINDOW_WIDTH",
			"iconText" : "L_ZOOM_MODE_WINDOW_WIDTH_TEXT"
		},
		"zoom-mode-window-height" : {
			"type" : "java",
			"title" : "L_ZOOM_MODE_WINDOW_HEIGHT",
			"iconText" : "L_ZOOM_MODE_WINDOW_HEIGHT_TEXT"
		},
		"text-size" : {
			"type" : "java",
			"title" : "L_TEXT_SIZE",
			"iconText" : "L_TEXT_SIZE_TEXT"
		},
		"text-size-large" : {
			"type" : "java",
			"title" : "L_TEXT_SIZE_LARGE",
			"iconText" : "L_TEXT_SIZE_LARGE_TEXT"
		},
		"text-size-normal" : {
			"type" : "java",
			"title" : "L_TEXT_SIZE_NORMAL",
			"iconText" : "L_TEXT_SIZE_NORMAL_TEXT"
		},
		"text-size-small" : {
			"type" : "java",
			"title" : "L_TEXT_SIZE_SMALL",
			"iconText" : "L_TEXT_SIZE_SMALL_TEXT"
		},
		"increase-text-size" : {
			"type" : "java",
			"title" : "L_INCREASE_TEXT_SIZE",
			"iconText" : "L_INCREASE_TEXT_SIZE_TEXT"
		},
		"decrease-text-size" : {
			"type" : "java",
			"title" : "L_DECREASE_TEXT_SIZE",
			"iconText" : "L_DECREASE_TEXT_SIZE_TEXT"
		},
		"page-mode" : {
			"type" : "java",
			"title" : "L_PAGE_MODE",
			"iconText" : "L_PAGE_MODE_TEXT"
		},
		"page-mode-continuous" : {
			"type" : "java",
			"title" : "L_PAGE_MODE_CONTINUOUS",
			"iconText" : "L_PAGE_MODE_CONTINUOUS_TEXT"
		},
		"page-mode-single-sided" : {
			"type" : "java",
			"title" : "L_PAGE_MODE_SINGLE_SIDED",
			"iconText" : "L_PAGE_MODE_SINGLE_SIDED_TEXT"
		},
		"page-mode-double-sided" : {
			"type" : "java",
			"title" : "L_PAGE_MODE_DOUBLE_SIDED",
			"iconText" : "L_PAGE_MODE_DOUBLE_SIDED_TEXT"
		},
		"increase-page-index" : {
			"type" : "java",
			"title" : "L_INCREASE_PAGE_INDEX",
			"iconText" : "L_INCREASE_PAGE_INDEX_TEXT"
		},
		"decrease-page-index" : {
			"type" : "java",
			"title" : "L_DECREASE_PAGE_INDEX",
			"iconText" : "L_DECREASE_PAGE_INDEX_TEXT"
		},
		"refresh-all" : {
			"type" : "java",
			"title" : "L_REFRESH_ALL",
			"shortcut" : "msck R",
			"macShortcut" : "F5",
			"iconText" : "L_REFRESH_ALL_TEXT"
		},
		"refresh-boxes" : {
			"type" : "java",
			"title" : "L_REFRESH_BOXES",
			"iconText" : "L_REFRESH_BOXES_TEXT"
		},
		"refresh-style" : {
			"type" : "java",
			"title" : "L_REFRESH_STYLE",
			"iconText" : "L_REFRESH_STYLE_TEXT"
		},
		"refresh-layout" : {
			"type" : "java",
			"title" : "L_REFRESH_LAYOUT",
			"iconText" : "L_REFRESH_LAYOUT_TEXT"
		},
		"refresh-position" : {
			"type" : "java",
			"title" : "L_REFRESH_POSITION",
			"iconText" : "L_REFRESH_POSITION_TEXT"
		},
		"toggle-auto-spellcheck" : {
			"type" : "java",
			"title" : "L_TOGGLE_AUTO_SPELLCHECK",
			"iconText" : "L_TOGGLE_AUTO_SPELLCHECK_TEXT"
		},
		"remove-annotation" : {
			"type" : "java",
			"title" : "L_REMOVE_ANNOTATION",
			"iconText" : "L_REMOVE_ANNOTATION_TEXT"
		},
		"show-annotations-disabled" : {
			"type" : "java",
			"title" : "L_SHOW_ANNOTATIONS_DISABLED",
			"iconText" : "L_SHOW_ANNOTATIONS_DISABLED_TEXT"
		},
		"show-annotations-inline" : {
			"type" : "java",
			"title" : "L_SHOW_ANNOTATIONS_INLINE",
			"iconText" : "L_SHOW_ANNOTATIONS_INLINE_TEXT"
		},
		"show-annotations-bubbles" : {
			"type" : "java",
			"title" : "L_SHOW_ANNOTATIONS_BUBBLES",
			"iconText" : "L_SHOW_ANNOTATIONS_BUBBLES_TEXT"
		},
		"bold" : {
			"type" : "java",
			"title" : "L_BOLD",
			"shortcut" : "msck B",
			"iconText" : "L_BOLD_TEXT"
		},
		"italic" : {
			"type" : "java",
			"title" : "L_ITALIC",
			"shortcut" : "msck I",
			"iconText" : "L_ITALIC_TEXT"
		},
		"underline" : {
			"type" : "java",
			"title" : "L_UNDERLINE",
			"shortcut" : "msck U",
			"iconText" : "L_UNDERLINE_TEXT"
		},
		"strikethrough" : {
			"type" : "java",
			"title" : "L_STRIKETHROUGH",
			"iconText" : "L_STRIKETHROUGH_TEXT"
		},
		"script-super" : {
			"type" : "java",
			"title" : "L_SCRIPT_SUPER",
			"iconText" : "L_SCRIPT_SUPER_TEXT"
		},
		"script-sub" : {
			"type" : "java",
			"title" : "L_SCRIPT_SUB",
			"iconText" : "L_SCRIPT_SUB_TEXT"
		},
		"font-family" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY",
			"iconText" : "L_FONT_FAMILY_TEXT"
		},
		"font-family-default" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_DEFAULT",
			"iconText" : "L_FONT_FAMILY_DEFAULT_TEXT"
		},
		"font-family-serif" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_SERIF",
			"iconText" : "L_FONT_FAMILY_SERIF_TEXT"
		},
		"font-family-sans-serif" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_SANS_SERIF",
			"iconText" : "L_FONT_FAMILY_SANS_SERIF_TEXT"
		},
		"font-family-cursive" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_CURSIVE",
			"iconText" : "L_FONT_FAMILY_CURSIVE_TEXT"
		},
		"font-family-fantasy" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_FANTASY",
			"iconText" : "L_FONT_FAMILY_FANTASY_TEXT"
		},
		"font-family-monospace" : {
			"type" : "java",
			"title" : "L_FONT_FAMILY_MONOSPACE",
			"iconText" : "L_FONT_FAMILY_MONOSPACE_TEXT"
		},
		"font-size" : {
			"type" : "java",
			"title" : "L_FONT_SIZE",
			"iconText" : "L_FONT_SIZE_TEXT"
		},
		"font-size-default" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_DEFAULT",
			"iconText" : "L_FONT_SIZE_DEFAULT_TEXT"
		},
		"font-size-8" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_8",
			"iconText" : "L_FONT_SIZE_8_TEXT"
		},
		"font-size-9" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_9",
			"iconText" : "L_FONT_SIZE_9_TEXT"
		},
		"font-size-10" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_10",
			"iconText" : "L_FONT_SIZE_10_TEXT"
		},
		"font-size-11" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_11",
			"iconText" : "L_FONT_SIZE_11_TEXT"
		},
		"font-size-12" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_12",
			"iconText" : "L_FONT_SIZE_12_TEXT"
		},
		"font-size-14" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_14",
			"iconText" : "L_FONT_SIZE_14_TEXT"
		},
		"font-size-16" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_16",
			"iconText" : "L_FONT_SIZE_16_TEXT"
		},
		"font-size-18" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_18",
			"iconText" : "L_FONT_SIZE_18_TEXT"
		},
		"font-size-20" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_20",
			"iconText" : "L_FONT_SIZE_20_TEXT"
		},
		"font-size-22" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_22",
			"iconText" : "L_FONT_SIZE_22_TEXT"
		},
		"font-size-24" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_24",
			"iconText" : "L_FONT_SIZE_24_TEXT"
		},
		"font-size-26" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_26",
			"iconText" : "L_FONT_SIZE_26_TEXT"
		},
		"font-size-28" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_28",
			"iconText" : "L_FONT_SIZE_28_TEXT"
		},
		"font-size-36" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_36",
			"iconText" : "L_FONT_SIZE_36_TEXT"
		},
		"font-size-48" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_48",
			"iconText" : "L_FONT_SIZE_48_TEXT"
		},
		"font-size-72" : {
			"type" : "java",
			"title" : "L_FONT_SIZE_72",
			"iconText" : "L_FONT_SIZE_72_TEXT"
		},
		"increase-font-size" : {
			"type" : "java",
			"title" : "L_INCREASE_FONT_SIZE",
			"iconText" : "L_INCREASE_FONT_SIZE_TEXT"
		},
		"decrease-font-size" : {
			"type" : "java",
			"title" : "L_DECREASE_FONT_SIZE",
			"iconText" : "L_DECREASE_FONT_SIZE_TEXT"
		},
		"color" : {
			"type" : "java",
			"title" : "L_COLOR",
			"iconText" : "L_COLOR_TEXT"
		},
		"color-default" : {
			"type" : "java",
			"title" : "L_COLOR_DEFAULT",
			"iconText" : "L_COLOR_DEFAULT_TEXT"
		},
		"color-white" : {
			"type" : "java",
			"title" : "L_COLOR_WHITE",
			"iconText" : "L_COLOR_WHITE_TEXT"
		},
		"color-silver" : {
			"type" : "java",
			"title" : "L_COLOR_SILVER",
			"iconText" : "L_COLOR_SILVER_TEXT"
		},
		"color-gray" : {
			"type" : "java",
			"title" : "L_COLOR_GRAY",
			"iconText" : "L_COLOR_GRAY_TEXT"
		},
		"color-black" : {
			"type" : "java",
			"title" : "L_COLOR_BLACK",
			"iconText" : "L_COLOR_BLACK_TEXT"
		},
		"color-navy" : {
			"type" : "java",
			"title" : "L_COLOR_NAVY",
			"iconText" : "L_COLOR_NAVY_TEXT"
		},
		"color-blue" : {
			"type" : "java",
			"title" : "L_COLOR_BLUE",
			"iconText" : "L_COLOR_BLUE_TEXT"
		},
		"color-aqua" : {
			"type" : "java",
			"title" : "L_COLOR_AQUA",
			"iconText" : "L_COLOR_AQUA_TEXT"
		},
		"color-teal" : {
			"type" : "java",
			"title" : "L_COLOR_TEAL",
			"iconText" : "L_COLOR_TEAL_TEXT"
		},
		"color-purple" : {
			"type" : "java",
			"title" : "L_COLOR_PURPLE",
			"iconText" : "L_COLOR_PURPLE_TEXT"
		},
		"color-fuchsia" : {
			"type" : "java",
			"title" : "L_COLOR_FUCHSIA",
			"iconText" : "L_COLOR_FUCHSIA_TEXT"
		},
		"color-lime" : {
			"type" : "java",
			"title" : "L_COLOR_LIME",
			"iconText" : "L_COLOR_LIME_TEXT"
		},
		"color-green" : {
			"type" : "java",
			"title" : "L_COLOR_GREEN",
			"iconText" : "L_COLOR_GREEN_TEXT"
		},
		"color-maroon" : {
			"type" : "java",
			"title" : "L_COLOR_MAROON",
			"iconText" : "L_COLOR_MAROON_TEXT"
		},
		"color-red" : {
			"type" : "java",
			"title" : "L_COLOR_RED",
			"iconText" : "L_COLOR_RED_TEXT"
		},
		"color-orange" : {
			"type" : "java",
			"title" : "L_COLOR_ORANGE",
			"iconText" : "L_COLOR_ORANGE_TEXT"
		},
		"color-yellow" : {
			"type" : "java",
			"title" : "L_COLOR_YELLOW",
			"iconText" : "L_COLOR_YELLOW_TEXT"
		},
		"color-olive" : {
			"type" : "java",
			"title" : "L_COLOR_OLIVE",
			"iconText" : "L_COLOR_OLIVE_TEXT"
		},
		"background-color" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR",
			"iconText" : "L_BACKGROUND_COLOR_TEXT"
		},
		"background-color-default" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_DEFAULT",
			"iconText" : "L_BACKGROUND_COLOR_DEFAULT_TEXT"
		},
		"background-color-white" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_WHITE",
			"iconText" : "L_BACKGROUND_COLOR_WHITE_TEXT"
		},
		"background-color-silver" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_SILVER",
			"iconText" : "L_BACKGROUND_COLOR_SILVER_TEXT"
		},
		"background-color-gray" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_GRAY",
			"iconText" : "L_BACKGROUND_COLOR_GRAY_TEXT"
		},
		"background-color-black" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_BLACK",
			"iconText" : "L_BACKGROUND_COLOR_BLACK_TEXT"
		},
		"background-color-navy" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_NAVY",
			"iconText" : "L_BACKGROUND_COLOR_NAVY_TEXT"
		},
		"background-color-blue" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_BLUE",
			"iconText" : "L_BACKGROUND_COLOR_BLUE_TEXT"
		},
		"background-color-aqua" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_AQUA",
			"iconText" : "L_BACKGROUND_COLOR_AQUA_TEXT"
		},
		"background-color-teal" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_TEAL",
			"iconText" : "L_BACKGROUND_COLOR_TEAL_TEXT"
		},
		"background-color-purple" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_PURPLE",
			"iconText" : "L_BACKGROUND_COLOR_PURPLE_TEXT"
		},
		"background-color-fuchsia" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_FUCHSIA",
			"iconText" : "L_BACKGROUND_COLOR_FUCHSIA_TEXT"
		},
		"background-color-lime" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_LIME",
			"iconText" : "L_BACKGROUND_COLOR_LIME_TEXT"
		},
		"background-color-green" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_GREEN",
			"iconText" : "L_BACKGROUND_COLOR_GREEN_TEXT"
		},
		"background-color-maroon" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_MAROON",
			"iconText" : "L_BACKGROUND_COLOR_MAROON_TEXT"
		},
		"background-color-red" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_RED",
			"iconText" : "L_BACKGROUND_COLOR_RED_TEXT"
		},
		"background-color-orange" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_ORANGE",
			"iconText" : "L_BACKGROUND_COLOR_ORANGE_TEXT"
		},
		"background-color-yellow" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_YELLOW",
			"iconText" : "L_BACKGROUND_COLOR_YELLOW_TEXT"
		},
		"background-color-olive" : {
			"type" : "java",
			"title" : "L_BACKGROUND_COLOR_OLIVE",
			"iconText" : "L_BACKGROUND_COLOR_OLIVE_TEXT"
		},
		"block-indent" : {
			"type" : "java",
			"title" : "L_BLOCK_INDENT",
			"iconText" : "L_BLOCK_INDENT_TEXT"
		},
		"increase-block-indent" : {
			"type" : "java",
			"title" : "L_INCREASE_BLOCK_INDENT",
			"iconText" : "L_INCREASE_BLOCK_INDENT_TEXT"
		},
		"decrease-block-indent" : {
			"type" : "java",
			"title" : "L_DECREASE_BLOCK_INDENT",
			"iconText" : "L_DECREASE_BLOCK_INDENT_TEXT"
		},
		"paragraph" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_PARAGRAPH",
			"iconText" : "L_STYLE_TEMPLATE_PARAGRAPH_TEXT"
		},
		"heading-1" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING1",
			"shortcut" : "msck 1",
			"macShortcut" : "alt F1",
			"iconText" : "L_STYLE_TEMPLATE_HEADING1_TEXT"
		},
		"heading-2" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING2",
			"shortcut" : "msck 2",
			"macShortcut" : "alt F2",
			"iconText" : "L_STYLE_TEMPLATE_HEADING2_TEXT"
		},
		"heading-3" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING3",
			"shortcut" : "msck 3",
			"macShortcut" : "alt F3",
			"iconText" : "L_STYLE_TEMPLATE_HEADING3_TEXT"
		},
		"heading-4" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING4",
			"shortcut" : "msck 4",
			"macShortcut" : "alt F4",
			"iconText" : "L_STYLE_TEMPLATE_HEADING4_TEXT"
		},
		"heading-5" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING5",
			"shortcut" : "msck 5",
			"macShortcut" : "alt F5",
			"iconText" : "L_STYLE_TEMPLATE_HEADING5_TEXT"
		},
		"heading-6" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_HEADING6",
			"shortcut" : "msck 6",
			"macShortcut" : "alt F6",
			"iconText" : "L_STYLE_TEMPLATE_HEADING6_TEXT"
		},
		"style-template-formatted" : {
			"type" : "java",
			"title" : "L_STYLE_TEMPLATE_FORMATTED",
			"iconText" : "L_STYLE_TEMPLATE_FORMATTED_TEXT"
		},
		"align" : {
			"type" : "java",
			"title" : "L_ALIGN",
			"iconText" : "L_ALIGN_TEXT"
		},
		"align-default" : {
			"type" : "java",
			"title" : "L_ALIGN_DEFAULT",
			"iconText" : "L_ALIGN_DEFAULT_TEXT"
		},
		"align-left" : {
			"type" : "java",
			"title" : "L_ALIGN_LEFT",
			"iconText" : "L_ALIGN_LEFT_TEXT"
		},
		"align-center" : {
			"type" : "java",
			"title" : "L_ALIGN_CENTER",
			"iconText" : "L_ALIGN_CENTER_TEXT"
		},
		"align-right" : {
			"type" : "java",
			"title" : "L_ALIGN_RIGHT",
			"iconText" : "L_ALIGN_RIGHT_TEXT"
		},
		"align-justify" : {
			"type" : "java",
			"title" : "L_ALIGN_JUSTIFY",
			"iconText" : "L_ALIGN_JUSTIFY_TEXT"
		},
		"insert-container" : {
			"type" : "java",
			"title" : "L_INSERT_CONTAINER",
			"iconText" : "L_INSERT_CONTAINER_TEXT"
		},
		"delete-container" : {
			"type" : "java",
			"title" : "L_DELETE_CONTAINER",
			"iconText" : "L_DELETE_CONTAINER_TEXT"
		},
		"split-container" : {
			"type" : "java",
			"title" : "L_SPLIT_CONTAINER",
			"iconText" : "L_SPLIT_CONTAINER_TEXT"
		},
		"merge-container" : {
			"type" : "java",
			"title" : "L_MERGE_CONTAINER",
			"iconText" : "L_MERGE_CONTAINER_TEXT"
		},
		"select-container" : {
			"type" : "java",
			"title" : "L_SELECT_CONTAINER",
			"iconText" : "L_SELECT_CONTAINER_TEXT"
		},
		"list" : {
			"type" : "java",
			"title" : "L_LIST",
			"iconText" : "L_LIST_TEXT"
		},
		"list-default" : {
			"type" : "java",
			"title" : "L_LIST_DEFAULT",
			"iconText" : "L_LIST_DEFAULT_TEXT"
		},
		"list-ordered" : {
			"type" : "java",
			"title" : "L_LIST_ORDERED",
			"iconText" : "L_LIST_ORDERED_TEXT"
		},
		"list-unordered" : {
			"type" : "java",
			"title" : "L_LIST_UNORDERED",
			"iconText" : "L_LIST_UNORDERED_TEXT"
		},
		"increase-list-indent" : {
			"type" : "java",
			"title" : "L_INCREASE_LIST_INDENT",
			"iconText" : "L_INCREASE_LIST_INDENT_TEXT"
		},
		"decrease-list-indent" : {
			"type" : "java",
			"title" : "L_DECREASE_LIST_INDENT",
			"iconText" : "L_DECREASE_LIST_INDENT_TEXT"
		},
		"increase-list-level" : {
			"type" : "java",
			"title" : "L_INCREASE_LIST_LEVEL",
			"iconText" : "L_INCREASE_LIST_LEVEL_TEXT"
		},
		"decrease-list-level" : {
			"type" : "java",
			"title" : "L_DECREASE_LIST_LEVEL",
			"iconText" : "L_DECREASE_LIST_LEVEL_TEXT"
		},
		"disable-list-level" : {
			"type" : "java",
			"title" : "L_DISABLE_LIST",
			"iconText" : "L_DISABLE_LIST_TEXT"
		},
		"insert-row-before" : {
			"type" : "java",
			"title" : "L_INSERT_ROW_BEFORE",
			"iconText" : "L_INSERT_ROW_BEFORE_TEXT"
		},
		"insert-row-after" : {
			"type" : "java",
			"title" : "L_INSERT_ROW_AFTER",
			"iconText" : "L_INSERT_ROW_AFTER_TEXT"
		},
		"insert-column-before" : {
			"type" : "java",
			"title" : "L_INSERT_COLUMN_BEFORE",
			"iconText" : "L_INSERT_COLUMN_BEFORE_TEXT"
		},
		"insert-column-after" : {
			"type" : "java",
			"title" : "L_INSERT_COLUMN_AFTER",
			"iconText" : "L_INSERT_COLUMN_AFTER_TEXT"
		},
		"delete-table" : {
			"type" : "java",
			"title" : "L_DELETE_TABLE",
			"iconText" : "L_DELETE_TABLE_TEXT"
		},
		"delete-row" : {
			"type" : "java",
			"title" : "L_DELETE_ROW",
			"iconText" : "L_DELETE_ROW_TEXT"
		},
		"delete-column" : {
			"type" : "java",
			"title" : "L_DELETE_COLUMN",
			"iconText" : "L_DELETE_COLUMN_TEXT"
		},
		"split-table" : {
			"type" : "java",
			"title" : "L_SPLIT_TABLE",
			"iconText" : "L_SPLIT_TABLE_TEXT"
		},
		"merge-table" : {
			"type" : "java",
			"title" : "L_MERGE_TABLE",
			"iconText" : "L_MERGE_TABLE_TEXT"
		},
		"table-cell-valign" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN",
			"iconText" : "L_TABLE_CELL_VALIGN_TEXT"
		},
		"table-cell-valign-default" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN_DEFAULT",
			"iconText" : "L_TABLE_CELL_VALIGN_DEFAULT_TEXT"
		},
		"table-cell-valign-top" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN_TOP",
			"iconText" : "L_TABLE_CELL_VALIGN_TOP_TEXT"
		},
		"table-cell-valign-middle" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN_MIDDLE",
			"iconText" : "L_TABLE_CELL_VALIGN_MIDDLE_TEXT"
		},
		"table-cell-valign-bottom" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN_BOTTOM",
			"iconText" : "L_TABLE_CELL_VALIGN_BOTTOM_TEXT"
		},
		"table-cell-valign-baseline" : {
			"type" : "java",
			"title" : "L_TABLE_CELL_VALIGN_BASELINE",
			"iconText" : "L_TABLE_CELL_VALIGN_BASELINE_TEXT"
		},
		"increase-indent" : {
			"type" : "java",
			"title" : "L_INCREASE_INDENT",
			"iconText" : "L_INCREASE_INDENT_TEXT"
		},
		"decrease-indent" : {
			"type" : "java",
			"title" : "L_DECREASE_INDENT",
			"iconText" : "L_DECREASE_INDENT_TEXT"
		},
		"convert-table" : {
			"type" : "java",
			"title" : "L_CONVERT_TABLE",
			"iconText" : "L_CONVERT_TABLE_TEXT"
		},
		"auto-fit-table-content" : {
			"type" : "java",
			"title" : "L_AUTO_FIT_TABLE_CONTENT",
			"iconText" : "L_AUTO_FIT_TABLE_CONTENT_TEXT"
		},
		"find-next" : {
			"type" : "java",
			"title" : "L_FIND_NEXT",
			"shortcut" : "msck G",
			"iconText" : "L_FIND_NEXT_TEXT"
		},
		"find-previous" : {
			"type" : "java",
			"title" : "L_FIND_PREVIOUS",
			"shortcut" : "msck shift G",
			"iconText" : "L_FIND_PREVIOUS_TEXT"
		},
		"insert-horizontal-line" : {
			"type" : "java",
			"title" : "L_INSERT_HORIZONTAL_LINE",
			"iconText" : "L_INSERT_HORIZONTAL_LINE_TEXT"
		},
		"insert-line-break" : {
			"type" : "java",
			"title" : "L_INSERT_LINE_BREAK",
			"iconText" : "L_INSERT_LINE_BREAK_TEXT"
		},
		"insert-page-break" : {
			"type" : "java",
			"title" : "L_INSERT_PAGE_BREAK",
			"shortcut" : "msck ENTER",
			"iconText" : "L_INSERT_PAGE_BREAK_TEXT"
		},
		"insert-nbsp" : {
			"type" : "java",
			"title" : "L_INSERT_NBSP",
			"shortcut" : "msck shift SPACE",
			"macShortcut" : "alt SPACE",
			"iconText" : "L_INSERT_NBSP_TEXT"
		},
		"insert-soft-hyphen" : {
			"type" : "java",
			"title" : "L_INSERT_SOFT_HYPHEN",
			"iconText" : "L_INSERT_SOFT_HYPHEN_TEXT"
		},
		"insert-non-breaking-hyphen" : {
			"type" : "java",
			"title" : "L_INSERT_NON_BREAKING_HYPHEN",
			"shortcut" : "msck shift MINUS",
			"iconText" : "L_INSERT_NON_BREAKING_HYPHEN_TEXT"
		},
		"insert-date" : {
			"type" : "java",
			"title" : "L_INSERT_DATE",
			"shortcut" : "msck shift D",
			"iconText" : "L_INSERT_DATE_TEXT"
		},
		"insert-table-caption" : {
			"type" : "java",
			"title" : "L_INSERT_TABLE_CAPTION",
			"iconText" : "L_INSERT_TABLE_CAPTION_TEXT"
		},
		"delete-table-caption" : {
			"type" : "java",
			"title" : "L_DELETE_TABLE_CAPTION",
			"iconText" : "L_DELETE_TABLE_CAPTION_TEXT"
		},
		"goto-page" : {
			"type" : "java",
			"title" : "L_GOTO_PAGE",
			"iconText" : "L_GOTO_PAGE_TEXT"
		},
		"merge-cells" : {
			"type" : "java",
			"title" : "L_MERGE_CELLS",
			"iconText" : "L_MERGE_CELLS_TEXT"
		},
		"language" : {
			"type" : "java",
			"title" : "L_LANGUAGE",
			"iconText" : "L_LANGUAGE_TEXT"
		},
		"language-default" : {
			"type" : "java",
			"title" : "L_LANGUAGE_DEFAULT",
			"iconText" : "L_LANGUAGE_DEFAULT_TEXT"
		},
		"language-none" : {
			"type" : "java",
			"title" : "L_LANGUAGE_NONE",
			"iconText" : "L_LANGUAGE_NONE_TEXT"
		},
		"language-american-english" : {
			"type" : "java",
			"title" : "L_LANGUAGE_AMERICAN_ENGLISH",
			"iconText" : "L_LANGUAGE_AMERICAN_ENGLISH_TEXT"
		},
		"language-american-legal" : {
			"type" : "java",
			"title" : "L_LANGUAGE_AMERICAN_LEGAL",
			"iconText" : "L_LANGUAGE_AMERICAN_LEGAL_TEXT"
		},
		"language-american-medical" : {
			"type" : "java",
			"title" : "L_LANGUAGE_AMERICAN_MEDICAL",
			"iconText" : "L_LANGUAGE_AMERICAN_MEDICAL_TEXT"
		},
		"language-brazilian-portuguese" : {
			"type" : "java",
			"title" : "L_LANGUAGE_BRAZILIAN_PORTUGUESE",
			"iconText" : "L_LANGUAGE_BRAZILIAN_PORTUGUESE_TEXT"
		},
		"language-british-english" : {
			"type" : "java",
			"title" : "L_LANGUAGE_BRITISH_ENGLISH",
			"iconText" : "L_LANGUAGE_BRITISH_ENGLISH_TEXT"
		},
		"language-british-legal" : {
			"type" : "java",
			"title" : "L_LANGUAGE_BRITISH_LEGAL",
			"iconText" : "L_LANGUAGE_BRITISH_LEGAL_TEXT"
		},
		"language-british-medical" : {
			"type" : "java",
			"title" : "L_LANGUAGE_BRITISH_MEDICAL",
			"iconText" : "L_LANGUAGE_BRITISH_MEDICAL_TEXT"
		},
		"language-canadian-english" : {
			"type" : "java",
			"title" : "L_LANGUAGE_CANADIAN_ENGLISH",
			"iconText" : "L_LANGUAGE_CANADIAN_ENGLISH_TEXT"
		},
		"language-danish" : {
			"type" : "java",
			"title" : "L_LANGUAGE_DANISH",
			"iconText" : "L_LANGUAGE_DANISH_TEXT"
		},
		"language-dutch" : {
			"type" : "java",
			"title" : "L_LANGUAGE_DUTCH",
			"iconText" : "L_LANGUAGE_DUTCH_TEXT"
		},
		"language-finnish" : {
			"type" : "java",
			"title" : "L_LANGUAGE_FINNISH",
			"iconText" : "L_LANGUAGE_FINNISH_TEXT"
		},
		"language-french" : {
			"type" : "java",
			"title" : "L_LANGUAGE_FRENCH",
			"iconText" : "L_LANGUAGE_FRENCH_TEXT"
		},
		"language-german" : {
			"type" : "java",
			"title" : "L_LANGUAGE_GERMAN",
			"iconText" : "L_LANGUAGE_GERMAN_TEXT"
		},
		"language-italian" : {
			"type" : "java",
			"title" : "L_LANGUAGE_ITALIAN",
			"iconText" : "L_LANGUAGE_ITALIAN_TEXT"
		},
		"language-norwegian" : {
			"type" : "java",
			"title" : "L_LANGUAGE_NORWEGIAN",
			"iconText" : "L_LANGUAGE_NORWEGIAN_TEXT"
		},
		"language-portuguese" : {
			"type" : "java",
			"title" : "L_LANGUAGE_PORTUGUESE",
			"iconText" : "L_LANGUAGE_PORTUGUESE_TEXT"
		},
		"language-spanish" : {
			"type" : "java",
			"title" : "L_LANGUAGE_SPANISH",
			"iconText" : "L_LANGUAGE_SPANISH_TEXT"
		},
		"language-swedish" : {
			"type" : "java",
			"title" : "L_LANGUAGE_SWEDISH",
			"iconText" : "L_LANGUAGE_SWEDISH_TEXT"
		},
		"get-webdav-image" : {
			"type" : "java",
			"title" : "L_GET_WEBDAV_IMAGE",
			"iconText" : "L_GET_WEBDAV_IMAGE_TEXT"
		},
		"get-webdav-object" : {
			"type" : "java",
			"title" : "L_GET_WEBDAV_OBJECT",
			"iconText" : "L_GET_WEBDAV_OBJECT_TEXT"
		},
		"get-webdav-document" : {
			"type" : "java",
			"title" : "L_GET_WEBDAV_DOCUMENT",
			"iconText" : "L_GET_WEBDAV_DOCUMENT_TEXT"
		},
		"get-webdav-hyperlink" : {
			"type" : "java",
			"title" : "L_GET_WEBDAV_HYPERLINK",
			"iconText" : "L_GET_WEBDAV_HYPERLINK_TEXT"
		},
		"insert-webdav-hyperlink" : {
			"type" : "java",
			"title" : "L_INSERT_HYPERLINK_DIALOG",
			"iconText" : "L_INSERT_HYPERLINK_DIALOG_TEXT"
		},
		"insert-webdav-image" : {
			"type" : "java",
			"title" : "L_INSERT_IMAGE_DIALOG",
			"iconText" : "L_INSERT_IMAGE_DIALOG_TEXT"
		},
		"upload-image" : {
			"type" : "java",
			"title" : "L_UPLOAD_IMAGE",
			"iconText" : "L_UPLOAD_IMAGE_TEXT"
		},
		"upload-document-all" : {
			"type" : "java",
			"title" : "L_UPLOAD_DOCUMENT_ALL",
			"iconText" : "L_UPLOAD_DOCUMENT_ALL_TEXT"
		},
		"upload-document" : {
			"type" : "java",
			"title" : "L_UPLOAD_DOCUMENT",
			"iconText" : "L_UPLOAD_DOCUMENT_TEXT"
		},
		"upload-object" : {
			"type" : "java",
			"title" : "L_UPLOAD_OBJECT",
			"iconText" : "L_UPLOAD_OBJECT_TEXT"
		},
		"undo" : {
			"type" : "java",
			"title" : "L_UNDO",
			"iconText" : "L_UNDO_TEXT"
		},
		"redo" : {
			"type" : "java",
			"title" : "L_REDO",
			"iconText" : "L_REDO_TEXT"
		},
		"spellcheck-dialog" : {
			"type" : "java",
			"title" : "L_SPELLCHECKDIALOG_TITLE",
			"iconText" : "L_SPELLCHECKDIALOG_TITLE_TEXT"
		},
		"thesaurus-dialog" : {
			"type" : "java",
			"title" : "L_THESAURUSDIALOG_TITLE",
			"iconText" : "L_THESAURUSDIALOG_TITLE_TEXT"
		},
		"save-document" : {
			"type" : "java",
			"title" : "L_SAVE_DOCUMENT",
			"iconText" : "L_SAVE_DOCUMENT_TEXT"
		},
		"save-document-as-dialog" : {
			"type" : "java",
			"title" : "L_SAVE_DOCUMENT_AS_DIALOG",
			"iconText" : "L_SAVE_DOCUMENT_AS_DIALOG_TEXT"
		},
		"find-replace-dialog" : {
			"type" : "java",
			"title" : "L_FIND_REPLACE_DIALOG",
			"iconText" : "L_FIND_REPLACE_DIALOG_TEXT"
		},
		"list-properties-dialog" : {
			"type" : "java",
			"title" : "L_LIST_PROPERTIES_DIALOG",
			"iconText" : "L_LIST_PROPERTIES_DIALOG_TEXT"
		},
		"auto-correct-dialog" : {
			"type" : "java",
			"title" : "L_AUTO_CORRECT_DIALOG",
			"iconText" : "L_AUTO_CORRECT_DIALOG_TEXT"
		},
		"open-file-dialog" : {
			"type" : "java",
			"title" : "L_OPEN_FILE_DIALOG",
			"iconText" : "L_OPEN_FILE_DIALOG_TEXT"
		},
		"insert-hyperlink" : {
			"type" : "java",
			"title" : "L_INSERT_HYPERLINK_DIALOG",
			"iconText" : "L_INSERT_HYPERLINK_DIALOG_TEXT"
		},
		"split-cell" : {
			"type" : "java",
			"title" : "L_SPLIT_CELL_DIALOG",
			"iconText" : "L_SPLIT_CELL_DIALOG_TEXT"
		},
		"paste-special-dialog" : {
			"type" : "java",
			"title" : "L_PASTE_SPECIAL_DIALOG",
			"iconText" : "L_PASTE_SPECIAL_DIALOG_TEXT"
		},
		"insert-annotation" : {
			"type" : "java",
			"title" : "L_INSERT_ANNOTATION_DIALOG",
			"iconText" : "L_INSERT_ANNOTATION_DIALOG_TEXT"
		},
		"edit-annotation" : {
			"type" : "java",
			"title" : "L_EDIT_ANNOTATION_DIALOG",
			"iconText" : "L_EDIT_ANNOTATION_DIALOG_TEXT"
		},
		"change-case" : {
			"type" : "java",
			"title" : "L_CHANGE_CASE_DIALOG",
			"iconText" : "L_CHANGE_CASE_DIALOG_TEXT"
		},
		"new-document" : {
			"type" : "java",
			"title" : "L_NEW_DOCUMENT",
			"iconText" : "L_NEW_DOCUMENT_TEXT"
		},
		"toggle-source-view" : {
			"type" : "java",
			"title" : "L_SOURCE_VIEW",
			"iconText" : "L_SOURCE_VIEW_TEXT"
		},
		"print" : {
			"type" : "java",
			"title" : "L_PRINT",
			"iconText" : "L_PRINT_TEXT"
		},
		"show-in-browser" : {
			"type" : "java",
			"title" : "L_SHOW_IN_BROWSER",
			"iconText" : "L_SHOW_IN_BROWSER_TEXT"
		},
		"clear-formatting" : {
			"type" : "java",
			"title" : "L_CLEAR_FORMATTING",
			"shortcut" : "msck SPACE",
			"iconText" : "L_CLEAR_FORMATTING_TEXT"
		},
		"copy-format" : {
			"type" : "java",
			"title" : "L_COPY_FORMAT",
			"iconText" : "L_COPY_FORMAT_TEXT"
		},
		"paste-format" : {
			"type" : "java",
			"title" : "L_PASTE_FORMAT",
			"iconText" : "L_PASTE_FORMAT_TEXT"
		},
		"format-painter" : {
			"type" : "java",
			"title" : "L_FORMAT_PAINTER",
			"iconText" : "L_FORMAT_PAINTER_TEXT"
		},
		"live-fragment-language" : {
			"type" : "java",
			"title" : "L_LIVE_FRAGMENT_LANGUAGE",
			"iconText" : "L_LIVE_FRAGMENT_LANGUAGE_TEXT"
		},
		"document-language" : {
			"type" : "java",
			"title" : "L_DOCUMENT_LANGUAGE",
			"iconText" : "L_DOCUMENT_LANGUAGE_TEXT"
		},
		"convert-image-to-data-uri" : {
			"type" : "java",
			"title" : "L_CONVERT_IMAGE_TO_DATA_URI",
			"iconText" : "L_CONVERT_IMAGE_TO_DATA_URI_TEXT"
		},
		"accept-diff" : {
			"type" : "java",
			"title" : "L_ACCEPT_DIFF",
			"text" : "L_ACCEPT_DIFF_TEXT"
		},
		"reject-diff" : {
			"type" : "java",
			"title" : "L_REJECT_DIFF",
			"text" : "L_REJECT_DIFF_TEXT"
		},
		"accept-diff-gonext" : {
			"type" : "java",
			"title" : "L_ACCEPT_DIFF_GONEXT",
			"text" : "L_ACCEPT_DIFF_GONEXT_TEXT"
		},
		"reject-diff-gonext" : {
			"type" : "java",
			"title" : "L_REJECT_DIFF_GONEXT",
			"text" : "L_REJECT_DIFF_GONEXT_TEXT"
		},
		"goto-next-diff" : {
			"type" : "java",
			"title" : "L_GOTO_NEXT_DIFF",
			"text" : "L_GOTO_NEXT_DIFF_TEXT"
		},
		"goto-prev-diff" : {
			"type" : "java",
			"title" : "L_GOTO_PREV_DIFF",
			"text" : "L_GOTO_PREV_DIFF_TEXT"
		},
		"accept-all-diff" : {
			"type" : "java",
			"title" : "L_ACCEPT_ALL_DIFF",
			"text" : "L_ACCEPT_ALL_DIFF_TEXT"
		},
		"reject-all-diff" : {
			"type" : "java",
			"title" : "L_REJECT_ALL_DIFF",
			"text" : "L_REJECT_ALL_DIFF_TEXT"
		},
		"show-changes-inline-diff" : {
			"type" : "java",
			"title" : "L_SHOW_CHANGES_INLINE_DIFF",
			"text" : "L_SHOW_CHANGES_INLINE_DIFF_TEXT"
		},
		"show-changes-insertions-diff" : {
			"type" : "java",
			"title" : "L_SHOW_CHANGES_INSERTIONS_DIFF",
			"text" : "L_SHOW_CHANGES_INSERTIONS_DIFF_TEXT"
		},
		"show-changes-deletions-diff" : {
			"type" : "java",
			"title" : "L_SHOW_CHANGES_DELETIONS_DIFF",
			"text" : "L_SHOW_CHANGES_DELETIONS_DIFF_TEXT"
		},
		"diff-list-dialog" : {
			"type" : "java",
			"title" : "L_DIFF_LIST_DIALOG",
			"text" : "L_DIFF_LIST_DIALOG_TEXT"
		},
		"compare-documents-dialog" : {
			"type" : "js",
			"functionName" : "compareDocumentsDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_COMPARE_DOCUMENTS_DIALOG",
			"iconText" : "L_COMPARE_DOCUMENTS_DIALOG_TEXT"
		},
		"end-comparison-mode" : {
			"type" : "java",
			"title" : "L_END_COMPARISON_MODE",
			"iconText" : "L_END_COMPARISON_MODE_TEXT"
		},
		"track-changes" : {
			"type" : "java",
			"title" : "L_TRACK_CHANGES",
			"text" : "L_TRACK_CHANGES_TEXT"
		},
		"accept-change" : {
			"type" : "java",
			"title" : "L_ACCEPT_CHANGE",
			"text" : "L_ACCEPT_CHANGE_TEXT"
		},
		"reject-change" : {
			"type" : "java",
			"title" : "L_REJECT_CHANGE",
			"text" : "L_REJECT_CHANGE_TEXT"
		},
		"accept-all-changes" : {
			"type" : "java",
			"title" : "L_ACCEPT_ALL_CHANGES",
			"text" : "L_ACCEPT_ALL_CHANGES_TEXT"
		},
		"reject-all-changes" : {
			"type" : "java",
			"title" : "L_REJECT_ALL_CHANGES",
			"text" : "L_REJECT_ALL_CHANGES_TEXT"
		},
		"goto-next-change" : {
			"type" : "java",
			"title" : "L_GOTO_NEXT_CHANGE",
			"text" : "L_GOTO_NEXT_CHANGE_TEXT"
		},
		"goto-prev-change" : {
			"type" : "java",
			"title" : "L_GOTO_PREV_CHANGE",
			"text" : "L_GOTO_PREV_CHANGE_TEXT"
		},
		"accept-change-gonext" : {
			"type" : "java",
			"title" : "L_ACCEPT_CHANGE_GONEXT",
			"text" : "L_ACCEPT_CHANGE_GONEXT_TEXT"
		},
		"reject-change-gonext" : {
			"type" : "java",
			"title" : "L_REJECT_CHANGE_GONEXT",
			"text" : "L_REJECT_CHANGE_GONEXT_TEXT"
		},
		"change-list-dialog" : {
			"type" : "java",
			"title" : "L_CHANGE_LIST_DIALOG",
			"text" : "L_CHANGE_LIST_DIALOG_TEXT"
		},
		"show-changes-final" : {
			"type" : "java",
			"title" : "L_DISPLAY_MODE_FINAL",
			"text" : "L_DISPLAY_MODE_FINAL_TEXT"
		},
		"show-changes-final-bubble" : {
			"type" : "java",
			"title" : "L_DISPLAY_MODE_FINAL_BUBBLE",
			"text" : "L_DISPLAY_MODE_FINAL_BUBBLE_TEXT"
		},
		"show-changes-mixed-inline" : {
			"type" : "java",
			"title" : "L_DISPLAY_MODE_MIXED_INLINE",
			"text" : "L_DISPLAY_MODE_MIXED_INLINE_TEXT"
		},
		"show-changes-original-bubble" : {
			"type" : "java",
			"title" : "L_DISPLAY_MODE_ORIGINAL_BUBBLE",
			"text" : "L_DISPLAY_MODE_ORIGINAL_BUBBLE_TEXT"
		},
		"show-changes-original" : {
			"type" : "java",
			"title" : "L_DISPLAY_MODE_ORIGINAL",
			"text" : "L_DISPLAY_MODE_ORIGINAL_TEXT"
		},
		"page-properties-dialog" : {
			"type" : "js",
			"functionName" : "pagePropertiesDialog",
			"actionPath" : "CustomJSActions",
			"title" : "L_PAGE_PROPERTIES_DIALOG",
			"iconText" : "L_PAGE_PROPERTIES_DIALOG_TEXT"
		},
		"current-page-placeholder" : {
			"type" : "js",
			"functionName" : "insertCurrentPage",
			"actionPath" : "CustomJSActions",
			"title" : "L_CURRENT_PAGE_PLACEHOLDER",
			"iconText" : "L_CURRENT_PAGE_PLACEHOLDER_TEXT"
		},
		"total-pages-placeholder" : {
			"type" : "js",
			"functionName" : "insertTotalPages",
			"actionPath" : "CustomJSActions",
			"title" : "L_TOTAL_PAGES_PLACEHOLDER",
			"iconText" : "L_TOTAL_PAGES_PLACEHOLDER_TEXT"
		}
	};
	this.getActionMap = function() {
		return this.actionMap;
	};
}
eongApplication.customJSActions = function(apiObj) {
	this.Helper = apiObj.Helper;
	this.dialogHTMLMap = this.Helper.DialogHTMLMap;
	this.headerFooterStyleURL = "";
	this.licenseKeyURL = "";
	var apiObject = apiObj;
	var cId = this.Helper.containerId;
	var thiz = this;
	this.insertCurrentPage = function() {
		apiObject.insertContent('<span class="ro-currentpage"></span>');
	};
	this.insertTotalPages = function() {
		apiObject.insertContent('<span class="ro-totalpages"></span>');
	};
	this.headerFooterDialog = function(contentElement) {
		var html = this.dialogHTMLMap["headerFooter"];
		var editorWidth = 650;
		var editorHeight = 250;
		this._createDialog(apiObject.locale
				.getLocaleCode("L_HEADER_FOOTER_DIALOG"), "modalDialog2_",
				false);
		this._showDialog(html, "modalDialog2_", false);
		jQuery("#headerfooter_" + cId).css({
			width : editorWidth,
			height : editorHeight
		});
		window["headerfootereong_" + cId] = new eongApplication(editorWidth,
				editorHeight, "headerfooter_" + cId, "headerfooter_" + cId,
				"headerfootereong_" + cId, true, false, apiObject.noConflict);
		var editor = window["headerfootereong_" + cId];
		editor.setJSLogLevel("INFO");
		editor.setLogLevel("INFO");
		editor.setCodebase(apiObject.Helper.codebase);
		editor
				.setUIConfig('{"toolbar":{"ribbons":{"options":{"sortabletabs":"false"},"elements":{"L_CONTENT_TAB":{"L_EDITING_PANE":{"subpanels":[{"size":"mediumPanel","actions":["undo","redo","select-all"]}]},"L_FORMAT_PANE":{"options":{"size":"smallPanel"},"actions":["bold","italic","underline","script-sub","script-super","strikethrough","color-dialog","backgroundcolor-dialog","change-case-dialog","clear-formatting"]},"L_PARAGRAPH_PANE":{"options":{"size":"smallPanel"},"actions":["align-left","align-center","align-right","align-justify","list-ordered","list-unordered","decrease-indent","increase-indent"]},"L_FONT_PANE":{"subpanels":[{"size":"dropdownPanel","comboactions":{"font-family":{"options":{"comboWidth":"100","dropdownWidth":"100"},"dropdownactions":"font-family-toolbar"},"font-size":{"options":{"comboWidth":"100","dropdownWidth":"100"},"dropdownactions":{"font-size-default":"","font-size-8":"","font-size-9":"","font-size-10":"","font-size-11":"","font-size-12":"","font-size-14":"","font-size-16":"","font-size-18":"","font-size-20":"","font-size-22":"","font-size-24":"","font-size-26":"","font-size-28":"","font-size-36":"","font-size-48":"","font-size-72":""}}}}]},"L_TABLE_INSERT_PANE":{"options":{"size":"largePanel"},"actions":["insert-table-dialog"]},"L_OBJECT_PANE":{"options":{"size":"mediumPanel"},"actions":["insert-image-dialog","insert-hyperlink-dialog"]},"L_MARKERS_PANE":{"options":{"size":"mediumPanel"},"actions":["toggle-show-marks","toggle-show-table-grid"]},"L_PLACEHOLDERS_PANE":{"options":{"size":"mediumPanel"},"actions":["current-page-placeholder","total-pages-placeholder"]}}}}},"contextmenu":{"clipboardgroup":{"actions":["cut","copy","paste"]},"selectgroup":{"actions":["select-all"]},"formattinggroup":{"submenus":{"fontfamilymenu":{"name":"L_FONT_FAMILY","fontfamilygroup":{"actions":["font-family-context"]}},"fontsizemenu":{"name":"L_FONT_SIZE","fontsizegroup":{"actions":["font-size-default","font-size-8","font-size-9","font-size-10","font-size-11","font-size-12","font-size-14","font-size-16","font-size-18","font-size-20","font-size-22","font-size-24","font-size-26","font-size-28","font-size-36","font-size-48","font-size-72"]}},"alignmenu":{"name":"L_ALIGN","aligngroup":{"actions":["align-left","align-center","align-right","align-justify"]}},"stylemenu":{"name":"L_CONTEXT_STYLE","stylegroup":{"actions":["bold","italic","underline","strikethrough"]},"scriptgroup":{"actions":["script-super","script-sub"]}}}},"tablegroup":{"submenus":{"tablemenu":{"name":"L_TABLE_TAB","tableinsertgroup":{"actions":["insert-table-dialog"]},"tablesubgroup":{"actions":["delete-table","auto-fit-table-content"]},"tablecaptiongroup":{"actions":["insert-table-caption","delete-table-caption"]},"tableinsertparagraphgroup":{"actions":["insert-paragraph-before-table","insert-paragraph-after-table"]},"tablepropertiesgroup":{"actions":["table-properties-dialog"]},"cellrowcolumnpropertiesgroup":{"submenus":{"columnpropertiesmenu":{"name":"L_COLUMN_PANE","columngroup":{"actions":["column-properties-dialog","insert-column-before","insert-column-after","delete-column"]}},"rowpropertiesmenu":{"name":"L_ROW_PANE","rowgroup":{"actions":["row-properties-dialog","insert-row-before","insert-row-after","delete-row"]}},"cellpropertiesmenu":{"name":"L_CELL_PANE","cellgroup":{"actions":["cell-properties-dialog","merge-cells","split-cell-dialog"]}}}}}}},"propertiesgroup":{"actions":["image-properties-dialog","list-properties-dialog","hyperlink-properties-dialog","remove-hyperlink","remove-bookmark"]}} }');
		editor
				.setConfig('{"saveuistate":"false","enabledocumentpalette":"false","enablestatusbar":"false","allowdefaultcolors":"true","allowpresetcolors":"true","allowfreecolors":"true","draggable":"false","resizable":"false","toolbarsortablepanes":"false","documentmode":"document","defaultfont":"Arial","automaticcanvassize":"false","showtablegrid":"true","enabledefaultparagraphstyles":"true","hidesingletabs":"true","hidetoolbarpaneldescription":"true"}');
		if (this.headerFooterStyleURL !== "") {
			editor.addUserAgentStylesFromURL(this.headerFooterStyleURL);
		}
		if (this.licenseKeyURL !== "") {
			editor.setLicenseKeyURL(this.licenseKeyURL);
		}
		editor.addUserAgentStyles(".ro-currentpage:before {content: '"
				+ apiObject.locale.getLocaleCode("L_CURRENT_PAGE")
				+ "';} .ro-totalpages:before {content: '"
				+ apiObject.locale.getLocaleCode("L_TOTAL_PAGES") + "'; }");
		if (contentElement.val() !== "") {
			var content = contentElement.val();
			content = content.replace(/\<html\>\<body\>/g, "");
			content = content.replace(/\<\/body\>\<\/html\>/g, "");
			editor.setBodyFragment(contentElement.val());
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog("modalDialog2_", false);
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			contentElement.val("<html><body>" + editor.getBodyFragment()
					+ "</body></html>");
			thiz._hideDialog("modalDialog2_", false);
		};
		jQuery("#modalDialog2_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs("modalDialog2_");
		editor.loadEditor();
	};
	this.pagePropertiesDialog = function() {
		var html = this.dialogHTMLMap["pageProperties"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_PAGE_PROPERTIES_DIALOG"));
		this._showDialog(html);
		var pageTopSpinner = jQuery("#page_margin_top_" + cId);
		var pageBottomSpinner = jQuery("#page_margin_bottom_" + cId);
		var pageLeftSpinner = jQuery("#page_margin_left_" + cId);
		var pageRightSpinner = jQuery("#page_margin_right_" + cId);
		var pageSizeWidthSpinner = jQuery("#page_size_width_" + cId);
		var pageSizeHeightSpinner = jQuery("#page_size_height_" + cId);
		var firstPageTopSpinner = jQuery("#first_page_margin_top_" + cId);
		var firstPageBottomSpinner = jQuery("#first_page_margin_bottom_" + cId);
		var firstPageLeftSpinner = jQuery("#first_page_margin_left_" + cId);
		var firstPageRightSpinner = jQuery("#first_page_margin_right_" + cId);
		var firstPageSizeWidthSpinner = jQuery("#first_page_size_width_" + cId);
		var firstPageSizeHeightSpinner = jQuery("#first_page_size_height_"
				+ cId);
		var pageMarginTopUnit = jQuery("#page_margin_top_unit_" + cId);
		var pageMarginBottomUnit = jQuery("#page_margin_bottom_unit_" + cId);
		var pageMarginLeftUnit = jQuery("#page_margin_left_unit_" + cId);
		var pageMarginRightUnit = jQuery("#page_margin_right_unit_" + cId);
		var firstPageMarginTopUnit = jQuery("#first_page_margin_top_unit_"
				+ cId);
		var firstPageMarginBottomUnit = jQuery("#first_page_margin_bottom_unit_"
				+ cId);
		var firstPageMarginLeftUnit = jQuery("#first_page_margin_left_unit_"
				+ cId);
		var firstPageMarginRightUnit = jQuery("#first_page_margin_right_unit_"
				+ cId);
		var pageSizeSelect = jQuery("#page_size_" + cId);
		var firstPageSizeSelect = jQuery("#first_page_size_" + cId);
		var pageSizeUnit = jQuery("#page_size_unit_" + cId);
		var firstPageSizeUnit = jQuery("#first_page_size_unit_" + cId);
		var pageLayout = jQuery("#page_layout_" + cId);
		jQuery(".spinner")
				.each(
						function(index, element) {
							var id = jQuery(element).attr("id");
							var unitId = "";
							if (id.search(/^page_size_.*/) != -1) {
								unitId = "page_size_unit_" + cId;
							} else if (id.search(/first_page_size_.*/) != -1) {
								unitId = "first_page_size_unit_" + cId;
							} else {
								unitId = id.substring(0, id.lastIndexOf("_"))
										+ "_unit_" + cId;
							}
							thiz._createSpinner("#" + id, 0, 9999, thiz
									._getIncrementFromUnit(jQuery("#" + unitId)
											.val()));
						});
		jQuery(".spinnerUnit").change(function(event) {
			var id = jQuery(this).attr("id");
			var unit = event.target.value;
			if (id.search(/^page_size_.*/) != -1) {
				thiz._updateSpinnerStep("page_size_width_" + cId, unit);
				thiz._updateSpinnerStep("page_size_height_" + cId, unit);
				thiz._updatePageSizeDropDown(event.target);
			} else if (id.search(/first_page_size_.*/) != -1) {
				thiz._updateSpinnerStep("first_page_size_width_" + cId, unit);
				thiz._updateSpinnerStep("first_page_size_height_" + cId, unit);
				thiz._updatePageSizeDropDown(event.target);
			} else {
				id = id.replace("_unit", "");
				thiz._updateSpinnerStep(id, unit);
			}
		});
		jQuery(
				"#page_size_width_" + cId + ", #page_size_height_" + cId
						+ ", #first_page_size_width_" + cId
						+ ", #first_page_size_height_" + cId).spinner("option",
				"stop", function(event, ui) {
					thiz._updatePageOrientationByPageSize(event.target);
					thiz._updatePageSizeDropDown(event.target);
				}).keyup(function(event) {
			thiz._updatePageOrientationByPageSize(event.target);
			thiz._updatePageSizeDropDown(event.target);
		}).change(function(event) {
			thiz._updatePageOrientationByPageSize(event.target);
			thiz._updatePageSizeDropDown(event.target);
		});
		jQuery("#page_size_" + cId + ", #first_page_size_" + cId).change(
				function(event) {
					thiz._updatePageSizeFromDropDown(event.target);
				});
		jQuery(
				"input[name='page_orientation_radio_" + cId
						+ "'], input[name='first_page_orientation_radio_" + cId
						+ "']").change(function(event) {
			thiz._flipPageSize(event.target);
		});
		jQuery("#page_layout_" + cId).change(function(event) {
			thiz._updatePageLayout(event.target);
		});
		jQuery("#first_page_enable_" + cId).change(function(event) {
			if (jQuery(event.target).is(":checked")) {
				jQuery("#first_page_settings_" + cId).css({
					"visibility" : "visible"
				});
			} else {
				jQuery("#first_page_settings_" + cId).css({
					"visibility" : "hidden"
				});
			}
		});
		jQuery("#pagePropertiesHeaderFooter_" + cId + " input[type='checkbox']")
				.change(
						function(event) {
							var id = jQuery(this).attr("id");
							var checked = event.target.checked;
							if (id.search(/^default_page_enable_header.*/) != -1) {
								jQuery("#default_page_edit_header_" + cId)
										.prop("disabled", !checked);
							} else if (id.search(/^first_page_enable_header.*/) != -1) {
								jQuery("#first_page_edit_header_" + cId).prop(
										"disabled", !checked);
							} else if (id.search(/^left_page_enable_header.*/) != -1) {
								jQuery("#left_page_edit_header_" + cId).prop(
										"disabled", !checked);
							} else if (id.search(/^right_page_enable_header.*/) != -1) {
								jQuery("#right_page_edit_header_" + cId).prop(
										"disabled", !checked);
							} else if (id
									.search(/^default_page_enable_footer.*/) != -1) {
								jQuery("#default_page_edit_footer_" + cId)
										.prop("disabled", !checked);
							} else if (id.search(/^first_page_enable_footer.*/) != -1) {
								jQuery("#first_page_edit_footer_" + cId).prop(
										"disabled", !checked);
							} else if (id.search(/^left_page_enable_footer.*/) != -1) {
								jQuery("#left_page_edit_footer_" + cId).prop(
										"disabled", !checked);
							} else if (id.search(/^right_page_enable_footer.*/) != -1) {
								jQuery("#right_page_edit_footer_" + cId).prop(
										"disabled", !checked);
							}
						});
		jQuery("#pagePropertiesHeaderFooter_" + cId + " input[type='button']")
				.click(
						function(event) {
							if (!jQuery(this).prop("disabled")) {
								var id = jQuery(this).attr("id");
								if (id.search(/^default_page_edit_header.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#default_page_edit_header_content_"
													+ cId));
								} else if (id
										.search(/^first_page_edit_header.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#first_page_edit_header_content_"
													+ cId));
								} else if (id
										.search(/^left_page_edit_header.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#left_page_edit_header_content_"
													+ cId));
								} else if (id
										.search(/^right_page_edit_header.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#right_page_edit_header_content_"
													+ cId));
								} else if (id
										.search(/^default_page_edit_footer.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#default_page_edit_footer_content_"
													+ cId));
								} else if (id
										.search(/^first_page_edit_footer.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#first_page_edit_footer_content_"
													+ cId));
								} else if (id
										.search(/^left_page_edit_footer.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#left_page_edit_footer_content_"
													+ cId));
								} else if (id
										.search(/^right_page_edit_footer.*/) != -1) {
									thiz
											.headerFooterDialog(jQuery("#right_page_edit_footer_content_"
													+ cId));
								}
							}
						});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var json = {};
			json["mirror"] = (pageLayout.val() === "mirrored" ? "true"
					: "false");
			var defaultPage = json["default-page-properties"] = {};
			defaultPage["margin-top"] = pageTopSpinner.val() + ""
					+ pageMarginTopUnit.val();
			defaultPage["margin-bottom"] = pageBottomSpinner.val() + ""
					+ pageMarginBottomUnit.val();
			defaultPage["margin-left"] = pageLeftSpinner.val() + ""
					+ pageMarginLeftUnit.val();
			defaultPage["margin-right"] = pageRightSpinner.val() + ""
					+ pageMarginRightUnit.val();
			defaultPage["width"] = pageSizeWidthSpinner.val() + ""
					+ pageSizeUnit.val();
			defaultPage["height"] = pageSizeHeightSpinner.val() + ""
					+ pageSizeUnit.val();
			var firstPage = json["first-page-properties"] = "null";
			if (jQuery("#first_page_enable_" + cId).is(":checked")) {
				firstPage = json["first-page-properties"] = {};
				firstPage["margin-top"] = firstPageTopSpinner.val() + ""
						+ firstPageMarginTopUnit.val();
				firstPage["margin-bottom"] = firstPageBottomSpinner.val() + ""
						+ firstPageMarginBottomUnit.val();
				firstPage["margin-left"] = firstPageLeftSpinner.val() + ""
						+ firstPageMarginLeftUnit.val();
				firstPage["margin-right"] = firstPageRightSpinner.val() + ""
						+ firstPageMarginRightUnit.val();
				firstPage["width"] = firstPageSizeWidthSpinner.val() + ""
						+ firstPageSizeUnit.val();
				firstPage["height"] = firstPageSizeHeightSpinner.val() + ""
						+ firstPageSizeUnit.val();
			}
			var defaultPageHeaderFooter = json["default-page-hf-properties"] = {
				"top-center" : "null",
				"bottom-center" : "null"
			};
			var firstPageHeaderFooter = json["first-page-hf-properties"] = {
				"top-center" : "null",
				"bottom-center" : "null"
			};
			var leftPageHeaderFooter = json["left-page-hf-properties"] = {
				"top-center" : "null",
				"bottom-center" : "null"
			};
			var rightPageHeaderFooter = json["right-page-hf-properties"] = {
				"top-center" : "null",
				"bottom-center" : "null"
			};
			if (jQuery("#default_page_enable_header_" + cId).prop("checked")) {
				defaultPageHeaderFooter["top-center"] = {
					"xhtml-content" : jQuery(
							"#default_page_edit_header_content_" + cId).val()
				};
			}
			if (jQuery("#default_page_enable_footer_" + cId).prop("checked")) {
				defaultPageHeaderFooter["bottom-center"] = {
					"xhtml-content" : jQuery(
							"#default_page_edit_footer_content_" + cId).val()
				};
			}
			if (jQuery("#first_page_enable_header_" + cId).prop("checked")) {
				firstPageHeaderFooter["top-center"] = {
					"xhtml-content" : jQuery(
							"#first_page_edit_header_content_" + cId).val()
				};
			}
			if (jQuery("#first_page_enable_footer_" + cId).prop("checked")) {
				firstPageHeaderFooter["bottom-center"] = {
					"xhtml-content" : jQuery(
							"#first_page_edit_footer_content_" + cId).val()
				};
			}
			if (jQuery("#left_page_enable_header_" + cId).prop("checked")) {
				leftPageHeaderFooter["top-center"] = {
					"xhtml-content" : jQuery(
							"#left_page_edit_header_content_" + cId).val()
				};
			}
			if (jQuery("#left_page_enable_footer_" + cId).prop("checked")) {
				leftPageHeaderFooter["bottom-center"] = {
					"xhtml-content" : jQuery(
							"#left_page_edit_footer_content_" + cId).val()
				};
			}
			if (jQuery("#right_page_enable_header_" + cId).prop("checked")) {
				rightPageHeaderFooter["top-center"] = {
					"xhtml-content" : jQuery(
							"#right_page_edit_header_content_" + cId).val()
				};
			}
			if (jQuery("#right_page_enable_footer_" + cId).prop("checked")) {
				rightPageHeaderFooter["bottom-center"] = {
					"xhtml-content" : jQuery(
							"#right_page_edit_footer_content_" + cId).val()
				};
			}
			json = jQuery.toJSON(json);
			apiObject.toolkitInternal._setPageProperties(json);
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
		var pageProperties = apiObject.toolkitInternal._getPageProperties();
		if (pageProperties !== "") {
			if (pageProperties["default-page-properties"] != undefined) {
				var defaultPage = pageProperties["default-page-properties"];
				if (defaultPage["margin-top"] !== undefined) {
					pageTopSpinner.val(defaultPage["margin-top"]);
				}
				if (defaultPage["margin-bottom"] !== undefined) {
					pageBottomSpinner.val(defaultPage["margin-bottom"]);
				}
				if (defaultPage["margin-left"] !== undefined) {
					pageLeftSpinner.val(defaultPage["margin-left"]);
				}
				if (defaultPage["margin-right"] !== undefined) {
					pageRightSpinner.val(defaultPage["margin-right"]);
				}
				if (defaultPage["margin-top-unit"] !== undefined) {
					pageMarginTopUnit.children(
							"option[value='" + defaultPage["margin-top-unit"]
									+ "']").prop("selected", true);
				}
				if (defaultPage["margin-bottom-unit"] !== undefined) {
					pageMarginBottomUnit.children(
							"option[value='"
									+ defaultPage["margin-bottom-unit"] + "']")
							.prop("selected", true);
				}
				if (defaultPage["margin-left-unit"] !== undefined) {
					pageMarginLeftUnit.children(
							"option[value='" + defaultPage["margin-left-unit"]
									+ "']").prop("selected", true);
				}
				if (defaultPage["margin-right-unit"] !== undefined) {
					pageMarginRightUnit.children(
							"option[value='" + defaultPage["margin-right-unit"]
									+ "']").prop("selected", true);
				}
				if (defaultPage["width"] !== undefined) {
					pageSizeWidthSpinner.val(defaultPage["width"]);
				}
				if (defaultPage["height"] !== undefined) {
					pageSizeHeightSpinner.val(defaultPage["height"]);
				}
				if (defaultPage["page-size-unit"] !== undefined) {
					pageSizeUnit.children(
							"option[value='" + defaultPage["page-size-unit"]
									+ "']").prop("selected", true);
				}
				jQuery(".spinnerUnit").trigger("change");
				pageSizeWidthSpinner.trigger("change");
				pageSizeUnit.trigger("change");
			}
			if (pageProperties["mirror"] !== "false") {
				pageLayout.children("option[value='mirrored']").prop(
						"selected", true);
				pageLayout.trigger("change");
			}
			if (pageProperties["first-page-properties"] != undefined) {
				var firstPage = pageProperties["first-page-properties"];
				if (firstPage["margin-top"] !== undefined) {
					firstPageTopSpinner.val(firstPage["margin-top"]);
				}
				if (firstPage["margin-bottom"] !== undefined) {
					firstPageBottomSpinner.val(firstPage["margin-bottom"]);
				}
				if (firstPage["margin-left"] !== undefined) {
					firstPageLeftSpinner.val(firstPage["margin-left"]);
				}
				if (firstPage["margin-right"] !== undefined) {
					firstPageRightSpinner.val(firstPage["margin-right"]);
				}
				if (firstPage["margin-top-unit"] !== undefined) {
					firstPageMarginTopUnit.children(
							"option[value='" + firstPage["margin-top-unit"]
									+ "']").prop("selected", true);
				}
				if (firstPage["margin-bottom-unit"] !== undefined) {
					firstPageMarginBottomUnit.children(
							"option[value='" + firstPage["margin-bottom-unit"]
									+ "']").prop("selected", true);
				}
				if (firstPage["margin-left-unit"] !== undefined) {
					firstPageMarginLeftUnit.children(
							"option[value='" + firstPage["margin-left-unit"]
									+ "']").prop("selected", true);
				}
				if (firstPage["margin-right-unit"] !== undefined) {
					firstPageMarginRightUnit.children(
							"option[value='" + firstPage["margin-right-unit"]
									+ "']").prop("selected", true);
				}
				if (firstPage["width"] !== undefined) {
					firstPageSizeWidthSpinner.val(firstPage["width"]);
				}
				if (firstPage["height"] !== undefined) {
					firstPageSizeHeightSpinner.val(firstPage["height"]);
				}
				if (firstPage["page-size-unit"] !== undefined) {
					firstPageSizeUnit.children(
							"option[value='" + firstPage["page-size-unit"]
									+ "']").prop("selected", true);
				}
				jQuery("#first_page_enable_" + cId).prop("checked", true)
						.trigger("change");
				jQuery(".spinnerUnit").trigger("change");
				firstPageSizeWidthSpinner.trigger("change");
				firstPageSizeUnit.trigger("change");
			}
			if (pageProperties["default-page-hf-properties"] != undefined) {
				var pageHF = pageProperties["default-page-hf-properties"];
				var pageHFTC = pageHF["top-center"];
				var pageHFBC = pageHF["bottom-center"];
				if (pageHFTC != undefined
						&& pageHFTC["xhtml-content"] != undefined
						&& pageHFTC["xhtml-content"] != "") {
					jQuery("#default_page_enable_header_" + cId).prop(
							"checked", true).trigger("change");
					var val = pageHFTC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#default_page_edit_header_content_" + cId).val(val);
				}
				if (pageHFBC != undefined
						&& pageHFBC["xhtml-content"] != undefined
						&& pageHFBC["xhtml-content"] != "") {
					jQuery("#default_page_enable_footer_" + cId).prop(
							"checked", true).trigger("change");
					var val = pageHFBC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#default_page_edit_footer_content_" + cId).val(val);
				}
			}
			if (pageProperties["first-page-hf-properties"] != undefined) {
				var pageHF = pageProperties["first-page-hf-properties"];
				var pageHFTC = pageHF["top-center"];
				var pageHFBC = pageHF["bottom-center"];
				if (pageHFTC != undefined
						&& pageHFTC["xhtml-content"] != undefined
						&& pageHFTC["xhtml-content"] != "") {
					jQuery("#first_page_enable_header_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFTC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#first_page_edit_header_content_" + cId).val(val);
				}
				if (pageHFBC != undefined
						&& pageHFBC["xhtml-content"] != undefined
						&& pageHFBC["xhtml-content"] != "") {
					jQuery("#first_page_enable_footer_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFBC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#first_page_edit_footer_content_" + cId).val(val);
				}
			}
			if (pageProperties["left-page-hf-properties"] != undefined) {
				var pageHF = pageProperties["left-page-hf-properties"];
				var pageHFTC = pageHF["top-center"];
				var pageHFBC = pageHF["bottom-center"];
				if (pageHFTC != undefined
						&& pageHFTC["xhtml-content"] != undefined
						&& pageHFTC["xhtml-content"] != "") {
					jQuery("#left_page_enable_header_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFTC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#left_page_edit_header_content_" + cId).val(val);
				}
				if (pageHFBC != undefined
						&& pageHFBC["xhtml-content"] != undefined
						&& pageHFBC["xhtml-content"] != "") {
					jQuery("#left_page_enable_footer_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFBC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#left_page_edit_footer_content_" + cId).val(val);
				}
			}
			if (pageProperties["right-page-hf-properties"] != undefined) {
				var pageHF = pageProperties["right-page-hf-properties"];
				var pageHFTC = pageHF["top-center"];
				var pageHFBC = pageHF["bottom-center"];
				if (pageHFTC != undefined
						&& pageHFTC["xhtml-content"] != undefined
						&& pageHFTC["xhtml-content"] != "") {
					jQuery("#right_page_enable_header_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFTC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#right_page_edit_header_content_" + cId).val(val);
				}
				if (pageHFBC != undefined
						&& pageHFBC["xhtml-content"] != undefined
						&& pageHFBC["xhtml-content"] != "") {
					jQuery("#right_page_enable_footer_" + cId).prop("checked",
							true).trigger("change");
					var val = pageHFBC["xhtml-content"].replace(/\\\"/g, "\"");
					jQuery("#right_page_edit_footer_content_" + cId).val(val);
				}
			}
		}
	};
	this.insertStructureTemplateDialog = function() {
		var html = this.dialogHTMLMap["insertStructureTemplate"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_INSERT_STRUCTURE_TEMPLATE_DIALOG"));
		this._showDialog(html);
		var tree = this._parseStructureTemplates();
		jQuery("#templateTree_" + cId).append(tree);
		jQuery("#templateTree_" + cId + " > ul").treeview({
			collapsed : true,
			unique : false
		});
		jQuery("ul.fileList:empty").parent("ul").parent("li").remove();
		jQuery("li.templateFile").bind("dblclick", function() {
			var url = jQuery(this).attr("name");
			apiObject.insertContentFromURL(url);
			thiz._hideDialog();
		});
		jQuery("li.templateFile").bind("click", function() {
			jQuery("li.templateFile span").css({
				"background-color" : "transparent",
				"color" : "black"
			});
			jQuery(this).children("span").css({
				"background-color" : "blue",
				"color" : "white"
			});
			jQuery("li.templateFile").removeClass("selectedTemplateItem");
			jQuery(this).addClass("selectedTemplateItem");
		});
		jQuery("div.ui-tooltip").remove();
		jQuery("li.templateFile span").each(function() {
			jQuery(this).tooltip({
				content : function() {
					return jQuery(this).next().html();
				}
			});
		});
		jQuery("li.templateFile").first().addClass("selectedTemplateItem")
				.children("span").css({
					"background-color" : "blue",
					"color" : "white"
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
			var url = jQuery("li.selectedTemplateItem").attr("name");
			apiObject.insertContentFromURL(url);
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.insertBookmarkDialog = function() {
		var bookmarkProperties = apiObject.toolkitInternal
				._getBookmarkProperties();
		var existingBookmark = "";
		if (bookmarkProperties !== "") {
			existingBookmark = bookmarkProperties["name"];
		}
		if (existingBookmark != undefined && existingBookmark != "") {
			this.bookmarkPropertiesDialog();
			return;
		}
		var html = this.dialogHTMLMap["insertBookmark"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_INSERT_BOOKMARK_DIALOG"));
		this._showDialog(html);
		var bookmarkList = apiObject.getBookmarkList();
		if (bookmarkList !== null) {
			for (var i = 0; i < bookmarkList.length; i++) {
				var option = "";
				var classContent = "";
				var value = bookmarkList[i];
				if (i === 0) {
					classContent = " class='ui-selected' ";
				}
				if (value !== undefined) {
					option = "<li " + classContent + " name=\"" + value + "\">"
							+ value + "</li>";
				}
				jQuery("#bookmark_blockelements_" + cId).append(option);
				jQuery("#bookmark_blockelements_" + cId + " li").bind(
						"click",
						function() {
							jQuery(this).siblings().removeClass("ui-selected");
							jQuery(this).addClass("ui-selected");
							jQuery("#bookmark_text_field_" + cId).val(
									jQuery(this).attr("name"));
						});
			}
		}
		jQuery("#go_to_bookmark_button_" + cId).bind("click", function() {
			var bookmarkName = jQuery("#bookmark_text_field_" + cId).val();
			if (bookmarkName !== undefined) {
				apiObject.invokeAction("move-to-bookmark", bookmarkName);
			} else {
			}
		});
		var addButton = jQuery("#add_bookmark_button_" + cId);
		addButton.bind("click", function() {
			var bookmarkName = jQuery("#bookmark_text_field_" + cId).val();
			if (bookmarkName !== undefined) {
				boomarkName = jQuery.trim(bookmarkName);
				apiObject.invokeAction("insert-bookmark", bookmarkName);
				thiz._hideDialog();
			} else {
			}
		});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		jQuery("#bookmark_text_field_" + cId).bind("keyup", function() {
			thiz._verifyBookmark();
		});
		addButton.attr("disabled", "disabled");
		addButton.addClass("ui-state-disabled");
		this._dialogCreateTabs();
	};
	this.bookmarkPropertiesDialog = function() {
		var bookmarkProperties = apiObject.toolkitInternal
				._getBookmarkProperties();
		var existingBookmark = "";
		if (bookmarkProperties !== "") {
			existingBookmark = bookmarkProperties["name"];
		}
		var html = this.dialogHTMLMap["insertBookmark"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_BOOKMARK_PROPERTIES_DIALOG"));
		this._showDialog(html);
		if (existingBookmark != undefined && existingBookmark != "") {
			jQuery("#bookmark_text_field_" + cId).val(existingBookmark);
		}
		var bookmarkList = apiObject.getBookmarkList();
		if (bookmarkList !== null) {
			for (var i = 0; i < bookmarkList.length; i++) {
				var option = "";
				var classContent = "";
				var value = bookmarkList[i];
				if (i === 0) {
					classContent = " class='ui-selected' ";
				}
				if (value !== undefined) {
					option = "<li " + classContent + " name=\"" + value + "\">"
							+ value + "</li>";
				}
				jQuery("#bookmark_blockelements_" + cId).append(option);
				jQuery("#bookmark_blockelements_" + cId + " li").bind(
						"click",
						function() {
							jQuery(this).siblings().removeClass("ui-selected");
							jQuery(this).addClass("ui-selected");
							jQuery("#bookmark_text_field_" + cId).val(
									jQuery(this).attr("name"));
						});
			}
		}
		jQuery("#go_to_bookmark_button_" + cId).bind("click", function() {
			var bookmarkName = jQuery("#bookmark_text_field_" + cId).val();
			if (bookmarkName !== undefined) {
				apiObject.invokeAction("move-to-bookmark", bookmarkName);
			} else {
			}
		});
		var addButton = jQuery("#add_bookmark_button_" + cId);
		addButton.bind("click", function() {
			var bookmarkName = jQuery("#bookmark_text_field_" + cId).val();
			if (bookmarkName !== undefined) {
				boomarkName = jQuery.trim(bookmarkName);
				apiObject.invokeAction("insert-bookmark", bookmarkName);
				thiz._hideDialog();
			} else {
			}
		});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		jQuery("#bookmark_text_field_" + cId).bind("keyup", function() {
			thiz._verifyBookmark();
		});
		addButton.attr("disabled", "disabled");
		addButton.addClass("ui-state-disabled");
		this._dialogCreateTabs();
	};
	this.insertHyperlinkDialog = function() {
		var bookmarkProperties = apiObject.toolkitInternal
				._getBookmarkProperties();
		var existingBookmark = "";
		if (bookmarkProperties !== "") {
			existingBookmark = bookmarkProperties["name"];
		}
		var hyperlinkText = "";
		var hyperlinkProperties = apiObject.toolkitInternal
				._getHyperlinkProperties();
		if (hyperlinkProperties !== "") {
			hyperlinkText = hyperlinkProperties["text"];
			if (hyperlinkProperties["href"] !== undefined) {
				this.linkPropertiesDialog();
				return;
			}
		}
		var html = this.dialogHTMLMap["insertHyperlink"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_INSERT_HYPERLINK_DIALOG"));
		this._showDialog(html);
		if (hyperlinkText !== undefined && hyperlinkText !== "") {
			jQuery("#hyperlink_text_field_" + cId).val(hyperlinkText);
		}
		jQuery(
				"#bookmark_blockelements_" + cId + " li[name='"
						+ existingBookmark + "']").trigger("click");
		this._bindOpenFileDialog("#hyperlink_open_file_button_" + cId,
				"#hyperlink_url_field_" + cId, null);
		this._bindOpenWebdavDialog("#link_open_webdav_button_" + cId,
				"#hyperlink_url_field_" + cId, "get-webdav-hyperlink");
		if (!apiObject.isActionEnabled("get-webdav-hyperlink")) {
			jQuery("#link_open_webdav_button_" + cId).hide();
		}
		var tabs = null;
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
			currTab = tabs.tabs('option', 'active');
			var externalURL = jQuery("#hyperlink_url_field_" + cId).val();
			var target = jQuery("#targetChooser_" + cId).val();
			var title = jQuery("#hyperlink_title_field_" + cId).val();
			var text = jQuery
					.trim(jQuery("#hyperlink_text_field_" + cId).val());
			var bookmarkURL = jQuery("#bookmark_text_field_" + cId).val();
			var insertURL = "";
			if (currTab == 0) {
				insertURL = externalURL;
			} else if (currTab == 1) {
				insertURL = bookmarkURL;
			}
			if (insertURL !== undefined && insertURL !== "") {
				json = {};
				if (title !== "") {
					json.title = title;
				}
				if (target !== "") {
					json.target = target;
				}
				if (text !== "") {
					json.text = text;
				} else {
					json.text = insertURL;
				}
				json.href = insertURL;
				json = jQuery.toJSON(json);
				apiObject.invokeAction("insert-hyperlink", json);
				thiz._hideDialog();
			} else {
				jQuery("#no_hyperlink_" + cId).show();
			}
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		tabs = jQuery("#insertHyperlinkTabContainer_" + cId).tabs();
		this._dialogCreateTabs();
		bookmarkList = apiObject.getBookmarkList();
		if (bookmarkList !== null) {
			for (var i = 0; i < bookmarkList.length; i++) {
				var option = "";
				var classContent = "";
				var value = bookmarkList[i];
				if (i === 0) {
					classContent = " class='ui-selected' ";
				}
				if (value !== undefined) {
					option = "<li " + classContent + " name=\"" + value + "\">"
							+ value + "</li>";
				}
				jQuery("#bookmark_blockelements_" + cId).append(option);
				jQuery("#bookmark_blockelements_" + cId + " li").bind(
						"click",
						function() {
							jQuery(this).siblings().removeClass("ui-selected");
							jQuery(this).addClass("ui-selected");
							jQuery("#bookmark_text_field_" + cId).val(
									"#" + jQuery(this).attr("name"));
						});
			}
		}
	};
	this.insertCrossreferenceDialog = function() {
		var isEdit = (apiObject.toolkitInternal._isCrossReferenceSelected() === "true");
		var dialogHTMLMapString;
		var localizedDialogTitle;
		if (isEdit) {
			dialogHTMLMapString = "insertCrossreference";
			localizedDialogTitle = apiObject.locale
					.getLocaleCode("L_EDIT_CROSSREFERENCE_DIALOG");
		} else {
			dialogHTMLMapString = "insertCrossreference";
			localizedDialogTitle = apiObject.locale
					.getLocaleCode("L_INSERT_CROSSREFERENCE_DIALOG");
		}
		var html = this.dialogHTMLMap[dialogHTMLMapString];
		this._createDialog(localizedDialogTitle);
		this._showDialog(html);
		var uiData = null;
		var json = apiObject.toolkitInternal._getCrossReferenceBlockList();
		if (json !== "") {
			uiData = json;
		}
		var i = 0;
		var elementTypesList = jQuery("#reference_element_types_" + cId);
		jQuery.each(uiData, function(elementType, elements) {
			var elementTypeOption = jQuery("<li name=\"" + i + "\">"
					+ elementType + "</li>");
			elementTypeOption.bind("click", {
				msg : elements
			}, function(event) {
				var elements = event.data.msg;
				jQuery(this).siblings().removeClass("ui-selected");
				jQuery(this).addClass("ui-selected");
				thiz._fillReferenceElementsList(elements);
			});
			if (i === 0) {
				elementTypeOption.addClass("ui-selected");
				thiz._fillReferenceElementsList(elements);
			}
			elementTypesList.append(elementTypeOption);
			i++;
		});
		if (isEdit) {
			var referenceProperties = apiObject.toolkitInternal
					._getCurrentCrossReferenceProperties();
			if (referenceProperties !== "null"
					&& referenceProperties !== undefined
					&& referenceProperties !== "") {
				var elementTypeIndex = referenceProperties.elementTypeIndex;
				var referenceElementIndex = referenceProperties.referenceElementIndex;
				var insertedContentType = referenceProperties.insertedContentType;
				var insertAsHyperlink = referenceProperties.insertAsHyperlink;
				var elementTypesList = jQuery("#reference_element_types_" + cId);
				var elementTypeOption = elementTypesList.children("[name=\""
						+ elementTypeIndex + "\"]");
				elementTypeOption.click();
				var referenceElementList = jQuery("#reference_blockelements_"
						+ cId);
				var referenceElementOption = referenceElementList
						.children("[name=\"" + referenceElementIndex + "\"]");
				referenceElementOption.click();
				jQuery(
						"input[name='source_radio_" + cId + "'][value='"
								+ insertedContentType + "']").attr("checked",
						"true");
				if (insertAsHyperlink === true) {
					jQuery("#reference_options_hyperlink_" + cId).attr(
							"checked", true);
				} else {
					jQuery("#reference_options_hyperlink_" + cId).attr(
							"checked", false);
				}
			}
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
			var returnData = thiz._createCrossreferencesJSON();
			if (returnData !== null) {
				if (isEdit) {
					apiObject.toolkitInternal._editCrossReference(returnData);
				} else {
					apiObject.toolkitInternal._insertCrossReference(returnData);
				}
			}
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.linkPropertiesDialog = function() {
		var currentElement = apiObject.getCurrentElement();
		if (/^<a.*/.test(currentElement)) {
			var html = this.dialogHTMLMap["linkProperties"];
			this._createDialog(apiObject.locale
					.getLocaleCode("L_HYPERLINK_PROPERTIES_DIALOG"));
			this._showDialog(html);
			this._bindOpenFileDialog("#hyperlink_open_file_button_" + cId,
					"#hyperlink_url_field_" + cId, null);
			this._bindOpenWebdavDialog("#link_open_webdav_button_" + cId,
					"#hyperlink_url_field_" + cId, "get-webdav-hyperlink");
			if (!apiObject.isActionEnabled("get-webdav-hyperlink")) {
				jQuery("#link_open_webdav_button_" + cId).hide();
			}
			var linkProperties = apiObject.toolkitInternal
					._getHyperlinkProperties();
			if (linkProperties != null) {
				jQuery("#hyperlink_url_field_" + cId).val(
						linkProperties["href"]);
				jQuery(
						"#targetChooser_" + cId + " option[value='"
								+ linkProperties["target"] + "']").prop(
						"selected", true);
				jQuery("#hyperlink_title_field_" + cId).val(
						linkProperties["title"]);
				var textField = jQuery("#hyperlink_text_field_" + cId);
				if (linkProperties["text"] == undefined) {
					textField.val("<Document Selection>");
					textField.attr("disabled", "disabled");
				} else {
					textField.val(linkProperties["text"]);
					textField.removeAttr("disabled");
				}
			}
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
				var url = jQuery("#hyperlink_url_field_" + cId).val();
				var text;
				var textField = jQuery("#hyperlink_text_field_" + cId);
				if (textField.attr("disabled") == undefined) {
					text = jQuery("#hyperlink_text_field_" + cId).val();
				} else {
					text = undefined;
				}
				var target = jQuery("#targetChooser_" + cId).val();
				var title = jQuery("#hyperlink_title_field_" + cId).val();
				if (url !== undefined && url !== "") {
					json = {};
					if (title !== "") {
						json.title = title;
					} else {
						json.title = null;
					}
					if (target !== "") {
						json.target = target;
					} else {
						json.target = null;
					}
					if (text !== linkProperties["text"]) {
						if (text !== "null" && text !== null && text.length > 0) {
							apiObject.setCurrentElementContent(text);
						}
					}
					json.href = url;
					apiObject.setElementAttributes(json);
					thiz._hideDialog();
				} else {
				}
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._dialogCreateTabs();
		}
	};
	this.compareDocumentsDialog = function() {
		var html = this.dialogHTMLMap["compareDocuments"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_COMPARE_DOCUMENTS_DIALOG"));
		this._showDialog(html);
		thiz._bindOpenFileDialog("#compare_file1_open_button_" + cId,
				"#compare_file1_field_" + cId, "document");
		thiz._bindOpenFileDialog("#compare_file2_open_button_" + cId,
				"#compare_file2_field_" + cId, "document");
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_COMPARE_BUTTON")] = function() {
			var url1 = "";
			var url2 = "";
			url1 = jQuery("#compare_file1_field_" + cId).val();
			url2 = jQuery("#compare_file2_field_" + cId).val();
			apiObject.toolkitInternal._compareDocumentsFromURL(url1, url2);
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.loadURLDialog = function() {
		var html = this.dialogHTMLMap["loadURL"];
		this._createDialog(apiObject.locale.getLocaleCode("L_LOAD_URL_DIALOG"));
		this._showDialog(html);
		var value = apiObject.toolkitInternal
				._getUserPreferences("loadurldialog");
		if (value !== null) {
			jQuery("#url_field_" + cId).attr({
				value : value
			});
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		if (apiObject.isActionEnabled("get-webdav-document")) {
			buttons[apiObject.locale.getLocaleCode("L_WEBDAV_OPEN")] = function() {
				thiz._openWebdavDialog("#url_field_" + cId,
						"get-webdav-document");
			};
		}
		buttons[apiObject.locale.getLocaleCode("L_LOAD_BUTTON")] = function() {
			var url = jQuery("#url_field_" + cId).val();
			thiz._hideDialog();
			apiObject.loadDocumentFromURL(url);
			apiObject.toolkitInternal._setUserPreferences({
				"loadurldialog" : url
			});
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.insertTableDialog = function() {
		var html = this.dialogHTMLMap["insertTable"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_INSERT_TABLE_DIALOG"));
		this._showDialog(html);
		this._createSpinner("#table_cell_padding_" + cId, 0, 100);
		this._createSpinner("#table_cell_spacing_" + cId, 0, 100);
		this._createSpinner("#table_border_width_" + cId, 0, 100);
		this._createDrawTableElement("tableDialog_table_" + cId, "table_rows_"
				+ cId, "table_columns_" + cId, 7, 8);
		jQuery("#tableColorPicker_" + cId)
				.bind(
						"click",
						function() {
							thiz
									.generalColorDialog(
											"#tableColorPicker_" + cId,
											apiObject.locale
													.getLocaleCode("L_TABLE_BACKGROUND_COLOR"));
						});
		jQuery("#tableBorderColorPicker_" + cId).bind(
				"click",
				function() {
					thiz.generalColorDialog("#tableBorderColorPicker_" + cId,
							apiObject.locale
									.getLocaleCode("L_TABLE_BORDER_COLOR"));
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
			var tableRows = jQuery("#table_rows_" + cId).val();
			var tableColumns = jQuery("#table_columns_" + cId).val();
			var tableWidth = jQuery("#table_width_" + cId).val();
			var tableWidthUnit = jQuery("#table_width_unit_" + cId).val();
			var tableBorderWidth = jQuery("#table_border_width_" + cId).val();
			var tableAlignment = jQuery("#table_alignment_" + cId).val();
			var cellPadding = jQuery("#table_cell_padding_" + cId).val();
			var cellSpacing = jQuery("#table_cell_spacing_" + cId).val();
			var tableBGColor = jQuery("#tableColorPicker_" + cId).attr("name");
			var tableBorderColor = jQuery("#tableBorderColorPicker_" + cId)
					.attr("name");
			var tableAttr = {};
			if (tableRows === "" || tableRows === undefined) {
				tableAttr.tableRows = 2;
			} else {
				tableAttr.tableRows = tableRows;
			}
			if (tableColumns === "" || tableColumns === undefined) {
				tableAttr.tableColumns = 2;
			} else {
				tableAttr.tableColumns = tableColumns;
			}
			if (tableWidthUnit === "percent") {
				tableAttr.tableWidthUnit = "%";
			} else {
				tableAttr.tableWidthUnit = tableWidthUnit;
			}
			if (tableWidth !== "" && tableWidth !== undefined) {
				tableAttr.tableWidth = tableWidth;
			} else {
				tableAttr.tableWidth = null;
			}
			if (tableBorderWidth !== "" && tableBorderWidth !== undefined) {
				tableAttr.borderWidth = tableBorderWidth;
				tableAttr.borderWidthUnit = "px";
			} else {
				tableAttr.borderWidth = null;
			}
			if (tableAlignment !== "default") {
				tableAttr.tableAlignment = tableAlignment;
			} else {
				tableAttr.tableAlignment = null;
			}
			if (tableBGColor !== "" && tableBGColor !== undefined
					&& tableBGColor !== "none") {
				tableAttr.tableBGColor = tableBGColor;
			} else {
				tableAttr.tableBGColor = null;
			}
			if (tableBorderColor !== "" && tableBorderColor !== undefined
					&& tableBorderColor !== "none") {
				tableAttr.tableBorderColor = tableBorderColor;
			} else {
				tableAttr.tableBorderColor = null;
			}
			if (cellPadding !== "" && cellPadding !== undefined) {
				tableAttr.cellPadding = cellPadding;
				tableAttr.cellPaddingUnit = "px";
			} else {
				tableAttr.cellPadding = null;
			}
			if (cellSpacing !== "" && cellSpacing !== undefined) {
				tableAttr.cellSpacing = cellSpacing;
				tableAttr.cellSpacingUnit = "px";
			} else {
				tableAttr.cellSpacing = null;
			}
			apiObject.invokeAction("insert-table", jQuery.toJSON(tableAttr));
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.textColorDialog = function() {
		var html = this.dialogHTMLMap["textColor"];
		this._createDialog(apiObject.locale.getLocaleCode("L_COLOR_DIALOG"));
		this._showDialog(html);
		this._createColorSelectTable(this._defaultColors,
				"textColor_default_color_table_" + cId);
		var combinedColors = [];
		var addedColors = [];
		if (apiObject.config.presetcolors !== undefined) {
			for (var i = 0; i < apiObject.config.presetcolors.color.length; i++) {
				combinedColors.push(apiObject.config.presetcolors.color[i]);
			}
		}
		var upcolors = apiObject.toolkitInternal
				._getUserPreferences("colordialog");
		if (upcolors !== null) {
			for (var i = 0; i < upcolors.length; i++) {
				combinedColors.push(upcolors[i]);
			}
		}
		this._createColorSelectTable(combinedColors,
				"textColor_custom_color_table_" + cId);
		jQuery("#colorPicker_" + cId).ColorPicker(
				{
					color : '#0000ff',
					onShow : function(colpkr) {
						jQuery(colpkr).fadeIn(100);
						return false;
					},
					onHide : function(colpkr) {
						jQuery(colpkr).fadeOut(100);
						return false;
					},
					onChange : function(hsb, hex, rgb) {
						jQuery("#colorPicker_" + cId).css('backgroundColor',
								'#' + hex);
						jQuery("#colorPicker_" + cId).attr('name', '#' + hex);
						jQuery("#hexvalue_" + cId).val("#" + hex);
					}
				});
		jQuery("#textColor_default_color_table_" + cId + " button").each(
				function(index, value) {
					jQuery(this).bind('click', this, function(e) {
						apiObject.invokeAction('color', e.data.name);
						thiz._hideDialog();
						if (addedColors.length > 0) {
							apiObject.toolkitInternal._setUserPreferences({
								"colordialog" : addedColors
							});
						}
					});
				});
		jQuery("#textColor_custom_color_table_" + cId + " button").each(
				function(index, value) {
					jQuery(this).bind("click", this, function(e) {
						apiObject.invokeAction('color', e.data.name);
						thiz._hideDialog();
						if (addedColors.length > 0) {
							apiObject.toolkitInternal._setUserPreferences({
								"colordialog" : addedColors
							});
						}
						addedColors = [];
					});
				});
		jQuery("#colorSelectorSubmit_" + cId).bind("click", function() {
			color = jQuery("#colorPicker_" + cId).attr('name');
			apiObject.invokeAction('color', color);
			thiz._hideDialog();
			if (addedColors.length > 0) {
				apiObject.toolkitInternal._setUserPreferences({
					"colordialog" : addedColors
				});
			}
			addedColors = [];
		});
		jQuery("#colorSelectorAdd_" + cId).bind(
				"click",
				function() {
					color = jQuery("#colorPicker_" + cId).attr('name');
					colorObject = {
						"rgb" : color,
						"desc" : color
					};
					addedColors.push(colorObject);
					combinedColors.push(colorObject);
					jQuery("#textColor_custom_color_table_" + cId).html("");
					thiz._createColorSelectTable(combinedColors,
							"textColor_custom_color_table_" + cId);
					if (addedColors.length > 0) {
						apiObject.toolkitInternal._setUserPreferences({
							"colordialog" : addedColors
						});
					}
					addedColors = [];
					jQuery("#textColor_custom_color_table_" + cId + " button")
							.each(
									function(index, value) {
										jQuery(this).bind(
												"click",
												this,
												function(e) {
													apiObject.invokeAction(
															'color',
															e.data.name);
													thiz._hideDialog();
												});
									});
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_REMOVE_COLOR")] = function() {
			thiz._hideDialog();
			apiObject.invokeAction('color', null);
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
		index = 0;
		if (apiObject.config.allowdefaultcolors !== undefined
				&& apiObject.config.allowdefaultcolors != "false") {
		} else {
			jQuery("#textColor_default_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowpresetcolors !== undefined
				&& apiObject.config.allowpresetcolors != "false"
				&& apiObject.config.presetcolors !== undefined) {
		} else {
			jQuery("#textColor_custom_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowfreecolors !== undefined
				&& apiObject.config.allowfreecolors != "false") {
		} else {
			jQuery("#colorPicker_" + cId).parents("td.ribbonPanel").remove();
		}
	};
	this.backgroundColorDialog = function() {
		var html = this.dialogHTMLMap["backgroundColor"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_BACKGROUNDCOLOR_DIALOG"));
		this._showDialog(html);
		this._createColorSelectTable(this._defaultColors,
				"backgroundColor_default_color_table_" + cId);
		var combinedColors = [];
		var addedColors = [];
		if (apiObject.config.presetcolors !== undefined) {
			for (var i = 0; i < apiObject.config.presetcolors.color.length; i++) {
				combinedColors.push(apiObject.config.presetcolors.color[i]);
			}
		}
		var upcolors = apiObject.toolkitInternal
				._getUserPreferences("colordialog");
		if (upcolors !== null) {
			for (i = 0; i < upcolors.length; i++) {
				combinedColors.push(upcolors[i]);
			}
		}
		this._createColorSelectTable(combinedColors,
				"backgroundColor_custom_color_table_" + cId);
		jQuery("#colorPicker_" + cId).ColorPicker(
				{
					color : '#0000ff',
					onShow : function(colpkr) {
						jQuery(colpkr).fadeIn(100);
						return false;
					},
					livePreview : false,
					onHide : function(colpkr) {
						jQuery(colpkr).fadeOut(100);
						return false;
					},
					onChange : function(hsb, hex, rgb) {
						jQuery("#colorPicker_" + cId).css('backgroundColor',
								'#' + hex);
						jQuery("#colorPicker_" + cId).attr('name', '#' + hex);
						jQuery("#hexvalue_" + cId).val("#" + hex);
					}
				});
		jQuery("#backgroundColor_default_color_table_" + cId + " button").each(
				function(index, value) {
					jQuery(this).bind(
							'click',
							this,
							function(e) {
								apiObject.invokeAction('background-color',
										e.data.name);
								thiz._hideDialog();
								if (addedColors.length > 0) {
									apiObject.toolkitInternal
											._setUserPreferences({
												"colordialog" : addedColors
											});
								}
							});
				});
		jQuery("#backgroundColor_custom_color_table_" + cId + " button").each(
				function(index, value) {
					jQuery(this).bind(
							"click",
							this,
							function(e) {
								apiObject.invokeAction('background-color',
										e.data.name);
								thiz._hideDialog();
								if (addedColors.length > 0) {
									apiObject.toolkitInternal
											._setUserPreferences({
												"colordialog" : addedColors
											});
								}
								addedColors = [];
							});
				});
		jQuery("#colorSelectorSubmit_" + cId).bind("click", function() {
			color = jQuery("#colorPicker_" + cId).attr('name');
			apiObject.invokeAction('background-color', color);
			thiz._hideDialog();
			if (addedColors.length > 0) {
				apiObject.toolkitInternal._setUserPreferences({
					"colordialog" : addedColors
				});
			}
			addedColors = [];
		});
		jQuery("#colorSelectorAdd_" + cId).bind(
				"click",
				function() {
					color = jQuery("#colorPicker_" + cId).attr('name');
					colorObject = {
						"rgb" : color,
						"desc" : color
					};
					addedColors.push(colorObject);
					combinedColors.push(colorObject);
					jQuery("#backgroundColor_custom_color_table_" + cId).html(
							"");
					thiz._createColorSelectTable(combinedColors,
							"backgroundColor_custom_color_table_" + cId);
					if (addedColors.length > 0) {
						apiObject.toolkitInternal._setUserPreferences({
							"colordialog" : addedColors
						});
					}
					addedColors = [];
					jQuery(
							"#backgroundColor_custom_color_table_" + cId
									+ " button").each(
							function(index, value) {
								jQuery(this).bind(
										"click",
										this,
										function(e) {
											apiObject.invokeAction(
													'background-color',
													e.data.name);
											thiz._hideDialog();
										});
							});
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_REMOVE_COLOR")] = function() {
			thiz._hideDialog();
			apiObject.invokeAction('background-color', null);
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
		index = 0;
		if (apiObject.config.allowdefaultcolors !== undefined
				&& apiObject.config.allowdefaultcolors != "false") {
		} else {
			jQuery("#backgroundColor_default_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowpresetcolors !== undefined
				&& apiObject.config.allowpresetcolors != "false"
				&& apiObject.config.presetcolors !== undefined) {
		} else {
			jQuery("#backgroundColor_custom_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowfreecolors !== undefined
				&& apiObject.config.allowfreecolors != "false") {
		} else {
			jQuery("#colorPicker_" + cId).parents("td.ribbonPanel").remove();
		}
	};
	this.documentStatisticsDialog = function() {
		var html = this.dialogHTMLMap["documentStatistics"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_DOCUMENT_STATISTICS_DIALOG"));
		this._showDialog(html);
		jQuery("#no_characters_" + cId).html(
				apiObject.getNumberOfCharacters(false));
		jQuery("#no_characters_w_" + cId).html(
				apiObject.getNumberOfCharacters(true));
		jQuery("#no_words_" + cId).html(apiObject.getNumberOfWords());
		jQuery("#no_paragraphs_" + cId).html(apiObject.getNumberOfParagraphs());
		jQuery("#no_images_" + cId).html(apiObject.getNumberOfImages());
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.splitCellDialog = function() {
		var html = this.dialogHTMLMap["splitCell"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_SPLIT_CELL_DIALOG"));
		this._showDialog(html);
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_OK_BUTTON")] = function() {
			var rows = 1;
			var columns = 1;
			rows = jQuery("#split_cell_rows_" + cId).val();
			columns = jQuery("#split_cell_columns_" + cId).val();
			apiObject.invokeAction("split-cell", "['" + rows + "', '" + columns
					+ "']");
			thiz._hideDialog();
			splitAttr = {};
			splitAttr.rows = rows;
			splitAttr.cols = columns;
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.changeCaseDialog = function() {
		var html = this.dialogHTMLMap["changeCase"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_CHANGE_CASE_DIALOG"));
		this._showDialog(html);
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_OK_BUTTON")] = function() {
			var caseString = jQuery(
					"input:radio[name=changeCaseRadio_" + cId + "]:checked")
					.val();
			apiObject.invokeAction("change-case", "['" + caseString + "']");
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.tablePropertiesDialog = function() {
		var html = this.dialogHTMLMap["tableProperties"];
		var tableWidth = "";
		var tableWidthUnit = "";
		var tableAlignment = "";
		var tableVerticalAlignment = "";
		var cellPadding = "";
		var cellSpacing = "";
		var borderWidth = "";
		var tableBorderColor = "";
		var tableBGColor = "";
		var tableProperties = apiObject.toolkitInternal._getTableProperties();
		if (tableProperties !== "") {
			tableWidth = tableProperties["tableWidth"];
			tableWidthUnit = tableProperties["tableWidthUnit"];
			tableAlignment = tableProperties["tableAlignment"];
			tableVerticalAlignment = tableProperties["tableVerticalAlignment"];
			cellPadding = tableProperties["cellPadding"];
			cellSpacing = tableProperties["cellSpacing"];
			borderWidth = tableProperties["borderWidth"];
			tableBorderColor = tableProperties["tableBorderColor"];
			tableBGColor = tableProperties["tableBGColor"];
		}
		this._createDialog(apiObject.locale
				.getLocaleCode("L_TABLE_PROPERTIES_DIALOG"));
		this._showDialog(html);
		jQuery("#table_properties_border_width_" + cId).val(borderWidth);
		jQuery(
				"#table_properties_width_unit_" + cId + " option[value='"
						+ tableWidthUnit + "']").prop("selected", true);
		jQuery(
				"#table_properties_alignment_" + cId + " option[value='"
						+ tableAlignment + "']").prop("selected", true);
		jQuery(
				"#table_properties_vertical_alignment_" + cId
						+ " option[value='" + tableVerticalAlignment + "']")
				.prop("selected", true);
		jQuery("#table_properties_width_" + cId).val(tableWidth);
		jQuery("#table_properties_cell_padding_" + cId).val(cellPadding);
		jQuery("#table_properties_cell_spacing_" + cId).val(cellSpacing);
		jQuery("#tablePropertiesColorPicker_" + cId).attr("name", tableBGColor);
		jQuery("#tablePropertiesColorPicker_" + cId).css({
			"background-color" : tableBGColor
		});
		jQuery("#tablePropertiesBorderColorPicker_" + cId).attr("name",
				tableBorderColor);
		jQuery("#tablePropertiesBorderColorPicker_" + cId).css({
			"background-color" : tableBorderColor
		});
		this._createSpinner("#table_properties_cell_padding_" + cId, 0, 100);
		this._createSpinner("#table_properties_cell_spacing_" + cId, 0, 100);
		this._createSpinner("#table_properties_border_width_" + cId, 0, 100);
		jQuery("#tablePropertiesColorPicker_" + cId).bind(
				"click",
				function() {
					thiz.generalColorDialog("#tablePropertiesColorPicker_"
							+ cId, apiObject.locale
							.getLocaleCode("L_TABLE_BACKGROUND_COLOR"));
				});
		jQuery("#tablePropertiesBorderColorPicker_" + cId).bind(
				"click",
				function() {
					thiz.generalColorDialog(
							"#tablePropertiesBorderColorPicker_" + cId,
							apiObject.locale
									.getLocaleCode("L_TABLE_BORDERCOLOR"));
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var attributesNew = {};
			var tableWidth = jQuery("#table_properties_width_" + cId).val();
			var tableWidthUnit = jQuery("#table_properties_width_unit_" + cId)
					.val();
			var tableBorderWidth = jQuery(
					"#table_properties_border_width_" + cId).val();
			var tableAlignment = jQuery("#table_properties_alignment_" + cId)
					.val();
			var tableVerticalAlignment = jQuery(
					"#table_properties_vertical_alignment_" + cId).val();
			var cellPadding = jQuery("#table_properties_cell_padding_" + cId)
					.val();
			var cellSpacing = jQuery("#table_properties_cell_spacing_" + cId)
					.val();
			var tableBGColor = jQuery("#tablePropertiesColorPicker_" + cId)
					.attr("name");
			var tableBorderColor = jQuery(
					"#tablePropertiesBorderColorPicker_" + cId).attr("name");
			if (tableWidthUnit === "percent") {
				tableWidthUnit = "%";
			} else {
				tableWidthUnit = "px";
			}
			if (tableWidth !== "" || tableWidth !== undefined) {
				attributesNew.tableWidth = tableWidth;
				attributesNew.tableWidthUnit = tableWidthUnit;
			} else {
				attributesNew.tableWidth = null;
				attributesNew.tableWidthUnit = tableWidthUnit;
			}
			if (tableBorderWidth !== "" || tableBorderWidth !== undefined) {
				attributesNew.borderWidth = tableBorderWidth;
				attributesNew.borderWidthUnit = "px";
			} else {
				attributesNew.borderWidth = null;
				attributesNew.borderWidthUnit = "px";
			}
			if (tableAlignment !== "default") {
				attributesNew.tableAlignment = tableAlignment;
			} else {
				attributesNew.tableAlignment = null;
			}
			if (tableVerticalAlignment !== "default") {
				attributesNew.tableVerticalAlignment = tableVerticalAlignment;
			} else {
				attributesNew.tableVerticalAlignment = null;
			}
			if (cellPadding !== "") {
				attributesNew.cellPadding = cellPadding;
				attributesNew.cellPaddingUnit = "px";
			} else {
				cellPadding = null;
			}
			if (cellSpacing !== "") {
				attributesNew.cellSpacing = cellSpacing;
				attributesNew.cellSpacingUnit = "px";
			} else {
				attributesNew.cellSpacing = null;
			}
			if (tableBGColor !== "" && tableBGColor !== "none") {
				attributesNew.tableBGColor = tableBGColor;
			} else {
				attributesNew.tableBGColor = null;
			}
			if (tableBorderColor !== "" && tableBorderColor !== "none") {
				attributesNew.tableBorderColor = tableBorderColor;
			} else {
				attributesNew.tableBorderColor = null;
			}
			apiObject.invokeAction("table-properties", jQuery
					.toJSON(attributesNew));
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.rowPropertiesDialog = function() {
		var html = this.dialogHTMLMap["rowProperties"];
		var rowProperties = apiObject.toolkitInternal._getRowProperties();
		if (rowProperties !== "") {
			this._createDialog(apiObject.locale
					.getLocaleCode("L_ROW_PROPERTIES_DIALOG"));
			this._showDialog(html);
			var rowHeight = rowProperties["height"];
			var rowHeightUnit = rowProperties["heightUnit"];
			var rowValign = rowProperties["valign"];
			var rowAlign = rowProperties["align"];
			var rowBGColor = rowProperties["bgcolor"];
			jQuery("#rowproperties_row_height_" + cId).val(rowHeight);
			jQuery(
					"#rowproperties_row_height_unit_" + cId + " option[value='"
							+ rowHeightUnit + "']").prop("selected", true);
			jQuery(
					"#rowproperties_vertical_alignment_" + cId
							+ " option[value='" + rowValign + "']").prop(
					"selected", true);
			jQuery(
					"#rowproperties_alignment_" + cId + " option[value='"
							+ rowAlign + "']").prop("selected", true);
			jQuery("#rowColorPicker_" + cId).attr("name", rowBGColor);
			jQuery("#rowColorPicker_" + cId).css({
				"background-color" : rowBGColor
			});
			jQuery("#rowColorPicker_" + cId)
					.bind(
							"click",
							function() {
								thiz
										.generalColorDialog(
												"#rowColorPicker_" + cId,
												apiObject.locale
														.getLocaleCode("L_ROW_BACKGROUND_COLOR"));
							});
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
				var attributesNew = {};
				rowHeight = jQuery("#rowproperties_row_height_" + cId).val();
				rowHeightUnit = jQuery("#rowproperties_row_height_unit_" + cId)
						.val();
				rowValign = jQuery("#rowproperties_vertical_alignment_" + cId)
						.val();
				rowAlign = jQuery("#rowproperties_alignment_" + cId).val();
				rowBGColor = jQuery("#rowColorPicker_" + cId).attr("name");
				if (rowHeightUnit == "percent") {
					rowHeightUnit = "%";
				}
				if (rowHeight !== undefined && rowHeight !== "") {
					attributesNew.height = rowHeight;
					attributesNew.heightUnit = rowHeightUnit;
				} else {
					attributesNew.height = null;
					attributesNew.heightUnit = rowHeightUnit;
				}
				if (rowBGColor !== undefined && rowBGColor !== ""
						&& rowBGColor !== "none") {
					attributesNew.bgcolor = rowBGColor;
				} else {
					attributesNew.bgcolor = null;
				}
				if (rowValign !== undefined && rowValign !== ""
						&& rowValign !== "default") {
					attributesNew.valign = rowValign;
				} else {
					attributesNew.valign = null;
				}
				if (rowAlign !== undefined && rowAlign !== ""
						&& rowAlign !== "default") {
					attributesNew.align = rowAlign;
				} else {
					attributesNew.align = null;
				}
				apiObject.invokeAction("row-properties", jQuery
						.toJSON(attributesNew));
				thiz._hideDialog();
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._dialogCreateTabs();
		}
	};
	this.columnPropertiesDialog = function() {
		var html = this.dialogHTMLMap["columnProperties"];
		var columnProperties = apiObject.toolkitInternal._getColumnProperties();
		if (columnProperties !== "") {
			this._createDialog(apiObject.locale
					.getLocaleCode("L_COLUMN_PROPERTIES_DIALOG"));
			this._showDialog(html);
			var columnWidth = columnProperties["width"];
			var columnWidthUnit = columnProperties["widthUnit"];
			var columnValign = columnProperties["valign"];
			var columnAlign = columnProperties["align"];
			var columnBGColor = columnProperties["bgcolor"];
			jQuery("#columnproperties_column_width_" + cId).val(columnWidth);
			jQuery(
					"#columnproperties_column_width_unit_" + cId
							+ " option[value='" + columnWidthUnit + "']").prop(
					"selected", true);
			jQuery(
					"#columnproperties_vertical_alignment_" + cId
							+ " option[value='" + columnValign + "']").prop(
					"selected", true);
			jQuery(
					"#columnproperties_alignment_" + cId + " option[value='"
							+ columnAlign + "']").prop("selected", true);
			jQuery("#columnColorPicker_" + cId).attr("name", columnBGColor);
			jQuery("#columnColorPicker_" + cId).css({
				"background-color" : columnBGColor
			});
			jQuery("#columnColorPicker_" + cId)
					.bind(
							"click",
							function() {
								thiz
										.generalColorDialog(
												"#columnColorPicker_" + cId,
												apiObject.locale
														.getLocaleCode("L_COLUMN_BACKGROUND_COLOR"));
							});
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
				var attributesNew = {};
				columnWidth = jQuery("#columnproperties_column_width_" + cId)
						.val();
				columnWidthUnit = jQuery(
						"#columnproperties_column_width_unit_" + cId).val();
				columnAlign = jQuery("#columnproperties_alignment_" + cId)
						.val();
				columnValign = jQuery(
						"#columnproperties_vertical_alignment_" + cId).val();
				columnBGColor = jQuery("#columnColorPicker_" + cId)
						.attr("name");
				if (columnWidthUnit === "percent") {
					columnWidthUnit = "%";
				}
				if (columnWidth !== undefined && columnWidth !== "") {
					attributesNew.width = columnWidth;
					attributesNew.widthUnit = columnWidthUnit;
				} else {
					attributesNew.width = null;
					attributesNew.widthUnit = columnWidthUnit;
				}
				if (columnAlign !== undefined && columnAlign !== ""
						&& columnAlign !== "default") {
					attributesNew.align = columnAlign;
				} else {
					attributesNew.align = null;
				}
				if (columnValign !== undefined && columnValign !== ""
						&& columnValign !== "default") {
					attributesNew.valign = columnValign;
				} else {
					attributesNew.valign = null;
				}
				if (columnBGColor !== undefined && columnBGColor !== ""
						&& columnBGColor !== "none") {
					attributesNew.bgcolor = columnBGColor;
				} else {
					attributesNew.bgcolor = null;
				}
				apiObject.invokeAction("column-properties", jQuery
						.toJSON(attributesNew));
				thiz._hideDialog();
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._dialogCreateTabs();
		}
	};
	this.cellPropertiesDialog = function() {
		var html = this.dialogHTMLMap["cellProperties"];
		var cellWidth = "";
		var cellHeight = "";
		var cellValign = "";
		var cellAlign = "";
		var cellBGColor = "";
		var cellWidthUnit = "";
		var cellHeightUnit = "";
		var cellProperties = apiObject.toolkitInternal._getCellProperties();
		if (cellProperties !== "") {
			cellWidth = cellProperties["width"];
			cellHeight = cellProperties["height"];
			cellValign = cellProperties["valign"];
			cellAlign = cellProperties["align"];
			cellBGColor = cellProperties["bgcolor"];
			cellWidthUnit = cellProperties["widthUnit"];
			cellHeightUnit = cellProperties["heightUnit"];
		}
		this._createDialog(apiObject.locale
				.getLocaleCode("L_CELL_PROPERTIES_DIALOG"));
		this._showDialog(html);
		jQuery("#cellproperties_width_" + cId).val(cellWidth);
		jQuery(
				"#cellproperties_width_unit_" + cId + " option[value='"
						+ cellWidthUnit + "']").prop("selected", true);
		jQuery("#cellproperties_height_" + cId).val(cellHeight);
		jQuery(
				"#cellproperties_height_unit_" + cId + " option[value='"
						+ cellHeightUnit + "']").prop("selected", true);
		jQuery(
				"#cellproperties_vertical_alignment_" + cId + " option[value='"
						+ cellValign + "']").prop("selected", true);
		jQuery(
				"#cellproperties_alignment_" + cId + " option[value='"
						+ cellAlign + "']").prop("selected", true);
		jQuery("#cellColorPicker_" + cId).attr("name", cellBGColor);
		jQuery("#cellColorPicker_" + cId).css({
			"background-color" : cellBGColor
		});
		jQuery("#cellColorPicker_" + cId).bind(
				"click",
				function() {
					thiz.generalColorDialog("#cellColorPicker_" + cId,
							apiObject.locale
									.getLocaleCode("L_CELL_BACKGROUND_COLOR"));
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var attributesNew = {};
			cellWidth = jQuery("#cellproperties_width_" + cId).val();
			cellWidthUnit = jQuery("#cellproperties_width_unit_" + cId).val();
			cellHeight = jQuery("#cellproperties_height_" + cId).val();
			cellHeightUnit = jQuery("#cellproperties_height_unit_" + cId).val();
			cellValign = jQuery("#cellproperties_vertical_alignment_" + cId)
					.val();
			cellAlign = jQuery("#cellproperties_alignment_" + cId).val();
			cellBGColor = jQuery("#cellColorPicker_" + cId).attr("name");
			if (cellHeightUnit === "percent") {
				cellHeightUnit = "%";
			}
			if (cellWidthUnit === "percent") {
				cellWidthUnit = "%";
			}
			if (cellWidth !== undefined && cellWidth !== "") {
				attributesNew.width = cellWidth;
				attributesNew.widthUnit = cellWidthUnit;
			} else {
				attributesNew.width = null;
				attributesNew.widthUnit = cellWidthUnit;
			}
			if (cellHeight !== undefined && cellHeight !== "") {
				attributesNew.height = cellHeight;
				attributesNew.heightUnit = cellHeightUnit;
			} else {
				attributesNew.height = null;
				attributesNew.heightUnit = cellHeightUnit;
			}
			if (cellValign !== undefined && cellValign !== ""
					&& cellValign !== "default") {
				attributesNew.valign = cellValign;
			} else {
				attributesNew.valign = null;
			}
			if (cellAlign !== undefined && cellAlign !== ""
					&& cellAlign !== "default") {
				attributesNew.align = cellAlign;
			} else {
				attributesNew.align = null;
			}
			if (cellBGColor !== undefined && cellBGColor !== ""
					&& cellBGColor !== "none") {
				attributesNew.bgcolor = cellBGColor;
			} else {
				attributesNew.bgcolor = null;
			}
			apiObject.invokeAction("cell-properties", jQuery
					.toJSON(attributesNew));
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.insertAnnotationDialog = function() {
		var html = this.dialogHTMLMap["insertAnnotation"];
		apiObject.toolkitInternal._initializeInsertAnnotationHelper();
		var annotationProperties = apiObject.toolkitInternal
				._getInsertAnnotationProperties();
		var strAuthor = "";
		var strUid = "";
		var strDate = "";
		if (annotationProperties !== "") {
			strAuthor = annotationProperties["author"];
			strUid = annotationProperties["uid"];
			strDate = annotationProperties["date"];
		}
		this._createDialog(apiObject.locale
				.getLocaleCode("L_INSERT_ANNOTATION_DIALOG"));
		this._showDialog(html);
		jQuery("#annotation_time_" + cId).html(strDate);
		jQuery("#annotation_author_" + cId).html(strAuthor);
		jQuery("#annotation_uid_" + cId).html(strUid);
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
			var annotationText = jQuery("#annotation_text_" + cId).val();
			if (annotationText !== "" && annotationText !== undefined) {
				apiObject.invokeAction("insert-annotation", annotationText);
				thiz._hideDialog();
			} else {
			}
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.editAnnotationDialog = function() {
		var html = this.dialogHTMLMap["editAnnotation"];
		apiObject.toolkitInternal._initializeEditAnnotationHelper();
		var uid = "";
		var author = "";
		var date = "";
		var text = "";
		var enabled = false;
		var annotationProperties = apiObject.toolkitInternal
				._getEditAnnotationProperties();
		if (annotationProperties !== "") {
			uid = annotationProperties["uid"];
			author = annotationProperties["author"];
			date = annotationProperties["date"];
			text = htmlEncode(annotationProperties["text"]);
			enabled = annotationProperties["enabled"];
		}
		this._createDialog(apiObject.locale
				.getLocaleCode("L_EDIT_ANNOTATION_DIALOG"));
		this._showDialog(html);
		jQuery("#annotation_time_" + cId).html(date);
		jQuery("#annotation_author_" + cId).html(author);
		jQuery("#annotation_uid_" + cId).html(uid);
		jQuery("#annotation_text_" + cId).html(text);
		if (!enabled) {
			jQuery("#annotation_time_" + cId).attr('disabled', true);
			jQuery("#annotation_author_" + cId).attr('disabled', true);
			jQuery("#annotation_uid_" + cId).attr('disabled', true);
			jQuery("#annotation_text_" + cId).attr('disabled', true);
			jQuery("#notAllowed_" + cId).show();
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		if (enabled) {
			jQuery("#notAllowed_" + cId).hide();
			buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
				var annotationText = jQuery("#annotation_text_" + cId).val();
				if (annotationText !== "" && annotationText !== undefined) {
					apiObject.invokeAction("edit-annotation", annotationText);
					thiz._hideDialog();
				} else {
				}
			};
		}
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.horizontalLinePropertiesDialog = function() {
		var html = this.dialogHTMLMap["hrProperties"];
		if (/^<hr.*/.test(apiObject.getCurrentElement())) {
			this._createDialog(apiObject.locale
					.getLocaleCode("L_HORIZONTAL_LINE_PROPERTIES_DIALOG"));
			this._showDialog(html);
			var size = "";
			var width = "";
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
				var attributesNew = {};
				width = jQuery("#hrproperties_width_" + cId).val();
				widthUnit = jQuery("#hrproperties_width_unit_" + cId).val();
				size = jQuery("#hrproperties_size_" + cId).val();
				if (widthUnit === "percent") {
					widthUnit = "%";
				}
				if (width !== undefined && width !== "") {
					attributesNew.hrWidth = width;
					attributesNew.hrWidthUnit = widthUnit;
				}
				if (size !== undefined && size !== "") {
					attributesNew.hrHeight = size;
					attributesNew.hrHeightUnit = "px";
				}
				apiObject.invokeAction("horizontal-line-properties", jQuery
						.toJSON(attributesNew));
				thiz._hideDialog();
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._dialogCreateTabs();
		}
	};
	this.insertObjectDialog = function() {
		var currentElement = apiObject.getCurrentElement();
		if (/^<object.*/.test(currentElement)) {
			this.objectPropertiesDialog();
		} else {
			var html = this.dialogHTMLMap["insertObject"];
			this._createDialog(apiObject.locale
					.getLocaleCode("L_INSERT_OBJECT_DIALOG"));
			this._showDialog(html);
			this._bindOpenFileDialog("#object_open_file_button_" + cId,
					"#object_url_field_" + cId, "object");
			this._bindOpenWebdavDialog("#object_open_webdav_button_" + cId,
					"#object_url_field_" + cId, "get-webdav-object");
			if (!apiObject.isActionEnabled("get-webdav-object")) {
				jQuery("#object_open_webdav_button_" + cId).hide();
			}
			var paramObject = {};
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
				var objectSource = jQuery("#object_url_field_" + cId).val();
				var objectType = jQuery("#object_type_" + cId).val();
				var objectName = jQuery("#object_name_" + cId).val();
				var objectClass = jQuery("#object_class_" + cId).val();
				var objectAlignment = jQuery("#object_alignment_" + cId).val();
				var objectWidth = jQuery("#object_width_" + cId).val();
				var objectHeight = jQuery("#object_height_" + cId).val();
				var objectAltHTML = jQuery("#object_althtml_" + cId).val();
				var objectCodeBase = jQuery("#object_codebase_" + cId).val();
				var paramJson = {};
				jQuery("#object_parameter_container_" + cId + " tr")
						.each(
								function() {
									var paramName = jQuery(this).children("td")
											.children("input.paramName").val();
									var paramValue = jQuery(this)
											.children("td").children(
													"input.paramValue").val();
									if (paramName !== undefined
											&& paramName !== null
											&& paramName !== ""
											&& paramValue !== undefined
											&& paramValue !== null
											&& paramValue !== "") {
										paramJson[paramName] = paramValue;
									}
								});
				var objAttr = {};
				objAttr.objectParams = paramJson;
				if (objectSource !== undefined && objectSource !== null
						&& objectSource !== "") {
					objAttr.objectData = objectSource;
					if (objectType !== undefined && objectType !== null
							&& objectType !== "") {
						objAttr.objectType = objectType;
					} else {
						objAttr.objectType = null;
					}
					if (objectName !== undefined && objectName !== null
							&& objectName !== "") {
						objAttr.objectName = objectName;
					} else {
						objAttr.objectName = null;
					}
					if (objectClass !== undefined && objectClass !== null
							&& objectClass !== "") {
						objAttr.objectClass = objectClass;
					} else {
						objAttr.objectClass = objectClass;
					}
					if (objectAlignment !== undefined
							&& objectAlignment !== null
							&& objectAlignment !== "") {
						objAttr.objectAlignment = objectAlignment;
					} else {
						objAttr.objectAlignment = null;
					}
					if (objectWidth !== undefined && objectWidth !== null
							&& objectWidth !== "") {
						objAttr.objectWidth = objectWidth;
						objAttr.objectWidthUnit = "px";
					} else {
						objAttr.objectWidth = null;
						objAttr.objectWidthUnit = "px";
					}
					if (objectHeight !== undefined && objectHeight !== null
							&& objectHeight !== "") {
						objAttr.objectHeight = objectHeight;
						objAttr.objectHeightUnit = "px";
					} else {
						objAttr.objectHeight = null;
						objAttr.objectHeightUnit = "px";
					}
					if (objectCodeBase !== undefined && objectCodeBase !== null
							&& objectCodeBase !== "") {
						objAttr.objectCodeBase = objectCodeBase;
					} else {
						objAttr.objectCodeBase = null;
					}
					if (objectAltHTML !== undefined && objectAltHTML !== null
							&& jQuery.trim(objectAltHTML) !== "") {
						objAttr.objectAlt = objectAltHTML;
					} else {
						objAttr.objectAlt = "";
					}
					apiObject.invokeAction("insert-object", jQuery
							.toJSON(objAttr));
					thiz._hideDialog();
				} else {
				}
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._createParameterWidget("#object_parameter_container_" + cId,
					paramObject);
			this._dialogCreateTabs();
		}
	};
	this.objectPropertiesDialog = function() {
		var properties = apiObject.toolkitInternal._getObjectProperties();
		if (properties == null || properties == undefined || properties == "") {
			return;
		}
		var html = this.dialogHTMLMap["objectProperties"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_OBJECT_PROPERTIES_DIALOG"));
		this._showDialog(html);
		this._bindOpenFileDialog("#object_open_file_button_" + cId,
				"#object_url_field_" + cId, "object");
		this._bindOpenWebdavDialog("#object_open_webdav_button_" + cId,
				"#object_url_field_" + cId, "get-webdav-object");
		if (!apiObject.isActionEnabled("get-webdav-object")) {
			jQuery("#object_open_webdav_button_" + cId).hide();
		}
		var objectSource = properties["objectData"];
		var objectType = properties["objectType"];
		var objectName = properties["objectName"];
		var objectClass = properties["objectClass"];
		var objectAlt = properties["objectAlt"];
		var objectParams = properties["objectParams"];
		var objectAlignment = properties["objectAlignment"];
		var objectWidth = properties["objectWidth"];
		var objectHeight = properties["objectHeight"];
		var objectCodeBase = properties["objectCodeBase"];
		if (objectSource !== undefined && objectSource !== null
				&& objectSource !== "") {
			jQuery("#object_url_field_" + cId).val(objectSource);
		}
		if (objectType !== undefined && objectType !== null
				&& objectType !== "") {
			jQuery(
					"#object_type_" + cId + " option[value='" + objectType
							+ "']").prop("selected", true);
		}
		if (objectName !== undefined && objectName !== null
				&& objectName !== "") {
			jQuery("#object_name_" + cId).val(objectName);
		}
		if (objectClass !== undefined && objectClass !== null
				&& objectClass !== "") {
			jQuery("#object_class_" + cId).val(objectClass);
		}
		if (objectAlt !== undefined && objectAlt !== null && objectAlt !== "") {
			jQuery("#object_althtml_" + cId).val(objectAlt);
		}
		if (objectAlignment !== undefined && objectAlignment !== null
				&& objectAlignment !== "") {
			jQuery(
					"#object_alignment_" + cId + " option[value='"
							+ objectAlignment + "']").prop("selected", true);
		}
		if (objectWidth !== undefined && objectWidth !== null
				&& objectWidth !== "") {
			jQuery("#object_width_" + cId).val(objectWidth);
		}
		if (objectHeight !== undefined && objectHeight !== null
				&& objectHeight !== "") {
			jQuery("#object_height_" + cId).val(objectHeight);
		}
		if (objectCodeBase !== undefined && objectCodeBase !== null
				&& objectCodeBase !== "") {
			jQuery("#object_codebase_" + cId).val(objectCodeBase);
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			objectSource = jQuery("#object_url_field_" + cId).val();
			objectType = jQuery("#object_type_" + cId).val();
			objectName = jQuery("#object_name_" + cId).val();
			objectClass = jQuery("#object_class_" + cId).val();
			objectAlignment = jQuery("#object_alignment_" + cId).val();
			objectWidth = jQuery("#object_width_" + cId).val();
			objectHeight = jQuery("#object_height_" + cId).val();
			objectAltHTML = jQuery("#object_althtml_" + cId).val();
			objectCodeBase = jQuery("#object_codebase_" + cId).val();
			var paramJson = {};
			jQuery("#object_parameter_container_" + cId + " tr").each(
					function() {
						var paramName = jQuery(this).children("td").children(
								"input.paramName").val();
						var paramValue = jQuery(this).children("td").children(
								"input.paramValue").val();
						if (paramName !== undefined && paramName !== null
								&& paramName !== "" && paramValue !== undefined
								&& paramValue !== null && paramValue !== "") {
							paramJson[paramName] = paramValue;
						}
					});
			var objAttr = {};
			objAttr.objectParams = paramJson;
			if (objectSource !== undefined && objectSource !== null
					&& objectSource !== "") {
				objAttr.objectData = objectSource;
				if (objectType !== undefined && objectType !== null
						&& objectType !== "") {
					objAttr.objectType = objectType;
				} else {
					objAttr.objectType = null;
				}
				if (objectName !== undefined && objectName !== null
						&& objectName !== "") {
					objAttr.objectName = objectName;
				} else {
					objAttr.objectName = null;
				}
				if (objectClass !== undefined && objectClass !== null
						&& objectClass !== "") {
					objAttr.objectClass = objectClass;
				} else {
					objAttr.objectClass = null;
				}
				if (objectAlignment !== undefined && objectAlignment !== null
						&& objectAlignment !== "") {
					objAttr.objectAlignment = objectAlignment;
				} else {
					objAttr.objectAlignment = null;
				}
				if (objectWidth !== undefined && objectWidth !== null
						&& objectWidth !== "") {
					objAttr.objectWidth = objectWidth;
					objAttr.objectWidthUnit = "px";
				} else {
					objAttr.objectWidth = null;
					objAttr.objectWidthUnit = "px";
				}
				if (objectHeight !== undefined && objectHeight !== null
						&& objectHeight !== "") {
					objAttr.objectHeight = objectHeight;
					objAttr.objectHeightUnit = "px";
				} else {
					objAttr.objectHeight = null;
					objAttr.objectHeightUnit = "px";
				}
				if (objectCodeBase !== undefined && objectCodeBase !== null
						&& objectCodeBase !== "") {
					objAttr.objectCodeBase = objectCodeBase;
				} else {
					objAttr.objectCodeBase = null;
				}
				if (objectAltHTML !== undefined && objectAltHTML !== null
						&& objectAltHTML !== "") {
					objAttr.objectAlt = objectAltHTML;
				} else {
					objAttr.objectAlt = "";
				}
				apiObject.invokeAction("object-properties", jQuery
						.toJSON(objAttr));
				thiz._hideDialog();
			} else {
			}
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._createParameterWidget("#object_parameter_container_" + cId,
				objectParams);
		this._dialogCreateTabs();
	};
	this.generalColorDialog = function(updateElement, title) {
		var html = this.dialogHTMLMap["generalColor"];
		this._createDialog(title, "modalDialog2_", false);
		this._showDialog(html, "modalDialog2_", false);
		this._createColorSelectTable(this._defaultColors,
				"generalColor_default_color_table_" + cId);
		var combinedColors = [];
		var addedColors = [];
		if (apiObject.config.presetcolors !== undefined) {
			for (var i = 0; i < apiObject.config.presetcolors.color.length; i++) {
				combinedColors.push(apiObject.config.presetcolors.color[i]);
			}
		}
		var upcolors = apiObject.toolkitInternal
				._getUserPreferences("colordialog");
		if (upcolors !== null) {
			for (i = 0; i < upcolors.length; i++) {
				combinedColors.push(upcolors[i]);
			}
		}
		this._createColorSelectTable(combinedColors,
				"generalColor_custom_color_table_" + cId);
		jQuery("#colorPicker_" + cId).ColorPicker(
				{
					color : '#0000ff',
					onShow : function(colpkr) {
						jQuery(colpkr).fadeIn(100);
						return false;
					},
					onHide : function(colpkr) {
						jQuery(colpkr).fadeOut(100);
						return false;
					},
					onChange : function(hsb, hex, rgb) {
						jQuery("#colorPicker_" + cId).css('backgroundColor',
								'#' + hex);
						jQuery("#colorPicker_" + cId).attr('name', '#' + hex);
						jQuery("#hexvalue_" + cId).val("#" + hex);
					}
				});
		jQuery("#generalColor_default_color_table_" + cId + " button")
				.each(
						function(index, value) {
							jQuery(this)
									.bind(
											'click',
											this,
											function(e) {
												jQuery(updateElement).css(
														"backgroundColor",
														e.data.name);
												jQuery(updateElement).attr(
														"name", e.data.name);
												thiz._hideDialog(
														"modalDialog2_", false);
												if (addedColors.length > 0) {
													apiObject.toolkitInternal
															._setUserPreferences({
																"colordialog" : addedColors
															});
												}
												addedColors = [];
											});
						});
		jQuery("#generalColor_custom_color_table_" + cId + " button")
				.each(
						function(index, value) {
							jQuery(this)
									.bind(
											"click",
											this,
											function(e) {
												jQuery(updateElement).css(
														"backgroundColor",
														e.data.name);
												jQuery(updateElement).attr(
														"name", e.data.name);
												thiz._hideDialog(
														"modalDialog2_", false);
												if (addedColors.length > 0) {
													apiObject.toolkitInternal
															._setUserPreferences({
																"colordialog" : addedColors
															});
												}
												addedColors = [];
											});
						});
		jQuery("#colorSelectorSubmit_" + cId).bind("click", function() {
			color = jQuery("#colorPicker_" + cId).attr('name');
			jQuery(updateElement).css("backgroundColor", color);
			jQuery(updateElement).attr("name", color);
			thiz._hideDialog("modalDialog2_", false);
			if (addedColors.length > 0) {
				apiObject.toolkitInternal._setUserPreferences({
					"colordialog" : addedColors
				});
			}
			addedColors = [];
		});
		jQuery("#colorSelectorAdd_" + cId).bind(
				"click",
				function() {
					color = jQuery("#colorPicker_" + cId).attr('name');
					colorObject = {
						"rgb" : color,
						"desc" : color
					};
					addedColors.push(colorObject);
					combinedColors.push(colorObject);
					jQuery("#generalColor_custom_color_table_" + cId).html("");
					thiz._createColorSelectTable(combinedColors,
							"generalColor_custom_color_table_" + cId);
					if (addedColors.length > 0) {
						apiObject.toolkitInternal._setUserPreferences({
							"colordialog" : addedColors
						});
					}
					addedColors = [];
					jQuery(
							"#generalColor_custom_color_table_" + cId
									+ " button").each(
							function(index, value) {
								jQuery(this).bind(
										"click",
										this,
										function(e) {
											jQuery(updateElement).css(
													"backgroundColor",
													e.data.name);
											jQuery(updateElement).attr("name",
													e.data.name);
											thiz._hideDialog("modalDialog2_",
													false);
										});
							});
				});
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog("modalDialog2_", false);
		};
		buttons[apiObject.locale.getLocaleCode("L_REMOVE_COLOR")] = function() {
			thiz._hideDialog("modalDialog2_", false);
			jQuery(updateElement).css("backgroundColor", "");
			jQuery(updateElement).attr("name", "none");
		};
		jQuery("#modalDialog2_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs("modalDialog2_");
		index = 0;
		if (apiObject.config.allowdefaultcolors !== undefined
				&& apiObject.config.allowdefaultcolors != "false") {
		} else {
			jQuery("#generalColor_default_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowpresetcolors !== undefined
				&& apiObject.config.allowpresetcolors != "false") {
		} else {
			jQuery("#generalColor_custom_color_table_" + cId).parents(
					"td.ribbonPanel").remove();
		}
		if (apiObject.config.allowfreecolors !== undefined
				&& apiObject.config.allowfreecolors != "false") {
		} else {
			jQuery("#colorPicker_" + cId).parents("td.ribbonPanel").remove();
		}
	};
	this.changeLanguageDialog = function() {
		var html = this.dialogHTMLMap["changeLanguage"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_CHANGE_LANGUAGE_DIALOG"));
		this._showDialog(html);
		var langNames = apiObject.toolkitInternal._getLanguageNames();
		var langCodes = apiObject.toolkitInternal._getLanguageCodes();
		var fragmentLang = apiObject.getFragmentLanguage();
		var documentLang = apiObject.getDocumentLanguage();
		for (var i = 0; i < langNames.length; i++) {
			if (langCodes[i] === fragmentLang) {
				jQuery("#selectFragmentLanguage_" + cId).append(
						"<option value=\"" + langCodes[i]
								+ "\" selected=\"selected\">" + langNames[i]
								+ "</option>");
			} else {
				jQuery("#selectFragmentLanguage_" + cId).append(
						"<option value=\"" + langCodes[i] + "\">"
								+ langNames[i] + "</option>");
			}
			if (langCodes[i] == documentLang) {
				jQuery("#selectDocumentLanguage_" + cId).append(
						"<option value=\"" + langCodes[i]
								+ "\" selected=\"selected\">" + langNames[i]
								+ "</option>");
			} else {
				jQuery("#selectDocumentLanguage_" + cId).append(
						"<option value=\"" + langCodes[i] + "\">"
								+ langNames[i] + "</option>");
			}
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CLOSE_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var fragmentCode = jQuery("#selectFragmentLanguage_" + cId).val();
			var documentCode = jQuery("#selectDocumentLanguage_" + cId).val();
			if (fragmentCode !== fragmentLang) {
				apiObject.invokeAction("live-fragment-language", fragmentCode);
			}
			if (documentCode !== documentLang) {
				apiObject.invokeAction("document-language", documentCode);
			}
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.documentPropertiesDialog = function() {
		var html = this.dialogHTMLMap["documentProperties"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_DOCUMENT_PROPERTIES_DIALOG"));
		this._showDialog(html);
		var documentProperties = apiObject.toolkitInternal
				._getDocumentProperties();
		if (documentProperties !== undefined) {
			if (documentProperties.title !== undefined
					&& documentProperties.title !== "") {
				jQuery("#documentproperties_title_field_" + cId).val(
						documentProperties.title);
			}
			if (documentProperties.base !== undefined
					&& documentProperties.base !== "") {
				jQuery("#documentproperties_base_field_" + cId).val(
						documentProperties.base);
			}
			if (documentProperties.color !== undefined
					&& documentProperties.color !== "") {
				jQuery("#documentproperties_text_color_" + cId).css({
					"background-color" : documentProperties.color
				});
				jQuery("#documentproperties_text_color_" + cId).attr("name",
						documentProperties.color);
			}
			if (documentProperties.bgcolor !== undefined
					&& documentProperties.bgcolor !== "") {
				jQuery("#documentproperties_background_color_" + cId).css({
					"background-color" : documentProperties.bgcolor
				});
				jQuery("#documentproperties_background_color_" + cId).attr(
						"name", documentProperties.bgcolor);
			}
			if (documentProperties.bgimage !== undefined
					&& documentProperties.bgimage !== "") {
				documentProperties.bgimage = documentProperties.bgimage
						.replace(/url\(/g, "");
				documentProperties.bgimage = documentProperties.bgimage
						.replace(/\)/g, "");
				jQuery("#background_image_field_" + cId).val(
						documentProperties.bgimage);
			}
		}
		jQuery("#documentproperties_text_color_" + cId)
				.bind(
						"click",
						function() {
							thiz
									.generalColorDialog(
											"#documentproperties_text_color_"
													+ cId,
											apiObject.locale
													.getLocaleCode("L_DOCUMENT_PROPERTIES_TEXT_COLOR"));
						});
		jQuery("#documentproperties_background_color_" + cId)
				.bind(
						"click",
						function() {
							thiz
									.generalColorDialog(
											"#documentproperties_background_color_"
													+ cId,
											apiObject.locale
													.getLocaleCode("L_DOCUMENT_PROPERTIES_BACKGROUND_COLOR"));
						});
		this._bindOpenFileDialog("#background_image_open_file_button_" + cId,
				"#background_image_field_" + cId, "image");
		this._bindOpenWebdavDialog("#background_image_open_webdav_button_"
				+ cId, "#background_image_field_" + cId, "get-webdav-image");
		if (!apiObject.isActionEnabled("get-webdav-image")) {
			jQuery("#background_image_open_webdav_button_" + cId).hide();
		}
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var documentProperties = {};
			var title = jQuery("#documentproperties_title_field_" + cId).val();
			var base = jQuery("#documentproperties_base_field_" + cId).val();
			var textColor = jQuery("#documentproperties_text_color_" + cId)
					.attr("name");
			var backgroundColor = jQuery(
					"#documentproperties_background_color_" + cId).attr("name");
			var backgroundImage = jQuery("#background_image_field_" + cId)
					.val();
			if (title !== undefined && title !== "") {
				documentProperties.title = title;
			}
			if (base !== undefined && base !== "") {
				documentProperties.base = base;
			}
			if (textColor !== undefined && textColor !== "") {
				if (textColor === "none") {
					documentProperties.color = null;
				} else {
					documentProperties.color = textColor;
				}
			}
			if (backgroundColor !== undefined && backgroundColor !== "") {
				if (backgroundColor === "none") {
					documentProperties.bgcolor = null;
				} else {
					documentProperties.bgcolor = backgroundColor;
				}
			}
			if (backgroundImage !== undefined && backgroundImage !== "") {
				documentProperties.bgimage = backgroundImage;
			}
			apiObject.toolkitInternal._setDocumentProperties(jQuery
					.toJSON(documentProperties));
			thiz._hideDialog();
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this.insertImageDialog = function() {
		currentElement = apiObject.getCurrentElement();
		if (/^<img.*/.test(currentElement)) {
			this.imagePropertiesDialog();
		} else {
			var html = this.dialogHTMLMap["insertImage"];
			this._createDialog(apiObject.locale
					.getLocaleCode("L_INSERT_IMAGE_DIALOG"));
			this._showDialog(html);
			this._createSpinner("#image_border_width_" + cId, 0, 100);
			this._bindOpenFileDialog("#image_open_file_button_" + cId,
					"#image_url_field_" + cId, "image");
			this._bindOpenWebdavDialog("#image_open_webdav_button_" + cId,
					"#image_url_field_" + cId, "get-webdav-image");
			if (!apiObject.isActionEnabled("get-webdav-image")) {
				jQuery("#image_open_webdav_button_" + cId).hide();
			}
			var buttons = {};
			buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
				thiz._hideDialog();
			};
			buttons[apiObject.locale.getLocaleCode("L_INSERT_BUTTON")] = function() {
				var url = "";
				var alt = "";
				var borderWidth = "";
				var width = "";
				var height = "";
				url = jQuery("#image_url_field_" + cId).val();
				alt = jQuery("#image_alt_field_" + cId).val();
				borderWidth = jQuery("#image_border_width_" + cId).val();
				width = jQuery("#image_size_width_field_" + cId).val();
				height = jQuery("#image_size_height_field_" + cId).val();
				if (url !== "") {
					var imgAttr = {};
					imgAttr.imageSource = url;
					if (alt !== "") {
						imgAttr.imageAlt = alt;
					} else {
						imgAttr.imageAlt = null;
					}
					if (borderWidth !== "") {
						imgAttr.imageBorderWidth = borderWidth;
						imgAttr.imageBorderWidthUnit = "px";
					} else {
						imgAttr.imageBorderWidth = null;
					}
					if (width !== "") {
						imgAttr.imageWidth = width;
						imgAttr.imageWidthUnit = "px";
					} else {
						imgAttr.imageWidth = null;
					}
					if (height !== "") {
						imgAttr.imageHeight = height;
						imgAttr.imageHeightUnit = "px";
					} else {
						imgAttr.imageHeight = null;
					}
					if (jQuery("#image_convert_to_data_uri_checkbox_" + cId)
							.is(":checked")) {
						apiObject.invokeAction("convert-image-to-data-uri",
								jQuery.toJSON(imgAttr));
					} else {
						apiObject.invokeAction("insert-image", jQuery
								.toJSON(imgAttr));
					}
					thiz._hideDialog();
				} else {
				}
			};
			jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
			this._dialogCreateTabs();
			if (!apiObject.isActionEnabled("convert-image-to-data-uri")) {
				jQuery("#image_convert_to_data_uri_" + cId).hide();
			}
		}
	};
	this.imagePropertiesDialog = function() {
		var properties = apiObject.toolkitInternal._getImageProperties();
		if (properties == null || properties == undefined || properties == "") {
			return;
		}
		var html = this.dialogHTMLMap["imageProperties"];
		this._createDialog(apiObject.locale
				.getLocaleCode("L_IMAGE_PROPERTIES_DIALOG"));
		this._showDialog(html);
		this._createSpinner("#image_border_width_" + cId, 0, 100);
		this._bindOpenFileDialog("#image_open_file_button_" + cId,
				"#image_url_field_" + cId, "image");
		this._bindOpenWebdavDialog("#image_open_webdav_button_" + cId,
				"#image_url_field_" + cId, "get-webdav-image");
		if (!apiObject.isActionEnabled("get-webdav-image")) {
			jQuery("#image_open_webdav_button_" + cId).hide();
		}
		var url = properties["imageSource"];
		var alt = properties["imageAlt"];
		var borderwidth = properties["imageBorderWidth"];
		var width = properties["imageWidth"];
		var height = properties["imageHeight"];
		jQuery("#image_url_field_" + cId).val(url);
		jQuery("#image_alt_field_" + cId).val(alt);
		jQuery("#image_border_width_" + cId).val(borderwidth);
		jQuery("#image_size_width_field_" + cId).val(width);
		jQuery("#image_size_height_field_" + cId).val(height);
		var buttons = {};
		buttons[apiObject.locale.getLocaleCode("L_CANCEL_BUTTON")] = function() {
			thiz._hideDialog();
		};
		buttons[apiObject.locale.getLocaleCode("L_APPLY_BUTTON")] = function() {
			var url = "";
			var alt = "";
			var borderWidth = "";
			var width = "";
			var height = "";
			url = jQuery("#image_url_field_" + cId).val();
			alt = jQuery("#image_alt_field_" + cId).val();
			borderWidth = jQuery("#image_border_width_" + cId).val();
			width = jQuery("#image_size_width_field_" + cId).val();
			height = jQuery("#image_size_height_field_" + cId).val();
			if (url !== "") {
				attributes = {};
				attributes.imageSource = url;
				if (alt !== "") {
					attributes.imageAlt = alt;
				} else {
					attributes.imageAlt = null;
				}
				if (borderWidth !== "") {
					attributes.imageBorderWidth = borderWidth;
					attributes.imageBorderWidthUnit = "px";
				} else {
					attributes.imageBorderWidth = null;
				}
				if (width !== "") {
					attributes.imageWidth = width;
					attributes.imageWidthUnit = "px";
				} else {
					attributes.imageWidth = null;
				}
				if (height !== "") {
					attributes.imageHeight = height;
					attributes.imageHeightUnit = "px";
				} else {
					attributes.imageHeight = null;
				}
				apiObject.invokeAction("image-properties", jQuery
						.toJSON(attributes));
				thiz._hideDialog();
			} else {
			}
		};
		jQuery("#modalDialog_" + cId).dialog('option', 'buttons', buttons);
		this._dialogCreateTabs();
	};
	this._updateSpinnerStep = function(elementId, unit) {
		jQuery("#" + elementId).spinner("option", "step",
				this._getIncrementFromUnit(unit));
	};
	this._getIncrementFromUnit = function(unit) {
		switch (unit) {
		case "cm":
			return 0.1;
			break;
		case "em":
			return 0.1;
			break;
		case "in":
			return 0.1;
			break;
		case "mm":
			return 1;
			break;
		case "px":
			return 1;
			break;
		case "pt":
			return 1;
			break;
		}
	};
	this._updatePageOrientationByPageSize = function(target) {
		var width = 0;
		var height = 0;
		var id = jQuery(target).attr("id");
		if (id.search(/^page_size_.*/) != -1) {
			width = parseFloat(jQuery("#page_size_width_" + cId).val());
			height = parseFloat(jQuery("#page_size_height_" + cId).val());
			if (width > height) {
				jQuery(
						"input[name='page_orientation_radio_" + cId
								+ "'][value='1']").prop("checked", true);
			} else if (height > width) {
				jQuery(
						"input[name='page_orientation_radio_" + cId
								+ "'][value='0']").prop("checked", true);
			}
		} else {
			width = parseFloat(jQuery("#first_page_size_width_" + cId).val());
			height = parseFloat(jQuery("#first_page_size_height_" + cId).val());
			if (width > height) {
				jQuery(
						"input[name='first_page_orientation_radio_" + cId
								+ "'][value='1']").prop("checked", true);
			} else if (height > width) {
				jQuery(
						"input[name='first_page_orientation_radio_" + cId
								+ "'][value='0']").prop("checked", true);
			}
		}
	};
	this._updatePageSizeFromDropDown = function(target) {
		var id = jQuery(target).attr("id");
		var orientation = jQuery(
				"input[name='page_orientation_radio_" + cId + "']:checked")
				.val();
		var pageSize = jQuery(target).val();
		if (pageSize !== "Custom") {
			var pageSizeInformation = this._pageSizes[pageSize];
			var unit = pageSizeInformation["units"][0];
			if (id.search(/^page_size_.*/) != -1) {
				jQuery(
						"#page_size_unit_" + cId + " option[value='" + unit
								+ "']").prop("selected", true);
				this._updateSpinnerStep("page_size_width_" + cId, unit);
				this._updateSpinnerStep("page_size_height_" + cId, unit);
				if (orientation == 0) {
					jQuery("#page_size_width_" + cId).val(
							pageSizeInformation["width"]);
					jQuery("#page_size_height_" + cId).val(
							pageSizeInformation["height"]);
				} else {
					jQuery("#page_size_width_" + cId).val(
							pageSizeInformation["height"]);
					jQuery("#page_size_height_" + cId).val(
							pageSizeInformation["width"]);
				}
			} else {
				jQuery(
						"#first_page_size_unit_" + cId + " option[value='"
								+ unit + "']").prop("selected", true);
				this._updateSpinnerStep("first_page_size_width_" + cId, unit);
				this._updateSpinnerStep("first_page_size_height_" + cId, unit);
				if (orientation == 0) {
					jQuery("#first_page_size_width_" + cId).val(
							pageSizeInformation["width"]);
					jQuery("#first_page_size_height_" + cId).val(
							pageSizeInformation["height"]);
				} else {
					jQuery("#first_page_size_width_" + cId).val(
							pageSizeInformation["height"]);
					jQuery("#first_page_size_height_" + cId).val(
							pageSizeInformation["width"]);
				}
			}
		}
	};
	this._flipPageSize = function(target) {
		var id = jQuery(target).attr("name");
		var width = 0;
		var height = 0;
		if (id.search(/^page_orientation_radio.*/) != -1) {
			width = jQuery("#page_size_width_" + cId).val();
			height = jQuery("#page_size_height_" + cId).val();
			jQuery("#page_size_width_" + cId).val(height);
			jQuery("#page_size_height_" + cId).val(width);
		} else {
			width = jQuery("#first_page_size_width_" + cId).val();
			height = jQuery("#first_page_size_height_" + cId).val();
			jQuery("#first_page_size_width_" + cId).val(height);
			jQuery("#first_page_size_height_" + cId).val(width);
		}
	};
	this._updatePageLayout = function(target) {
		var layoutState = jQuery(target).val();
		if (layoutState == "normal") {
			jQuery("#page_margin_left_label_" + cId).html(
					apiObject.locale.getLocaleCode("L_PAGE_MARGIN_LEFT"));
			jQuery("#page_margin_right_label_" + cId).html(
					apiObject.locale.getLocaleCode("L_PAGE_MARGIN_RIGHT"));
		} else {
			jQuery("#page_margin_left_label_" + cId).html(
					apiObject.locale.getLocaleCode("L_PAGE_MARGIN_OUTER"));
			jQuery("#page_margin_right_label_" + cId).html(
					apiObject.locale.getLocaleCode("L_PAGE_MARGIN_INNER"));
		}
	};
	this._updatePageSizeDropDown = function(target) {
		var width = 0;
		var height = 0;
		var unit = "";
		var pageSize = "";
		var id = jQuery(target).attr("id");
		if (id.search(/^page_size_.*/) != -1) {
			width = jQuery("#page_size_width_" + cId).val();
			height = jQuery("#page_size_height_" + cId).val();
			unit = jQuery("#page_size_unit_" + cId).val();
			pageSize = this._getPageSizeConstant(width, height, unit);
			jQuery("#page_size_" + cId + " option[value='" + pageSize + "']")
					.prop("selected", true);
		} else {
			width = jQuery("#first_page_size_width_" + cId).val();
			height = jQuery("#first_page_size_height_" + cId).val();
			unit = jQuery("#first_page_size_unit_" + cId).val();
			pageSize = this._getPageSizeConstant(width, height, unit);
			jQuery(
					"#first_page_size_" + cId + " option[value='" + pageSize
							+ "']").prop("selected", true);
		}
	};
	this._getPageSizeConstant = function(width, height, unit) {
		if (unit === "mm") {
			width = width / 10;
			height = height / 10;
		}
		var pageSize = "Custom";
		jQuery
				.each(
						this._pageSizes,
						function(index, value) {
							var unitArray = value["units"];
							if (jQuery.inArray(unit, unitArray) != -1) {
								if ((value["width"] == width && value["height"] == height)
										|| (value["width"] == height && value["height"] == width)) {
									pageSize = index;
									return false;
								}
							}
						});
		return pageSize;
	};
	this._verifyBookmark = function() {
		var text = jQuery.trim(jQuery("#bookmark_text_field_" + cId).val());
		var addButton = jQuery("#add_bookmark_button_" + cId);
		var validBookmark = apiObject.toolkitInternal
				._isIdValidAndAvailable(text);
		if (text !== jQuery(this).attr("name") && validBookmark) {
			addButton.removeAttr("disabled");
			addButton.removeClass("ui-state-disabled");
		} else {
			addButton.attr("disabled", "disabled");
			addButton.addClass("ui-state-disabled");
		}
		if (validBookmark) {
			jQuery("#bookmark_invalid_id_" + cId).css("display", "none");
		} else if (text !== "") {
			jQuery("#bookmark_invalid_id_" + cId).css("display", "inline");
		}
	};
	this._fillReferenceElementsList = function(elements) {
		var referenceElementList = jQuery("#reference_blockelements_" + cId);
		referenceElementList.html("");
		jQuery.each(elements, function(i, element) {
			var elementOption = jQuery("<li name=\"" + i + "\">" + element
					+ "</li>");
			elementOption.bind("click", function() {
				jQuery(this).siblings().removeClass("ui-selected");
				jQuery(this).addClass("ui-selected");
			});
			if (i === 0) {
				elementOption.addClass("ui-selected");
			}
			referenceElementList.append(elementOption);
		});
	};
	this._createCrossreferencesJSON = function() {
		var elementTypeIndex = jQuery(
				"#reference_element_types_" + cId + " .ui-selected").attr(
				"name");
		var referenceElementIndex = jQuery(
				"#reference_blockelements_" + cId + " .ui-selected").attr(
				"name");
		if (elementTypeIndex === null || referenceElementIndex === null) {
			return null;
		}
		var type = jQuery("input[name='source_radio_" + cId + "']:checked")
				.val();
		var hyperLinkChecked = jQuery(
				"#reference_options_hyperlink_" + cId + ":checked").val();
		var crossReferenceInsertionData = {};
		crossReferenceInsertionData.elementTypeIndex = elementTypeIndex;
		crossReferenceInsertionData.referenceElementIndex = referenceElementIndex;
		crossReferenceInsertionData.insertedContentType = type;
		crossReferenceInsertionData.insertAsHyperlink = (hyperLinkChecked === "on");
		var jsonedReturnData = jQuery.toJSON(crossReferenceInsertionData);
		return jsonedReturnData;
	};
	this._createDialog = function(title, prefix, replace) {
		this.Helper.createDialog(title, prefix, replace);
	};
	this._showDialog = function(html, prefix, replace) {
		this.Helper.showDialog(html, prefix, replace);
	};
	this._createSpinner = function(id, min, max, step) {
		this.Helper.createSpinner(id, min, max, step);
	};
	this._hideDialog = function(prefix, replace) {
		this.Helper.hideDialog(prefix, replace);
	};
	this._dialogCreateTabs = function(prefix) {
		this.Helper.dialogCreateTabs(prefix);
	};
	this._parseStructureTemplates = function() {
		return this.Helper.parseStructureTemplates();
	};
	this._bindOpenFileDialog = function(bindToElemId, updateElem, filter) {
		this.Helper.bindOpenFileDialog(bindToElemId, updateElem, filter);
	};
	this._bindOpenWebdavDialog = function(bindToElemId, updateElem, actionID) {
		this.Helper.bindOpenWebdavDialog(bindToElemId, updateElem, actionID);
	};
	this._openWebdavDialog = function(updateElem, actionID) {
		this.Helper.openWebdavDialog(updateElem, actionID);
	};
	this._createDrawTableElement = function(tableId, rowResultId,
			columnResultId, rows, columns) {
		this.Helper.createDrawTableElement(tableId, rowResultId,
				columnResultId, rows, columns);
	};
	this._createColorSelectTable = function(colors, element) {
		this.Helper.createColorSelectTable(colors, element);
	};
	this._createParameterWidget = function(container, paramObject) {
		this.Helper.createParameterWidget(container, paramObject);
	};
	this._pageSizes = this.Helper.pageSizes;
	this._defaultColors = this.Helper.defaultColors;
};
eongApplication.DOMElements = function(DOMElementsHelper, DOMElementsLogger) {
	DOMElementsObject = this;
	this.enableToolbar = function() {
		jQuery("#" + DOMElementsHelper.containerId + "_toolbar_container")
				.tabs("option", "disabled", []);
	};
	this.createToolbar = function(fake) {
		if (this.detachedUI) {
			this.toolbarWidth = DOMElementsHelper.detachableUI.toolbar.options.width;
		} else {
			if (!isNaN(DOMElementsHelper.containerWidth)
					|| (DOMElementsHelper.containerWidth.indexOf("%") > 0)) {
				if (DOMElementsHelper.isMSIE) {
					this.toolbarWidth = (DOMElementsHelper.containerWidth - 7)
							+ "px";
				} else if (DOMElementsHelper.isWebKit) {
					this.toolbarWidth = (DOMElementsHelper.containerWidth - 5)
							+ "px";
				} else {
					this.toolbarWidth = (DOMElementsHelper.containerWidth - 6)
							+ "px";
				}
			}
		}
		if (fake) {
			this.Toolbar.createToolBar(this.toolbarWidth,
					DOMElementsHelper.containerId, fake);
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_ribbon_tab_container li, #"
							+ DOMElementsHelper.containerId
							+ "_toolbar_container .ui-tabs-panel").css({
				visibility : "hidden"
			});
			if (DOMElementsHelper.isMac
					|| (!DOMElementsHelper.isMac && DOMElementsHelper.isWebKit)) {
				var toolbarHeight = 114;
			} else {
				var toolbarHeight = 119;
			}
			if (DOMElementsHelper.config.hidesingletabs !== undefined
					&& DOMElementsHelper.config.hidesingletabs === "true") {
				if (DOMElementsHelper.uiconfig.toolbar.ribbons.elements !== undefined
						&& jQuery(DOMElementsHelper.uiconfig.toolbar.ribbons.elements).length === 1) {
					jQuery(
							"#" + DOMElementsHelper.containerId
									+ "_ribbon_tab_container").hide();
					if (DOMElementsHelper.isMac
							|| (!DOMElementsHelper.isMac && DOMElementsHelper.isWebKit)) {
						toolbarHeight -= 23;
					} else {
						toolbarHeight -= 25;
					}
					jQuery("#iconContainer_" + DOMElementsHelper.containerId)
							.hide();
				}
			}
			if (DOMElementsHelper.config.hidetoolbarpaneldescription !== undefined
					&& DOMElementsHelper.config.hidetoolbarpaneldescription === "true") {
				jQuery(
						"#" + DOMElementsHelper.containerId
								+ "_toolbar_container .ribbonPanelDescription")
						.hide();
				if (DOMElementsHelper.isMac
						|| (!DOMElementsHelper.isMac && DOMElementsHelper.isWebKit)) {
					toolbarHeight -= 15;
				} else {
					toolbarHeight -= 16;
				}
			}
			jQuery("#" + DOMElementsHelper.containerId + "_toolbar").css({
				"min-height" : toolbarHeight + "px"
			});
		} else {
			jQuery("#" + DOMElementsHelper.containerId + "_toolbar").html("");
			this.Toolbar.createToolBar(this.toolbarWidth,
					DOMElementsHelper.containerId, fake);
			if (DOMElementsHelper.config.hidesingletabs !== undefined
					&& DOMElementsHelper.config.hidesingletabs === "true") {
				if (DOMElementsHelper.uiconfig.toolbar.ribbons.elements !== undefined
						&& jQuery(DOMElementsHelper.uiconfig.toolbar.ribbons.elements).length === 1) {
					jQuery(
							"#" + DOMElementsHelper.containerId
									+ "_ribbon_tab_container").hide();
					jQuery("#iconContainer_" + DOMElementsHelper.containerId)
							.hide();
				}
			}
			if (DOMElementsHelper.config.hidetoolbarpaneldescription !== undefined
					&& DOMElementsHelper.config.hidetoolbarpaneldescription === "true") {
				jQuery(
						"#" + DOMElementsHelper.containerId
								+ "_toolbar_container .ribbonPanelDescription")
						.hide();
			}
			DOMElementsLogger.log("[assembleDOM]: attaching events", "FINEST",
					this);
			jQuery('.editorAction_' + DOMElementsHelper.containerId).each(
					function(i) {
						DOMElementsHelper.jsObj.attachEventToElement(this,
								DOMElementsHelper.jsObj);
					});
		}
	}
	this.assembleDOM = function() {
		DOMElementsLogger.log("[assembleDOM]: setting application container",
				"FINEST", this);
		if (DOMElementsHelper.config.detachableUI !== undefined) {
			DOMElementsHelper.detachableUI = DOMElementsHelper.config.detachableUI;
		} else {
			DOMElementsHelper.detachableUI = {};
		}
		this.setApplicationContainer();
		DOMElementsLogger.log("[assembleDOM]: creating toolbar object",
				"FINEST", this);
		this.Toolbar = new eongApplication.Toolbar(DOMElementsHelper,
				DOMElementsLogger);
		DOMElementsLogger
				.log("[assembleDOM]: creating toolbar", "FINEST", this);
		DOMElementsLogger.log("[assembleDOM]: setting statusbar", "FINEST",
				this);
		if (DOMElementsHelper.config.enablestatusbar === undefined
				|| DOMElementsHelper.config.enablestatusbar == "true"
				|| DOMElementsHelper.config.enablestatusbar === true) {
			this.setStatusBar();
		}
		if (DOMElementsHelper.config.saveuistate !== undefined
				&& DOMElementsHelper.config.saveuistate == "true") {
			this.createToolbar(true);
		} else {
			this.createToolbar(false);
		}
		DOMElementsLogger.log("[assembleDOM]: setting sidebar", "FINEST", this);
		if (DOMElementsHelper.config.enablestyletemplatepanel === undefined
				|| DOMElementsHelper.config.enablestyletemplatepanel == "true"
				|| DOMElementsHelper.config.enablestyletemplatepanel === true) {
			this.setSidebar();
		}
		DOMElementsLogger.log("[assembleDOM]: setting applet container",
				"FINEST", this);
		this.setAppletContainer();
		if (DOMElementsHelper.config.enableruler !== undefined
				&& DOMElementsHelper.config.enableruler == "true") {
			DOMElementsLogger.log("[assembleDOM]: setting ruler container",
					"FINEST", this);
			this.setRulerContainer();
		}
		DOMElementsLogger.log("[assembleDOM]: applying layout", "FINEST", this);
		this.applyLayout();
		var tabBarWidth = 15;
		jQuery("#" + DOMElementsHelper.containerId + "_ribbon_tab_container")
				.children().each(function() {
					tabBarWidth += jQuery(this).outerWidth() + 2;
				});
		tabBarWidth += jQuery("#iconContainer_" + DOMElementsHelper.containerId)
				.outerWidth();
		var statusBarWidth = 0;
		jQuery(
				"#" + DOMElementsHelper.containerId
						+ "_statusbar .statusBarCell").each(function() {
			if (jQuery(this).css("display") !== "none") {
				statusBarWidth += jQuery(this).outerWidth();
			}
		});
		statusBarWidth -= jQuery(
				"#" + DOMElementsHelper.containerId
						+ "_statusbar .documentPaletteContainer").outerWidth() + 8;
		var maxPanelWidth = 0;
		jQuery(
				"#" + DOMElementsHelper.containerId
						+ "_toolbar div.dialogPanels").each(function() {
			var currentPanelWidth = 0;
			jQuery(this).children("div.ribbonPanel").each(function() {
				currentPanelWidth += jQuery(this).outerWidth() + 2;
			});
			if (currentPanelWidth > maxPanelWidth) {
				maxPanelWidth = currentPanelWidth;
			}
		});
		var minResizeWidth = Math.max(tabBarWidth, statusBarWidth,
				maxPanelWidth);
		if (!this.detachedUI) {
			if (DOMElementsHelper.config.draggable !== undefined
					&& DOMElementsHelper.config.draggable == "true") {
				DOMElementsLogger.log("[assembleDOM]: setting draggable",
						"FINEST", this);
				this.setDraggable();
			}
			if (DOMElementsHelper.config.resizable !== undefined
					&& DOMElementsHelper.config.resizable == "true") {
				DOMElementsLogger.log("[assembleDOM]: setting resizable",
						"FINEST", this);
				this.setResizable(minResizeWidth);
			}
		}
		DOMElementsLogger.log("[assembleDOM]: loading applet", "FINEST", this);
		if (jQuery("#modalDialog_" + DOMElementsHelper.containerId).length == 0) {
			jQuery("body")
					.append(
							"<div id=\"modalDialog_"
									+ DOMElementsHelper.containerId
									+ "\" class=\"modalDialog ui-tabs ui-widget ui-widget-content ui-corner-all ui-dialog-content\" style=\"height: 1px; display:none;\"></div>");
		}
		this.loadApplet();
		jQuery("#" + DOMElementsHelper.containerId + "_div").width(
				(DOMElementsHelper.parseNumber(DOMElementsHelper.editorWidth)));
		var width = jQuery("#" + DOMElementsHelper.id).width();
		var height = jQuery("#" + DOMElementsHelper.id).height();
		var replaceTop = 0;
		if (DOMElementsHelper.config.enableruler !== undefined
				&& DOMElementsHelper.config.enableruler == "true") {
			replaceTop = "18px";
		}
		if (DOMElementsHelper.isMSIE
				&& parseInt(DOMElementsHelper.BrowserVersion) < 8
				|| (DOMElementsHelper.config.enablereplacementimage !== undefined && DOMElementsHelper.config.enablereplacementimage === "false")) {
			jQuery("#" + DOMElementsHelper.containerId + "_div")
					.append(
							"<div class=\"ui-state-normal\" id=\"replacementImage_"
									+ DOMElementsHelper.containerId
									+ "\" border=\"0\" style=\"position: absolute; top: "
									+ replaceTop
									+ "; left: 0; padding: 5px; background-color: #ffffff; font-size: 16px; display: none; width: "
									+ width
									+ "px; height: "
									+ height
									+ "px;\"><p>The \"ReplacementImage\" functionality which is necessary to display content of the editor while a HTML dialog is open, is disabled by configuration or non-support of BASE64 images of your browser.</p><p> If the functionality is not disabled by configuration and you are using IE 8 please make sure to deactivate the \"Compatibility Mode\" when using edit-on NG.</p></div>");
		} else {
			jQuery("#" + DOMElementsHelper.containerId + "_div")
					.append(
							"<img id=\"replacementImage_"
									+ DOMElementsHelper.containerId
									+ "\" border=\"0\" style=\"position: absolute; top: "
									+ replaceTop
									+ "; left: 0; display: none;\" width=\""
									+ width + "\" height=\"" + height
									+ "\"src=\"\" />");
		}
		DOMElementsHelper.initialOffset = jQuery(
				"#" + DOMElementsHelper.containerId).offset();
		if (DOMElementsHelper.isStartFullscreen) {
			DOMElementsHelper.toggleFullscreenMode();
		}
		if (DOMElementsHelper.isMac) {
			DOMElementsHelper.resizeUI();
		}
	};
	this.assembleDOMPreload = function() {
		jQuery("body").append(this.getPreloadAppletElement);
	};
	this.setDraggable = function() {
		jQuery("#" + DOMElementsHelper.containerId).draggable({
			ghost : true,
			animate : true,
			handle : "#dragHandler_" + DOMElementsHelper.containerId,
			stop : function(ui, e) {
				DOMElementsHelper.resizeUI(true);
				DOMElementsHelper.jsWrapperObj.requestFocus();
			}
		});
	};
	this.setResizable = function(minResizeWidth) {
		jQuery("#" + DOMElementsHelper.containerId)
				.resizable(
						{
							minWidth : minResizeWidth,
							minHeight : jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_toolbar").height()
									+ jQuery(
											"#" + DOMElementsHelper.containerId
													+ "_statusbar").height()
									+ 40,
							handles : {
								se : ".seHandle"
							},
							resize : function(event, ui) {
								if (DOMElementsHelper.isMSIE
										&& parseInt(DOMElementsHelper.BrowserVersion) < 7) {
									DOMElementsHelper.resizeUI(false,
											ui.size.width, ui.size.height);
								} else {
									DOMElementsHelper.resizeUI();
								}
								DOMElementsHelper.jsWrapperObj.requestFocus();
								jQuery("#" + DOMElementsHelper.containerId)
										.offset(DOMElementsHelper.initialOffset);
							}
						});
	};
	this.getAppletElement = function() {
		if (window.navigator.javaEnabled()) {
			if (DOMElementsHelper.isMSIE) {
				if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
					DOMElementsHelper.addAttribute("classid",
							"clsid:8AD9C840-044E-11D1-B3E9-00805F499D93");
				}
				if (DOMElementsHelper.isJREAutoDownloadEnabled) {
					DOMElementsHelper.addAttribute("codebase",
							DOMElementsHelper.jreAutoDownloadURL
									+ DOMElementsHelper.jreMinVersion);
				}
			} else {
				if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
					DOMElementsHelper.addAttribute("classid", "java:"
							+ DOMElementsHelper.code);
				} else {
					DOMElementsHelper.addAttribute("code",
							DOMElementsHelper.code);
				}
			}
			if (DOMElementsHelper.enablePack200) {
				DOMElementsHelper.setParam("java_arguments",
						DOMElementsHelper.maxMemory + " "
								+ DOMElementsHelper.pack200);
			} else {
				DOMElementsHelper.setParam("java_arguments",
						DOMElementsHelper.maxMemory);
			}
			if (!isNaN(DOMElementsHelper
					.parseNumber(DOMElementsHelper.editorWidth))) {
				DOMElementsHelper.editorWidth--;
			}
			if (!isNaN(DOMElementsHelper
					.parseNumber(DOMElementsHelper.editorHeight))) {
				DOMElementsHelper.editorHeight--;
			}
			var toolbarHeight = 0;
			var statusBarHeight = 0;
			if (!this.detachedUI) {
				toolbarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_toolbar").css(
						"min-height");
				if (toolbarHeight === "auto" || toolbarHeight === "0px") {
					toolbarHeight = jQuery(
							"#" + DOMElementsHelper.containerId + "_toolbar")
							.height();
				}
				if (DOMElementsHelper.config.enablestatusbar === undefined
						|| DOMElementsHelper.config.enablestatusbar == "true") {
					statusBarHeight = jQuery(
							"#" + DOMElementsHelper.containerId + "_statusbar")
							.height();
				} else {
					statusBarHeight = 0;
				}
			}
			var reduceHeight = parseInt(toolbarHeight, 10)
					+ parseInt(statusBarHeight, 10);
			if (DOMElementsHelper.isMSIE) {
				reduceHeight = reduceHeight - 1;
			} else if (DOMElementsHelper.isWebKit) {
				reduceHeight = reduceHeight - 1;
			} else {
				reduceHeight = reduceHeight - 1;
			}
			var sideBarWidth = parseInt(jQuery(
					"#" + DOMElementsHelper.containerId + "_sidebar").css(
					"width"), 10);
			var sideBarVisible = jQuery(
					"#" + DOMElementsHelper.containerId + "_sidebar").css(
					"display");
			if (sideBarVisible == "none" || sideBarVisible === undefined) {
				reduceWidth = 0;
			} else {
				reduceWidth = sideBarWidth + 7;
			}
			if (DOMElementsHelper.config.enablestyletemplatepanel === undefined
					|| DOMElementsHelper.config.enablestyletemplatepanel == "true"
					|| DOMElementsHelper.config.enablestyletemplatepanel === true) {
				DOMElementsHelper.addAttribute("width", DOMElementsHelper
						.parseNumber(DOMElementsHelper.editorWidth
								- reduceWidth));
			} else {
				DOMElementsHelper.addAttribute("width", DOMElementsHelper
						.parseNumber(DOMElementsHelper.editorWidth));
			}
			DOMElementsHelper
					.addAttribute("height", DOMElementsHelper
							.parseNumber(DOMElementsHelper.editorHeight
									- reduceHeight));
			DOMElementsHelper.addAttribute("id", DOMElementsHelper.id);
			DOMElementsHelper
					.addAttribute("name", DOMElementsHelper.appletName);
			DOMElementsHelper.setParam("jsobject", DOMElementsHelper.jsObjName);
			if (DOMElementsHelper.isMac || DOMElementsHelper.isWebKit) {
				DOMElementsHelper.tagStyle = DOMElementsHelper.APPLET_TAG;
				DOMElementsHelper.addAttribute("codebase",
						DOMElementsHelper.codebase);
				DOMElementsHelper.addAttribute("code", DOMElementsHelper.code);
				DOMElementsHelper.setParam("type",
						"application/x-java-applet;version=1.5");
			} else {
				DOMElementsHelper.setParam("java_codebase",
						DOMElementsHelper.codebase);
				DOMElementsHelper.setParam("java_code", DOMElementsHelper.code);
				DOMElementsHelper.setParam("java_type",
						"application/x-java-applet;version=1.5");
			}
			var elem = "";
			if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
				DOMElementsHelper.setParam("mayscript", "true");
				DOMElementsHelper.setParam("scriptable", "true");
				elem = "object";
			} else if (DOMElementsHelper.tagStyle == DOMElementsHelper.APPLET_TAG) {
				DOMElementsHelper.addAttribute("mayscript", "true");
				DOMElementsHelper.addAttribute("scriptable", "true");
				elem = "applet";
			}
			DOMElementsHelper.setParam("image", DOMElementsHelper.codebase
					+ "/splashscreen.gif");
			DOMElementsHelper.setParam("centerimage", "true");
			DOMElementsHelper.setParam("boxborder", "false");
			DOMElementsHelper.setParam("codebase_lookup", "false");
			appletElement = "<" + elem;
			appletElement += DOMElementsHelper.attribs;
			appletElement += ">";
			appletElement += DOMElementsHelper.params;
			appletElement += "</" + elem + ">";
			return appletElement;
		} else {
			var toolbarHeight = 0;
			var statusBarHeight = 0;
			if (!this.detachedUI) {
				toolbarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_toolbar")
						.height();
				statusBarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_statusbar")
						.height();
			}
			var reduceHeight = parseInt(toolbarHeight, 10)
					+ parseInt(statusBarHeight, 10);
			if (DOMElementsHelper.isMSIE) {
				reduceHeight = reduceHeight - 1;
			} else if (DOMElementsHelper.isWebKit) {
				reduceHeight = reduceHeight - 3;
			} else {
				reduceHeight = reduceHeight - 1;
			}
			var sideBarWidth = parseInt(jQuery(
					"#" + DOMElementsHelper.containerId + "_sidebar").css(
					"width"), 10);
			var sideBarVisible = jQuery(
					"#" + DOMElementsHelper.containerId + "_sidebar").css(
					"display");
			if (sideBarVisible == "none" || sideBarVisible === undefined) {
				reduceWidth = 0;
			} else {
				reduceWidth = sideBarWidth + 7;
			}
			if (DOMElementsHelper.config.enablestyletemplatepanel === undefined
					|| DOMElementsHelper.config.enablestyletemplatepanel == "true"
					|| DOMElementsHelper.config.enablestyletemplatepanel === true) {
				var width = DOMElementsHelper.editorWidth - (reduceWidth + 13);
			} else {
				var width = DOMElementsHelper.editorWidth - 13;
			}
			var height = DOMElementsHelper.editorHeight - reduceHeight;
			var replaceAppletElement = "<div class='ui-state-error' style='width: "
					+ width + "px; height:" + height + "px; padding: 5px;'>";
			replaceAppletElement += "<h2 style='text-align: center; font-size: 12pt !important;'>Error: Java is not enabled</h2>";
			replaceAppletElement += "<p><a href='#' onclick='deployJava.installLatestJRE();'>Update to latest Java version</a></p>";
			replaceAppletElement += "</div>";
			return replaceAppletElement;
		}
	};
	this.getPreloadAppletElement = function() {
		if (window.navigator.javaEnabled()) {
			if (DOMElementsHelper.isMSIE) {
				if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
					DOMElementsHelper.addAttribute("classid",
							"clsid:8AD9C840-044E-11D1-B3E9-00805F499D93");
				}
				if (DOMElementsHelper.isJREAutoDownloadEnabled) {
					DOMElementsHelper.addAttribute("codebase",
							DOMElementsHelper.jreAutoDownloadURL
									+ DOMElementsHelper.jreMinVersion);
				}
			} else {
				if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
					DOMElementsHelper.addAttribute("classid", "java:"
							+ DOMElementsHelper.code);
				} else {
					DOMElementsHelper.addAttribute("code",
							DOMElementsHelper.code);
				}
			}
			if (DOMElementsHelper.enablePack200) {
				DOMElementsHelper.setParam("java_arguments",
						DOMElementsHelper.pack200 + " "
								+ DOMElementsHelper.maxMemory);
			} else {
				DOMElementsHelper.setParam("java_arguments",
						DOMElementsHelper.maxMemory);
			}
			DOMElementsHelper.addAttribute("width", DOMElementsHelper
					.parseNumber(DOMElementsHelper.editorWidth));
			DOMElementsHelper.addAttribute("height", DOMElementsHelper
					.parseNumber(DOMElementsHelper.editorHeight));
			DOMElementsHelper.addAttribute("id", DOMElementsHelper.id);
			DOMElementsHelper
					.addAttribute("name", DOMElementsHelper.appletName);
			if (DOMElementsHelper.isMac || DOMElementsHelper.isWebKit) {
				DOMElementsHelper.tagStyle = DOMElementsHelper.APPLET_TAG;
				DOMElementsHelper.addAttribute("codebase",
						DOMElementsHelper.codebase);
				DOMElementsHelper.addAttribute("code", DOMElementsHelper.code);
				DOMElementsHelper.setParam("type",
						"application/x-java-applet;version=1.5");
			} else {
				DOMElementsHelper.setParam("java_codebase",
						DOMElementsHelper.codebase);
				DOMElementsHelper.setParam("java_code", DOMElementsHelper.code);
				DOMElementsHelper.setParam("java_type",
						"application/x-java-applet;version=1.5");
			}
			var elem = "";
			if (DOMElementsHelper.tagStyle == DOMElementsHelper.OBJECT_TAG) {
				DOMElementsHelper.setParam("mayscript", "true");
				DOMElementsHelper.setParam("scriptable", "true");
				elem = "object";
			} else if (DOMElementsHelper.tagStyle == DOMElementsHelper.APPLET_TAG) {
				DOMElementsHelper.addAttribute("mayscript", "true");
				DOMElementsHelper.addAttribute("scriptable", "true");
				elem = "applet";
			}
			DOMElementsHelper.setParam("codebase_lookup", "false");
			appletElement = "<" + elem;
			appletElement += DOMElementsHelper.attribs;
			appletElement += ">";
			appletElement += DOMElementsHelper.params;
			appletElement += "</" + elem + ">";
			return appletElement;
		} else {
			var width = DOMElementsHelper.editorWidth;
			var height = DOMElementsHelper.editorHeight;
			var replaceAppletElement = "<div class='ui-state-error' style='width: "
					+ width + "px; height:" + height + "px; padding: 5px;'>";
			replaceAppletElement += "<h2 style='text-align: center; font-size: 12pt !important;'>Error: Java is not enabled</h2>";
			replaceAppletElement += "<p><a href='#' onclick='deployJava.installLatestJRE();'>Update to latest Java version</a></p>";
			replaceAppletElement += "</div>";
			return replaceAppletElement;
		}
	};
	this.setApplicationContainer = function() {
		this.detachedUI = false;
		jQuery("#" + DOMElementsHelper.containerId).addClass("eongmainstyles");
		jQuery("#" + DOMElementsHelper.containerId).css({
			width : DOMElementsHelper.editorWidth + "px"
		});
		if (DOMElementsHelper.detachableUI.enabled !== undefined
				&& (DOMElementsHelper.detachableUI.enabled === "true" || DOMElementsHelper.detachableUI.enabled === true)) {
			jQuery("" + DOMElementsHelper.detachableUI.toolbar.options.location)
					.append(
							"<div id=\""
									+ DOMElementsHelper.containerId
									+ "_detachedToolBarContainer\" style=\""
									+ DOMElementsHelper.detachableUI.toolbar.options.style
									+ "\"></div>");
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer").append(
					"<div id=\"" + DOMElementsHelper.containerId
							+ "_toolbar\"></div>");
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer").css({
				width : DOMElementsHelper.detachableUI.toolbar.options.width
			});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer").addClass(
					"eongmainstyles");
			this.detachedUI = true;
			if (jQuery("#" + DOMElementsHelper.containerId + "_virtualCaret").length == 0) {
				jQuery("body")
						.append(
								"<div id=\""
										+ DOMElementsHelper.containerId
										+ "_virtualCaret\" class=\"virtualCaret\">&nbsp;</div>");
				jQuery("#" + DOMElementsHelper.containerId + "_virtualCaret")
						.css({});
			}
		} else {
			jQuery("#" + DOMElementsHelper.containerId).append(
					"<div id=\"" + DOMElementsHelper.containerId
							+ "_toolbar\"></div>");
		}
		jQuery("#" + DOMElementsHelper.containerId).append(
				"<div id=\"applicationContainer_"
						+ DOMElementsHelper.containerId + "\"></div>");
		jQuery("#applicationContainer_" + DOMElementsHelper.containerId).css({
			width : DOMElementsHelper.editorWidth + "px",
			height : DOMElementsHelper.editorHeight + "px"
		});
		if (DOMElementsHelper.isMSIE) {
			jQuery("#" + DOMElementsHelper.containerId).append(
					"<button id=\"" + DOMElementsHelper.containerId
							+ "_focusButton\" class=\"focusButton\"></button>");
		}
		if (!this.detachedUI) {
			jQuery("#" + DOMElementsHelper.containerId + "_toolbar").css({
				width : DOMElementsHelper.editorWidth + "px"
			});
		} else {
			jQuery("#" + DOMElementsHelper.containerId + "_toolbar").css({
				width : DOMElementsHelper.detachableUI.toolbar.options.width
			});
		}
	};
	this.setSidebar = function() {
		var content = "<div id=\"" + DOMElementsHelper.containerId
				+ "_sidebar\">";
		content += "<div class=\"sidebar_header ui-widget-header\" id=\""
				+ DOMElementsHelper.containerId + "_sidebar_header\">";
		content += "<div class=\"headerContent\">Style Templates</div>";
		content += "</div>";
		content += "<div class=\"ui-layout-content\" id=\""
				+ DOMElementsHelper.containerId + "_sidebar_content\"></div>";
		content += "</div>";
		jQuery("#applicationContainer_" + DOMElementsHelper.containerId)
				.append(content);
		jQuery("#" + DOMElementsHelper.containerId + "_sidebar").addClass(
				"ui-layout-west");
	};
	this.setAppletContainer = function() {
		DOMElementsLogger.log("[setAppletContainer]: appending applet div",
				"ALL", this);
		jQuery("#applicationContainer_" + DOMElementsHelper.containerId)
				.append(
						"<div id=\"" + DOMElementsHelper.appletName
								+ "_div\"></div>");
		DOMElementsLogger.log("[setAppletContainer]: setting div atributes",
				"ALL", this);
		jQuery("#" + DOMElementsHelper.appletName + "_div").attr({
			name : DOMElementsHelper.appletName + "_div"
		});
		DOMElementsLogger
				.log(
						"[setAppletContainer]: Adjusting the size: getting information",
						"ALL", this);
		var toolbarHeight = 0;
		var statusBarHeight = 0;
		if (!this.detachedUI) {
			toolbarHeight = jQuery(
					"#" + DOMElementsHelper.containerId + "_toolbar").css(
					"min-height");
			if (toolbarHeight === "auto" || toolbarHeight === "0px") {
				toolbarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_toolbar")
						.height();
			}
			if (DOMElementsHelper.config.enablestatusbar === undefined
					|| DOMElementsHelper.config.enablestatusbar == "true") {
				statusBarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_statusbar")
						.height();
			} else {
				statusBarHeight = 0;
			}
		}
		var reduceHeight = parseInt(toolbarHeight, 10)
				+ parseInt(statusBarHeight, 10);
		var reducedHeight = parseInt(DOMElementsHelper.containerHeight, 10)
				- reduceHeight;
		DOMElementsLogger.log("[setAppletContainer]: New size reducedHeight: "
				+ reducedHeight + ", containerWidth: "
				+ DOMElementsHelper.containerWidth, "ALL", this);
		DOMElementsLogger.log(
				"[setAppletContainer]: Adjusting the size: setting new size",
				"ALL", this);
		jQuery("#" + DOMElementsHelper.appletName + "_div").addClass(
				"ui-layout-center");
		jQuery("#" + DOMElementsHelper.appletName + "_div").css(
				{
					width : (DOMElementsHelper
							.parseNumber(DOMElementsHelper.editorWidth))
							+ "px",
					height : reducedHeight + "px",
					padding : "0",
					margin : "0"
				});
		DOMElementsLogger.log("[setAppletContainer]: Adjusted size", "ALL",
				this);
	};
	this.setRulerContainer = function() {
		var rulerContainer = jQuery("<div id=\""
				+ DOMElementsHelper.containerId
				+ "_ruler\" class=\"rulerContainer_div\"></div>");
		rulerContainer.addClass("ui-widget-header");
		jQuery("#" + DOMElementsHelper.appletName + "_div").append(
				rulerContainer);
	};
	this.loadApplet = function() {
		el = this.getAppletElement();
		document.getElementById(DOMElementsHelper.appletName + "_div").innerHTML += el
				.toString();
	};
	this.applyLayout = function() {
		var toolbarHeight = 0;
		var statusBarHeight = 0;
		if (!this.detachedUI) {
			toolbarHeight = jQuery(
					"#" + DOMElementsHelper.containerId + "_toolbar").css(
					"min-height");
			if (toolbarHeight === "auto" || toolbarHeight === "0px") {
				toolbarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_toolbar")
						.height();
			}
			if (DOMElementsHelper.config.enablestatusbar === undefined
					|| DOMElementsHelper.config.enablestatusbar == "true") {
				statusBarHeight = jQuery(
						"#" + DOMElementsHelper.containerId + "_statusbar")
						.height();
			} else {
				statusBarHeight = 0;
			}
		}
		var reduceHeight = parseInt(toolbarHeight, 10)
				+ parseInt(statusBarHeight, 10);
		jQuery("#applicationContainer_" + DOMElementsHelper.containerId).css({
			height : DOMElementsHelper.editorHeight - reduceHeight + "px"
		});
		initClosedWest = true;
		initWidth = 145;
		DOMElementsHelper.editorLayout = jQuery(
				"#applicationContainer_" + DOMElementsHelper.containerId)
				.layout(
						{
							defaults : {
								showErrorMessages : false,
								showDebugMessages : false,
								closable : true,
								spacing_open : 5,
								spacing_closed : 5,
								enableCursorHotkey : false
							},
							panes : {
								spacing_open : 5,
								spacing_closed : 5,
								closable : true,
								enableCursorHotkey : false
							},
							center : {
								closable : false,
								resizable : false
							},
							west : {
								initClosed : initClosedWest,
								onopen_end : function(name, el, state) {
									jQuery(
											"#"
													+ DOMElementsHelper.containerId
													+ "_statusbar .styleTemplateButton button")
											.parent("div").addClass(
													"ui-state-active");
									DOMElementsHelper.resizeUI(true);
									if (DOMElementsHelper.config.saveuistate !== undefined
											&& DOMElementsHelper.config.saveuistate == "true") {
										var stateObject = DOMElementsHelper
												.getUserPreferences("sidebarstate");
										if (stateObject === null) {
											stateObject = {};
										}
										if (stateObject[DOMElementsHelper
												.getLocation()] !== undefined
												&& stateObject[DOMElementsHelper
														.getLocation()] !== null
												&& stateObject[DOMElementsHelper
														.getLocation()] !== "") {
											if (stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId] !== undefined
													&& stateObject[DOMElementsHelper
															.getLocation()][DOMElementsHelper.containerId] !== null
													&& stateObject[DOMElementsHelper
															.getLocation()][DOMElementsHelper.containerId] !== "") {
											} else {
												stateObject[DOMElementsHelper
														.getLocation()][DOMElementsHelper.containerId] = {};
											}
										} else {
											stateObject[DOMElementsHelper
													.getLocation()] = {};
											stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId] = {};
										}
										stateObject[DOMElementsHelper
												.getLocation()][DOMElementsHelper.containerId]["size"] = state.size;
										stateObject[DOMElementsHelper
												.getLocation()][DOMElementsHelper.containerId]["initClosed"] = "false";
										DOMElementsHelper.setUserPreferences({
											"sidebarstate" : stateObject
										});
									}
								},
								onclose_end : function(name, el, state) {
									jQuery(".ui-layout-resizer").removeClass(
											" ui-state-disabled");
									jQuery(
											"#"
													+ DOMElementsHelper.containerId
													+ "_statusbar .styleTemplateButton button")
											.parent("div").removeClass(
													"ui-state-active");
									DOMElementsHelper.resizeUI(true);
									if (DOMElementsHelper.config.saveuistate !== undefined
											&& DOMElementsHelper.config.saveuistate == "true") {
										var stateObject = DOMElementsHelper
												.getUserPreferences("sidebarstate");
										if (stateObject === null) {
											stateObject = {};
										}
										if (stateObject[DOMElementsHelper
												.getLocation()] !== undefined
												&& stateObject[DOMElementsHelper
														.getLocation()] !== null
												&& stateObject[DOMElementsHelper
														.getLocation()] !== "") {
											if (stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId] !== undefined
													&& stateObject[DOMElementsHelper
															.getLocation()][DOMElementsHelper.containerId] !== null
													&& stateObject[DOMElementsHelper
															.getLocation()][DOMElementsHelper.containerId] !== "") {
											} else {
												stateObject[DOMElementsHelper
														.getLocation()][DOMElementsHelper.containerId] = {};
											}
										} else {
											stateObject[DOMElementsHelper
													.getLocation()] = {};
											stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId] = {};
										}
										stateObject[DOMElementsHelper
												.getLocation()][DOMElementsHelper.containerId]["size"] = state.size;
										stateObject[DOMElementsHelper
												.getLocation()][DOMElementsHelper.containerId]["initClosed"] = "true";
										DOMElementsHelper.setUserPreferences({
											"sidebarstate" : stateObject
										});
									}
								},
								onresize_end : function(name, el, state) {
									if (jQuery(
											"#" + DOMElementsHelper.containerId
													+ "_sidebar")
											.css("display") == "none") {
									} else {
										DOMElementsHelper.resizeUI(true);
										if (DOMElementsHelper.config.saveuistate !== undefined
												&& DOMElementsHelper.config.saveuistate == "true") {
											var stateObject = DOMElementsHelper
													.getUserPreferences("sidebarstate");
											if (stateObject === null) {
												stateObject = {};
											}
											if (stateObject[DOMElementsHelper
													.getLocation()] !== undefined
													&& stateObject[DOMElementsHelper
															.getLocation()] !== null
													&& stateObject[DOMElementsHelper
															.getLocation()] !== "") {
												if (stateObject[DOMElementsHelper
														.getLocation()][DOMElementsHelper.containerId] !== undefined
														&& stateObject[DOMElementsHelper
																.getLocation()][DOMElementsHelper.containerId] !== null
														&& stateObject[DOMElementsHelper
																.getLocation()][DOMElementsHelper.containerId] !== "") {
												} else {
													stateObject[DOMElementsHelper
															.getLocation()][DOMElementsHelper.containerId] = {};
												}
											} else {
												stateObject[DOMElementsHelper
														.getLocation()] = {};
												stateObject[DOMElementsHelper
														.getLocation()][DOMElementsHelper.containerId] = {};
											}
											stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId]["size"] = state.size;
											stateObject[DOMElementsHelper
													.getLocation()][DOMElementsHelper.containerId]["initClosed"] = "false";
											DOMElementsHelper
													.setUserPreferences({
														"sidebarstate" : stateObject
													});
										}
									}
								},
								ondrag_start : function() {
									DOMElementsHelper.replaceEditor(true);
								},
								ondrag_end : function() {
									DOMElementsHelper.replaceEditor(false);
								},
								spacing_closed : 0,
								spacing_open : 5,
								slidable : false,
								minSize : 145,
								size : initWidth
							}
						});
		if (DOMElementsHelper.config.enablestyletemplatepanel === undefined
				|| DOMElementsHelper.config.enablestyletemplatepanel == "true"
				|| DOMElementsHelper.config.enablestyletemplatepanel === true) {
			jQuery(".ui-layout-resizer").addClass("ui-widget-content");
			if (initClosedWest === false) {
				jQuery(
						"#" + DOMElementsHelper.containerId
								+ "_statusbar .styleTemplateButton > div")
						.addClass("highlight");
			}
		}
		if (this.detachedUI
				&& DOMElementsHelper.detachableUI.toolbar.options.draggable.enabled !== undefined
				&& (DOMElementsHelper.detachableUI.toolbar.options.draggable.enabled === "true" || DOMElementsHelper.detachableUI.toolbar.options.draggable.enabled === true)) {
			DOMElementsHelper.detachableUI.toolbar.options.draggable.options.handle = "#"
					+ DOMElementsHelper.containerId + "_ribbon_tab_container";
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer")
					.draggable(
							DOMElementsHelper.detachableUI.toolbar.options.draggable.options);
		}
		if (this.detachedUI
				&& DOMElementsHelper.detachableUI.toolbar.options.transparency.enabled !== undefined
				&& (DOMElementsHelper.detachableUI.toolbar.options.transparency.enabled === "true" || DOMElementsHelper.detachableUI.toolbar.options.transparency.enabled === true)) {
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer")
					.css(
							{
								"opacity" : DOMElementsHelper.detachableUI.toolbar.options.transparency.options.start
							});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer")
					.bind(
							"mouseenter",
							function() {
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_detachedToolBarContainer")
										.fadeTo(
												250,
												DOMElementsHelper.config.detachableUI.toolbar.options.transparency.options.end);
							});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer")
					.bind(
							"mouseleave",
							function() {
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_detachedToolBarContainer")
										.fadeTo(
												250,
												DOMElementsHelper.config.detachableUI.toolbar.options.transparency.options.start);
							});
		}
		if (this.detachedUI
				&& DOMElementsHelper.detachableUI.statusbar.options.draggable.enabled !== undefined
				&& (DOMElementsHelper.detachableUI.statusbar.options.draggable.enabled === "true" || DOMElementsHelper.detachableUI.statusbar.options.draggable.enabled === true)) {
			DOMElementsHelper.detachableUI.statusbar.options.draggable.options.handle = "#"
					+ DOMElementsHelper.containerId + "_statusbar table";
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer")
					.draggable(
							DOMElementsHelper.detachableUI.toolbar.options.draggable.options);
		}
		if (this.detachedUI
				&& DOMElementsHelper.detachableUI.statusbar.options.transparency.enabled !== undefined
				&& (DOMElementsHelper.detachableUI.statusbar.options.transparency.enabled === "true" || DOMElementsHelper.detachableUI.statusbar.options.transparency.enabled === true)) {
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer")
					.css(
							{
								"opacity" : DOMElementsHelper.detachableUI.statusbar.options.transparency.options.start
							});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer")
					.bind(
							"mouseenter",
							function() {
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_detachedStatusBarContainer")
										.fadeTo(
												250,
												DOMElementsHelper.config.detachableUI.statusbar.options.transparency.options.end);
							});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer")
					.bind(
							"mouseleave",
							function() {
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_detachedStatusBarContainer")
										.fadeTo(
												250,
												DOMElementsHelper.config.detachableUI.statusbar.options.transparency.options.start);
							});
		}
	};
	this.setStatusBar = function() {
		if (this.detachedUI
				&& DOMElementsHelper.detachableUI.statusbar.options.location !== undefined
				&& DOMElementsHelper.detachableUI.statusbar.options.location === "attachedToToolBar") {
			statusBarWidth = DOMElementsHelper.detachableUI.toolbar.options.width - 2;
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedToolBarContainer").append(
					"<div id=\"" + DOMElementsHelper.containerId
							+ "_statusbar\"></div>");
			jQuery("#" + DOMElementsHelper.containerId + "_statusbar").css({
				"border-top" : 0
			});
			jQuery("#" + DOMElementsHelper.containerId + "_statusbar")
					.addClass("ui-widget-header ui-corner-bottom statusBar");
		} else if (this.detachedUI
				&& DOMElementsHelper.detachableUI.statusbar.options.location !== undefined) {
			statusBarWidth = DOMElementsHelper.detachableUI.statusbar.options.width;
			jQuery(
					""
							+ DOMElementsHelper.detachableUI.statusbar.options.location)
					.append(
							"<div id=\""
									+ DOMElementsHelper.containerId
									+ "_detachedStatusBarContainer\" style=\""
									+ DOMElementsHelper.detachableUI.statusbar.options.style
									+ "\"></div>");
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer").append(
					"<div id=\"" + DOMElementsHelper.containerId
							+ "_statusbar\"></div>");
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer").css({
				width : DOMElementsHelper.detachableUI.statusbar.options.width
			});
			jQuery(
					"#" + DOMElementsHelper.containerId
							+ "_detachedStatusBarContainer").addClass(
					"eongmainstyles");
			jQuery("#" + DOMElementsHelper.containerId + "_statusbar").css({
				"border-top" : 0
			});
			jQuery("#" + DOMElementsHelper.containerId + "_statusbar")
					.addClass("ui-widget-header ui-corner-all statusBar");
		} else {
			statusBarWidth = DOMElementsHelper.editorWidth - 3;
			jQuery("#" + DOMElementsHelper.containerId).append(
					"<div id=\"" + DOMElementsHelper.containerId
							+ "_statusbar\"></div>");
			jQuery("#" + DOMElementsHelper.containerId + "_statusbar")
					.addClass("ui-widget-header ui-corner-bottom statusBar");
		}
		jQuery("#" + DOMElementsHelper.containerId + "_statusbar").css({
			"min-height" : "34px",
			"height" : "34px",
			width : statusBarWidth
		});
		jQuery
				.ajax({
					url : DOMElementsHelper.codebase
							+ "/../dialog/statusbar.html",
					cache : true,
					async : false,
					success : function(html) {
						var decreaseZoomIcon = DOMElementsHelper
								.resolveURL("../icons/decrease-zoom-small.png");
						var increaseZoomIcon = DOMElementsHelper
								.resolveURL("../icons/increase-zoom-small.png");
						var toggleSourceViewIcon = DOMElementsHelper
								.resolveURL("../icons/toggle-source-view-status-bar.png");
						var toggleStyleTemplatesIcon = DOMElementsHelper
								.resolveURL("../icons/style-templates-status-bar.png");
						if (DOMElementsHelper.isMSIE
								&& parseInt(DOMElementsHelper.BrowserVersion) < 7) {
							decreaseZoomIcon = DOMElementsHelper
									.resolveURL("../icons/gif/decrease-zoom-small.gif");
							increaseZoomIcon = DOMElementsHelper
									.resolveURL("../icons/gif/increase-zoom-small.gif");
							toggleSourceViewIcon = DOMElementsHelper
									.resolveURL("../icons/gif/toggle-source-view-status-bar.gif");
							toggleStyleTemplatesIcon = DOMElementsHelper
									.resolveURL("../icons/gif/style-templates-status-bar.gif");
						}
						jQuery(
								"#" + DOMElementsHelper.containerId
										+ "_statusbar").append(
								DOMElementsHelper.processTemplate(html));
						jQuery(
								"#" + DOMElementsHelper.containerId
										+ "_statusbar td").css({
							"min-height" : "30px",
							"height" : "30px"
						});
						if (DOMElementsHelper.config.charactercounter !== undefined
								&& DOMElementsHelper.config.charactercounter.enabled !== undefined
								&& DOMElementsHelper.config.charactercounter.enabled === "true") {
							var counterStr = "";
							if (DOMElementsHelper.config.charactercounter !== undefined
									&& DOMElementsHelper.config.charactercounter.limit !== undefined) {
								counterStr = "0 / "
										+ DOMElementsHelper.config.charactercounter.limit;
							} else {
								counterStr = "0";
							}
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .documentCounterDisplay")
									.html(counterStr);
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .documentCounterArea")
									.parent("td").css({
										display : "none"
									});
						}
						if (DOMElementsHelper.config.enablezoomarea !== undefined
								&& DOMElementsHelper.config.enablezoomarea == "false") {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .zoomArea").parent(
									"td").css({
								display : "none"
							});
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .zoomArea").parent(
									"td").html("");
						} else if (DOMElementsHelper.config.enablezoomarea === undefined
								|| DOMElementsHelper.config.enablezoomarea == "true") {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .zoomSlider")
									.slider(
											{
												value : 500,
												min : 50,
												max : 1000,
												step : 1,
												animate : true,
												start : function(event, ui) {
													noSlide = true;
												},
												slide : function(event, ui) {
													noSlide = false;
													if (ui.value >= 500) {
														valuePercentage = (ui.value - 500) / 500;
														newZoom = Math
																.round(100 + ((500 - 100) * valuePercentage));
													} else {
														valuePercentage = ui.value / 500;
														newZoom = Math
																.round(100 * valuePercentage);
													}
													DOMElementsHelper.jsObj
															.invokeAction(
																	"zoom",
																	newZoom
																			+ "%|noFocus");
												},
												stop : function(event, ui) {
													if (!noSlide) {
														if (ui.value >= 500) {
															valuePercentage = (ui.value - 500) / 500;
															newZoom = Math
																	.round(100 + ((500 - 100) * valuePercentage));
														} else {
															valuePercentage = ui.value / 500;
															newZoom = Math
																	.round(100 * valuePercentage);
														}
														DOMElementsHelper.jsObj
																.invokeAction(
																		"zoom",
																		newZoom
																				+ "%");
													}
												}
											});
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .ui-slider-handle")
									.attr(
											"title",
											DOMElementsHelper.LocaleObject.L_ZOOM_100_DBL_CLICK_INFO);
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .zoomSliderDecreaseButton")
									.append(
											'<div class="enabled ui-widget-header transparent-border"><button class="buttonImage editorAction_'
													+ DOMElementsHelper.containerId
													+ ' enabled" style="background-image: url('
													+ decreaseZoomIcon
													+ ');" title="'
													+ DOMElementsHelper.LocaleObject.L_DECREASE_ZOOM
													+ '" name="decrease-zoom" type="button"/></div>');
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .zoomSliderIncreaseButton")
									.append(
											'<div class="enabled ui-widget-header transparent-border"><button class="buttonImage editorAction_'
													+ DOMElementsHelper.containerId
													+ ' enabled" style="background-image: url('
													+ increaseZoomIcon
													+ ');" title="'
													+ DOMElementsHelper.LocaleObject.L_INCREASE_ZOOM
													+ '" name="increase-zoom" type="button"/></div>');
							var dropdownArray = [ "ww", "wh", "10%", "25%",
									"50%", "75%", "100%", "125%", "150%",
									"175%", "200%", "300%", "400%", "500%" ];
							jQuery("#" + DOMElementsHelper.containerId).append(
									"<div class=\"hidden\" id=\"zoomDropDownList_"
											+ DOMElementsHelper.containerId
											+ "\"><ul></ul></div>")
							var list = jQuery("#zoomDropDownList_"
									+ DOMElementsHelper.containerId + " ul");
							jQuery
									.each(
											dropdownArray,
											function(index, value) {
												var displayValue = value;
												var useValue = value;
												if (value === "ww") {
													useValue = -1;
													displayValue = DOMElementsHelper.LocaleObject.L_ZOOM_MODE_WINDOW_WIDTH;
												}
												if (value === "wh") {
													useValue = -2;
													displayValue = DOMElementsHelper.LocaleObject.L_ZOOM_MODE_WINDOW_HEIGHT;
												}
												list.append("<li name=\""
														+ value + "\" alt=\""
														+ value
														+ "\"><a href=\"#\">"
														+ displayValue
														+ "</a></li>");
											});
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .zoomValues").append(
									"<div style=\"margin-right: 5px; float: left;\" id=\"zoomDropDownContainer_"
											+ DOMElementsHelper.containerId
											+ "\"></div>");
							jQuery(
									"#zoomDropDownContainer_"
											+ DOMElementsHelper.containerId)
									.romenu(
											{
												content : jQuery(
														"#zoomDropDownList_"
																+ DOMElementsHelper.containerId)
														.html(),
												showSpeed : 200,
												height : 300,
												directionV : "up",
												iconDirection : "up",
												onSelect : function() {
													var newZoom = jQuery(this)
															.attr("alt");
													if (newZoom.indexOf("%") === -1
															&& newZoom !== "wh"
															&& newZoom !== "ww") {
														newZoom = newZoom + "%";
													}
													if (newZoom === "ww") {
														DOMElementsHelper.jsObj
																.invokeAction("zoom-mode-window-width");
													} else if (newZoom === "wh") {
														DOMElementsHelper.jsObj
																.invokeAction("zoom-mode-window-height");
													} else {
														DOMElementsHelper.jsObj
																.invokeAction(
																		"zoom",
																		newZoom);
													}
												},
												onComboChange : function() {
													var newZoom = jQuery(this)
															.val();
													if (newZoom.indexOf("%") === -1
															&& newZoom !== "wh"
															&& newZoom !== "ww") {
														newZoom = newZoom + "%";
													}
													if (newZoom === "ww"
															|| newZoom
																	.toLowerCase() === "window width") {
														DOMElementsHelper.jsObj
																.invokeAction("zoom-mode-window-width");
														jQuery(this).attr(
																"alt", "ww");
													} else if (newZoom === "wh"
															|| newZoom
																	.toLowerCase() === "window height") {
														DOMElementsHelper.jsObj
																.invokeAction("zoom-mode-window-height");
														jQuery(this).attr(
																"alt", "wh");
													} else {
														DOMElementsHelper.jsObj
																.invokeAction(
																		"zoom",
																		newZoom);
														jQuery(this).attr(
																"alt", newZoom);
													}
												},
												onShowDropDown : function() {
													DOMElementsHelper
															.replaceEditor(true);
												},
												onCloseDropDown : function() {
													DOMElementsHelper
															.replaceEditor(false);
												},
												combobox : true,
												comboboxName : "zoom",
												comboboxClass : "editorAction_"
														+ DOMElementsHelper.containerId
														+ " enabled",
												comboSize : 4,
												comboMaxLength : 4,
												comboWidth : 42,
												dropdownWidth : 100,
												comboAlign : "right"
											});
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .ui-slider-handle")
									.bind(
											"dblclick",
											function() {
												DOMElementsHelper.jsObj
														.invokeAction("zoom",
																100 + "%");
											});
						}
						if (DOMElementsHelper.config.resizable !== undefined
								&& DOMElementsHelper.config.resizable == "true") {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .resizerContainer")
									.append(
											"<div class=\"seHandle ui-resizable-handle ui-resizable-handle-se ui-icon ui-icon-gripsmall-diagonal-se\"></div>");
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .resizerContainer")
									.parent("td").css({
										"display" : "none"
									});
						}
						if (DOMElementsHelper.config.sourceview === undefined
								|| DOMElementsHelper.config.sourceview.enabled === undefined
								|| DOMElementsHelper.config.sourceview.enabled === true
								|| DOMElementsHelper.config.sourceview.enabled === "true") {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .sourceViewButton")
									.append(
											'<div class="enabled ui-widget-header"><button class="buttonImage editorAction_'
													+ DOMElementsHelper.containerId
													+ ' enabled" style="background-image: url('
													+ toggleSourceViewIcon
													+ ');" title="'
													+ DOMElementsHelper.LocaleObject.L_TOGGLE_SOURCE_VIEW
													+ '" name="toggle-source-view" type="button"/></div>');
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .sourceViewButton")
									.css({
										"display" : "none"
									});
						}
						if (DOMElementsHelper.config.enablestyletemplatepanel === undefined
								|| DOMElementsHelper.config.enablestyletemplatepanel == "true"
								|| DOMElementsHelper.config.enablestyletemplatepanel === true) {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .styleTemplateButton")
									.append(
											'<div class="enabled ui-widget-header"><button class="buttonImage enabled" style="background-image: url('
													+ toggleStyleTemplatesIcon
													+ ');" title="'
													+ DOMElementsHelper.LocaleObject.L_TOGGLE_STYLE_TEMPLATE_PANEL
													+ '" name="toggle-style-template-panel" type="button"/></div>');
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .styleTemplateButton button")
									.bind(
											"click",
											function() {
												DOMElementsHelper.editorLayout
														.toggle("west");
												if (!DOMElementsHelper.editorLayout.state.west.isClosed) {
													jQuery(this)
															.parent("div")
															.addClass(
																	"ui-state-active");
												} else {
													jQuery(this)
															.parent("div")
															.removeClass(
																	"ui-state-active");
												}
												DOMElementsHelper.jsWrapperObj
														.requestFocus();
											});
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .styleTemplateButton")
									.css({
										"display" : "none"
									});
						}
						if (DOMElementsHelper.config.languagebar !== undefined) {
							var languageActions = {
								"en-US" : DOMElementsHelper.LocaleObject.L_LANGUAGE_AMERICAN_ENGLISH,
								"en-US-x-legal" : DOMElementsHelper.LocaleObject.L_LANGUAGE_AMERICAN_LEGAL,
								"en-US-x-medical" : DOMElementsHelper.LocaleObject.L_LANGUAGE_AMERICAN_MEDICAL,
								"pt-BR" : DOMElementsHelper.LocaleObject.L_LANGUAGE_BRAZILIAN_PORTUGUESE,
								"en-GB" : DOMElementsHelper.LocaleObject.L_LANGUAGE_BRITISH_ENGLISH,
								"en-GB-x-legal" : DOMElementsHelper.LocaleObject.L_LANGUAGE_BRITISH_LEGAL,
								"en-GB-x-medical" : DOMElementsHelper.LocaleObject.L_LANGUAGE_BRITISH_MEDICAL,
								"en-CA" : DOMElementsHelper.LocaleObject.L_LANGUAGE_CANADIAN_ENGLISH,
								"da-DK" : DOMElementsHelper.LocaleObject.L_LANGUAGE_DANISH,
								"nl-NL" : DOMElementsHelper.LocaleObject.L_LANGUAGE_DUTCH,
								"fi-FI" : DOMElementsHelper.LocaleObject.L_LANGUAGE_FINNISH,
								"fr-FR" : DOMElementsHelper.LocaleObject.L_LANGUAGE_FRENCH,
								"de-DE" : DOMElementsHelper.LocaleObject.L_LANGUAGE_GERMAN,
								"it-IT" : DOMElementsHelper.LocaleObject.L_LANGUAGE_ITALIAN,
								"no-NO" : DOMElementsHelper.LocaleObject.L_LANGUAGE_NORWEGIAN,
								"pt-PT" : DOMElementsHelper.LocaleObject.L_LANGUAGE_PORTUGUESE,
								"es-ES" : DOMElementsHelper.LocaleObject.L_LANGUAGE_SPANISH,
								"sv-SE" : DOMElementsHelper.LocaleObject.L_LANGUAGE_SWEDISH,
								"" : DOMElementsHelper.LocaleObject.L_LANGUAGE_NONE
							};
							var dropDownContent = [];
							var actionProperties = "";
							var cType = "json";
							jQuery.each(languageActions, function(
									dropdownIndex, dropdownValue) {
								var itemValues = [];
								itemValues.push(dropdownIndex);
								itemValues.push(dropdownValue);
								dropDownContent.push(itemValues);
							});
							if (DOMElementsHelper.config.languagebar.documentlanguage !== undefined
									&& DOMElementsHelper.config.languagebar.documentlanguage.enabled === "true") {
								var comboWidth = 65;
								if (DOMElementsHelper.config.languagebar.documentlanguage.combowidth !== undefined) {
									comboWidth = parseInt(DOMElementsHelper.config.languagebar.documentlanguage.combowidth);
								}
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_statusbar .languageBar")
										.append(
												"<div style=\"margin-right: 5px; float: left;\" id=\"documentLanguageDropDownContainer_"
														+ DOMElementsHelper.containerId
														+ "\"></div>");
								jQuery(
										"#documentLanguageDropDownContainer_"
												+ DOMElementsHelper.containerId)
										.romenu(
												{
													content : dropDownContent,
													contentType : cType,
													showSpeed : 200,
													height : 300,
													directionV : "up",
													iconDirection : "up",
													onSelect : function() {
														var documentLanguage = jQuery(
																this).attr(
																"alt");
														DOMElementsHelper.jsObj
																.invokeAction(
																		"document-language",
																		documentLanguage);
													},
													onComboChange : function() {
														var documentLanguage = jQuery(
																this).val();
														DOMElementsHelper.jsObj
																.invokeAction(
																		"document-language",
																		documentLanguage);
													},
													onShowDropDown : function() {
														DOMElementsHelper
																.replaceEditor(true);
													},
													onCloseDropDown : function() {
														DOMElementsHelper
																.replaceEditor(false);
													},
													combobox : true,
													comboboxName : "document-language",
													comboboxTitle : DOMElementsHelper.LocaleObject.L_CHANGE_DOCUMENT_LANGUAGE,
													comboboxClass : "editorAction_"
															+ DOMElementsHelper.containerId
															+ " enabled",
													comboWidth : comboWidth,
													dropdownWidth : 130,
													comboAlign : "left"
												});
							}
							if (DOMElementsHelper.config.languagebar.fragmentlanguage !== undefined
									&& DOMElementsHelper.config.languagebar.fragmentlanguage.enabled === "true") {
								var comboWidth = 65;
								if (DOMElementsHelper.config.languagebar.fragmentlanguage.combowidth !== undefined) {
									comboWidth = parseInt(DOMElementsHelper.config.languagebar.fragmentlanguage.combowidth);
								}
								jQuery(
										"#" + DOMElementsHelper.containerId
												+ "_statusbar .languageBar")
										.append(
												"<div style=\"margin-right: 5px; float: left;\" id=\"fragmentLanguageDropDownContainer_"
														+ DOMElementsHelper.containerId
														+ "\"></div>");
								jQuery(
										"#fragmentLanguageDropDownContainer_"
												+ DOMElementsHelper.containerId)
										.romenu(
												{
													content : dropDownContent,
													contentType : cType,
													showSpeed : 200,
													height : 300,
													directionV : "up",
													iconDirection : "up",
													onSelect : function() {
														var fragmentLanguage = jQuery(
																this).attr(
																"alt");
														DOMElementsHelper.jsObj
																.invokeAction(
																		"live-fragment-language",
																		fragmentLanguage);
													},
													onComboChange : function() {
														var fragmentLanguage = jQuery(
																this).val();
														DOMElementsHelper.jsObj
																.invokeAction(
																		"live-fragment-language",
																		fragmentLanguage);
													},
													onShowDropDown : function() {
														DOMElementsHelper
																.replaceEditor(true);
													},
													onCloseDropDown : function() {
														DOMElementsHelper
																.replaceEditor(false);
													},
													combobox : true,
													comboboxName : "live-fragment-language",
													comboboxTitle : DOMElementsHelper.LocaleObject.L_CHANGE_FRAGMENT_LANGUAGE,
													comboboxClass : "editorAction_"
															+ DOMElementsHelper.containerId
															+ " enabled",
													comboWidth : comboWidth,
													dropdownWidth : 130,
													comboAlign : "left"
												});
							}
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .languageBar")
									.parents(".statusBarCell").css({
										"display" : "none"
									});
						}
						var buttonContainerElements = jQuery(
								"#" + DOMElementsHelper.containerId
										+ "_statusbar .buttonContainer tr")
								.children("td");
						var hideContainer = true;
						jQuery.each(buttonContainerElements, function(index,
								value) {
							if (jQuery(value).css("display") !== "none") {
								hideContainer = false;
							}
						});
						if (hideContainer) {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .buttonContainer")
									.parent("td").css({
										"display" : "none"
									});
						}
						var statusBarReduceWidth = jQuery(
								"#" + DOMElementsHelper.containerId
										+ "_statusbar .buttonContainer")
								.outerWidth(true) + 6;
						statusBarReduceWidth += ((jQuery("#"
								+ DOMElementsHelper.containerId
								+ "_statusbar .buttonContainer td").length + 1) * 2) + 2;
						if (DOMElementsHelper.config.enablezoomarea === undefined
								|| DOMElementsHelper.config.enablezoomarea == "true") {
							statusBarReduceWidth += 246;
						}
						if (DOMElementsHelper.config.charactercounter !== undefined
								&& DOMElementsHelper.config.charactercounter.enabled !== undefined
								&& DOMElementsHelper.config.charactercounter.enabled === "true") {
							statusBarReduceWidth += jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .documentCounterArea")
									.outerWidth(true) + 6;
						}
						if (DOMElementsHelper.config.resizable !== undefined
								&& DOMElementsHelper.config.resizable == "true") {
							statusBarReduceWidth += jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .resizerContainer")
									.outerWidth(true) + 6;
						}
						if (DOMElementsHelper.config.languagebar !== undefined) {
							statusBarReduceWidth += jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .languageBar")
									.outerWidth(true) + 6;
						}
						if (DOMElementsHelper.config.enablepagecountarea !== undefined
								&& DOMElementsHelper.config.enablepagecountarea == "true") {
							statusBarReduceWidth += jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .pageCounter")
									.outerWidth(true) + 6;
						} else {
							jQuery(
									"#" + DOMElementsHelper.containerId
											+ "_statusbar .pageCounter")
									.parent("td").css({
										"display" : "none"
									});
						}
						statusBarReduceWidth += 40;
						if (DOMElementsHelper.config.enabledocumentpalette === undefined
								|| DOMElementsHelper.config.enabledocumentpalette === "false") {
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .documentPaletteContainer")
									.parents(".statusBarCell").css({
										"visibility" : "hidden"
									});
							jQuery(
									"#"
											+ DOMElementsHelper.containerId
											+ "_statusbar .documentPaletteNavLeft, #"
											+ DOMElementsHelper.containerId
											+ "_statusbar .documentPaletteNavRight")
									.css({
										"visibility" : "hidden"
									});
						}
					},
					error : function(request, error, arg) {
						DOMElementsLogger.log("Failed to load status bar: "
								+ error, "SEVERE", this);
					}
				});
	};
};
eongApplication.dialogMap = function() {
	this.dialogMap = {
		"backgroundColor" : "../dialog/backgroundColor.html",
		"cellProperties" : "../dialog/cellProperties.html",
		"changeCase" : "../dialog/changeCase.html",
		"changeLanguage" : "../dialog/changeLanguage.html",
		"columnProperties" : "../dialog/columnProperties.html",
		"documentStatistics" : "../dialog/documentStatistics.html",
		"editAnnotation" : "../dialog/editAnnotation.html",
		"generalColor" : "../dialog/generalColor.html",
		"hrProperties" : "../dialog/hrProperties.html",
		"imageProperties" : "../dialog/imageProperties.html",
		"insertAnnotation" : "../dialog/insertAnnotation.html",
		"insertHyperlink" : "../dialog/insertHyperlink.html",
		"insertImage" : "../dialog/insertImage.html",
		"insertObject" : "../dialog/insertObject.html",
		"insertSpecialChar" : "../dialog/insertSpecialChar.html",
		"insertTable" : "../dialog/insertTable.html",
		"linkProperties" : "../dialog/linkProperties.html",
		"loadURL" : "../dialog/loadURL.html",
		"objectProperties" : "../dialog/objectProperties.html",
		"rowProperties" : "../dialog/rowProperties.html",
		"splitCell" : "../dialog/splitCell.html",
		"tableProperties" : "../dialog/tableProperties.html",
		"textColor" : "../dialog/textColor.html",
		"pageProperties" : "../dialog/pageProperties.html",
		"insertCrossreference" : "../dialog/insertCrossreference.html",
		"editCrossreference" : "../dialog/editCrossreference.html",
		"insertBookmark" : "../dialog/insertBookmark.html",
		"insertStructureTemplate" : "../dialog/insertStructureTemplate.html",
		"compareDocuments" : "../dialog/compareDocuments.html",
		"documentProperties" : "../dialog/documentProperties.html",
		"headerFooter" : "../dialog/headerFooter.html",
		"pageProperties" : "../dialog/pageProperties.html"
	};
	this.getDialogMap = function() {
		return this.dialogMap;
	}
}
eongApplication.Helper = function(width, height, appletName, id, jsObjName,
		jsObj) {
	this.initialized = false;
	this.containerId = id;
	this.actions = {};
	this.id = this.containerId + "_eong";
	this.editorWidth = width;
	this.editorHeight = height;
	this.appletName = appletName;
	this.jsObjName = jsObjName;
	this.jsObj = jsObj;
	this.testValue = appletName;
	this.isStartFullscreen = false;
	this.isFullscreenMode = false;
	this.isJREAutoDownloadEnabled = false;
	this.jreAutoDownloadURL = "http://java.sun.com/update/1.7.0/jinstall-7u45-windows-i586.cab";
	this.jreMinVersion = "";
	this.OBJECT_TAG = 0;
	this.APPLET_TAG = 1;
	this.tagStyle = this.OBJECT_TAG;
	this.archive = "eong.jar";
	this.codebase = "";
	this.code = "com.realobjects.eong.Main";
	this.params = "";
	this.attribs = "";
	this.isMac = false;
	this.isWindows = false;
	this.isLinux = false;
	this.isMSIE = false;
	this.isSafari = false;
	this.isOpera = false;
	this.isFirefox = false;
	this.isChrome = false;
	this.BrowserVersion = -1;
	this.obj = null;
	this.actions = {};
	this.uiconfig = "";
	this.config = "";
	this.iconRepositoryURL = "";
	this.BrowserVersion = jQuery.browser.version;
	if (this.isMSIE) {
		language = navigator.browserLanguage;
	} else {
		language = navigator.language;
	}
	switch (language) {
	case "de":
		this.browserLocale = "de-DE";
		break;
	case "fr":
		this.browserLocale = "fr-FR";
		break;
	case "es":
		this.browserLocale = "es-ES";
		break;
	default:
		this.browserLocale = "en-US";
	}
	this.localeCode = this.browserLocale;
	this.localeURL = "";
	this.LocaleObject = null;
	this.ActionMap = null;
	this.DialogMap = null;
	this.DialogHTMLMap = {};
	this.JSActionMap = {};
	this.enablePack200 = true;
	this.pack200 = "-Djnlp.packEnabled=true ";
	this.maxMemory = "-Xmx256m";
	this.currentPaletteScrollValue = 0;
	this.maxScrollValue = 0;
	this.scrollSpeed = 1;
	this.defaultColors = {
		"COLOR_WHITE" : {
			"value" : "#ffffff",
			"locale" : "L_COLOR_WHITE"
		},
		"COLOR_SILVER" : {
			"value" : "#c0c0c0",
			"locale" : "L_COLOR_SILVER"
		},
		"COLOR_GRAY" : {
			"value" : "#808080",
			"locale" : "L_COLOR_GRAY"
		},
		"COLOR_BLACK" : {
			"value" : "#000000",
			"locale" : "L_COLOR_BLACK"
		},
		"COLOR_NAVY" : {
			"value" : "#000080",
			"locale" : "L_COLOR_NAVY"
		},
		"COLOR_BLUE" : {
			"value" : "#0000ff",
			"locale" : "L_COLOR_BLUE"
		},
		"COLOR_AQUA" : {
			"value" : "#00ffff",
			"locale" : "L_COLOR_AQUA"
		},
		"COLOR_TEAL" : {
			"value" : "#008080",
			"locale" : "L_COLOR_TEAL"
		},
		"COLOR_PURPLE" : {
			"value" : "#800080",
			"locale" : "L_COLOR_PURPLE"
		},
		"COLOR_FUCHSIA" : {
			"value" : "#ff00ff",
			"locale" : "L_COLOR_FUCHSIA"
		},
		"COLOR_LIME" : {
			"value" : "#00ff00",
			"locale" : "L_COLOR_LIME"
		},
		"COLOR_GREEN" : {
			"value" : "#008000",
			"locale" : "L_COLOR_GREEN"
		},
		"COLOR_MAROON" : {
			"value" : "#800000",
			"locale" : "L_COLOR_MAROON"
		},
		"COLOR_RED" : {
			"value" : "#ff0000",
			"locale" : "L_COLOR_RED"
		},
		"COLOR_ORANGE" : {
			"value" : "#ffA500",
			"locale" : "L_COLOR_ORANGE"
		},
		"COLOR_YELLOW" : {
			"value" : "#ffff00",
			"locale" : "L_COLOR_YELLOW"
		},
		"COLOR_OLIVE" : {
			"value" : "#808000",
			"locale" : "L_COLOR_OLIVE"
		}
	};
	this.pageSizes = {
		"A3" : {
			"width" : 29.7,
			"height" : 42,
			"units" : [ "cm", "mm" ]
		},
		"A4" : {
			"width" : 21,
			"height" : 29.7,
			"units" : [ "cm", "mm" ]
		},
		"A5" : {
			"width" : 14.8,
			"height" : 21,
			"units" : [ "cm", "mm" ]
		},
		"A6" : {
			"width" : 10.5,
			"height" : 14.8,
			"units" : [ "cm", "mm" ]
		},
		"B4" : {
			"width" : 25,
			"height" : 35.3,
			"units" : [ "cm", "mm" ]
		},
		"B5" : {
			"width" : 17.6,
			"height" : 25,
			"units" : [ "cm", "mm" ]
		},
		"B6" : {
			"width" : 12.5,
			"height" : 17.6,
			"units" : [ "cm", "mm" ]
		},
		"Letter" : {
			"width" : 8.5,
			"height" : 11,
			"units" : [ "in" ]
		},
		"Legal" : {
			"width" : 8.5,
			"height" : 14,
			"units" : [ "in" ]
		},
		"Ledger" : {
			"width" : 11,
			"height" : 17,
			"units" : [ "in" ]
		},
		"Invoice" : {
			"width" : 5.5,
			"height" : 8,
			"units" : [ "in" ]
		}
	}
	this.template = "";
	this.templateURL = "";
	this.dialogExtensionURL = "";
	this.actionExtensionURL = "";
	this.localeExtensionObject = {};
	this.extensionDirectoryURL = "";
	this.fontNamesTemp = null;
	this.intrusiveJSLogging = false;
	this.jsWrapperObj = null;
	this.dtabs = {};
	this.checkConfig = function(jsonString) {
		var config;
		if (jsonString !== undefined && jsonString !== null
				&& jsonString !== "") {
			config = jQuery.secureEvalJSON(jsonString);
		} else {
			config = {};
			config.warnempty = "true";
		}
		if (config.fontsettings === undefined) {
			config.fontsettings = {
				"usesystemfonts" : "false",
				"fontlist" : [ {
					"family" : "Arial, Helvetica, sans-serif",
					"displayname" : "Arial"
				}, {
					"family" : "Times New Roman, Times",
					"displayname" : "Times"
				}, {
					"family" : "Courier New, Courier",
					"displayname" : "Courier"
				} ]
			};
		}
		if (config.specialcharacterdialog === undefined) {
			config.specialcharacterdialog = {
				"unicodeblocks" : [ "Basic Latin", "Latin-1 Supplement",
						"Latin Extended-A", "Latin Extended-B",
						"IPA Extensions", "Spacing Modifier Letters",
						"Combining Diacritical Marks", "Greek and Coptic",
						"Cyrillic", "Cyrillic Supplement", "Armenian",
						"Hebrew", "Arabic", "Syriac", "Arabic Supplement",
						"Thaana", "N'Ko", "Samaritan", "Mandaic", "Devanagari",
						"Bengali", "Gurmukhi", "Gujarati", "Oriya", "Tamil",
						"Telugu", "Kannada", "Malayalam", "Sinhala", "Thai",
						"Lao", "Tibetan", "Myanmar", "Georgian", "Hangul Jamo",
						"Ethiopic", "Ethiopic Supplement", "Cherokee",
						"Unified Canadian Aboriginal Syllabics", "Ogham",
						"Runic", "Tagalog", "Hanunoo", "Buhid", "Tagbanwa",
						"Khmer", "Mongolian",
						"Unified Canadian Aboriginal Syllabics Extended",
						"Limbu", "Tai Le", "New Tai Lue", "Khmer Symbols",
						"Buginese", "Tai Tham", "Balinese", "Sundanese",
						"Batak", "Lepcha", "Ol Chiki", "Vedic Extensions",
						"Phonetic Extensions",
						"Phonetic Extensions Supplement",
						"Combining Diacritical Marks Supplement",
						"Latin Extended Additional", "Greek Extended",
						"General Punctuation", "Superscripts and Subscripts",
						"Currency Symbols",
						"Combining Diacritical Marks for Symbols",
						"Letterlike Symbols", "Number Forms", "Arrows",
						"Mathematical Operators", "Miscellaneous Technical",
						"Control Pictures", "Optical Character Recognition",
						"Enclosed Alphanumerics", "Box Drawing",
						"Block Elements", "Geometric Shapes",
						"Miscellaneous Symbols", "Dingbats",
						"Miscellaneous Mathematical Symbols-A",
						"Supplemental Arrows-A", "Braille Patterns",
						"Supplemental Arrows-B",
						"Miscellaneous Mathematical Symbols-B",
						"Supplemental Mathematical Operators",
						"Miscellaneous Symbols and Arrows", "Glagolitic",
						"Latin Extended-C", "Coptic", "Georgian Supplement",
						"Tifinagh", "Ethiopic Extended", "Cyrillic Extended-A",
						"Supplemental Punctuation", "CJK Radicals Supplement",
						"Kangxi Radicals",
						"Ideographic Description Characters",
						"CJK Symbols and Punctuation", "Hiragana", "Katakana",
						"Bopomofo", "Hangul Compatibility Jamo", "Kanbun",
						"Bopomofo Extended", "CJK Strokes",
						"Katakana Phonetic Extensions",
						"Enclosed CJK Letters and Months", "CJK Compatibility",
						"CJK Unified Ideographs Extension A",
						"Yijing Hexagram Symbols", "CJK Unified Ideographs",
						"Yi Syllables", "Yi Radicals", "Lisu", "Vai",
						"Cyrillic Extended-B", "Bamum",
						"Modifier Tone Letters", "Latin Extended-D",
						"Syloti Nagri", "Common Indic Number Forms",
						"Phags-pa", "Saurashtra", "Devanagari Extended",
						"Kayah Li", "Rejang", "Hangul Jamo Extended-A",
						"Javanese", "Cham", "Myanmar Extended-A", "Tai Viet",
						"Ethiopic Extended-A", "Meetei Mayek",
						"Hangul Syllables", "Hangul Jamo Extended-B",
						"High Surrogates", "High Private Use Surrogates",
						"Low Surrogates", "Private Use Area",
						"CJK Compatibility Ideographs",
						"Alphabetic Presentation Forms",
						"Arabic Presentation Forms-A", "Variation Selectors",
						"Vertical Forms", "Combining Half Marks",
						"CJK Compatibility Forms", "Small Form Variants",
						"Arabic Presentation Forms-B",
						"Halfwidth and Fullwidth Forms", "Specials", "All" ]
			}
		}
		return config = jQuery.toJSON(config);
	}
	this.parseNumber = function(num) {
		var ret = Number(num);
		if (ret != isNaN(ret)) {
			return num;
		} else {
			return ret;
		}
	};
	this.cancelBackspace = function(event) {
		if (event.target.nodeName !== "INPUT"
				&& event.target.nodeName !== "TEXTAREA"
				&& event.target.nodeName !== "APPLET") {
			if (event.keyCode == 8) {
				return false;
			}
		}
		return event;
	};
	this.containerHeight = this.parseNumber(this.editorHeight);
	this.containerWidth = this.parseNumber(this.editorWidth);
	if (!isNaN(this.containerHeight)) {
		this.containerHeight += "px";
	}
	this.generateKey = function(prefix) {
		prefix += this.appletName;
		return prefix;
	};
	this.addAttribute = function(sName, sVal) {
		this.attribs += ' ' + sName + '="' + sVal + '"';
	};
	this.setParam = function(name, value) {
		this.params += "<param name='" + name + "' value='" + value + "' />";
	};
	this.formatString = function(str) {
		var str = str.replace(/\'/g, '\\\'');
		str = str.replace(/\n/g, '');
		return str;
	};
	this.getOSInfo = function() {
		var platform = navigator.platform;
		this.isWindows = /Win/.test(platform);
		this.isMac = /Mac/.test(platform);
		this.isLinux = /Linux/.test(platform);
		var ua = navigator.userAgent;
		var ve = navigator.vendor;
		this.isWebKit = /WebKit/.test(ua);
		this.isChrome = /Chrome/.test(ua);
		this.isOpera = window.opera !== undefined;
		this.isMSIE = /MSIE/.test(ua) || /Trident/.test(ua);
		this.isFirefox = /Firefox/.test(ua);
	};
	this.toggleButtonHover = function(element, classname) {
		jQuery(element).bind('mouseover', function(e) {
			if (!jQuery(this).hasClass("disabled")) {
				jQuery(this).addClass(classname);
			}
		});
		jQuery(element).bind('mouseout', function(e) {
			if (!jQuery(this).hasClass("disabled")) {
				jQuery(this).removeClass(classname);
			}
		});
	};
	this.processTemplate = function(input) {
		var parsedHTML = input.replace(/\{containerId\}/g, this.containerId);
		var matchLocales = parsedHTML.match(/\[.*\]/g);
		var matchLocalesInQuotes = parsedHTML.match(/\"\{.*\}\"/g);
		var localeStr = null;
		var localeString = null;
		var replaceSearch = null;
		var testMatch = null;
		var processTemplateHelper = this;
		if (matchLocales !== undefined && matchLocales !== null) {
			jQuery.each(matchLocales, function(index, value) {
				localeStr = value.replace(/\[/, "");
				localeStr = localeStr.replace(/\]/, "");
				localeString = processTemplateHelper.LocaleObject[localeStr];
				if (localeString === undefined) {
					localeString = localeStr;
				}
				replaceSearch = eval("/\\[" + localeStr + "\\]/");
				testMatch = parsedHTML.match(replaceSearch);
				parsedHTML = parsedHTML.replace(replaceSearch, localeString);
			});
		}
		if (matchLocalesInQuotes !== undefined && matchLocalesInQuotes !== null) {
			jQuery.each(matchLocalesInQuotes, function(index, value) {
				localeStr = value.replace(/\"\{/, "");
				localeStr = localeStr.replace(/\}\"/, "");
				localeString = processTemplateHelper.LocaleObject[localeStr];
				if (localeString === undefined) {
					localeString = localeStr;
				}
				replaceSearch = eval("/\\{" + localeStr + "\\}/");
				testMatch = parsedHTML.match(replaceSearch);
				parsedHTML = parsedHTML.replace(replaceSearch, localeString);
			});
		}
		return parsedHTML;
	};
	this.resolveURL = function(url) {
		return this.resolveURLInternal(url, this.codebase, false)
	};
	this.resolveURLAgainstDocBase = function(url, forceBaseHost) {
		return this.resolveURLInternal(url, document.URL.substring(0,
				document.URL.lastIndexOf("/") + 1), forceBaseHost)
	}
	this.resolveURLInternal = function(url, baseurl, forceBaseHost) {
		if (url.indexOf("://") > -1) {
			if (forceBaseHost === undefined || !forceBaseHost) {
				return this.flattenPath(url);
			}
			url = url.substring(url.indexOf("/", url.indexOf("://") + 3));
		}
		if (url.indexOf("/") == 0) {
			baseurl = baseurl.substring(0, (baseurl.indexOf("/", baseurl
					.indexOf("://") + 3)));
		} else if (baseurl.lastIndexOf("/") != (baseurl.length - 1)) {
			baseurl += "/";
		}
		url = baseurl + url;
		return this.flattenPath(url);
	}
	this.flattenPath = function(path) {
		while ((p = path.indexOf("/../")) > -1) {
			path = path.substring(0, path.substring(0, p).lastIndexOf("/"))
					+ path.substring(p + 3);
		}
		return path
	}
	this.escapeSingleQuotes = function(string) {
		var replaced = string.replace(/\'/g, "&#39;");
		return replaced;
	};
	this.setLocaleObject = function() {
		var setLocaleHelper = this;
		if (this.localeURL !== "") {
			localeURLHelper = this.resolveURL(this.localeURL);
			jQuery
					.ajax({
						dataType : "text",
						async : false,
						url : localeURLHelper,
						success : function(json) {
							setLocaleHelper.LocaleObject = jQuery
									.secureEvalJSON(json);
						},
						error : function(errormsg) {
							jQuery
									.ajax({
										dataType : "text",
										async : false,
										url : setLocaleHelper.codebase
												+ "/../locale/"
												+ setLocaleHelper.localeCode
												+ ".json",
										success : function(json) {
											setLocaleHelper.LocaleObject = jQuery
													.secureEvalJSON(json);
											setLocaleHelper
													.extendLocaleObject(setLocaleHelper.localeCode);
										},
										error : function(errormsg) {
											jQuery
													.ajax({
														dataType : "text",
														async : false,
														url : setLocaleHelper.codebase
																+ "/../locale/en-US.json",
														success : function(json) {
															setLocaleHelper.LocaleObject = jQuery
																	.secureEvalJSON(json);
															setLocaleHelper
																	.extendLocaleObject("en-US");
														},
														error : function(
																errormsg) {
														}
													});
										}
									});
						}
					});
		} else {
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : setLocaleHelper.codebase + "/../locale/"
						+ setLocaleHelper.localeCode + ".json",
				success : function(json) {
					setLocaleHelper.LocaleObject = jQuery.secureEvalJSON(json);
					setLocaleHelper
							.extendLocaleObject(setLocaleHelper.localeCode);
				},
				error : function(errormsg) {
					jQuery.ajax({
						dataType : "text",
						async : false,
						url : setLocaleHelper.codebase
								+ "/../locale/en-US.json",
						success : function(json) {
							setLocaleHelper.LocaleObject = jQuery
									.secureEvalJSON(json);
							setLocaleHelper.extendLocaleObject("en-US");
						},
						error : function(errormsg) {
						}
					});
				}
			});
		}
	};
	this.extendLocaleObject = function(localeCode) {
		if (this.localeExtensionObject[localeCode] !== undefined
				&& this.localeExtensionObject[localeCode] !== "") {
			var extURL = this
					.resolveURL(this.localeExtensionObject[localeCode]);
			var extendLocaleHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extURL,
				success : function(json) {
					json = jQuery.secureEvalJSON(extendLocaleHelper
							.escapeSingleQuotes(json));
					jQuery.each(json, function(key, value) {
						extendLocaleHelper.LocaleObject[key] = value;
					});
				},
				error : function(errormsg) {
					extendLocaleHelper.jsObj.Logger.log(
							"[extendLocaleObject]: The locale extension file for locale code "
									+ localeCode + " could not be found at: "
									+ extURL, "WARNING", this);
				}
			});
		} else if (this.extensionDirectoryURL !== "") {
			var extDir = this.resolveURL(this.extensionDirectoryURL);
			var extendLocaleHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extDir + "/" + localeCode + ".ext.json",
				success : function(json) {
					json = jQuery.secureEvalJSON(extendLocaleHelper
							.escapeSingleQuotes(json));
					jQuery.each(json, function(key, value) {
						extendLocaleHelper.LocaleObject[key] = value;
					});
				},
				error : function(errormsg) {
					extendLocaleHelper.jsObj.Logger.log(
							"[extendLocaleObject]: The locale extension file for locale code "
									+ localeCode + " could not be found at: "
									+ extDir + "/" + localeCode + ".ext.json",
							"WARNING", this);
				}
			});
		}
	};
	this.setActionMap = function() {
		var setActionMapHelper = this;
		this.ActionMap = jsObj.ActionMap.getActionMap();
		this.extendActionMap();
		var tmpJson = jQuery.toJSON(setActionMapHelper.ActionMap);
		tmpJson = tmpJson.replace(/\r/g, '');
		tmpJson = tmpJson.replace(/\n/g, '');
		tmpJson = tmpJson.replace(/\t/g, '');
		this.setParam("ACTIONMAP", tmpJson);
	};
	this.extendActionMap = function() {
		if (this.actionExtensionURL !== "") {
			var extURL = this.resolveURL(this.actionExtensionURL);
			var extendActionHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extURL,
				success : function(json) {
					json = jQuery.secureEvalJSON(json);
					jQuery.each(json, function(key, value) {
						if (extendActionHelper.ActionMap[key] === undefined) {
							extendActionHelper.ActionMap[key] = {};
						}
						jQuery.each(value, function(key2, value2) {
							extendActionHelper.ActionMap[key][key2] = value2;
						});
					});
				},
				error : function(errormsg) {
					extendActionHelper.jsObj.Logger.log(
							"[extendActionMap]: The action extension file could not be found at: "
									+ extURL, "WARNING", this);
				}
			});
		} else if (this.extensionDirectoryURL !== "") {
			var extDir = this.resolveURL(this.extensionDirectoryURL);
			var extendActionHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extDir + "/actionmap.ext.json",
				success : function(json) {
					json = jQuery.secureEvalJSON(json);
					jQuery.each(json, function(key, value) {
						extendActionHelper.ActionMap[key] = {};
						jQuery.each(value, function(key2, value2) {
							extendActionHelper.ActionMap[key][key2] = value2;
						});
					});
				},
				error : function(errormsg) {
					extendActionHelper.jsObj.Logger.log(
							"[extendActionMap]: The action extension file could not be found at: "
									+ extDir + "/actionmap.ext.json",
							"WARNING", this);
				}
			});
		}
	};
	this.setDialogMap = function() {
		var setDialogMapHelper = this;
		this.DialogMap = jsObj.DialogMap.getDialogMap();
		this.extendDialogMap();
	};
	this.inArray = function(array, value) {
		if (!(array instanceof Array)) {
			array = [];
		}
		value = value || 0;
		for (var i = 0, len = array.length; i < len; ++i) {
			if (array[i] == value) {
				return true;
			}
		}
		return false;
	};
	this.extendDialogMap = function() {
		if (this.dialogExtensionURL !== "") {
			var extURL = this.resolveURL(this.dialogExtensionURL);
			var extendDialogHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extURL,
				success : function(json) {
					json = jQuery.secureEvalJSON(json);
					jQuery.each(json, function(key, value) {
						extendDialogHelper.DialogMap[key] = {};
						jQuery.each(value, function(key2, value2) {
							extendDialogHelper.DialogMap[key][key2] = value2;
						});
					});
				},
				error : function(errormsg) {
					extendDialogHelper.jsObj.Logger.log(
							"[extendDialogMap]: The dialog extension file could not be found at: "
									+ extURL, "WARNING", this);
				}
			});
		} else if (this.extensionDirectoryURL !== "") {
			var extDir = this.resolveURL(this.extensionDirectoryURL);
			var extendDialogHelper = this;
			jQuery.ajax({
				dataType : "text",
				async : false,
				url : extDir + "/dialogmap.ext.json",
				success : function(json) {
					json = jQuery.secureEvalJSON(json);
					jQuery.each(json, function(key, value) {
						extendDialogHelper.DialogMap[key] = {};
						jQuery.each(value, function(key2, value2) {
							extendDialogHelper.DialogMap[key][key2] = value2;
						});
					});
				},
				error : function(errormsg) {
					extendDialogHelper.jsObj.Logger.log(
							"[extendDialogMap]: The dialog extension file could not be found at: "
									+ extDir + "/dialogmap.ext.json",
							"WARNING", this);
				}
			});
		}
	};
	this.parseStructureTemplates = function() {
		var tree = "";
		var currentContext = this.jsObj.getObj().getContextNames();
		if (currentContext === "") {
			currentContext = [];
		} else {
			currentContext = jQuery.evalJSON(currentContext);
		}
		if (this.structureTemplateConfig !== undefined
				&& this.structureTemplateConfig !== "") {
			tree = "<ul class=\"filetree\"><li>"
					+ this.parseRecursiveST(this.structureTemplateConfig,
							currentContext) + "</li></ul>";
		}
		return tree;
	};
	this.parseRecursiveST = function(json, currentContext) {
		var parseStructureTemplatesHelper = this;
		var tree = "";
		jQuery
				.each(
						json,
						function(index, value) {
							if (index === "templateArray") {
								tree += "<ul class=\"fileList\">"
								jQuery
										.each(
												value,
												function(arrayIndex, arrayValue) {
													jQuery
															.each(
																	arrayValue,
																	function(
																			templateObjectIndex,
																			templateObjectValue) {
																		var uid = templateObjectIndex
																				.replace(
																						/ /g,
																						"_");
																		var toolTip = "<div id=\"templateTooltip_"
																				+ uid
																				+ "_"
																				+ parseStructureTemplatesHelper.containerId
																				+ "\" class=\"tooltip ui-widget-content\">";
																		toolTip += "<table width=\"100%\" cellspacing=\"0\" cellspacing=\"0\" border=\"0\"><tr><td colspan=\"2\" class=\"tooltipHead\">"
																				+ templateObjectIndex
																				+ "</td></tr>";
																		toolTip += "<tr><td class=\"tooltipImage\">";
																		if (templateObjectValue.previewimage !== undefined) {
																			toolTip += "<img alt=\""
																					+ templateObjectIndex
																					+ "\" src=\""
																					+ parseStructureTemplatesHelper
																							.resolveURL(templateObjectValue.previewimage)
																					+ "\" />";
																		}
																		toolTip += "</td><td class=\"tooltipDescription\">";
																		if (templateObjectValue.description !== undefined) {
																			toolTip += templateObjectValue.description
																		}
																		toolTip += "</td></tr></table></div>";
																		if (templateObjectValue.context !== undefined
																				&& (templateObjectValue.context.length > 0)
																				&& templateObjectValue.context !== "") {
																			var inContext = false;
																			jQuery
																					.each(
																							templateObjectValue.context,
																							function(
																									index,
																									value) {
																								if (parseStructureTemplatesHelper
																										.inArray(
																												currentContext,
																												value)) {
																									inContext = true;
																								}
																							});
																			if (inContext) {
																				tree += "<li name=\""
																						+ templateObjectValue.URL
																						+ "\" class=\"templateFile\"><span class=\"file\">"
																						+ templateObjectIndex
																						+ "</span>"
																						+ toolTip
																						+ "</li>";
																			} else {
																				tree += "";
																			}
																		} else {
																			tree += "<li name=\""
																					+ templateObjectValue.URL
																					+ "\" class=\"templateFile\"><span class=\"file\">"
																					+ templateObjectIndex
																					+ "</span>"
																					+ toolTip
																					+ "</li>";
																		}
																	});
												});
								tree += "</ul>";
							} else {
								tree += "<li><span class=\"folder\">"
										+ index
										+ "</span><ul class=\"\subList\">"
										+ parseStructureTemplatesHelper
												.parseRecursiveST(value,
														currentContext);
								tree += "</ul></li>";
							}
						});
		return tree;
	};
	this.loadDialogHTML = function() {
		var extendDialogHTMLHelper = this;
		jQuery
				.each(
						this.DialogMap,
						function(index, value) {
							var dialogUrl = extendDialogHTMLHelper
									.resolveURL(value);
							jQuery
									.ajax({
										url : dialogUrl,
										async : true,
										cache : true,
										success : function(html) {
											extendDialogHTMLHelper.DialogHTMLMap[index] = extendDialogHTMLHelper
													.processTemplate(html);
										},
										error : function(request, error, arg) {
											extendDialogHTMLHelper.jsObj.Logger
													.log(
															"[loadDialogHTML] Could not load dialog content for "
																	+ index
																	+ " dialog: "
																	+ error,
															"SEVERE", this);
										}
									});
						});
	};
	this.createDialog = function(dialogTitle, dialogContainerPrefix, replace) {
		var createDialogHelper = this;
		this.disableVirtualCaret = true;
		if (dialogContainerPrefix === undefined || dialogContainerPrefix === "") {
			dialogContainerPrefix = "modalDialog_";
		}
		if (replace === undefined || replace === null || replace === "") {
			replace = true;
		}
		if (jQuery("#" + dialogContainerPrefix + this.containerId).length > 0) {
			jQuery("#" + dialogContainerPrefix + this.containerId).show();
		} else {
			jQuery("#" + this.containerId)
					.append(
							"<div id=\""
									+ dialogContainerPrefix
									+ this.containerId
									+ "\" class=\"modalDialog ui-tabs ui-widget ui-widget-content ui-corner-all ui-dialog-content\" style=\"height: 1px; display:none;\"></div>");
			jQuery("#" + dialogContainerPrefix + this.containerId).show();
		}
		if (dialogTitle === undefined || dialogTitle === "") {
			dialogTitle = "No title defined";
		}
		jQuery("#" + dialogContainerPrefix + this.containerId).dialog({
			title : dialogTitle,
			autoOpen : false,
			minHeight : 20,
			resizable : false,
			close : function(event, ui) {
				createDialogHelper.hideDialog(dialogContainerPrefix, replace);
			}
		});
	};
	this.showDialog = function(parsedHTML, dialogContainerPrefix, replace) {
		var showDialogHelper = this;
		if (dialogContainerPrefix === undefined || dialogContainerPrefix === "") {
			dialogContainerPrefix = "modalDialog_";
		}
		if (replace === undefined || replace === null || replace === "") {
			replace = true;
		}
		if (replace) {
			this.replaceEditor(true);
		}
		jQuery("#" + dialogContainerPrefix + this.containerId).dialog('open');
		jQuery("#" + dialogContainerPrefix + this.containerId).html(parsedHTML);
		jQuery(document).bind("keypress.backSpaceHandler", function(event) {
			return showDialogHelper.cancelBackspace(event);
		});
		jQuery(document).bind("keydown.backSpaceHandler", function(event) {
			return showDialogHelper.cancelBackspace(event);
		});
	};
	this.dialogCreateTabs = function(dialogContainerPrefix) {
		if (dialogContainerPrefix === undefined || dialogContainerPrefix === "") {
			dialogContainerPrefix = "modalDialog_";
		}
		var tabSize = jQuery(
				"#" + dialogContainerPrefix + this.containerId
						+ " .dialogPanelContainer").size();
		if (tabSize > 1) {
			var tab = jQuery("#" + dialogContainerPrefix + this.containerId)
					.tabs();
			this.dtabs[dialogContainerPrefix] = tab;
		} else {
			jQuery("#" + dialogContainerPrefix + this.containerId + " > ul")
					.hide();
		}
		this.sizeDialog(dialogContainerPrefix);
	};
	this.sizeDialog = function(dialogContainerPrefix) {
		var contentWidth = 0;
		jQuery(
				"#" + dialogContainerPrefix + this.containerId
						+ " .dialogPanelContainer").each(function() {
			if (contentWidth < jQuery(this).outerWidth()) {
				contentWidth = jQuery(this).outerWidth();
			}
		});
		var dialogWidth = contentWidth + 10;
		jQuery("#" + dialogContainerPrefix + this.containerId).dialog('option',
				'width', dialogWidth);
		jQuery("#" + dialogContainerPrefix + this.containerId).dialog('option',
				'minWidth', dialogWidth);
		var tabWidth = 7;
		if (jQuery("#" + dialogContainerPrefix + this.containerId + " > ul")
				.css('display') !== 'none') {
			jQuery("#" + dialogContainerPrefix + this.containerId + " > ul li")
					.each(function() {
						tabWidth += jQuery(this).width() + 5;
					});
		}
		if (tabWidth > contentWidth) {
			jQuery("#" + dialogContainerPrefix + this.containerId).dialog(
					'option', 'width', tabWidth);
			jQuery("#" + dialogContainerPrefix + this.containerId).dialog(
					'option', 'minWidth', tabWidth);
		}
		var dialogWidth = jQuery("#" + dialogContainerPrefix + this.containerId)
				.dialog('option', 'width');
		jQuery(
				"#" + dialogContainerPrefix + this.containerId
						+ " .dialogPanelContainer").width(dialogWidth - 10);
		contentHeight = 0;
		jQuery("#" + dialogContainerPrefix + this.containerId).find(
				".dialogPanels").each(function() {
			if (contentHeight < jQuery(this).outerHeight()) {
				contentHeight = jQuery(this).outerHeight();
			}
		});
		jQuery("#" + dialogContainerPrefix + this.containerId).find(
				".dialogPanels").height(contentHeight);
		this.centerDialog(dialogContainerPrefix);
	};
	this.centerDialog = function(dialogContainerPrefix) {
		var offset = jQuery("#" + this.containerId).offset();
		var dialogPositionX = 0;
		var dialogPositionY = 0;
		if (jQuery("#" + this.containerId).height() > jQuery(window).height()) {
			dialogPositionY = (jQuery(window).scrollTop() - offset.top)
					+ ((jQuery(window).height() / 2) - (jQuery(
							"#" + dialogContainerPrefix + this.containerId)
							.parent(".ui-dialog").height() / 2));
		} else {
			dialogPositionY = offset.top
					+ ((jQuery("#" + this.containerId).height() / 2) - (jQuery(
							"#" + dialogContainerPrefix + this.containerId)
							.parent(".ui-dialog").height() / 2));
		}
		dialogPositionX = offset.left
				+ ((jQuery("#" + this.containerId).width() / 2) - (jQuery(
						"#" + dialogContainerPrefix + this.containerId).parent(
						".ui-dialog").width() / 2));
		if (dialogPositionY < 0) {
			dialogPositionY = 0;
		}
		if (dialogPositionX < 0) {
			dialogPositionX = 0;
		}
		jQuery("#" + dialogContainerPrefix + this.containerId).parent(
				".ui-dialog").css({
			top : dialogPositionY,
			left : dialogPositionX
		});
		jQuery("#" + dialogContainerPrefix + this.containerId).find(
				"input, textarea, select, button").first().focus();
	};
	this.hideDialog = function(dialogContainerPrefix, replace) {
		var hideDialogHelper = this;
		if (dialogContainerPrefix === undefined || dialogContainerPrefix === "") {
			dialogContainerPrefix = "modalDialog_";
		}
		if (replace === undefined || replace === null || replace === "") {
			replace = true;
		}
		jQuery("#" + dialogContainerPrefix + this.containerId)
				.dialog('destroy');
		if (this.dtabs !== undefined
				&& this.dtabs[dialogContainerPrefix] !== undefined) {
			this.dtabs[dialogContainerPrefix].tabs('destroy');
			this.dtabs[dialogContainerPrefix] = undefined;
		}
		jQuery("#" + dialogContainerPrefix + this.containerId).html("");
		if (replace) {
			this.replaceEditor(false);
		}
		this.disableVirtualCaret = false;
		this.jsWrapperObj.requestFocus();
		jQuery(document).unbind("keypress.backSpaceHandler");
		jQuery(document).unbind("keydown.backSpaceHandler");
	};
	this.replaceEditorNoOverlay = function(state) {
		var replaceEditorHelper = this;
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			if (!state) {
				jQuery("#" + this.id).css({
					visibility : "visible"
				});
				jQuery("#replacementImage_" + this.containerId).css({
					display : "none"
				});
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					this.jsWrapperObj.replaceEditor(state);
				}
			} else {
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					this.jsWrapperObj.replaceEditor(state);
				}
				if (this.isMSIE) {
					jQuery("#" + this.containerId + " button:first").focus();
				}
				jQuery("#" + this.id).css({
					visibility : "hidden"
				});
				jQuery("#replacementImage_" + this.containerId).css({
					display : "block"
				});
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					jQuery("#replacementImage_" + this.containerId).attr("src",
							"");
				}
			}
		}
	};
	this.replaceEditor = function(state) {
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			var replaceEditorHelper = this;
			if (!state) {
				jQuery("#dialogOverlay_" + this.containerId).remove();
				jQuery("#dialogOverlayTB_" + this.containerId).remove();
				jQuery("#dialogOverlaySB_" + this.containerId).remove();
				jQuery("#" + this.id).css({
					visibility : "visible"
				});
				jQuery("#replacementImage_" + this.containerId).css({
					display : "none"
				});
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					this.jsWrapperObj.replaceEditor(state);
				}
			} else {
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					this.jsWrapperObj.replaceEditor(state);
				}
				if (this.isMSIE) {
					jQuery("#" + this.containerId + "_focusButton").focus();
				}
				jQuery("#" + this.id).css({
					visibility : "hidden"
				});
				jQuery("#replacementImage_" + this.containerId).css({
					display : "block"
				});
				if (this.isMSIE
						&& parseInt(this.BrowserVersion) < 8
						|| (this.config.enablereplacementimage !== undefined && this.config.enablereplacementimage === "false")) {
				} else {
					jQuery("#replacementImage_" + this.containerId).attr("src",
							"");
				}
				jQuery("#" + this.containerId)
						.append(
								"<div id=\"dialogOverlay_"
										+ this.containerId
										+ "\" class=\"dialogOverlay ui-corner-all\"></div>");
				jQuery("#dialogOverlay_" + this.containerId).width(
						jQuery("#" + this.containerId).width());
				jQuery("#dialogOverlay_" + this.containerId).height(
						jQuery("#" + this.containerId).height());
				if (this.detachableUI.enabled !== undefined
						&& (this.detachableUI.enabled === "true" || this.detachableUI.enabled === true)) {
					var offset = jQuery("#" + this.containerId).offset();
					jQuery("#dialogOverlay_" + this.containerId).offset(offset);
					jQuery(this.detachableUI.toolbar.options.location)
							.append(
									"<div id=\"dialogOverlayTB_"
											+ this.containerId
											+ "\" class=\"dialogOverlay ui-corner-all\"></div>");
					jQuery("#dialogOverlayTB_" + this.containerId).width(
							jQuery(
									"#" + this.containerId
											+ "_detachedToolBarContainer")
									.width());
					jQuery("#dialogOverlayTB_" + this.containerId).height(
							jQuery(
									"#" + this.containerId
											+ "_detachedToolBarContainer")
									.height());
					var offset = jQuery(
							"#" + this.containerId
									+ "_detachedToolBarContainer").offset();
					jQuery("#dialogOverlayTB_" + this.containerId).offset(
							offset);
					jQuery(this.detachableUI.statusbar.options.location)
							.append(
									"<div id=\"dialogOverlaySB_"
											+ this.containerId
											+ "\" class=\"dialogOverlay ui-corner-all\"></div>");
					jQuery("#dialogOverlaySB_" + this.containerId).width(
							jQuery(
									"#" + this.containerId
											+ "_detachedStatusBarContainer")
									.width());
					jQuery("#dialogOverlaySB_" + this.containerId).height(
							jQuery(
									"#" + this.containerId
											+ "_detachedStatusBarContainer")
									.height());
					var offset = jQuery(
							"#" + this.containerId
									+ "_detachedStatusBarContainer").offset();
					jQuery("#dialogOverlaySB_" + this.containerId).offset(
							offset);
				}
			}
		}
	};
	this.assembleFontDropDownList = function() {
		var fontNames = "";
		if (this.fontNamesTemp === null) {
			fontNames = this.jsWrapperObj.getAvailableFonts();
			if (fontNames !== "") {
				eval("fontNamesNew = " + fontNames);
				this.fontNamesTemp = fontNamesNew;
			}
		} else {
			fontNames = this.fontNamesTemp;
		}
		jQuery("#" + this.containerId).append(
				"<div class=\"hidden\" id=\"fontDropDownList_"
						+ this.containerId + "\"><ul></ul></div>")
		var list = jQuery("#fontDropDownList_" + this.containerId + " ul");
		list.append("<li style=\"text-align: left\" name=\"default\" name=\""
				+ this.LocaleObject.L_DEFAULT_VALUE_TEXT
				+ "\"><a class=\"dropdownMenuItem\" href=\"#\">"
				+ this.LocaleObject.L_DEFAULT_VALUE_TEXT + "</a></li>");
		jQuery.each(fontNamesNew, function(index, value) {
			list.append("<li style=\"text-align: left\" alt=\"" + value
					+ "\" name=\"" + value
					+ "\"><a class=\"dropdownMenuItem\" href=\"#\">" + value
					+ "</a></li>");
		});
	};
	this.createSpinner = function(id, min, max, step) {
		if (step === undefined) {
			step = 1;
		}
		jQuery(id).spinner({
			max : max,
			min : min,
			step : step
		});
	};
	this.bindOpenFileDialog = function(bindToElemId, updateElem, filter) {
		var bindOpenFileHelper = this;
		jQuery(bindToElemId).bind(
				"click",
				function(e) {
					bindOpenFileHelper.jsObj.invokeAction("open-file-dialog",
							"['" + updateElem + "', '" + filter + "']");
				});
	};
	this.bindOpenWebdavDialog = function(bindToElemId, updateElem, actionID) {
		var bindOpenWebDavHelper = this;
		jQuery(bindToElemId).bind(
				"click",
				function(e) {
					bindOpenWebDavHelper.jsObj.invokeAction(actionID, "['"
							+ updateElem + "']");
				});
	};
	this.openFileDialog = function(updateElem, filter) {
		var bindOpenFileHelper = this;
		bindOpenFileHelper.jsObj.invokeAction("open-file-dialog", "['"
				+ updateElem + "', '" + filter + "']");
	};
	this.openWebdavDialog = function(updateElem, actionID) {
		var bindOpenWebDavHelper = this;
		bindOpenWebDavHelper.jsObj.invokeAction(actionID, "['" + updateElem
				+ "']");
	};
	this.createDrawTableElement = function(tableId, rowResultId,
			columnResultId, rows, columns) {
		var createDrawTableHelper = this;
		var tableStr = "";
		for (var i = 0; i < rows; i++) {
			tableStr += "<tr>";
			for (var j = 0; j < columns; j++) {
				tableStr += "<td>&nbsp;</td>";
			}
			tableStr += "</tr>";
		}
		jQuery("#" + tableId).append(tableStr);
		var currentTd = null;
		var col, row = 0;
		this.bindTableEvents = function() {
			btE = this;
			jQuery("#" + tableId + " td")
					.each(
							function(i, elem) {
								jQuery(this)
										.bind(
												'mouseover',
												elem,
												function(e) {
													if (currentTd != e.data) {
														currentTd = e.data;
														col = jQuery(currentTd)
																.prevAll().length;
														row = currentTd.parentNode.rowIndex;
														jQuery(
																"#" + tableId
																		+ " td")
																.each(
																		function(
																				i,
																				elem) {
																			(jQuery(
																					elem)
																					.prevAll().length <= col
																					&& elem.parentNode.rowIndex <= row ? jQuery(
																					elem)
																					.addClass(
																							"hover")
																					: jQuery(
																							elem)
																							.removeClass(
																									"hover"));
																		});
													}
												});
								jQuery(this)
										.bind(
												'click',
												elem,
												function(e) {
													jQuery(
															"#" + tableId
																	+ " td")
															.each(
																	function(i,
																			elem) {
																		jQuery(
																				this)
																				.unbind(
																						"mouseover");
																		jQuery(
																				this)
																				.unbind(
																						"click");
																		jQuery(
																				"#"
																						+ tableId)
																				.unbind(
																						"click");
																	});
													col = jQuery(e.data)
															.prevAll().length;
													row = e.data.parentNode.rowIndex;
													jQuery("#" + rowResultId)
															.val(row + 1);
													jQuery("#" + columnResultId)
															.val(col + 1);
													jQuery("#" + rowResultId)
															.effect("highlight");
													jQuery("#" + columnResultId)
															.effect("highlight");
													window
															.setTimeout(
																	"jQuery(\"#"
																			+ tableId
																			+ "\").bind(\"click\", function(){eval(btE).bindTableEvents();});",
																	300);
												});
							});
		};
		this.bindTableEvents();
	};
	this.createColorSelectTable = function(colorObject, attachId) {
		var createColorSelectTableHelper = this;
		var cols = 4;
		var i = 0;
		var html = "";
		var colorValue = null;
		var localeValue = null;
		jQuery
				.each(
						colorObject,
						function(index, value) {
							if (value.value === undefined) {
								colorValue = value.rgb;
								localeValue = value.desc;
							} else {
								colorValue = value.value;
								localeValue = createColorSelectTableHelper.LocaleObject[value.locale];
							}
							if (i === 0) {
								html += "<tr>\n<td><button name='"
										+ colorValue
										+ "' id='textColor_"
										+ localeValue
										+ "_"
										+ createColorSelectTableHelper.containerId
										+ "' style='background-color: "
										+ colorValue + "' title='"
										+ localeValue + "' /></td>";
							} else if (i % cols === 0 && i !== 0) {
								html += "</tr><tr>\n<td><button name='"
										+ colorValue
										+ "' id='textColor_"
										+ localeValue
										+ "_"
										+ createColorSelectTableHelper.containerId
										+ "' style='background-color: "
										+ colorValue + "' title='"
										+ localeValue + "' /></td>";
							} else {
								html += "\n<td><button name='"
										+ colorValue
										+ "' id='textColor_"
										+ localeValue
										+ "_"
										+ createColorSelectTableHelper.containerId
										+ "' style='background-color: "
										+ colorValue + "' title='"
										+ localeValue + "' /></td>";
							}
							i++;
						});
		var difference = 0;
		if (i % cols === 0) {
			difference = 0;
		} else {
			difference = cols - (i % cols);
		}
		for (var k = 0; k < difference; k++) {
			html += "<td>&nbsp;</td>";
		}
		jQuery("#" + attachId).append(html + "</tr>");
	};
	this.toggleFullscreenMode = function() {
		var toggleFullscreenModeHelper = this;
		var toolbarHeight = "";
		var statusBarHeight = "";
		var reduceHeight = "";
		var sideBarWidth = "";
		var sideBarVisible = "";
		var width = "";
		if (!this.isFullscreenMode) {
			jQuery("#toggleFullscreenMode_" + this.containerId + " span")
					.removeClass("ui-icon-extlink");
			jQuery("#toggleFullscreenMode_" + this.containerId + " span")
					.addClass("ui-icon-newwin");
			jQuery("#toggleFullscreenMode_" + this.containerId + " span").attr(
					"title",
					toggleFullscreenModeHelper.LocaleObject.L_RESTORE_DOWN);
			var windowWidth = jQuery(window).width();
			var windowHeight = jQuery(window).height();
			var reduceWindowWidth = 18;
			var reduceWindowHeight = 0;
			if (this.isMSIE) {
				reduceWindowWidth = 18;
				reduceWindowHeight = 1;
			}
			jQuery("#" + this.containerId).css({
				width : windowWidth - reduceWindowWidth,
				height : windowHeight - reduceWindowHeight
			});
			jQuery("#" + this.containerId).offset({
				top : 0,
				left : 0
			});
			this.resizeUI();
			jQuery("#" + this.containerId).offset({
				top : 0,
				left : 0
			});
			if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
				this.jsWrapperObj.requestFocus();
			}
			jQuery("#" + this.containerId).offset({
				top : 0,
				left : 0
			});
			this.isFullscreenMode = true;
		} else {
			jQuery("#toggleFullscreenMode_" + this.containerId + " span")
					.removeClass("ui-icon-newwin");
			jQuery("#toggleFullscreenMode_" + this.containerId + " span")
					.addClass("ui-icon-extlink");
			jQuery("#toggleFullscreenMode_" + this.containerId + " span")
					.attr("title",
							toggleFullscreenModeHelper.LocaleObject.L_MAXIMIZE);
			jQuery("#" + this.containerId).offset(this.initialOffset);
			jQuery("#" + this.containerId).css({
				width : toggleFullscreenModeHelper.editorWidth,
				height : toggleFullscreenModeHelper.editorHeight
			});
			if (toggleFullscreenModeHelper.isMSIE
					&& parseInt(toggleFullscreenModeHelper.BrowserVersion) < 7) {
				this.resizeUI(false, toggleFullscreenModeHelper.editorWidth,
						toggleFullscreenModeHelper.editorHeight);
			} else {
				this.resizeUI();
			}
			if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
				this.jsWrapperObj.requestFocus();
			}
			this.isFullscreenMode = false;
		}
	};
	this.serializeJSON = function(json) {
		var arrayStr = "";
		var entries = 0;
		var serializeJSONHelper = this;
		jQuery.each(json, function(key, val) {
			key = "" + key;
			while (key.length < 4) {
				key = "0" + key;
			}
			if (typeof val == "object") {
				if (entries !== 0) {
					arrayStr += ",";
				}
				arrayStr += "\"" + entries + "\": ";
				arrayStr += "{\n";
				arrayStr += "\"" + key + "\": {\n";
				arrayStr += serializeJSONHelper.serializeJSON(val);
				arrayStr += "}";
				arrayStr += "}\n";
			} else {
				if (entries !== 0) {
					arrayStr += ",";
				}
				arrayStr += "\"" + key + "\": ";
				arrayStr += "\"" + val + "\"\n";
			}
			entries++;
		});
		return arrayStr;
	};
	this.resizeUI = function(widthOnly, prewidth, preheight) {
		if (widthOnly === undefined) {
			widthOnly = false;
		}
		var toolbarHeight = 0;
		var statusBarHeight = 0;
		var reduceWidth = 0;
		if (this.detachableUI.enabled !== undefined
				&& (this.detachableUI.enabled === "true" || this.detachableUI.enabled === true)) {
		} else {
			toolbarHeight = jQuery("#" + this.containerId + "_toolbar")
					.height();
			statusBarHeight = jQuery("#" + this.containerId + "_statusbar")
					.height();
		}
		if (statusBarHeight === null || statusBarHeight === undefined) {
			statusBarHeight = 0;
		}
		var reduceHeight = parseInt(toolbarHeight, 10)
				+ parseInt(statusBarHeight, 10);
		var sideBarWidth = parseInt(jQuery("#" + this.containerId + "_sidebar")
				.width(), 10);
		var sideBarVisible = jQuery("#" + this.containerId + "_sidebar").css(
				"display");
		var width = 0;
		if (prewidth === undefined) {
			width = jQuery("#" + this.containerId).width();
		} else {
			width = prewidth;
		}
		var reducedWidth = "";
		if (sideBarVisible == "none" || sideBarVisible === undefined) {
			reduceWidth = 0;
		} else {
			reduceWidth = sideBarWidth + 7;
		}
		var height = 0;
		if (preheight === undefined) {
			height = jQuery("#" + this.containerId).height();
		} else {
			height = preheight;
		}
		var reducedHeight = this.parseNumber(height - (reduceHeight));
		if (this.isMSIE) {
			reducedHeight = reducedHeight - 1;
		} else if (this.isWebKit) {
			reducedHeight = reducedHeight - 1;
		} else {
			reducedHeight = reducedHeight - 1;
		}
		if (this.config.enablestyletemplatepanel === undefined
				|| this.config.enablestyletemplatepanel == "true"
				|| this.config.enablestyletemplatepanel === true) {
			reducedWidth = this.parseNumber(width - reduceWidth);
		} else {
			reducedWidth = this.parseNumber(width);
		}
		if (this.detachableUI.enabled !== undefined
				&& (this.detachableUI.enabled === "true" || this.detachableUI.enabled === true)) {
			jQuery(
					"#applicationContainer_" + this.containerId
							+ " .ui-layout-resizer").height(reducedHeight - 2);
			jQuery("#" + this.containerId + "_sidebar").height(
					reducedHeight - 2);
			jQuery(
					"#" + this.containerId + "_sidebar #" + this.containerId
							+ "_sidebar_content").height(reducedHeight - (37));
		} else {
			jQuery("#" + this.containerId + "_toolbar").width(width);
			if (this.isMSIE) {
				jQuery("#" + this.containerId + "_toolbar_container").width(
						width - 7);
			} else if (this.isWebKit) {
				jQuery("#" + this.containerId + "_toolbar_container").width(
						width - 5);
			} else {
				jQuery("#" + this.containerId + "_toolbar_container").width(
						width - 6);
			}
			jQuery("#" + this.containerId + "_statusbar").width(width - 3);
			jQuery(
					"#applicationContainer_" + this.containerId
							+ " .ui-layout-resizer").height(reducedHeight);
			jQuery("#" + this.containerId + "_sidebar").height(
					reducedHeight - 1);
			jQuery(
					"#" + this.containerId + "_sidebar #" + this.containerId
							+ "_sidebar_content").height(reducedHeight - (37));
		}
		if (!widthOnly) {
			jQuery("#applicationContainer_" + this.containerId).height(
					reducedHeight);
		}
		jQuery("#applicationContainer_" + this.containerId).width(width);
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			this.jsWrapperObj.setMinCanvasWidth(reducedWidth);
		}
		var rulerContainer = jQuery("#" + this.containerId + "_ruler");
		var reduceHeightRuler = 0;
		if (rulerContainer.length > 0) {
			reduceHeightRuler = rulerContainer.outerHeight();
		}
		var reducedHeightRuler = reducedHeight
				- this.parseNumber(reduceHeightRuler);
		jQuery("#" + this.containerId + "_div").css({
			"width" : reducedWidth,
			"height" : reducedHeight
		});
		jQuery("#" + this.id).css({
			"width" : reducedWidth - 1,
			"height" : reducedHeightRuler
		});
		jQuery("#" + this.id).attr({
			"width" : reducedWidth - 1,
			"height" : reducedHeightRuler
		});
		jQuery("#replacementImage_" + this.containerId).css({
			width : reducedWidth,
			height : reducedHeightRuler
		});
		var statusBarReduceWidth = jQuery(
				"#" + this.containerId + "_statusbar .buttonContainer")
				.outerWidth(true) + 6;
		statusBarReduceWidth += ((jQuery("#" + this.containerId
				+ "_statusbar .buttonContainer td").length + 1) * 2) + 2;
		if (this.config.enablezoomarea === undefined
				|| this.config.enablezoomarea == "true") {
			statusBarReduceWidth += 246;
		} else {
			statusBarReduceWidth += 18;
		}
		if (this.config.charactercounter !== undefined
				&& this.config.charactercounter.enabled !== undefined
				&& this.config.charactercounter.enabled === "true") {
			statusBarReduceWidth += jQuery(
					"#" + this.containerId + "_statusbar .documentCounterArea")
					.outerWidth(true) + 6;
		}
		if (this.config.resizable !== undefined
				&& this.config.resizable == "true") {
			statusBarReduceWidth += jQuery(
					"#" + this.containerId + "_statusbar .resizerContainer")
					.outerWidth(true) + 6;
		}
		if (this.config.languagebar !== undefined) {
			statusBarReduceWidth += jQuery(
					"#" + this.containerId + "_statusbar .languageBar")
					.outerWidth(true) + 6;
		}
		if (this.config.enablepagecountarea !== undefined
				&& this.config.enablepagecountarea == "true") {
			statusBarReduceWidth += jQuery(
					"#" + this.containerId + "_statusbar .pageCounter")
					.outerWidth(true) + 6;
		}
		statusBarReduceWidth += 40;
		jQuery("#" + this.containerId + "_statusbar .documentPaletteContainer")
				.width(width - statusBarReduceWidth);
		this.jsObj.toggleNav();
	};
	this.createParameterWidget = function(paramContainerId, paramObject) {
		var createParameterWidgetHelper = this;
		var height = jQuery(paramContainerId).parents(".dialogPanels").height();
		jQuery(paramContainerId)
				.append(
						"<table cellspacing='0' class='parameterWidgetHeader ui-widget-content ui-corner-top' width='100%'><tr class='ui-widget-header'><td style='border-right: 1px solid grey;'>"
								+ this.LocaleObject.L_PARAM_WIDGET_NAME
								+ "</td><td>"
								+ this.LocaleObject.L_PARAM_WIDGET_VALUE
								+ "</td></tr></table>");
		jQuery(paramContainerId)
				.parents(".dialogPanelInnerContainer")
				.append(
						"<button id='parameterWidgetAddButton_"
								+ this.containerId
								+ "'>"
								+ this.LocaleObject.L_ADD_BUTTON
								+ "</button>"
								+ "<button disabled='disabled' id='parameterWidgetRemoveButton_"
								+ this.containerId + "'>"
								+ this.LocaleObject.L_REMOVE_BUTTON
								+ "</button>");
		if (paramObject !== undefined && paramObject !== null) {
			jQuery.each(paramObject, function(index, value) {
				createParameterWidgetHelper.addParamWidgetBindEvents(
						paramContainerId, index, value);
			});
		} else {
			this.addParamWidgetBindEvents(paramContainerId, "", "");
		}
		jQuery("#parameterWidgetAddButton_" + this.containerId)
				.bind(
						"click",
						function(e) {
							createParameterWidgetHelper
									.addParamWidgetBindEvents(paramContainerId,
											"", "");
							if (jQuery(paramContainerId + " tr").length > 2) {
								jQuery(
										"#parameterWidgetRemoveButton_"
												+ createParameterWidgetHelper.containerId)
										.attr("disabled", "");
							}
						});
		jQuery("#parameterWidgetRemoveButton_" + this.containerId)
				.bind(
						"click",
						function(e) {
							var beforeEmpty = jQuery(".selectedRow").prev(
									"tr:not(.ui-widget-header)").length === 0;
							var afterEmpty = jQuery(".selectedRow").next().length === 0;
							var current = jQuery(".selectedRow");
							if (!beforeEmpty) {
								current.prev().addClass("selectedRow");
							} else if (!afterEmpty) {
								current.next().addClass("selectedRow");
							} else {
								jQuery(
										"#parameterWidgetRemoveButton_"
												+ createParameterWidgetHelper.containerId)
										.attr("disabled", "true");
							}
							current.remove();
							if (jQuery(paramContainerId + " tr").length < 3) {
								jQuery(
										"#parameterWidgetRemoveButton_"
												+ createParameterWidgetHelper.containerId)
										.attr("disabled", "disabled");
							}
							var height = jQuery(paramContainerId).height();
							var innerHeight = jQuery(
									paramContainerId + " table").height();
							if (innerHeight <= height) {
								jQuery(paramContainerId).css({
									"padding-right" : 0
								});
							}
						});
		if (jQuery(paramContainerId + " tr").length > 2) {
			jQuery(
					"#parameterWidgetRemoveButton_"
							+ createParameterWidgetHelper.containerId).attr(
					"disabled", "");
		}
	};
	this.addParamWidgetBindEvents = function(paramContainerId, name, value) {
		var createParameterWidgetHelperHelper = this;
		jQuery(paramContainerId + " table")
				.append(
						"<tr><td><input class='paramName' value='"
								+ name
								+ "' type='text' size='14'/></td><td><input class='paramValue' type='text' value='"
								+ value + "' size='14'/></td></tr>");
		var height = jQuery(paramContainerId).height();
		var innerHeight = jQuery(paramContainerId + " table").height();
		if (innerHeight > height) {
			jQuery(paramContainerId).css({
				"padding-right" : 14
			});
		}
		jQuery("#parameterWidgetInnerContainer_" + this.containerId + " input")
				.bind("blur", function(e) {
					jQuery(this).css({
						"background-color" : "#FFFFFF",
						"cursor" : "default"
					});
					jQuery(this).parent("td").css({
						"background-color" : "#FFFFFF"
					});
				});
		jQuery(paramContainerId + " input").bind("focus", function(e) {
			jQuery(paramContainerId + " table tr").each(function() {
				jQuery(this).removeClass("selectedRow");
			});
			jQuery(this).parent("td").parent("tr").addClass("selectedRow");
			jQuery(this).parent("td").parent("tr").focus();
		});
	};
	this.scrollToViewPort = function(element) {
		var viewPortY = jQuery(document).scrollTop()
				|| jQuery(window).scrollTop();
		var viewPortX = jQuery(document).scrollLeft()
				|| jQuery(window).scrollLeft();
		var windowHeight = jQuery(window).height();
		var windowWidth = jQuery(window).width();
		var elementTop = jQuery(element).offset().top;
		var elementLeft = jQuery(element).offset().left;
		var elementHeight = jQuery(element).outerHeight();
		var elementWidth = jQuery(element).outerWidth();
		if (viewPortY > elementTop) {
			scrollY = elementTop - 5;
		} else if (viewPortY < elementTop
				&& !((elementTop + elementHeight) > (viewPortY + windowHeight))) {
			scrollY = 0
		} else {
			scrollY = elementTop + Math.min(elementHeight - windowHeight, 0)
					+ 5;
		}
		if (viewPortX > elementLeft) {
			scrollX = elementLeft;
		} else if (viewPortX < elementLeft
				&& !((elementLeft + elementWidth) > (viewPortX + windowWidth))) {
			scrollX = 0;
		} else {
			scrollX = elementLeft + Math.min(elementWidth - windowWidth, 0);
		}
		if (scrollY !== 0) {
			jQuery("html,body").scrollTop(scrollY);
		}
		if (scrollX !== 0) {
			jQuery("html,body").scrollLeft(scrollX);
		}
	};
	this.getUserPreferences = function(entry) {
		var setting = null;
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			var json = this.jsWrapperObj.getUserPreferences();
			try {
				json = jQuery.evalJSON(json);
				jQuery.each(json, function(key, value) {
					if (entry == key) {
						setting = value;
						return false;
					}
				});
			} catch (err) {
			}
		}
		return setting;
	};
	this.getInitialUserPreferences = function(entry) {
		userPreferences = this.initialUserPreferences;
		setting = null;
		try {
			userPreferences = jQuery.evalJSON(userPreferences);
			jQuery.each(userPreferences, function(key, value) {
				if (entry == key) {
					setting = value;
					return false;
				}
			});
		} catch (err) {
		}
		return setting;
	};
	this.setUserPreferences = function(setting) {
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			this.jsWrapperObj.setUserPreferences(jQuery.toJSON(setting));
		}
	};
	this.clearUserPreferences = function() {
		if (this.jsWrapperObj !== undefined && this.jsWrapperObj !== null) {
			this.jsWrapperObj.clearUserPreferences();
		}
	};
	this.getLocation = function() {
		var locationString = window.location.href;
		locationString = locationString.substr(0, locationString
				.lastIndexOf("/") + 1);
		return locationString;
	}
	this.htmlspecialchars = function(str, typ) {
		if (typeof str === "undefined") {
			str = "";
		}
		if (typeof typ !== "number") {
			typ = 2;
		}
		typ = Math.max(0, Math.min(3, parseInt(typ)));
		var from = [ /&/g, /</g, />/g ];
		var to = [ "&amp;", "&lt;", "&gt;" ];
		if (typ == 1 || typ == 3) {
			from.push(/'/g);
			to.push("&#039;");
		}
		if (typ == 2 || typ == 3) {
			from.push(/"/g);
			to.push("&quot;");
		}
		for ( var i in from) {
			str = str.replace(from[i], to[i]);
		}
		return str;
	}
	this.createToolbarObjectFromDOM = function() {
		stateObject = this.getUserPreferences("toolbarstate");
		if (stateObject === null) {
			stateObject = {};
		}
		if (stateObject[this.getLocation()] !== undefined
				&& stateObject[this.getLocation()] !== null
				&& stateObject[this.getLocation()] !== "") {
		} else {
			stateObject[this.getLocation()] = {};
		}
		if (stateObject[this.getLocation()][this.containerId] !== undefined
				&& stateObject[this.getLocation()][this.containerId] !== null
				&& stateObject[this.getLocation()][this.containerId] !== "") {
		} else {
			stateObject[this.getLocation()][this.containerId] = {};
		}
		var uiObject = {};
		var createFromDOMHelper = this;
		var tabs = jQuery("#" + this.containerId + "_ribbon_tab_container li");
		jQuery
				.each(
						tabs,
						function(i, value) {
							tabId = value.id;
							str = "/" + createFromDOMHelper.containerId
									+ "_tab_li_/g";
							tabId = tabId.replace(eval(str), "");
							uiObject[tabId] = {};
							subpanelContainers = jQuery(
									"#" + createFromDOMHelper.containerId
											+ "_ribbonPanelHolder_" + tabId)
									.children();
							jQuery
									.each(
											subpanelContainers,
											function(containerIndex, container) {
												var paneName = jQuery(this)
														.attr("id");
												var expr = "/subPanelContainer_"
														+ tabId + "_/g";
												var expr2 = "/_"
														+ createFromDOMHelper.containerId
														+ "/g";
												paneName = paneName.replace(
														eval(expr), "");
												paneName = paneName.replace(
														eval(expr2), "");
												uiObject[tabId][paneName] = createFromDOMHelper.uiconfig['toolbar']['ribbons']['elements'][tabId][paneName];
											});
						});
		stateObject[this.getLocation()][this.containerId] = escape(jQuery
				.toJSON(uiObject));
		this.setUserPreferences({
			"toolbarstate" : stateObject
		});
	};
	this.getUserDefinedToolbar = function() {
		var uistate = this.getInitialUserPreferences("toolbarstate");
		if (uistate !== null) {
			if (uistate[this.getLocation()] !== undefined
					&& uistate[this.getLocation()] !== null
					&& uistate[this.getLocation()] !== "") {
				if (uistate[this.getLocation()][this.containerId] !== undefined
						&& uistate[this.getLocation()][this.containerId] !== null
						&& uistate[this.getLocation()][this.containerId] !== "") {
					return unescape(uistate[this.getLocation()][this.containerId]);
				}
			}
		}
		return "";
	};
	this.getLocaleCode = function(localeConstant) {
		if (this.LocaleObject && this.LocaleObject[localeConstant]) {
			return this.LocaleObject[localeConstant];
		} else {
			return localeConstant;
		}
	}
};
eongApplication.Logger = function(Helper) {
	var LOG_LEVEL_SEVERE = 0;
	var LOG_LEVEL_WARNING = 1;
	var LOG_LEVEL_INFO = 2;
	var LOG_LEVEL_CONFIG = 3;
	var LOG_LEVEL_FINE = 4;
	var LOG_LEVEL_FINER = 5;
	var LOG_LEVEL_FINEST = 6;
	var LOG_LEVEL_ALL = 7;
	this.logLevel = LOG_LEVEL_CONFIG;
	this.Helper = Helper;
	if (window.console && console.firebug) {
		window.konsole = window.console;
		konsole.info("konsole detected Firebug.");
	} else {
		window.konsole = function() {
			var messages = [];
			if (window.console) {
				messages
						.push("<i>Check the built-in console for other messages.</i>")
			}
			var alertTimeout = null;
			function pushMsg(theMsg) {
				messages.push(theMsg);
				clearTimeout(alertTimeout);
				alertTimeout = setTimeout('konsole.doAlert('
						+ Helper.intrusiveJSLogging + ')', 800);
			}
			return {
				doAlert : function(intrusive) {
					alertTimeout = null;
					if (intrusive) {
						var comboMsg = "";
						try {
							var logDiv = document.createElement("div");
							logDiv.style.border = "2px dotted red";
							logDiv.style.padding = "4px";
							logDiv.style.backgroundColor = "#e0e0e0";
							logDiv.innerHTML = "<tt>"
									+ messages.join("<br /><br />") + "</tt>";
							document.body.appendChild(logDiv);
						} catch (e) {
							alert(messages.join("\n"));
						}
						window.status += messages.length + " messages written ";
						messages = [];
					}
				},
				log : function(msg) {
					if (window.console && window.console.log) {
						window.console.log(msg);
					} else {
						pushMsg("(log)... " + msg);
					}
				},
				debug : function(msg) {
					if (window.console && window.console.debug) {
						window.console.debug(msg);
					} else if (window.console) {
						window.console.log(msg);
					} else {
						pushMsg("(dbg)... " + msg);
					}
				},
				info : function(msg) {
					if (window.console && window.console.info) {
						window.console.info(msg);
					} else {
						pushMsg("(info).. " + msg);
					}
				},
				warn : function(msg) {
					if (window.console && window.console.warn) {
						window.console.warn(msg);
					} else {
						pushMsg("<b>[warn! ] </b>" + msg);
					}
				},
				error : function(msg) {
					if (window.console && window.console.error) {
						window.console.error(msg);
					} else {
						pushMsg("<b style='color:red'>ERROR: " + msg + "</b>");
					}
				},
				group : function(msg) {
					msg = msg || "";
					if (window.console && window.console.group) {
						window.console.group(msg);
					} else {
						pushMsg("<p style='border-left:1px solid black'>" + msg);
					}
				},
				groupEnd : function() {
					if (window.console && window.console.groupEnd) {
						window.console.groupEnd();
					} else {
						pushMsg("</p>");
					}
				},
				dir : function(obj) {
					if (window.console && window.console.dir) {
						window.console.dir(obj);
					} else {
						try {
							pushMsg(YAHOO.lang.JSON.stringify(obj, null, 20));
						} catch (yahooErr) {
							try {
								pushMsg(JSON.stringify(obj));
							} catch (jsonErr) {
								pushMsg("<i>JSON stringify failed or is disabled.</i><br />--"
										+ yahooErr.message
										+ "<br />--"
										+ jsonErr.message);
							}
						}
					}
				},
				time : function(name) {
					name = name || "anonymous";
					if (window.console && window.console.time) {
						window.console.time();
					} else {
						pushMsg(name + " timer started @ "
								+ new Date().getTime());
					}
				},
				timeEnd : function(name) {
					name = name || "anonymous";
					if (window.console && window.console.timeEnd) {
						window.console.timeEnd();
					} else {
						pushMsg(name + " timer stopped @ "
								+ new Date().getTime());
					}
				}
			}
		}();
		konsole.info("Created konsole");
	}
	this.log = function(msg, level, reference) {
		switch (level.toUpperCase()) {
		case "SEVERE":
			levelNo = 0;
			break;
		case "WARNING":
			levelNo = 1;
			break;
		case "INFO":
			levelNo = 2;
			break;
		case "CONFIG":
			levelNo = 3;
			break;
		case "FINE":
			levelNo = 4;
			break;
		case "FINER":
			levelNo = 5;
			break;
		case "FINEST":
			levelNo = 6;
			break;
		case "ALL":
			levelNo = 7;
			break;
		}
		try {
			if (levelNo <= this.logLevel) {
				switch (level.toUpperCase()) {
				case "SEVERE":
					konsole.error("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "WARNING":
					konsole.warn("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "INFO":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "CONFIG":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "FINE":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "FINER":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "FINEST":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				case "ALL":
					konsole.info("[" + this.Helper.jsObjName + "]["
							+ level.toUpperCase() + "] " + msg);
					break;
				}
			}
		} catch (err) {
		}
	};
	this.setJSLogLevel = function(logLevel) {
		if (logLevel.toUpperCase() == "ALL") {
			this.logLevel = LOG_LEVEL_ALL;
		} else if (logLevel.toUpperCase() == "FINEST") {
			this.logLevel = LOG_LEVEL_FINEST;
		} else if (logLevel.toUpperCase() == "FINER") {
			this.logLevel = LOG_LEVEL_FINER;
		} else if (logLevel.toUpperCase() == "FINE") {
			this.logLevel = LOG_LEVEL_FINE;
		} else if (logLevel.toUpperCase() == "CONFIG") {
			this.logLevel = LOG_LEVEL_CONFIG;
		} else if (logLevel.toUpperCase() == "INFO") {
			this.logLevel = LOG_LEVEL_INFO;
		} else if (logLevel.toUpperCase() == "WARNING") {
			this.logLevel = LOG_LEVEL_WARNING;
		} else if (logLevel.toUpperCase() == "SEVERE") {
			this.logLevel = LOG_LEVEL_SEVERE;
		} else {
			this.logLevel = LOG_LEVEL_CONFIG;
		}
	};
};
Ruler = function(rulerController, rulerContainer) {
	this.UPDATE_NOTHING = 0;
	this.UPDATE_BLOCK = 1;
	this.UPDATE_PAGE = 2;
	this.UPDATE_ALL = 4;
	this.DEFAULT_RULER_UNIT = "cm";
	this.DRAG_NONE = 0;
	this.DRAG_PAGE_LEFT = 1;
	this.DRAG_PAGE_RIGHT = 2;
	this.DRAG_BLOCK_LEFT = 3;
	this.DRAG_BLOCK_RIGHT = 4;
	this.ondragstart;
	this.ondragstop;
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
	var dpi = 96;
	var pagePositionX = -1;
	var pageMarginLeft = -1;
	var pageMarginRight = -1;
	var pageWidth = -1;
	var zoomFactor = 1;
	this.mouseDownX = -1;
	this.draggingMode = this.DRAG_NONE;
	var blockPositionX = -1;
	var blockWidth = -1;
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
	var rulerOffsetX = 0;
	this.init = function(newRulerUnit) {
		if (newRulerUnit != undefined) {
			this._setRulerUnit(newRulerUnit);
		}
		rulerContainer
				.bind(
						"mousedown",
						function(event) {
							if (event.which == 1) {
								var target = jQuery(event.target);
								if (!target.hasClass("blockMargin")) {
									if (ruler.pageMarginHandlesEnabled
											&& (target
													.hasClass("pageMarginLeftHandle") || ruler
													._isEventInside(
															event,
															ruler.pageMarginLeftElement))) {
										ruler.mouseDownX = event.pageX;
										ruler.pageMarginLeft = ruler
												.getPageMarginLeft();
										ruler.blockPosition = ruler
												.getBlockPosition();
										ruler.blockWidth = ruler
												.getBlockWidth();
										ruler.draggingMode = ruler.DRAG_PAGE_LEFT;
									}
									if (ruler.pageMarginHandlesEnabled
											&& (target
													.hasClass("pageMarginRightHandle") || ruler
													._isEventInside(
															event,
															ruler.pageMarginRightElement))) {
										ruler.mouseDownX = event.pageX;
										ruler.pageMarginRight = ruler
												.getPageMarginRight();
										ruler.blockPosition = ruler
												.getBlockPosition();
										ruler.blockWidth = ruler
												.getBlockWidth();
										ruler.draggingMode = ruler.DRAG_PAGE_RIGHT;
									}
								} else {
									if (ruler.blockMarginHandlesEnabled
											&& target
													.hasClass("blockMarginLeft")) {
										ruler.mouseDownX = event.pageX;
										ruler.blockPosition = ruler
												.getBlockPosition();
										ruler.blockWidth = ruler
												.getBlockWidth();
										ruler.draggingMode = ruler.DRAG_BLOCK_LEFT;
									} else if (ruler.blockMarginHandlesEnabled
											&& target
													.hasClass("blockMarginRight")) {
										ruler.mouseDownX = event.pageX;
										ruler.blockPosition = ruler
												.getBlockPosition();
										ruler.blockWidth = ruler
												.getBlockWidth();
										ruler.draggingMode = ruler.DRAG_BLOCK_RIGHT;
									}
								}
								if (ruler.ondragstart != undefined
										&& ruler.draggingMode != ruler.DRAG_NONE) {
									ruler.ondragstart();
								}
								return false;
							}
						});
		jQuery(document)
				.bind(
						"mousemove",
						function(event) {
							if (ruler.draggingMode != ruler.DRAG_NONE) {
								var delta = (event.pageX - ruler.mouseDownX)
										/ ruler.unitConversionFactor;
								switch (ruler.draggingMode) {
								case ruler.DRAG_PAGE_LEFT: {
									var marginLeft = ruler
											.rulerRound(ruler.pageMarginLeft
													+ delta);
									var blockLeft = ruler.blockPosition
											+ ruler.rulerRound(delta);
									var blockWidth = ruler.getBlockWidth()
											+ ruler.getBlockPosition()
											- blockLeft;
									if (blockWidth > (ruler.rulerStep * zoomFactor)
											&& marginLeft >= 0) {
										ruler.setPageValues(undefined,
												marginLeft, undefined,
												undefined);
										ruler.setBlockValues(blockLeft,
												blockWidth);
										ruler.update();
									}
									break;
								}
								case ruler.DRAG_PAGE_RIGHT: {
									var marginRight = ruler
											.rulerRound(ruler.pageMarginRight
													- delta);
									var blockWidth = ruler
											.rulerRound(ruler.blockWidth
													+ delta);
									if (blockWidth > 0 && marginRight >= 0) {
										ruler.setPageValues(undefined,
												undefined, marginRight,
												undefined);
										ruler.setBlockValues(undefined,
												blockWidth);
										ruler.update();
									}
									break;
								}
								case ruler.DRAG_BLOCK_LEFT: {
									delta = ruler.rulerRound(delta);
									var blockLeft = Math.max(0,
											ruler.blockPosition + delta);
									var blockWidth = ruler.getBlockWidth()
											+ ruler.getBlockPosition()
											- blockLeft;
									if (blockWidth >= ruler.rulerStep) {
										ruler.setBlockValues(blockLeft,
												blockWidth);
										ruler.update();
									}
									break;
								}
								case ruler.DRAG_BLOCK_RIGHT: {
									delta = ruler.rulerRound(delta);
									var maxWidth = parseFloat(rulerContainer[0].style.width)
											- ruler.blockPosition;
									var blockWidth = Math
											.min(
													maxWidth,
													Math
															.max(
																	(ruler.rulerStep * zoomFactor),
																	ruler.blockWidth
																			+ delta));
									ruler.setBlockValues(undefined, blockWidth);
									ruler.update();
									break;
								}
								}
								return false;
							}
						});
		jQuery(document)
				.bind(
						"mouseup",
						function(event) {
							if (ruler.draggingMode != ruler.DRAG_NONE) {
								switch (ruler.draggingMode) {
								case ruler.DRAG_PAGE_LEFT: {
									var margin = parseFloat(ruler.pageMarginLeftElement[0].style.width);
									rulerController.setPageMarginLeft((ruler
											.rulerRound(margin) / zoomFactor)
											+ rulerUnit);
									break;
								}
								case ruler.DRAG_PAGE_RIGHT: {
									var margin = parseFloat(ruler.pageMarginRightElement[0].style.width);
									rulerController.setPageMarginRight((ruler
											.rulerRound(margin) / zoomFactor)
											+ rulerUnit);
									break;
								}
								case ruler.DRAG_BLOCK_LEFT: {
									var pixel = ruler.marginLeftHandle
											.position().left;
									var usedUnit = pixel
											/ ruler.unitConversionFactor;
									ruler.marginLeftHandle.css("left", usedUnit
											+ rulerUnit);
									var delta = Math
											.round((usedUnit - ruler.blockPosition)
													/ (ruler.rulerStep * zoomFactor))
											* (ruler.rulerStep * zoomFactor);
									rulerController.modifyBlockMarginLeft(delta
											/ zoomFactor);
									break;
								}
								case ruler.DRAG_BLOCK_RIGHT: {
									var pixel = ruler.marginRightHandle
											.position().left;
									var usedUnit = pixel
											/ ruler.unitConversionFactor;
									ruler.marginRightHandle.css("left",
											usedUnit - rulerUnit);
									var delta = Math
											.round((usedUnit
													- ruler.blockPosition - ruler.blockWidth)
													/ (ruler.rulerStep * zoomFactor))
											* (ruler.rulerStep * zoomFactor)
											* -1;
									rulerController
											.modifyBlockMarginRight(delta
													/ zoomFactor);
									break;
								}
								}
								ruler.mouseDownX = -1;
								ruler.draggingMode = ruler.DRAG_NONE;
								if (ruler.ondragstop != undefined) {
									ruler.ondragstop();
								}
								return false;
							}
						});
	};
	this._isEventInside = function(event, object) {
		if ((event.pageX >= object.offset().left && event.pageX <= object
				.offset().left
				+ object.width())) {
			return true;
		}
		var children = object.children();
		for (var i = 0; i < children.length; i++) {
			if (this._isEventInside(event, jQuery(children[i]))) {
				return true;
			}
		}
		return false;
	};
	this.update = function() {
		if (updateLevel >= this.UPDATE_PAGE) {
			this.pageMarginLeftElement.css("width", (pageMarginLeft)
					+ rulerUnit);
			this.pageMarginLeftHandle.css("left", (pageMarginLeft) + rulerUnit);
			this.pageMarginRightElement.css("width", (pageMarginRight)
					+ rulerUnit);
			this.pageMarginRightHandle.css("right", (pageMarginRight)
					+ rulerUnit);
			rulerContainer.css("width", pageWidth + rulerUnit);
		}
		if (updateLevel >= this.UPDATE_BLOCK) {
			this.blockContentElement.css("left", blockPositionX + rulerUnit);
			this.blockContentElement.css("width", blockWidth + rulerUnit);
			this.marginLeftHandle.css("left", (blockPositionX) + rulerUnit);
			this.marginRightHandle.css("left", (blockPositionX + blockWidth)
					+ rulerUnit);
		}
		if (updateLevel >= this.UPDATE_ALL) {
			this._createDashes();
		}
		updateLevel = this.UPDATE_NOTHING;
	};
	this._createDashes = function() {
		var step = this.rulerStep * zoomFactor;
		var stepsPerNumber = this.rulerStepsPerNumber;
		var stepInPixel = step * this.unitConversionFactor;
		var lod = 0;
		var detailHelp = stepInPixel / 16;
		if (detailHelp < 0.10) {
			lod = 4;
		} else if (detailHelp < 0.2) {
			lod = 3;
		} else if (detailHelp < 0.3) {
			lod = 2;
		} else if (detailHelp < 0.5) {
			lod = 1;
		}
		var origin = pageMarginLeft;
		var str_html = "";
		var counter = 0;
		for (var i = 0; i * step < pageWidth; i++) {
			if (counter % stepsPerNumber == 0) {
				if (counter != 0) {
					var number = Math.round(counter / stepsPerNumber);
					if (lod < 3 || (lod < 4 && number % 2 == 0)
							|| (lod < 5 && number % 4 == 0)) {
						str_html += "<div class='rulerCount' style='left:"
								+ (origin + i * step) + rulerUnit + "'>"
								+ number * this.rulerNumberFactor + "</div>";
						str_html += "<div class='rulerCount' style='left:"
								+ (origin - i * step) + rulerUnit + "'>"
								+ number * this.rulerNumberFactor + "</div>";
					}
				}
			} else {
				var dashClass = "rulerDashSmall";
				var createDash = false;
				if (counter % (stepsPerNumber / 2) == 0) {
					if (lod < 2) {
						createDash = true;
					}
					dashClass = "rulerDashMedium";
				}
				if (lod < 1) {
					createDash = true;
				}
				if (createDash) {
					str_html += "<div class='" + dashClass + "' style='left:"
							+ (origin + i * step) + rulerUnit + "'></div>";
					str_html += "<div class='" + dashClass + "' style='left:"
							+ (origin - i * step) + rulerUnit + "'></div>";
				}
			}
			counter++;
		}
		this.rulerDashContainer
				.html(str_html + "<div id='rulerContent'></div>");
	};
	this.setRulerContainerOffset = function(newOffsetX) {
		if (rulerOffsetX != newOffsetX) {
			rulerOffsetX = newOffsetX;
			rulerContainer.css("left", rulerOffsetX);
		}
	};
	this.setPageValues = function(offset, marginLeft, marginRight, width) {
		var change = false;
		if (offset != undefined && pagePositionX != offset) {
			pagePositionX = offset;
			rulerContainer.css("left", pagePositionX + "px");
		}
		if (marginLeft != undefined && pageMarginLeft != marginLeft) {
			change = true;
			pageMarginLeft = marginLeft;
			this._increaseUpdateLevel(this.UPDATE_ALL);
		}
		if (marginRight != undefined && pageMarginRight != marginRight) {
			change = true;
			pageMarginRight = marginRight;
		}
		if (width != undefined && pageWidth != width) {
			pageWidth = width;
			rulerContainer.css("width", width + this.getRulerUnit());
			this._increaseUpdateLevel(this.UPDATE_ALL);
		}
		if (change) {
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
		if (offset != undefined && blockPositionX != offset) {
			change = true;
			blockPositionX = offset;
		}
		if (width != undefined && blockWidth != width) {
			change = true;
			blockWidth = width;
		}
		if (change) {
			this._increaseUpdateLevel(this.UPDATE_BLOCK);
		}
	};
	this.getBlockWidth = function() {
		return blockWidth;
	};
	this.getBlockPosition = function() {
		return blockPositionX;
	};
	this._setRulerUnit = function(newRulerUnit) {
		if (newRulerUnit != undefined) {
			newRulerUnit = newRulerUnit.toLowerCase();
			if (rulerUnit != newRulerUnit
					&& (newRulerUnit == "cm" || newRulerUnit == "in"
							|| newRulerUnit == "mm" || newRulerUnit == "px")) {
				rulerUnit = newRulerUnit;
				this._increaseUpdateLevel(this.UPDATE_ALL);
				if (rulerUnit == "cm") {
					ruler.unitConversionFactor = dpi / 2.54;
					ruler.rulerStep = 0.25;
					ruler.rulerStepsPerNumber = 4;
					ruler.rulerNumberFactor = 1;
				} else if (rulerUnit == "mm") {
					ruler.unitConversionFactor = dpi / 25.4;
					ruler.rulerStep = 2.5;
					ruler.rulerStepsPerNumber = 8;
					ruler.rulerNumberFactor = 20;
				} else if (rulerUnit == "in") {
					ruler.unitConversionFactor = dpi;
					ruler.rulerStep = 0.25;
					ruler.rulerStepsPerNumber = 8;
					ruler.rulerNumberFactor = 2;
				} else if (rulerUnit == "px") {
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
		if (newZoomFactor != undefined && newZoomFactor != zoomFactor
				&& newZoomFactor > 0) {
			if (newZoomFactor >= 0.1) {
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
		if (this.pageMarginHandlesEnabled != enabled) {
			if (enabled) {
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
		if (this.pageBlockHandlesEnabled != enabled) {
			if (enabled) {
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
		if (level != undefined && level > updateLevel) {
			updateLevel = level;
		}
		return updateLevel;
	};
	this.rulerRound = function(input, ignoreZoom) {
		var factor;
		if (ignoreZoom != undefined && ignoreZoom) {
			factor = 1;
		} else {
			factor = zoomFactor;
		}
		return Math.round(input / (ruler.rulerStep * factor))
				* (ruler.rulerStep * factor);
	}
	this._setRulerUnit(this.DEFAULT_RULER_UNIT);
};
RulerController = function(apiObject) {
	var rulerController = this;
	var editorReplaced = false;
	this.ruler;
	this.rulerContainer;
	this.currentBlockMarginLeft = 0;
	this.currentBlockMarginRight = 0;
	this.init = function(container, unit) {
		if (unit == undefined) {
			unit = "cm";
		}
		var ieSelectionFix = "";
		if (apiObject.Helper.isMSIE) {
			ieSelectionFix = "onselectstart=\"return false;\"";
		}
		this.rulerContainer = jQuery("<div " + ieSelectionFix + "></div>");
		container.prepend(this.rulerContainer);
		this.ruler = new Ruler(this, this.rulerContainer);
		this.ruler.init(unit);
		this.ruler.setPageValues(0, 0, 0, 0);
		this.ruler.setBlockValues(0, 0);
		this.ruler.update();
		if (apiObject.Helper.isMSIE
				&& parseInt(eong.Helper.BrowserVersion) == 7) {
			this._ie7fix();
		}
		this.ruler.ondragstop = function() {
			apiObject.requestFocus();
		};
	};
	this.updateRuler = function(updateObj) {
		if (updateObj != undefined) {
			var zoomFactor = updateObj["zoom"];
			rulerController.setZoomFactor(zoomFactor);
			rulerController.currentBlockMarginLeft = updateObj["block-margin-left"];
			rulerController.currentBlockMarginRight = updateObj["block-margin-right"];
			var blockOffset = updateObj["block-offset-x"]
					+ rulerController.currentBlockMarginLeft * zoomFactor;
			var blockWidth = updateObj["block-width"]
					- rulerController.currentBlockMarginLeft * zoomFactor
					- rulerController.currentBlockMarginRight * zoomFactor;
			rulerController.ruler.setBlockValues(blockOffset, blockWidth);
			var pagedMode = updateObj["paged-mode"];
			rulerController.ruler.setPageMarginHandlesEnabled(pagedMode);
			var rulerBorderLeftWidth = 0;
			if (rulerController.rulerContainer.css("border-left-style") != "none") {
				rulerBorderLeftWidth = rulerController
						._resolveBorderWidth(rulerController.rulerContainer
								.css("border-left-width"));
			}
			var pageOffset = updateObj["page-offset-x"];
			var pageWidth = pagedMode ? updateObj["page-width"]
					: updateObj["page-width"] / zoomFactor;
			var pageMarginLeft = updateObj["page-margin-left"] * zoomFactor;
			var pageMarginRight = updateObj["page-margin-right"] * zoomFactor;
			var scrollX = updateObj["horizontal-scrollbar"];
			rulerController.ruler.setPageValues(pageOffset
					- rulerBorderLeftWidth - scrollX, pageMarginLeft,
					pageMarginRight, pageWidth);
			rulerController.ruler.update();
		}
	};
	this.setPageMarginLeft = function(margin) {
		apiObject.getObj().setPageMarginLeft(margin);
	};
	this.setPageMarginRight = function(margin) {
		apiObject.getObj().setPageMarginRight(margin);
	};
	this.modifyBlockMarginLeft = function(margin) {
		var oldLength = this.ruler
				.rulerRound(this.currentBlockMarginLeft, true);
		if (oldLength != undefined) {
			margin = oldLength + margin;
		}
		if (Math.abs(margin) < this.ruler.rulerStep / 2) {
			margin = 0;
		}
		apiObject.getObj().setUsedBlockMarginLeft(
				margin + this.ruler.getRulerUnit());
	};
	this.modifyBlockMarginRight = function(margin) {
		var oldLength = this.ruler.rulerRound(this.currentBlockMarginRight,
				true);
		if (oldLength != undefined) {
			margin = oldLength + margin;
		}
		if (Math.abs(margin) < this.ruler.rulerStep / 2) {
			margin = 0;
		}
		apiObject.getObj().setUsedBlockMarginRight(
				margin + this.ruler.getRulerUnit());
	};
	this.getZoomFactor = function() {
		if (this.ruler) {
			return this.ruler.getZoomFactor();
		}
		return 1;
	};
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
	this._ie7fix = function() {
		var zIndexFix = 1000;
		jQuery('.rulerContainer, .rulerContainer > div').each(function() {
			jQuery(this).css('zIndex', zIndexFix);
			zIndexFix -= 10;
		});
	}
};
eongApplication.Toolbar = function(toolbarHelper, toolbarLogger) {
	this.uiconfig = toolbarHelper.uiconfig;
	this.config = toolbarHelper.config;
	var toolbar = this;
	this.createToolBar = function(toolbarwidth, editorcontainerid, fake) {
		this.appendContainers(toolbarwidth, editorcontainerid);
		this.appendTabHTML(editorcontainerid)
		this.appendQuickIcons(editorcontainerid);
		if ((toolbarHelper.config.resizable !== undefined && toolbarHelper.config.resizable == "true")
				|| (toolbarHelper.config.draggable !== undefined && toolbarHelper.config.draggable == "true")) {
			this.appendIconContainer(editorcontainerid);
		}
		if (toolbarHelper.config.draggable !== undefined
				&& toolbarHelper.config.draggable == "true") {
			this.appendDragHandle(editorcontainerid);
		}
		if (toolbarHelper.config.resizable !== undefined
				&& toolbarHelper.config.resizable == "true") {
			this.appendFullScreenButton(editorcontainerid);
		}
		this.appenTabContentContainer(editorcontainerid);
		this.createTabs(editorcontainerid, fake);
		jQuery("#" + editorcontainerid + "_toolbar_container").removeClass(
				"ui-corner-all");
		jQuery
				.each(
						this.uiconfig.toolbar.ribbons.elements,
						function(i, val) {
							var paneLocaleName = "";
							if (val !== undefined && val !== null) {
								jQuery
										.each(
												val,
												function(j, valj) {
													var actionCount = 0;
													var row = 0;
													var counter = 0;
													if (toolbarHelper.LocaleObject[j] !== undefined) {
														paneLocaleName = toolbarHelper.LocaleObject[j];
													} else {
														paneLocaleName = j;
													}
													if (valj.subpanels !== undefined) {
														toolbar
																.appendSubPanelContainer(
																		editorcontainerid,
																		i, j);
														jQuery
																.each(
																		valj.subpanels,
																		function(
																				subpanelIndex,
																				subpanel) {
																			var actionCount = 0;
																			var row = 0;
																			var counter = 0;
																			var buttonSetSize = subpanel.size;
																			if (buttonSetSize === "dropdownPanel") {
																				toolbar
																						.appendSubPanel(
																								editorcontainerid,
																								i,
																								j,
																								subpanelIndex,
																								buttonSetSize);
																				actionCount = toolbar
																						.getActionCount(subpanel);
																				iconsPerRow = toolbar
																						.getIconsPerRow(
																								buttonSetSize,
																								actionCount);
																				toolbar
																						.appendNewRow(
																								editorcontainerid,
																								row,
																								i,
																								j,
																								subpanelIndex,
																								buttonSetSize);
																				jQuery
																						.each(
																								subpanel.comboactions,
																								function(
																										comboactionIndex,
																										comboactionValue) {
																									if (iconsPerRow === -1
																											|| (counter % iconsPerRow) !== 0
																											|| counter === 0) {
																									} else {
																										row++;
																										toolbar
																												.appendNewRow(
																														editorcontainerid,
																														row,
																														i,
																														j,
																														subpanelIndex,
																														buttonSetSize);
																									}
																									counter++;
																									var dropDownContent = [];
																									var actionProperties = "";
																									var cType = "json";
																									if (comboactionValue.dropdownactions === "font-family-toolbar") {
																										if (toolbarHelper.config.fontsettings !== undefined
																												&& toolbarHelper.config.fontsettings.usesystemfonts !== undefined
																												&& toolbarHelper.config.fontsettings.usesystemfonts === "true") {
																											dropDownContent = "#fontDropDownList_"
																													+ toolbarHelper.containerId;
																											cType = "selector";
																										} else {
																											dropDownContent
																													.push([
																															"default",
																															toolbarHelper.LocaleObject.L_DEFAULT_VALUE_TEXT ]);
																											if (toolbarHelper.config.fontsettings.fontlist !== undefined) {
																												jQuery
																														.each(
																																toolbarHelper.config.fontsettings.fontlist,
																																function(
																																		fontIndex,
																																		fontObject) {
																																	var itemValues = [];
																																	actionProperties = toolbar
																																			.getActionProperties(fontObject.family);
																																	itemValues
																																			.push(fontObject.family);
																																	if (actionProperties.actionId !== "undefined") {
																																		itemValues
																																				.push(actionProperties.actionTitle);
																																	} else {
																																		if (toolbarHelper.LocaleObject[fontObject.displayname] !== undefined) {
																																			itemValues
																																					.push(toolbarHelper.LocaleObject[fontObject.displayname]);
																																		} else {
																																			itemValues
																																					.push(fontObject.displayname);
																																		}
																																	}
																																	dropDownContent
																																			.push(itemValues);
																																});
																											}
																										}
																									} else {
																										jQuery
																												.each(
																														comboactionValue.dropdownactions,
																														function(
																																dropdownIndex,
																																dropdownValue) {
																															var itemValues = [];
																															actionProperties = toolbar
																																	.getActionProperties(dropdownIndex);
																															itemValues
																																	.push(dropdownIndex);
																															if (actionProperties.actionId !== "undefined") {
																																itemValues
																																		.push(actionProperties.actionTitle);
																															} else {
																																itemValues
																																		.push(dropdownValue);
																															}
																															dropDownContent
																																	.push(itemValues);
																														});
																									}
																									var cWidth = 100;
																									var dWidth = 100
																									if (comboactionValue.options.dropdownWidth !== undefined) {
																										dWidth = comboactionValue.options.dropdownWidth;
																									}
																									if (comboactionValue.options.comboWidth !== undefined) {
																										cWidth = comboactionValue.options.comboWidth;
																									}
																									var comboProperties = toolbar
																											.getActionProperties(comboactionIndex);
																									var comboactionTitle = comboProperties.actionTitle;
																									jQuery(
																											"#"
																													+ editorcontainerid
																													+ "_"
																													+ i
																													+ "_ribbonPanel_"
																													+ j
																													+ "_subPanel_"
																													+ subpanelIndex
																													+ "_row"
																													+ row)
																											.append(
																													"<td class=\"eongbutton\"><div class=\"enabled toolbarDropdown\" id=\"toolbarDropdown_"
																															+ i
																															+ "_"
																															+ toolbarHelper.containerId
																															+ "_"
																															+ comboactionIndex
																															+ "\"></div></td>");
																									jQuery(
																											"#toolbarDropdown_"
																													+ i
																													+ "_"
																													+ toolbarHelper.containerId
																													+ "_"
																													+ comboactionIndex)
																											.romenu(
																													{
																														content : dropDownContent,
																														contentType : cType,
																														showSpeed : 200,
																														combobox : true,
																														comboboxClass : "editorAction_"
																																+ editorcontainerid
																																+ " enabled",
																														comboboxName : comboactionIndex,
																														comboboxTitle : comboactionTitle,
																														comboAlign : "right",
																														directionV : "down",
																														iconDirection : "down",
																														comboWidth : cWidth,
																														dropdownWidth : dWidth,
																														onSelect : function() {
																															var action = jQuery(
																																	this)
																																	.attr(
																																			"alt");
																															var actionProperties = toolbar
																																	.getActionProperties(action);
																															if (actionProperties.actionId !== "undefined") {
																																toolbarHelper.jsObj
																																		.invokeAction(action);
																															} else {
																																var actionCommand = jQuery(
																																		this)
																																		.attr(
																																				"alt");
																																if (actionCommand === toolbarHelper.LocaleObject["L_DEFAULT_TEXT"]
																																		|| actionCommand === "default") {
																																	actionCommand = "[Default]";
																																}
																																toolbarHelper.jsObj
																																		.invokeAction(
																																				comboactionIndex,
																																				actionCommand);
																															}
																														},
																														onComboChange : function() {
																															var actionCommand = jQuery(
																																	this)
																																	.val()
																															if (actionCommand === toolbarHelper.LocaleObject["L_DEFAULT_TEXT"]) {
																																actionCommand = "[Default]";
																															}
																															toolbarHelper.jsObj
																																	.invokeAction(
																																			comboactionIndex,
																																			actionCommand);
																														},
																														onShowDropDown : function() {
																															toolbarHelper
																																	.replaceEditor(true);
																														},
																														onCloseDropDown : function() {
																															toolbarHelper
																																	.replaceEditor(false);
																														}
																													});
																								});
																			} else {
																				toolbar
																						.appendSubPanel(
																								editorcontainerid,
																								i,
																								j,
																								subpanelIndex,
																								buttonSetSize);
																				actionCount = toolbar
																						.getActionCount(subpanel);
																				iconsPerRow = toolbar
																						.getIconsPerRow(
																								buttonSetSize,
																								actionCount);
																				toolbar
																						.appendNewRow(
																								editorcontainerid,
																								row,
																								i,
																								j,
																								subpanelIndex,
																								buttonSetSize);
																				jQuery
																						.each(
																								subpanel.actions,
																								function(
																										k,
																										valk) {
																									actionProperties = toolbar
																											.getActionProperties(
																													valk,
																													false,
																													subpanel.size);
																									var displayText = false;
																									if (subpanel.displaytext !== undefined
																											&& (subpanel.displaytext === "true" || subpanel.displaytext === true)) {
																										displayText = true;
																									}
																									if (iconsPerRow === -1
																											|| (counter % iconsPerRow) !== 0
																											|| counter === 0) {
																										toolbar
																												.createToolbarButton(
																														editorcontainerid,
																														actionProperties,
																														row,
																														i,
																														j,
																														subpanelIndex,
																														subpanel.size,
																														displayText);
																									} else {
																										row++;
																										toolbar
																												.appendNewRow(
																														editorcontainerid,
																														row,
																														i,
																														j,
																														subpanelIndex,
																														buttonSetSize);
																										toolbar
																												.createToolbarButton(
																														editorcontainerid,
																														actionProperties,
																														row,
																														i,
																														j,
																														subpanelIndex,
																														subpanel.size,
																														displayText);
																									}
																									counter++;
																								});
																			}
																		});
														toolbar
																.appendDescription(
																		editorcontainerid,
																		paneLocaleName,
																		i, j);
													} else {
														if (valj.options !== undefined
																&& valj.options !== null) {
															var buttonSetSize = valj.options.size;
															if (buttonSetSize === "dropdownPanel") {
																toolbar
																		.appendSubPanelContainer(
																				editorcontainerid,
																				i,
																				j);
																toolbar
																		.appendSubPanel(
																				editorcontainerid,
																				i,
																				j,
																				0,
																				buttonSetSize);
																actionCount = toolbar
																		.getActionCount(valj);
																iconsPerRow = toolbar
																		.getIconsPerRow(
																				buttonSetSize,
																				actionCount);
																toolbar
																		.appendNewRow(
																				editorcontainerid,
																				row,
																				i,
																				j,
																				0,
																				buttonSetSize);
																jQuery
																		.each(
																				valj.comboactions,
																				function(
																						comboactionIndex,
																						comboactionValue) {
																					if (iconsPerRow === -1
																							|| (counter % iconsPerRow) !== 0
																							|| counter === 0) {
																					} else {
																						row++;
																						toolbar
																								.appendNewRow(
																										editorcontainerid,
																										row,
																										i,
																										j,
																										0,
																										buttonSetSize);
																					}
																					counter++;
																					var dropDownContent = [];
																					var actionProperties = "";
																					var cType = "json";
																					if (comboactionValue.dropdownactions === "font-family-toolbar") {
																						if (toolbarHelper.config.fontsettings !== undefined
																								&& toolbarHelper.config.fontsettings.usesystemfonts !== undefined
																								&& toolbarHelper.config.fontsettings.usesystemfonts === "true") {
																							dropDownContent = "#fontDropDownList_"
																									+ toolbarHelper.containerId;
																							cType = "selector";
																						} else {
																							dropDownContent
																									.push([
																											"default",
																											toolbarHelper.LocaleObject.L_DEFAULT_VALUE_TEXT ])
																							if (toolbarHelper.config.fontsettings.fontlist !== undefined) {
																								jQuery
																										.each(
																												toolbarHelper.config.fontsettings.fontlist,
																												function(
																														fontIndex,
																														fontObject) {
																													var itemValues = [];
																													actionProperties = toolbar
																															.getActionProperties(fontObject.family);
																													itemValues
																															.push(fontObject.family);
																													if (actionProperties.actionId !== "undefined") {
																														itemValues
																																.push(actionProperties.actionTitle);
																													} else {
																														if (toolbarHelper.LocaleObject[fontObject.displayname] !== undefined) {
																															itemValues
																																	.push(toolbarHelper.LocaleObject[fontObject.displayname]);
																														} else {
																															itemValues
																																	.push(fontObject.displayname);
																														}
																													}
																													dropDownContent
																															.push(itemValues);
																												});
																							}
																						}
																					} else {
																						jQuery
																								.each(
																										comboactionValue.dropdownactions,
																										function(
																												dropdownIndex,
																												dropdownValue) {
																											var itemValues = [];
																											actionProperties = toolbar
																													.getActionProperties(dropdownIndex);
																											itemValues
																													.push(dropdownIndex);
																											if (actionProperties.actionId !== "undefined") {
																												itemValues
																														.push(actionProperties.actionTitle);
																											} else {
																												itemValues
																														.push(dropdownValue);
																											}
																											dropDownContent
																													.push(itemValues);
																										});
																					}
																					var cWidth = 100;
																					var dWidth = 100
																					if (comboactionValue.options.dropdownWidth !== undefined) {
																						dWidth = comboactionValue.options.dropdownWidth;
																					}
																					if (comboactionValue.options.comboWidth !== undefined) {
																						cWidth = comboactionValue.options.comboWidth;
																					}
																					var comboProperties = toolbar
																							.getActionProperties(comboactionIndex);
																					var comboactionTitle = comboProperties.actionTitle;
																					jQuery(
																							"#"
																									+ editorcontainerid
																									+ "_"
																									+ i
																									+ "_ribbonPanel_"
																									+ j
																									+ "_subPanel_"
																									+ 0
																									+ "_row"
																									+ row)
																							.append(
																									"<td class=\"eongbutton\"><div class=\"enabled toolbarDropdown\" id=\"toolbarDropdown_"
																											+ i
																											+ "_"
																											+ toolbarHelper.containerId
																											+ "_"
																											+ comboactionIndex
																											+ "\"></div></td>");
																					jQuery(
																							"#toolbarDropdown_"
																									+ i
																									+ "_"
																									+ toolbarHelper.containerId
																									+ "_"
																									+ comboactionIndex)
																							.romenu(
																									{
																										content : dropDownContent,
																										contentType : cType,
																										showSpeed : 200,
																										combobox : true,
																										comboboxClass : "editorAction_"
																												+ editorcontainerid
																												+ " enabled",
																										comboboxName : comboactionIndex,
																										comboboxTitle : comboactionTitle,
																										comboAlign : "right",
																										directionV : "down",
																										iconDirection : "down",
																										comboWidth : cWidth,
																										dropdownWidth : dWidth,
																										onSelect : function() {
																											var action = jQuery(
																													this)
																													.attr(
																															"alt");
																											var actionProperties = toolbar
																													.getActionProperties(action);
																											if (actionProperties.actionId !== "undefined") {
																												toolbarHelper.jsObj
																														.invokeAction(action);
																											} else {
																												var actionCommand = jQuery(
																														this)
																														.attr(
																																"alt");
																												if (actionCommand === toolbarHelper.LocaleObject["L_DEFAULT_TEXT"]
																														|| actionCommand === "default") {
																													actionCommand = "[Default]";
																												}
																												toolbarHelper.jsObj
																														.invokeAction(
																																comboactionIndex,
																																actionCommand);
																											}
																										},
																										onComboChange : function() {
																											var actionCommand = jQuery(
																													this)
																													.val()
																											if (actionCommand === toolbarHelper.LocaleObject["L_DEFAULT_TEXT"]) {
																												actionCommand = "[Default]";
																											}
																											toolbarHelper.jsObj
																													.invokeAction(
																															comboactionIndex,
																															actionCommand);
																										},
																										onShowDropDown : function() {
																											toolbarHelper
																													.replaceEditor(true);
																										},
																										onCloseDropDown : function() {
																											toolbarHelper
																													.replaceEditor(false);
																										}
																									});
																				});
																toolbar
																		.appendDescription(
																				editorcontainerid,
																				paneLocaleName,
																				i,
																				j);
															} else {
																toolbar
																		.appendSubPanelContainer(
																				editorcontainerid,
																				i,
																				j);
																toolbar
																		.appendSubPanel(
																				editorcontainerid,
																				i,
																				j,
																				0,
																				buttonSetSize);
																actionCount = toolbar
																		.getActionCount(valj);
																iconsPerRow = toolbar
																		.getIconsPerRow(
																				buttonSetSize,
																				actionCount);
																toolbar
																		.appendNewRow(
																				editorcontainerid,
																				row,
																				i,
																				j,
																				0,
																				buttonSetSize);
																jQuery
																		.each(
																				valj.actions,
																				function(
																						k,
																						valk) {
																					actionProperties = toolbar
																							.getActionProperties(
																									valk,
																									false,
																									buttonSetSize);
																					var displayText = false;
																					if (valj.options.displaytext !== undefined
																							&& (valj.options.displaytext === "true" || valj.options.displaytext === true)) {
																						displayText = true;
																					}
																					if (iconsPerRow === -1
																							|| (counter % iconsPerRow) !== 0
																							|| counter === 0) {
																						toolbar
																								.createToolbarButton(
																										editorcontainerid,
																										actionProperties,
																										row,
																										i,
																										j,
																										0,
																										buttonSetSize,
																										displayText);
																					} else {
																						row++;
																						toolbar
																								.appendNewRow(
																										editorcontainerid,
																										row,
																										i,
																										j,
																										0,
																										buttonSetSize);
																						toolbar
																								.createToolbarButton(
																										editorcontainerid,
																										actionProperties,
																										row,
																										i,
																										j,
																										0,
																										buttonSetSize,
																										displayText);
																					}
																					counter++;
																				});
																toolbar
																		.appendDescription(
																				editorcontainerid,
																				paneLocaleName,
																				i,
																				j);
															}
														}
													}
												});
							}
							if (toolbarHelper.config.toolbarsortablepanes !== undefined
									&& toolbarHelper.config.toolbarsortablepanes == "true") {
								toolbar.addSortable(editorcontainerid, i);
							}
						});
		if (toolbarHelper.isMSIE && toolbarHelper.BrowserVersion == "6.0") {
			toolbarHelper
					.toggleButtonHover(
							".eongbutton div:not(.zoomSliderDecreaseButton div, .zoomSliderIncreaseButton div, .toolbarDropdown)",
							"hover");
		}
		toolbarHelper
				.toggleButtonHover(
						".eongbutton div:not(.zoomSliderDecreaseButton div, .zoomSliderIncreaseButton div, .toolbarDropdown), #dragHandler_"
								+ editorcontainerid
								+ ", #toggleFullscreenMode_"
								+ editorcontainerid, "ui-state-hover");
	};
	this.appendContainers = function(toolbarwidth, editorcontainerid) {
		jQuery("#" + editorcontainerid + "_toolbar")
				.append(
						"<div style=\"width:"
								+ toolbarwidth
								+ ";\" id=\""
								+ editorcontainerid
								+ "_toolbar_container\" class=\"ui-corner-top\"></div>");
		jQuery("#" + editorcontainerid + "_toolbar_container").append(
				"<ul id=\"" + editorcontainerid
						+ "_ribbon_tab_container\"></ul>");
	};
	this.appendTabHTML = function(editorcontainerid) {
		var tabLocaleName = "";
		tabCounter = 0;
		jQuery.each(this.uiconfig.toolbar.ribbons.elements, function(i, val) {
			if (toolbarHelper.LocaleObject[i] !== undefined) {
				tabLocaleName = toolbarHelper.LocaleObject[i];
			} else {
				tabLocaleName = i;
			}
			jQuery("#" + editorcontainerid + "_ribbon_tab_container").append(
					"<li id=\"" + editorcontainerid + "_tab_li_" + i
							+ "\"><a href=\"#" + editorcontainerid
							+ "_tab_panel_" + i + "\">" + tabLocaleName
							+ "</a></li>");
			tabCounter++;
		});
	};
	this.appendIconContainer = function(editorcontainerid) {
		jQuery("#" + editorcontainerid + "_toolbar_container")
				.append(
						"<div id=\"iconContainer_"
								+ editorcontainerid
								+ "\" style=\"float: right; position: relative; margin-top: -21px; margin-right: 3px;\"></div>");
	}
	this.appendFullScreenButton = function(editorcontainerid) {
		if (toolbarHelper.isFullscreenMode) {
			jQuery("#iconContainer_" + editorcontainerid)
					.append(
							"<div id=\"toggleFullscreenMode_"
									+ editorcontainerid
									+ "\" style=\"float: left;\" class=\"ui-state-default ui-corner-all\"><span unselectable=\"on\" class=\"ui-icon ui-icon-newwin\" title=\""
									+ toolbarHelper.LocaleObject.L_RESTORE_DOWN
									+ "\">&nbsp;</span></div>");
		} else {
			jQuery("#iconContainer_" + editorcontainerid)
					.append(
							"<div id=\"toggleFullscreenMode_"
									+ editorcontainerid
									+ "\" style=\"float: left;\" class=\"ui-state-default ui-corner-all\"><span unselectable=\"on\" class=\"ui-icon ui-icon-extlink\" title=\""
									+ toolbarHelper.LocaleObject.L_MAXIMIZE
									+ "\">&nbsp;</span></div>");
		}
		jQuery("#toggleFullscreenMode_" + editorcontainerid).bind('click',
				function(e) {
					toolbarHelper.toggleFullscreenMode();
				});
	};
	this.appendDragHandle = function(editorcontainerid) {
		jQuery("#iconContainer_" + editorcontainerid)
				.append(
						"<div id=\"dragHandler_"
								+ editorcontainerid
								+ "\" style=\"float: left;\" class=\"ui-state-default ui-corner-all\"><span unselectable=\"on\" class=\"ui-icon ui-icon-arrow-4-diag\" title=\""
								+ toolbarHelper.LocaleObject.L_DRAG
								+ "\"></span></div>");
	};
	this.appendQuickIcons = function(editorcontainerid) {
		if (this.uiconfig.toolbar.quickactions !== undefined) {
			jQuery("#" + editorcontainerid + "_toolbar_container ul")
					.prepend(
							"<div id=\"quickIcons_"
									+ editorcontainerid
									+ "\" class=\"quickIcons ribbonPanelquickPanel\"></div>");
			var tableString = "<table class=\"ribbonPanel\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr class=\"quickPanel\">";
			jQuery.each(this.uiconfig.toolbar.quickactions, function(index,
					value) {
				actionProperties = toolbar.getActionProperties(value, true);
				tableString += "<td class=\"eongbutton\">"
						+ "<div class=\"disabled ui-widget-header\">"
						+ "<button class=\"buttonImage editorAction_"
						+ editorcontainerid + " disabled\" name=\""
						+ actionProperties.actionId + "\""
						+ "style=\"background-image: url("
						+ actionProperties.iconURL + ");\"" + "title=\""
						+ actionProperties.actionTitle + "\" type=\"button\"/>"
						+ "</div>" + "</td>";
			});
			tableString += "</tr></table>";
			jQuery("#quickIcons_" + editorcontainerid).append(tableString);
		}
	};
	this.appenTabContentContainer = function(editorcontainerid) {
		jQuery
				.each(
						this.uiconfig.toolbar.ribbons.elements,
						function(i, val) {
							jQuery(
									"#" + editorcontainerid
											+ "_toolbar_container")
									.append(
											"<div style=\"padding-bottom: 0 !important;\" id=\""
													+ editorcontainerid
													+ "_tab_panel_"
													+ i
													+ "\"><div id=\""
													+ editorcontainerid
													+ "_ribbonPanelHolder_"
													+ i
													+ "\" class=\"dialogPanels\"></div><div style=\"clear: both\"></div></div>");
						});
	};
	this.createTabs = function(editorcontainerid, fake) {
		if (this.config.saveuistate !== undefined
				&& this.config.saveuistate == "true") {
			var selectedTab = 0;
			if (!fake) {
				upTab = toolbarHelper.getInitialUserPreferences("selectedtab");
				if (upTab !== null) {
					if (upTab[toolbarHelper.getLocation()] !== undefined
							&& upTab[toolbarHelper.getLocation()] !== null
							&& upTab[toolbarHelper.getLocation()] !== "") {
						if (upTab[toolbarHelper.getLocation()][toolbarHelper.containerId] !== undefined
								&& upTab[toolbarHelper.getLocation()][toolbarHelper.containerId] !== null
								&& upTab[toolbarHelper.getLocation()][toolbarHelper.containerId] !== "") {
							selectedTabId = upTab[toolbarHelper.getLocation()][toolbarHelper.containerId];
							tabs = jQuery(
									"#" + toolbarHelper.containerId
											+ "_ribbon_tab_container")
									.children("li");
							jQuery.each(tabs, function(index, value) {
								if (value.id === selectedTabId) {
									selectedTab = index;
								}
							});
						}
					}
				}
			}
			disabledArray = [];
			for (var i = 0; i < tabCounter; i++) {
				if (i !== selectedTab) {
					disabledArray.push(i);
				}
			}
			if (this.uiconfig.toolbar.ribbons.options !== undefined) {
				if (this.uiconfig.toolbar.ribbons.options.sortabletabs !== undefined
						&& this.uiconfig.toolbar.ribbons.options.sortabletabs == "true") {
					jQuery("#" + editorcontainerid + "_toolbar_container")
							.tabs(
									{
										selected : selectedTab,
										disabled : disabledArray,
										select : function(event, ui) {
											var tab_id = ui.tab.offsetParent.id;
											if (toolbarHelper.initialized) {
												var tabObject = toolbarHelper
														.getUserPreferences("selectedtab");
												if (tabObject !== null) {
												} else {
													tabObject = {};
												}
												if (tabObject[toolbarHelper
														.getLocation()] !== undefined) {
												} else {
													tabObject[toolbarHelper
															.getLocation()] = {};
												}
												tabObject[toolbarHelper
														.getLocation()][toolbarHelper.containerId] = tab_id;
												toolbarHelper
														.setUserPreferences({
															"selectedtab" : tabObject
														});
											}
										}
									}).find(".ui-tabs-nav").sortable({
								axis : 'x',
								containment : 'parent',
								items : 'li',
								stop : function(event, ui) {
									toolbarHelper.createToolbarObjectFromDOM();
								}
							});
				} else {
					jQuery("#" + editorcontainerid + "_toolbar_container")
							.tabs(
									{
										selected : selectedTab,
										select : function(event, ui) {
											var tab_id = ui.tab.offsetParent.id;
											if (toolbarHelper.initialized) {
												var tabObject = toolbarHelper
														.getUserPreferences("selectedtab");
												if (tabObject !== null) {
												} else {
													tabObject = {};
												}
												if (tabObject[toolbarHelper
														.getLocation()] !== undefined) {
												} else {
													tabObject[toolbarHelper
															.getLocation()] = {};
												}
												tabObject[toolbarHelper
														.getLocation()][toolbarHelper.containerId] = tab_id;
												toolbarHelper
														.setUserPreferences({
															"selectedtab" : tabObject
														});
											}
										}
									});
				}
			} else {
				jQuery("#" + editorcontainerid + "_toolbar_container")
						.tabs(
								{
									selected : selectedTab,
									select : function(event, ui) {
										var tab_id = ui.tab.offsetParent.id;
										if (toolbarHelper.initialized) {
											var tabObject = toolbarHelper
													.getUserPreferences("selectedtab");
											if (tabObject !== null) {
											} else {
												tabObject = {};
											}
											if (tabObject[toolbarHelper
													.getLocation()] !== undefined) {
											} else {
												tabObject[toolbarHelper
														.getLocation()] = {};
											}
											tabObject[toolbarHelper
													.getLocation()][toolbarHelper.containerId] = tab_id;
											toolbarHelper.setUserPreferences({
												"selectedtab" : tabObject
											});
										}
									}
								});
			}
		} else {
			disabledArray = [];
			for (var i = 0; i < tabCounter; i++) {
				if (i !== 1) {
					disabledArray.push(i);
				}
			}
			if (this.uiconfig.toolbar.ribbons.options.sortabletabs !== undefined
					&& this.uiconfig.toolbar.ribbons.options.sortabletabs == "true") {
				jQuery("#" + editorcontainerid + "_toolbar_container").tabs({
					selected : 0,
					disabled : disabledArray
				}).find(".ui-tabs-nav").sortable({
					axis : 'x',
					items : 'li',
					containment : 'parent',
					stop : function(event, ui) {
						toolbarHelper.createToolbarObjectFromDOM();
					}
				});
			} else {
				jQuery("#" + editorcontainerid + "_toolbar_container").tabs({
					selected : 0,
					disabled : disabledArray
				});
			}
		}
	};
	this.appendDescription = function(editorcontainerid, paneLocaleName, i, j) {
		jQuery("#subPanelContainer_" + i + "_" + j + "_" + editorcontainerid)
				.append(
						"<div style=\"clear: both;\"></div><p class=\"ribbonPanelDescription ui-widget-header\">"
								+ paneLocaleName + "</p>");
	};
	this.getActionProperties = function(valk, quickaction, size) {
		var properties = {};
		if (toolbarHelper.ActionMap[valk] !== undefined) {
			if (quickaction === undefined) {
				quickaction = false;
			}
			var actionTitle = "";
			try {
				if (toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].title] === null
						|| toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].title] === undefined) {
					actionTitle = toolbarHelper
							.htmlspecialchars(toolbarHelper.ActionMap[valk].title);
				} else {
					actionTitle = toolbarHelper
							.htmlspecialchars(toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].title]);
				}
			} catch (err1) {
				actionTitle = "Not available";
			}
			var iconText = "";
			try {
				if (toolbarHelper.ActionMap[valk].iconText === null
						|| toolbarHelper.ActionMap[valk].iconText === undefined) {
					iconText = actionTitle;
				} else if (toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].iconText] === null
						|| toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].iconText] === undefined) {
					iconText = toolbarHelper
							.htmlspecialchars(toolbarHelper.ActionMap[valk].iconText);
				} else {
					iconText = toolbarHelper
							.htmlspecialchars(toolbarHelper.LocaleObject[toolbarHelper.ActionMap[valk].iconText]);
				}
			} catch (err1) {
				iconText = "Not available";
			}
			var actionId = "";
			try {
				actionId = valk;
			} catch (err3) {
				actionId = "actionContextMissing";
			}
			var iconURL = undefined;
			if (quickaction) {
				try {
					iconURL = toolbarHelper.ActionMap[valk].smallIconURL;
				} catch (err4) {
				}
			} else {
				try {
					iconURL = toolbarHelper.ActionMap[valk].iconURL;
				} catch (err4) {
				}
			}
			if (size != undefined) {
				try {
					switch (size) {
					case "tinyPanel":
						if (toolbarHelper.ActionMap[valk]["iconURLTinyPanel"] != undefined) {
							iconURL = toolbarHelper.ActionMap[valk]["iconURLTinyPanel"];
						}
						break;
					case "smallPanel":
						if (toolbarHelper.ActionMap[valk]["iconURLSmallPanel"] != undefined) {
							iconURL = toolbarHelper.ActionMap[valk]["iconURLSmallPanel"];
						}
						break;
					case "mediumPanel":
						if (toolbarHelper.ActionMap[valk]["iconURLMediumPanel"] != undefined) {
							iconURL = toolbarHelper.ActionMap[valk]["iconURLMediumPanel"];
						}
						break;
					case "largePanel":
						if (toolbarHelper.ActionMap[valk]["iconURLLargePanel"] != undefined) {
							iconURL = toolbarHelper.ActionMap[valk]["iconURLLargePanel"];
						}
						break;
					}
				} catch (err) {
				}
			}
			if (iconURL === undefined) {
				if (toolbarHelper.iconRepositoryURL === ""
						|| toolbarHelper.iconRepositoryURL === null) {
					iconRepositoryURL = toolbarHelper.codebase + "/../icons";
				} else {
					iconRepositoryURL = toolbarHelper
							.resolveURL(toolbarHelper.iconRepositoryURL);
				}
				if (toolbarHelper.isMSIE
						&& parseInt(toolbarHelper.BrowserVersion) < 7) {
					if (quickaction) {
						iconURL = iconRepositoryURL + "/gif/"
								+ valk.toLowerCase() + "-small.gif";
					} else {
						iconURL = iconRepositoryURL + "/gif/"
								+ valk.toLowerCase() + ".gif";
					}
				} else {
					if (quickaction) {
						iconURL = iconRepositoryURL + "/" + valk.toLowerCase()
								+ "-small.png";
					} else {
						iconURL = iconRepositoryURL + "/" + valk.toLowerCase()
								+ ".png";
					}
				}
			} else {
				iconURL = toolbarHelper.resolveURL(iconURL);
			}
			var actionStatus = "disabled";
			properties.actionId = actionId;
			properties.iconURL = iconURL;
			properties.actionTitle = actionTitle;
			properties.actionStatus = actionStatus;
			properties.iconText = iconText;
			return properties;
		} else {
			properties.actionId = "undefined";
			properties.iconURL = "none";
			properties.actionTitle = "Action not available";
			properties.actionStatus = "disabled";
			properties.iconText = "none";
			return properties;
		}
	};
	this.createToolbarButton = function(editorcontainerid, actionProperties,
			row, i, j, panelIndex, size, displayText) {
		tmpContent = "<td class=\"eongbutton\">";
		tmpContent += "<div class=\"" + actionProperties.actionStatus
				+ " ui-corner-all\" style='text-align: center;'>";
		if (size === "largePanel") {
			if (displayText) {
				tmpContent += "<button type=\"button\" name=\""
						+ actionProperties.actionId
						+ "\" title=\""
						+ actionProperties.actionTitle
						+ "\" style=\"background-position: 0 -6px; background-image: url("
						+ actionProperties.iconURL
						+ ");\" class=\"buttonImage editorAction_"
						+ editorcontainerid + " "
						+ actionProperties.actionStatus + "\" />";
				tmpContent += "<p class='actionText' title='"
						+ actionProperties.actionTitle + "'>"
						+ actionProperties.iconText + "</p>";
			} else {
				tmpContent += "<button type=\"button\" name=\""
						+ actionProperties.actionId + "\" title=\""
						+ actionProperties.actionTitle
						+ "\" style=\"float: left; background-image: url("
						+ actionProperties.iconURL
						+ ");\" class=\"buttonImage editorAction_"
						+ editorcontainerid + " "
						+ actionProperties.actionStatus + "\" />";
			}
		} else {
			tmpContent += "<button type=\"button\" name=\""
					+ actionProperties.actionId + "\" title=\""
					+ actionProperties.actionTitle
					+ "\" style=\"float: left; background-image: url("
					+ actionProperties.iconURL
					+ ");\" class=\"buttonImage editorAction_"
					+ editorcontainerid + " " + actionProperties.actionStatus
					+ "\" />";
			if (displayText) {
				tmpContent += "<p class='actionText' title='"
						+ actionProperties.actionTitle + "'>"
						+ actionProperties.iconText + "</p>";
			}
		}
		tmpContent += "</div>";
		tmpContent += "</td>";
		jQuery(
				"#" + editorcontainerid + "_" + i + "_ribbonPanel_" + j
						+ "_subPanel_" + panelIndex + "_row" + row).append(
				tmpContent);
	};
	this.appendNewRow = function(editorcontainerid, row, i, j, panelIndex,
			buttonSetSize) {
		jQuery(
				"#" + i + "_ribbonPanel_inner_div_" + j + "_subPanel_"
						+ panelIndex + "_" + editorcontainerid).append(
				"<tr id=\"" + editorcontainerid + "_" + i + "_ribbonPanel_" + j
						+ "_subPanel_" + panelIndex + "_row" + row
						+ "\" class=\"" + buttonSetSize + "\"></tr>");
	};
	this.addSortable = function(editorcontainerid, i) {
		jQuery("#" + editorcontainerid + "_ribbonPanelHolder_" + i).sortable({
			items : ".sortablePanel",
			containment : "#" + editorcontainerid + "_tab_panel_" + i,
			axis : "x",
			handle : "p",
			stop : function(event, ui) {
				toolbarHelper.createToolbarObjectFromDOM();
			}
		});
	};
	this.appendSubPanelContainer = function(editorcontainerid, i, j) {
		var tmpContent = "<div class=\"ui-widget-content sortablePanel ribbonPanel\" id=\"subPanelContainer_"
				+ i + "_" + j + "_" + editorcontainerid + "\">";
		tmpContent += "</div>";
		jQuery("#" + editorcontainerid + "_ribbonPanelHolder_" + i).append(
				tmpContent);
	};
	this.appendSubPanel = function(editorcontainerid, i, j, panelIndex,
			buttonSetSize) {
		var tmpContent = "<div class=\"subPanel " + buttonSetSize
				+ "SubPanel\">";
		tmpContent += "<table id=\"" + i + "_ribbonPanel_inner_div_" + j
				+ "_subPanel_" + panelIndex + "_" + editorcontainerid
				+ "\" class=\"ribbonPanel\">";
		tmpContent += "</table>";
		tmpContent += "</div>";
		jQuery("#subPanelContainer_" + i + "_" + j + "_" + editorcontainerid)
				.append(tmpContent);
	};
	this.getIconsPerRow = function(buttonSetSize, actionCount) {
		if (buttonSetSize == "smallPanel" || buttonSetSize == "mediumPanel"
				|| buttonSetSize == "dropdownPanel") {
			iconsPerRow = Math.ceil(actionCount / 2);
		} else if (buttonSetSize == "tinyPanel") {
			iconsPerRow = Math.ceil(actionCount / 3);
		} else {
			iconsPerRow = actionCount;
		}
		return iconsPerRow;
	};
	this.getActionCount = function(valj) {
		var actionCount = 0;
		if (valj.actions !== undefined) {
			jQuery.each(valj.actions, function(c, cval) {
				actionCount++;
			});
		} else {
			jQuery.each(valj.comboactions, function(c, cval) {
				actionCount++;
			});
		}
		return actionCount;
	};
};