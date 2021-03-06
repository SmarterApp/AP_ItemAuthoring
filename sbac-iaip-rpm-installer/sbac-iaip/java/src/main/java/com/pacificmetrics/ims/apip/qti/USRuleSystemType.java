//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti;

import java.math.BigInteger;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 The USRuleSystem complexType is the container for the simple specification of the Rule, using US units, to be used with the set of APIP Items. The Rule is defined in terms of its length and increment resolution.
 *             
 * 
 * <p>Java class for USRuleSystem.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="USRuleSystem.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="minimumLength" type="{http://www.w3.org/2001/XMLSchema}integer"/>
 *         &lt;element name="minorIncrement" type="{http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0}USLinearValue.Type" minOccurs="0"/>
 *         &lt;element name="majorIncrement" type="{http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0}USLinearValue.Type"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "USRuleSystem.Type", propOrder = {
    "minimumLength",
    "minorIncrement",
    "majorIncrement"
})
public class USRuleSystemType {

    @XmlElement(required = true)
    protected BigInteger minimumLength;
    protected USLinearValueType minorIncrement;
    @XmlElement(required = true)
    protected USLinearValueType majorIncrement;

    /**
     * Gets the value of the minimumLength property.
     * 
     * @return
     *     possible object is
     *     {@link BigInteger }
     *     
     */
    public BigInteger getMinimumLength() {
        return minimumLength;
    }

    /**
     * Sets the value of the minimumLength property.
     * 
     * @param value
     *     allowed object is
     *     {@link BigInteger }
     *     
     */
    public void setMinimumLength(BigInteger value) {
        this.minimumLength = value;
    }

    /**
     * Gets the value of the minorIncrement property.
     * 
     * @return
     *     possible object is
     *     {@link USLinearValueType }
     *     
     */
    public USLinearValueType getMinorIncrement() {
        return minorIncrement;
    }

    /**
     * Sets the value of the minorIncrement property.
     * 
     * @param value
     *     allowed object is
     *     {@link USLinearValueType }
     *     
     */
    public void setMinorIncrement(USLinearValueType value) {
        this.minorIncrement = value;
    }

    /**
     * Gets the value of the majorIncrement property.
     * 
     * @return
     *     possible object is
     *     {@link USLinearValueType }
     *     
     */
    public USLinearValueType getMajorIncrement() {
        return majorIncrement;
    }

    /**
     * Sets the value of the majorIncrement property.
     * 
     * @param value
     *     allowed object is
     *     {@link USLinearValueType }
     *     
     */
    public void setMajorIncrement(USLinearValueType value) {
        this.majorIncrement = value;
    }

}
