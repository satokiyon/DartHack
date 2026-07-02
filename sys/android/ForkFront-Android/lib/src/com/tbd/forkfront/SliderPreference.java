/* The following code was written by Matthew Wiggins 
 * and is released under the APACHE 2.0 license 
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 */
package com.tbd.forkfront;

import android.content.Context;
import androidx.preference.DialogPreference;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

public class SliderPreference extends DialogPreference
{
	private static final String androidns = "http://schemas.android.com/apk/res/android";
	private static final String thisns = "forkfront";

	private String mDialogMessage, mSuffix;
	private int mDefault, mMin, mMax, mValue;

	public SliderPreference(Context context, AttributeSet attrs)
	{
		super(context, attrs);

		mDialogMessage = attrs.getAttributeValue(androidns, "dialogMessage");
		mSuffix = attrs.getAttributeValue(androidns, "text");
		mDefault = attrs.getAttributeIntValue(androidns, "defaultValue", 0);
		mMin = attrs.getAttributeIntValue(thisns, "min", 0);
		mMax = attrs.getAttributeIntValue(androidns, "max", 100);
	}

	public String getDialogMessage() { return mDialogMessage; }
	public String getSuffix() { return mSuffix; }
	public int getDefaultVal() { return mDefault; }
	public int getMin() { return mMin; }
	public int getMax() { return mMax; }
	
	public int getPersistedValue()
	{
		return getPersistedInt(mDefault);
	}

	public void setValue(int value)
	{
		mValue = value;
		persistInt(value);
	}

	@Override
	protected Object onGetDefaultValue(android.content.res.TypedArray a, int index)
	{
		return a.getInt(index, 0);
	}

	@Override
	protected void onSetInitialValue(boolean restore, Object defaultValue)
	{
		if(restore)
		{
			mValue = getPersistedInt(mDefault);
		}
		else
		{
			mValue = (Integer)defaultValue;
			persistInt(mValue);
		}
	}

	public static class SliderPreferenceDialogFragment extends androidx.preference.PreferenceDialogFragmentCompat implements SeekBar.OnSeekBarChangeListener
	{
		private SeekBar mSeekBar;
		private TextView mSplashText, mValueText;
		private int mValue;

		public static SliderPreferenceDialogFragment newInstance(String key)
		{
			SliderPreferenceDialogFragment fragment = new SliderPreferenceDialogFragment();
			android.os.Bundle b = new android.os.Bundle(1);
			b.putString(ARG_KEY, key);
			fragment.setArguments(b);
			return fragment;
		}

		@Override
		protected View onCreateDialogView(Context context)
		{
			SliderPreference pref = (SliderPreference) getPreference();
			int min = pref.getMin();
			int max = pref.getMax();
			String dialogMessage = pref.getDialogMessage();

			LinearLayout.LayoutParams params;
			LinearLayout layout = new LinearLayout(context);
			layout.setOrientation(LinearLayout.VERTICAL);
			layout.setPadding(6, 6, 6, 6);

			mSplashText = new TextView(context);
			if(dialogMessage != null)
				mSplashText.setText(dialogMessage);
			layout.addView(mSplashText);

			mValueText = new TextView(context);
			mValueText.setGravity(Gravity.CENTER_HORIZONTAL);
			mValueText.setTextSize(32);
			params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
			layout.addView(mValueText, params);

			mValue = pref.getPersistedValue();

			mSeekBar = new SeekBar(context);
			mSeekBar.setMax(max - min);
			mSeekBar.setProgress(mValue - min);
			mSeekBar.setOnSeekBarChangeListener(this);
			layout.addView(mSeekBar, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));

			updateValueText();

			return layout;
		}

		@Override
		protected void onBindDialogView(View v)
		{
			super.onBindDialogView(v);
			SliderPreference pref = (SliderPreference) getPreference();
			int min = pref.getMin();
			int max = pref.getMax();
			mSeekBar.setMax(max - min);
			mSeekBar.setProgress(mValue - min);
		}

		private void updateValueText()
		{
			SliderPreference pref = (SliderPreference) getPreference();
			String suffix = pref.getSuffix();
			String t = String.valueOf(mValue);
			mValueText.setText(suffix == null ? t : t.concat(suffix));
		}

		@Override
		public void onProgressChanged(SeekBar seek, int progress, boolean fromTouch)
		{
			SliderPreference pref = (SliderPreference) getPreference();
			int min = pref.getMin();
			mValue = progress + min;
			updateValueText();
		}

		@Override
		public void onStartTrackingTouch(SeekBar seek) {}

		@Override
		public void onStopTrackingTouch(SeekBar seek) {}

		@Override
		public void onDialogClosed(boolean positiveResult)
		{
			if (positiveResult)
			{
				SliderPreference pref = (SliderPreference) getPreference();
				if (pref.callChangeListener(mValue))
				{
					pref.setValue(mValue);
				}
			}
		}
	}
}
