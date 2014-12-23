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

JRS.Controls = (function (jQuery, _, Controls, layoutModule) {

//module:
//
//  controls.components
//
//summary:
//
//  Provide default input controls types
//
//main types:
//
//  Bool, SingleValue, SingleValueDate, SingleSelect, MultiSelect, MultiSelectCheckbox, SingleSelectRadio - default
//  input controls
//
//  ReportOptions - special control, not connected with cascade
//
//dependencies:
//
//  jQuery          - jquery v1.7.1
//  _,         - underscore.js 1.3.1
//  Controls   - controls.core module

    function changeDateFunc(dateText) {
        this.set({selection:dateText});
    }

    function changeMonthYear(year, month, inst) {
        var newDate = inst.input.datepicker("getDate");
        if (newDate && !(newDate.getFullYear() === year && newDate.getMonth() === month - 1)) {
            newDate = updateYearMonth(newDate, year, month - 1);
            inst.input.datepicker("setDate", newDate);
            changeDateFunc.call(this, inst.input.val());
        }
    }

    function getNormalizedDatetimeValue(rawValue) {
        var normalizedValue = rawValue.toUpperCase().replace(/([\s]+$|^[\s]+)/g, "");
        return normalizedValue.replace(/[\s]*(\+|\-)[\s]*/g, "$1");
    }

    return _.extend(Controls, {

        Bool:Controls.BaseControl.extend({

            update:function (controlData) {
                var container = this.getElem();
                var input = container.find('input');
                if (controlData == "true") {
                    input.attr('checked', 'checked');
                } else {
                    input.removeAttr('checked');
                }
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'input', _.bind(function (evt) {
                    var value = evt.target.getValue() == null ? "false" : "true";
                    this.set({selection:value});
                }, this));
            }
        }),

        SingleValueText:Controls.BaseControl.extend({

            update:function (controlData) {
                var value = controlData == ControlsBase.NULL_SUBSTITUTION_VALUE ? ControlsBase.NULL_SUBSTITUTION_LABEL : controlData;
                var container = this.getElem();
                if (container) {
                    container.find('input').attr('value', value);
                }
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'input', _.bind(function (evt) {
                    var inputValue = evt.target.value;
                    var value = inputValue == ControlsBase.NULL_SUBSTITUTION_LABEL ? ControlsBase.NULL_SUBSTITUTION_VALUE : inputValue;
                    this.set({selection:value});
                }, this));

            }
        }),

        SingleValueNumber:Controls.BaseControl.extend({

            update:function (controlData) {
                this.getElem().find('input').attr('value', controlData);
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'input', _.bind(function (evt) {
                    this.set({selection:evt.target.value});
                }, this));
            }
        }),

        SingleValueDate:Controls.BaseControl.extend({

            initialize:function (args) {
                this.baseRender(args);
                this.setupCalendar();
            },

            setupCalendar:function () {
                var input = this.getElem().find('input');

                input.datepicker({
                    showOn:"button",
                    dateFormat:JRS.i18n["bundledCalendarFormat"],
                    changeMonth:true,
                    changeYear:true,
                    showButtonPanel:true,
                    disabled:input[0].disabled,
                    onSelect:_.bind(changeDateFunc, this),
                    onChangeMonthYear:_.bind(changeMonthYear, this),
                    beforeShow:jQuery.datepicker.movePickerRelativelyToTriggerIcon,
                    constrainInput:false
                });

                input.change(_.bind(function (evt) {
                    //prevent triggering of global control change event
                    evt.stopPropagation();

                    //remove all spaces and convert to upper case
                    jQuery(evt.target).val(getNormalizedDatetimeValue(evt.target.value));

                    changeDateFunc.call(this, jQuery(evt.target).val());
                }, this));

                input.after('&nbsp;');
                var button = this.getElem().find('button');
                button.wrap(ControlsBase.CALENDAR_ICON_SPAN).empty();
            },

            update:function (controlData) {
                var container = this.getElem();
                container.find('input').attr('value', controlData);
            }

        }),

        SingleValueDatetime:Controls.BaseControl.extend({

            initialize:function (args) {
                this.baseRender(args);
                this.setupCalendar();
            },

            setupCalendar:function () {
                var input = this.getElem().find('input');

                input.datetimepicker({
                    showOn:"button",
                    dateFormat:JRS.i18n["bundledCalendarFormat"],
                    timeFormat:JRS.i18n["bundledCalendarTimeFormat"],
                    showSecond:true,
                    changeMonth:true,
                    changeYear:true,
                    showButtonPanel:true,
                    disabled:input[0].disabled,
                    onSelect:_.bind(changeDateFunc, this),
                    onChangeMonthYear:_.bind(changeMonthYear, this),
                    beforeShow:jQuery.datepicker.movePickerRelativelyToTriggerIcon,
                    constrainInput:false
                });

                input.change(_.bind(function (evt) {
                    //prevent triggering of global control change event
                    evt.stopPropagation();

                    //remove all spaces and convert to upper case
                    jQuery(evt.target).val(getNormalizedDatetimeValue(evt.target.value));

                    changeDateFunc.call(this, jQuery(evt.target).val());
                }, this));

                input.after('&nbsp;');
                var button = this.getElem().find('button');
                button.wrap(ControlsBase.CALENDAR_ICON_SPAN).empty();
            },
            update:function (controlData) {
                var container = this.getElem();
                container.find('input').attr('value', controlData);
            }
        }),

        SingleSelect:Controls.BaseControl.extend({

            update:function (controlData) {
                var select = this.getElem().find('select')[0];

                var template = this.getTemplateSection('data');

                Controls.Utils.setInnerHtml(select, template, {data:controlData});

            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'select', _.bind(function (evt) {
                    var selection = jQuery(evt.target).val();
                    this.set({selection:selection});
                }, this));
            }
        }),

        MultiSelect:Controls.BaseControl.extend({

            update:function (controlData) {

                var select = this.getElem().find('select');

                var template = this.getTemplateSection('data');

                Controls.Utils.setInnerHtml(select[0], template, {data:controlData});

                //TODO move to decorator
                if (select.find('option').length < 5 && this.getElem()[0].clientHeight < 125) {
                    this.getElem().find('.sizer').addClass('hidden');
                    this.getElem().find('.inputSet').removeClass('sizable').attr('style', false);
                } else {
                    if (this.resizable) {
                        this.getElem().find('.sizer').removeClass('hidden');
                        this.getElem().find('.inputSet').addClass('sizable');
                    }
                }
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'select', _.bind(function (evt) {
                    var selection = jQuery(evt.target).val();
                    this.set({selection:selection});
                }, this));

                this.getElem().on('click','a',_.bind(function(evt){

                    var options = this.getElem().find('option');

                    var name = jQuery(evt.target)[0].name;
                    if (name === "multiSelectAll" || name === "multiSelectNone") {
                        _.each(options,  function(opt){
                            opt.selected = name === "multiSelectAll";
                        });
                    } else if (name === "multiSelectInverse") {
                        _.each(options,  function(opt){
                            opt.selected = !opt.selected;
                        });
                    }

                    this.getElem().find('select').change(); // trigger the cascading request

                }, this));
            },

            get:function (attribute) {
                var result = this[attribute];
                if (attribute == 'selection' && _.isEmpty(result)) {
                    return [ControlsBase.NOTHING_SUBSTITUTION_VALUE];
                } else {
                    return result;
                }
            },

            //TODO move to decorator
            makeResizable:function () {
                this.resizable = true;
                var label = this.getElem().find('label');
                var sizer = label.parents(".leaf").find('.sizer').removeClass('hidden'); // FF 3.6
                layoutModule.createSizer(label[0], {fillerPattern:'select', sizer:sizer[0]});
            }
        }),

        SingleSelectRadio:Controls.BaseControl.extend({

            update:function (controlData) {

                var start = (new Date()).getTime();

                var list = this.getElem().find('ul')[0];

                var data = _.map(controlData, function (val) {
                    var result = _.clone(val);
                    result.readOnly = this.readOnly;
                    result.name = this.getOptionName();
                    result.uuid = _.uniqueId(this.id);
                    return result;
                }, this);

                var template = this.getTemplateSection('data');

                Controls.Utils.setInnerHtml(list, template, {data:data});
                list.innerHTML += "&nbsp;"; //workaround for IE scrollbar

                //TODO move to decorator
                if (jQuery(list).find('li').length < 5 && this.getElem()[0].clientHeight < 125) {
                    this.getElem().find('.sizer').addClass('hidden');
                    this.getElem().find('.inputSet').removeClass('sizable').attr('style', false);
                } else {
                    if (this.resizable) {
                        this.getElem().find('.sizer').removeClass('hidden');
                        this.getElem().find('.inputSet').addClass('sizable');
                    }
                }
            },

            getOptionName:function () {
                return this.id + "_option";
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'input', _.bind(function (evt) {
                    var selection = evt.target.value;
                    // for better performance in IE7
                    var that = this;
                    setTimeout(function () {
                        that.set({selection:selection})
                    });
                }, this));
            },

            //TODO move to decorator
            makeResizable:function () {
                this.resizable = true;
                var list = this.getElem().find('ul')[0];
                var sizer = this.getElem().find('.sizer').removeClass('hidden')[0];
                layoutModule.createSizer(list, {sizer:sizer});
            }

        }),

        MultiSelectCheckbox:Controls.BaseControl.extend({

            update:function (controlData) {

                var data = _.map(controlData, function (val) {
                    var result = _.clone(val);
                    result.readOnly = this.readOnly;
                    result.uuid = _.uniqueId(this.id);
                    return result;
                }, this);

                var list = this.getElem().find('ul')[0];

                var template = this.getTemplateSection('data');

                Controls.Utils.setInnerHtml(list, template, {data:data});

                //TODO move to decorator
                if (jQuery(list).find('li').length < 5 && this.getElem()[0].clientHeight < 125) {
                    this.getElem().find('.sizer').addClass('hidden');
                    this.getElem().find('.inputSet').removeClass('sizable').attr('style', false);
                } else {
                    if (this.resizable) {
                        this.getElem().find('.sizer').removeClass('hidden');
                        this.getElem().find('.inputSet').addClass('sizable');
                    }
                }
            },

            getSelection:function () {
                var boxes = this.getElem().find(":checkbox").filter(":checked");

                return _.map(boxes, function (box) {
                    return jQuery(box).val();
                });
            },

            bindCustomEventListeners:function () {
                this.getElem().on('change', 'input', _.bind(function (evt) {
                    var selection = this.getSelection();
                    // for better performance in IE7
                    var that = this;
                    setTimeout(function () {
                        that.set({selection:selection})
                    });
                }, this));

                this.getElem().on('click','a',_.bind(function(evt) {

                    var options = this.getElem().find('input');

                    var name = jQuery(evt.target)[0].name;
                    if (name === "multiSelectAll" || name === "multiSelectNone") {
                        _.each(options,  function(opt){
                            opt.checked = name === "multiSelectAll";
                        });
                    } else if (name === "multiSelectInverse") {
                        _.each(options,  function(opt){
                            opt.checked = !opt.checked;
                        });
                    }

                    this.getElem().find('input').change(); // trigger the cascading request

                }, this));
            },

            get:function (attribute) {
                var result = this[attribute];
                if (attribute == 'selection' && _.isEmpty(result)) {
                    return [ControlsBase.NOTHING_SUBSTITUTION_VALUE];
                } else {
                    return result;
                }
            },

            //TODO move to decorator
            makeResizable:function () {
                this.resizable = true;
                var list = this.getElem().find('ul')[0];
                var sizer = this.getElem().find('.sizer').removeClass('hidden')[0];
                layoutModule.createSizer(list, {sizer:sizer});
            }

        })
    });

})(
    jQuery,
    _,
    JRS.Controls,
    layoutModule
);
