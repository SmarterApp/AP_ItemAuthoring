//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 06:44:50 PM IST 
//


package com.pacificmetrics.ims.apip.cpext;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlID;
import javax.xml.bind.annotation.XmlIDREF;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;


/**
 * 
 *                 A variant element is closely analogous to a resource element in the IMS CP informaton model. Variant is a container for an alternative resource. A resource many contain references to assets that are all of the same type or different types i.e. file formats. The Variant class points to the alternative resource. Metadata is used to describe the nature of a collection of alternative assets and their intended use. Examples include, but are not limited to, use as lingual variants, visual or auditory variants, remediation variants or platform delivery variants. The scope of referenced assts is specific to a Variant object. Their use is in the context of the parent object containing a variant instance, typically a bound instance of a Resource object from the IMS CP namespace.
 * Represents a binding of the kinds of child objects defined for ims-cp-imResource: Resource.[ Metadata, File, Dependency, Extension ].
 *                 Represents a binding of the kinds of characteristic objects defined for ims-cp-imResource: Resource{ Identifier, Type, Base, Href, Other }.
 *             
 * 
 * <p>Java class for Variant.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="Variant.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="metadata" type="{http://www.imsglobal.org/xsd/apip/apipv1p0/imscp_extensionv1p2}Metadata.Type"/>
 *       &lt;/sequence>
 *       &lt;attribute name="identifier" use="required" type="{http://www.w3.org/2001/XMLSchema}ID" />
 *       &lt;attribute name="identifierref" use="required" type="{http://www.w3.org/2001/XMLSchema}IDREF" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "Variant.Type", propOrder = {
    "metadata"
})
@XmlRootElement(name = "variant")
public class Variant {

    @XmlElement(required = true)
    protected MetadataType metadata;
    @XmlAttribute(name = "identifier", required = true)
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    @XmlID
    @XmlSchemaType(name = "ID")
    protected String identifier;
    @XmlAttribute(name = "identifierref", required = true)
    @XmlIDREF
    @XmlSchemaType(name = "IDREF")
    protected Object identifierref;

    /**
     * Gets the value of the metadata property.
     * 
     * @return
     *     possible object is
     *     {@link MetadataType }
     *     
     */
    public MetadataType getMetadata() {
        return metadata;
    }

    /**
     * Sets the value of the metadata property.
     * 
     * @param value
     *     allowed object is
     *     {@link MetadataType }
     *     
     */
    public void setMetadata(MetadataType value) {
        this.metadata = value;
    }

    /**
     * Gets the value of the identifier property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getIdentifier() {
        return identifier;
    }

    /**
     * Sets the value of the identifier property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setIdentifier(String value) {
        this.identifier = value;
    }

    /**
     * Gets the value of the identifierref property.
     * 
     * @return
     *     possible object is
     *     {@link Object }
     *     
     */
    public Object getIdentifierref() {
        return identifierref;
    }

    /**
     * Sets the value of the identifierref property.
     * 
     * @param value
     *     allowed object is
     *     {@link Object }
     *     
     */
    public void setIdentifierref(Object value) {
        this.identifierref = value;
    }

}