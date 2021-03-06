//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 06:44:50 PM IST 
//


package org.ieee.ltsc.lom.resource;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElementRef;
import javax.xml.bind.annotation.XmlElementRefs;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 The Kind complexType is the container for the nature of the relationship between this learning object and the
 * target learning object, identified by information in the associated Resource complexType.  In LOMv1.0 (Strict) this is an 
 * enumerated vocabulary.
 *             
 * 
 * <p>Java class for Kind.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="Kind.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;choice maxOccurs="unbounded" minOccurs="0">
 *         &lt;element name="source" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/resource}CharacterString.Type" minOccurs="0"/>
 *         &lt;element name="value" minOccurs="0">
 *           &lt;simpleType>
 *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *               &lt;enumeration value="ispartof"/>
 *               &lt;enumeration value="haspart"/>
 *               &lt;enumeration value="isversionof"/>
 *               &lt;enumeration value="hasversion"/>
 *               &lt;enumeration value="isformatof"/>
 *               &lt;enumeration value="hasformat"/>
 *               &lt;enumeration value="references"/>
 *               &lt;enumeration value="isreferencedby"/>
 *               &lt;enumeration value="isbasedon"/>
 *               &lt;enumeration value="isbasisfor"/>
 *               &lt;enumeration value="requires"/>
 *               &lt;enumeration value="isrequiredby"/>
 *             &lt;/restriction>
 *           &lt;/simpleType>
 *         &lt;/element>
 *       &lt;/choice>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "Kind.Type", propOrder = {
    "sourcesAndValues"
})
public class KindType {

    @XmlElementRefs({
        @XmlElementRef(name = "source", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/resource", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "value", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/resource", type = JAXBElement.class, required = false)
    })
    protected List<JAXBElement<String>> sourcesAndValues;

    /**
     * Gets the value of the sourcesAndValues property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the sourcesAndValues property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getSourcesAndValues().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link JAXBElement }{@code <}{@link String }{@code >}
     * {@link JAXBElement }{@code <}{@link String }{@code >}
     * 
     * 
     */
    public List<JAXBElement<String>> getSourcesAndValues() {
        if (sourcesAndValues == null) {
            sourcesAndValues = new ArrayList<JAXBElement<String>>();
        }
        return this.sourcesAndValues;
    }

}
