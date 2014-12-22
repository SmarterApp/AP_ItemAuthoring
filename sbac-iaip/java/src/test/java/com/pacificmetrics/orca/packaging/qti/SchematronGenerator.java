/**
 * 
 */
package com.pacificmetrics.orca.packaging.qti;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.junit.Test;

/**
 * @author maumock
 * 
 */
public class SchematronGenerator {
    private static final String SCHEMATRON = "src/test/resources/schematron/iso/";

    @SuppressWarnings("static-method")
    @Test
    public void createSchematronXSLTForAPIPItems() throws TransformerException, IOException{
        String st=convert(new File("src/test/resources/schematron/apipItemSchematronRules.xsd"),SCHEMATRON+"ExtractSchFromXSD.xsl");
        st=convert(st,SCHEMATRON+"iso_dsdl_include.xsl");
        st=convert(st,SCHEMATRON+"iso_abstract_expand.xsl");
        st=convert(st,SCHEMATRON+"iso_svrl_for_xslt1.xsl");
        FileWriter out=new FileWriter("src/main/resources/xslt/apip/itemSchematron.xsl");
        out.write(st);
        out.close();
        
        st=convert(new File("src/test/resources/apipPkgs/cde_resources/devcdesbac/VE-IP-05.xml"),"src/main/resources/xslt/apip/itemSchematron.xsl");
    }

    private static String convert(String xml, String xsl) throws TransformerException {
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        TransformerFactory tFactory = TransformerFactory.newInstance();
        Transformer transformer = tFactory.newTransformer(new StreamSource(xsl));
        transformer.transform(new StreamSource(new ByteArrayInputStream(xml.getBytes())), new StreamResult(os));
        return new String(os.toByteArray());
    }

    private static String convert(File xml, String xsl) throws TransformerException {
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        TransformerFactory tFactory = TransformerFactory.newInstance();
        Transformer transformer = tFactory.newTransformer(new StreamSource(xsl));
        transformer.transform(new StreamSource(xml), new StreamResult(os));
        return new String(os.toByteArray());
    }
}
