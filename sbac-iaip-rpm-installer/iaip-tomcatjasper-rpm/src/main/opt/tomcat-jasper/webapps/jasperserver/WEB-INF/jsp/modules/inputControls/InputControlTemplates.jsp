<%@ taglib uri="/spring" prefix="spring"%>

<script id="bool" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control input checkBox" for="{{uuid}}" title="{{label}}">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <input  type="checkbox" {{#readOnly}}disabled{{/readOnly}} />
        </label>
    </div>
</script>

<script id="singleValueText" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control input text"  title="{{label}}">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <input class=""  type="text" value="" {{#readOnly}}disabled{{/readOnly}} />
            <span class="warning">{{message}}</span>
        </label>
    </div>
</script>

<script id="singleValueNumber" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control input text"  title="{{label}}">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <input class=""  type="text" value="" {{#readOnly}}disabled{{/readOnly}} />
            <span class="warning">{{message}}</span>
        </label>
    </div>
</script>

<script id="singleValueDate" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control picker"
               title="{{label}}. &#10;<spring:message code="DATE_IC_TOOLTIP" javaScriptEscape="true"/>">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <input class="date"  type="text" value="" {{#readOnly}}disabled{{/readOnly}} />
            <div class="warning">{{message}}</div>
        </label>
    </div>
</script>

<script id="singleValueDatetime" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control picker"
               title="{{label}}. &#10;<spring:message code="DATE_IC_TOOLTIP" javaScriptEscape="true"/>">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <input class="date" type="text" value="" {{#readOnly}}disabled{{/readOnly}} />
            <div class="warning">{{message}}</div>
        </label>
    </div>
</script>

<script id="singleSelect" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <label class="control select"  title="{{label}}">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <select {{#readOnly}}disabled{{/readOnly}}>
                {{#data}}
                    <option value="{{value}}" {{#selected}}selected="selected"{{/selected}}>{{label}}</option>
                {{/data}}
            </select>
            <span class="warning">{{message}}</span>
        </label>
    </div>
</script>

<script id="multiSelect" type="template/mustache">
    <div class="leaf" id="{{id}}">
        <label class="control select multiple"  title="{{label}}">
            <span class="wrap">{{#mandatory}}* {{/mandatory}}{{label}}</span>
            <select multiple="multiple" {{#readOnly}}disabled{{/readOnly}}>
                {{#data}}
                    <option value="{{value}}" {{#selected}}selected="selected"{{/selected}}>{{label}}</option>
                {{/data}}
            </select>
	        <div class="{{#readOnly}}hidden{{/readOnly}}">
    	        <a href="#" name="multiSelectAll"><spring:message code="button.select.all" javaScriptEscape="true"/></a>
    	        <a href="#" name="multiSelectNone"><spring:message code="button.select.none" javaScriptEscape="true"/></a>
    	        <a href="#" name="multiSelectInverse"><spring:message code="button.select.inverse" javaScriptEscape="true"/></a>
    	    </div>
            <span class="warning">{{message}}</span>
            <div class="resizeOverlay hidden"></div>
            <div class="sizer vertical hidden"><span class="ui-icon ui-icon-grip-solid-horizontal"></span></div>
        </label>
    </div>
</script>

<script id="singleSelectRadio" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <fieldset class="control select multiple" title="{{label}}">
            <legend>{{#mandatory}}* {{/mandatory}}{{label}}</legend>
            <ul class="list inputSet">
                {{#data}}
                <li>
                    <div class="control radio">
                        <input {{#selected}}checked="checked"{{/selected}} class="" id="{{uuid}}" type="radio" name="{{name}}" {{#readOnly}}disabled="disabled"{{/readOnly}} value="{{value}}"/>
                        <label class="wrap" for="{{uuid}}" title="{{label}}">
                            {{label}}&nbsp;
                        </label>
                    </div>
                </li>
                {{/data}}
            </ul>
        </fieldset>
        <span class="warning">{{message}}</span>
        <div class="resizeOverlay hidden"></div>
        <div class="sizer vertical hidden"><span class="ui-icon ui-icon-grip-solid-horizontal"></span></div>
    </div>
</script>

<script id="multiSelectCheckbox" type="template/mustache">
    <div id="{{id}}" class="leaf">
        <fieldset class="control select checkbox" title="{{label}}">
            <legend>{{#mandatory}}* {{/mandatory}}{{label}}</legend>
            <ul class="list inputSet">
                {{#data}}
                    <li>
                        <div class="control checkBox">
                            <label class="wrap" for="{{uuid}}" title="{{label}}">
                                {{label}}&nbsp;
                            </label>
                            <input {{#selected}}checked="checked"{{/selected}} class="" id="{{uuid}}" type="checkbox" {{#readOnly}}disabled="disabled"{{/readOnly}} value="{{value}}"/>
                        </div>
                    </li>
                {{/data}}
            </ul>
	        <div class="{{#readOnly}}hidden{{/readOnly}}">
                <a href="#" name="multiSelectAll"><spring:message code="button.select.all" javaScriptEscape="true"/></a>
                <a href="#" name="multiSelectNone"><spring:message code="button.select.none" javaScriptEscape="true"/></a>
                <a href="#" name="multiSelectInverse"><spring:message code="button.select.inverse" javaScriptEscape="true"/></a>
            </div>
        </fieldset>
        <span class="warning">{{message}}</span>
        <div class="resizeOverlay hidden"></div>
        <div class="sizer vertical hidden"><span class="ui-icon ui-icon-grip-solid-horizontal"></span></div>
    </div>
</script>

<script id="reportOptions" type="template/mustache">
    <div>
        <label class="control select" for="reportOptionsSelect" title="{{title}}">
            <span class="wrap">{{label}}</span>
            <select id="reportOptionsSelect">
                {{#data}}
                    <option value="{{id}}" {{#selected}}selected="selected"{{/selected}}>{{label}}</option>
                {{/data}}
            </select>
        </label>
    </div>
</script>


