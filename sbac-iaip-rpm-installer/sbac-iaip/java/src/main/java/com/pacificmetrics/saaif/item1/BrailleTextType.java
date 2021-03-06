//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:51:28 PM IST 
//


package com.pacificmetrics.saaif.item1;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlType;
import org.w3c.dom.Element;


/**
 * 
 *     Define the brailleText type.
 *     String containing pronunciation directives.
 *     
 * 
 * <p>Java class for brailleTextType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="brailleTextType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="brailleTextString" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}brailleTextStringType" minOccurs="0"/>
 *         &lt;element name="brailleCode" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}brailleCodeType" minOccurs="0"/>
 *         &lt;any processContents='lax' namespace='##other' maxOccurs="unbounded" minOccurs="0"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "brailleTextType", propOrder = {
    "brailleTextString",
    "brailleCode",
    "any"
})
public class BrailleTextType {

    protected String brailleTextString;
    protected BrailleCodeType brailleCode;
    @XmlAnyElement(lax = true)
    protected List<Object> any;

    /**
     * Gets the value of the brailleTextString property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getBrailleTextString() {
        return brailleTextString;
    }

    /**
     * Sets the value of the brailleTextString property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setBrailleTextString(String value) {
        this.brailleTextString = value;
    }

    /**
     * Gets the value of the brailleCode property.
     * 
     * @return
     *     possible object is
     *     {@link BrailleCodeType }
     *     
     */
    public BrailleCodeType getBrailleCode() {
        return brailleCode;
    }

    /**
     * Sets the value of the brailleCode property.
     * 
     * @param value
     *     allowed object is
     *     {@link BrailleCodeType }
     *     
     */
    public void setBrailleCode(BrailleCodeType value) {
        this.brailleCode = value;
    }

    /**
     * Gets the value of the any property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the any property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getAny().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link Object }
     * {@link Element }
     * 
     * 
     */
    public List<Object> getAny() {
        if (any == null) {
            any = new ArrayList<Object>();
        }
        return this.any;
    }

}
