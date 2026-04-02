///|
using @uv {type Errno}

///|
/// 为一次同步文件系统操作创建并托管独立 libuv Loop。
fn[T] with_loop(f : (@uv.Loop) -> T raise) -> T raise {
  let uv = @uv.Loop::new()
  try {
    let result = f(uv)
    uv.close()
    result
  } catch {
    err => {
      let _ = try? uv.close()
      raise err
    }
  }
}

///|
/// 判断路径是否存在，用于材料和输出目录检查。
pub fn path_exists(path : String) -> Bool raise {
  let target = normalize_path(path)
  with_loop((uv : @uv.Loop) => {
    try {
      ignore(uv.fs_stat_sync(@utf8.encode(target)))
      true
    } catch {
      Errno::ENOENT => false
      err => raise err
    }
  })
}

///|
/// 递归确保目录存在，是所有写文件操作的前置步骤。
pub fn ensure_dir(path : String) -> Unit raise {
  let target = normalize_path(path)
  if target == "" || target == "." || target == "/" {
    return
  }
  let absolute = target.has_prefix("/")
  let parts = split_path(target)
  with_loop((uv : @uv.Loop) => {
    let mut current = if absolute { "/" } else { "" }
    for part in parts {
      current = if current == "" || current == "/" {
        current + part
      } else {
        current + "/" + part
      }
      try {
        let stat = uv.fs_stat_sync(@utf8.encode(current))
        if !stat.is_directory() {
          raise Failure::Failure(
            "Path exists but is not a directory: \{current}",
          )
        }
      } catch {
        Errno::ENOENT => uv.fs_mkdir_sync(@utf8.encode(current), 0o755)
        err => raise err
      }
    }
  })
}

///|
/// 以 UTF-8 文本方式完整读取一个文件。
pub fn read_text(path : String) -> String raise {
  let target = normalize_path(path)
  with_loop((uv : @uv.Loop) => {
    let file = uv.fs_open_sync(
      @utf8.encode(target),
      @uv.OpenFlags::read_only(),
      0o644,
    )
    try {
      let stat = uv.fs_stat_sync(@utf8.encode(target))
      let size = stat.size().to_int()
      if size == 0 {
        uv.fs_close_sync(file)
        return ""
      }
      let buffer = Bytes::make(size, 0)
      let read_count = uv.fs_read_sync(file, [buffer])
      uv.fs_close_sync(file)
      @utf8.decode_lossy(buffer[0:read_count])
    } catch {
      err => {
        let _ = try? uv.fs_close_sync(file)
        raise err
      }
    }
  })
}

///|
/// 在文件缺失时返回 None，避免调用方显式处理 ENOENT。
pub fn read_text_if_exists(path : String) -> String? raise {
  Some(read_text(path)) catch {
    Errno::ENOENT => None
    err => raise err
  }
}

///|
/// 以 UTF-8 文本方式覆盖写入一个文件。
pub fn write_text(path : String, content : String) -> Unit raise {
  let target = normalize_path(path)
  ensure_dir(dirname(target))
  with_loop((uv : @uv.Loop) => {
    let file = uv.fs_open_sync(
      @utf8.encode(target),
      @uv.OpenFlags::write_only(create=true, truncate=true),
      0o644,
    )
    try {
      let bytes = @utf8.encode(content)
      uv.fs_write_sync(file, [bytes])
      uv.fs_close_sync(file)
    } catch {
      err => {
        let _ = try? uv.fs_close_sync(file)
        raise err
      }
    }
  })
}
