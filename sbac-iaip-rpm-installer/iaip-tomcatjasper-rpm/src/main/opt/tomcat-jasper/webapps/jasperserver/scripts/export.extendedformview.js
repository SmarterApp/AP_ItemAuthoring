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
 * @author inesterenko
 */

JRS.Export.ExtendedFormView = (function (exportz, jQuery, _, Backbone, templateEngine, AuthorityModel, AuthorityPickerView, State) {

    return Backbone.View.extend({

        events:{
            "input #exportDataFile #filenameId":"editFileName",
            "change #exportOptions #everything":"exportEverything",
            "change #exportOptions #includeSystemProperties":"includeSystemProperties",
            "change #exportOptions #roleUsers":"includeRolesByUsers",
            "change #exportOptions #includeAccessEvents":"includeAccessEvents",
            "change #exportOptions #includeAuditEvents":"includeAuditEvents",
            "change #exportOptions #includeMonitoringEvents ":"includeMonitoringEvents",
            "click #exportOptions .checkBox label":"clickOnCheckbox",
            "click #exportButton":"sendParameters"

        },

        initialize:function () {
            _.bindAll(this);

            this.rolesList = new AuthorityPickerView({
                model:AuthorityModel.instance("rest_v2/roles{{#searchString}}?search={{searchString}}{{/searchString}}"),
                customClass:"selectedRoles",
                title:exportz.i18n["export.select.roles"]
            });

            this.rolesList.on("change:selection", this.bindWithRoles);
            this.rolesList.render();

            this.usersList = new AuthorityPickerView({
                model:AuthorityModel.instance("rest_v2/users{{#searchString}}?search={{searchString}}{{/searchString}}"),
                customClass:"select selectedUsers",
                title:exportz.i18n["export.select.users"]
            });

            this.usersList.on("change:selection", this.bindWithUsers);
            this.usersList.render();

            this.rolesToUsers =  AuthorityModel.instance("rest_v2/users?hasAllRequiredRoles=false{{#roles}}&requiredRole={{.}}{{/roles}}");
            this.rolesToUsers.on("change", this.onRolesToUsersChange);

            this.fileTemplate = templateEngine.createTemplate("exportDataFileTemplate");
            this.optionsTemplate = templateEngine.createTemplate("exportOptionsTemplates");
            this.controlsTemplate = templateEngine.createTemplate("controlButtonsTemplate");

            this.model.on("change", this.onModelChange);
        },

        render:function (options) {
            var fileControlHtml = this.fileTemplate({defaultFileName:this.model.get('fileName')});
            var optionsHtml = this.optionsTemplate({
                everything:this.model.get("everything"),
                includeSystemProperties:this.model.get("includeSystemProperties"),
                userForRoles:this.model.get("userForRoles"),
                includeAccessEvents:this.model.get("includeAccessEvents"),
                includeAuditEvents:this.model.get("includeAuditEvents")
            });
            var controlsHtml = this.controlsTemplate();

            if (options && options.container) {
                this.undelegateEvents();
                this.$el = jQuery(options.container);
                this.el = this.$el[0];
                this.$el.find(".body").append(fileControlHtml + optionsHtml);
                this.$el.find(".footer").prepend(controlsHtml);
                this.delegateEvents();
            } else {
                this.$el.html(fileControlHtml + optionsHtml + controlsHtml);
            }

            this.$el.find("#selectRolesUsers").append(this.rolesList.el).append(this.usersList.el);
            jQuery.browser.msie && this.$el.find("#exportDataFile #filenameId").on("propertychange input",this.editFileName);

            this.changeEnabledState(this.model.get("everything"));

            return this;
        },

        bindWithRoles : function(selection){
            this.model.set({roles:selection});
            if (selection.length) {
                this.rolesToUsers.setContext({roles: selection});
            } else {
                this.rolesToUsers.set({items:[]});
            }
        },

        bindWithUsers : function(selection){
            this.model.set({users:selection});
        },

        changeEnabledState : function(value){
            this.rolesList.setDisabled(value);
            this.usersList.setDisabled(value);

            this.$el.find("#roleUsers").attr("disabled", value);

            this.$el.find("#includeAccessEvents").attr("disabled", !value).attr("checked", this.model.get("includeAccessEvents"));
        },

        editFileName:function (evt) {
            var edit = jQuery(evt.target);
            var button =  this.$el.find("#exportButton").attr("disabled", false);
            edit.parent().removeClass("error");
            this.model.set({fileName: edit.val()}, {
                    error: function(model, error) {
                        edit.next().html(error);
                        edit.parent().addClass("error");
                        button.attr("disabled", true);
                    }
                });
        },

        exportEverything:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({everything:val});
            this.changeEnabledState(val);
            if (val){
                this.rolesList.selectNone();
                this.usersList.selectNone();
            }
        },

        includeSystemProperties:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({includeSystemProperties:val});
        },

        includeRolesByUsers:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({userForRoles:val});
            this.onRolesToUsersChange();
        },

        includeAccessEvents:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({includeAccessEvents:val});
        },

        includeAuditEvents:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({includeAuditEvents:val});
        },

        includeMonitoringEvents:function (evt) {
            var val = jQuery(evt.target).is(":checked");
            this.model.set({includeMonitoringEvents:val});
        },

        sendParameters:function (evt) {
            if (this.model.isValid() && this.model.isAcceptable() && this.isValid()) {
                this.model.save();
            }
        },

        clickOnCheckbox: function(evt){
            var checkbox = jQuery(evt.target).next();
            if (!checkbox[0].disabled) {
                checkbox[0].checked = !checkbox[0].checked;
                checkbox.trigger("change");
            }
        },

        isValid: function(){
            return !this.$el.find("fieldset .error").length;
        },

        onModelChange: function() {
            var button = this.$el.find("#exportButton");
            button.attr("disabled", !(this.model.isAcceptable() && this.isValid()));
        },

        onRolesToUsersChange: function() {
            if (this.model.get("userForRoles")) {
                this.usersList.highlightSet(_.map(this.rolesToUsers.get("items"), function(item) {
                    return item.username + (item.tenantId ? "|" + item.tenantId : "")
                }));
            } else {
                this.usersList.highlightSet([]);
            }
        }
    })

})(
    JRS.Export,
    jQuery,
    _,
    Backbone,
    jaspersoft.components.templateEngine,
    jaspersoft.components.AuthorityModel,
    jaspersoft.components.AuthorityPickerView,
    jaspersoft.components.State
);