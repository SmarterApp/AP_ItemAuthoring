//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti.item;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 The MatchTableEnry complexType is the container for an entry n a match table. Intentionally empty comlexType.
 *             
 * 
 * <p>Java class for MatchTableEntry.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="MatchTableEntry.Type">
 *   &lt;complexContent>
 *     &lt;extension base="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}EmptyPrimitiveType.Type">
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}sourceValue.MatchTableEntry.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}targetValue.MatchTableEntry.Attr"/>
 *     &lt;/extension>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "MatchTableEntry.Type")
@XmlRootElement(name = "matchTableEntry")
public class MatchTableEntry
    extends EmptyPrimitiveTypeType
{

    @XmlAttribute(name = "sourceValue", required = true)
    protected int sourceValue;
    @XmlAttribute(name = "targetValue", required = true)
    protected String targetValue;

    /**
     * Gets the value of the sourceValue property.
     * 
     */
    public int getSourceValue() {
        return sourceValue;
    }

    /**
     * Sets the value of the sourceValue property.
     * 
     */
    public void setSourceValue(int value) {
        this.sourceValue = value;
    }

    /**
     * Gets the value of the targetValue property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getTargetValue() {
        return targetValue;
    }

    /**
     * Sets the value of the targetValue property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setTargetValue(String value) {
        this.targetValue = value;
    }

}
