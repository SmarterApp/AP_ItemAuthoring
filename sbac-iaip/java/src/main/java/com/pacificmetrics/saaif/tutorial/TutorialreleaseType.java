//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:54:09 PM IST 
//


package com.pacificmetrics.saaif.tutorial;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *     Define the itemrelease type.
 *     Container element for the release of an Assessment (Tutorial) Item.
 *     
 * 
 * <p>Java class for tutorialreleaseType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="tutorialreleaseType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="item" type="{http://www.smarterapp.org/xsd/saaif/v1p0/tutorial_v1p0.xsd}tutorialitemType"/>
 *       &lt;/sequence>
 *       &lt;attribute name="version" type="{http://www.w3.org/2001/XMLSchema}string" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "tutorialreleaseType", propOrder = {
    "item"
})
@XmlRootElement(name = "itemrelease")
public class TutorialreleaseType {

    @XmlElement(required = true)
    protected TutorialitemType item;
    @XmlAttribute(name = "version")
    protected String version;

    /**
     * Gets the value of the item property.
     * 
     * @return
     *     possible object is
     *     {@link TutorialitemType }
     *     
     */
    public TutorialitemType getItem() {
        return item;
    }

    /**
     * Sets the value of the item property.
     * 
     * @param value
     *     allowed object is
     *     {@link TutorialitemType }
     *     
     */
    public void setItem(TutorialitemType value) {
        this.item = value;
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

}
