package com.tbd.forkfront;

import android.app.Activity;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.content.res.Configuration;
import android.view.Gravity;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.widget.Button;
import android.widget.FrameLayout;

public class DPadOverlay
{
	private NH_State mNHState;
	private boolean mShowDirectional;
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
	private MoveMode mMoveMode = MoveMode.NORMAL;

	// ____________________________________________________________________________________
	public void setMoveMode(MoveMode mode)
	{
		mMoveMode = mode;
		if(mUI != null)
			mUI.updateNumPadState();
	}

	// ____________________________________________________________________________________
	public DPadOverlay(NH_State nhState)
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
	public void showDirectional(boolean showDirectional)
	{
		mShowDirectional = showDirectional;
		mHideForced = false;
		mUI.updateVisibleState();
	}

	// ____________________________________________________________________________________
	public boolean isVisible()
	{
		return (mAlwaysShow || mShowDirectional) && !mHideForced;
	}

	// ____________________________________________________________________________________
	private boolean isNormalMode()
	{
		return mAlwaysShow && !mShowDirectional;
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
		mPortAlwaysShow = prefs.getBoolean("ovlPortAlways", false);
		mLandAlwaysShow = prefs.getBoolean("ovlLandAlways", false);
		mPortLoc = getGravity(prefs.getString("ovlPortLoc", "1"));
		mLandLoc = getGravity(prefs.getString("ovlLandLoc", "1"));
		mOpacity = prefs.getInt("ovlOpacity", 150);
		mRelSize = prefs.getInt("ovlSize", 0);
		mUI.setTransparent();
		mUI.updateSize();
		mUI.loadEnabledModes(prefs);
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
	public void updateNumPadState()
	{
		mUI.updateNumPadState();
	}

	// ____________________________________________________________________________________ //
	// 																						//
	// ____________________________________________________________________________________ //
	private class UI
	{
		private View mDPad;
		private View mExtra;
		private Button[] mButtons;
		private Activity mContext;
		private ColorStateList mDefaultTextColor;
		private boolean mLongClick;
		private java.util.List<MoveMode> mEnabledModes = new java.util.ArrayList<>();

		public UI(Activity context)
		{
			mContext = context;
			mDPad = context.findViewById(R.id.dpad);

			mButtons = new Button[12];
			mButtons[0] = (Button)mDPad.findViewById(R.id.dpad0);
			mButtons[1] = (Button)mDPad.findViewById(R.id.dpad1);
			mButtons[2] = (Button)mDPad.findViewById(R.id.dpad2);
			mButtons[3] = (Button)mDPad.findViewById(R.id.dpad3);
			mButtons[4] = (Button)mDPad.findViewById(R.id.dpad4);
			mButtons[5] = (Button)mDPad.findViewById(R.id.dpad5);
			mButtons[6] = (Button)mDPad.findViewById(R.id.dpad6);
			mButtons[7] = (Button)mDPad.findViewById(R.id.dpad7);
			mButtons[8] = (Button)mDPad.findViewById(R.id.dpad8);
			mButtons[9] = (Button)mDPad.findViewById(R.id.dpad9);
			mButtons[10] = (Button)mDPad.findViewById(R.id.dpad10);
			mButtons[11] = (Button)mDPad.findViewById(R.id.dpad_esc);
			
			mDefaultTextColor = mButtons[0].getTextColors();
			
			mExtra = (View)mButtons[11].getParent();
			
			for(Button b : mButtons)
			{
				b.setOnTouchListener(onDPadTouch);
				if (b.getId() == R.id.dpad4)
				{
					b.setOnClickListener(new OnClickListener()
					{
						@Override
						public void onClick(View v)
						{
							cycleMoveMode();
							v.getBackground().setAlpha(mOpacity);
						}
					});
					b.setOnLongClickListener(new View.OnLongClickListener()
					{
						@Override
						public boolean onLongClick(View v)
						{
							showModeSelectDialog();
							return true;
						}
					});
				}
				else
				{
					b.setOnClickListener(onDPad);
				}
			}

			// g<dir> on long press
			mButtons[0].setOnLongClickListener(onDPadLong);
			mButtons[1].setOnLongClickListener(onDPadLong);
			mButtons[2].setOnLongClickListener(onDPadLong);
			mButtons[3].setOnLongClickListener(onDPadLong);
			mButtons[5].setOnLongClickListener(onDPadLong);
			mButtons[6].setOnLongClickListener(onDPadLong);
			mButtons[7].setOnLongClickListener(onDPadLong);
			mButtons[8].setOnLongClickListener(onDPadLong);

			setTransparent();
			updateSize();
			updateNumPadState();
		}

		private String applyMoveMode(String baseDir)
		{
			if (mMoveMode == null || mMoveMode == MoveMode.NORMAL)
				return baseDir;
			
			switch (mMoveMode)
			{
				case UPPER:
					return baseDir.toUpperCase();
				case G_LOWER:
					return "g" + baseDir;
				case G_UPPER:
					return "G" + baseDir;
				case CTRL:
					return "^" + baseDir;
				case M_CMD:
					return "m" + baseDir;
				case F_CMD:
					return "F" + baseDir;
			}
			return baseDir;
		}

		// ____________________________________________________________________________________
		public void updateNumPadState()
		{
			if(mNHState.isNumPadOn())
			{
				mButtons[0].setText(applyMoveMode("7"));
				mButtons[1].setText(applyMoveMode("8"));
				mButtons[2].setText(applyMoveMode("9"));
				mButtons[3].setText(applyMoveMode("4"));
				mButtons[5].setText(applyMoveMode("6"));
				mButtons[6].setText(applyMoveMode("1"));
				mButtons[7].setText(applyMoveMode("2"));
				mButtons[8].setText(applyMoveMode("3"));
			}
			else
			{
				mButtons[0].setText(applyMoveMode("y"));
				mButtons[1].setText(applyMoveMode("k"));
				mButtons[2].setText(applyMoveMode("u"));
				mButtons[3].setText(applyMoveMode("h"));
				mButtons[5].setText(applyMoveMode("l"));
				mButtons[6].setText(applyMoveMode("b"));
				mButtons[7].setText(applyMoveMode("j"));
				mButtons[8].setText(applyMoveMode("n"));
			}

			// 中段中央 (dpad4) のテキストを更新
			String label = mMoveMode.getLabel();
			mButtons[4].setText(label);
			if(label.length() > 4)
			{
				mButtons[4].setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 8);
			}
			else if(label.length() > 2)
			{
				mButtons[4].setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 10);
			}
			else
			{
				mButtons[4].setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 14);
			}
		}

		public void loadEnabledModes(SharedPreferences prefs)
		{
			String raw = prefs.getString("dpad_enabled_move_modes", "NORMAL,UPPER,G_LOWER,G_UPPER,CTRL,M_CMD,F_CMD");
			mEnabledModes.clear();
			for(String name : raw.split(","))
			{
				try
				{
					mEnabledModes.add(MoveMode.valueOf(name.trim()));
				}
				catch(Exception e)
				{
					// Ignore invalid values
				}
			}
			if(mEnabledModes.isEmpty())
			{
				mEnabledModes.add(MoveMode.NORMAL);
			}

			// もし現在の mMoveMode が有効なリストになければ、切り替える
			if(!mEnabledModes.contains(mMoveMode))
			{
				setMoveMode(mEnabledModes.get(0));
			}
			else
			{
				updateNumPadState();
			}
		}

		private void saveEnabledModes()
		{
			SharedPreferences prefs = mContext.getSharedPreferences(mContext.getPackageName() + "_preferences", android.content.Context.MODE_PRIVATE);
			SharedPreferences.Editor editor = prefs.edit();
			StringBuilder sb = new StringBuilder();
			for(int i = 0; i < mEnabledModes.size(); i++)
			{
				sb.append(mEnabledModes.get(i).name());
				if(i + 1 < mEnabledModes.size())
					sb.append(",");
			}
			editor.putString("dpad_enabled_move_modes", sb.toString());
			editor.commit();
		}

		private void showModeSelectDialog()
		{
			final MoveMode[] allModes = MoveMode.values();
			final String[] labels = new String[allModes.length];
			final boolean[] checked = new boolean[allModes.length];

			for(int i = 0; i < allModes.length; i++)
			{
				labels[i] = allModes[i].getLabel();
				checked[i] = mEnabledModes.contains(allModes[i]);
			}

			android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(mContext);
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
					mEnabledModes.clear();
					for(int i = 0; i < allModes.length; i++)
					{
						if(checked[i])
						{
							mEnabledModes.add(allModes[i]);
						}
					}
					if(mEnabledModes.isEmpty())
					{
						mEnabledModes.add(MoveMode.NORMAL);
					}

					saveEnabledModes();

					if(!mEnabledModes.contains(mMoveMode))
					{
						setMoveMode(mEnabledModes.get(0));
					}
					else
					{
						updateNumPadState();
					}
				}
			});
			builder.setNegativeButton("キャンセル", null);
			builder.show();
		}

		private void cycleMoveMode()
		{
			if(mEnabledModes.isEmpty())
			{
				mEnabledModes.add(MoveMode.NORMAL);
			}

			int idx = mEnabledModes.indexOf(mMoveMode);
			int nextIdx = (idx + 1) % mEnabledModes.size();
			setMoveMode(mEnabledModes.get(nextIdx));
		}

		// ____________________________________________________________________________________
		public void setOrientation(int orientation)
		{
			mOrientation = orientation;
			FrameLayout.LayoutParams params = (FrameLayout.LayoutParams)mDPad.getLayoutParams();
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
			mDPad.setVisibility(View.GONE);
			updateVisibleState();
		}

		// ____________________________________________________________________________________
		private void updateVisibleState()
		{
			if(isVisible())
			{
				if(mShowDirectional)
					setDirectionalMode();
				else
					setNormalMode();
				mDPad.setVisibility(View.VISIBLE);
			}
			else
				mDPad.setVisibility(View.GONE);
		}

		// ____________________________________________________________________________________
		private void setNormalMode()
		{
			mExtra.setVisibility(View.GONE);
			updateNumPadState();
		}

		// ____________________________________________________________________________________
		private void setDirectionalMode()
		{
			mExtra.setVisibility(View.VISIBLE);
			updateNumPadState();
		}

		private final int OPAQUE = 0xff;
		
		// ____________________________________________________________________________________
		private OnTouchListener onDPadTouch = new OnTouchListener()
		{
			@Override
			public boolean onTouch(View v, MotionEvent event)
			{
				int action = event.getAction() & MotionEvent.ACTION_MASK;

				if(action == MotionEvent.ACTION_DOWN)
					mLongClick = false;

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

		private int getBaseKeyChar(View v)
		{
			int id = v.getId();
			if (id == R.id.dpad0) return mNHState.isNumPadOn() ? '7' : 'y';
			if (id == R.id.dpad1) return mNHState.isNumPadOn() ? '8' : 'k';
			if (id == R.id.dpad2) return mNHState.isNumPadOn() ? '9' : 'u';
			if (id == R.id.dpad3) return mNHState.isNumPadOn() ? '4' : 'h';
			if (id == R.id.dpad4) return mNHState.isNumPadOn() ? '.' : ' ';
			if (id == R.id.dpad5) return mNHState.isNumPadOn() ? '6' : 'l';
			if (id == R.id.dpad6) return mNHState.isNumPadOn() ? '1' : 'b';
			if (id == R.id.dpad7) return mNHState.isNumPadOn() ? '2' : 'j';
			if (id == R.id.dpad8) return mNHState.isNumPadOn() ? '3' : 'n';
			if (id == R.id.dpad9) return '<';
			if (id == R.id.dpad10) return '>';
			return 0;
		}

		private void sendMoveModeKey(int baseKey)
		{
			if (mMoveMode == null || mMoveMode == MoveMode.NORMAL)
			{
				mNHState.sendKeyCmd(baseKey);
				return;
			}

			switch (mMoveMode)
			{
				case UPPER:
					if (mNHState.isNumPadOn()) {
						mNHState.sendKeyCmd(getRunCmd(baseKey));
					} else {
						mNHState.sendKeyCmd(Character.toUpperCase(baseKey));
					}
					break;
				case G_LOWER:
					mNHState.sendKeyCmd('g');
					mNHState.sendKeyCmd(baseKey);
					break;
				case G_UPPER:
					mNHState.sendKeyCmd('G');
					mNHState.sendKeyCmd(baseKey);
					break;
				case CTRL:
					if (mNHState.isNumPadOn()) {
						mNHState.sendKeyCmd(getCtrlCmd(baseKey));
					} else {
						mNHState.sendKeyCmd((char)(baseKey - 'a' + 1));
					}
					break;
				case M_CMD:
					mNHState.sendKeyCmd('m');
					mNHState.sendKeyCmd(baseKey);
					break;
				case F_CMD:
					mNHState.sendKeyCmd('F');
					mNHState.sendKeyCmd(baseKey);
					break;
			}
		}

		private int getCtrlCmd(int dir)
		{
			switch(dir) {
				case '4': return 'h' - 'a' + 1;
				case '6': return 'l' - 'a' + 1;
				case '8': return 'k' - 'a' + 1;
				case '2': return 'j' - 'a' + 1;
				case '7': return 'y' - 'a' + 1;
				case '9': return 'u' - 'a' + 1;
				case '1': return 'b' - 'a' + 1;
				case '3': return 'n' - 'a' + 1;
			}
			return '\033';
		}

		// ____________________________________________________________________________________
		private OnClickListener onDPad = new OnClickListener()
		{
			@Override
			public void onClick(View v)
			{
				if (v.getId() == R.id.dpad_esc) {
					mNHState.sendKeyCmd('\033');
					v.getBackground().setAlpha(mOpacity);
					return;
				}

				int baseKey = getBaseKeyChar(v);
				if (baseKey == ' ') {
					mNHState.clickCursorPos();
					v.getBackground().setAlpha(mOpacity);
					return;
				}

				boolean isDirKey = false;
				int id = v.getId();
				if (id == R.id.dpad0 || id == R.id.dpad1 || id == R.id.dpad2 ||
					id == R.id.dpad3 || id == R.id.dpad5 || id == R.id.dpad6 ||
					id == R.id.dpad7 || id == R.id.dpad8) {
					isDirKey = true;
				}

				if (!isDirKey) {
					mNHState.sendKeyCmd(baseKey);
					v.getBackground().setAlpha(mOpacity);
					return;
				}

				if (mNHState.isYnQuestionActive()) {
					mNHState.sendKeyCmd(baseKey);
					mLongClick = false;
					v.getBackground().setAlpha(mOpacity);
					return;
				}

				if (mLongClick) {
					mNHState.sendKeyCmd('g');
					mNHState.sendKeyCmd(baseKey);
				} else {
					sendMoveModeKey(baseKey);
				}

				mLongClick = false;
				v.getBackground().setAlpha(mOpacity);
			}
		};

		// ____________________________________________________________________________________
		private int getRunCmd(int dir)
		{
			switch(dir) {
				case '4': case 'h': return 'H';
				case '6': case 'l': return 'L';
				case '8': case 'k': return 'K';
				case '2': case 'j': return 'J';
				case '7': case 'y': return 'Y';
				case '9': case 'u': return 'U';
				case '1': case 'b': return 'B';
				case '3': case 'n': return 'N';
			}
			return '\033';
		}

		// ____________________________________________________________________________________
		private View.OnLongClickListener onDPadLong = new View.OnLongClickListener()
		{
			@Override
			public boolean onLongClick(View v)
			{
				if(isNormalMode())
				{
					if(mNHState.isMouseLocked())
					{
						// Only cursor will be moved. Execute immediately
						int k = getBaseKeyChar(v);
						k = getRunCmd(k);
						mNHState.sendKeyCmd(k);
						return true;
					}

					// Don't execute run command until button is released. Gives the player a chance to abort
					mLongClick = true;
					v.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
				}
				return false;
			}
		};

		// ____________________________________________________________________________________
		private void setTransparent()
		{
			for(Button b : mButtons)
			{
				b.getBackground().setAlpha(mOpacity);
				if(mOpacity > 127)
					b.setTextColor(mDefaultTextColor);
				else
					b.setTextColor(0xffffffff);
			}
		}

		// ____________________________________________________________________________________
		private void updateSize()
		{
			final float density = mContext.getResources().getDisplayMetrics().density;
			int scale = mRelSize > 0 ? 2 : 1;
			int size = (int)((50 + scale * mRelSize) * density + 0.5f);
			for(Button b : mButtons)
			{
				b.getLayoutParams().width = size;
				b.getLayoutParams().height = size;
				b.requestLayout();
			}
		}
	}
}
