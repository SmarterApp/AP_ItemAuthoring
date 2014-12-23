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

var ScheduleParams = {

    reportOptionsDialog: null,
    controlsController : new JRS.Controls.Controller(),
    action: null,
    jobParameters: null,

    initialize: function() {

        Schedule.initSwipeScroll();

        if (isProVersion()) {
            var reportOptions = new JRS.Controls.ReportOptions();

            jQuery.when(
                reportOptions.fetch(ScheduleParams.reportUnitURI, ScheduleParams.reportOptionsURI)
            ).done(function () {
                    jQuery("#stepDisplay .sub.header").prepend(reportOptions.getElem());
            });

            JRS.Controls.listen({
                "viewmodel:selection:changed":function(){
                    var option = reportOptions.find({uri:ScheduleParams.reportUnitURI });
                    reportOptions.set({selection:option}, true);
                }
            })
        }

        ScheduleParams.controlsController.initialize({
            reportUri : ScheduleParams.reportUnitURI,
            reportOptionUri: ScheduleParams.reportOptionsURI,
            preSelectedData: ScheduleParams.jobParameters
        });

        var optionsButtonActions = {
            'button#saveAsBtnSave':function () {
                var optionName = ScheduleParams.reportOptionsDialog.input.getValue();
                var selectedData = ScheduleParams.controlsController.getViewModel().get("selection");
                var overwrite = optionName === ScheduleParams.reportOptionsDialog.optionNameToOverwrite;
                jQuery.when(reportOptions.add(ScheduleParams.reportUnitURI,optionName, selectedData, overwrite)).done(function () {
                    ScheduleParams.reportOptionsDialog.hideWarning();
                    var container = reportOptions.getElem().parent();
                    if (container.length == 0) {
                       container = jQuery("#stepDisplay .sub.header");
                       container.prepend(reportOptions.getElem());
                    }
                    ScheduleParams.reportOptionsDialog.hide();
                    delete ScheduleParams.reportOptionsDialog.optionNameToOverwrite;
                }).fail(function(err){
                    try {
                        var response = jQuery.parseJSON(err.responseText);
                        if (response.errorCode === "report.options.dialog.confirm.message"){
                           !overwrite && (ScheduleParams.reportOptionsDialog.optionNameToOverwrite = optionName);
                        }
                        ScheduleParams.reportOptionsDialog.showWarning(response.message);
                    } catch (e) {
                        // In this scenario security error is handled earlier, in errorHandler, so we can ignore exception here.
                        // Comment this because it will not work in IE, but can be uncommented for debug purpose.
                        // console.error("Can't parse server response: %s", "controls.core", err.responseText);
                    }
                });
            },
            'button#saveAsBtnCancel': function() {ScheduleParams.reportOptionsDialog.hide()}
        };

        if ($(ControlsBase.SAVE_REPORT_OPTIONS_DIALOG)) {
            this.reportOptionsDialog = new OptionsDialog(optionsButtonActions);
        }

        $(Schedule.PAGE_JOB_PARAMETERS).observe('click', function(e) {
            var elem = e.element();

            // observe navigation buttons
            var link = matchAny(e.element(), ['a','button','li'], true);
            if (link) {
                for (var pattern in Schedule.buttonActions) {
                    if (link.match(pattern)) {
                        e.stop();

                        // if pro, call applyParameters before next or back.
                        if (isProVersion() && Schedule.buttonActions[pattern] == 'next') {
                            ScheduleParams.next();
                        } else if (isProVersion() && Schedule.buttonActions[pattern] == 'back') {
                            ScheduleParams.back();
                        } else {
                            var viewModel = ScheduleParams.controlsController.getViewModel();
                            Schedule.submitForm($(Schedule.STEP_DISPLAY_FORM), Schedule.buttonActions[pattern], viewModel.get("selection"));
                        }

                        return;
                    }
                }

                if (link.match('button#save')) {
                    e.stop();
                    ScheduleParams.save();
                    return;
                }

            }
        });

        // disable Previous button if Run Now Mode
        if (Schedule.isRunNowMode) {
            buttonManager.disable($('previous'));
        }

    },

    next: function() {
        ScheduleParams.controlsController.validate().then(function(areControlsValid){
            areControlsValid && ScheduleParams.navigateTo('next');
        });
    },

    back: function() {
        ScheduleParams.controlsController.validate().then(function(areControlsValid){
            areControlsValid && ScheduleParams.navigateTo('back');
        });
    },

    save: function() {
        ScheduleParams.reportOptionsDialog.show();
    },

    navigateTo: function (action) {
        var viewModel = ScheduleParams.controlsController.getViewModel();
        var selectedData = viewModel.get('selection');
        var postAction = _.bind(Schedule.submitForm, null, $(Schedule.STEP_DISPLAY_FORM), action, selectedData);
        ScheduleParams.sendAsForm(postAction, ControlsBase.buildSelectedDataUri(selectedData, {"_eventId": "applyParameter"}));
    },

    sendAsForm : function (postAction, schedulerReportParametersUri){
        var url = "flow.html?_flowExecutionKey=" + Schedule.flowExecutionKey + "&decorate=no";

        var tempContainer = Builder.node('DIV', {id: ControlsBase.TEMP_REPORT_CONTAINER, style: 'display:none'});
        document.body.insertBefore(tempContainer, document.body.firstChild);

        ajaxTargettedUpdate( url,   {
            postData: schedulerReportParametersUri,
            fillLocation: tempContainer,
            callback: function(){
                postAction && postAction();
            }
        });
    }

};

document.observe('dom:loaded', ScheduleParams.initialize.bind(ScheduleParams));

