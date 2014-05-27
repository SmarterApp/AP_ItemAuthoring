/*
 * This variable is used in Accessibility tagging to display names for the HTML content tags.
 * Only these HTML tags can be tagged for accessibility; 
 * 
 */
var tagNames = {"P" : "Paragraph", "SPAN" : "Block", "TH" : "Table Header", "TD" : "Table Cell", 
                "IMG" : "Image", "TR" : "Table Row", "TABLE" : "Table",
                "TEXT" : "Text", "MEDIA" : "Media", "DIV" : "Section", "A" : "Hyperlink", "MEDIA" : "Media",
                "LI" : "List Item", 
                "H1" : "Header", "H2" : "Header", "H3" : "Header", "H4" : "Header", "H5" : "Header", "H6" : "Header",
                "B"  : "Bold Text", "STRONG" : "Strong Text", "EM" : "Emphasis", "SMALL" : "Small Text", 
                "DFN" : "Definition", "CODE" : "Code", "SAMP" : "Sample", "KBD" : "Keyboard", "VAR" : "Variable",
                "ABBR" : "Abbreviation", "ARTICLE" : "Article", "BLOCKQUOTE" : "Block Quote", "BUTTON" : "Button",
                "CAPTION" : "Caption", "CITE" : "Title", "DD" : "Description", "DL" : "Definition List", "FIGURE" : "Figure",
                "FOOTER" : "Footer", "FORM" : "Form",  "HEADER" : "Header", "HGROUP" : "Header Group", "INS" : "Inserted",
                "I" : "Italic", "LABEL" : "Label", "LEGEND" : "Legend", "MARK" : "Marked Text", "OL" : "Ordered List",
                "PRE" : "Preformatted Text", "Q" : "Quotation", "SECTION" : "Section", "SUB" : "Subscripted", "SUP" : "Superscripted", 
                "TFOOT" : "Table Footer", "THEAD" : "Table Header", 
                "UL" : "Unordered List", "U" : "Underlined", 
                "MATH" : "Math"};


String.prototype.endsWith = function(suffix) {
    return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

if (typeof String.prototype.trim !== 'function') {
	String.prototype.trim = function() {
		return this.replace(/^\s+|\s+$/g, ''); 
	};
}

function stopEvent(e) {
	var event = e || window.event;
	//IE9 & Other Browsers
    if (event.stopPropagation) {
      event.stopPropagation();
    } //IE8 and Lower
    else {
      event.cancelBubble = true;
    }
}

function xmlToString(xmlDoc) {
    if (window.ActiveXObject) {
        return xmlDoc.xml;
    } else {
        return (new XMLSerializer()).serializeToString(xmlDoc);
    }
  }        

function popupWindowCentered(url, title, w, h) {
    var left = (screen.width/2)-(w/2);
    var top = (screen.height/2)-(h/2);
    window.open (url, title, 'toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=yes, resizable=yes, copyhistory=no, width='+w+', height='+h+', top='+top+', left='+left);
}


if (!Array.prototype.indexOf) { 
	 
	Array.prototype.indexOf = function(obj, start) { 
	    for (var i = (start || 0), j = this.length; i < j; i++) { 
	        if (this[i] === obj) { return i; } 
	    } 
	    return -1; 
	}; 
 
} 

if (!Array.prototype.forEach) {
    Array.prototype.forEach = function(fn, scope) {
        for(var i = 0, len = this.length; i < len; ++i) {
            fn.call(scope || this, this[i], i, this);
        }
    };
}

function hideWaitingDiv() {
    document.getElementById('waitingDiv').style.display = 'none';
}

function showWaitingDiv() {
    document.getElementById('waitingDiv').style.display = 'block';
}