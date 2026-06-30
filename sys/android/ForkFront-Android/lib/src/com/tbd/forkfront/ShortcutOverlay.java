package com.tbd.forkfront;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.content.res.Configuration;
import android.preference.PreferenceManager;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnLongClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Spinner;



public class ShortcutOverlay
{
	private static final String[] EXT_COMMANDS = {
		"",
		"#adjust", "#annotate", "#apply", "#attributes", "#cast", "#chat", "#chronicle",
		"#close", "#force", "#invoke", "#jump", "#loot", "#monster", "#name", "#offer",
		"#open", "#overview", "#pay", "#pray", "#quaff", "#quit", "#read", "#rest",
		"#ride", "#rub", "#search", "#sit", "#surrender", "#takeoff", "#teleport",
		"#terrain", "#therecmdmenu", "#turn", "#untrap", "#version", "#wear", "#wield",
		"#wipe"
	};

	private NH_State mNHState;
	private boolean mShowShortcut;
	private boolean mHideForced;
	private boolean mAlwaysShow;
	private boolean mPortAlwaysShow;
	private boolean mLandAlwaysShow;
	private UI mUI;
	private int mPortLoc;
	private int mLandLoc;
	public int mOrientation;
	private int mOpacity;
	private int mRelSize;


	// ____________________________________________________________________________________
	public ShortcutOverlay(NH_State nhState)
	{
		mNHState = nhState;
	}

	// ____________________________________________________________________________________
	public void setContext(Activity context)
	{
		mOrientation = context.getResources().getConfiguration().orientation;
		mUI = new UI(context);
		mUI.updateVisibleState();
	}

	// ____________________________________________________________________________________
	public boolean isVisible()
	{
		return (mAlwaysShow || mShowShortcut) && !mHideForced;
	}

	// ____________________________________________________________________________________
	public void forceHide()
	{
		mHideForced = true;
		mUI.updateVisibleState();
	}

	// ____________________________________________________________________________________
	public void preferencesUpdated(SharedPreferences prefs)
	{
		mPortAlwaysShow = prefs.getBoolean("ovlShortcutPortAlways", false);
		mLandAlwaysShow = prefs.getBoolean("ovlShortcutLandAlways", false);
		mPortLoc = getGravity(prefs.getString("ovlShortcutPortLoc", "3"));
		mLandLoc = getGravity(prefs.getString("ovlShortcutLandLoc", "3"));
		mOpacity = prefs.getInt("ovlShortcutOpacity", 150);
		mRelSize = prefs.getInt("ovlShortcutSize", 5);
		mUI.setTransparent();
		mUI.updateSize();
		mUI.loadCommands(prefs);
		setOrientation(mOrientation);
	}

	// ____________________________________________________________________________________
	private int getGravity(String val)
	{
		int loc = Integer.parseInt(val);
		if(loc == 0)
			return Gravity.LEFT;
		if(loc == 1)
			return Gravity.CENTER;
		if(loc == 2)
			return Gravity.RIGHT;
		if(loc == 3)
			return Gravity.BOTTOM | Gravity.LEFT;
		if(loc == 4)
			return Gravity.BOTTOM;
		if(loc == 5)
			return Gravity.BOTTOM | Gravity.RIGHT;
		return Gravity.CENTER;
	}

	// ____________________________________________________________________________________
	public void setOrientation(int orientation)
	{
		mUI.setOrientation(orientation);
	}

	// ____________________________________________________________________________________
	public void updateVisibleState()
	{
		mHideForced = false;
		mUI.updateVisibleState();
	}



	// ____________________________________________________________________________________
	private class UI
	{
		private View mPanel;
		private Button[] mCmdButtons;
		private Activity mContext;
		private ColorStateList mDefaultTextColor;
		private String[] mCommands = new String[9];

		public UI(Activity context)
		{
			mContext = context;
			mPanel = context.findViewById(R.id.shortcut_ovl);

			mCmdButtons = new Button[9];
			mCmdButtons[0] = (Button)mPanel.findViewById(R.id.shortcut_btn0);
			mCmdButtons[1] = (Button)mPanel.findViewById(R.id.shortcut_btn1);
			mCmdButtons[2] = (Button)mPanel.findViewById(R.id.shortcut_btn2);
			mCmdButtons[3] = (Button)mPanel.findViewById(R.id.shortcut_btn3);
			mCmdButtons[4] = (Button)mPanel.findViewById(R.id.shortcut_btn4);
			mCmdButtons[5] = (Button)mPanel.findViewById(R.id.shortcut_btn5);
			mCmdButtons[6] = (Button)mPanel.findViewById(R.id.shortcut_btn6);
			mCmdButtons[7] = (Button)mPanel.findViewById(R.id.shortcut_btn7);
			mCmdButtons[8] = (Button)mPanel.findViewById(R.id.shortcut_btn8);

			mDefaultTextColor = mCmdButtons[0].getTextColors();

			for(int i = 0; i < 9; i++)
			{
				final int idx = i;
				mCmdButtons[i].setOnTouchListener(onTouch);
				mCmdButtons[i].setOnClickListener(new OnClickListener()
				{
					@Override
					public void onClick(View v)
					{
						String chars = mCommands[idx];
						if(chars != null && !chars.isEmpty())
						{
							if(chars.startsWith("#") && !chars.endsWith("\n") && !chars.endsWith("\\n"))
							{
								chars += "\\n";
							}
							Cmd.KeySequnece seq = new Cmd.KeySequnece(mNHState, chars, "");
							seq.execute(new Cmd.ExecuteFinishedHandler()
							{
								@Override
								public void onExecuteFinished()
								{
								}
							});
						}
						v.getBackground().setAlpha(mOpacity);
					}
				});
				mCmdButtons[i].setOnLongClickListener(new OnLongClickListener()
				{
					@Override
					public boolean onLongClick(View v)
					{
						showEditDialog(idx);
						return true;
					}
				});
			}

			setTransparent();
			updateSize();
		}

		public void loadCommands(SharedPreferences prefs)
		{
			mCommands[0] = prefs.getString("shortcut_btn_0", "i");
			mCommands[1] = prefs.getString("shortcut_btn_1", "/");
			mCommands[2] = prefs.getString("shortcut_btn_2", "#terrain");
			mCommands[3] = prefs.getString("shortcut_btn_3", "#therecmdmenu");
			mCommands[4] = prefs.getString("shortcut_btn_4", "#herecmdmenu");
			mCommands[5] = prefs.getString("shortcut_btn_5", "#attributes");
			mCommands[6] = prefs.getString("shortcut_btn_6", "#chronicle");
			mCommands[7] = prefs.getString("shortcut_btn_7", "#overview");
			mCommands[8] = prefs.getString("shortcut_btn_8", "#chat");

			updateButtonLabels();
		}

		private void updateButtonLabels()
		{
			for(int i = 0; i < 9; i++)
			{
				String cmd = mCommands[i];
				if(cmd == null)
					cmd = "";
				String label = cmd;
				if(label.length() > 4)
				{
					label = label.substring(0, 4);
				}
				mCmdButtons[i].setText(label);
			}
		}

		public void setOrientation(int orientation)
		{
			mOrientation = orientation;
			FrameLayout.LayoutParams params = (FrameLayout.LayoutParams)mPanel.getLayoutParams();
			if(orientation == Configuration.ORIENTATION_PORTRAIT)
			{
				params.gravity = mPortLoc;
				mAlwaysShow = mPortAlwaysShow;
			}
			else
			{
				params.gravity = mLandLoc;
				mAlwaysShow = mLandAlwaysShow;
			}
			mPanel.setVisibility(View.GONE);
			updateVisibleState();
		}

		public void updateVisibleState()
		{
			if(isVisible())
			{
				mPanel.setVisibility(View.VISIBLE);
			}
			else
			{
				mPanel.setVisibility(View.GONE);
			}
		}

		private final int OPAQUE = 0xff;

		private OnTouchListener onTouch = new OnTouchListener()
		{
			@Override
			public boolean onTouch(View v, MotionEvent event)
			{
				int action = event.getAction() & MotionEvent.ACTION_MASK;

				final float density = mContext.getResources().getDisplayMetrics().density;
				float margin = density * 18;
				float x = event.getX();
				float y = event.getY();
				boolean outside = x < -margin || y < -margin || x > v.getWidth() + margin || y > v.getHeight() + margin;

				if(action == MotionEvent.ACTION_DOWN)
					v.getBackground().setAlpha(OPAQUE);
				else if(action == MotionEvent.ACTION_UP || outside)
					v.getBackground().setAlpha(mOpacity);
				v.invalidate();

				return false;
			}
		};

		public void setTransparent()
		{
			for(Button b : mCmdButtons)
			{
				b.getBackground().setAlpha(mOpacity);
				if(mOpacity > 127)
					b.setTextColor(mDefaultTextColor);
				else
					b.setTextColor(0xffffffff);
			}
		}

		public void updateSize()
		{
			final float density = mContext.getResources().getDisplayMetrics().density;
			int scale = mRelSize > 0 ? 2 : 1;
			int size = (int)((50 + scale * mRelSize) * density + 0.5f);
			for(Button b : mCmdButtons)
			{
				b.getLayoutParams().width = size;
				b.getLayoutParams().height = size;
				b.requestLayout();
			}
		}

		private void showEditDialog(final int index)
		{
			AlertDialog.Builder builder = new AlertDialog.Builder(mContext);
			builder.setTitle("ショートカット設定");

			LinearLayout layout = new LinearLayout(mContext);
			layout.setOrientation(LinearLayout.VERTICAL);
			layout.setPadding(30, 20, 30, 20);

			final EditText input = new EditText(mContext);
			input.setText(mCommands[index]);
			layout.addView(input);

			final Spinner spinner = new Spinner(mContext);
			ArrayAdapter<String> adapter = new ArrayAdapter<>(mContext, android.R.layout.simple_spinner_item, EXT_COMMANDS);
			adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
			spinner.setAdapter(adapter);
			layout.addView(spinner);

			// Spinnerの選択時に入力フィールドに値を設定する
			spinner.setOnTouchListener(new OnTouchListener()
			{
				@Override
				public boolean onTouch(View v, MotionEvent event)
				{
					// ユーザーがタッチしたときのみイベントを拾うようにする（初期配置時の自動発火防止）
					return false;
				}
			});
			spinner.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener()
			{
				@Override
				public void onItemSelected(android.widget.AdapterView<?> parent, View view, int position, long id)
				{
					String selected = EXT_COMMANDS[position];
					if(!selected.isEmpty())
					{
						input.setText(selected);
					}
				}

				@Override
				public void onNothingSelected(android.widget.AdapterView<?> parent)
				{
				}
			});

			builder.setView(layout);

			builder.setPositiveButton("OK", new DialogInterface.OnClickListener()
			{
				@Override
				public void onClick(DialogInterface dialog, int which)
				{
					String value = input.getText().toString().trim();
					mCommands[index] = value;
					updateButtonLabels();

					// 保存
					SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(mContext);
					prefs.edit().putString("shortcut_btn_" + index, value).apply();
				}
			});
			builder.setNegativeButton("キャンセル", new DialogInterface.OnClickListener()
			{
				@Override
				public void onClick(DialogInterface dialog, int which)
				{
					dialog.cancel();
				}
			});

			builder.show();
		}
	}
}
