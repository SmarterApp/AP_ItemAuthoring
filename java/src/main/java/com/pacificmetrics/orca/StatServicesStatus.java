package com.pacificmetrics.orca;

import com.pacificmetrics.common.Status;

public class StatServicesStatus extends Status {

    protected StatServicesStatus(String name) {
        super(name);
    }

    static public StatServicesStatus IMPORT_BAD_FILE_FORMAT = new StatServicesStatus("Error.PsychometricsImport.BadFileFormat");
    static public StatServicesStatus IMPORT_UNKNOWN_FIELD = new StatServicesStatus("Error.PsychometricsImport.UnknownField");
    static public StatServicesStatus IMPORT_INCORRECT_NUMBER_OF_VALUES = new StatServicesStatus("IMPORT_INCORRECT_NUMBER_OF_VALUES");
    static public StatServicesStatus IMPORT_ITEM_NOT_FOUND = new StatServicesStatus("Error.PsychometricsImport.ItemNotFound");
    static public StatServicesStatus IMPORT_WRONG_ITEM_BANK = new StatServicesStatus("Error.PsychometricsImport.WrongItemBank");
    static public StatServicesStatus IMPORT_INVALID_NUMBER = new StatServicesStatus("Error.PsychometricsImport.InvalidNumber");

}
