function id(elementId){	return document.getElementById(elementId);}
function ce(nodeType, attributes){var element = document.createElement(nodeType);for (var i in attributes){element[i] = attributes[i];} return element;}
function ac(parent, child){parent.appendChild(child); return child;}
function tx(str){return document.createTextNode(str);}
function cl(elt){if (elt){while (elt.firstChild){elt.removeChild(elt.firstChild);}}return elt;}
var imageDiv = ce("div");
var pxn8Div = ce("div");
pxn8Div.style.fontSize = "13pt";
pxn8Div.style.fontFamily = "Verdana, Arial";
pxn8Div.style.padding = "12px";
pxn8Div.style.backgroundColor = "#f0f0f0";
pxn8Div.style.borderBottom = "3px solid #cccccc";

ac(pxn8Div,tx("Click on any image to edit it in PXN8"));

var cancel = ce("a",{href: window.location.href});
cancel.style.textDecoration = "none";
cancel.style.padding = "6px";
cancel.style.backgroundColor = "#dddddd";
cancel.style.borderTop = "2px solid white";
cancel.style.borderLeft = "2px solid white";
cancel.style.borderBottom = "2px solid #bbbbbb";
cancel.style.borderRight = "2px solid #bbbbbb";
cancel.style.margin = "12px";

ac(cancel,tx("Cancel"));
ac(pxn8Div,cancel);

var d = document;
var images = d.getElementsByTagName('img');
var imagesForEdit = [];
for (var i = 0;i < images.length;i++){
	// ignore small images (less than 100x100)
	if ((images[i].width * images[i].height) < 10000)
       continue;
   else
       imagesForEdit.push(images[i]);
}
var bySize = function(a,b)
{
    var asize = a.width * a.height;
    var bsize = b.width * b.height;
    return bsize-asize;
}
imagesForEdit = imagesForEdit.sort(bySize);

var orderedList = ac(imageDiv,ce("ol"));
var seen = {};

for (var i = 0; i < imagesForEdit.length; i++)
{
    var imgSrc = imagesForEdit[i].src;

    if (seen[imgSrc]){
        continue;
    }
    
    seen[imgSrc] = true;
    var newlink = ce("a",{href: "http://pxn8.com/index.pl?image="+escape(imgSrc)});
    ac(newlink,ce("img",{border: 0,src: imgSrc}));

    var li = ce("li");
    li.style.margin = "28px";
    
    ac(li,newlink);
    ac(orderedList,li);
    
}
var body = d.getElementsByTagName('body')[0];
body.style.backgroundColor="white";
body.style.backgroundImage="none";
ac(cl(body),pxn8Div);
ac(body,imageDiv);





