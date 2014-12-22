package com.pacificmetrics.orca.cts;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.pacificmetrics.orca.cts.model.Category;
import com.pacificmetrics.orca.cts.model.Grade;
import com.pacificmetrics.orca.cts.model.Publication;
import com.pacificmetrics.orca.cts.model.Publisher;
import com.pacificmetrics.orca.cts.model.Standard;
import com.pacificmetrics.orca.cts.model.Subject;

public class CTSResponseUtil {

    private static final Logger LOGGER = Logger.getLogger(CTSResponseUtil.class
            .getName());

    private CTSResponseUtil() {
    }

    public static List<Publisher> parsePublisherPayload(String jsonPayload)
            throws JSONException {
        JSONArray publisherArray = new JSONArray(jsonPayload);
        List<Publisher> publishers = new ArrayList<Publisher>();
        for (int i = 0; i < publisherArray.length(); i++) {
            Publisher publisher = new Publisher();
            JSONObject publisherObject = publisherArray.getJSONObject(i);

            try {
                publisher.setKey(URLEncoder.encode(
                        publisherObject.getString(CTSResponseConstant.KEY),
                        "UTF-8"));
            } catch (UnsupportedEncodingException e) {
                LOGGER.log(Level.SEVERE, "Error in parsing Publisher Payload "
                        + e.getMessage(), e);
            }
            publisher.setName(publisherObject
                    .getString(CTSResponseConstant.NAME));
            publishers.add(publisher);

        }
        return publishers;
    }

    public static List<Subject> parseSubjectPayload(String jsonPayload)
            throws JSONException {
        JSONArray publisherArray = new JSONArray(jsonPayload);
        List<Subject> subjects = new ArrayList<Subject>();
        for (int i = 0; i < publisherArray.length(); i++) {
            Subject subject = new Subject();
            JSONObject subjectObject = publisherArray.getJSONObject(i);
            try {
                subject.setKey(URLEncoder.encode(
                        subjectObject.getString(CTSResponseConstant.KEY),
                        "UTF-8"));
            } catch (UnsupportedEncodingException e) {
                LOGGER.log(Level.SEVERE, "Error in parsing Subject Payload "
                        + e.getMessage(), e);
            }
            subject.setName(subjectObject.getString(CTSResponseConstant.NAME));
            subject.setCode(subjectObject.getString(CTSResponseConstant.CODE));
            subjects.add(subject);
        }
        return subjects;
    }

    public static List<Publication> parsePublicationPayload(String jsonPayload)
            throws JSONException {
        JSONArray publicationArray = new JSONArray(jsonPayload);
        List<Publication> publications = new ArrayList<Publication>();
        for (int i = 0; i < publicationArray.length(); i++) {
            Publication publication = new Publication();
            JSONObject publicationObject = publicationArray.getJSONObject(i);
            try {
                publication.setKey(URLEncoder.encode(
                        publicationObject.getString(CTSResponseConstant.KEY),
                        "UTF-8"));
            } catch (UnsupportedEncodingException e) {
                LOGGER.log(
                        Level.SEVERE,
                        "Error in parsing Publication Payload "
                                + e.getMessage(), e);
            }
            publication.setVersion(publicationObject
                    .getString(CTSResponseConstant.VERSION));
            publication.setFkPublisher(publicationObject
                    .getString(CTSResponseConstant.FKPUBLISHER));
            publication.setFkSubject(publicationObject
                    .getString(CTSResponseConstant.FKSUBJECT));
            publication.setDescription(publicationObject
                    .getString(CTSResponseConstant.DESC));
            publication.setSubjectLabel(publicationObject
                    .getString(CTSResponseConstant.SUBJECT_LABEL));
            publication.setStatus(publicationObject
                    .getString(CTSResponseConstant.STATUS));
            publications.add(publication);
        }
        return publications;
    }

    public static List<Category> parseCategoryPayload(String jsonPayload)
            throws JSONException {
        JSONArray categoryArray = new JSONArray(jsonPayload);
        List<Category> categories = new ArrayList<Category>();
        for (int i = 0; i < categoryArray.length(); i++) {
            Category category = new Category();
            JSONObject categoryObject = categoryArray.getJSONObject(i);
            category.setName(categoryObject.getString(CTSResponseConstant.NAME));
            category.setFkPublication(categoryObject
                    .getString(CTSResponseConstant.FKPUBLICATION));
            category.setTreeLevel(categoryObject
                    .getString(CTSResponseConstant.TREE_LEVEL));
            categories.add(category);
        }
        return categories;
    }

    public static List<Grade> parseGradePayload(String jsonPayload)
            throws JSONException {
        JSONArray gradeArray = new JSONArray(jsonPayload);
        List<Grade> grades = new ArrayList<Grade>();
        for (int i = 0; i < gradeArray.length(); i++) {
            Grade grade = new Grade();
            JSONObject gradeObject = gradeArray.getJSONObject(i);
            grade.setName(gradeObject.getString(CTSResponseConstant.NAME));
            grade.setKey(gradeObject.getString(CTSResponseConstant.KEY));
            grade.setDescription(gradeObject
                    .getString(CTSResponseConstant.DESC));
            grades.add(grade);
        }
        return grades;
    }

    public static List<Standard> parseStandardPayload(String jsonPayload)
            throws JSONException {
        JSONArray standardArray = new JSONArray(jsonPayload);
        List<Standard> standards = new ArrayList<Standard>();
        for (int i = 0; i < standardArray.length(); i++) {
            Standard standard = new Standard();
            JSONObject gradeObject = standardArray.getJSONObject(i);
            standard.setName(gradeObject.getString(CTSResponseConstant.NAME));
            standard.setKey(gradeObject.getString(CTSResponseConstant.KEY));
            standard.setDescription(gradeObject
                    .getString(CTSResponseConstant.DESC));
            standard.setFkGradeLevel(gradeObject
                    .getString(CTSResponseConstant.FKGRADE_LEVEL));
            standard.setFkParent(gradeObject
                    .getString(CTSResponseConstant.FKPARENT));
            standard.setFkPublication(gradeObject
                    .getString(CTSResponseConstant.FKPUBLICATION));
            standard.setTreeLevel(gradeObject
                    .getString(CTSResponseConstant.TREE_LEVEL));
            standard.setShortName(gradeObject
                    .getString(CTSResponseConstant.SHORT_NAME));
            standards.add(standard);
        }
        return standards;
    }

}