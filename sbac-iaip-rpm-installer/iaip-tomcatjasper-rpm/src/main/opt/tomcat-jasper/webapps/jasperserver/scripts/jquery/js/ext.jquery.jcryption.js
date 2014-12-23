/*
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
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

(function($) {
    /**
     * The function was modified from jquery.jcryption.js  $.jCryption.encryptKey version in order NOT
     * to include redundancy/checksum bytes.
     *
     * @param {string} string The AES key
     * @param {keypair} keyPair The RSA keypair to use
     * @param {function} callback The function to call when the encryption has finished
     */
    $.jCryption.encryptKeyWithoutRedundancy = function(string, keyPair, callback) {
        var charSum = 0;
        for(var i = 0; i < string.length; i++){
            charSum += string.charCodeAt(i);
        }

        /*		var tag = '0123456789abcdef';
         var hex = '';
         hex += tag.charAt((charSum & 0xF0) >> 4) + tag.charAt(charSum & 0x0F);

         var taggedString = hex + string;*/

        var encrypt = [];
        var j = 0;

        /*
         while (j < taggedString.length) {
         encrypt[j] = taggedString.charCodeAt(j);
         j++;
         }
         */

        while (j < string.length) {
            encrypt[j] = string.charCodeAt(j);
            j++;
        }

        while (encrypt.length % keyPair.chunkSize !== 0) {
            encrypt[j++] = 0;
        }

        function encryption(encryptObject) {
            var charCounter = 0;
            var j, block;
            var encrypted = "";
            function encryptChar() {
                block = new BigInt();
                j = 0;
                for (var k = charCounter; k < charCounter+keyPair.chunkSize; ++j) {
                    block.digits[j] = encryptObject[k++];
                    block.digits[j] += encryptObject[k++] << 8;
                }
                var crypt = keyPair.barrett.powMod(block, keyPair.e);
                var text = keyPair.radix == 16 ? biToHex(crypt) : biToString(crypt, keyPair.radix);
                encrypted += text + " ";
                charCounter += keyPair.chunkSize;
                if (charCounter < encryptObject.length) {
                    setTimeout(encryptChar, 1)
                } else {
                    var encryptedString = encrypted.substring(0, encrypted.length - 1);
                    if($.isFunction(callback)) {
                        callback(encryptedString);
                    } else {
                        return encryptedString;
                    }

                }
            }
            setTimeout(encryptChar, 1);
        }

        encryption(encrypt);
    };
})(jQuery);

