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
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;
import org.w3c.dom.Element;


/**
 * 
 *     Define the itemcontent type.
 *     Content of an assessment item.
 *     
 * 
 * <p>Java class for itemcontentType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="itemcontentType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="qti" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}qtiType" minOccurs="0"/>
 *         &lt;element name="concept" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}opencontentType" minOccurs="0"/>
 *         &lt;element name="es" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}opencontentType" minOccurs="0"/>
 *         &lt;element name="himi" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}opencontentType" minOccurs="0"/>
 *         &lt;element name="rationaleoptlist" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}rationaleoptlistType" minOccurs="0"/>
 *         &lt;element name="illustration" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}illustrationType" minOccurs="0"/>
 *         &lt;element name="stem" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}stemType"/>
 *         &lt;element name="rubriclist" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}rubriclistType" minOccurs="0"/>
 *         &lt;element name="optionlist" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}optionlistType" minOccurs="0"/>
 *         &lt;element name="attachmentlist" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}attachmentlistType" minOccurs="0"/>
 *         &lt;element name="apipAccessibility" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}apipAccessibilityType" minOccurs="0"/>
 *         &lt;any processContents='lax' namespace='##other' maxOccurs="unbounded" minOccurs="0"/>
 *       &lt;/sequence>
 *       &lt;attGroup ref="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}contentAttr"/>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "itemcontentType", propOrder = {
    "qti",
    "concept",
    "es",
    "himi",
    "rationaleoptlist",
    "illustration",
    "stem",
    "rubriclist",
    "optionlist",
    "attachmentlist",
    "apipAccessibility",
    "any"
})
public class ItemcontentType {

    protected QtiType qti;
    protected OpencontentType concept;
    protected OpencontentType es;
    protected OpencontentType himi;
    protected RationaleoptlistType rationaleoptlist;
    protected IllustrationType illustration;
    @XmlElement(required = true)
    protected StemType stem;
    protected RubriclistType rubriclist;
    protected OptionlistType optionlist;
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
    @XmlAttribute(name = "format")
    protected ItemFormatType format;
    @XmlAttribute(name = "approvedVersion")
    protected String approvedVersion;

    /**
     * Gets the value of the qti property.
     * 
     * @return
     *     possible object is
     *     {@link QtiType }
     *     
     */
    public QtiType getQti() {
        return qti;
    }

    /**
     * Sets the value of the qti property.
     * 
     * @param value
     *     allowed object is
     *     {@link QtiType }
     *     
     */
    public void setQti(QtiType value) {
        this.qti = value;
    }

    /**
     * Gets the value of the concept property.
     * 
     * @return
     *     possible object is
     *     {@link OpencontentType }
     *     
     */
    public OpencontentType getConcept() {
        return concept;
    }

    /**
     * Sets the value of the concept property.
     * 
     * @param value
     *     allowed object is
     *     {@link OpencontentType }
     *     
     */
    public void setConcept(OpencontentType value) {
        this.concept = value;
    }

    /**
     * Gets the value of the es property.
     * 
     * @return
     *     possible object is
     *     {@link OpencontentType }
     *     
     */
    public OpencontentType getEs() {
        return es;
    }

    /**
     * Sets the value of the es property.
     * 
     * @param value
     *     allowed object is
     *     {@link OpencontentType }
     *     
     */
    public void setEs(OpencontentType value) {
        this.es = value;
    }

    /**
     * Gets the value of the himi property.
     * 
     * @return
     *     possible object is
     *     {@link OpencontentType }
     *     
     */
    public OpencontentType getHimi() {
        return himi;
    }

    /**
     * Sets the value of the himi property.
     * 
     * @param value
     *     allowed object is
     *     {@link OpencontentType }
     *     
     */
    public void setHimi(OpencontentType value) {
        this.himi = value;
    }

    /**
     * Gets the value of the rationaleoptlist property.
     * 
     * @return
     *     possible object is
     *     {@link RationaleoptlistType }
     *     
     */
    public RationaleoptlistType getRationaleoptlist() {
        return rationaleoptlist;
    }

    /**
     * Sets the value of the rationaleoptlist property.
     * 
     * @param value
     *     allowed object is
     *     {@link RationaleoptlistType }
     *     
     */
    public void setRationaleoptlist(RationaleoptlistType value) {
        this.rationaleoptlist = value;
    }

    /**
     * Gets the value of the illustration property.
     * 
     * @return
     *     possible object is
     *     {@link IllustrationType }
     *     
     */
    public IllustrationType getIllustration() {
        return illustration;
    }

    /**
     * Sets the value of the illustration property.
     * 
     * @param value
     *     allowed object is
     *     {@link IllustrationType }
     *     
     */
    public void setIllustration(IllustrationType value) {
        this.illustration = value;
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
     * Gets the value of the rubriclist property.
     * 
     * @return
     *     possible object is
     *     {@link RubriclistType }
     *     
     */
    public RubriclistType getRubriclist() {
        return rubriclist;
    }

    /**
     * Sets the value of the rubriclist property.
     * 
     * @param value
     *     allowed object is
     *     {@link RubriclistType }
     *     
     */
    public void setRubriclist(RubriclistType value) {
        this.rubriclist = value;
    }

    /**
     * Gets the value of the optionlist property.
     * 
     * @return
     *     possible object is
     *     {@link OptionlistType }
     *     
     */
    public OptionlistType getOptionlist() {
        return optionlist;
    }

    /**
     * Sets the value of the optionlist property.
     * 
     * @param value
     *     allowed object is
     *     {@link OptionlistType }
     *     
     */
    public void setOptionlist(OptionlistType value) {
        this.optionlist = value;
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
     * Gets the value of the format property.
     * 
     * @return
     *     possible object is
     *     {@link ItemFormatType }
     *     
     */
    public ItemFormatType getFormat() {
        return format;
    }

    /**
     * Sets the value of the format property.
     * 
     * @param value
     *     allowed object is
     *     {@link ItemFormatType }
     *     
     */
    public void setFormat(ItemFormatType value) {
        this.format = value;
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
