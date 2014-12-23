package com.pacificmetrics.orca.export.saaif;

import javax.xml.bind.annotation.adapters.XmlAdapter;

public class AdapterCDATA extends XmlAdapter<String, String> {

	public AdapterCDATA() {
		// TODO Auto-generated constructor stub
	}

	@Override
    public String marshal(String arg0) throws Exception {

		return arg0;
    }
    @Override
    public String unmarshal(String arg0) throws Exception {
        return arg0;
    }

}
