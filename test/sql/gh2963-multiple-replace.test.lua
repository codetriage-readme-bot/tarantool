-- gh-2963 - this test is a part of that ticket
-- The purpose is to ban an opportunity for user to create table with multiple
-- ON CONFLICT clauses for columns, user should be able to point it only to one
-- column. This test checks it.

test_run = require('test_run').new()

box.sql.execute('CREATE TABLE t1(a INT PRIMARY KEY, b INT UNIQUE ON CONFLICT REPLACE, c UNIQUE)')

box.sql.execute('CREATE TABLE t2(a INT PRIMARY KEY, b INT UNIQUE ON CONFLICT REPLACE, c UNIQUE ON CONFLICT REPLACE)')

box.sql.execute('DROP TABLE t1')
box.sql.execute('DROP TABLE t2')
