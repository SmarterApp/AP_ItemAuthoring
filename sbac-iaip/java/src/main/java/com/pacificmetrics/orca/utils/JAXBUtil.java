package com.pacificmetrics.orca.utils;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.PropertyException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class JAXBUtil {

    private static final Log LOGGER = LogFactory.getLog(JAXBUtil.class);

    private JAXBUtil() {
    }

    public static <T> String mershall(T object, Class<T> jaxbClass) {
        try {
            StringWriter stringWriter = new StringWriter();
            JAXBContext context = JAXBContext.newInstance(jaxbClass);
            Marshaller m = context.createMarshaller();
            m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
            m.marshal(object, stringWriter);
            return stringWriter.toString();
        } catch (JAXBException e) {
            LOGGER.error(
                    "Unable to mershal object of class " + jaxbClass.getName(),
                    e);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to mershal object of class " + jaxbClass.getName(),
                    e);
        }
        return null;
    }

    public static <T> String mershallSBAIF(T object, Class<T> jaxbClass) {
        StringWriter stringWriter = null;
        Marshaller m = null;
        try {
            stringWriter = new StringWriter();
            JAXBContext context = JAXBContext.newInstance(jaxbClass);
            m = context.createMarshaller();

            m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
            m.setProperty(Marshaller.JAXB_ENCODING, "UTF-8");
            setMarshalProperty(m);

            m.marshal(object, stringWriter);
            return stringWriter.toString();
        } catch (JAXBException e) {
            LOGGER.error(
                    "Unable to mershal object of class " + jaxbClass.getName()
                            + ", " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to mershal object of class " + jaxbClass.getName()
                            + ", " + e.getMessage(), e);
        } finally {
            try {
                stringWriter.close();
            } catch (IOException io) { /* ignore */
                LOGGER.error("Unable to close stringWriter " + io.getMessage(),
                        io);
            }
        }
        return null;
    }

    public static void setMarshalProperty(Marshaller m) {
        try {
            m.setProperty("com.sun.xml.internal.bind.characterEscapeHandler",
                    new CharacterEscape());
        } catch (Exception e) {
            LOGGER.error(e.getMessage(), e);
            try {
                m.setProperty("com.sun.xml.bind.characterEscapeHandler",
                        new CharacterEscape());
            } catch (PropertyException e1) {
                LOGGER.error(e1.getMessage(), e1);
            }
        }
    }

    public static <T> String mershall(T object, Class<?>... jaxbClasses) {
        try {
            StringWriter stringWriter = new StringWriter();
            JAXBContext context = JAXBContext.newInstance(jaxbClasses);
            Marshaller m = context.createMarshaller();
            m.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
            m.marshal(object, stringWriter);
            return stringWriter.toString();
        } catch (JAXBException e) {
            LOGGER.error("Unable to mershal object of class " + jaxbClasses, e);
        } catch (Exception e) {
            LOGGER.error("Unable to mershal object of class " + jaxbClasses, e);
        }
        return null;
    }

    public static <T> T unmershall(String xmlContent, Class<T> jaxbClass) {
        try {
            JAXBContext context = JAXBContext.newInstance(jaxbClass);
            StringReader reader = new StringReader(xmlContent);
            Object object = context.createUnmarshaller().unmarshal(reader);
            if (object instanceof JAXBElement<?>) {
                JAXBElement<T> jaxbElement = (JAXBElement<T>) object;
                return jaxbElement.getValue();
            }
            return (T) object;
        } catch (JAXBException e) {
            LOGGER.error(
                    "Unable to unmershal to object of class "
                            + jaxbClass.getName(), e);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to unmershal to object of class "
                            + jaxbClass.getName(), e);
        }
        return null;
    }

    public static <T> T unmershall(String xmlContent, Class<?>... jaxbClasses) {
        try {
            JAXBContext context = JAXBContext.newInstance(jaxbClasses);
            StringReader reader = new StringReader(xmlContent);
            Object object = context.createUnmarshaller().unmarshal(reader);
            if (object instanceof JAXBElement<?>) {
                JAXBElement<T> jaxbElement = (JAXBElement<T>) object;
                return jaxbElement.getValue();
            }
            return (T) object;
        } catch (JAXBException e) {
            LOGGER.error("Unable to unmershal to object of classes "
                    + jaxbClasses, e);
        } catch (Exception e) {
            LOGGER.error("Unable to unmershal to object of classes "
                    + jaxbClasses, e);
        }
        return null;
    }

}
