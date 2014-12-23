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

/*
* @author afomin, inesterenko
*/

;(function(jQuery,_, Controls) {

//module:
//
//  controls.controller
//
//summary:
//
//  Connect input controls with server
//
//main types:
//
//  Controller - provide common functions around input controls, like update, reset, etc.
//
//dependencies:
//
//  jQuery          - v1.7.1
//  _,              - underscore.js 1.3.1
//  Controls        - controls.viewmodel and controls.datatransfer


    //get specific parameter from url
    function getParameterFromUrl(param){
        var urlParams = jQuery.url.parse(location.href).params;
        return urlParams && urlParams[param];
    }

    /**
     * Wrapper for Report.getAllRequestParameters()
     * in case if Report object is unavailable, e.g. Scheduling flow.
     */
    function getAllRequestParameters() {
        return _.isObject(window.Report) && _.isFunction(Report.getAllRequestParameters) ?
                Report.getAllRequestParameters() : {};
    }

    return _.extend(Controls, {

        //Provides common operations under input controls
        Controller : Controls.Base.extend({

            constructor:function (args) {
                _.bindAll(this);

                this.viewModel = new Controls.ViewModel();

                this.dataTransfer = new Controls.DataTransfer();

                Controls.listen({

                    "viewmodel:selection:changed" : _.bind(function(event,selectedData,controlsIds, inCascade){
                        if (selectedData && inCascade){
                            this.updateControlsValues(selectedData, controlsIds);
                        }
                    }, this),

                    "reportoptions:selection:changed" : _.bind(function(event,reportOption){
                            this.reset(reportOption && reportOption.uri);
                    }, this)
                });

                Controls.getController =_.bind(function () {
                    return this;
                }, this);
            },

            //post initialization
            initialize:function (args) {

                this.detectReportUri(args);

                var dataTransfer = this.dataTransfer,
                    viewModel = this.viewModel;

                viewModel.initialize();

                var urlParameters = getAllRequestParameters();
                // Pre-selected parameters have priority over url ones.
                var finalInitialParameters = _.extend({}, urlParameters, args.preSelectedData);
                var controlIds = args.fetchStructuresOnlyForPreSelectedData && !_.isEmpty(args.preSelectedData) ? _.keys(args.preSelectedData) : [];

                return dataTransfer.fetchControlsStructure(controlIds, finalInitialParameters).done(function (response) {
                    if (response) {
                        viewModel.set({
                            structure : response.structure,
                            state: response.state
                        });
                    }
                });
            },

            //detect report uri and report option
            detectReportUri:function (args) {

                if (args && args.reportUri) {
                    this.reportUri = args.reportUri;
                } else  {
                    this.reportUri = getParameterFromUrl("reportUnitURI");
                }

                if (!this.reportUri) {
                    throw Error("Can't initialize without reportUri");
                }

                if (args && args.reportOptionUri) {
                    this.reportOptionUri = args.reportOptionUri;
                } else {
                    this.reportOptionUri = getParameterFromUrl("reportOptionsURI");
                }

                this.dataTransfer.setReportUri(this.reportOptionUri ? this.reportOptionUri : this.reportUri);
            },

            //Returns api under rest api for run report service
            getDataTransfer:function () {
                return this.dataTransfer;
            },

            //Returns object responsible for initialization and drawing of controls
            getViewModel:function () {
                return this.viewModel;
            },

            //Update specified controls with some selection
            updateControlsValues:function (selectedData, controlIds) {
                var dataTransfer = this.getDataTransfer();
                var viewModel = this.getViewModel();
                var controlsIds = controlIds || _.map(viewModel.getControls(), function (control) {
                    return control.id;
                });
                return dataTransfer.fetchControlsUpdatedValues(controlsIds, selectedData).done(viewModel.set);
            },

            //Resets input controls values to initial for current report
            reset:function (uri) {

                var viewModel = this.getViewModel();
                var dataTransfer = this.getDataTransfer();
                if(!uri){
                    uri = this.reportOptionUri ? this.reportOptionUri : this.reportUri;
                }
                return dataTransfer.fetchInitialControlValues(uri).done(viewModel.set);
            },

            //update controls by given selection or by current selection
            update:function (selectedData) {
                if (!selectedData){
                    selectedData = this.getViewModel().get("selection");
                }
                return this.updateControlsValues(selectedData);
            },

            //validate controls values and update only invalid controls
            validate : function(){
                var dataTransfer = this.getDataTransfer();
                var viewModel = this.getViewModel();
                var controlsIds = _.map(viewModel.getControls(), function (control) {
                    return control.id;
                });
                var selectedData = viewModel.get('selection');
                return dataTransfer.fetchControlsUpdatedValues(controlsIds, selectedData).then(function(responce){
                    var state = _(responce.state).reduce(function(memo, controlState, controlId){
                        memo[controlId] = {error: controlState["error"]};
                        return memo;
                    }, {});
                    viewModel.set({state: state});
                }).pipe(function(){
                     return viewModel.areAllControlsValid();
                });
            }
        })
    });

})(
    jQuery,
    _,
    JRS.Controls
);
