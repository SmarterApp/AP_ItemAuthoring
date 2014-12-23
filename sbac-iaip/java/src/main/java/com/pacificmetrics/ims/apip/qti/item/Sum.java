//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package com.pacificmetrics.ims.apip.qti.item;

import java.util.ArrayList;
import java.util.List;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElementRef;
import javax.xml.bind.annotation.XmlElementRefs;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;


/**
 * 
 *                 Provides the ability to use a multi variable numeric-based operator e.g. a 'sum' of the set of variables.
 *             
 * 
 * <p>Java class for NumericLogic1toMany.Type complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="NumericLogic1toMany.Type">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;choice maxOccurs="unbounded">
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}sum"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}subtract"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}divide"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}multiple"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}ordered"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}customOperator"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}random"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}numberIncorrect"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}numberCorrect"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}numberPresented"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}numberResponded"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}numberSelected"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}null"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}delete"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}index"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}power"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}containerSize"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}correct"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}default"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}integerDivide"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}integerModulus"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}product"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}round"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}truncate"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}fieldValue"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}randomInteger"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}randomFloat"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}variable"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}outcomeMinimum"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}outcomeMaximum"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}testVariables"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}integerToFloat"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}baseValue"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}mapResponsePoint"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}mapResponse"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}repeat"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}roundTo"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}lcm"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}gcd"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}min"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}max"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}mathConstant"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}statsOperator"/>
 *           &lt;element ref="{http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2}mathOperator"/>
 *         &lt;/choice>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "NumericLogic1toMany.Type", propOrder = {
    "saAndSubtractsAndDivides"
})
@XmlRootElement(name = "sum")
public class Sum {

    @XmlElementRefs({
        @XmlElementRef(name = "numberSelected", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "testVariables", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = TestVariables.class, required = false),
        @XmlElementRef(name = "integerModulus", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "numberIncorrect", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "mapResponse", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "default", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Default.class, required = false),
        @XmlElementRef(name = "statsOperator", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = StatsOperator.class, required = false),
        @XmlElementRef(name = "null", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "gcd", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "multiple", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "roundTo", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = RoundTo.class, required = false),
        @XmlElementRef(name = "containerSize", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "subtract", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "sum", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Sum.class, required = false),
        @XmlElementRef(name = "correct", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Correct.class, required = false),
        @XmlElementRef(name = "randomFloat", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = RandomFloat.class, required = false),
        @XmlElementRef(name = "numberResponded", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "variable", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Variable.class, required = false),
        @XmlElementRef(name = "divide", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "delete", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "round", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "product", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "outcomeMaximum", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "numberPresented", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "random", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "customOperator", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = CustomOperator.class, required = false),
        @XmlElementRef(name = "mathConstant", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = MathConstant.class, required = false),
        @XmlElementRef(name = "integerToFloat", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "index", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Index.class, required = false),
        @XmlElementRef(name = "integerDivide", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "repeat", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = Repeat.class, required = false),
        @XmlElementRef(name = "lcm", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "numberCorrect", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "outcomeMinimum", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "ordered", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "baseValue", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = BaseValue.class, required = false),
        @XmlElementRef(name = "randomInteger", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = RandomInteger.class, required = false),
        @XmlElementRef(name = "truncate", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "max", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "mapResponsePoint", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "mathOperator", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = MathOperator.class, required = false),
        @XmlElementRef(name = "min", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "power", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = JAXBElement.class, required = false),
        @XmlElementRef(name = "fieldValue", namespace = "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p2", type = FieldValue.class, required = false)
    })
    protected List<java.lang.Object> saAndSubtractsAndDivides;

    /**
     * Gets the value of the saAndSubtractsAndDivides property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the saAndSubtractsAndDivides property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getSaAndSubtractsAndDivides().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link JAXBElement }{@code <}{@link NumberType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link TestVariables }
     * {@link JAXBElement }{@code <}{@link NumberType }{@code >}
     * {@link JAXBElement }{@code <}{@link MapResponseType }{@code >}
     * {@link Default }
     * {@link StatsOperator }
     * {@link JAXBElement }{@code <}{@link EmptyPrimitiveTypeType }{@code >}
     * {@link JAXBElement }{@code <}{@link Logic1ToManyType }{@code >}
     * {@link JAXBElement }{@code <}{@link Logic0ToManyType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicSingleType }{@code >}
     * {@link RoundTo }
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link Correct }
     * {@link Sum }
     * {@link RandomFloat }
     * {@link JAXBElement }{@code <}{@link NumberType }{@code >}
     * {@link Variable }
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicSingleType }{@code >}
     * {@link JAXBElement }{@code <}{@link Logic1ToManyType }{@code >}
     * {@link CustomOperator }
     * {@link JAXBElement }{@code <}{@link LogicSingleType }{@code >}
     * {@link JAXBElement }{@code <}{@link NumberType }{@code >}
     * {@link JAXBElement }{@code <}{@link OutcomeMinMaxType }{@code >}
     * {@link MathConstant }
     * {@link JAXBElement }{@code <}{@link LogicSingleType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link Index }
     * {@link Repeat }
     * {@link JAXBElement }{@code <}{@link Logic1ToManyType }{@code >}
     * {@link JAXBElement }{@code <}{@link NumberType }{@code >}
     * {@link JAXBElement }{@code <}{@link Logic0ToManyType }{@code >}
     * {@link JAXBElement }{@code <}{@link OutcomeMinMaxType }{@code >}
     * {@link JAXBElement }{@code <}{@link LogicSingleType }{@code >}
     * {@link RandomInteger }
     * {@link BaseValue }
     * {@link JAXBElement }{@code <}{@link Logic1ToManyType }{@code >}
     * {@link JAXBElement }{@code <}{@link MapResponseType }{@code >}
     * {@link MathOperator }
     * {@link JAXBElement }{@code <}{@link LogicPairType }{@code >}
     * {@link JAXBElement }{@code <}{@link Logic1ToManyType }{@code >}
     * {@link FieldValue }
     * 
     * 
     */
    public List<java.lang.Object> getSaAndSubtractsAndDivides() {
        if (saAndSubtractsAndDivides == null) {
            saAndSubtractsAndDivides = new ArrayList<java.lang.Object>();
        }
        return this.saAndSubtractsAndDivides;
    }

}
