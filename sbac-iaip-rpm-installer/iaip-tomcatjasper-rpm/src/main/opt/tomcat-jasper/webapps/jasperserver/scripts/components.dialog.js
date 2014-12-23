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

jaspersoft.components.Dialog = (function(exports, $, _, Backbone, templateEngine, dialogs) {

//module:
//
//
//summary:
//
//
    var constants = {
        TEMPLATE_ID : "exportsDialogTemplate"
    };

    return Backbone.View.extend({
        events: {
            "click .cancel":"hide"
        },

        initialize : function(){
            _.bindAll(this);
        },

        render : function(elem){
            this.undelegateEvents();
            var dialogPopup = $(templateEngine.getTemplateText(exports.Dialog.TEMPLATE_ID)).closest("div");
            this.$el = dialogPopup;
            this.el = dialogPopup[0];
            $(elem ? elem : document.body).append(this.$el);
            this.delegateEvents();

            return this;
        },

        hide: function(event){
            dialogs.popup.hide(this.el);
            event && event.stopPropagation();
        },

        show: function(){
            dialogs.popup.show(this.el, this.options.modal);
        }

    },constants);

})(
    jaspersoft.components,
    jQuery,
    _,
    Backbone,
    jaspersoft.components.templateEngine,
    dialogs
);
