
var PXN8 = PXN8 || {};

PXN8.toolbar = {
    hidemenu: function(e){
        if (!e) var e = window.event;
        var tg = (window.event) ? e.srcElement : e.target;
        if (tg.nodeName != 'DIV') return;
        var reltg = (e.relatedTarget) ? e.relatedTarget : e.toElement;
        while (reltg != tg && reltg.nodeName != 'BODY'){
            reltg = reltg.parentNode;
        }
        if (reltg == tg) return;
        
        tg.style.display = "none";
    },
    /**
     * OnToolClick handles the special case of a toolbar button which 
     * has a default action or displays a dropdown menu of operations if the 
     * dropdown arrow is clicked.
     * menuDiv : the dropdown menu's div
     * button_offset: a numeric offset for where the dropdown arrow is
     * menuMap: A hash of menu text to functions
     * default_func: The default function to be called if the dropdown arrow
     * isn't clicked.
     */
    ontoolclick: function(event, menuDiv, button_offset, menuMap, default_func){
        var dom = PXN8.dom;
        if (!event){
            event = window.event;
        }
        var button = (window.event) ? event.srcElement : event.target;
        
        menuDiv.onmouseout = function(event){
            PXN8.toolbar.hidemenu(event);
        };

        if (menuDiv.style.display == "block"){
            menuDiv.style.display = "none";
            return;
        }

        /**
         * Hide all other dropdowns
         */
        var dropdowns = PXN8.dom.clz("pxn8_toolbar_dropdown");
        for (var i = 0; i < dropdowns.length; i++){
            var dropdown = dropdowns[i];
            dropdown.style.display = "none";
        }
        
            
        var pos = dom.eb(button);
        var ox = event.clientX - pos.x ;
        var oy = event.clientY - pos.y ;
        

        if (ox > button_offset){
            dom.cl(menuDiv);

            for (var i in menuMap){
                var link = dom.ce("a",{href: "javascript:void(0);",
                                       className: "pxn8_toolbar_option",
                                       onclick : menuMap[i].onclick});
                if (menuMap[i].image){
                    var linkImage = dom.ce("img", {border: 0, src: PXN8.root + "/" +menuMap[i].image});
                    dom.ac(link,linkImage);
                }
                
                dom.ac(link,dom.tx(i));
                dom.ac(menuDiv,link);
            }
            menuDiv.style.display = "block";
            menuDiv.style.top = pos.y + pos.height + 4 + "px";
            menuDiv.style.left = (pos.x - 4) + "px";
            
        }else{
            default_func();
        }
        return false;
    }
};
/**
 * Toolbar menu definitions go here
 */
PXN8.toolbar.menu = {
    crop: {},
    rotate: {},
    instantFix: {}
};

PXN8.toolbar.menu.rotate = {
    /**
     * Populate gets called by PXN8.toolbar.draw when the page first loads
     */ 
    populate: function(){
        
    }
};



/**
 *
 * You can override this value in your html
 * 
 */
PXN8.toolbar.crop_options = ["4x6","5x8"];

PXN8.toolbar.buttons = {
    'zoomin': {
        onclick: function(){PXN8.zoom.zoomIn();return false;},
        image: "/images/icons/magnifier_zoom_in.gif",
        tip: "Zoom In"
    },
    'zoomout': {
        onclick: function(){PXN8.zoom.zoomOut();return false;},
        image: "/images/icons/magnifier_zoom_out.gif",
        tip: "Zoom Out"
    },
    'rotate': {
        onclick: function(event){
            var dropdown = document.getElementById("pxn8_toolbar_rotate");
            var menuContents = {
                Clockwise: {
                    onclick: PXN8.curry(function(menu){
                        PXN8.tools.rotate({angle: 90});
                        menu.style.display = "none";
                    },dropdown),
                    image: "/images/icons/rotate_clockwise.gif"
                },
                
                "Anti-Clockwise": {
                    onclick: PXN8.curry(function(menu){
                        PXN8.tools.rotate({angle: 270});
                        menu.style.display = "none";
                    },dropdown),
                    image: "/images/icons/rotate_anticlockwise.gif"
                },
                "Flip Vertically": {
                    onclick: PXN8.curry(function(menu){
                        PXN8.tools.rotate({flipvt: "true"});
                        menu.style.display = "none";
                    },dropdown),
                    image: "/images/icons/shape_flip_vertical.gif"

                },
                "Flip Horizontally": {
                    onclick: PXN8.curry(function(menu){
                        PXN8.tools.rotate({fliphz: "true"});
                        menu.style.display = "none";
                    },dropdown),
                    image: "/images/icons/shape_flip_horizontal.gif"
                }
                
            };
            PXN8.toolbar.ontoolclick(event,dropdown,40,menuContents,function(){
                PXN8.tools.rotate({angle:90});
            });
            return false;
        }, 
        image: "/images/icons/rotate.gif",
        tip: "Rotate the photo by 90 degrees clockwise"
    },
    'add_text': {
        onclick: function(event){
        },
        image: "/images/icons/add_text.gif",
        tip: "Add Text to photo"
    },
    'normalize': {
        onclick: function(){PXN8.tools.normalize();return false;}, 
        image: "/images/icons/normalize.gif",
        tip: "Gives better color balance"
    },
    'enhance': {
        onclick: function(event){
            PXN8.tools.enhance();return false;
        }, 
        image: "/images/icons/enhance.gif",
        tip: "Smooths facial lines"
    },
    'save': {
        onclick: function(event){
            return PXN8.save.toServer();
        }, 
        image: "/images/icons/save.gif",
        tip: "Save image to server"
    },
    'instantFix': {
        onclick: function(event){

            var dropdown = document.getElementById("pxn8_toolbar_fix");
            var fixes = {
                Enhance: {onclick: PXN8.curry(function(menu){
                    PXN8.tools.enhance();
                    menu.style.display = "none";
                },dropdown)},
                
                Normalize: {onclick: PXN8.curry(function(menu){
                    PXN8.tools.normalize();
                    menu.style.display = "none";
                },dropdown)
                }
            };

            PXN8.toolbar.ontoolclick(event,dropdown,48,
                                     fixes,PXN8.tools.instantFix);
            
            return false;
        }, 
        image: "/images/icons/instant_fix.gif",
        tip: "A quick fix solution - gives better color balance and smooths lines"
    },
    
    'crop': {
        onclick: function(event){
            
            var dropdown = document.getElementById("pxn8_toolbar_crop");

            var callback = function(opt){
                return function(){
                    PXN8.selectByRatio(opt);
                    document.getElementById("pxn8_toolbar_crop").style.display = "none";
                };
            };

            var menuContents = {};
            
            for (var i = 0;i < PXN8.toolbar.crop_options.length; i++){
                var option = PXN8.toolbar.crop_options[i];
                menuContents[option] = {onclick: callback(option)};
            }

            PXN8.toolbar.ontoolclick(event,dropdown,40,menuContents,function(){
                var selection = PXN8.getSelection();
                
                if (selection.width > 0){
                    PXN8.tools.crop(selection);
                }else{
                    PXN8.show.alert("Select an area to crop");
                }
            });
            return false;
        },
        image: "/images/icons/cut_red.gif",
        tip: "Crop the image"
    },
    'fillflash': {
        onclick: function(){PXN8.tools.fill_flash();return false;},
        image: "/images/icons/lightning_add.gif",
        tip: "Add Fill-Flash to brighten the image"

    },
    'undo': {
        onclick: function(){PXN8.tools.undo();return false;},
        image: "/images/icons/undo.gif",
        tip: "Undo the last operation"

    },
    'redo': {
        onclick: function(){PXN8.tools.redo();return false;},
        image: "/images/icons/redo.gif",
        tip: "Redo the last operation"
    },
    'undoall': {
        onclick: function(){PXN8.tools.undoall();return false;}, 
        image: "/images/icons/undo_all.gif",
        tip: "Undo all operations"

    },
    'redoall': {
        onclick: function(){PXN8.tools.redoall();return false;}, 
        image: "/images/icons/redo_all.gif",
        tip: "Redo all operations"
    }
};
/**
 * Draw the toolbar
 */
PXN8.toolbar.draw = function(buttons){

    var dom = PXN8.dom;
    
    if (!buttons){
        buttons = new Array();
        for (var i in PXN8.toolbar.buttons){
            buttons.push(i);
        }
    }
    
    document.writeln("<table cellspacing='0' cellpadding='0'><tbody><tr id='pxn8_toolbar_table'></tr></tbody></table>");

    var dropdowns = ["pxn8_toolbar_crop", "pxn8_toolbar_fix", "pxn8_toolbar_rotate"];
    
    for (var i = 0;i < dropdowns.length; i++){
        document.writeln("<div id='" + dropdowns[i] + "' class='pxn8_toolbar_dropdown' style='display:none;'></div>");
    }
    /**
     * wph 20060704: Need to move the drop-down menus up to the 
     * document.body because the position will break inside a 
     * relative div.
     * Create a closure that will move the dropdown menus to the body
     * when executed.
     */
    function moveMenusToBody(){
        for (var i = 0;i < dropdowns.length; i++){
            var menuElement = document.getElementById(dropdowns[i]);
            var menuParent = menuElement.parentNode;
            menuParent.removeChild(menuElement);
            document.body.appendChild(menuElement);
        }
    };
    /**
     * Delay running the closure until the document has loaded.
     */
    PXN8.dom.addLoadEvent(moveMenusToBody);
    
	 var toolbar = dom.id('pxn8_toolbar_table');

    for (var h =0; h < buttons.length; h++)
    {
        var i= buttons[h];

        var widgetModel = PXN8.toolbar.buttons[i];
        
        var cell = dom.ac(toolbar,dom.ce("td"));
        var widget = dom.ce("a",{className: "pxn8_toolbar_btn", 
                                 href: "javascript:void(0);",
                                 onclick: widgetModel.onclick,
                                 title: widgetModel.tip,
                                 onmousedown: function(){this.className = 'pxn8_toolbar_btndown';},
                                 onmouseup: function(){this.className = 'pxn8_toolbar_btn';},
                                 onmouseout: function(){this.className = 'pxn8_toolbar_btn';}
        });

        
        
	     var arrowLink = dom.ce("a",{href: "javascript:void(0);",
                                    onclick: function(event,element){
                                        widgetModel.arrowClicked = widgetModel.arrowClicked==true?false:true;
                                    }
        });
                                
        dom.ac(cell,widget);
        var widgetImage = dom.ce("img", {border: 0, 
                                         alt: widgetModel.tip, 
                                         src: PXN8.root + widgetModel.image
        });
        dom.ac(widget,widgetImage);

    }

    dom.ac(dom.ac(dom.ac(toolbar,
                         dom.ce("td")),
                  dom.ce("a",{ href: "http://pxn8.com/"})),
           dom.ce("img",{border: 0, 
                         id: "pxn8_poweredby", 
                         src: PXN8.root + "/images/icons/powered_by_pxn8.gif"}));
    
};


