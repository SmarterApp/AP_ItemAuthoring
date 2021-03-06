//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti.item;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlID;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.NormalizedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;


/**
 * 
 *                 GraphicOrderInteraction is the complexType for graphic order QTI interactions. A graphic order interaction is a graphic interaction with a corresponding set of choices that are defined as areas of the graphic image. The candidate's task is to impose an ordering on the areas (hotspots). The order hotspot interaction should only be used when the spacial relationship of the choices with respect to each other (as represented by the graphic image) is important to the needs of the item.
 *             
 * 
 * <p>Java class for GraphicOrderInteraction.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="GraphicOrderInteraction.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}prompt" minOccurs="0"/>
 *         &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}object"/>
 *         &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}hotspotChoice" maxOccurs="unbounded"/>
 *       &lt;/sequence>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}xmlbase.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}class.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}minChoices.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}maxChoices.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}id.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}responseIdentifier.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}label.GraphicOrderInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}xmllang.GraphicOrderInteraction.Attr"/>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "GraphicOrderInteraction.Type", propOrder = {
    "prompt",
    "object",
    "hotspotChoices"
})
@XmlRootElement(name = "graphicOrderInteraction")
public class GraphicOrderInteraction {

    protected Prompt prompt;
    @XmlElement(required = true)
    protected Object object;
    @XmlElement(name = "hotspotChoice", required = true)
    protected List<HotspotChoice> hotspotChoices;
    @XmlAttribute(name = "base", namespace = "http://www.w3.org/XML/1998/namespace")
    @XmlSchemaType(name = "anyURI")
    protected String base;
    @XmlAttribute(name = "class")
    protected List<String> clazzs;
    @XmlAttribute(name = "minChoices")
    @XmlSchemaType(name = "nonNegativeInteger")
    protected BigInteger minChoices;
    @XmlAttribute(name = "maxChoices")
    @XmlSchemaType(name = "nonNegativeInteger")
    protected BigInteger maxChoices;
    @XmlAttribute(name = "id")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    @XmlID
    protected String id;
    @XmlAttribute(name = "responseIdentifier", required = true)
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String responseIdentifier;
    @XmlAttribute(name = "label")
    @XmlJavaTypeAdapter(NormalizedStringAdapter.class)
    @XmlSchemaType(name = "normalizedString")
    protected String label;
    @XmlAttribute(name = "lang", namespace = "http://www.w3.org/XML/1998/namespace")
    protected String lang;

    /**
     * Gets the value of the prompt property.
     * 
     * @return
     *     possible object is
     *     {@link Prompt }
     *     
     */
    public Prompt getPrompt() {
        return prompt;
    }

    /**
     * Sets the value of the prompt property.
     * 
     * @param value
     *     allowed object is
     *     {@link Prompt }
     *     
     */
    public void setPrompt(Prompt value) {
        this.prompt = value;
    }

    /**
     * Gets the value of the object property.
     * 
     * @return
     *     possible object is
     *     {@link Object }
     *     
     */
    public Object getObject() {
        return object;
    }

    /**
     * Sets the value of the object property.
     * 
     * @param value
     *     allowed object is
     *     {@link Object }
     *     
     */
    public void setObject(Object value) {
        this.object = value;
    }

    /**
     * Gets the value of the hotspotChoices property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the hotspotChoices property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getHotspotChoices().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link HotspotChoice }
     * 
     * 
     */
    public List<HotspotChoice> getHotspotChoices() {
        if (hotspotChoices == null) {
            hotspotChoices = new ArrayList<HotspotChoice>();
        }
        return this.hotspotChoices;
    }

    /**
     * Gets the value of the base property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getBase() {
        return base;
    }

    /**
     * Sets the value of the base property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setBase(String value) {
        this.base = value;
    }

    /**
     * Gets the value of the clazzs property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the clazzs property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getClazzs().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link String }
     * 
     * 
     */
    public List<String> getClazzs() {
        if (clazzs == null) {
            clazzs = new ArrayList<String>();
        }
        return this.clazzs;
    }

    /**
     * Gets the value of the minChoices property.
     * 
     * @return
     *     possible object is
     *     {@link BigInteger }
     *     
     */
    public BigInteger getMinChoices() {
        return minChoices;
    }

    /**
     * Sets the value of the minChoices property.
     * 
     * @param value
     *     allowed object is
     *     {@link BigInteger }
     *     
     */
    public void setMinChoices(BigInteger value) {
        this.minChoices = value;
    }

    /**
     * Gets the value of the maxChoices property.
     * 
     * @return
     *     possible object is
     *     {@link BigInteger }
     *     
     */
    public BigInteger getMaxChoices() {
        return maxChoices;
    }

    /**
     * Sets the value of the maxChoices property.
     * 
     * @param value
     *     allowed object is
     *     {@link BigInteger }
     *     
     */
    public void setMaxChoices(BigInteger value) {
        this.maxChoices = value;
    }

    /**
     * Gets the value of the id property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getId() {
        return id;
    }

    /**
     * Sets the value of the id property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setId(String value) {
        this.id = value;
    }

    /**
     * Gets the value of the responseIdentifier property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getResponseIdentifier() {
        return responseIdentifier;
    }

    /**
     * Sets the value of the responseIdentifier property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setResponseIdentifier(String value) {
        this.responseIdentifier = value;
    }

    /**
     * Gets the value of the label property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getLabel() {
        return label;
    }

    /**
     * Sets the value of the label property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setLabel(String value) {
        this.label = value;
    }

    /**
     * Gets the value of the lang property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getLang() {
        return lang;
    }

    /**
     * Sets the value of the lang property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setLang(String value) {
        this.lang = value;
    }

}
