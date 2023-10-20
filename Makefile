include .env
export

RELEASE_EXE=/tmp/aob.com
AOB_DB_FILE=/tmp/out.db

AOB_SOURCES=.init.lua about.lua events.lua index.lua leaderboard.lua \
			login.lua logout.lua profile.lua puzzle-answer.lua \
			puzzle-index.lua puzzle-input.lua puzzle-leaderboard.lua \
			puzzle-submit.lua stats.lua updateprofile.lua schema.sql \
			style.css test.sql

all: dev

bench: $(RELEASE_EXE)
	$(RELEASE_EXE) -s

dev: $(RELEASE_EXE)
	$(RELEASE_EXE)

make-admin:
	# TODO: don't hardcode id
	$(RELEASE_EXE) -e "db=lsqlite3.open('$(AOB_DB_FILE)')" \
		           -e "db:exec[[UPDATE user SET admin = TRUE WHERE rowid = 5]]" \
				   -e "db:close() unix.exit(0)"

$(RELEASE_EXE):
	cp redbean.com $@
	zip $@ $(AOB_SOURCES)

release: $(RELEASE_EXE)

.PHONY: clean release $(RELEASE_EXE) make-admin

clean:
	rm -f $(RELEASE_EXE)
	rm -f $(AOB_DB_FILE) $(AOB_DB_FILE)-wal $(AOB_DB_FILE)-shm
