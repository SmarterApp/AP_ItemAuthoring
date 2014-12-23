//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 The SignFile complexType is the container for the links to the external signing files. Signing is available as video or bone animation files.
 *             
 * 
 * <p>Java class for SignFile.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="SignFile.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="videoFileInfo" type="{http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0}VideoFileInfo.Type" minOccurs="0"/>
 *         &lt;element name="boneAnimationVideoFile" type="{http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0}ObjectFileInfo.Type" minOccurs="0"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "SignFile.Type", propOrder = {
    "videoFileInfo",
    "boneAnimationVideoFile"
})
public class SignFileType {

    protected VideoFileInfoType videoFileInfo;
    protected ObjectFileInfoType boneAnimationVideoFile;

    /**
     * Gets the value of the videoFileInfo property.
     * 
     * @return
     *     possible object is
     *     {@link VideoFileInfoType }
     *     
     */
    public VideoFileInfoType getVideoFileInfo() {
        return videoFileInfo;
    }

    /**
     * Sets the value of the videoFileInfo property.
     * 
     * @param value
     *     allowed object is
     *     {@link VideoFileInfoType }
     *     
     */
    public void setVideoFileInfo(VideoFileInfoType value) {
        this.videoFileInfo = value;
    }

    /**
     * Gets the value of the boneAnimationVideoFile property.
     * 
     * @return
     *     possible object is
     *     {@link ObjectFileInfoType }
     *     
     */
    public ObjectFileInfoType getBoneAnimationVideoFile() {
        return boneAnimationVideoFile;
    }

    /**
     * Sets the value of the boneAnimationVideoFile property.
     * 
     * @param value
     *     allowed object is
     *     {@link ObjectFileInfoType }
     *     
     */
    public void setBoneAnimationVideoFile(ObjectFileInfoType value) {
        this.boneAnimationVideoFile = value;
    }

}