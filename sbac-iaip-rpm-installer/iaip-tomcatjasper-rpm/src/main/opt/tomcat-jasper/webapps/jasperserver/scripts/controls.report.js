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

var Controls = (function (jQuery, _, Controls, Report) {

    return _.extend(Controls,{

        _messages:{},

        layouts:{
            LAYOUT_POPUP_SCREEN:1,
            LAYOUT_SEPARATE_PAGE:2,
            LAYOUT_TOP_OF_PAGE:3,
            LAYOUT_IN_PAGE:4
        },

        controlDialog:null,
        reportOptionsDialog:null,

        inputControlsLocation:null,
        toggleControlsOn:false,
        controller:new JRS.Controls.Controller(),
        hideControls:null,
        selectionChanged:true,

        initialize:function () {

            var controlsArgs = {
                reportUri:Report.reportUnitURI,
                reportOptionUri:Report.reportOptionsURI,
                preSelectedData:Report.reportParameterValues
            };

            this.controller.initialize(controlsArgs).always(function () {

                var viewModel = Controls.controller.getViewModel();
                // Report.reportParameterValues means that parameters were saved in flow and were put on jsp, we do it when we go drill through.
                // _.isEmpty(Report.reportParameterValues) means that we are not returning from drill through.
                var isValidSelection = viewModel.areAllControlsValid();
                if (Report.hasInputControls && ((Report.reportForceControls && _.isEmpty(Report.reportParameterValues)) || !isValidSelection)) {
                    Controls.show();
                    Report.showNothingToDisplayPanel();
                    Controls.lastSelection = viewModel.get('selection');
                } else {
                    Controls.refreshReport();
                }

                JRS.Controls.listen({
                    "viewmodel:selection:changed":function () {
                        Controls.selectionChanged = true;
                    },
                    "reportoptions:selection:changed":function (event, selection) {
                        Controls.selectionChanged = true;
                    }
                });

            });

            this.viewModel = Controls.controller.getViewModel();

            this.initializeOptions();

            this.buttonActions = {
                'button#ok':_.bind(Controls.applyInputValues, Controls, true),
                'button#apply':_.bind(Controls.applyInputValues, Controls),
                'button#cancel':_.bind(Controls.cancel, Controls),
                'button#reset':Controls.resetToInitial,
                'button#save':Controls.save,
                'button#remove':Controls.remove
            };

            var dialogButtonActions = {
                'button#ok':_.bind(Controls.applyInputValues, Controls, true),
                'button#cancel':_.bind(Controls.cancel, Controls),
                'button#reset':Controls.resetToInitial,
                'button#apply':_.bind(Controls.applyInputValues, Controls),
                'button#save':Controls.save,
                'button#remove':Controls.remove
            };

            if ($(ControlsBase.INPUT_CONTROLS_DIALOG)) {
                this.controlDialog = new ControlDialog(dialogButtonActions);
            }

            if ($(ControlsBase.INPUT_CONTROLS_FORM)) {
                $(ControlsBase.INPUT_CONTROLS_FORM).observe('click', function (e) {
                    var elem = e.element();

                    //                observe Input Controls buttons
                    for (var pattern in this.buttonActions) {
                        if (matchAny(elem, [pattern], true)) {
                            this.buttonActions[pattern]();
                            e.stop();
                            return;
                        }
                    }

                }.bindAsEventListener(this));
            }

            this.inputControlsLocation = $(ControlsBase.INPUT_CONTROLS_CONTAINER) ? $(ControlsBase.INPUT_CONTROLS_CONTAINER) : $(ControlsBase.INPUT_CONTROLS_FORM);
            if ($(ControlsBase.TOOLBAR_CONTROLS_BUTTON)) {
                this.toggleControlsOn = $(ControlsBase.TOOLBAR_CONTROLS_BUTTON).hasClassName('down');
            }
        },

        initializeOptions:function () {
            if ((isProVersion())) {

                function showSubHeader() {
                    var parent;
                    if (Controls.layouts.LAYOUT_POPUP_SCREEN == Report.reportControlsLayout) {
                        parent = jQuery("#" + ControlsBase.INPUT_CONTROLS_DIALOG);
                    } else {
                        parent = jQuery("#" + ControlsBase.INPUT_CONTROLS_FORM);
                    }
                    if (parent && parent.length > 0) {
                        parent.addClass("showingSubHeader")
                    }
                }

                function hideSubHeader() {
                    var parent;
                    if (Controls.layouts.LAYOUT_POPUP_SCREEN == Report.reportControlsLayout) {
                        parent = jQuery("#" + ControlsBase.INPUT_CONTROLS_DIALOG);
                    } else {
                        parent = jQuery("#" + ControlsBase.INPUT_CONTROLS_FORM);
                    }
                    if (parent && parent.length > 0) {
                        parent.removeClass("showingSubHeader")
                    }
                }

                var optionsContainerSelector;

                if (this.layouts.LAYOUT_POPUP_SCREEN == Report.reportControlsLayout) {
                    optionsContainerSelector = "#" + ControlsBase.INPUT_CONTROLS_DIALOG + " .sub.header";
                } else if (this.layouts.LAYOUT_TOP_OF_PAGE == Report.reportControlsLayout) {
                    optionsContainerSelector = "#" + ControlsBase.INPUT_CONTROLS_FORM + " .sub.header";
                } else {
                    optionsContainerSelector = "#" + ControlsBase.INPUT_CONTROLS_FORM + " .sub.header";
                }

                var reportOptions = new JRS.Controls.ReportOptions();

                reportOptions.fetch(Report.reportUnitURI, Report.reportOptionsURI)
                    .done(function () {
                        jQuery(optionsContainerSelector).append(reportOptions.getElem());
                        Controls.lastReportOptionsSelection = reportOptions.get("selection");
                    })
                    .fail(function () {
                        jQuery(optionsContainerSelector).addClass('hidden');
                    })
                    .always(function(){
                        if (!Controls.lastReportOptionsSelection){
                            Controls.lastReportOptionsSelection = reportOptions.get("defaultOption");
                        }

                    }
                );




                reportOptions.updateWarningMessage = function () {
                    Controls.reportOptionsDialog.showWarning(this.error);
                };

                JRS.Controls.listen({
                    "viewmodel:selection:changed":function () {
                        var option = reportOptions.find({uri:Report.reportUnitURI });
                        reportOptions.set({selection:option}, true);
                    }
                });

                var optionsButtonActions = {
                    'button#saveAsBtnSave':function () {
                        var optionName = Controls.reportOptionsDialog.input.getValue();
                        var selectedData = Controls.viewModel.get("selection");
                        var overwrite = optionName === Controls.reportOptionsDialog.optionNameToOverwrite;
                        reportOptions.add(Report.reportUnitURI, optionName, selectedData, overwrite)
                            .done(function () {
                                Controls.reportOptionsDialog.hideWarning();
                                dialogs.systemConfirm.show(ControlsBase.getMessage("report.options.option.saved"));
                                showSubHeader();
                                var container = reportOptions.getElem().parent();
                                if (container.length > 0) {
                                    container.removeClass("hidden");
                                } else {
                                    jQuery(optionsContainerSelector).removeClass("hidden");
                                    jQuery(optionsContainerSelector).append(reportOptions.getElem());
                                }
                                if (Controls.layouts.LAYOUT_TOP_OF_PAGE == Report.reportControlsLayout) {
                                    jQuery("#" + ControlsBase.INPUT_CONTROLS_FORM + " .header").removeClass("hidden");
                                }
                                Controls.reportOptionsDialog.hide();
                                delete Controls.reportOptionsDialog.optionNameToOverwrite;
                            })
                            .fail(function(err){
                                if (err) {
                                    try {
                                        var errorResponse = jQuery.parseJSON(err.responseText);
                                        //check on error  for overwrite
                                        if (errorResponse.errorCode === "report.options.dialog.confirm.message"){
                                            !overwrite && (Controls.reportOptionsDialog.optionNameToOverwrite = optionName);
                                        }
                                    } catch (e) {
                                        // In this scenario security error is handled earlier, in errorHandler, so we can ignore exception here.
                                        // Comment this because it will not work in IE, but can be uncommented for debug purpose.
                                        // console.error("Can't parse server response: %s", "controls.core", err.responseText);
                                    }
                                }
                            }
                        );
                    },
                    'button#saveAsBtnCancel':function () {
                        Controls.reportOptionsDialog.hide();
                        delete Controls.reportOptionsDialog.optionNameToOverwrite;
                    }
                };

                if ($(ControlsBase.SAVE_REPORT_OPTIONS_DIALOG)) {
                    this.reportOptionsDialog = new OptionsDialog(optionsButtonActions);
                }


                this.remove = function () {
                    var optionName = reportOptions.get('selection').label;
                    if (confirm(ControlsBase.getMessage("report.options.option.confirm.remove", {option: optionName}))) {
                        reportOptions.removeOption(Report.reportUnitURI, optionName)
                            .done(function () {
                                if (!reportOptions.get('values')) {
                                    hideSubHeader();
                                    var container = reportOptions.getElem().parent();
                                    if (container.length > 0) {
                                        container.addClass("hidden");
                                    } else {
                                        jQuery(optionsContainerSelector).addClass("hidden");
                                        jQuery(optionsContainerSelector).innerHTML = "";
                                    }
                                    if (Controls.layouts.LAYOUT_TOP_OF_PAGE == Report.reportControlsLayout) {
                                        jQuery("#" + ControlsBase.INPUT_CONTROLS_FORM + " .header").addClass("hidden");
                                    }
                                }
                                reportOptions.enableRemoveButton(false); // change the Remove button to Save
                                dialogs.systemConfirm.show(ControlsBase.getMessage("report.options.option.removed"));
                            });
                    }
                }

                Controls.reportOptions = reportOptions;
            }
        },

        cancel:function () {

            if (Report.reportControlsLayout == Controls.layouts.LAYOUT_SEPARATE_PAGE && Controls.separatePageICLayoutFirstShow) {
                //TODO this property is no longer used, determine condition using "errors" flag after resolve control values.
                Report.goBack();
            } else {

                Controls.controller.update(Controls.lastSelection)
                    .always(function () {
                        if (Report.reportControlsLayout == Controls.layouts.LAYOUT_POPUP_SCREEN) {
                            Controls.controlDialog.hide();
                        } else if (Report.reportControlsLayout == Controls.layouts.LAYOUT_SEPARATE_PAGE) {
                            Controls.showReport();
                        }

                        if (Controls.reportOptions){
                            if (Controls.lastReportOptionsSelection){
                               Controls.reportOptions.set({"selection": Controls.lastReportOptionsSelection}, true);
                            }
                        }

                    }
                );
            }
        },

        save:function () {
            if (Controls.selectionChanged){
                Controls.controller.validate().then(Controls.showOptionDialog);
            }else{
                Controls.showOptionDialog();
            }
        },

        refreshReport:function (checkOnChangedSelection) {
            var selectedData = Controls.viewModel.get("selection");
            if (checkOnChangedSelection){
                var isSelectionChanged = JRS.Controls.ViewModel.isSelectionChanged(Controls.lastSelection, selectedData);
                if (!isSelectionChanged) return;
            }
            if (selectedData && !_.isEmpty(selectedData)) {
                Report.refreshReport(null, null, ControlsBase.buildSelectedDataUri(selectedData));
                Controls.lastSelection = selectedData;
            } else {
                Report.refreshReport();
                Controls.lastSelection = {};
            }
        },

        applyInputValues:function (hideControls) {
            var viewModel = Controls.viewModel;
            if (Controls.selectionChanged) {
                Controls.controller.validate().then(function (areAllControlsValid) {
                    if (areAllControlsValid){
                        Controls.refreshReport();
                        hideControls && Controls.hide();
                        if (Controls.reportOptions){
                            Controls.lastReportOptionsSelection = Controls.reportOptions.get("selection");
                        }
                    }
                    Controls.selectionChanged = false;
                });
            }else if (viewModel.areAllControlsValid()) {
                hideControls && Controls.hide();
            }
        },

        resetToInitial:function () {
            Controls.selectionChanged = true;
            var reportOptions = Controls.reportOptions;
            if (reportOptions) {
                var option = reportOptions.find({
                    uri:Report.reportOptionsURI ? Report.reportOptionsURI : Report.reportUnitURI
                });
                if (option) {
                    reportOptions.set({selection:option});
                    return;
                }
            }
            Controls.controller.reset();
        },

        show:function () {
            switch (Report.reportControlsLayout) {
                case 2:
                    Controls.showControls();
                    break;
                case 3:
                    Controls.toggleControls();
                    break;
                case 4:
                    /* Controls "in page" cannot be opened or closed, they're always shown. */
                    break;
                default:
                    Controls.showDialog();
            }
        },

        hide:function () {
            switch (Report.reportControlsLayout) {
                case 2:
                    Controls.showReport();
                    break;
                case 3:
                    /* Controls "top of page" can be closed only using input controls button. */
                    break;
                case 4:
                    /* Controls "in page" cannot be opened or closed, they're always shown. */
                    break;
                default:
                    Controls.controlDialog.hide();
            }
        },

        toggleControls:function () {
            if (Controls.toggleControlsOn) {
                $(ControlsBase.TOOLBAR_CONTROLS_BUTTON).removeClassName('down').addClassName('up');
                $$('.panel.pane.inputControls')[0].addClassName(layoutModule.HIDDEN_CLASS);
            } else {
                $(ControlsBase.TOOLBAR_CONTROLS_BUTTON).removeClassName('up').addClassName('down');
                $$('.panel.pane.inputControls')[0].removeClassName(layoutModule.HIDDEN_CLASS);
            }

            Controls.toggleControlsOn = !Controls.toggleControlsOn;

            isIPad() && Report.touchController.reset();
            /**
             * Fix to force rendering of input controls on webkit.
             */
            jQuery('#' + ControlsBase.INPUT_CONTROLS_FORM).show().height();
        },

        showDialog:function () {
            if (Controls.controlDialog){
                Controls.controlDialog.show();
            }
        },

        showReport:function () {
            $(layoutModule.PAGE_BODY_ID).
                removeClassName(layoutModule.CONTROL_PAGE_CLASS).addClassName(layoutModule.ONE_COLUMN_CLASS);
        },

        showControls:function () {
            $(layoutModule.PAGE_BODY_ID).
                removeClassName(layoutModule.ONE_COLUMN_CLASS).addClassName(layoutModule.CONTROL_PAGE_CLASS);

            document.getElementById(ControlsBase.INPUT_CONTROLS_FORM) && jQuery('#' + ControlsBase.INPUT_CONTROLS_FORM).show();
        },

        showOptionDialog:function () {
            JRS.Controls.Utils.wait(200).then(function () {
                //workaround for bug 27415,
                //because can't prevent bubbling up to parent dialog window,
                //so add delay and only then shows options dialog on top of controls dialog
                if (Controls.viewModel.areAllControlsValid()) {
                    Controls.reportOptionsDialog.show();
                    selectAndFocusOn(Controls.reportOptionsDialog.input);
                }
            });
        }
    });

})(
    jQuery,
    _,
    {},
    Report
);

