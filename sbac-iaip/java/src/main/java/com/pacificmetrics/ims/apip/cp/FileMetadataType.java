//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 06:44:50 PM IST 
//


package com.pacificmetrics.ims.apip.cp;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 An instance of the File metadata element contains data structures that declare descriptive information about the parent File only. One or more different metadata models may be declared as child extensions of a metadata element.
 * Represents a binding of the kinds of child objects defined for ims-cp-imMetadata: Metadata.[ Extension ].
 *                 [APIPv1p0] Profile - the changes to the XML element list are:
 *                 * The "schema" element has been prohibited;
 *                 * The "schemaversion" element has been prohibited;
 *             
 * 
 * <p>Java class for FileMetadata.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="FileMetadata.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;group ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/imscp_v1p1}grpStrict.any"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "FileMetadata.Type", propOrder = {
    "anies"
})
public class FileMetadataType {

    @XmlAnyElement(lax = true)
    protected List<Object> anies;

    /**
     * Gets the value of the anies property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the anies property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getAnies().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link Object }
     * 
     * 
     */
    public List<Object> getAnies() {
        if (anies == null) {
            anies = new ArrayList<Object>();
        }
        return this.anies;
    }

}