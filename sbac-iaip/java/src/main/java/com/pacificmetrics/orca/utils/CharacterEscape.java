package com.pacificmetrics.orca.utils;

import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;

import com.sun.xml.bind.marshaller.CharacterEscapeHandler;

public class CharacterEscape implements CharacterEscapeHandler {

	public CharacterEscape() {
		// TODO Auto-generated constructor stub
	}

	@Override
	public void escape(char[] ch, int start, int length, boolean isAttVal,
			Writer out) throws IOException {
		StringWriter buffer = new StringWriter();

		for (int i = start; i < start + length; i++) {
			buffer.write(ch[i]);
		}

		String st = buffer.toString();

		if (!st.contains("CDATA")) {
			st = buffer.toString().replace("&", "&amp;").replace("<", "&lt;")
					.replace(">", "&gt;").replace("'", "&apos;")
					.replace("\"", "&quot;");

		}
		out.write(st);

	}

}
