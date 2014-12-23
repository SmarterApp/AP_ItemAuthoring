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


JRS.Controls = (function (jQuery, _, Controls) {

    //module:
    //
    //  controls.datatransfer
    //
    //summary:
    //
    //DataTransfer    - REST wrapper, returns normalized data
    //
    //dependencies:
    //
    //
    //  jQuery          - v1.7.1
    //  _,              - underscore.js 1.3.1
    //  Controls,       - controls.core module


    //Clean up input structure from mess
   function structureFormater(response) {
        var results = response.inputControl;
        return _.map(results, function (res) {
            res.readOnly = String(res.readOnly) == "true";
            res.uri = res.uri.replace("repo:", "");
            return res;
        });
    }

   //Convert controls update response to data structure compatible with controls
   function convertResponseToControlsState (rawState) {
        var result = {};
        var requestStates = rawState.inputControlState ? rawState.inputControlState : rawState;

        var convertOptionFunc = function (option) {
            var opt = {
                value : option.value,
                label : option.label
            };
            if (String(option.selected) == "true"){
                opt.selected  = true;
            }
            return opt;
        };

        var convertOptionsFunc = function(options){
            var values;
            if (_.isArray(options)) {
                values = _.map(options, convertOptionFunc);
            } else {
                values = [];
            }
            return values;
        };

        var convertToValues = function(requestState) {
            if (!_.isUndefined(requestState.value) && !_.isNull(requestState.value)) {
                return requestState.value;
            }
            return convertOptionsFunc(requestState.options);
        };

        _.each(requestStates, _.bind(function (requestState) {
            if (requestState && requestState.uri) {
                result[requestState.id]  = {
                    error : requestState.error,
                    values : convertToValues(requestState)
                };
            }
        }, this));
        return {
            state : result
        };
    }

   //Common error handing
    function commonErrorHandler(err) {
        try {
            var errorObject = jQuery.parseJSON(err.responseText);
            _.each(errorObject.error, function (error) {
                //TODO: try to avoid it
                var viewModel = Controls.getViewModel();
                var controlUri = error.inputControlUri.replace("repo:", "");
                var control = viewModel.find({uri:controlUri});
                if (error.errorCode) {
                    control.set({error:error.errorCode});
                } else if (error.defaultMessage) {
                    control.set({error:error.defaultMessage});
                }
            });
        } catch (e) {
            // In this scenario security error is handled earlier, in errorHandler, so we can ignore exception here.
            // Comment this because it will not work in IE, but can be uncommented for debug purpose.
            // console.error("Can't parse server response: %s", "controls.core", err.responseText);
        }
    }

    return _.extend(Controls, {

        //REST wrapper, returns normalized data
        DataTransfer:Controls.Base.extend({

            setReportUri:function (reportUri) {
                this.currentReportUri = reportUri;
            },

            fetchControlsStructure:function (uris, selectedData) {

                var controlsIds = "";
                if (uris && uris.length > 0) {
                    controlsIds = uris.join(";");
                }
                var url = Controls.TemplateEngine.renderUrl(
                    Controls.DataTransfer.CONTROLS_STRUCTURE_TEMPLATE_URI, {
                        reportUri:this.currentReportUri,
                        controlIds:controlsIds
                    });

                var queryData = {
                    type:"GET",
                    url:url,
                    dataType:"json",
                    cache: false
                };

                if (selectedData && !_.isEmpty(selectedData)) {
                    queryData = _.extend(queryData, {
                        type:"POST",
                        processData:false,
                        //TODO:try to replace by JSON
                        data:Object.toJSON(selectedData),
                        contentType:"application/json"
                    });
                }

                var controlsStructure = jQuery.ajax(queryData).pipe(function (response) {
                    var formatedResponse, state;
                    if (response) {
                        formatedResponse = structureFormater(response);
                        state = _.map(formatedResponse, function (controlStructure) {
                            return controlStructure.state;
                        });
                        state = _.compact(state);
                        _.each(formatedResponse, function(structure){
                            delete structure["state"];
                        });
                        return _.extend({
                            structure:formatedResponse
                        }, convertResponseToControlsState(state))
                    }
                });

                Controls.Utils.showLoadingDialogOn(controlsStructure);
                return  controlsStructure;
            },

            fetchInitialControlValues:function (reportUri) {

                var url = Controls.TemplateEngine.renderUrl(
                    Controls.DataTransfer.INITIAL_CONTROLS_VALUES_TEMPLATE_URL, {
                        reportUri:reportUri
                    });

                var querySettings = {
                    type:"GET",
                    url:url,
                    dataType:"json",
                    cache: false
                };

                var initialControlsValues = jQuery.ajax(querySettings).
                    pipe(convertResponseToControlsState).
                    fail(commonErrorHandler);

                Controls.Utils.showLoadingDialogOn(initialControlsValues);
                return initialControlsValues;
            },

            fetchControlsUpdatedValues:function (ids, selectedData) {

                var url = Controls.TemplateEngine.renderUrl(
                    Controls.DataTransfer.CONTROLS_VALUES_TEMPLATE_URL, {
                        reportUri:this.currentReportUri,
                        controlIds:ids.join(";")
                    });

                var querySettings = {
                    type:"POST",
                    url:url,
                    processData:false,
                    //TODO: implicit dependency on Prototype library
                    data:Object.toJSON(selectedData),
                    contentType:"application/json",
                    dataType:"json"
                };

                if (this.fullUpdateDeferred && this.fullUpdateDeferred.state() == "pending") {
                    this.fullUpdateDeferred.reject();
                }

                var fullUpdateDeferred = new jQuery.Deferred();

                var triggerRequestDeferred = Controls.Utils.wait(Controls.DataTransfer.FREQUENT_CHANGES_MIN_DELAY);

                triggerRequestDeferred.done(function () {
                    jQuery.ajax(querySettings).pipe(convertResponseToControlsState).done(
                            function (data) {
                                if (fullUpdateDeferred.state() == "pending") {
                                    fullUpdateDeferred.resolve(data);
                                }
                    }).fail(commonErrorHandler);
                });

                fullUpdateDeferred.fail(function () {
                    triggerRequestDeferred.reject();
                });

                Controls.Utils.showLoadingDialogOn(fullUpdateDeferred);

                this.fullUpdateDeferred = fullUpdateDeferred;

                return fullUpdateDeferred;
            }

        }, {

            //Static props

            CONTROLS_STRUCTURE_TEMPLATE_URI:"rest_v2/reports{{reportUri}}/inputControls/{{controlIds}}",

            INITIAL_CONTROLS_VALUES_TEMPLATE_URL:"rest_v2/reports{{reportUri}}/inputControls/values",

            CONTROLS_VALUES_TEMPLATE_URL:"rest_v2/reports{{reportUri}}/inputControls/{{controlIds}}/values",

            FREQUENT_CHANGES_MIN_DELAY : 400
        })
    });

})(
    jQuery,
    _,
    JRS.Controls
);