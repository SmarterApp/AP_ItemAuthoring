package com.pacificmetrics.orca.cts.service;

import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.Stateless;

import org.apache.commons.lang.StringUtils;
import org.json.JSONException;
import org.json.JSONObject;

import com.pacificmetrics.orca.cts.CTSResponseConstant;
import com.pacificmetrics.orca.cts.CTSResponseUtil;
import com.pacificmetrics.orca.cts.CTSRestClient;
import com.pacificmetrics.orca.cts.model.Category;
import com.pacificmetrics.orca.cts.model.Grade;
import com.pacificmetrics.orca.cts.model.Publication;
import com.pacificmetrics.orca.cts.model.Publisher;
import com.pacificmetrics.orca.cts.model.Standard;
import com.pacificmetrics.orca.cts.model.Subject;

@Stateless
public class CTSService {

    private static final Logger LOGGER = Logger.getLogger(CTSService.class
            .getCanonicalName());

    private static final String SUCCESS = "success";

    public List<Publisher> findAllPublishers() {
        List<Publisher> publishers = null;
        try {
            String jsonString = CTSRestClient.getPublisherJSON();
            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                publishers = CTSResponseUtil.parsePublisherPayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Publishers : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Publishers : " + e.getMessage(), e);
        }
        return publishers != null ? publishers : Collections
                .<Publisher> emptyList();
    }

    public List<Subject> findAllSubjects() {
        return perseSubjects(null);
    }

    public List<Subject> findSubjectsByPublisher(String publisherKey) {
        return perseSubjects(publisherKey);
    }

    public List<Publication> findPublicationByPublisherAndSubject(
            String publisherKey, String subjectKey) {
        List<Publication> publications = null;
        try {
            String jsonString = CTSRestClient.getPublicationJSON(publisherKey,
                    subjectKey);

            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                publications = CTSResponseUtil
                        .parsePublicationPayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Publications : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Publications : " + e.getMessage(), e);
        }
        return publications != null ? publications : Collections
                .<Publication> emptyList();
    }

    public List<Category> findCategoryByPublicationKey(String publicationKey) {
        List<Category> categories = null;
        try {
            String jsonString = CTSRestClient.getCategoryJSON(publicationKey);

            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                categories = CTSResponseUtil.parseCategoryPayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Categoies : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Categoies : " + e.getMessage(), e);
        }
        return categories != null ? categories : Collections
                .<Category> emptyList();
    }

    public List<Grade> findAllGrades() {
        return parseGrade(null);
    }

    public List<Grade> findGradesByPublication(String publicationKey) {
        return parseGrade(publicationKey);
    }

    public List<Standard> findStandardByPublicationAndGrade(
            String publicationKey, String gradeKey) {
        List<Standard> standards = null;
        try {
            String jsonString = CTSRestClient.getStandardJSON(publicationKey,
                    gradeKey);

            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                standards = CTSResponseUtil.parseStandardPayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Standards : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Standards : " + e.getMessage(), e);
        }
        return standards != null ? standards : Collections
                .<Standard> emptyList();
    }

    private List<Subject> perseSubjects(String publisherKey) {
        List<Subject> subjects = null;
        String jsonString = "";
        try {
            if (StringUtils.isNotBlank(publisherKey)) {
                jsonString = CTSRestClient.getSubjectJSON();
            } else {
                jsonString = CTSRestClient.getSubjectJSON(publisherKey);
            }

            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                subjects = CTSResponseUtil.parseSubjectPayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Subjects : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Subjects : " + e.getMessage(), e);
        }
        return subjects != null ? subjects : Collections.<Subject> emptyList();
    }

    private List<Grade> parseGrade(String publicationKey) {
        List<Grade> grades = null;
        String jsonString = null;
        try {
            if (StringUtils.isNotBlank(publicationKey)) {
                jsonString = CTSRestClient.getGradeJSON(publicationKey);
            } else {
                jsonString = CTSRestClient.getAllGradeJSON();
            }

            JSONObject jsonObject = new JSONObject(jsonString);

            String status = jsonObject.getString(CTSResponseConstant.STATUS);

            if (SUCCESS.equalsIgnoreCase(status)) {
                String jsonPayload = jsonObject
                        .getString(CTSResponseConstant.PAYLOAD);
                grades = CTSResponseUtil.parseGradePayload(jsonPayload);
            }
        } catch (JSONException e) {
            LOGGER.log(Level.SEVERE,
                    "Error persing Grades : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error fetching Grades : " + e.getMessage(), e);
        }
        return grades != null ? grades : Collections.<Grade> emptyList();
    }

}
