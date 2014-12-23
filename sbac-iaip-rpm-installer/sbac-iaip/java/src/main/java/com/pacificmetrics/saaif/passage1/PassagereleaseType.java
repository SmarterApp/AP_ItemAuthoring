//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:53:01 PM IST 
//


package com.pacificmetrics.saaif.passage1;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *     Define the passage itemrelease type.
 *     Container element for the release of a Passage Item.
 *     
 * 
 * <p>Java class for passagereleaseType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="passagereleaseType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="passage" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}passageType"/>
 *       &lt;/sequence>
 *       &lt;attribute name="version" type="{http://www.w3.org/2001/XMLSchema}string" />
 *       &lt;attribute name="schemaversion" type="{http://www.w3.org/2001/XMLSchema}string" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "passagereleaseType", propOrder = {
    "passage"
})
@XmlRootElement(name = "itemrelease")
public class PassagereleaseType {

    @XmlElement(required = true)
    protected PassageType passage;
    @XmlAttribute(name = "version")
    protected String version;
    @XmlAttribute(name = "schemaversion")
    protected String schemaversion;

    /**
     * Gets the value of the passage property.
     * 
     * @return
     *     possible object is
     *     {@link PassageType }
     *     
     */
    public PassageType getPassage() {
        return passage;
    }

    /**
     * Sets the value of the passage property.
     * 
     * @param value
     *     allowed object is
     *     {@link PassageType }
     *     
     */
    public void setPassage(PassageType value) {
        this.passage = value;
    }

    /**
     * Gets the value of the version property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getVersion() {
        return version;
    }

    /**
     * Sets the value of the version property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setVersion(String value) {
        this.version = value;
    }

    /**
     * Gets the value of the schemaversion property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getSchemaversion() {
        return schemaversion;
    }

    /**
     * Sets the value of the schemaversion property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setSchemaversion(String value) {
        this.schemaversion = value;
    }

}