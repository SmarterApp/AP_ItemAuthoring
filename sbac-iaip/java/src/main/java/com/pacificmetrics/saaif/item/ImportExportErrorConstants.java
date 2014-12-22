package com.pacificmetrics.saaif.item;

public class ImportExportErrorConstants {

    private ImportExportErrorConstants() {
    }

    public static final String ERROR_RLBACK_PROGRESS = "Package Import status is 'In Progress'. Unable to rollback package: ";
    public static final String SUCCESS_RLBACK = "Successfully rollback package ";
    public static final String FAILED_RLBACK = "Unable to rollabck package";
    public static final String PASSAGE_UNIQUE = "Passage with name \"<passageName>\" already exists for the program: <programName>.  Passage \"<passageId>\" cannot be imported.";

}
