//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.08.09 at 09:22:32 PM IST 
//


package org.w3.synthesis;

import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlElementDecl;
import javax.xml.bind.annotation.XmlRegistry;
import javax.xml.namespace.QName;


/**
 * This object contains factory methods for each 
 * Java content interface and Java element interface 
 * generated in the org.w3.synthesis package. 
 * <p>An ObjectFactory allows you to programatically 
 * construct new instances of the Java representation 
 * for XML content. The Java representation of XML 
 * content can consist of schema derived interfaces 
 * and classes representing the binding of schema 
 * type definitions, element declarations and model 
 * groups.  Factory methods for each of these are 
 * provided in this class.
 * 
 */
@XmlRegistry
public class ObjectFactory {

    private static final QName STRUCTQNAME = new QName("http://www.w3.org/2001/10/synthesis", "struct");
    private static final QName VOICEQNAME = new QName("http://www.w3.org/2001/10/synthesis", "voice");
    private static final QName SUBQNAME = new QName("http://www.w3.org/2001/10/synthesis", "sub");
    private static final QName PROSODYQNAME = new QName("http://www.w3.org/2001/10/synthesis", "prosody");
    private static final QName AUDIOQNAME = new QName("http://www.w3.org/2001/10/synthesis", "audio");
    private static final QName PHONEMEQNAME = new QName("http://www.w3.org/2001/10/synthesis", "phoneme");
    private static final QName AWSQNAME = new QName("http://www.w3.org/2001/10/synthesis", "aws");
    private static final QName MARKQNAME = new QName("http://www.w3.org/2001/10/synthesis", "mark");
    private static final QName EMPHASISQNAME = new QName("http://www.w3.org/2001/10/synthesis", "emphasis");
    private static final QName SAYASQNAME = new QName("http://www.w3.org/2001/10/synthesis", "say-as");
    private static final QName SQNAME = new QName("http://www.w3.org/2001/10/synthesis", "s");
    private static final QName PQNAME = new QName("http://www.w3.org/2001/10/synthesis", "p");
    private static final QName BREAKQNAME = new QName("http://www.w3.org/2001/10/synthesis", "break");
    private static final QName ORIGINALSPEAKLEXICONQNAME = new QName("http://www.w3.org/2001/10/synthesis", "lexicon");
    private static final QName ORIGINALSPEAKMETAQNAME = new QName("http://www.w3.org/2001/10/synthesis", "meta");
    private static final QName ORIGINALSPEAKMETADATAQNAME = new QName("http://www.w3.org/2001/10/synthesis", "metadata");

    /**
     * Create a new ObjectFactory that can be used to create new instances of schema derived classes for package: org.w3.synthesis
     * 
     */
    public ObjectFactory() {
    }

    /**
     * Create an instance of {@link Sub }
     * 
     */
    public Sub createSub() {
        return new Sub();
    }

    /**
     * Create an instance of {@link Desc }
     * 
     */
    public Desc createDesc() {
        return new Desc();
    }

    /**
     * Create an instance of {@link Voice }
     * 
     */
    public Voice createVoice() {
        return new Voice();
    }

    /**
     * Create an instance of {@link Audio }
     * 
     */
    public Audio createAudio() {
        return new Audio();
    }

    /**
     * Create an instance of {@link Speak }
     * 
     */
    public Speak createSpeak() {
        return new Speak();
    }

    /**
     * Create an instance of {@link OriginalSpeak }
     * 
     */
    public OriginalSpeak createOriginalSpeak() {
        return new OriginalSpeak();
    }

    /**
     * Create an instance of {@link SsmlMeta }
     * 
     */
    public SsmlMeta createSsmlMeta() {
        return new SsmlMeta();
    }

    /**
     * Create an instance of {@link SsmlMetadata }
     * 
     */
    public SsmlMetadata createSsmlMetadata() {
        return new SsmlMetadata();
    }

    /**
     * Create an instance of {@link SsmlLexicon }
     * 
     */
    public SsmlLexicon createSsmlLexicon() {
        return new SsmlLexicon();
    }

    /**
     * Create an instance of {@link Prosody }
     * 
     */
    public Prosody createProsody() {
        return new Prosody();
    }

    /**
     * Create an instance of {@link Mark }
     * 
     */
    public Mark createMark() {
        return new Mark();
    }

    /**
     * Create an instance of {@link Break }
     * 
     */
    public Break createBreak() {
        return new Break();
    }

    /**
     * Create an instance of {@link Sentence }
     * 
     */
    public Sentence createSentence() {
        return new Sentence();
    }

    /**
     * Create an instance of {@link Phoneme }
     * 
     */
    public Phoneme createPhoneme() {
        return new Phoneme();
    }

    /**
     * Create an instance of {@link Paragraph }
     * 
     */
    public Paragraph createParagraph() {
        return new Paragraph();
    }

    /**
     * Create an instance of {@link Emphasis }
     * 
     */
    public Emphasis createEmphasis() {
        return new Emphasis();
    }

    /**
     * Create an instance of {@link SayAs }
     * 
     */
    public SayAs createSayAs() {
        return new SayAs();
    }

    /**
     * Create an instance of {@link OriginalMark }
     * 
     */
    public OriginalMark createOriginalMark() {
        return new OriginalMark();
    }

    /**
     * Create an instance of {@link OriginalAudio }
     * 
     */
    public OriginalAudio createOriginalAudio() {
        return new OriginalAudio();
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Object }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "struct")
    public JAXBElement<Object> createStruct(Object value) {
        return new JAXBElement<Object>(STRUCTQNAME, Object.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Voice }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "voice", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Voice> createVoice(Voice value) {
        return new JAXBElement<Voice>(VOICEQNAME, Voice.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Sub }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "sub", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Sub> createSub(Sub value) {
        return new JAXBElement<Sub>(SUBQNAME, Sub.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Prosody }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "prosody", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Prosody> createProsody(Prosody value) {
        return new JAXBElement<Prosody>(PROSODYQNAME, Prosody.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Audio }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "audio", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Audio> createAudio(Audio value) {
        return new JAXBElement<Audio>(AUDIOQNAME, Audio.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Phoneme }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "phoneme", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Phoneme> createPhoneme(Phoneme value) {
        return new JAXBElement<Phoneme>(PHONEMEQNAME, Phoneme.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Object }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "aws")
    public JAXBElement<Object> createAws(Object value) {
        return new JAXBElement<Object>(AWSQNAME, Object.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Mark }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "mark", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Mark> createMark(Mark value) {
        return new JAXBElement<Mark>(MARKQNAME, Mark.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Emphasis }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "emphasis", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Emphasis> createEmphasis(Emphasis value) {
        return new JAXBElement<Emphasis>(EMPHASISQNAME, Emphasis.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link SayAs }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "say-as", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<SayAs> createSayAs(SayAs value) {
        return new JAXBElement<SayAs>(SAYASQNAME, SayAs.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Sentence }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "s", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "struct")
    public JAXBElement<Sentence> createS(Sentence value) {
        return new JAXBElement<Sentence>(SQNAME, Sentence.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Paragraph }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "p", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "struct")
    public JAXBElement<Paragraph> createP(Paragraph value) {
        return new JAXBElement<Paragraph>(PQNAME, Paragraph.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link Break }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "break", substitutionHeadNamespace = "http://www.w3.org/2001/10/synthesis", substitutionHeadName = "aws")
    public JAXBElement<Break> createBreak(Break value) {
        return new JAXBElement<Break>(BREAKQNAME, Break.class, null, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link SsmlLexicon }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "lexicon", scope = OriginalSpeak.class)
    public JAXBElement<SsmlLexicon> createOriginalSpeakLexicon(SsmlLexicon value) {
        return new JAXBElement<SsmlLexicon>(ORIGINALSPEAKLEXICONQNAME, SsmlLexicon.class, OriginalSpeak.class, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link SsmlMeta }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "meta", scope = OriginalSpeak.class)
    public JAXBElement<SsmlMeta> createOriginalSpeakMeta(SsmlMeta value) {
        return new JAXBElement<SsmlMeta>(ORIGINALSPEAKMETAQNAME, SsmlMeta.class, OriginalSpeak.class, value);
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link SsmlMetadata }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.w3.org/2001/10/synthesis", name = "metadata", scope = OriginalSpeak.class)
    public JAXBElement<SsmlMetadata> createOriginalSpeakMetadata(SsmlMetadata value) {
        return new JAXBElement<SsmlMetadata>(ORIGINALSPEAKMETADATAQNAME, SsmlMetadata.class, OriginalSpeak.class, value);
    }

}
