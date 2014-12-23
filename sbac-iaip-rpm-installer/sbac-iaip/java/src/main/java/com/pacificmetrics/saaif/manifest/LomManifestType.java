package com.pacificmetrics.saaif.manifest;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;

@XmlAccessorType(XmlAccessType.FIELD)
@XmlRootElement(name = "lom", namespace = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest")
@XmlType(name = "lomManifestType")
public class LomManifestType {
    @XmlAttribute(name = "xmlns")
    private String xmlns = "http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest";
}
