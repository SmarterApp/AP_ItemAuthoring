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

var resourceDataSource = {
    TYPE_ID: "typeID",
    PARAM_TYPE: "type",
    LABEL_ID: "labelID",
    RESOURCE_ID_ID: "nameID",
    DESCRIPTION_ID: "descriptionID",

    // JDBC
    DRIVER_ID: "driverID",
    URL_ID: "urlID",
    USER_NAME_ID: "userNameID",

    // JNDI
    SERVICE_ID: "serviceID",

    // Bean
    BEAN_NAME_ID: "beanNameID",
    BEAN_METHOD_ID: "beanMethodID",

    SUBMIT_BUTTON_ID: "done",
    SUBMIT_EVENT_ID: "submitEvent",
    TEST_BUTTON_ID: "testDataSource",
    CANCEL_BUTTON_ID: "dsCancel",
    PREVIOUS_BUTTON_ID: "previous",
    NEXT_BUTTON_ID: "next",
    SUB_DATASOURCES_TREE_ID: "subDataSourcesTree",
    SELECTED_SUB_DATASOURCES_LIST_ID: "selectedSubDataSourcesList",

    _canGenerateId: true,
    _alreadySubmitted: false,

    initialize: function(options) {
        var that = this;
        jQuery("form").on("keydown", "input[type=\"text\"]", function(ev) {
           if(ev.which == Event.KEY_RETURN) {
               ev.preventDefault();
               if(!jQuery(ev.target).hasClass("noSubmit")) {
                   $(resourceDataSource.SUBMIT_BUTTON_ID).click();
               }
           }
        });

        this._form = $(document.body).select('form')[0];
        this._submitEvent = $(this.SUBMIT_EVENT_ID);
        this._type = $(this.TYPE_ID);
        this._label = $(this.LABEL_ID);
        this._resourceId = $(this.RESOURCE_ID_ID);
        this._description = $(this.DESCRIPTION_ID);
        this._paramType = $(this.PARAM_TYPE);

        this._validationEntries = [];

        var type = this._type.getValue();
        if (type == "jdbc") {
            this._driver = $(this.DRIVER_ID);
            this._url = $(this.URL_ID);
            this._userName = $(this.USER_NAME_ID);

            this._validationEntries.push({element: this._driver,
                method: "mandatory",
                messages: {mandatory: resource.messages['driverIsEmpty']}
            });
            this._validationEntries.push({element: this._url,
                method: "mandatory",
                messages: {mandatory: resource.messages['urlIsEmpty']}
            });
            this._validationEntries.push({element: this._userName,
                method: "mandatory",
                messages: {mandatory: resource.messages['userNameIsEmpty']}
            });

        } else if (type == "jndi") {
            this._service = $(this.SERVICE_ID);

            this._validationEntries.push({element: this._service,
                method: "mandatory",
                messages: {mandatory: resource.messages['serviceIsEmpty']}
            });

        } else if (type == "bean") {
            this._beanName = $(this.BEAN_NAME_ID);
            this._beanMethod = $(this.BEAN_METHOD_ID);

            this._validationEntries.push({element: this._beanName,
                method: "mandatory",
                messages: {mandatory: resource.messages['beanNameIsEmpty']}
            });
            this._validationEntries.push({element: this._beanMethod,
                method: "mandatory",
                messages: {mandatory: resource.messages['beanMethodIsEmpty']}
            });

        } else if (type == "virtual") {
            this._showDependentResources(options.dependentResources);

            this._selDsList = new dynamicList.List(this.SELECTED_SUB_DATASOURCES_LIST_ID, {
                listTemplateDomId: "selectedDataSourcesTemplate",
                itemTemplateDomId: "selectedDataSourcesTemplate:leaf",
                dragPattern: '', //no DnD for now
                multiSelect: true,
                selectOnMousedown: !isIPad()
            });

            var valEntry = {
                element: that._selDsList._getElement(),
                selector: "input.dataSourceID",
                validators: [
                    {method: "wordChars",
                        messages: resource.messages},
                    {method: "mandatory",
                        messages: {mandatory: resource.messages['resourceIdIsEmpty']}},
                    {method: "minMaxLength",
                        messages: {tooLong: resource.messages['resourceIdToLong']},
                        options: {maxLength: resource.resourceIdMaxLength}}]
            };

            this._validationEntries.push(valEntry);
            that._selDsList._getElement().validationEntry = valEntry;


            this._selDsList.show();
            this._$selectedSubDs = jQuery("#selectedSubDs");
            this._validationEntries.push(this._$selectedSubDs[0].validationEntry = {
                element: this._$selectedSubDs[0],
                method: this._subDatasourcesValidator.bind(this)
            });

            var readOnlyIDs = options.dependentResources && options.dependentResources.length > 0;
            var subDsArray = this._updateSelectedSubDsFromField(readOnlyIDs);

            var treeOptions = {
                treeId: this.SUB_DATASOURCES_TREE_ID,
                providerId: 'joinableDsTreeDataProvider',
                selectLeavesOnly: true,
                multiSelectEnabled: true,
                treeOptions: {
                    organizationId: this.organizationId,
                    publicFolderUri: this.publicFolderUri
                }
            }
            this._subDsTree = dynamicTree.createRepositoryTree(this.SUB_DATASOURCES_TREE_ID, treeOptions);
            var prefetchNodesUri = [];
            if(subDsArray) {
                prefetchNodesUri = _.map(subDsArray, function(subDs) {return subDs.dsUri});
            }
            this._subDsTree.showTreePrefetchNodes(prefetchNodesUri.join(","), function(arg) {
                that._hideAvailableSubDs(prefetchNodesUri);
            });
        }

        this._submitButton = $(this.SUBMIT_BUTTON_ID);
        this._testButton = $(this.TEST_BUTTON_ID);
        this._cancelButton = $(this.CANCEL_BUTTON_ID);
        this._previousButton = $(this.PREVIOUS_BUTTON_ID);
        this._nextButton = $(this.NEXT_BUTTON_ID);

        this._isEditMode = options.isEditMode;
        this._initialType = options.type;
        this._parentFolderUri = options.parentFolderUri;
        this._connectionState = options.connectionState;

        this._validationEntries.push(resource.getLabelValidationEntry(this._label));
        this._validationEntries.push(resource.getIdValidationEntry(this._resourceId));
        this._validationEntries.push(resource.getDescriptionValidationEntry(this._description));

        resourceLocator.initialize({
            resourceInput : 'folderUri',
            browseButton : 'browser_button',
            treeId : 'addFileTreeRepoLocation',
            providerId : 'repositoryExplorerTreeFoldersProvider',
            dialogTitle : resource.messages["resource.Add.Files.Title"]
        });

        this._sortTypeSelect();
        this._initEvents();
        this._showConnectionState();
    },

    _showDependentResources: function(dependentResources) {
        if(!dependentResources || dependentResources.length == 0) {
            return;
        }
        dialogs.dependentResources.show(dependentResources,
            {}, //no actions, just inform user
            {
                canSave: false,
                okOnly: true,
                topMessage: resource.messages["dependenciesTopMessage"],
                bottomMessage: resource.messages["dependenciesBottomMessage"]
            });
    },

    _initEvents: function() {
        var that = this;
        this._type.observe('change', function(e) {
            var currentType = e.element().getValue();

            if (this._initialType != currentType) {
                this._paramType = currentType;
                this._form.submit();
            }
        }.bindAsEventListener(this));

        var submitHandler = function(e) {
            if (!this._isDataValid()) {
                e.stop();
            } else {
               this._submitEvent.writeAttribute("disabled", "disabled");
            }
        }.bindAsEventListener(this);

        var cancelHandler = function(e) {
            this._submitEvent.writeAttribute("disabled", "disabled");
        }.bindAsEventListener(this);

        this._submitButton.observe('click', submitHandler);
        this._nextButton.observe('click', submitHandler);
        this._testButton && this._testButton.observe('click', submitHandler);
        this._cancelButton.observe('click', cancelHandler);
        this._previousButton.observe('click', cancelHandler);

        this._form.observe('submit', function(e) {
            if (this._alreadySubmitted) {
                e.stop();
            } else {
                this._alreadySubmitted = true;
            }
        }.bindAsEventListener(this));

        ValidationModule.attachOnEvent("keyup", this._validationEntries);
        if(!this._isEditMode) {
            jQuery(this._resourceId).on("keyup", function(event) {
                if(that._resourceId.getValue() != resource.generateResourceId(that._label.getValue())) {
                    that._canGenerateId = false;
                }
            });
            jQuery(this._label).on("keyup", function(event) {
                if (that._canGenerateId) {
                    that._resourceId.setValue(resource.generateResourceId(that._label.getValue()));
                }
            });
        }

        if(this._type.getValue() == "virtual") {
            this._initVDSEvents();
        }
    },

    _initVDSEvents: function() { //init Virtual Data Source events
        var that = this;

        //init table selection buttons
        var butContainer = jQuery("#subDsSelectionContainer .moveButtons");
        var btn = this._$dsSelButtons = {
            right: butContainer.find(".right"),
            left: butContainer.find(".left"),
            allLeft: butContainer.find(".toLeft")
        }

        function node2SubDs(node) { //convert tree node into subDs object
            if(!node) {
                return null;
            } else {
                return {dsName: node.name, dsId: node.param.id, dsUri: node.param.uri};
            };
        }
        that._subDsHiddenNodes = {};

        function handleDsChoiceEvent(ev) {
            btn.right.attr("disabled", true);
            btn.right.removeClass("over");
            ev.preventDefault();
            var nodes = that._subDsTree.selectedNodes;
            _.each(nodes, function(node) {
                var selDs = node2SubDs(node);
                if(selDs) {
                    that._addSubDsCore(selDs);
                }
            });
            var nodeUris = _.map(nodes, function(node) {
                return node.param.uri;
            });
            that._hideAvailableSubDs(nodeUris);
            that._updateSelectedSubDsField();

            //select moved nodes in selected DS list
            that._selDsList.resetSelected();
            _.each(that._selDsList.getItems(), function(item) {
                if(_.indexOf(nodeUris, item.getValue().dsUri) >= 0 ) {
                    that._selDsList.selectItem(item, true);
                }
            });
            updateAllLeftState();
        };
        btn.right.click(handleDsChoiceEvent);
        this._subDsTree.observe("leaf:dblclick", handleDsChoiceEvent);

        btn.left.click(function(ev) {
            ev.preventDefault();
            that._removeSelectedSubDs();
            updateAllLeftState();
            updateRightState();
        });
        btn.allLeft.click(function(ev) {
            ev.preventDefault();
            that._removeAllSubDs();
            updateAllLeftState();
            updateRightState();
        });

        function updateAllLeftState() {
            var items = that._selDsList.getItems();
            if(items.length > 0 && !containsReadOnly(items)) {
                btn.allLeft.removeAttr("disabled");
            } else {
                btn.allLeft.attr("disabled", true);
                btn.allLeft.removeClass("over");
            }
        }
        function updateRightState() {
            var nodes = that._subDsTree.selectedNodes;
            var hasMovables = false;
            var hasUnmovables = false;
            for(var i=0; i<nodes.length; i++) {
                if(nodes[i].isParent() || isDsSelected(nodes[i].param.uri)) {
                    hasUnmovables = true;
                    break;
                } else {
                    hasMovables = true;
                }
            }

            if(hasMovables && !hasUnmovables) {
                btn.right.removeAttr("disabled");
            } else {
                btn.right.attr("disabled", true);
            }
        }
        function updateLeftState() {
            var items = that._selDsList.getSelectedItems();
            if(items.length > 0) {
                btn.left.removeAttr("disabled");
            } else {
                btn.left.attr("disabled", true);
                btn.left.removeClass("over");
            }
        }
        function isDsSelected(uri) {
            var subDS = that.getSubDatasources();
            for(var i=0; i<subDS.length; i++) {
                if(subDS[i].dsUri == uri) {
                    return true;
                }
            }
            return false;
        }
        function containsReadOnly(items) {
            for(var i=0; i<items.length; i++) {
                if(items[i].getValue().readOnly) {
                    return true;
                }
            }
            return false;
        }
        updateAllLeftState();

        this._subDsTree.observe('node:selected', updateRightState);
        this._subDsTree.observe('node:unselected', updateRightState);
        this._subDsTree.observe('leaf:selected', updateRightState);
        this._subDsTree.observe('leaf:unselected', updateRightState);
        this._selDsList.observe('item:unselected', updateLeftState);
        this._selDsList.observe('item:selected', updateLeftState);
        jQuery(this._selDsList._getElement()).on("focus", "input.dataSourceID", function(event) {
            enableSelection(that._selDsList._getElement());
        });
        jQuery(this._selDsList._getElement()).on("blur", "input.dataSourceID", function(event) {
            disableSelectionWithoutCursorStyle(that._selDsList._getElement());
        });
        jQuery(this._selDsList._getElement()).on("change", "input.dataSourceID", function(event) {
            var item = that._selDsList.getItemByEvent(event);
            var dsId = jQuery(this).val();
            if(!item) {
                return;
            }
            item.getValue().dsId = dsId;
            that._updateSelectedSubDsField();
        });
    },//end _initVDSEvents

    _addSubDsCore: function(subDs) { //add sub-datasource to selected subDatasources list. Don't update subDS JSON
        var listItem = new dynamicList.TemplatedListItem({
            cssClassName: layoutModule.LEAF_CLASS,
            value: subDs, //contains dsName, dsId, dsUri
            tooltipText: subDs.dsUri
        });

        this._selDsList.addItems([listItem]);
        this._selDsList.show();
        _.each(this._selDsList.getItems(), function(item) { //update validation message containers
            var dsID = jQuery(item._getElement()).find("input.dataSourceID")[0]
            dsID.validatorMessageContainer = jQuery(item._getElement()).find(".validatorMessageContainer")[0];
        }, this);
    },

    _addSubDs: function(subDs) { //add sub-datasource to selected subDatasources list
        this._addSubDsCore(subDs);
        this._updateSelectedSubDsField();
    },


    _removeSelectedSubDs: function() {
        var that = this;
        that._subDsTree._deselectAllNodes();
        var selItems = this._selDsList.getSelectedItems();
        _.each(selItems, function(item) {
            var elm = jQuery(item._getElement()).find("input.dataSourceID")[0];
            that._unhideAvailableSubDs(item.getValue().dsUri);
        });
        this._selDsList.removeItems(selItems);
        this._updateSelectedSubDsField();
    },

    _removeAllSubDs: function() {
        var that = this;
        var items = this._selDsList.getItems();
        _.each(items, function(item) {
            that._unhideAvailableSubDs(item.getValue().dsUri);
        });
        this._selDsList.setItems([]);
        this._selDsList.show();
        this._updateSelectedSubDsField();
    },

    _hideAvailableSubDs: function(uri) {
        var that = this;
        if(_.isArray(uri)) {
            _.each(uri, function(uriItem) {
                that._hideAvailableSubDs(uriItem);
            })
        } else {
            var node = this._subDsTree.findLastLoadedNode(uri);
            //keep removed node for the case if user unselects it
            this._subDsHiddenNodes[uri] = {parent: node.parent,
                child: node};
            var parent = node.parent;
            parent.removeChild(node);
            parent.resortChilds();
        }
    },

    _unhideAvailableSubDs: function(uri) {
        function expandTreePath(tree, uri) {
            tree.processNodePath(uri, function(node) {
                if(node.parent) {
                    if (tree.rootNode != node.parent && tree.getState(node.parent.id) == dynamicTree.TreeNode.State.CLOSED) {
                        node.parent.handleNode();
                    }
                }
            });
        }
        var that = this;
        if(_.isArray(uri)) {
            _.each(uri, function(uriItem) {
                that._unhideAvailableSubDs(uriItem);
            })
        } else {
            var hiddenNode = this._subDsHiddenNodes[uri];
            if(hiddenNode) {
                hiddenNode.parent.addChild(hiddenNode.child);
                hiddenNode.parent.resortChilds();
                hiddenNode.parent.refreshNode();
                expandTreePath(this._subDsTree, uri);
                hiddenNode.child.select();
            }
        }
    },

    _updateSelectedSubDsFromField: function(readOnly) {
        var that = this;
        var subDsJson = this._$selectedSubDs.val();
        if(subDsJson == null || subDsJson.length == 0) {
            return null;
        }
        //TODO clean previous items
        var subDsArray = subDsJson.evalJSON(true);
        _.each(subDsArray, function(subDs) {
            subDs.readOnly = readOnly;
            that._addSubDsCore(subDs);
        });
        return subDsArray;
    },

    _updateSelectedSubDsField: function() {
        var list = this.getSubDatasources();
        var json = list.toJSON();
        this._$selectedSubDs.val(json);
    },

    getSubDatasources: function() { //get list of subDS objects
        var list = this._selDsList.getItems();
        list = _.map(list, function(item) {return item.getValue()});
        return list;
    },

    _showConnectionState: function() {
        if (this._connectionState) {
            if (this._connectionState == "false"){
                dialogs.systemConfirm.show(resource.messages['connectionFailed']);
            } else  if (this._connectionState == "true") {
                dialogs.systemConfirm.show(resource.messages['connectionPassed']);
            }
        }
    },

    _isDataValid: function() {
        return ValidationModule.validate(this._validationEntries);
    },


    _subDatasourcesValidator: function(value) {
        /**
         * Find all duplicated IDs of sub-datasources
         * @param subDS
         */
        function findDuplicateID(subDS) {
            var visitedIds = {};
            for(var i=0; i<subDS.length; i++) {
                var dsId = subDS[i].dsId.toLowerCase();
                if(visitedIds[dsId]) {
                    return dsId;
                }
                visitedIds[dsId] = true;
            }
            return null;
        }
        var subDSJson = this._$selectedSubDs.val();
        if(!subDSJson || subDSJson.length == 0) {
            subDSJson = "[]";
        }
        var subDS = subDSJson.evalJSON();

        var msg = null;
        if(!subDS || subDS.length < 2) {
            return resource.messages["subDatasourcesNeeded"];
        }
        var dupID = findDuplicateID(subDS);
        if(dupID) {
            return resource.messages["subDatasourcesIdDuplicates"].replace("{0}", dupID);
        }
        return null;
    },

    _sortTypeSelect: function() {
        var types = $(this.TYPE_ID);
        var selected = types.getValue();
        var sorter = new Array();

        for (i = 0; i < types.length; i++) {
            sorter[i] = new Array();
            sorter[i][0] = types.options[i].text;
            sorter[i][1] = types.options[i].value;
        }

        sorter.sort();

        while (types.options.length > 0) {
            types.options[0] = null;
        }

        for (var i = 0; i < sorter.length; i++) {
            if (sorter[i][1] == selected) {
                types.options[i] = new Option(sorter[i][0], sorter[i][1], true, true);
            } else {
                types.options[i] = new Option(sorter[i][0], sorter[i][1], false, false);
            }
        }
    }
};

document.observe('dom:loaded', function() {
    resourceDataSource.initialize(localContext.initOptions);
});
