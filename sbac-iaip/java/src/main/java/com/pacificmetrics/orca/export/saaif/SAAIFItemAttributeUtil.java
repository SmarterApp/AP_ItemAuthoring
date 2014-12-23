package com.pacificmetrics.orca.export.saaif;

import java.util.Arrays;
import java.util.List;

public class SAAIFItemAttributeUtil {

    private SAAIFItemAttributeUtil() {
    }

    public static String getResponseType(String itemFormat) {
        if ("EBSR".equalsIgnoreCase(itemFormat)) {
            return "EBSR";
        } else if ("EQ".equalsIgnoreCase(itemFormat)) {
            return "EquationEditor";
        } else if ("NL".equalsIgnoreCase(itemFormat)
                || "SA".equalsIgnoreCase(itemFormat)
                || "ER".equalsIgnoreCase(itemFormat)) {
            return "PlainText";
        } else if ("GI".equalsIgnoreCase(itemFormat)) {
            return "Grid";
        } else if ("HT".equalsIgnoreCase(itemFormat)) {
            return "HotText";
        } else if ("MC".equalsIgnoreCase(itemFormat)) {
            // alternate type Stacked
            return "Vertical";
        } else if ("MI".equalsIgnoreCase(itemFormat)) {
            // alternate type TableMatch
            return "MatchItem";
        } else if ("TI".equalsIgnoreCase(itemFormat)) {
            return "TableInput";
        } else if ("MS".equalsIgnoreCase(itemFormat)) {
            return "Vertical MS";
        } else if ("WER".equalsIgnoreCase(itemFormat)) {
            return "HTMLEditor";
        } else if ("WORDLIST".equalsIgnoreCase(itemFormat)
                || "TUT".equalsIgnoreCase(itemFormat)
                || "SIM".equalsIgnoreCase(itemFormat)
                || "PASS".equalsIgnoreCase(itemFormat)) {
            return "NA";
        } else {
            return null;
        }
    }

    public static String getPageLayout(String itemFormat) {
        if ("EBSR".equalsIgnoreCase(itemFormat)) {
            return "21";
        } else if ("EQ".equalsIgnoreCase(itemFormat)) {
            // alternate is 21
            return "8";
        } else if ("NL".equalsIgnoreCase(itemFormat)) {
            // alternate is 8
            return "21";
        } else if ("SA".equalsIgnoreCase(itemFormat)) {
            // alternate is 21
            return "8";
        } else if ("ER".equalsIgnoreCase(itemFormat)) {
            // alternates are 1,8,29
            return "21";
        } else if ("GI".equalsIgnoreCase(itemFormat)) {
            // alternates are 21,22
            return "8";
        } else if ("HT".equalsIgnoreCase(itemFormat)) {
            // alternate is 8
            return "21";
        } else if ("MC".equalsIgnoreCase(itemFormat)) {
            // alternate is 8
            return "21";
        } else if ("MI".equalsIgnoreCase(itemFormat)) {
            // alternate is 8,21
            return "1";
        } else if ("TI".equalsIgnoreCase(itemFormat)) {
            return "13";
        } else if ("MS".equalsIgnoreCase(itemFormat)) {
            // alternate is 8
            return "21";
        } else if ("WER".equalsIgnoreCase(itemFormat)) {
            return "21";
        } else if ("WORDLIST".equalsIgnoreCase(itemFormat)
                || "TUT".equalsIgnoreCase(itemFormat)
                || "SIM".equalsIgnoreCase(itemFormat)
                || "PASS".equalsIgnoreCase(itemFormat)) {
            return null;
        } else {
            return null;
        }
    }

    public static String getAnswerKey(String itemFormat) {
        List formats = Arrays.asList("EBSR", "EQ", "NL", "SA", "ER", "GI",
                "HT", "MI", "TI", "WER", "WORDLIST", "TUT", "SIM", "PASS");
        if (formats.contains(itemFormat)) {
            return itemFormat;
        } else {
            return null;
        }
    }
}
