package com.pacificmetrics.orca.cts.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.cts.model.Category;
import com.pacificmetrics.orca.cts.model.Grade;
import com.pacificmetrics.orca.cts.model.Publication;
import com.pacificmetrics.orca.cts.model.Publisher;
import com.pacificmetrics.orca.cts.model.Standard;
import com.pacificmetrics.orca.cts.model.Subject;

@Stateless
public class ClaimTargetStandardService {

    private static final Log LOGGER = LogFactory
            .getLog(ClaimTargetStandardService.class);

    @EJB
    private CTSCacheService cacheService;

    @EJB
    private CTSService ctsService;

    public List<Publisher> findAllPublishers() {
        List<Publisher> publishers = null;
        try {
            publishers = cacheService.getPublishers();
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read publishers from cache " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(publishers)) {
            publishers = ctsService.findAllPublishers();
            updatePublisher(publishers);
        }
        return publishers != null ? publishers : Collections
                .<Publisher> emptyList();
    }

    public List<Subject> findSubjects(String publisherKey) {
        List<Subject> subjects = null;
        try {
            subjects = cacheService.getSubjects(publisherKey);
        } catch (Exception e) {
            LOGGER.error("Unable to read subject from cache for publisher key "
                    + publisherKey + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(subjects)) {
            subjects = ctsService.findSubjectsByPublisher(publisherKey);
            updateSubjects(publisherKey, subjects);
        }
        return subjects != null ? subjects : Collections.<Subject> emptyList();
    }

    public List<Publication> findPublications(String publisherKey,
            String subjectKey) {
        List<Publication> publications = null;
        try {
            publications = cacheService.getPublications(publisherKey,
                    subjectKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read publications from cache for publisher key "
                            + publisherKey + " and subject key " + subjectKey
                            + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(publications)) {
            publications = ctsService.findPublicationByPublisherAndSubject(
                    publisherKey, subjectKey);
            updatePublications(publisherKey, subjectKey, publications);
        }
        return publications != null ? publications : Collections
                .<Publication> emptyList();
    }

    public List<Category> findCateogries(String publicationKey) {
        List<Category> categories = null;
        try {
            categories = cacheService.getCategories(publicationKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read categories from cache for publication key "
                            + publicationKey + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(categories)) {
            categories = ctsService
                    .findCategoryByPublicationKey(publicationKey);
            updateCategories(publicationKey, categories);
        }
        return categories != null ? categories : Collections
                .<Category> emptyList();
    }

    public List<Grade> findGrades(String publicationKey) {
        List<Grade> grades = null;
        try {
            grades = cacheService.getGrades(publicationKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read grades from cache for publication key "
                            + publicationKey + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(grades)) {
            grades = ctsService.findGradesByPublication(publicationKey);
            updateGrade(publicationKey, grades);
        }
        return grades != null ? grades : Collections.<Grade> emptyList();
    }

    public List<Standard> findStandards(String publicationKey, String gradeKey) {
        List<Standard> standards = null;
        try {
            standards = cacheService.getStandards(publicationKey, gradeKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read standards from cache for publication key "
                            + publicationKey + " and grade key " + gradeKey
                            + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(standards)) {
            standards = ctsService.findStandardByPublicationAndGrade(
                    publicationKey, gradeKey);
            updateStandards(publicationKey, gradeKey, standards);
        }
        return standards != null ? standards : Collections
                .<Standard> emptyList();
    }

    public List<Standard> findStandards(String publicationKey, String gradeKey,
            String treeLevel) {
        List<Standard> standards = new ArrayList<Standard>();
        List<Standard> standardLists = new ArrayList<Standard>();
        try {
            standardLists = cacheService.getStandards(publicationKey, gradeKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read standards from cache for publication key "
                            + publicationKey + " and grade key " + gradeKey
                            + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(standardLists)) {
            standardLists = ctsService.findStandardByPublicationAndGrade(
                    publicationKey, gradeKey);
            updateStandards(publicationKey, gradeKey, standardLists);
        }

        for (Standard standard : standardLists) {
            if (standard != null
                    && (StringUtils.isNotEmpty(treeLevel) && treeLevel
                            .equalsIgnoreCase(standard.getTreeLevel()))) {
                standards.add(standard);
            }
        }
        return standards != null ? standards : Collections
                .<Standard> emptyList();
    }

    public List<Standard> findStandards(String publicationKey, String gradeKey,
            String treeLevel, String parentLevel) {
        List<Standard> standards = new ArrayList<Standard>();
        List<Standard> standardLists = new ArrayList<Standard>();
        try {
            cacheService.getStandards(publicationKey, gradeKey);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read standards from cache for publication key "
                            + publicationKey + " grade key " + gradeKey
                            + " tree level " + treeLevel + " parent level "
                            + parentLevel + " " + e.getMessage(), e);
        }
        if (CollectionUtils.isEmpty(standardLists)) {
            standardLists = ctsService.findStandardByPublicationAndGrade(
                    publicationKey, gradeKey);
            updateStandards(publicationKey, gradeKey, standardLists);
        }
        for (Standard standard : standardLists) {
            if (standard != null
                    && (StringUtils.isNotEmpty(treeLevel) && treeLevel
                            .equalsIgnoreCase(standard.getTreeLevel()))
                    && (StringUtils.isNotEmpty(parentLevel) && parentLevel
                            .equalsIgnoreCase(standard.getFkParent()))) {
                standards.add(standard);
            }
        }
        return standards != null ? standards : Collections
                .<Standard> emptyList();
    }

    private void updatePublisher(List<Publisher> publishers) {
        try {
            cacheService.setPublishers(publishers);
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to update the publishers in cache "
                            + e.getMessage(), e);
        }
    }

    private void updateSubjects(String publisherKey, List<Subject> subjects) {
        try {
            cacheService.setSubjects(publisherKey, subjects);
        } catch (Exception e) {
            LOGGER.error("Unable to update subjects for publisher key "
                    + publisherKey, e);
        }
    }

    private void updatePublications(String publisherKey, String subjectKey,
            List<Publication> publications) {
        try {
            cacheService
                    .setPublications(publisherKey, subjectKey, publications);
        } catch (Exception e) {
            LOGGER.error("Unable to update publications for publisher key "
                    + publisherKey + " and subject key " + subjectKey, e);
        }
    }

    private void updateCategories(String publicationKey,
            List<Category> categories) {
        try {
            cacheService.setCategories(publicationKey, categories);
        } catch (Exception e) {
            LOGGER.error("Unable to update categories for publication key "
                    + publicationKey, e);
        }
    }

    private void updateGrade(String publicationKey, List<Grade> grades) {
        try {
            cacheService.setGrades(publicationKey, grades);
        } catch (Exception e) {
            LOGGER.error("Unable to update grades for publication key "
                    + publicationKey, e);
        }
    }

    private void updateStandards(String publicationKey, String gradeKey,
            List<Standard> standardLists) {
        try {
            cacheService.setStandards(publicationKey, gradeKey, standardLists);
        } catch (Exception e) {
            LOGGER.error("Unable to update standard for publication key "
                    + publicationKey + " grade key " + gradeKey, e);
        }
    }
}
