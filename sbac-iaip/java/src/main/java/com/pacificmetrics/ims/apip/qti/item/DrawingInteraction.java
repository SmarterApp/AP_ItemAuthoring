//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti.item;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;


/**
 * 
 *                 DrawingInteraction is the complexType for graphic gap match QTI interactions. The drawing interaction allows the candidate to use a common set of drawing tools to modify a given graphical image (the canvas). It must be bound to a response variable with base-type file and single cardinality. The result is a file in the same format as the original image.
 *             
 * 
 * <p>Java class for DrawingInteraction.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="DrawingInteraction.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}prompt" minOccurs="0"/>
 *         &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}object"/>
 *       &lt;/sequence>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}label.DrawingInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}responseIdentifier.DrawingInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}xmllang.DrawingInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}id.DrawingInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}xmlbase.DrawingInteraction.Attr"/>
 *       &lt;attGroup ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}class.DrawingInteraction.Attr"/>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "DrawingInteraction.Type", propOrder = {
    "prompt",
    "object"
})
@XmlRootElement(name = "drawingInteraction")
public class DrawingInteraction {

    protected Prompt prompt;
    @XmlElement(required = true)
    protected Object object;
    @XmlAttribute(name = "label")
    protected Double label;
    @XmlAttribute(name = "responseIdentifier", required = true)
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String responseIdentifier;
    @XmlAttribute(name = "lang", namespace = "http://www.w3.org/XML/1998/namespace")
    protected String lang;
    @XmlAttribute(name = "id")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String id;
    @XmlAttribute(name = "base", namespace = "http://www.w3.org/XML/1998/namespace")
    @XmlSchemaType(name = "anyURI")
    protected String base;
    @XmlAttribute(name = "class")
    protected List<String> clazzs;

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
     * Gets the value of the label property.
     * 
     * @return
     *     possible object is
     *     {@link Double }
     *     
     */
    public Double getLabel() {
        return label;
    }

    /**
     * Sets the value of the label property.
     * 
     * @param value
     *     allowed object is
     *     {@link Double }
     *     
     */
    public void setLabel(Double value) {
        this.label = value;
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

}
