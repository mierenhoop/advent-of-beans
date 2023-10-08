include .env
export

RELEASE_EXE=/tmp/aob.com
DB_FILE=/tmp/out.db
AOB_DB_FILE=$(DB_FILE)

DEV_RUN_CMD=./redbean.com -D.

AOB_SOURCES=.init.lua about.lua events.lua index.lua leaderboard.lua \
			login.lua logout.lua profile.lua puzzle-answer.lua \
			puzzle-index.lua puzzle-input.lua puzzle-leaderboard.lua \
			puzzle-submit.lua stats.lua updateprofile.lua schema.sql \
			style.css test.sql

all: dev

test:
	$(DEV_RUN_CMD) -s server

dev: $(DB_FILE)
	$(DEV_RUN_CMD) server

$(DB_FILE):
	$(DEV_RUN_CMD) init

$(RELEASE_EXE):
	cp redbean.com $@
	zip $@ $(AOB_SOURCES)

release: $(RELEASE_EXE)

.PHONY: clean release $(RELEASE_EXE)

clean:
	rm -f $(RELEASE_EXE)
	rm -f $(DB_FILE) $(DB_FILE)-wal $(DB_FILE)-shm
