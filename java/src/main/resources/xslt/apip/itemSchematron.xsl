<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:sch="http://www.ascc.net/xml/schematron" 
xmlns:qti="http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1" xmlns:apip="http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0" version="1.0">
<!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
<xsl:param name="archiveDirParameter"/>
<xsl:param name="archiveNameParameter"/>
<xsl:param name="fileNameParameter"/>
<xsl:param name="fileDirParameter"/>

<!--PHASES-->


<!--PROLOG-->
<xsl:output xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" method="xml" omit-xml-declaration="no" standalone="yes" indent="yes"/>

<!--KEYS-->


<!--DEFAULT RULES-->


<!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-select-full-path">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:template>

<!--MODE: SCHEMATRON-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-get-full-path">
<xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
<xsl:text>/</xsl:text>
<xsl:choose>
<xsl:when test="namespace-uri()=''">
<xsl:value-of select="name()"/>
<xsl:variable name="p_1" select="1+    count(preceding-sibling::*[name()=name(current())])"/>
<xsl:if test="$p_1&gt;1 or following-sibling::*[name()=name(current())]">[<xsl:value-of select="$p_1"/>]</xsl:if>
</xsl:when>
<xsl:otherwise>
<xsl:text>*[local-name()='</xsl:text>
<xsl:value-of select="local-name()"/>
<xsl:text>' and namespace-uri()='</xsl:text>
<xsl:value-of select="namespace-uri()"/>
<xsl:text>']</xsl:text>
<xsl:variable name="p_2" select="1+   count(preceding-sibling::*[local-name()=local-name(current())])"/>
<xsl:if test="$p_2&gt;1 or following-sibling::*[local-name()=local-name(current())]">[<xsl:value-of select="$p_2"/>]</xsl:if>
</xsl:otherwise>
</xsl:choose>
</xsl:template>
<xsl:template match="@*" mode="schematron-get-full-path">
<xsl:text>/</xsl:text>
<xsl:choose>
<xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
</xsl:when>
<xsl:otherwise>
<xsl:text>@*[local-name()='</xsl:text>
<xsl:value-of select="local-name()"/>
<xsl:text>' and namespace-uri()='</xsl:text>
<xsl:value-of select="namespace-uri()"/>
<xsl:text>']</xsl:text>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<!--MODE: SCHEMATRON-FULL-PATH-2-->
<!--This mode can be used to generate prefixed XPath for humans-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-2">
<xsl:for-each select="ancestor-or-self::*">
<xsl:text>/</xsl:text>
<xsl:value-of select="name(.)"/>
<xsl:if test="preceding-sibling::*[name(.)=name(current())]">
<xsl:text>[</xsl:text>
<xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
<xsl:text>]</xsl:text>
</xsl:if>
</xsl:for-each>
<xsl:if test="not(self::*)">
<xsl:text/>/@<xsl:value-of select="name(.)"/>
</xsl:if>
</xsl:template>

<!--MODE: GENERATE-ID-FROM-PATH -->
<xsl:template match="/" mode="generate-id-from-path"/>
<xsl:template match="text()" mode="generate-id-from-path">
<xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
<xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
</xsl:template>
<xsl:template match="comment()" mode="generate-id-from-path">
<xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
<xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
</xsl:template>
<xsl:template match="processing-instruction()" mode="generate-id-from-path">
<xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
<xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
</xsl:template>
<xsl:template match="@*" mode="generate-id-from-path">
<xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
<xsl:value-of select="concat('.@', name())"/>
</xsl:template>
<xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
<xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
<xsl:text>.</xsl:text>
<xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
</xsl:template>
<!--MODE: SCHEMATRON-FULL-PATH-3-->
<!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-3">
<xsl:for-each select="ancestor-or-self::*">
<xsl:text>/</xsl:text>
<xsl:value-of select="name(.)"/>
<xsl:if test="parent::*">
<xsl:text>[</xsl:text>
<xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
<xsl:text>]</xsl:text>
</xsl:if>
</xsl:for-each>
<xsl:if test="not(self::*)">
<xsl:text/>/@<xsl:value-of select="name(.)"/>
</xsl:if>
</xsl:template>

<!--MODE: GENERATE-ID-2 -->
<xsl:template match="/" mode="generate-id-2">U</xsl:template>
<xsl:template match="*" mode="generate-id-2" priority="2">
<xsl:text>U</xsl:text>
<xsl:number level="multiple" count="*"/>
</xsl:template>
<xsl:template match="node()" mode="generate-id-2">
<xsl:text>U.</xsl:text>
<xsl:number level="multiple" count="*"/>
<xsl:text>n</xsl:text>
<xsl:number count="node()"/>
</xsl:template>
<xsl:template match="@*" mode="generate-id-2">
<xsl:text>U.</xsl:text>
<xsl:number level="multiple" count="*"/>
<xsl:text>_</xsl:text>
<xsl:value-of select="string-length(local-name(.))"/>
<xsl:text>_</xsl:text>
<xsl:value-of select="translate(name(),':','.')"/>
</xsl:template>
<!--Strip characters-->
<xsl:template match="text()" priority="-1"/>

<!--SCHEMA METADATA-->
<xsl:template match="/">
<svrl:schematron-output xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" title="Schematron validation rules for the enforcement of the Unordered stereotype." schemaVersion="">
<xsl:comment>
<xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
</xsl:comment>
<svrl:ns-prefix-in-attribute-values uri="http://www.imsglobal.org/xsd/imsqti_v2p1" prefix="qti"/>
<svrl:ns-prefix-in-attribute-values uri="http://www.imsglobal.org/xsd/apip/apipv1p0/imsapip_qtiv1p0" prefix="apip"/>
<svrl:active-pattern>
<xsl:attribute name="name">Ensure that certain expressions are NOT used for Response Processing.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M4"/>
<svrl:active-pattern>
<xsl:attribute name="name">Ensure that the Item, Section, Test and TestPart identifiers are unique.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M5"/>
<svrl:active-pattern>
<xsl:attribute name="name">Ensure that AssessmentItem Response Declarations are correct.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M6"/>
<svrl:active-pattern>
<xsl:attribute name="name">Enforce the correct use the TextEntryInteraction attributes.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M7"/>
<svrl:active-pattern>
<xsl:attribute name="id">CompanionMaterialsInfo.Type</xsl:attribute>
<xsl:attribute name="name">[RULESET] For the CompanionMaterialsInfo.Type complexType.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M8"/>
<svrl:active-pattern>
<xsl:attribute name="id">InclusionOrder.Type</xsl:attribute>
<xsl:attribute name="name">[RULESET] For the InclusionOrder.Type complexType.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M9"/>
<svrl:active-pattern>
<xsl:attribute name="id">RelatedElementInfo.Type</xsl:attribute>
<xsl:attribute name="name">[RULESET] For the RelatedElementInfo.Type complexType.</xsl:attribute>
<xsl:apply-templates/>
</svrl:active-pattern>
<xsl:apply-templates select="/" mode="M10"/>
</svrl:schematron-output>
</xsl:template>

<!--SCHEMATRON PATTERNS-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Schematron Validation Rules for QTI Specification v2.1.</svrl:text>
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Schematron validation rules for the enforcement of the Unordered stereotype.</svrl:text>

<!--PATTERN Ensure that certain expressions are NOT used for Response Processing.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Ensure that certain expressions are NOT used for Response Processing.</svrl:text>

	<!--RULE -->
<xsl:template match="//qti:assessmentItem/qti:responseProcessing" priority="1000" mode="M4">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//qti:assessmentItem/qti:responseProcessing"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:numberPresented) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:numberPresented) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 3] The expression numberPresented must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:numberResponded) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:numberResponded) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 4] The expression numberResponded must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:numberSelected) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:numberSelected) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 5] The expression numberSelected must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:numberCorrect) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:numberCorrect) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 1] The expression numberCorrect must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:numberIncorrect) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:numberIncorrect) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 2] The expression numberIncorrect must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:outcomeMinimum) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:outcomeMinimum) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 6] The expression outcomeMinimum must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:outcomeMaximum) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:outcomeMaximum) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 7] The expression outcomeMaximum must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(descendant::qti:testVariables) = 0"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::qti:testVariables) = 0">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 1a:Assertion 8] The expression testVariables must NOT be used in Response Processing.
                        <xsl:text/>
<xsl:value-of select="concat('The Assessment Item identifier is:', ../@identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M4"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M4"/>
<xsl:template match="@*|node()" priority="-2" mode="M4">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M4"/>
</xsl:template>

<!--PATTERN Ensure that the Item, Section, Test and TestPart identifiers are unique.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Ensure that the Item, Section, Test and TestPart identifiers are unique.</svrl:text>

	<!--RULE -->
<xsl:template match="//qti:assessmentTest" priority="1002" mode="M5">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//qti:assessmentTest"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:testPart/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:testPart/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2a:Assertion 1] The AssessmentTest and a TestPart must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentTest identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2a:Assertion 2] The AssessmentTest and an AssessmentSection must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentTest identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:testPart/qti:assessmentSectionRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:testPart/qti:assessmentSectionRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2a:Assertion 3] The AssessmentTest and a direct child AssessmentSectionRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentTest identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/qti:assessmentSectionRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/qti:assessmentSectionRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2a:Assertion 4] The AssessmentTest and a descendant AssessmentSectionRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentTest identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/qti:assessmentItemRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:testPart/descendant::qti:assessmentSection/qti:assessmentItemRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2a:Assertion 5] The AssessmentTest and a descendant AssessmentItemRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentTest identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/>
</xsl:template>

	<!--RULE -->
<xsl:template match="//qti:assessmentTest/qti:testPart" priority="1001" mode="M5">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//qti:assessmentTest/qti:testPart"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentSection/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentSection/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2b:Assertion 2] The TestPart and an AssessmentSection must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=qti:assessmentSectionRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=qti:assessmentSectionRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2b:Assertion 3] The TestPart and a direct child AssessmentSectionRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentSection/qti:assessmentSectionRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentSection/qti:assessmentSectionRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2b:Assertion 4] The TestPart and a descendant AssessmentSectionRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentSection/qti:assessmentItemRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentSection/qti:assessmentItemRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2b:Assertion 5] The TestPart and a descendant AssessmentItemRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=preceding-sibling::qti:testPart/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=preceding-sibling::qti:testPart/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2b:Assertion 1] Two TestParts must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/>
</xsl:template>

	<!--RULE -->
<xsl:template match="//qti:assessmentTest/qti:testPart/qti:assessmentSection" priority="1000" mode="M5">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//qti:assessmentTest/qti:testPart/qti:assessmentSection"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentSection/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentSection/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2c:Assertion 2] The AssessmentSection and a descendant AssessmentSection must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentSection identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentSectionRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentSectionRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2c:Assertion 3] The AssessmentSection and a descendant AssessmentSectionRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=descendant::qti:assessmentItemRef/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=descendant::qti:assessmentItemRef/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2c:Assertion 4] The AssessmentSection and a descendant AssessmentItemRef must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The TestPart identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@identifier=preceding-sibling::qti:assessmentSection/@identifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@identifier=preceding-sibling::qti:assessmentSection/@identifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE GENERAL 2c:Assertion 1] Two AssessmentSection children of a TestPart must not have the same unique identifier.
                        <xsl:text/>
<xsl:value-of select="concat('The AssessmentSection identifier is:', @identifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M5"/>
<xsl:template match="@*|node()" priority="-2" mode="M5">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/>
</xsl:template>

<!--PATTERN Ensure that AssessmentItem Response Declarations are correct.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Ensure that AssessmentItem Response Declarations are correct.</svrl:text>
<xsl:template match="text()" priority="-1" mode="M6"/>
<xsl:template match="@*|node()" priority="-2" mode="M6">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M6"/>
</xsl:template>

<!--PATTERN Enforce the correct use the TextEntryInteraction attributes.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Enforce the correct use the TextEntryInteraction attributes.</svrl:text>

	<!--RULE -->
<xsl:template match="//qti:extendedTextInteraction[@stringIdentifier]" priority="1000" mode="M7">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//qti:textEntryInteraction[@stringIdentifier]"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="not(@stringIdentifier=@responseIdentifier)"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@stringIdentifier=@responseIdentifier)">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE INTERACTION 1a:Assertion 1] The StringIdentifier and ResponseIdentifier attribute values must not be the same.
                        <xsl:text/>
<xsl:value-of select="concat('The StringIdentifier value is:', @stringIdentifier)"/>
<xsl:text/>
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M7"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M7"/>
<xsl:template match="@*|node()" priority="-2" mode="M7">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M7"/>
</xsl:template>

<!--PATTERN CompanionMaterialsInfo.Type[RULESET] For the CompanionMaterialsInfo.Type complexType.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">[RULESET] For the CompanionMaterialsInfo.Type complexType.</svrl:text>

	<!--RULE -->
<xsl:template match="apip:apipAccessibility/apip:companionMaterialsInfo" priority="1000" mode="M8">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="apip:apipAccessibility/apip:companionMaterialsInfo"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:calculator) = 0 or count(apip:calculator) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:calculator) = 0 or count(apip:calculator) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 1] Invalid number of "calculator" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:calculator)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M8"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M8"/>
<xsl:template match="@*|node()" priority="-2" mode="M8">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M8"/>
</xsl:template>

<!--PATTERN InclusionOrder.Type[RULESET] For the InclusionOrder.Type complexType.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">[RULESET] For the InclusionOrder.Type complexType.</svrl:text>

	<!--RULE -->
<xsl:template match="apip:apipAccessibility/apip:inclusionOrder" priority="1000" mode="M9">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="apip:apipAccessibility/apip:inclusionOrder"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:brailleDefaultOrder) = 0 or count(apip:brailleDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:brailleDefaultOrder) = 0 or count(apip:brailleDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 1] Invalid number of "brailleDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:brailleDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:textOnlyDefaultOrder) = 0 or count(apip:textOnlyDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:textOnlyDefaultOrder) = 0 or count(apip:textOnlyDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 2] Invalid number of "textOnlyDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:textOnlyDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:textOnlyOnDemandOrder) = 0 or count(apip:textOnlyOnDemandOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:textOnlyOnDemandOrder) = 0 or count(apip:textOnlyOnDemandOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 3] Invalid number of "textOnlyOnDemandOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:textOnlyOnDemandOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:textGraphicsDefaultOrder) = 0 or count(apip:textGraphicsDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:textGraphicsDefaultOrder) = 0 or count(apip:textGraphicsDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 4] Invalid number of "textGraphicsDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:textGraphicsDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:textGraphicsOnDemandOrder) = 0 or count(apip:textGraphicsOnDemandOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:textGraphicsOnDemandOrder) = 0 or count(apip:textGraphicsOnDemandOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 5] Invalid number of "textGraphicsOnDemandOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:textGraphicsOnDemandOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:graphicsOnlyOnDemandOrder) = 0 or count(apip:graphicsOnlyOnDemandOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:graphicsOnlyOnDemandOrder) = 0 or count(apip:graphicsOnlyOnDemandOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 6] Invalid number of "graphicsOnlyOnDemandOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:graphicsOnlyOnDemandOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:nonVisualDefaultOrder) = 0 or count(apip:nonVisualDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:nonVisualDefaultOrder) = 0 or count(apip:nonVisualDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 7] Invalid number of "nonVisualDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:nonVisualDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:aslDefaultOrder) = 0 or count(apip:aslDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:aslDefaultOrder) = 0 or count(apip:aslDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 8] Invalid number of "aslDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:aslDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:aslOnDemandOrder) = 0 or count(apip:aslOnDemandOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:aslOnDemandOrder) = 0 or count(apip:aslOnDemandOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 9] Invalid number of "aslOnDemandOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:aslOnDemandOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:signedEnglishDefaultOrder) = 0 or count(apip:signedEnglishDefaultOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:signedEnglishDefaultOrder) = 0 or count(apip:signedEnglishDefaultOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 10] Invalid number of "signedEnglishDefaultOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:signedEnglishDefaultOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:signedEnglishOnDemandOrder) = 0 or count(apip:signedEnglishOnDemandOrder) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:signedEnglishOnDemandOrder) = 0 or count(apip:signedEnglishOnDemandOrder) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 11] Invalid number of "signedEnglishOnDemandOrder" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:signedEnglishOnDemandOrder)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M9"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M9"/>
<xsl:template match="@*|node()" priority="-2" mode="M9">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M9"/>
</xsl:template>

<!--PATTERN RelatedElementInfo.Type[RULESET] For the RelatedElementInfo.Type complexType.-->
<svrl:text xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">[RULESET] For the RelatedElementInfo.Type complexType.</svrl:text>

	<!--RULE -->
<xsl:template match="apip:apipAccessibility/apip:accessibilityInfo/apip:accessElement/apip:relatedElementInfo" priority="1000" mode="M10">
<svrl:fired-rule xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="apip:apipAccessibility/apip:accessibilityInfo/apip:accessElement/apip:relatedElementInfo"/>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:spoken) = 0 or count(apip:spoken) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:spoken) = 0 or count(apip:spoken) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 1] Invalid number of "spoken" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:spoken)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:brailleText) = 0 or count(apip:brailleText) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:brailleText) = 0 or count(apip:brailleText) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 2] Invalid number of "brailleText" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:brailleText)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:tactileFile) = 0 or count(apip:tactileFile) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:tactileFile) = 0 or count(apip:tactileFile) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 3] Invalid number of "tactileFile" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:tactileFile)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:signing) = 0 or count(apip:signing) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:signing) = 0 or count(apip:signing) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 4] Invalid number of "signing" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:signing)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:keyWordTranslation) = 0 or count(apip:keyWordTranslation) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:keyWordTranslation) = 0 or count(apip:keyWordTranslation) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 5] Invalid number of "keyWordTranslation" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:keyWordTranslation)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:revealAlternativeRepresentation) = 0 or count(apip:revealAlternativeRepresentation) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:revealAlternativeRepresentation) = 0 or count(apip:revealAlternativeRepresentation) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 6] Invalid number of "revealAlternativeRepresentation" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:revealAlternativeRepresentation)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:guidance) = 0 or count(apip:guidance) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:guidance) = 0 or count(apip:guidance) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 7] Invalid number of "guidance" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:guidance)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:structuredMask) = 0 or count(apip:structuredMask) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:structuredMask) = 0 or count(apip:structuredMask) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 8] Invalid number of "structuredMask" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:structuredMask)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:scaffold) = 0 or count(apip:scaffold) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:scaffold) = 0 or count(apip:scaffold) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 9] Invalid number of "scaffold" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:scaffold)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:chunk) = 0 or count(apip:chunk) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:chunk) = 0 or count(apip:chunk) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 10] Invalid number of "chunk" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:chunk)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:answerReduction) = 0 or count(apip:answerReduction) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:answerReduction) = 0 or count(apip:answerReduction) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 11] Invalid number of "answerReduction" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:answerReduction)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>

		<!--ASSERT -->
<xsl:choose>
<xsl:when test="count(apip:keyWordEmphasis) = 0 or count(apip:keyWordEmphasis) = 1"/>
<xsl:otherwise>
<svrl:failed-assert xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(apip:keyWordEmphasis) = 0 or count(apip:keyWordEmphasis) = 1">
<xsl:attribute name="location">
<xsl:apply-templates select="." mode="schematron-get-full-path"/>
</xsl:attribute>
<svrl:text>
                        [RULE for Local Attribute 12] Invalid number of "keyWordEmphasis" elements:
                        <xsl:text/>
<xsl:value-of select="count(apip:keyWordEmphasis)"/>
<xsl:text/>
                        .
                    </svrl:text>
</svrl:failed-assert>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M10"/>
</xsl:template>
<xsl:template match="text()" priority="-1" mode="M10"/>
<xsl:template match="@*|node()" priority="-2" mode="M10">
<xsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M10"/>
</xsl:template>
</xsl:stylesheet>
