//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, vhudson-jaxb-ri-2.1-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2013.01.06 at 01:14:11 PM MST 
//


package com.pacificmetrics.apip.cp.manifest;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;


/**
 * <p>Java class for lifeCycleType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="lifeCycleType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="version" type="{http://pacificmetrics.com/apip/cp/manifest}versionType"/>
 *         &lt;element name="status" type="{http://pacificmetrics.com/apip/cp/manifest}statusType"/>
 *         &lt;element name="contribute" type="{http://pacificmetrics.com/apip/cp/manifest}contributeType"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "lifeCycleType", propOrder = {
    "version",
    "status",
    "contribute"
})
public class LifeCycleType {

    @XmlElement(required = true)
    protected VersionType version;
    @XmlElement(required = true)
    protected StatusType status;
    @XmlElement(required = true)
    protected ContributeType contribute;

    /**
     * Gets the value of the version property.
     * 
     * @return
     *     possible object is
     *     {@link VersionType }
     *     
     */
    public VersionType getVersion() {
        return version;
    }

    /**
     * Sets the value of the version property.
     * 
     * @param value
     *     allowed object is
     *     {@link VersionType }
     *     
     */
    public void setVersion(VersionType value) {
        this.version = value;
    }

    /**
     * Gets the value of the status property.
     * 
     * @return
     *     possible object is
     *     {@link StatusType }
     *     
     */
    public StatusType getStatus() {
        return status;
    }

    /**
     * Sets the value of the status property.
     * 
     * @param value
     *     allowed object is
     *     {@link StatusType }
     *     
     */
    public void setStatus(StatusType value) {
        this.status = value;
    }

    /**
     * Gets the value of the contribute property.
     * 
     * @return
     *     possible object is
     *     {@link ContributeType }
     *     
     */
    public ContributeType getContribute() {
        return contribute;
    }

    /**
     * Sets the value of the contribute property.
     * 
     * @param value
     *     allowed object is
     *     {@link ContributeType }
     *     
     */
    public void setContribute(ContributeType value) {
        this.contribute = value;
    }

}
