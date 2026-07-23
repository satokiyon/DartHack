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

	choose_windows(DEFAULT_WINDOW_SYS);

	initoptions();

	init_nhwindows(&argc, argv);

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
	plnamesuffix(); /* strip suffix from name; calls askname() */

#ifdef WIZARD
	if(!wizard)
#endif
	set_username();

	Sprintf(gl.lock, "%d%s", (int)getuid(), svp.plname);
	getlock();

	/* Set up level 0 file to keep the game state.
	 */
	nhfp = create_levelfile(0, (char *)0);
	if(!nhfp)
	{
		raw_print("ロックファイルを作成できません");
	}
	else
	{
		svh.hackpid = 1;
		Sfo_int(nhfp, &svh.hackpid, "svh.hackpid");
		close_nhfile(nhfp);
	}

	dlb_init(); /* must be before newgame() */

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

	if((nhfp = restore_saved_game()) != 0)
	{
#ifdef WIZARD
		boolean remember_wiz_mode = wizard;
#endif
		const char *fq_save = fqname(gs.SAVEF, SAVEPREFIX, 1);
		int fq_save_fd = open(fq_save, O_RDONLY);
		if (fq_save_fd == -1) {
			debuglog("failed to open save file: %s", strerror(errno));
			goto backup_error;
		}
		struct stat sb;
		if (fstat(fq_save_fd, &sb) < 0) {
			debuglog("failed to stat save file: %s", strerror(errno));
			goto backup_error;
		}
		size_t fq_save_length = sb.st_size;
		char *fq_save_contents = mmap(NULL, fq_save_length, PROT_READ, MAP_PRIVATE, fq_save_fd, 0);
		if (fq_save_contents == MAP_FAILED) {
			debuglog("failed to mmap save file: %s", strerror(errno));
			goto backup_error;
		} else goto backup_clean;
backup_error:
		debuglog("WARNING: failed to make a backup save file.");
backup_clean:
		if (fq_save_fd != -1) close(fq_save_fd);

        if (ge.early_raw_messages)
            raw_print("セーブファイルを復元中...");
        else
            pline("セーブファイルを復元中...");
		mark_synch();
		if(!dorecover(nhfp)) {
			pline("セーブファイルの復元に失敗しました。");
			goto not_recovered;
		}
		if (fq_save_contents) {
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
		resuming = TRUE;
#ifdef WIZARD
		if(!wizard && remember_wiz_mode)
			wizard = TRUE;
#endif
		check_special_room(FALSE);
		wd_message();

		if(discover || wizard)
		{
			if(y_n("セーブファイルを保持しますか？") == 'n')
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
		not_recovered: player_selection();
		resuming = FALSE;
		newgame();
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
