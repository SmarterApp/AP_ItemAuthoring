//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.06.25 at 12:09:14 PM IST 
//

package com.pacificmetrics.saaif.manifest;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;

/**
 * <p>
 * Java class for anonymous complex type.
 * 
 * <p>
 * The following schema fragment specifies the expected content contained within
 * this class.
 * 
 * <pre>
 * &lt;complexType>
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="metadata">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="schema" type="{http://www.w3.org/2001/XMLSchema}string"/>
 *                   &lt;element name="schemaversion" type="{http://www.w3.org/2001/XMLSchema}string"/>
 *                   &lt;element name="lom" type="{http://www.w3.org/2001/XMLSchema}string"/>
 *                 &lt;/sequence>
 *               &lt;/restriction>
 *             &lt;/complexContent>
 *           &lt;/complexType>
 *         &lt;/element>
 *         &lt;element name="organizations" type="{http://www.w3.org/2001/XMLSchema}anyType"/>
 *         &lt;element name="resources">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="resource" maxOccurs="unbounded">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="file">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;attribute name="href" type="{http://www.w3.org/2001/XMLSchema}string" />
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                             &lt;element name="dependency" maxOccurs="unbounded">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;attribute name="identifierref" type="{http://www.w3.org/2001/XMLSchema}string" />
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                           &lt;attribute name="identifier" type="{http://www.w3.org/2001/XMLSchema}string" />
 *                           &lt;attribute name="type" type="{http://www.w3.org/2001/XMLSchema}string" />
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                 &lt;/sequence>
 *               &lt;/restriction>
 *             &lt;/complexContent>
 *           &lt;/complexType>
 *         &lt;/element>
 *       &lt;/sequence>
 *       &lt;attribute name="identifier" type="{http://www.w3.org/2001/XMLSchema}string" />
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "", propOrder = { "metadata", "organizations", "resources" })
@XmlRootElement(name = "manifest")
public class Manifest {

    @XmlElement(required = true)
    protected Manifest.Metadata metadata;
    @XmlElement(required = true)
    protected String organizations = new String();
    @XmlElement(required = true)
    protected Manifest.Resources resources;
    @XmlAttribute(name = "identifier")
    protected String identifier;

    /**
     * Gets the value of the metadata property.
     * 
     * @return possible object is {@link Manifest.Metadata }
     * 
     */
    public Manifest.Metadata getMetadata() {
        return metadata;
    }

    /**
     * Sets the value of the metadata property.
     * 
     * @param value
     *            allowed object is {@link Manifest.Metadata }
     * 
     */
    public void setMetadata(Manifest.Metadata value) {
        this.metadata = value;
    }

    /**
     * Gets the value of the organizations property.
     * 
     * @return possible object is {@link Object }
     * 
     */
    public String getOrganizations() {
        return organizations;
    }

    /**
     * Sets the value of the organizations property.
     * 
     * @param value
     *            allowed object is {@link Object }
     * 
     */
    public void setOrganizations(String value) {
        this.organizations = value;
    }

    /**
     * Gets the value of the resources property.
     * 
     * @return possible object is {@link Manifest.Resources }
     * 
     */
    public Manifest.Resources getResources() {
        return resources;
    }

    /**
     * Sets the value of the resources property.
     * 
     * @param value
     *            allowed object is {@link Manifest.Resources }
     * 
     */
    public void setResources(Manifest.Resources value) {
        this.resources = value;
    }

    /**
     * Gets the value of the identifier property.
     * 
     * @return possible object is {@link String }
     * 
     */
    public String getIdentifier() {
        return identifier;
    }

    /**
     * Sets the value of the identifier property.
     * 
     * @param value
     *            allowed object is {@link String }
     * 
     */
    public void setIdentifier(String value) {
        this.identifier = value;
    }

    /**
     * <p>
     * Java class for anonymous complex type.
     * 
     * <p>
     * The following schema fragment specifies the expected content contained
     * within this class.
     * 
     * <pre>
     * &lt;complexType>
     *   &lt;complexContent>
     *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *       &lt;sequence>
     *         &lt;element name="schema" type="{http://www.w3.org/2001/XMLSchema}string"/>
     *         &lt;element name="schemaversion" type="{http://www.w3.org/2001/XMLSchema}string"/>
     *         &lt;element name="lom" type="{http://www.w3.org/2001/XMLSchema}string"/>
     *       &lt;/sequence>
     *     &lt;/restriction>
     *   &lt;/complexContent>
     * &lt;/complexType>
     * </pre>
     * 
     * 
     */
    @XmlAccessorType(XmlAccessType.FIELD)
    @XmlType(name = "", propOrder = { "schema", "schemaversion", "lom" })
    public static class Metadata {

        @XmlElement(required = true)
        protected String schema;
        @XmlElement(required = true)
        protected String schemaversion;
        @XmlElement(required = true)
        protected LomManifestType lom;

        /**
         * Gets the value of the schema property.
         * 
         * @return possible object is {@link String }
         * 
         */
        public String getSchema() {
            return schema;
        }

        /**
         * Sets the value of the schema property.
         * 
         * @param value
         *            allowed object is {@link String }
         * 
         */
        public void setSchema(String value) {
            this.schema = value;
        }

        /**
         * Gets the value of the schemaversion property.
         * 
         * @return possible object is {@link String }
         * 
         */
        public String getSchemaversion() {
            return schemaversion;
        }

        /**
         * Sets the value of the schemaversion property.
         * 
         * @param value
         *            allowed object is {@link String }
         * 
         */
        public void setSchemaversion(String value) {
            this.schemaversion = value;
        }

        /**
         * Gets the value of the lom property.
         * 
         * @return possible object is {@link String }
         * 
         */
        public LomManifestType getLom() {
            return lom;
        }

        /**
         * Sets the value of the lom property.
         * 
         * @param value
         *            allowed object is {@link String }
         * 
         */
        public void setLom(LomManifestType value) {
            this.lom = value;
        }

    }

    /**
     * <p>
     * Java class for anonymous complex type.
     * 
     * <p>
     * The following schema fragment specifies the expected content contained
     * within this class.
     * 
     * <pre>
     * &lt;complexType>
     *   &lt;complexContent>
     *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *       &lt;sequence>
     *         &lt;element name="resource" maxOccurs="unbounded">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="file">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;attribute name="href" type="{http://www.w3.org/2001/XMLSchema}string" />
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                   &lt;element name="dependency" maxOccurs="unbounded">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;attribute name="identifierref" type="{http://www.w3.org/2001/XMLSchema}string" />
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *                 &lt;attribute name="identifier" type="{http://www.w3.org/2001/XMLSchema}string" />
     *                 &lt;attribute name="type" type="{http://www.w3.org/2001/XMLSchema}string" />
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *       &lt;/sequence>
     *     &lt;/restriction>
     *   &lt;/complexContent>
     * &lt;/complexType>
     * </pre>
     * 
     * 
     */
    @XmlAccessorType(XmlAccessType.FIELD)
    @XmlType(name = "", propOrder = { "resource" })
    public static class Resources {

        @XmlElement(required = true)
        protected List<Manifest.Resources.Resource> resource;

        /**
         * Gets the value of the resource property.
         * 
         * <p>
         * This accessor method returns a reference to the live list, not a
         * snapshot. Therefore any modification you make to the returned list
         * will be present inside the JAXB object. This is why there is not a
         * <CODE>set</CODE> method for the resource property.
         * 
         * <p>
         * For example, to add a new item, do as follows:
         * 
         * <pre>
         * getResource().add(newItem);
         * </pre>
         * 
         * 
         * <p>
         * Objects of the following type(s) are allowed in the list
         * {@link Manifest.Resources.Resource }
         * 
         * 
         */
        public List<Manifest.Resources.Resource> getResource() {
            if (resource == null) {
                resource = new LinkedList<Manifest.Resources.Resource>();
            }
            return this.resource;
        }

        /**
         * <p>
         * Java class for anonymous complex type.
         * 
         * <p>
         * The following schema fragment specifies the expected content
         * contained within this class.
         * 
         * <pre>
         * &lt;complexType>
         *   &lt;complexContent>
         *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *       &lt;sequence>
         *         &lt;element name="file">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;attribute name="href" type="{http://www.w3.org/2001/XMLSchema}string" />
         *               &lt;/restriction>
         *             &lt;/complexContent>
         *           &lt;/complexType>
         *         &lt;/element>
         *         &lt;element name="dependency" maxOccurs="unbounded">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;attribute name="identifierref" type="{http://www.w3.org/2001/XMLSchema}string" />
         *               &lt;/restriction>
         *             &lt;/complexContent>
         *           &lt;/complexType>
         *         &lt;/element>
         *       &lt;/sequence>
         *       &lt;attribute name="identifier" type="{http://www.w3.org/2001/XMLSchema}string" />
         *       &lt;attribute name="type" type="{http://www.w3.org/2001/XMLSchema}string" />
         *     &lt;/restriction>
         *   &lt;/complexContent>
         * &lt;/complexType>
         * </pre>
         * 
         * 
         */
        @XmlAccessorType(XmlAccessType.FIELD)
        @XmlType(name = "", propOrder = { "file", "dependency" })
        public static class Resource {

            @XmlElement(required = true)
            protected Manifest.Resources.Resource.File file;
            @XmlElement(required = true)
            protected List<Manifest.Resources.Resource.Dependency> dependency;
            @XmlAttribute(name = "identifier")
            protected String identifier;
            @XmlAttribute(name = "type")
            protected String type;

            /**
             * Gets the value of the file property.
             * 
             * @return possible object is
             *         {@link Manifest.Resources.Resource.File }
             * 
             */
            public Manifest.Resources.Resource.File getFile() {
                return file;
            }

            /**
             * Sets the value of the file property.
             * 
             * @param value
             *            allowed object is
             *            {@link Manifest.Resources.Resource.File }
             * 
             */
            public void setFile(Manifest.Resources.Resource.File value) {
                this.file = value;
            }

            /**
             * Gets the value of the dependency property.
             * 
             * <p>
             * This accessor method returns a reference to the live list, not a
             * snapshot. Therefore any modification you make to the returned
             * list will be present inside the JAXB object. This is why there is
             * not a <CODE>set</CODE> method for the dependency property.
             * 
             * <p>
             * For example, to add a new item, do as follows:
             * 
             * <pre>
             * getDependency().add(newItem);
             * </pre>
             * 
             * 
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link Manifest.Resources.Resource.Dependency }
             * 
             * 
             */
            public List<Manifest.Resources.Resource.Dependency> getDependency() {
                if (dependency == null) {
                    dependency = new ArrayList<Manifest.Resources.Resource.Dependency>();
                }
                return this.dependency;
            }

            /**
             * Gets the value of the identifier property.
             * 
             * @return possible object is {@link String }
             * 
             */
            public String getIdentifier() {
                return identifier;
            }

            /**
             * Sets the value of the identifier property.
             * 
             * @param value
             *            allowed object is {@link String }
             * 
             */
            public void setIdentifier(String value) {
                this.identifier = value;
            }

            /**
             * Gets the value of the type property.
             * 
             * @return possible object is {@link String }
             * 
             */
            public String getType() {
                return type;
            }

            /**
             * Sets the value of the type property.
             * 
             * @param value
             *            allowed object is {@link String }
             * 
             */
            public void setType(String value) {
                this.type = value;
            }

            /**
             * <p>
             * Java class for anonymous complex type.
             * 
             * <p>
             * The following schema fragment specifies the expected content
             * contained within this class.
             * 
             * <pre>
             * &lt;complexType>
             *   &lt;complexContent>
             *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
             *       &lt;attribute name="identifierref" type="{http://www.w3.org/2001/XMLSchema}string" />
             *     &lt;/restriction>
             *   &lt;/complexContent>
             * &lt;/complexType>
             * </pre>
             * 
             * 
             */
            @XmlAccessorType(XmlAccessType.FIELD)
            @XmlType(name = "")
            public static class Dependency {

                @XmlAttribute(name = "identifierref")
                protected String identifierref;

                /**
                 * Gets the value of the identifierref property.
                 * 
                 * @return possible object is {@link String }
                 * 
                 */
                public String getIdentifierref() {
                    return identifierref;
                }

                /**
                 * Sets the value of the identifierref property.
                 * 
                 * @param value
                 *            allowed object is {@link String }
                 * 
                 */
                public void setIdentifierref(String value) {
                    this.identifierref = value;
                }

            }

            /**
             * <p>
             * Java class for anonymous complex type.
             * 
             * <p>
             * The following schema fragment specifies the expected content
             * contained within this class.
             * 
             * <pre>
             * &lt;complexType>
             *   &lt;complexContent>
             *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
             *       &lt;attribute name="href" type="{http://www.w3.org/2001/XMLSchema}string" />
             *     &lt;/restriction>
             *   &lt;/complexContent>
             * &lt;/complexType>
             * </pre>
             * 
             * 
             */
            @XmlAccessorType(XmlAccessType.FIELD)
            @XmlType(name = "")
            public static class File {

                @XmlAttribute(name = "href")
                protected String href;

                /**
                 * Gets the value of the href property.
                 * 
                 * @return possible object is {@link String }
                 * 
                 */
                public String getHref() {
                    return href;
                }

                /**
                 * Sets the value of the href property.
                 * 
                 * @param value
                 *            allowed object is {@link String }
                 * 
                 */
                public void setHref(String value) {
                    this.href = value;
                }

            }

        }

    }

}
