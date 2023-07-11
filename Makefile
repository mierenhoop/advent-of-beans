all: dev

dev: /tmp/out.db
	./redbean.com -D.

/tmp/out.db:
	sqlite3 /tmp/out.db < schema.sql

.PHONY: clean

clean:
	rm /tmp/out.db*
