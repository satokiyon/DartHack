#include "hack.h"

extern void debuglog(const char *fmt, ...);
extern boolean recover_savefile(void);

#include <errno.h>
#include <sys/stat.h>
#if defined(NO_FILE_LINKS) || defined(SUNOS4) || defined(POSIX_TYPES)
#include <fcntl.h>
#endif

static struct stat buf;

void regularize(char *s)
{
	register char *lp;

	while((lp=strchr(s, '.')) || (lp=strchr(s, '/')) || (lp=strchr(s,' ')) || (lp=strchr(s,':')))
		*lp = '_';
}

int eraseoldlocks(void)
{
	register int i;

	for(i = 1; i <= MAXDUNGEON*MAXLEVEL + 1; i++) {
		set_levelfile_name(gl.lock, i);
		(void) unlink(fqname(gl.lock, LEVELPREFIX, 0));
	}
	set_levelfile_name(gl.lock, 0);
	if (unlink(fqname(gl.lock, LEVELPREFIX, 0)))
		return(0);
	return(1);
}

static boolean g_getlock_failed = FALSE;

boolean getlock_failed(void)
{
	return g_getlock_failed;
}

void getlock(void)
{
	register int i = 0, fd, c;
	const char *fq_lock;

	g_getlock_failed = FALSE;

	if (!lock_file(HLOCK, LOCKPREFIX, 10))
	{
		wait_synch();
		error("%s", "");
	}

	regularize(gl.lock);
	set_levelfile_name(gl.lock, 0);

	fq_lock = fqname(gl.lock, LEVELPREFIX, 0);
	if((fd = open(fq_lock, 0)) == -1)
	{
		if(errno == ENOENT)
			goto gotlock;
		perror(fq_lock);
		unlock_file(HLOCK);
		error("Cannot open %s", fq_lock);
	}
	(void) close(fd);

	if(!recover_savefile())
	{
		(void) eraseoldlocks();
		unlock_file(HLOCK);
		g_getlock_failed = TRUE;
		exit_nhwindows("セーブデータの復元に失敗したため破損データを削除しました。次回起動時は新規ゲームから開始します。");
		return;
	}

gotlock:
	(void) eraseoldlocks();
	fd = creat(fq_lock, FCMASK);
	unlock_file(HLOCK);
	if(fd == -1)
	{
		error("cannot creat lock file (%s).", fq_lock);
	}
	else
	{
		if(write(fd, (genericptr_t) &svh.hackpid, sizeof(svh.hackpid)) != sizeof(svh.hackpid))
		{
			error("cannot write lock (%s)", fq_lock);
		}
		if(close(fd) == -1)
		{
			error("cannot close lock (%s)", fq_lock);
		}
	}
}

boolean
file_exists(const char *path)
{
	struct stat stbuf;

	return (boolean) (stat(path, &stbuf) == 0);
}

boolean
check_user_string(const char *optstr)
{
	int pwlen;
	const char *eop, *w;
	char *pwname = svp.plname;

	if (!*optstr)
		return FALSE;
	if (optstr[0] == '*')
		return TRUE; /* allow any user */
	if (!pwname || !*pwname)
		return FALSE;
	pwlen = (int) strlen(pwname);
	eop = eos((char *) optstr);
	w = optstr;
	while (w + pwlen <= eop) {
		if (!*w)
			break;
		if (!strncmpi(w, pwname, pwlen)
		    && (w[pwlen] == ',' || w[pwlen] == '\0'))
			return TRUE;
		while (*w && *w != ',')
			w++;
		if (*w == ',')
			w++;
	}
	return FALSE;
}

/* Missing Unix / Terminal Compatibility Stubs for Flutter Port */
void sethanguphandler(void (*f)(int)) { (void)f; }
void introff(void) {}
void intron(void) {}
int child(int x) { (void)x; return 0; }
void more(void) {}
void linux_mapon(void) {}
void linux_mapoff(void) {}
void win_tty_init(void) {}
int dosh(void) { return 0; }

#ifndef NETHACK_JP
boolean recover_savefile(void) { return FALSE; }
#endif

