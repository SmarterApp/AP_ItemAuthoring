//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:54:09 PM IST 
//


package com.pacificmetrics.saaif.tutorial;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 * 			    Define the KeyWordTranslation type.
 * 			    String containing languages and information.
 * 			    
 * 
 * <p>Java class for KeyWordTranslation.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="KeyWordTranslation.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="definitionId" type="{http://www.smarterapp.org/xsd/saaif/v1p0/tutorial_v1p0.xsd}definitionIdType" minOccurs="0"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "KeyWordTranslation.Type", propOrder = {
    "definitionId"
})
public class KeyWordTranslationType {

    protected DefinitionIdType definitionId;

    /**
     * Gets the value of the definitionId property.
     * 
     * @return
     *     possible object is
     *     {@link DefinitionIdType }
     *     
     */
    public DefinitionIdType getDefinitionId() {
        return definitionId;
    }

    /**
     * Sets the value of the definitionId property.
     * 
     * @param value
     *     allowed object is
     *     {@link DefinitionIdType }
     *     
     */
    public void setDefinitionId(DefinitionIdType value) {
        this.definitionId = value;
    }

}
