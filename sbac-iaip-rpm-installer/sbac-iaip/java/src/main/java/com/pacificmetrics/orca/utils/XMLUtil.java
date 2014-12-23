package com.pacificmetrics.orca.utils;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.namespace.NamespaceContext;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.validation.SchemaFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Convenience methods for working with XML data. This class is not thread safe.
 * 
 * @author maumock
 * 
 */
public class XMLUtil {
	private static final Logger LOGGER = Logger.getLogger(XMLUtil.class
			.getName());
	private Document doc;
	private DocumentBuilder docBuilder;
	private XMLErrorHandler errorHandler = new XMLErrorHandler();
	private final XPathFactory factory = XPathFactory.newInstance();
	private final XPath path = this.factory.newXPath();
	private final NamespaceAware namespaceContext = new NamespaceAware(1, 1.0F);
	private final DocumentBuilderFactory dbFactory = DocumentBuilderFactory
			.newInstance();

	public XMLUtil() {
		this(true);
	}

	public XMLUtil(boolean namespaceAware) {
		this.dbFactory.setNamespaceAware(namespaceAware);
		this.path.setNamespaceContext(this.namespaceContext);
	}

	public void load(File xmlFile) throws ParserConfigurationException,
			SAXException, IOException {
		load(new FileInputStream(xmlFile));
	}

	public void load(String xmlString) throws ParserConfigurationException,
			SAXException, IOException {
		load(new ByteArrayInputStream(xmlString.getBytes("UTF-8")));
	}

	private void load(InputStream is) throws SAXException, IOException,
			ParserConfigurationException {
		this.errorHandler.reset();
		if (this.docBuilder == null) {
			this.docBuilder = this.dbFactory.newDocumentBuilder();
			this.docBuilder.setErrorHandler(this.errorHandler);
		}
		this.doc = this.docBuilder.parse(is);
		this.doc.getDocumentElement().normalize();
	}

	public void reset() {
		this.docBuilder.reset();
		this.errorHandler.reset();
	}

	public final void setSchema(String schema) throws SAXException {
		SchemaFactory schemaFactory = SchemaFactory.newInstance(schema);
		this.dbFactory.setValidating(false);
		this.dbFactory.setSchema(schemaFactory.newSchema());
	}

	public final void setSchema(String location, String xmlns) {
		this.dbFactory.setValidating(false);
		this.dbFactory.setAttribute(location, xmlns);
	}

	public final Node createElement(String targetName) {
		return this.doc.createElement(targetName);
	}

	public final Node createElement(String targetName,
			Map<String, String> attributes) {
		Node n = this.doc.createElement(targetName);
		for (String key : attributes.keySet()) {
			Node a = this.doc.createAttribute(key);
			a.setNodeValue(attributes.get(key));
			n.appendChild(a);
		}
		return n;
	}

	public static void print(Node node, OutputStream out)
			throws UnsupportedEncodingException, TransformerException {
		TransformerFactory tf = TransformerFactory.newInstance();
		Transformer transformer = tf.newTransformer();
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
		transformer.setOutputProperty(OutputKeys.METHOD, "xml");
		transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
		transformer.setOutputProperty(
				"{http://xml.apache.org/xslt}indent-amount", "2");

		transformer.transform(new DOMSource(node), new StreamResult(
				new OutputStreamWriter(out, "UTF-8")));
	}

	public void print(OutputStream out) throws IOException,
			TransformerException {
		TransformerFactory tf = TransformerFactory.newInstance();
		Transformer transformer = tf.newTransformer();
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
		transformer.setOutputProperty(OutputKeys.METHOD, "xml");
		transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
		transformer.setOutputProperty(
				"{http://xml.apache.org/xslt}indent-amount", "2");

		transformer.transform(new DOMSource(this.doc), new StreamResult(
				new OutputStreamWriter(out, "UTF-8")));
	}

	public static final String getValue(Node node) {
		if (node.getNodeValue() != null) {
			return node.getNodeValue();
		}
		if (node.hasChildNodes()) {
			return node.getChildNodes().item(0).getNodeValue();
		}
		return null;
	}

	public String getValue(String xpath) throws XPathExpressionException {
		Object result = this.path
				.evaluate(xpath, this.doc, XPathConstants.NODE);
		if (result == null) {
			return null;
		}
		return ((Node) result).getNodeValue();
	}

	public String[] getValues(String xpath) throws XPathExpressionException {
		Object result = this.path.evaluate(xpath, this.doc,
				XPathConstants.NODESET);
		NodeList nodes = (NodeList) result;
		String[] out = new String[nodes.getLength()];
		for (int i = 0; i < out.length; i++) {
			out[i] = nodes.item(i).getNodeValue();
		}
		return out;
	}

	public NodeList getNodes(String xpath) throws XPathExpressionException {
		return (NodeList) this.path.evaluate(xpath, this.doc,
				XPathConstants.NODESET);
	}

	public NodeList getNodes(String xpath, Node node)
			throws XPathExpressionException {
		return (NodeList) this.path.evaluate(xpath, node,
				XPathConstants.NODESET);
	}

	public Map<String, String> getAllNamespaces() {
		final Map<String, String> names = new HashMap<String, String>(1, 1.0F);
		getNamespaces(this.doc.getDocumentElement(), names);
		return names;
	}

	public void addXPathNS(String prefix, String namespace) {
		this.namespaceContext.put(prefix, namespace);
	}

	public static void getNamespaces(Node node, Map<String, String> list) {
		NamedNodeMap atts = node.getAttributes();
		for (int i = 0; i < atts.getLength(); i++) {
			Node n = atts.item(i);
			if ("xmlns".equals(n.getNodeName())) {
				list.put(n.getNodeName(), n.getNodeValue());
			} else {
				if (n.getNodeName().startsWith("xmlns:")) {
					list.put(n.getNodeName().substring(6), n.getNodeValue());
				}
			}
		}
	}

	/**
	 * This method is used to marshal given XML bean to get string
	 * representation of XML document
	 * 
	 * @param xml
	 *            XML Bean instance to marshal
	 * @return String representation of the XML document
	 * @throws JAXBException
	 */
	public static <T> String marshal(JAXBElement<T> xml) throws JAXBException {
		JAXBContext context = JAXBContext
				.newInstance(xml.getValue().getClass());
		Marshaller marshaller = context.createMarshaller();
		StringWriter sw = new StringWriter();
		marshaller.marshal(xml, sw);
		return sw.toString();
	}

	/**
	 * @return the errorHandler
	 */
	public XMLErrorHandler getErrorHandler() {
		return this.errorHandler;
	}

	/**
	 * @param errorHandler
	 *            the errorHandler to set
	 */
	public void setErrorHandler(XMLErrorHandler errorHandler) {
		this.errorHandler = errorHandler;
	}

	public class NamespaceAware extends HashMap<String, String> implements
			NamespaceContext {
		/**
         * 
         */
		private static final long serialVersionUID = -7564472416528508184L;

		/**
         * 
         */
		public NamespaceAware() {
			super();
		}

		/**
		 * @param arg0
		 * @param arg1
		 */
		public NamespaceAware(int arg0, float arg1) {
			super(arg0, arg1);
		}

		/**
		 * @param arg0
		 */
		public NamespaceAware(int arg0) {
			super(arg0);
		}

		/**
		 * @param arg0
		 */
		public NamespaceAware(Map<? extends String, ? extends String> arg0) {
			super(arg0);
		}

		@Override
		public String getNamespaceURI(String prefix) {
			return get(prefix);
		}

		@Override
		public String getPrefix(String namespaceURI) {
			return null;
		}

		@Override
		public Iterator<?> getPrefixes(String namespaceURI) {
			return null;
		}

	}

	public class XMLErrorHandler implements ErrorHandler {
		private final List<SAXException> errors = new ArrayList<SAXException>();
		private final List<SAXException> warnings = new ArrayList<SAXException>();
		private final List<SAXException> fatal = new ArrayList<SAXException>();

		public boolean hasException() {
			return (this.errors.size() + this.warnings.size() + this.fatal
					.size()) > 0;
		}

		public boolean hasError() {
			return (this.errors.size() + this.fatal.size()) > 0;
		}

		public List<SAXException> getErrors() {
			return this.errors;
		}

		public List<SAXException> getWarnings() {
			return this.warnings;
		}

		public List<SAXException> getFatal() {
			return this.fatal;
		}

		public void reset() {
			this.errors.clear();
			this.warnings.clear();
			this.fatal.clear();
		}

		@Override
		public void error(SAXParseException exception) throws SAXException {
			XMLUtil.LOGGER.log(Level.ALL, exception.getMessage());
			this.errors.add(exception);
		}

		@Override
		public void fatalError(SAXParseException exception) throws SAXException {
			XMLUtil.LOGGER.log(Level.ALL, exception.getMessage());
			this.fatal.add(exception);
		}

		@Override
		public void warning(SAXParseException exception) throws SAXException {
			XMLUtil.LOGGER.log(Level.ALL, exception.getMessage());
			this.warnings.add(exception);
		}

	}

	public Document getDoc() {
		return doc;
	}
}
