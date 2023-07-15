RELEASE_EXE=/tmp/aob.com
DB_FILE=/tmp/out.db

DEV_RUN_CMD=AOB_DB_FILE=$(DB_FILE) ./redbean.com -D.

all: dev

dev: $(DB_FILE)
	$(DEV_RUN_CMD) server

$(DB_FILE):
	$(DEV_RUN_CMD) init

$(RELEASE_EXE):
	cp redbean.com $@
	zip $@ .init.lua *.lua style.css schema.sql

release: $(RELEASE_EXE)

.PHONY: clean release $(RELEASE_EXE)

clean:
	rm -f $(RELEASE_EXE)
	rm -f $(DB_FILE) $(DB_FILE)-wal $(DB_FILE)-shm
