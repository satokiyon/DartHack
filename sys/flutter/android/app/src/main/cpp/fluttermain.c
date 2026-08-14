/* fluttermain.c
 * Flutter / Dart Port Entry Point & OS Initialization
 */

#include "hack.h"
#include "dlb.h"
#include <setjmp.h>

#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <pwd.h>
#ifndef O_RDONLY
#include <fcntl.h>
#endif

#include <android/log.h>
#define LOG_TAG "NetHackFlutter"
#define debuglog(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

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

staticfn boolean whoami(void);
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

void nethack_exit(int code)
{
	longjmp(env, code);
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
	(void)umask(0777 & ~FCMASK);

	// remove all dangling locks on startup in Flutter mobile environment
	remove_all_lock_files();

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
			int fq_save_fd = open(fq_save, O_RDONLY);
			size_t fq_save_length = 0;
			char *fq_save_contents = MAP_FAILED;
			if (fq_save_fd != -1) {
				struct stat sb;
				if (fstat(fq_save_fd, &sb) >= 0) {
					fq_save_length = sb.st_size;
					fq_save_contents = mmap(NULL, fq_save_length, PROT_READ, MAP_PRIVATE, fq_save_fd, 0);
				}
			}

			if (ge.early_raw_messages)
				raw_print("セーブファイルを復元中...");
			else
				pline("セーブファイルを復元中...");
			mark_synch();

			if (!dorecover(nhfp)) {
				debuglog("ERROR: dorecover failed for %s. Cleaning up and exiting...", fq_save);
				if (fq_save_contents != MAP_FAILED) munmap(fq_save_contents, fq_save_length);
				if (fq_save_fd != -1) close(fq_save_fd);
				(void) delete_savefile();
				(void) eraseoldlocks();
				unlock_file(HLOCK);
				clearlocks();
				exit_nhwindows("セーブデータの復元に失敗したため破損データを削除しました。次回起動時は新規ゲームから開始します。");
				return 0;
			}

			if (fq_save_contents != MAP_FAILED) {
				char *fq_save_backup = (char *)alloc(strlen(fq_save) + 4 + 1);
				if (fq_save_backup) {
					Sprintf(fq_save_backup, "%s.bak", fq_save);
					int fq_save_backup_fd = creat(fq_save_backup, FCMASK);
					if (fq_save_backup_fd != -1) {
						size_t written_total = 0;
						while (written_total < fq_save_length) {
							ssize_t written_just_now = write(fq_save_backup_fd, fq_save_contents + written_total, fq_save_length - written_total);
							if (written_just_now < 0) {
								if (errno == EINTR) continue;
								break;
							} else if (written_just_now == 0) {
								break;
							} else {
								written_total += written_just_now;
							}
						}
						close(fq_save_backup_fd);
					}
					free(fq_save_backup);
				}
				munmap(fq_save_contents, fq_save_length);
			}
			if (fq_save_fd != -1) close(fq_save_fd);

			resuming = TRUE;
#ifdef WIZARD
			if (!wizard && remember_wiz_mode)
				wizard = TRUE;
#endif
			check_special_room(FALSE);
			wd_message();

			if (discover || wizard)
			{
				if (y_n("セーブファイルを保持しますか？") == 'n')
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

staticfn boolean whoami(void)
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
		pline("スコアが記録されない探索モードです。");
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
