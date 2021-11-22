#ifndef SQLPARSER_H__
#define SQLPARSER_H__

#ifdef __cplusplus
extern "C" {
#endif

int parse_as_json(const char* sql, char** json);

#ifdef __cplusplus
}
#endif

#endif  // SQLPARSER_H__
