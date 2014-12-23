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
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *     Define the samplelist type.
 *     Example responses that deserve certain item point values. 
 *     
 * 
 * <p>Java class for samplelistType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="samplelistType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="sample" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}sampleType" maxOccurs="unbounded" minOccurs="0"/>
 *       &lt;/sequence>
 *       &lt;attribute name="minval" use="required" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}positiveIntType" />
 *       &lt;attribute name="maxval" use="required" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}positiveIntType" />
 *       &lt;attribute name="index" type="{http://www.smarterapp.org/xsd/saaif/v1p0/passageitem_v1p0.xsd}positiveIntType" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "samplelistType", propOrder = {
    "sample"
})
public class SamplelistType {

    protected List<SampleType> sample;
    @XmlAttribute(name = "minval", required = true)
    protected int minval;
    @XmlAttribute(name = "maxval", required = true)
    protected int maxval;
    @XmlAttribute(name = "index")
    protected Integer index;

    /**
     * Gets the value of the sample property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the sample property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getSample().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link SampleType }
     * 
     * 
     */
    public List<SampleType> getSample() {
        if (sample == null) {
            sample = new ArrayList<SampleType>();
        }
        return this.sample;
    }

    /**
     * Gets the value of the minval property.
     * 
     */
    public int getMinval() {
        return minval;
    }

    /**
     * Sets the value of the minval property.
     * 
     */
    public void setMinval(int value) {
        this.minval = value;
    }

    /**
     * Gets the value of the maxval property.
     * 
     */
    public int getMaxval() {
        return maxval;
    }

    /**
     * Sets the value of the maxval property.
     * 
     */
    public void setMaxval(int value) {
        this.maxval = value;
    }

    /**
     * Gets the value of the index property.
     * 
     * @return
     *     possible object is
     *     {@link Integer }
     *     
     */
    public Integer getIndex() {
        return index;
    }

    /**
     * Sets the value of the index property.
     * 
     * @param value
     *     allowed object is
     *     {@link Integer }
     *     
     */
    public void setIndex(Integer value) {
        this.index = value;
    }

}
