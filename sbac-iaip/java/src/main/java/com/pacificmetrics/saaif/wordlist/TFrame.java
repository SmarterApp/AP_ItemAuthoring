//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.09.17 at 10:18:01 AM IST 
//


package com.pacificmetrics.saaif.wordlist;

import javax.xml.bind.annotation.XmlEnum;
import javax.xml.bind.annotation.XmlEnumValue;
import javax.xml.bind.annotation.XmlType;


/**
 * <p>Java class for TFrame.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * <p>
 * <pre>
 * &lt;simpleType name="TFrame">
 *   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}token">
 *     &lt;enumeration value="void"/>
 *     &lt;enumeration value="above"/>
 *     &lt;enumeration value="below"/>
 *     &lt;enumeration value="hsides"/>
 *     &lt;enumeration value="lhs"/>
 *     &lt;enumeration value="rhs"/>
 *     &lt;enumeration value="vsides"/>
 *     &lt;enumeration value="box"/>
 *     &lt;enumeration value="border"/>
 *   &lt;/restriction>
 * &lt;/simpleType>
 * </pre>
 * 
 */
@XmlType(name = "TFrame")
@XmlEnum
public enum TFrame {

    @XmlEnumValue("void")
    VOID("void"),
    @XmlEnumValue("above")
    ABOVE("above"),
    @XmlEnumValue("below")
    BELOW("below"),
    @XmlEnumValue("hsides")
    HSIDES("hsides"),
    @XmlEnumValue("lhs")
    LHS("lhs"),
    @XmlEnumValue("rhs")
    RHS("rhs"),
    @XmlEnumValue("vsides")
    VSIDES("vsides"),
    @XmlEnumValue("box")
    BOX("box"),
    @XmlEnumValue("border")
    BORDER("border");
    private final String value;

    TFrame(String v) {
        value = v;
    }

    public String value() {
        return value;
    }

    public static TFrame fromValue(String v) {
        for (TFrame c: TFrame.values()) {
            if (c.value.equals(v)) {
                return c;
            }
        }
        throw new IllegalArgumentException(v);
    }

}
