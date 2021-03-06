//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:53:01 PM IST 
//


package com.pacificmetrics.saaif.passage1;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;
import org.w3c.dom.Element;


/**
 * 
 *     Define the accessElement type.
 *     Accessibility information for an item.
 *     
 * 
 * <p>Java class for accessElementType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="accessElementType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="contentLinkInfo" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}contentLinkInfoType"/>
 *         &lt;element name="relatedElementInfo" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}relatedElementInfoType"/>
 *         &lt;any processContents='lax' namespace='##other' maxOccurs="unbounded" minOccurs="0"/>
 *       &lt;/sequence>
 *       &lt;attribute name="identifier" use="required" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}uniqueIDType" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "accessElementType", propOrder = {
    "contentLinkInfo",
    "relatedElementInfo",
    "any"
})
public class AccessElementType {

    @XmlElement(required = true)
    protected ContentLinkInfoType contentLinkInfo;
    @XmlElement(required = true)
    protected RelatedElementInfoType relatedElementInfo;
    @XmlAnyElement(lax = true)
    protected List<Object> any;
    @XmlAttribute(name = "identifier", required = true)
    protected String identifier;

    /**
     * Gets the value of the contentLinkInfo property.
     * 
     * @return
     *     possible object is
     *     {@link ContentLinkInfoType }
     *     
     */
    public ContentLinkInfoType getContentLinkInfo() {
        return contentLinkInfo;
    }

    /**
     * Sets the value of the contentLinkInfo property.
     * 
     * @param value
     *     allowed object is
     *     {@link ContentLinkInfoType }
     *     
     */
    public void setContentLinkInfo(ContentLinkInfoType value) {
        this.contentLinkInfo = value;
    }

    /**
     * Gets the value of the relatedElementInfo property.
     * 
     * @return
     *     possible object is
     *     {@link RelatedElementInfoType }
     *     
     */
    public RelatedElementInfoType getRelatedElementInfo() {
        return relatedElementInfo;
    }

    /**
     * Sets the value of the relatedElementInfo property.
     * 
     * @param value
     *     allowed object is
     *     {@link RelatedElementInfoType }
     *     
     */
    public void setRelatedElementInfo(RelatedElementInfoType value) {
        this.relatedElementInfo = value;
    }

    /**
     * Gets the value of the any property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the any property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getAny().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link Object }
     * {@link Element }
     * 
     * 
     */
    public List<Object> getAny() {
        if (any == null) {
            any = new ArrayList<Object>();
        }
        return this.any;
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

}
