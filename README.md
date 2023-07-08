# Advent of beans

Advent of code clone built with redbean.
As of the time of writing it has the following features:
* Page listing all the puzzles
* Puzzle can have starting time
* Puzzle inputs are stored in buckets, some users will share a bucket
* Wrong answer submit timeout
* Leaderboard for everything & individual puzzles
* Silver and gold stars
* User profile page (for testing currently)

Todo list:
* Login with github oauth (or alternative)
* Don't use sqlite for storing answer times (this blocks and might fail), alternatives: PGSQL/redis/plain text in file system.
* Alternative method of storing leaderboard
* Better styling
* Custom paths/routing
* Rate limiting/DDOS protection
* Support multiple events
* The stats page