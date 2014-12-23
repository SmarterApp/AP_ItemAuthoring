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

;(function (jQuery, templateEngine){

    describe("Common TempateEngine", function () {

        var templateText;

        beforeEach(function() {
            templateText = "please, read this '{{message}}{{#items}}<li>{{label}}</li>{{/items}}'";
            var content =
                "<script id='sandbox' type='template/mustache'>"+
                    templateText
                    +"</script>";
            jasmine.getFixtures().set(content);

        });

        it("can render default templates", function () {
            var result = templateEngine.render(
                templateText,
                {message:"bla-bla"}
            );
            expect(result).toEqual("please, read this 'bla-bla'");
        });

        it("can render placeholders like {0} with simple array ", function () {

            var templateText = "dfsdfsdf sdfsdfsdf {0}, afdfsdfsdfsd {1} dffsdfsdf, dfsdfsdfsd {2}",
                parameters = ["a", "bb","ccc"];

            var result = templateEngine.render(
                templateText,
                parameters,
                templateEngine.STD_PLACEHOLDERS
            );

            expect(result).toEqual("dfsdfsdf sdfsdfsdf a, afdfsdfsdfsd bb dffsdfsdf, dfsdfsdfsd ccc");
        });

        it("URL is encoded if param set", function(){
            var template = "/path/to/service/entity{{entityUri}}/";
            var entityUri = "/абв/abc/qфg";
            var encoded = "/path/to/service/entity/%C3%83%C2%A0%C3%83%C2%A1%C3%83%C2%A2/abc/q%C3%83%C2%B4g/";
            var result = templateEngine.renderUrl(template, {entityUri: entityUri}, true);
            expect(result).toEqual(encoded);
        });

        it("can get template's  content", function () {
            var content = templateEngine.getTemplateText("sandbox");
            expect(content).toEqual(templateText);
        });

        it("create template function", function () {
            var template = templateEngine.createTemplate('sandbox');
            expect(template).toBeFunction();

            var result = template({message:"bla-bla"});
            expect(result).toEqual("please, read this 'bla-bla'");
        });

        it("get template section as function", function(){
            var template = templateEngine.createTemplateSection("items", "sandbox");
            expect(template).toBeFunction();

            var result = template({
                items: [
                    {label :"1"},
                    {label :"2"},
                    {label :"3"}
                ]
            });

            expect(result).toEqual("<li>1</li><li>2</li><li>3</li>");
        });
    })

})(
    jQuery,
    jaspersoft.components.templateEngine
);
