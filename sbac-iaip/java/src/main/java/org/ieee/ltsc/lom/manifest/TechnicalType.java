//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 06:44:50 PM IST 
//


package org.ieee.ltsc.lom.manifest;

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
 *                 The Technical complexType is the container for the information that describes the technical requirements and 
 * characteristics of this learning object.
 *             
 * 
 * <p>Java class for Technical.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="Technical.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;choice maxOccurs="unbounded" minOccurs="0">
 *         &lt;element name="format" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}CharacterString.Type" maxOccurs="unbounded" minOccurs="0"/>
 *         &lt;element name="size" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}CharacterString.Type" minOccurs="0"/>
 *         &lt;element name="location" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}CharacterString.Type" maxOccurs="unbounded" minOccurs="0"/>
 *         &lt;element name="requirement" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}Requirement.Type" maxOccurs="unbounded" minOccurs="0"/>
 *         &lt;element name="installationRemarks" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}LangString.Type" minOccurs="0"/>
 *         &lt;element name="otherPlatformRequirements" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}LangString.Type" minOccurs="0"/>
 *         &lt;element name="duration" type="{http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest}Duration.Type" minOccurs="0"/>
 *       &lt;/choice>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "Technical.Type", propOrder = {
    "formatsAndSizesAndLocations"
})
public class TechnicalType {

    @XmlElementRefs({
        @XmlElementRef(name = "requirement", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "size", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "otherPlatformRequirements", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "duration", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "format", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "location", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "installationRemarks", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest", type = JAXBElement.class, required = false)
    })
    protected List<JAXBElement<?>> formatsAndSizesAndLocations;

    /**
     * Gets the value of the formatsAndSizesAndLocations property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the formatsAndSizesAndLocations property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getFormatsAndSizesAndLocations().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link JAXBElement }{@code <}{@link String }{@code >}
     * {@link JAXBElement }{@code <}{@link RequirementType }{@code >}
     * {@link JAXBElement }{@code <}{@link String }{@code >}
     * {@link JAXBElement }{@code <}{@link LangStringType }{@code >}
     * {@link JAXBElement }{@code <}{@link String }{@code >}
     * {@link JAXBElement }{@code <}{@link LangStringType }{@code >}
     * {@link JAXBElement }{@code <}{@link DurationType }{@code >}
     * 
     * 
     */
    public List<JAXBElement<?>> getFormatsAndSizesAndLocations() {
        if (formatsAndSizesAndLocations == null) {
            formatsAndSizesAndLocations = new ArrayList<JAXBElement<?>>();
        }
        return this.formatsAndSizesAndLocations;
    }

}
