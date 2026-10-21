/* fluttermain.c
 * Flutter / Dart Port Entry Point & OS Initialization
 */

#include "flutter_compat.h"
#include "hack.h"
#include "dlb.h"
#include <setjmp.h>

#include <errno.h>
#ifndef O_RDONLY
#include <fcntl.h>
#endif

#define LOG_TAG "NetHackFlutter"
#ifdef FLUTTER_ANDROID
#define debuglog(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#elif defined(FLUTTER_WIN32)
static void win32_debuglog(const char *fmt, ...) {
    char buf[2048];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    OutputDebugStringA(buf);
    OutputDebugStringA("\n");
}
#define debuglog(...) win32_debuglog(__VA_ARGS__)
#else
#define debuglog(...) do {} while(0)
#endif

extern int g_language_is_jp;

void set_username(void) {
    if (!*svp.plname) {
        Strcpy(svp.plname, "player");
    }
}

static jmp_buf env;

extern struct passwd *getpwuid(uid_t);
extern struct passwd *getpwnam(const char *);
extern int eraseoldlocks(void);
extern boolean getlock_failed(void);

boolean whoami(void);
staticfn void process_options(int, char **);
staticfn void wd_message(void);

void get_nhuuid(void) {
#ifdef NHUUID
    if (svn.nhuuid[0]) return;
    char struuid[sizeof svn.nhuuid] = {0};
    uuid_t binuuid;
    uuid_generate_random(binuuid);
    uuid_unparse(binuuid, struuid);
    if (struuid[0]) memcpy(svn.nhuuid, struuid, sizeof svn.nhuuid);
#endif
}

void free_nhuuid(void) {
    memset(&svn.nhuuid, 0, sizeof svn.nhuuid);
}

static char *make_lockname(const char *filename, char *lockname)
{
#  ifdef NO_FILE_LINKS
	Strcpy(lockname, LOCKDIR);
	Strcat(lockname, "/");
	Strcat(lockname, filename);
#  else
	Strcpy(lockname, filename);
#  endif
	Strcat(lockname, "_lock");
	return lockname;
}

void remove_lock_file(const char *filename)
{
	char locknambuf[BUFSZ];
	const char *lockname;

	lockname = make_lockname(filename, locknambuf);
	unlink(lockname);
}

void remove_all_lock_files(void)
{
	remove_lock_file(RECORD);
	remove_lock_file(HLOCK);
#ifdef LOGFILE
	remove_lock_file(LOGFILE);
#endif
#ifdef XLOGFILE
	remove_lock_file(XLOGFILE);
#endif
#ifdef LIVELOGFILE
	remove_lock_file(LIVELOGFILE);
#endif
#ifdef PANICLOG
	remove_lock_file(PANICLOG);
#endif
}

#ifdef exit
#undef exit
#endif
#ifdef nethack_exit
#undef nethack_exit
#endif
void nethack_exit(int code)
{
	longjmp(env, code);
}

static void backup_savefile(const char *src_path) {
    char dst_path[BUFSZ];
    snprintf(dst_path, sizeof(dst_path), "%s.bak", src_path);
    FILE *in = fopen(src_path, "rb");
    if (!in) return;
    FILE *out = fopen(dst_path, "wb");
    if (!out) {
        fclose(in);
        return;
    }
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
        fwrite(buf, 1, n, out);
    }
    fclose(in);
    fclose(out);
}

int NetHackMain(int argc, char** argv)
{
	debuglog("Starting NetHack Flutter!");

	int val;

	val = setjmp(env);
	if(val)
	{
		debuglog("exiting...");
		return 0;
	}

	NHFILE *nhfp;
	FILE* fp;

    boolean resuming = FALSE; /* assume new game */

    early_init(argc, argv);

	gh.hname = argv[0];
	svh.hackpid = getpid();
#ifdef FLUTTER_WIN32
	_set_fmode(_O_BINARY);
	debuglog("fluttermain: _set_fmode(_O_BINARY) configured");
#else
	// Android / Flutter 環境ではプロセス全体で Dart VM / Flutter エンジンと同居するため、
	// ディレクトリの実行権限 (x) を奪う 0777 & ~FCMASK (0117) ではなく、
	// Android/POSIX 標準の安全な 0022 (dir: 0755, file: 0644) を設定する。
	(void)umask(0022);
	debuglog("fluttermain: umask safely configured to 0022");
#ifdef FLUTTER_ANDROID
	__android_log_print(ANDROID_LOG_INFO, "DartHack", "[C-Core] fluttermain: umask safely configured to 0022");
#endif
#endif

	// remove all dangling locks on startup in Flutter mobile environment
	remove_all_lock_files();

	// Migration: record_jp が存在し、record がまだ無い場合は record_jp を record に自動リネームして移行
	const char* fq_rec = fqname(RECORD, SCOREPREFIX, 0);
	FILE* test_rec = fopen(fq_rec, "r");
	if (test_rec) {
		fclose(test_rec);
	} else {
		const char* fq_rec_jp = fqname("record_jp", SCOREPREFIX, 0);
		FILE* test_rec_jp = fopen(fq_rec_jp, "r");
		if (test_rec_jp) {
			fclose(test_rec_jp);
			rename(fq_rec_jp, fq_rec);
			debuglog("Migrated record_jp to unified record file.");
		}
	}

	// make sure RECORD exists
	fp = fopen_datafile(RECORD, "a", SCOREPREFIX);
	if (fp) fclose(fp);

	debuglog("STEP 1: choose_windows starting...");
	choose_windows(DEFAULT_WINDOW_SYS);

	debuglog("STEP 1.1: initoptions starting...");
	initoptions();
	debuglog("STEP 1.2: initoptions done. Calling init_nhwindows...");

	init_nhwindows(&argc, argv);
	debuglog("STEP 1.3: init_nhwindows done. Calling process_options & plnamesuffix...");

	/*
	 * It seems you really want to play.
	 */
	u.uhp = 1; /* prevent RIP on early quits */

	process_options(argc, argv); /* command line options */

#ifdef DEF_PAGER
	if(!(catmore = nh_getenv("HACKPAGER")) && !(catmore = nh_getenv("PAGER")))
	catmore = DEF_PAGER;
#endif

    gp.plnamelen = 0;
    debuglog("STEP 4: calling plnamesuffix()... (svp.plname='%s')", svp.plname);
	plnamesuffix(); /* strip suffix from name; calls askname() */
    debuglog("STEP 4: plnamesuffix() done. svp.plname='%s'", svp.plname);

#ifdef WIZARD
	if(!wizard)
#endif
	set_username();

	Sprintf(gl.lock, "%d%s", (int)getuid(), svp.plname);
	debuglog("STEP 5: calling getlock() with lock='%s'...", gl.lock);
	getlock();
	if (getlock_failed()) {
		debuglog("STEP 5: getlock failed (recovery failed/impossible). Exiting NetHackMain...");
		return 0;
	}
	debuglog("STEP 5: getlock() done.");

	/* Set up level 0 file to keep the game state.
	 */
	debuglog("STEP 6: calling create_levelfile(0)...");
	nhfp = create_levelfile(0, (char *)0);
	if(!nhfp)
	{
		debuglog("STEP 6 ERROR: create_levelfile(0) failed!");
		raw_print("ロックファイルを作成できません");
	}
	else
	{
		svh.hackpid = 1;
		Sfo_int(nhfp, &svh.hackpid, "svh.hackpid");
		close_nhfile(nhfp);
	}
	debuglog("STEP 6: create_levelfile done.");

	debuglog("STEP 7: calling dlb_init()...");
	dlb_init(); /* must be before newgame() */
	debuglog("STEP 7: dlb_init() done.");

	/*
	 * Initialization of the boundaries of the mazes
	 * Both boundaries have to be even.
	 */
	gx.x_maze_max = COLNO - 1;
	if(gx.x_maze_max % 2)
		gx.x_maze_max--;
	gy.y_maze_max = ROWNO - 1;
	if(gy.y_maze_max % 2)
		gy.y_maze_max--;

	/*
	 * Initialize the vision system.
	 */
	vision_init();

	init_sound_disp_gamewindows();

	set_savefile_name(TRUE);
	if ((nhfp = restore_saved_game()) != 0)
	{
		const char *fq_save = fqname(gs.SAVEF, SAVEPREFIX, 1);
		debuglog("STEP 8: restore_saved_game SUCCESS (%s)! Resuming game...", fq_save);
#ifdef WIZARD
			boolean remember_wiz_mode = wizard;
#endif
			if (ge.early_raw_messages)
				raw_print(g_language_is_jp ? "セーブファイルを復元中..." : "Restoring save file...");
			else
				pline(g_language_is_jp ? "セーブファイルを復元中..." : "Restoring save file...");
			mark_synch();

			if (!dorecover(nhfp)) {
				debuglog("ERROR: dorecover failed for %s. Cleaning up and exiting...", fq_save);
				(void) delete_savefile();
				(void) eraseoldlocks();
				unlock_file(HLOCK);
				clearlocks();
				exit_nhwindows(g_language_is_jp ? "セーブデータの復元に失敗したため破損データを削除しました。次回起動時は新規ゲームから開始します。" : "Failed to restore save file. Damaged save data has been removed.");
				return 0;
			}

			backup_savefile(fq_save);

			resuming = TRUE;
#ifdef WIZARD
			if (!wizard && remember_wiz_mode)
				wizard = TRUE;
#endif
			check_special_room(FALSE);
			wd_message();

			if (discover || wizard)
			{
				if (y_n(g_language_is_jp ? "セーブファイルを保持しますか？" : "Keep saved game?") == 'n')
				{
					(void)delete_savefile();
				}
				else
				{
					nh_compress(fq_save);
				}
			}
		}
	else
	{
		debuglog("STEP 9: Savefile does not exist. Calling player_selection()...");
		player_selection();
		debuglog("STEP 9: player_selection() done. Calling newgame()...");
		resuming = FALSE;
		newgame();
		debuglog("STEP 9: newgame() done.");
		wd_message();
	}

	moveloop(resuming);
    exit(EXIT_SUCCESS);

	return (0);
}

boolean authorize_wizard_mode(void)
{
	return TRUE;
}

boolean authorize_explore_mode(void)
{
    return TRUE;
}

staticfn void process_options(int argc, char *argv[])
{
	int i;

	while(argc > 1 && argv[1][0] == '-')
	{
		argv++;
		argc--;
		switch(argv[0][1])
		{
		case 'D':
			wizard = TRUE;
		break;
		case 'X':
			discover = TRUE;
		break;
		case 'u':
			if(!*svp.plname)
			{
				if(argv[0][2])
					(void)strncpy(svp.plname, argv[0] + 2, sizeof(svp.plname) - 1);
				else if(argc > 1)
				{
					argc--;
					argv++;
					(void)strncpy(svp.plname, argv[0], sizeof(svp.plname) - 1);
				}
			}
		break;
		case 'p':
			if(argv[0][2])
			{
				if((i = str2role(&argv[0][2])) >= 0)
					flags.initrole = i;
			}
			else if(argc > 1)
			{
				argc--;
				argv++;
				if((i = str2role(argv[0])) >= 0)
					flags.initrole = i;
			}
		break;
		case 'r':
			if(argv[0][2])
			{
				if((i = str2race(&argv[0][2])) >= 0)
					flags.initrace = i;
			}
			else if(argc > 1)
			{
				argc--;
				argv++;
				if((i = str2race(argv[0])) >= 0)
					flags.initrace = i;
			}
		break;
		case '@':
			flags.randomall = 1;
		break;
		default:
			if((i = str2role(&argv[0][1])) >= 0)
			{
				flags.initrole = i;
				break;
			}
		}
	}
}

#ifdef CHDIR
void chdirx(const char *dir, boolean wr) {
    if (!dir) goto exit;
    if (chdir(dir) < 0) {
        perror(dir);
        goto exit;
    }
    return;
exit:
    error("Cannot chdir to %s.", dir);
}
#endif

boolean whoami(void)
{
	register char *s;

	if(*svp.plname)
		return FALSE;
	if((s = getlogin()))
		(void)strncpy(svp.plname, s, sizeof(svp.plname) - 1);
	return TRUE;
}

staticfn void wd_message(void)
{
	if(discover)
		pline(g_language_is_jp ? "スコアが記録されない探索モードです。" : "You are in explore mode; your score will not be saved.");
}

void append_slash(char *name)
{
	char *ptr;

	if(!*name)
		return;
	ptr = name + (strlen(name) - 1);
	if(*ptr != '/')
	{
		*++ptr = '/';
		*++ptr = '\0';
	}
	return;
}

unsigned long sys_random_seed(void)
{
    unsigned long seed = 0L;
    unsigned long pid = (unsigned long) getpid();
    boolean no_seed = TRUE;
#ifdef DEV_RANDOM
    FILE *fptr;

    fptr = fopen(DEV_RANDOM, "r");
    if (fptr) {
        fread(&seed, sizeof (long), 1, fptr);
        has_strong_rngseed = TRUE;
        no_seed = FALSE;
        (void) fclose(fptr);
    } else {
        paniclog("sys_random_seed", "falling back to weak seed");
    }
#endif
    if (no_seed) {
        seed = (unsigned long) getnow();
        if (pid) {
            if (!(pid & 3L))
                pid -= 1L;
            seed *= pid;
        }
    }
    return seed;
}
