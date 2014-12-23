package com.pacificmetrics.orca.loader.ims;

import java.util.ArrayList;
import java.util.List;

public class IMSMetadata {

    private String identifier;
    private String title = "";
    private String description = "";
    private String language = IMSPackageConstants.DEFAULT_LANG;
    private String difficulty = IMSPackageConstants.DEFAULT_DIFFICULTY;
    private String publicationStatus = IMSPackageConstants.DEFAULT_PUBLICATION_STATUS;
    private String interactionType = "";
    private String subject = "";
    private String grade = "";
    private String points = "";
    private String gradeStart = "";
    private String gradeEnd = "";
    private String depthOfKnowledge = "";
    private String primaryStandard = "";
    private List<String> secondaryStandards = new ArrayList<String>();
    private String genre = IMSPackageConstants.DEFAULT_GENRE;

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }

    public String getPublicationStatus() {
        return publicationStatus;
    }

    public void setPublicationStatus(String publicationStatus) {
        this.publicationStatus = publicationStatus;
    }

    public String getInteractionType() {
        return interactionType;
    }

    public void setInteractionType(String interactionType) {
        this.interactionType = interactionType;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getGrade() {
        return grade;
    }

    public void setGrade(String grade) {
        this.grade = grade;
    }

    public String getPoints() {
        return points;
    }

    public void setPoints(String points) {
        this.points = points;
    }

    public String getGradeStart() {
        return gradeStart;
    }

    public void setGradeStart(String gradeStart) {
        this.gradeStart = gradeStart;
    }

    public String getGradeEnd() {
        return gradeEnd;
    }

    public void setGradeEnd(String gradeEnd) {
        this.gradeEnd = gradeEnd;
    }

    public String getDepthOfKnowledge() {
        return depthOfKnowledge;
    }

    public void setDepthOfKnowledge(String depthOfKnowledge) {
        this.depthOfKnowledge = depthOfKnowledge;
    }

    public String getPrimaryStandard() {
        return primaryStandard;
    }

    public void setPrimaryStandard(String primaryStandard) {
        this.primaryStandard = primaryStandard;
    }

    public List<String> getSecondaryStandards() {
        return secondaryStandards;
    }

    public void setSecondaryStandards(List<String> secondaryStandards) {
        this.secondaryStandards = secondaryStandards;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

}
