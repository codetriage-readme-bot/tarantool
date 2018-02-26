uuid = require('uuid')
test_run = require('test_run').new()

box.schema.user.grant('guest', 'replication')

-- gh-2991 - Tarantool asserts on box.cfg.replication update if one of
-- servers is dead
replication_timeout = box.cfg.replication_timeout
box.cfg{replication_timeout=0.05, replication={}}
box.cfg{replication = {'127.0.0.1:12345', box.cfg.listen}}
box.cfg{replication_timeout = replication_timeout}

-- gh-3111 - Allow to rebootstrap a replica from a read-only master
replica_uuid = uuid.new()
test_run:cmd('create server test with rpl_master=default, script="replication/replica_uuid.lua"')
test_run:cmd(string.format('start server test with args="%s"', replica_uuid))
test_run:cmd('stop server test')
test_run:cmd('cleanup server test')
box.cfg{read_only = true}
test_run:cmd(string.format('start server test with args="%s"', replica_uuid))
test_run:cmd('stop server test')
test_run:cmd('cleanup server test')
box.cfg{read_only = false}

-- gh-3160 - Send heartbeats if there are changes from a remote master only
test_run:cmd('create server test_timeout with rpl_master=default, script="replication/replica.lua"')
box.cfg{replication_timeout = 0.05}
test_run:cmd('start server test_timeout')
test_run:cmd('switch test_timeout')
test_run = require('test_run').new()
test_run:cmd(string.format('eval default "box.cfg{replication = \'%s\'}"', box.cfg.listen))
old_replication = box.cfg.replication
box.cfg{replication = {}}
box.cfg{replication_timeout = 0.05, replication = old_replication}
test_run:cmd('switch default')
fiber = require'fiber'
_ = box.schema.space.create('test_timeout'):create_index('pk')
for i = 0, 22 do box.space.test_timeout:replace({1}) fiber.sleep(0.01) end
box.info.replication[3].upstream.status
box.info.replication[3].upstream.message
test_run:cmd('stop server test_timeout')
test_run:cmd('cleanup server test_timeout')

box.schema.user.revoke('guest', 'replication')
