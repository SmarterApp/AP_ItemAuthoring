package com.pacificmetrics.orca.test;

import static java.lang.annotation.ElementType.FIELD;
import static java.lang.annotation.RetentionPolicy.RUNTIME;

import java.lang.annotation.Retention;
import java.lang.annotation.Target;

import org.unitils.inject.annotation.TestedObject;
import org.unitils.inject.util.PropertyAccess;

@Target(FIELD)
@Retention(RUNTIME)
public @interface InjectIntoByTypeExt {

    /**
     * The names of the fields that references the object to which the object in the annotated field should be injected.
     * If not specified, the target is defined by the field annotated with {@link TestedObject}
     *
     * @return the target field, null for tested object
     */
    String[] target() default {};

    /**
     * The property access that should be used for injection.
     *
     * @return the access type, not null
     */
    PropertyAccess propertyAccess() default PropertyAccess.DEFAULT;

}
