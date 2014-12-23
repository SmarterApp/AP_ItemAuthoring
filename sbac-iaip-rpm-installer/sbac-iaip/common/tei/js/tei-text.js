var startsWithCR = new RegExp(" *\\n");

if(typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
        return this.replace(/^\s+|\s+$/g, ''); 
    };
}

var ieVersion = getInternetExplorerVersion();
var isIE8 = false;//ieVersion > 0 && ieVersion <= 8; 

//alert('IE' + ieVersion);

function textChange(paper, text, fontName, fontSize) {
    if (paper.txt) {
        paper.txt.attr({text: text});
    } else {
        paper.txt = paper.text(4, 0, text);
    }
    paper.txt.attr({"text-anchor": "start", "font-family": fontName, "font-size": fontSize});
    var bbox = paper.txt.getBBox(true);
    paper.txt.attr({y: (bbox.height / 2 + 5)});
}

function createText(paper, x, y, str, attr, fontName, fontSize) {
    var txt = paper.text(x, y + fontSize * 0.6, str);
    if (!isIE8) {
        txt.mouseover(txtMouseOver);
        txt.mouseout(txtMouseOut);
        txt.mousedown(txtMouseDown);
        txt.mouseup(txtMouseUp);
    }
    if (fontName && fontSize) {
        txt.attr({"font-family": fontName, "font-size": fontSize});
    }
    txt.attr(attr);
    txt.attr({cursor: 'default'});
    
    $(txt.node).css({
        "-webkit-touch-callout": "none",
        "-webkit-user-select": "none",
        "-khtml-user-select": "none",
        "-moz-user-select": "none",
        "-ms-user-select": "none",
        "user-select": "none"
    }); 
    
    return txt;
}

function createTextElements(paper, items, fontName, fontSize) {
    paper.clear();
    paper.fragments = items;
    paper.selectedFragment = undefined;
    paper.textHeight = undefined;
    paper.params.fontName = fontName;
    paper.params.fontSize = fontSize;
    paper.selectedCount = 0;
    paper.selecting = paper.deSelecting = false;
    if (paper.fragmentBGColor == undefined) {
        paper.fragmentBGColor = "lightgray";
    }
    var current = {x: 0, y: 0};
    for (var i = 0; i < items.length; i++) {
        current = addTextElements(paper, items[i], i, current, fontName, fontSize);
    }
    paper.fragmentMap = {};
    paper.forEach(function(el) {
        if (el.type == "text") {
            var bbox = el.getBBox(true);
            var rect = paper.rect(bbox.x, bbox.y, bbox.width, bbox.height);
            rect.attr({stroke: paper.fragmentBGColor, fill: paper.fragmentBGColor});
            rect.toBack();
            rect.innerText = el;
            if (isIE8) {
                rect.mouseover(function(e) {txtMouseOver.call(el, e);});
                rect.mouseout(function(e) {txtMouseOut.call(el, e);});
                rect.mouseup(function(e) {txtMouseUp.call(el, e);});
                rect.mousedown(function(e) {txtMouseDown.call(el, e);});
                rect.toFront();
            }
            var set = paper.fragmentMap[el.fragmentNo];
            if (set) {
            } else {
                set = paper.fragmentMap[el.fragmentNo] = paper.set();
            }
            set.push(rect);
        }
    });
}

function addTextElements(paper, fragment, fragmentNo, current, fontName, fontSize) {
    if (startsWithCR.test(fragment) && paper.textHeight) {
        current.x = 0;
        current.y += paper.textHeight + fontSize / 2;
    }
    fragment = fragment.trim();
    var spaceWidth = fontSize * 0.5;
    var txt = createText(paper, current.x, current.y, fragment, {"text-anchor": "start"}, fontName, fontSize);
    txt.fragmentNo = fragmentNo;
    var bbox = txt.getBBox(true);
    paper.textHeight = bbox.height;
    if (current.x + bbox.width <= paper.width - spaceWidth) {
        current.x += bbox.width;
        if (paper.textHeight > 2) {
            var rect = paper.rect(current.x, current.y + 1, spaceWidth, paper.textHeight - 2);
            rect.attr({fill: "white", "stroke": "white"});
        }
        current.x += spaceWidth;
    } else {
        fragment = trimTextElement(txt, current.x, paper.width - spaceWidth);
        current.x = 0;
        current.y += bbox.height;
        if (fragment.length > 0) 
        {
            addTextElements(paper, fragment, fragmentNo, current, fontName, fontSize);
        }
    }
    return current;
}

function trimTextElement(txt, x, margin) {
    var width = margin - x;
    var fragment = txt.attr("text").trim();
//  txt.attr({"text": ""});
    var newTxt = null, oldTxt = null;
    for (var i = 0; i < fragment.length; i++) {
        if (fragment.charAt(i) == ' ' || i == fragment.length - 1) {
            oldTxt = newTxt;
            newTxt = createText(txt.paper, -1000, -1000, fragment.substring(0, i + 1), txt.attr(["text-anchor", "font-family", "font-size"]));
            newTxt.fragmentNo = txt.fragmentNo;
            //txt.attr({"text": fragment.substring(0, i + 1)});
            if (newTxt.getBBox(true).width >= width) {
                if (oldTxt != null) {
                    oldTxt.attr(txt.attr(['x', 'y']));
                    txt.remove();
                    return fragment.substring(oldTxt.attr("text").length);
                } else {
                	newTxt.remove();
                    if (x > 0) {
                        txt.remove();
                        return fragment;
                    } else {
                        return fragment.substring(i + 1);
                    }
                }
            } else {
                if (oldTxt) {
                    oldTxt.remove();
                }
            }
        }
    }
    if (newTxt == null) {
        if (x > 0) {
            txt.remove();
            return fragment;
        } else {
            return "";
        }
    }
    return "";
}

txtMouseOver = function(e) {
    var paper = this.paper;
//    var set = paper.fragmentMap[this.fragmentNo];
    if (!this.selected) {
        paper.fragmentMap[this.fragmentNo].attr({stroke: "yellow", fill: "yellow"});
    }
    if (e.which == 1 && (paper.selecting || paper.deSelecting) && (paper.select || paper.selectAndEdit)) {
    	selectFragment(this);
    }
    paper.mouseOverFragmentChar = this.fragmentNo < 26 ? String.fromCharCode("A".charCodeAt() + this.fragmentNo) : "?";
};

txtMouseOut = function(e) {
    var paper = this.paper;
//    var bbox = this.getBBox(true);
    var color = this.selected ? "lightgreen" : paper.fragmentBGColor;
    paper.fragmentMap[this.fragmentNo].attr({stroke: color, fill: color});
    if (paper.fragmentOver) {
        paper.fragmentOver.remove();
    }
    paper.mouseOverFragmentChar = undefined;
};

txtMouseUp = function(e) {
    this.paper.selecting = false;
    this.paper.deSelecting = false;
};

txtMouseDown = function(e) {
	selectFragment(this);
};

function selectFragment(el) {
    var paper = el.paper;
    if (paper.reorder) {
        if (el.selected) {
            paper.selectedFragment = undefined;
            el.selected = false;
            if (paper.fragmentOver) {
                paper.fragmentOver.remove();
                paper.fragmentOver = undefined;
            }
        } else {
            if (paper.selectedFragment) {
                if (paper.selectedFragment.fragmentNo + 1 == el.fragmentNo) {
                    var oldText = paper.fragments[el.fragmentNo];
                    paper.fragments[el.fragmentNo] = paper.fragments[paper.selectedFragment.fragmentNo];
                    paper.fragments[paper.selectedFragment.fragmentNo] = oldText;
                } else {
                    paper.fragments.splice(el.fragmentNo, 0, paper.fragments[paper.selectedFragment.fragmentNo]);
                    if (paper.selectedFragment.fragmentNo > el.fragmentNo) {
                        paper.fragments.splice(paper.selectedFragment.fragmentNo + 1, 1); //delete selected fragment. it will be moved one position to the right
                    } else {
                        paper.fragments.splice(paper.selectedFragment.fragmentNo, 1);
                    }
                }
                createTextElements(paper, paper.fragments, paper.params.fontName, paper.params.fontSize);
                return;
            } else {
                el.selected = true;
                paper.selectedFragment = el;
            }
        }
    } else if (paper.select) {
        if (el.selected) {
            el.selected = false;
        } else {
            el.selected = true;
        }
    } else if (paper.selectAndEdit) {
        var before = findText(paper, el.fragmentNo - 1);
        var after = findText(paper, el.fragmentNo + 1);
        if (el.selected) {
            if (before == null || !before.selected || after == null || !after.selected) {
                el.selected = false;
                paper.selectedCount--;
                paper.deSelecting = true;
            }
        } else {
            if (paper.selectedCount == 0 ||
                (paper.selectedCount > 0 && ((before != null && before.selected) || (after != null && after.selected)))) {
                paper.selectedCount++;
                el.selected = true;
                paper.selecting = true;
            }
        }
        updateSelectedText(paper);
    }
    var color = el.selected ? "lightgreen" : "yellow";
    paper.fragmentMap[el.fragmentNo].attr({stroke: color, fill: color});
}

function updateSelectedText(paper) {
    var result = "";
    paper.forEach(function(el) {
        if (el.type == "text" && el.selected) {
            result += el.attr('text') + ' ';
        }
    });
    document.getElementById('changeTextArea').value = result;
}

function findText(paper, fragmentNo) {
    var result = null;
    paper.forEach(function(el) {
        if (el.type == "text" && el.fragmentNo == fragmentNo) {
            result = el;
        }
    });
    return result;
}

function splitText(text) {
    if (!document.getElementById('separatorParagraphs').checked) {
        text = text.replace(/\n+/g, ' ');
    }
    if (document.getElementById('separatorCharacter').checked) {
        return splitText2(text, document.getElementById('separatorChar').value);                
    } else if (document.getElementById('separatorParagraphs').checked) {
        return splitText2(text, "paragraphs");
    } else if (document.getElementById('separatorSentences').checked) {
        return splitText2(text, "sentences");
    } else if (document.getElementById('separatorWords').checked) {
        return splitText2(text, "words");
    }
    return [];
}

function splitText2(text, separator) {
	getPaper().params.separator = separator;
    var fragments = new Array();
    if (separator == "paragraphs") {
        fragments = text.split(/\n+/);
        for (var i = 0; i < fragments.length; i++) {
            fragments[i] += '\n';
        }
    } else if (separator == "sentences") {
        fragments = splitSentences(text);
    } else if (separator == "words") {
        fragments = text.split(/[\n ]+/);
    } else {
        if (separator.length > 0) {
            fragments = text.split(separator);
        }               
    }
    return fragments;
}

function splitSentences(text) {
    var fragments = [];
    var sentence = "";
    for (var i = 0; i < text.length; i++) {
        sentence += text.charAt(i); 
        if (text.charAt(i) == '.' || text.charAt(i) == '!' || text.charAt(i) == '?') {
            fragments.push(sentence);
            sentence = "";
        }
    }
    return fragments;
}

function reorderMouseMove(paper, x, y) {
    if (paper.selectedFragment) {
//      console.log(x, y);
        if (paper.fragmentOver) {
            paper.fragmentOver.remove();
        }
        
        var set = paper.fragmentMap[paper.selectedFragment.fragmentNo];
        
        paper.fragmentOver = set[0].innerText.clone();
        if (set.length > 1) {
            paper.fragmentOver.attr({text: paper.fragmentOver.attr("text") + '...'});
        }
        paper.fragmentOver.attr({x: x + 12, y: y + 17, opacity: 0.75});

    }
}

function textMouseMove(paper, x, y) {
//  console.log(x, y);
    if (paper.mouseOverFragmentChar) {
        if (!paper.mouseOverFragmentText) {
            paper.mouseOverFragmentText = paper.text(x + 12, y + 20, paper.mouseOverFragmentChar);
            paper.mouseOverFragmentText.attr({"text-anchor": "start", "font-family": "Arial Bold", "font-size": 40, "fill": "black", opacity: 0.75});
        } else {
            paper.mouseOverFragmentText.attr({"x": x + 12, "y": y + 20});
        }
        console.log(paper.mouseOverFragmentChar);
    } else {
        if (paper.mouseOverFragmentText) {
            paper.mouseOverFragmentText.remove();
            paper.mouseOverFragmentText = undefined;
        }
    }
}

function textMouseOut(paper, event) {
    if (paper.mouseOverFragmentText) {
        paper.mouseOverFragmentText.remove();
        paper.mouseOverFragmentText = undefined;
    }
}

function separatorChanged() {
    document.getElementById('separatorChar').disabled = !document.getElementById('separatorCharacter').checked;
    textChanged();
}

function textChanged() {
	var paper = getPaper();
	paper.params.workingText = document.getElementById('workingText').value;
    var fragments = splitText(paper.params.workingText);
    createTextElements(paper, fragments, document.getElementById('fontName').value, document.getElementById('fontSize').value);               
}

function setTextParams(workingText, separator, fontName, fontSize) {
	document.getElementById('workingText').value = workingText;
	if (separator == 'paragraphs') {
		document.getElementById('separatorParagraphs').checked = true;
	} else if (separator == 'sentences') {
		document.getElementById('separatorSentences').checked = true;
	} else if (separator == 'words') {
		document.getElementById('separatorWords').checked = true;
	} else {
		document.getElementById('separatorCharacter').checked = true;
		document.getElementById('separatorChar').value = separator;
	}
	document.getElementById('fontName').value = fontName;
	document.getElementById('fontSize').value = fontSize;
	separatorChanged();
}

function changeText(text) {
	var paper = getPaper();
	var firstSelected = -1, lastSelected = -1;
	paper.forEach(function(el) {
		if (el.type == "text" && el.selected) {
			if (firstSelected == -1) {
				firstSelected = el.fragmentNo;
			}
			lastSelected = el.fragmentNo;
		}
	});
	var newFragments = splitText2(text, paper.params.separator);
	paper.fragments = paper.fragments.slice(0, firstSelected).concat(newFragments, paper.fragments.slice(lastSelected + 1));
	createTextElements(paper, paper.fragments, paper.params.fontName, paper.params.fontSize);
	document.getElementById('changeTextArea').value = '';
}

