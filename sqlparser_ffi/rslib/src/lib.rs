extern crate serde_json;
extern crate sqlparser;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use sqlparser::{dialect, parser::Parser};

#[no_mangle]
pub extern "C" fn parse_as_json(
  // dialect: *const c_char,
  sql: *const c_char,
  json: *mut *mut c_char,
) -> isize {
  if json.is_null() {
    return libc::EINVAL as isize;
  }

  let csql = unsafe { CStr::from_ptr(sql) };

  // let s = CString::new("hello").unwrap();
  // unsafe {
  //   return s.into_raw();
  // }

  let dialect = dialect::GenericDialect {};

  let parse_result = Parser::parse_sql(&dialect, csql.to_str().unwrap());

  match parse_result {
    Ok(statements) => {
      let serialized = serde_json::to_string_pretty(&statements).unwrap();

      let m = unsafe { libc::malloc(1 + serialized.len()) as *mut c_char };
      if m.is_null() {
        return libc::ENOMEM as isize;
      }

      let s = CString::new(serialized).unwrap();

      unsafe {
        *json = m;
        libc::strcpy(*json, s.as_ptr());
      };

      0
    }
    Err(_) => -1,
  }
}

#[cfg(test)]
mod tests {
  #[test]
  fn it_works() {
    let result = 2 + 2;
    assert_eq!(result, 4);
  }
}
