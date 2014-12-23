//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 06:44:50 PM IST 
//


package com.pacificmetrics.ims.apip.cp;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlIDREF;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 A Dependency element provides a way to associate another collection of asset references within the scope of the dependency element's parent resource element. This element allows the parsimonious declaration of asset refereces. Shared asset references can be declared once and associated many times through a Dependency element.
 * Represents a binding of the kinds of child objects defined for ims-cp-imDependency: Dependency.[ Extension ].
 *                 Represents a binding of the kinds of characteristic objects defined for ims-cp-imDependency: Dependency{ IdentifierRef, Other }.
 *                 [APIPv1p0] Profile - the changes to the XML element list are:
 *                 * The "extension" element has been prohibited;
 *                 [APIPv1p0] Profile - the changes to the XML attribute list are:
 *                 * The "extension" attribute has been prohibited;
 *                 * The "identifierref" attribute class type has been changed to the class "IDREF";
 *             
 * 
 * <p>Java class for Dependency.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="Dependency.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *       &lt;/sequence>
 *       &lt;attribute name="identifierref" use="required" type="{http://www.w3.org/2001/XMLSchema}IDREF" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "Dependency.Type")
public class DependencyType {

    @XmlAttribute(name = "identifierref", required = true)
    @XmlIDREF
    @XmlSchemaType(name = "IDREF")
    protected Object identifierref;

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
