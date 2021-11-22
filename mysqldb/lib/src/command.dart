part of mysql.impl;

///
enum Command {
  sleep, // 0
  quit, // 1
  initDb, // 2
  query, // 3
  fieldList, // 4
  createDb, // 5
  dropDb, // 6
  refresh, // 7
  shutdown, // 8
  statistics, // 9
  processInfo, // 10
  connect, // 11
  processKill, // 12
  debug,
  ping,
  time, // 15 0x0f
  delayedInsert,
  changeUser,
  binlogDump,
  tableDump, // 19 0x13
  connectOut,
  registerSlave,
  stmtPrepare,
  stmtExecute,
  stmtSendLongData,
  stmtClose,
  stmtReset,
  setOption,
  stmtFetch,
  daemon,
  binlogDumpGtid,
  resetConnection,
}
