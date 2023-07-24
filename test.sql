INSERT INTO user(rowid, name, gh_id, gh_auth) VALUES
(1, '1', '', ''),
(2, '2', '', ''),
(3, '3', '', ''),
(4, '4', '', '');

INSERT INTO achievement(user_id, puzzle, time, type) VALUES
(1, '01', 10, 'silver'),
(2, '01', 15, 'silver'),
(1, '01', 20, 'gold'),
(1, '02', 30, 'silver'),
(2, '02', 35, 'silver'),
(1, '02', 40, 'gold')
;

INSERT INTO user_puzzle(user_id, puzzle, bucket_id) VALUES
(1, '01', 0),
(2, '01', 0),
(1, '02', 0),
(2, '02', 0)
;


INSERT INTO puzzle (name, time_start, part1, part2, gen_code) VALUES (
  '01', 0, '
<p>Add one to input</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>10</code>.</p>','
<p>Add two to input</p>
<p>With the same input as before, the answer would be <code>10</code>.</p>', '
  local n = math.random(998)
  return n, n + 1, n + 2
'), (
  '02', 10, '
<p>Multiply by four</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>36</code>.</p>','
<p>Multiply by 5</p>
<p>With the same input as before, the answer would be <code>45</code>.</p>', '
  local n = math.random(100, 249)
  return n, n * 4, n * 5');
