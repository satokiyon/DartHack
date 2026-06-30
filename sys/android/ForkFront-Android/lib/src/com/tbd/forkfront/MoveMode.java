package com.tbd.forkfront;

public enum MoveMode {
	NORMAL("標準"),
	UPPER("大文字"),
	G_LOWER("g"),
	G_UPPER("G"),
	CTRL("^(Ctrl)"),
	M_CMD("m"),
	F_CMD("F");

	private final String label;
	MoveMode(String label) {
		this.label = label;
	}
	public String getLabel() {
		return label;
	}
}
