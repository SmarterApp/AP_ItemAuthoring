package com.pacificmetrics.orca.export.ims;

import java.util.List;

import com.pacificmetrics.ims.apip.qti.item.Prompt;
import com.pacificmetrics.ims.apip.qti.item.SimpleChoice;

public interface IMSInteractionInf {
	
	public List<SimpleChoice> getSimpleChoices();
	public void setPrompt(Prompt value);
	
	
}
