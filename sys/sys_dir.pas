unit sys_dir;

{$mode ObjFPC}{$H+}

interface

uses
 Windows,
 Classes,
 SysUtils,
 RWLock,
 sys_kernel,
 sys_time,
 sys_fd;

const
 // File types
 DT_UNKNOWN= 0; //The type is unknown.
 DT_FIFO   = 1; //A named pipe, or FIFO.
 DT_CHR    = 2; //A character device.
 DT_DIR    = 4; //A directory.
 DT_BLK    = 6; //A block device.
 DT_REG    = 8; //A regular file.
 DT_LNK    =10; //A symbolic link.
 DT_SOCK   =12; //A local-domain socket.
 DT_WHT    =14; //

type
 p_dirent=^dirent;
 dirent=packed object
  Const
   MAXNAMLEN=255;
  Var
   d_fileno:DWORD; // file number of entry
   d_reclen:WORD;  // length of this record
   d_type  :BYTE;  // file type, see below
   d_namlen:BYTE;  // length of string in d_name
   d_name  :array[0..MAXNAMLEN] of AnsiChar; //name must be no longer than this
 end;

function _sys_dir_open(const path:RawByteString;flags,mode:Integer):Integer;
function _sys_dir_stat(Const path:RawByteString;stat:PSceKernelStat):Integer;

implementation

type
 a_dirent=array of dirent;

 TDirFile=class(TCustomFile)
  var
   lock:TRWLock;
   path:RawByteString;
   dirs:a_dirent;
   pos:DWORD;
  Constructor Create;
  Destructor  Destroy; override;
  function read  (data:Pointer;size:Int64):Int64;                      override;
  function pread (data:Pointer;size,offset:Int64):Int64;               override;
  function readv (vector:p_iovec;count:Integer):Int64;                 override;
  function write (data:Pointer;size:Int64):Int64;                      override;
  function pwrite(data:Pointer;size,offset:Int64):Int64;               override;
  function fstat (stat:PSceKernelStat):Integer;                        override;
  function lseek (offset:Int64;whence:Integer):Int64;                  override;
  function getdirentries(buf:Pointer;nbytes:Int64;basep:PInt64):Int64; override;
 end;

function get_d_type(dwFileAttributes:DWORD):BYTE;
begin
 if (dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY)<>0 then
 begin
  Result:=DT_DIR;
 end else
 begin
  Result:=DT_REG;
 end;
end;

procedure move_dirent(id:DWORD;src:PWIN32FindDataW;buf:Pointer);
var
 p:p_dirent;
 f:RawByteString;
 len:ptruint;
begin
 f:=UTF8Encode(WideString(src^.cFileName));
 len:=Length(f);
 if (len>dirent.MAXNAMLEN) then len:=dirent.MAXNAMLEN;

 Inc(len);
 SetLength(f,len);
 f[len]:=#0;

 p:=buf;
 p^.d_fileno:=id;
 p^.d_reclen:=SizeOf(dirent);
 p^.d_type  :=get_d_type(src^.dwFileAttributes);
 p^.d_namlen:=BYTE(len-1);

 Move(PChar(f)^,p^.d_name,len);
end;

function get_dir_wp(const path:RawByteString):WideString;
begin
 Result:=UTF8Decode(IncludeTrailingPathDelimiter(path)+'*');
end;

function _sys_dir_open(const path:RawByteString;flags,mode:Integer):Integer;
var
 f:TDirFile;
 h:THandle;
 err:DWORD;
 wp:WideString;
 data:TWIN32FindDataW;
 tmp:dirent;
 i:Integer;
begin
 Result:=0;

 wp:=get_dir_wp(path);

 data:=Default(TWIN32FindDataW);
 h:=FindFirstFileW(PWideChar(wp),data);

 err:=0;
 if (h=INVALID_HANDLE_VALUE) then
 begin
  err:=GetLastError;
  Case err of
   ERROR_INVALID_DRIVE,
   ERROR_PATH_NOT_FOUND   :Exit(-ENOENT);
   ERROR_ACCESS_DENIED    :Exit(-EACCES);
   ERROR_BUFFER_OVERFLOW  :Exit(-ENAMETOOLONG);
   ERROR_NOT_ENOUGH_MEMORY:Exit(-ENOMEM);
   ERROR_DISK_FULL        :Exit(-ENOSPC);
   ERROR_NO_MORE_FILES,
   ERROR_FILE_NOT_FOUND   :;
   else
                           Exit(-EIO);
  end;
 end;

 f:=TDirFile.Create;
 f.path:=path;

 if (h<>INVALID_HANDLE_VALUE) then
 begin
  tmp:=Default(dirent);
  move_dirent(0,@data,@tmp);

  SetLength(f.dirs,1);
  f.dirs[0]:=tmp;

  repeat
   if FindNextFileW(h,data) then
   begin
    tmp:=Default(dirent);

    i:=Length(f.dirs);
    move_dirent(i,@data,@tmp);

    i:=Length(f.dirs);
    SetLength(f.dirs,i+1);
    f.dirs[i]:=tmp;
   end else
   begin
    err:=GetLastError;
    Case err of
     ERROR_NO_MORE_FILES,
     ERROR_FILE_NOT_FOUND:
      begin
       Break;
      end;
     else
      begin
       Windows.FindClose(h);
       f.Destroy;
       Exit(-EIO);
      end;
    end;
   end;
  until false;
  Windows.FindClose(h);
 end;

 Result:=_sys_open_fd(f);

 if (Result<0) then
 begin
  f.Destroy;
 end else
 begin
  f.Release;
 end;
end;

function _sys_dir_stat(Const path:RawByteString;stat:PSceKernelStat):Integer;
var
 hfi:WIN32_FILE_ATTRIBUTE_DATA;
 err:DWORD;
begin
 stat^:=Default(SceKernelStat);

 hfi:=Default(WIN32_FILE_ATTRIBUTE_DATA);
 err:=SwGetFileAttributes(path,@hfi);
 if (err<>0) then
 begin
  Case err of
   ERROR_ACCESS_DENIED,
   ERROR_SHARING_VIOLATION,
   ERROR_LOCK_VIOLATION,
   ERROR_SHARING_BUFFER_EXCEEDED:
     Exit(EACCES);

   ERROR_BUFFER_OVERFLOW:
     Exit(ENAMETOOLONG);

   ERROR_NOT_ENOUGH_MEMORY:
     Exit(ENOMEM);

   else
     Exit(ENOENT);
  end;
 end;

 stat^.st_mode    :=S_IFDIR;
 stat^.st_size    :=hfi.nFileSizeLow or (QWORD(hfi.nFileSizeHigh) shl 32);
 stat^.st_nlink   :=1;

 stat^.st_atim    :=filetime_to_timespec(hfi.ftLastAccessTime);
 stat^.st_mtim    :=filetime_to_timespec(hfi.ftLastWriteTime);
 stat^.st_ctim    :=stat^.st_mtim;
 stat^.st_birthtim:=filetime_to_timespec(hfi.ftCreationTime);

 stat^.st_blocks  :=0;
 stat^.st_blksize :=SizeOf(dirent);

 Result:=0;
end;

//

Constructor TDirFile.Create;
begin
 pos:=0;
 Handle:=INVALID_HANDLE_VALUE;
 rwlock_init(lock);
 dirs:=Default(a_dirent);
end;

Destructor  TDirFile.Destroy;
begin
 dirs:=Default(a_dirent);
 rwlock_destroy(lock);
end;

function TDirFile.read  (data:Pointer;size:Int64):Int64;
begin
 Result:=-EISDIR;
end;

function TDirFile.pread (data:Pointer;size,offset:Int64):Int64;
begin
 Result:=-EISDIR;
end;

function TDirFile.readv (vector:p_iovec;count:Integer):Int64;
begin
 Result:=-EISDIR;
end;

function TDirFile.write (data:Pointer;size:Int64):Int64;
begin
 Result:=-EISDIR;
end;

function TDirFile.pwrite(data:Pointer;size,offset:Int64):Int64;
begin
 Result:=-EISDIR;
end;

function TDirFile.fstat (stat:PSceKernelStat):Integer;
begin
 Result:=_sys_dir_stat(path,stat);
 if (Result=0) then
 begin
  stat^.st_dev :=fd;
  stat^.st_rdev:=fd;
 end;
end;

function TDirFile.lseek (offset:Int64;whence:Integer):Int64;
begin
 rwlock_wrlock(lock);
 case whence of
  SEEK_SET:
   begin
    if (offset>=0) then
    begin
     pos:=offset;
     Result:=offset;
    end else
    begin
     Result:=-EINVAL;
    end;
   end;
  SEEK_CUR:
   begin
    offset:=offset+pos;
    if (offset>=0) then
    begin
     pos:=offset;
     Result:=offset;
    end else
    begin
     Result:=-EINVAL;
    end;
   end;
  SEEK_END:
   begin
    offset:=offset+Length(dirs);
    if (offset>=0) then
    begin
     pos:=offset;
     Result:=offset;
    end else
    begin
     Result:=-EINVAL;
    end;
   end;
  else
   Result:=-EINVAL;
  end;
 rwlock_unlock(lock);
end;

function TDirFile.getdirentries(buf:Pointer;nbytes:Int64;basep:PInt64):Int64;
var
 i,count:DWORD;
begin
 count:=nbytes div SizeOf(dirent);

 rwlock_wrlock(lock);
  i:=pos+count;
  if (i>Length(dirs)) then
  begin
   i:=Length(dirs);
   if (pos>i) then
   begin
    count:=0;
   end else
   begin
    count:=(i-pos);
   end;
  end;

  if (count<>0) then
  begin
   Move(dirs[pos],buf^,count*SizeOf(dirent));
  end;

  pos:=i;
 rwlock_unlock(lock);

 Writeln('getdirentries:',count,' ',i);

 if (basep<>nil) then
 begin
  basep^:=i;
 end;

 Result:=count*SizeOf(dirent);
end;

//

end.

