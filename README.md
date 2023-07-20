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
* No javascript

Todo list:
* Better styling
* Rate limiting/DDOS protection
* Support multiple events
* Generate all buckets when puzzle added, assign bucket to user by hashing user-id puzzle-name mod n-buckets
