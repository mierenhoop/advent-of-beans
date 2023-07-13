all: dev

DB_FILE=/tmp/out.db

dev: $(DB_FILE)
	./redbean.com -D. -e'DB_FILE="$(DB_FILE)"'

$(DB_FILE):
	sqlite3 $@ < schema.sql

.PHONY: clean

clean:
	rm -f $(DB_FILE)*
