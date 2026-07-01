package com.tbd.forkfront;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.OnSharedPreferenceChangeListener;
import android.os.Build;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.preference.PreferenceCategory;
import android.preference.PreferenceScreen;
import android.view.Window;
import com.tbd.forkfront.TilesetPreference;

@SuppressWarnings("deprecation") // android.preference.PreferenceActivity クラス全体が非推奨のため抑制
public class Settings extends PreferenceActivity implements OnSharedPreferenceChangeListener
{
	private TilesetPreference mTilesetPref;
	private ExportPreferences mExportPreferences;
	private ImportPreferences mImportPreferences;
	// ____________________________________________________________________________________
	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		// turn off the window's title bar
		requestWindowFeature(Window.FEATURE_NO_TITLE);

		super.onCreate(savedInstanceState);

		addPreferencesFromResource(R.xml.preferences);
	}

	// ____________________________________________________________________________________
	@Override
	protected void onResume()
	{
		super.onResume();

		SharedPreferences sharedPreferences = getPreferenceScreen().getSharedPreferences();

		for(int i = 0; i < 10; i++)
		{
			char idx = (char)('0' + i);
			Preference screen = findPreference("panel" + idx);

			if(screen == null)
				break;

			String name = sharedPreferences.getString("pName" + idx, "");

			screen.setTitle(name);
		}

		sharedPreferences.registerOnSharedPreferenceChangeListener(this);

		mTilesetPref = (TilesetPreference)findPreference("tilesetPreference");
		mTilesetPref.setActivity(this);
		mExportPreferences = (ExportPreferences)findPreference("exportPreferences");
		mExportPreferences.setActivity(this);
		mImportPreferences = (ImportPreferences)findPreference("importPreferences");
		mImportPreferences.setActivity(this);

		if(!getApplicationContext().getResources().getBoolean(R.bool.hearseAvailable))
		{
			PreferenceCategory hearseParent = (PreferenceCategory)findPreference("advanced");
			Preference hearsePref = findPreference("hearse");
			if(hearsePref != null)
				hearseParent.removePreference(hearsePref);
		}

		// Immersive mode only available on API 11 and up
		PreferenceCategory settingsCategory = (PreferenceCategory)findPreference("settings");
		if(Build.VERSION.SDK_INT < Build.VERSION_CODES.HONEYCOMB)
		{
			Preference fullscreenPref = findPreference("immersive");
			if(fullscreenPref != null)
				settingsCategory.removePreference(fullscreenPref);
		}

		Preference moveModesPref = findPreference("ovlMoveModes");
		if(moveModesPref != null)
		{
			moveModesPref.setOnPreferenceClickListener(new Preference.OnPreferenceClickListener()
			{
				@Override
				public boolean onPreferenceClick(Preference preference)
				{
					showMoveModesSelectDialog();
					return true;
				}
			});
		}
	}

	// ____________________________________________________________________________________
	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data)
	{
		super.onActivityResult(requestCode, resultCode, data);
		if (mTilesetPref.onActivityResult(requestCode, resultCode, data)) return;
		if (mExportPreferences.onActivityResult(requestCode, resultCode, data)) return;
		if (mImportPreferences.onActivityResult(requestCode, resultCode, data)) return;
	}

	// ____________________________________________________________________________________
	@Override
	protected void onPause()
	{
		super.onPause();
		getPreferenceScreen().getSharedPreferences().unregisterOnSharedPreferenceChangeListener(this);
	}

	// ____________________________________________________________________________________
	@Override
	public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key)
	{
		if(key.startsWith("pName"))
		{
			char idx = key.charAt(key.length() - 1);
			Preference screen = findPreference("panel" + idx);
			String name = sharedPreferences.getString("pName" + idx, "");
			screen.setTitle(name);
		}
	}

	private void showMoveModesSelectDialog()
	{
		final String[] rawModes = {"NORMAL", "UPPER", "G_LOWER", "G_UPPER", "CTRL", "M_CMD", "F_CMD"};
		final String[] labels = {"標準", "大文字", "g", "G", "^(Ctrl)", "m", "F"};
		final boolean[] checked = new boolean[rawModes.length];

		final SharedPreferences prefs = getPreferenceScreen().getSharedPreferences();
		String raw = prefs.getString("dpad_enabled_move_modes", "NORMAL,UPPER,G_LOWER,G_UPPER,CTRL,M_CMD,F_CMD");
		final java.util.List<String> enabledList = new java.util.ArrayList<>();
		for(String s : raw.split(","))
		{
			enabledList.add(s.trim());
		}

		for(int i = 0; i < rawModes.length; i++)
		{
			checked[i] = enabledList.contains(rawModes[i]);
		}

		android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
		builder.setTitle("使用する移動モードの選択");
		builder.setMultiChoiceItems(labels, checked, new android.content.DialogInterface.OnMultiChoiceClickListener()
		{
			@Override
			public void onClick(android.content.DialogInterface dialog, int which, boolean isChecked)
			{
				checked[which] = isChecked;
			}
		});

		builder.setPositiveButton("OK", new android.content.DialogInterface.OnClickListener()
		{
			@Override
			public void onClick(android.content.DialogInterface dialog, int which)
			{
				StringBuilder sb = new StringBuilder();
				boolean first = true;
				for(int i = 0; i < rawModes.length; i++)
				{
					if(checked[i])
					{
						if(!first) sb.append(",");
						sb.append(rawModes[i]);
						first = false;
					}
				}
				if(sb.length() == 0)
				{
					sb.append("NORMAL");
				}

				SharedPreferences.Editor editor = prefs.edit();
				editor.putString("dpad_enabled_move_modes", sb.toString());
				editor.commit();
			}
		});
		builder.setNegativeButton("キャンセル", null);
		builder.show();
	}
}
