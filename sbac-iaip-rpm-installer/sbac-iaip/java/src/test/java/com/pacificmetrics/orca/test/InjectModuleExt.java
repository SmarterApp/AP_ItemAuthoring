package com.pacificmetrics.orca.test;

import static org.unitils.util.AnnotationUtils.getFieldsAnnotatedWith;
import static org.unitils.util.ReflectionUtils.getFieldWithName;

import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.Set;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.unitils.core.UnitilsException;
import org.unitils.inject.InjectModule;
import org.unitils.inject.annotation.InjectIntoByType;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.inject.util.InjectionUtils;
import org.unitils.inject.util.PropertyAccess;


public class InjectModuleExt extends InjectModule {
    
	private static final Log LOGGER = LogFactory
			.getLog(InjectModuleExt.class);
	
    @Override
    public void init(Properties configuration) {
        super.init(configuration);
        LOGGER.info("InjectModuleExt - init");        
    }

    @Override
    public void injectAllByType(Object test) {
        Set<Field> fields = getFieldsAnnotatedWith(test.getClass(), InjectIntoByTypeExt.class);
        for (Field field : fields) {
            injectByTypeExt(test, field);
        }
    }

    protected void injectByTypeExt(Object test, Field fieldToInject) {
        InjectIntoByTypeExt injectIntoByTypeAnnotation = fieldToInject.getAnnotation(InjectIntoByTypeExt.class);

        Object objectToInject = getObjectToInject(test, fieldToInject);
        Type objectToInjectType = getObjectToInjectType(test, fieldToInject);

        List<Object> targets = getTargets(InjectIntoByType.class, fieldToInject, injectIntoByTypeAnnotation.target(), test);
        for (Object target : targets) {
            try {
                InjectionUtils.injectIntoByType(objectToInject, objectToInjectType, target, PropertyAccess.FIELD);
            } catch (UnitilsException e) {
                throw new UnitilsException(getSituatedErrorMessage(InjectIntoByTypeExt.class, fieldToInject, e.getMessage()), e);
            }
        }
    }

    protected List<Object> getTargets(Class<? extends Annotation> annotationClass, Field annotatedField, String[] targetNames, Object test) {
        List<Object> targets = new ArrayList<Object>();
        if (targetNames == null || targetNames.length == 0) {
            // Default targetName, so it is probably not specified. Return all objects that are annotated with the TestedObject annotation.
            Set<Field> testedObjectFields = getFieldsAnnotatedWith(test.getClass(), TestedObject.class);
            for (Field testedObjectField : testedObjectFields) {
                Object target = getTarget(test, testedObjectField);
                targets.add(target);
            }
        } else {
            for (String targetName: targetNames) {
                Field field = getFieldWithName(test.getClass(), targetName, false);
                if (field == null) {
                    throw new UnitilsException(getSituatedErrorMessage(annotationClass, annotatedField, "Target with name " + targetName + " does not exist"));
                }
                Object target = getTarget(test, field);
                targets.add(target);
            }
        }
        return targets;
    }

}
