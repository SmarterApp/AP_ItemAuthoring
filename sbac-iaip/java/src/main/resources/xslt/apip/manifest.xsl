<?xml version="1.0" encoding="UTF-8"?>
<xs:stylesheet version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/1999/XSL/Transform">
    <xs:output method="xml" encoding="UTF-8" indent="no" standalone="yes"/>
    <xs:variable name="vUrl" select="'http://www.imsglobal.org/xsd/apip/apipv1p0/imscp_v1p1'"/>

    <!-- Main entry into the stylesheet. Other templates will be called from here. -->
    <xs:template match="/manifest">
        <xs:element name="manifest" use-attribute-sets="id" namespace="{$vUrl}">
            <xs:attribute name="xsi:schemaLocation">http://www.imsglobal.org/xsd/apip/apipv1p0/imscp_v1p1 http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_imscpv1p2_v1p0.xsd http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_lommanifestv1p0_v1p0.xsd http://ltsc.ieee.org/xsd/apipv1p0/LOM/resource http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_lomresourcev1p0_v1p0.xsd http://www.imsglobal.org/xsd/apip/apipv1p0/qtimetadata/imsqti_v2p1 http://www.imsglobal.org/profile/apip/apipv1p0/apipv1p0_qtimetadatav2p1_v1p0.xsd</xs:attribute>
            <metadata>
                <schema>
                    <xs:value-of select="./@schema"></xs:value-of>
                </schema>
                <schemaversion>
                    <xs:value-of select="./@schemaVersion" />
                </schemaversion>
                <xs:apply-templates select="lom" />
                <xs:apply-templates select="ccss" />
            </metadata>
            <organizations />
            <resources>
                <xs:apply-templates select="resource" />
            </resources>
        </xs:element>
    </xs:template>

    <!-- Resources are file pointers and metadata for tests, sections, and items. This is the entry point for each resource defined in the document -->
    <xs:template match="/manifest/resource">
        <xs:element name="resource" use-attribute-sets="id" namespace="{$vUrl}">
            <xs:attribute name="type"><xs:value-of select="@type" /></xs:attribute>
            <xs:if test="@base">
                <xs:attribute name="base"><xs:value-of select="@base" /></xs:attribute>
            </xs:if>
            <xs:if test="@href">
                <xs:attribute name="href"><xs:value-of select="@href" /></xs:attribute>
            </xs:if>
            <xs:if test="resourceMeta">
                <metadata>
                    <xs:apply-templates select="resourceMeta/lom" />
                    <xs:apply-templates select="resourceMeta/ccss" />
                </metadata>
            </xs:if>
            <xs:apply-templates select="file" />
            <xs:apply-templates select="dependency" />
            <xs:apply-templates select="variant" />
        </xs:element>
    </xs:template>

    <xs:template match="/manifest/resource/file">
        <xs:element name="file" namespace="{$vUrl}">
            <xs:attribute name="href"><xs:value-of select="@href" /></xs:attribute>
            <xs:apply-templates select="metadata" />
        </xs:element>
    </xs:template>

    <xs:template match="/manifest/resource/file/metadata">
        <xs:copy-of select="." />
    </xs:template>

    <xs:template match="/manifest/resource/dependency">
        <xs:element name="dependency" namespace="{$vUrl}">
            <xs:attribute name="identifierref"><xs:value-of select="@idRef" /></xs:attribute>
        </xs:element>
    </xs:template>

    <xs:template match="/manifest/resource/variant">
        <xs:element name="variant" use-attribute-sets="id" namespace="{$vUrl}">
            <xs:attribute name="identifierref"><xs:value-of select="@idRef" /></xs:attribute>
            <xs:apply-templates select="accessibility" />
        </xs:element>
    </xs:template>

    <xs:template match="/manifest/resource/variant/accessibility">
        <metadata>
            <accessForAllResource>
                <xs:apply-templates select="accessModeStatement" />
                <xs:copy-of select="controlFlexibility" />
                <xs:copy-of select="hasControlFlexibilityStatement" />
                <xs:copy-of select="displayTransformability" />
                <xs:copy-of select="hasDisplayTransformabilityStatement" />
                <xs:if test="@colourCoding">
                    <colourCodeing>
                        <xs:value-of select="@colourCoding" />
                    </colourCodeing>
                </xs:if>
                <xs:copy-of select="hazard" />
                <xs:copy-of select="hasAdaptation" />
                <xs:copy-of select="hasPart" />
                <xs:apply-templates select="isAdaptation" />
                <xs:if test="@isDisplayTransformabilityStatementOf">
                    <isDisplayTransformabilityStatementOf>
                        <xs:value-of select="@isDisplayTransformabilityStatementOf" />
                    </isDisplayTransformabilityStatementOf>
                </xs:if>
                <xs:if test="@isControlFlexibilityStatementOf">
                    <isControlFlexibilityStatementOf>
                        <xs:value-of select="@isControlFlexibilityStatementOf" />
                    </isControlFlexibilityStatementOf>
                </xs:if>
                <xs:if test="@isPartOf">
                    <isPartOf>
                        <xs:value-of select="@isPartOf" />
                    </isPartOf>
                </xs:if>
                <xs:apply-templates select="adaptationStatement" />
                <xs:copy-of select="./other/node()" />
            </accessForAllResource>
        </metadata>
    </xs:template>

    <xs:template match="/manifest/resource/variant/accessibility/accessModeStatement">
        <accessModeStatement>
            <originalAccessMode>
                <xs:value-of select="@originalAccessMode" />
            </originalAccessMode>
            <xs:if test="@accessModeUsage">
                <accessModeUsage>
                    <xs:value-of select="@accessModeUsage" />
                </accessModeUsage>
            </xs:if>
            <xs:copy-of select="./node()" />
        </accessModeStatement>
    </xs:template>

    <xs:template match="/manifest/resource/variant/accessibility/isAdaptation">
        <isAdaptation>
            <isAdaptationOf>
                <xs:value-of select="@isAdaptationOf" />
            </isAdaptationOf>
            <extent>
                <xs:value-of select="@extent" />
            </extent>
            <xs:copy-of select="./node()" />
        </isAdaptation>
    </xs:template>

    <xs:template match="/manifest/resource/variant/accessibility/adaptationStatement">
        <adaptationStatement>
            <xs:if test="@adaptationType">
                <adaptationType>
                    <xs:value-of select="@adaptationType" />
                </adaptationType>
            </xs:if>
            <originalAccessMode>
                <xs:value-of select="@originalAccessMode" />
            </originalAccessMode>
            <xs:if test="@extent">
                <extent>
                    <xs:value-of select="@extent" />
                </extent>
            </xs:if>
            <xs:copy-of select="./representationForm" />
            <xs:copy-of select="./language" />
            <xs:if test="@readingRate">
                <readingRate>
                    <xs:value-of select="@readingRate" />
                </readingRate>
            </xs:if>
            <xs:copy-of select="./educationLevel" />
            <xs:copy-of select="./other/node()" />
        </adaptationStatement>
    </xs:template>

    <!-- Entry point into the curriculum standards metadata -->
    <xs:template match="//ccss">
        <xs:element name="curriculumStandardsMetadataSet" namespace="{$vUrl}">
            <xs:attribute name="resourceLabel"><xs:value-of select="@resourceLabel" /></xs:attribute>
            <xs:attribute name="resourcePartId"><xs:value-of select="@resourcePartId" /></xs:attribute>
            <xs:apply-templates select="meta" />
        </xs:element>
    </xs:template>

    <xs:template match="//ccss/meta">
        <xs:element name="curriculumStandardsMetadata">
            <xs:attribute name="providerId"><xs:value-of select="@providerId" /></xs:attribute>
            <xs:apply-templates select="guid" />
        </xs:element>
    </xs:template>

    <xs:template match="//ccss/meta/guid">
        <xs:element name="setOfGUIDs">
            <xs:attribute name="region"><xs:value-of select="@region" /></xs:attribute>
            <xs:attribute name="version"><xs:value-of select="@version" /></xs:attribute>
            <xs:apply-templates select="label" />
        </xs:element>
    </xs:template>

    <xs:template match="//ccss/meta/guid/label">
        <labelledGUID>
            <label>
                <xs:value-of select="@label" />
            </label>
            <GUID>
                <xs:value-of select="@guid" />
            </GUID>
        </labelledGUID>
    </xs:template>

    <!-- Entry point into the lom processing. Please note there are two sections in the manifest where the lom is used. Different stylesheets determine the -->
    <xs:template match="/manifest/lom">
        <lom xmlns="http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest">
            <general>
                <xs:apply-templates select="general" />
            </general>
            <lifeCycle>
                <xs:apply-templates select="lifeCycle" />
            </lifeCycle>
            <xs:if test="metaMetadata">
                <metaMetadata>
                    <xs:apply-templates select="metaMetadata" />
                </metaMetadata>
            </xs:if>
            <xs:if test="technical">
                <technical>
                    <xs:apply-templates select="technical" />
                </technical>
            </xs:if>
            <educational>
                <xs:apply-templates select="educational" />
            </educational>
            <rights>
                <xs:apply-templates select="rights" />
            </rights>
            <xs:for-each select="relation">
                <relation>
                    <xs:apply-templates select="." />
                </relation>
            </xs:for-each>
            <xs:for-each select="annotation">
                <annotation>
                    <xs:apply-templates select="." />
                </annotation>
            </xs:for-each>
            <xs:for-each select="classification">
                <classification>
                    <xs:apply-templates select="." />
                </classification>
            </xs:for-each>
        </lom>
    </xs:template>

    <!-- Only differences are the name space and rights element is not required and qtiMetadata exists in resource but not manifest lom. May move this in the future into one template, 
        but works well for now. -->
    <xs:template match="/manifest/resource/resourceMeta/lom">
        <lom xmlns="http://ltsc.ieee.org/xsd/apipv1p0/LOM/resource">
            <general>
                <xs:apply-templates select="general" />
            </general>
            <lifeCycle>
                <xs:apply-templates select="lifeCycle" />
            </lifeCycle>
            <xs:if test="metaMetadata">
                <metaMetadata>
                    <xs:apply-templates select="metaMetadata" />
                </metaMetadata>
            </xs:if>
            <xs:if test="technical">
                <technical>
                    <xs:apply-templates select="technical" />
                </technical>
            </xs:if>
            <educational>
                <xs:apply-templates select="educational" />
            </educational>
            <xs:if test="rights">
                <rights>
                    <xs:apply-templates select="rights" />
                </rights>
            </xs:if>
            <xs:if test="relation">
                <relation>
                    <xs:apply-templates select="relation" />
                </relation>
            </xs:if>
            <xs:if test="annotation">
                <annotation>
                    <xs:apply-templates select="annotation" />
                </annotation>
            </xs:if>
            <xs:if test="classification">
                <classification>
                    <xs:apply-templates select="classification" />
                </classification>
            </xs:if>
            <xs:if test="qtiMetadata">
                <xs:apply-templates select="qtiMetadata" />
            </xs:if>
        </lom>
    </xs:template>

    <xs:template
        match="//lom/*/typicalAgeRange | //lom/*/structure | //lom/*/keyword | //lom/*/coverage | //lom/*/title | //lom/*/resource/description | //lom/*/description | //lom/*/version | //lom/*/installationRemarks | //lom/*/otherPlatformRequirements">
        <xs:element name="{name(.)}">
            <xs:for-each select="string">
                <string>
                    <xs:value-of select="@value" />
                </string>
            </xs:for-each>
        </xs:element>
    </xs:template>

    <xs:template match="//lom/*/entity | //lom/*/language | //lom/*/metadataschema | //lom/*/format | //lom/*/size | //lom/*/location">
        <xs:element name="{name(.)}">
            <xs:value-of select="@value" />
        </xs:element>
    </xs:template>

    <xs:template
        match="//lom/*/purpose | //lom/*/kind | //lom/*/copyrightAndOtherRestrictions | //lom/*/cost | //lom/*/difficulty | //lom/*/context | //lom/*/intendedEndUserRole | //lom/*/status | //lom/*/structure | //lom/*/aggregationLevel | //lom/*/interactivityType | //lom/*/learningResourceType | //lom/*/interactivityLevel | //lom/*/semanticDensity">
        <xs:element name="{name(.)}">
            <xs:if test="@source">
                <source>
                    <xs:value-of select="@source" />
                </source>
            </xs:if>
            <xs:if test="@value">
                <value>
                    <xs:value-of select="@value" />
                </value>
            </xs:if>
        </xs:element>
    </xs:template>

    <xs:template match="//lom/*/resource">
        <resource>
            <xs:apply-templates />
        </resource>
    </xs:template>

    <xs:template match="//lom/*/typicalLearningTime | //lom/*/duration">
        <xs:element name="{name(.)}">
            <xs:if test="@duration">
                <duration>
                    <xs:value-of select="@duration" />
                </duration>
            </xs:if>
            <xs:if test="@description">
                <description>
                    <xs:value-of select="@description" />
                </description>
            </xs:if>
        </xs:element>
    </xs:template>

    <xs:template match="//lom/*/taxonPath">
        <taxonPath>
            <xs:if test="@source">
                <source>
                    <xs:value-of select="@source" />
                </source>
            </xs:if>
            <xs:for-each select="taxon">
                <taxon>
                    <xs:value-of select="@value" />
                </taxon>
            </xs:for-each>
        </taxonPath>
    </xs:template>

    <xs:template match="//lom/*/identifier | //lom/*/resource/identifier">
        <identifier>
            <xs:if test="@catalog">
                <catalog>
                    <xs:value-of select="@catalog" />
                </catalog>
            </xs:if>
            <xs:if test="@entry">
                <entry>
                    <xs:value-of select="@entry" />
                </entry>
            </xs:if>
        </identifier>
    </xs:template>

    <xs:template match="//lom/*/date">
        <date>
            <xs:if test="@dateTime">
                <dateTime>
                    <xs:value-of select="@dateTime" />
                </dateTime>
            </xs:if>
            <xs:if test="@description">
                <description>
                    <xs:value-of select="@description" />
                </description>
            </xs:if>
        </date>
    </xs:template>

    <xs:template match="//lom/*/contribute">
        <contribute>
            <xs:if test="@role">
                <role>
                    <xs:value-of select="@role" />
                </role>
            </xs:if>
            <xs:if test="@date">
                <date>
                    <xs:value-of select="@date" />
                </date>
            </xs:if>
            <xs:for-each select="entity">
                <entity>
                    <xs:value-of select="@value" />
                </entity>
            </xs:for-each>
        </contribute>
    </xs:template>

    <xs:template match="//lom/*/requirement">
        <requirement>
            <orComposite>
                <type>
                    <xs:value-of select="@type" />
                </type>
                <name>
                    <xs:value-of select="@name" />
                </name>
                <minimumVersion>
                    <xs:value-of select="@minimumVersion" />
                </minimumVersion>
                <maximumVersion>
                    <xs:value-of select="@maximumVersion" />
                </maximumVersion>
            </orComposite>
        </requirement>
    </xs:template>

    <xs:template match="//lom/qtiMetadata">
        <qtiMetadata xmlns="http://www.imsglobal.org/xsd/apip/apipv1p0/qtimetadata/imsqti_v2p1">
            <xs:if test="@itemTemplate">
                <itemTemplate>
                    <xs:value-of select="@itemTemplate" />
                </itemTemplate>
            </xs:if>
            <xs:if test="@timeDependent">
                <timeDependent>
                    <xs:value-of select="@timeDependent" />
                </timeDependent>
            </xs:if>
            <xs:if test="@composite">
                <composite>
                    <xs:value-of select="@composite" />
                </composite>
            </xs:if>
            <xs:copy-of select="interactionType" />
            <xs:if test="@feedbackType">
                <feedbackType>
                    <xs:value-of select="@feedbackType" />
                </feedbackType>
            </xs:if>
            <xs:if test="@solutionAvailable">
                <solutionAvailable>
                    <xs:value-of select="@solutionAvailable" />
                </solutionAvailable>
            </xs:if>
        </qtiMetadata>
    </xs:template>

    <!-- Attribute groups that are called for multiple elements -->
    <xs:attribute-set name="id">
        <xs:attribute name="identifier"><xs:value-of select="@id" /></xs:attribute>
    </xs:attribute-set>
</xs:stylesheet> 