//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.10.22 at 03:51:28 PM IST 
//


package com.pacificmetrics.saaif.item1;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;
import org.w3c.dom.Element;


/**
 * 
 *     Define the passagecontent type.
 *     Content of a passage item.
 *     
 * 
 * <p>Java class for passagecontentType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="passagecontentType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="title" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}titleType"/>
 *         &lt;element name="author" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}authorType" minOccurs="0"/>
 *         &lt;element name="stem" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}stemType"/>
 *         &lt;element name="attachmentlist" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}attachmentlistType" minOccurs="0"/>
 *         &lt;element name="apipAccessibility" type="{http://www.smarterapp.org/xsd/saaif/v1p0/assessmentitem_v1p0.xsd}apipAccessibilityType" minOccurs="0"/>
 *         &lt;any processContents='lax' namespace='##other' maxOccurs="unbounded" minOccurs="0"/>
 *       &lt;/sequence>
 *       &lt;attribute name="language" use="required" type="{http://www.w3.org/2001/XMLSchema}language" />
 *       &lt;attribute name="version" use="required" type="{http://www.w3.org/2001/XMLSchema}string" />
 *       &lt;attribute name="approvedVersion" type="{http://www.w3.org/2001/XMLSchema}string" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "passagecontentType", propOrder = {
    "title",
    "author",
    "stem",
    "attachmentlist",
    "apipAccessibility",
    "any"
})
public class PassagecontentType {

    @XmlElement(required = true)
    protected TitleType title;
    protected AuthorType author;
    @XmlElement(required = true)
    protected StemType stem;
    protected AttachmentlistType attachmentlist;
    protected ApipAccessibilityType apipAccessibility;
    @XmlAnyElement(lax = true)
    protected List<Object> any;
    @XmlAttribute(name = "language", required = true)
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    @XmlSchemaType(name = "language")
    protected String language;
    @XmlAttribute(name = "version", required = true)
    protected String version;
    @XmlAttribute(name = "approvedVersion")
    protected String approvedVersion;

    /**
     * Gets the value of the title property.
     * 
     * @return
     *     possible object is
     *     {@link TitleType }
     *     
     */
    public TitleType getTitle() {
        return title;
    }

    /**
     * Sets the value of the title property.
     * 
     * @param value
     *     allowed object is
     *     {@link TitleType }
     *     
     */
    public void setTitle(TitleType value) {
        this.title = value;
    }

    /**
     * Gets the value of the author property.
     * 
     * @return
     *     possible object is
     *     {@link AuthorType }
     *     
     */
    public AuthorType getAuthor() {
        return author;
    }

    /**
     * Sets the value of the author property.
     * 
     * @param value
     *     allowed object is
     *     {@link AuthorType }
     *     
     */
    public void setAuthor(AuthorType value) {
        this.author = value;
    }

    /**
     * Gets the value of the stem property.
     * 
     * @return
     *     possible object is
     *     {@link StemType }
     *     
     */
    public StemType getStem() {
        return stem;
    }

    /**
     * Sets the value of the stem property.
     * 
     * @param value
     *     allowed object is
     *     {@link StemType }
     *     
     */
    public void setStem(StemType value) {
        this.stem = value;
    }

    /**
     * Gets the value of the attachmentlist property.
     * 
     * @return
     *     possible object is
     *     {@link AttachmentlistType }
     *     
     */
    public AttachmentlistType getAttachmentlist() {
        return attachmentlist;
    }

    /**
     * Sets the value of the attachmentlist property.
     * 
     * @param value
     *     allowed object is
     *     {@link AttachmentlistType }
     *     
     */
    public void setAttachmentlist(AttachmentlistType value) {
        this.attachmentlist = value;
    }

    /**
     * Gets the value of the apipAccessibility property.
     * 
     * @return
     *     possible object is
     *     {@link ApipAccessibilityType }
     *     
     */
    public ApipAccessibilityType getApipAccessibility() {
        return apipAccessibility;
    }

    /**
     * Sets the value of the apipAccessibility property.
     * 
     * @param value
     *     allowed object is
     *     {@link ApipAccessibilityType }
     *     
     */
    public void setApipAccessibility(ApipAccessibilityType value) {
        this.apipAccessibility = value;
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
     * Gets the value of the language property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getLanguage() {
        return language;
    }

    /**
     * Sets the value of the language property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setLanguage(String value) {
        this.language = value;
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
     * Gets the value of the approvedVersion property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getApprovedVersion() {
        return approvedVersion;
    }

    /**
     * Sets the value of the approvedVersion property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setApprovedVersion(String value) {
        this.approvedVersion = value;
    }

}