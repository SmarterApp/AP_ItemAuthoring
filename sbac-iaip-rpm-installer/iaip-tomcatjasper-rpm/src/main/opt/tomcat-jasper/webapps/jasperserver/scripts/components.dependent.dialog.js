dialogs.dependentResources = {
    dependenciesPanel: null,

    show: function(resources, actionsMap, options) {
        this.dependenciesPanel = jQuery("#dependencies");
        dialogs.popup.show(this.dependenciesPanel[0]);

        this._changeMessage(options);
        this._switchButtons(options);
        var list =
            this._initList(resources);

        ///////////////////////////////////////////////////////////
        // Observe buttons
        //////////////////////////////////////////////////////////
        this.dependenciesPanel.on("click", function(event){
            var buttonId = jQuery(event.target).closest('button').attr('id');
            var action = actionsMap && actionsMap[buttonId];
            if (_.include(["dependenciesBtnSave", "dependenciesBtnSaveAs", "dependenciesBtnOk", "dependenciesBtnCancel"], buttonId)) {
                dialogs.dependentResources.hide();
                list.setItems([]);

                event.stopPropagation();

                action && action();
            }
        });
//        designerBase.enableSelection();
    },

    hide: function () {
        if (this.dependenciesPanel) {
            this.dependenciesPanel.off("click");
            dialogs.popup.hide(this.dependenciesPanel[0]);
            this.dependenciesPanel = null;
        }
    },

    /**
     * Show message
     *
     * @param canSave
     * @private
     */
    _changeMessage: function(options) {
        jQuery("#topMessage").html(options.topMessage);
        jQuery("#bottomMessage").html(options.bottomMessage);
    },

    _initList: function(resources) {
        var list = new dynamicList.List("dependenciesList", {
            listTemplateDomId: "tabular_oneColumn",
            itemTemplateDomId: "tabular_oneColumn:leaf"
        });

        var items = [];
        if(resources) {
            items = resources.collect(function(resource) {
                var resourceItem = new dynamicList.ListItem({
                    cssClassName: layoutModule.LEAF_CLASS,
                    value: resource
                });

                resourceItem.processTemplate = function(element) {
                    var uriElement = element.select(".uri")[0];
                    var uri = this.getValue().uristring ? this.getValue().uristring : this.getValue().URIString;

                    uriElement.update(uri.escapeHTML());
                    return element;
                };
                return resourceItem;
            });
        }

        list.setItems(items);
        list.show();

        return list;
    },

    _switchButtons: function(options) {
        var saveBtn = jQuery("#dependenciesBtnSave");
        var saveAsBtn = jQuery("#dependenciesBtnSaveAs");
        var okBtn = jQuery("#dependenciesBtnOk");
        var cancelBtn = jQuery("#dependenciesBtnCancel");

        if (!!options.okOnly) {
            saveBtn.addClass("hidden");
            saveAsBtn.addClass("hidden");
            cancelBtn.addClass("hidden");
        } else {
            okBtn.addClass("hidden");
            if(!!options.canSave) {
                saveBtn.removeClass("hidden");
            } else {
                saveBtn.addClass("hidden");
            }
        }

    }
};