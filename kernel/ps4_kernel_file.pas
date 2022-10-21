unit ps4_kernel_file;

{$mode objfpc}{$H+}

interface

uses
  windows,
  sys_types,
  sys_path,
  Classes,
  SysUtils;

const
 NAME_MAX  =255;  // max bytes in a file name
 PATH_MAX  =1024; // max bytes in pathname
 IOV_MAX   =1024; // max elements in i/o vector
 MAXNAMLEN =255;

 O_RDONLY  =$0000;  // open for reading only
 O_WRONLY  =$0001;  // open for writing only
 O_RDWR    =$0002;  // open for reading and writing
 O_ACCMODE =$0003;  // mask for above modes

 O_NONBLOCK =$0004;  // no delay
 O_APPEND   =$0008;  // set append mode
 O_SYNC     =$0080;  // POSIX synonym for O_FSYNC
 O_CREAT    =$0200;  // create if nonexistent
 O_TRUNC    =$0400;  // truncate to zero length
 O_EXCL     =$0800;  // error if already exists
 O_DSYNC    =$1000;  // synchronous data writes(omit inode writes)

 O_DIRECT   =$00010000;
 O_FSYNC    =$0080;  // synchronous writes

 O_DIRECTORY =$00020000; // Fail if not directory
 O_EXEC      =$00040000; // Open for execute only

 S_IRWXU  =&0000700;   // RWX mask for owner
 S_IRUSR  =&0000400;   // R for owner
 S_IWUSR  =&0000200;   // W for owner
 S_IXUSR  =&0000100;   // X for owner

 S_IRWXG  =&0000070;   // RWX mask for group
 S_IRGRP  =&0000040;   // R for group
 S_IWGRP  =&0000020;   // W for group
 S_IXGRP  =&0000010;   // X for group

 S_IRWXO  =&0000007;   // RWX mask for other
 S_IROTH  =&0000004;   // R for other
 S_IWOTH  =&0000002;   // W for other
 S_IXOTH  =&0000001;   // X for other

 S_IFMT   =&0170000; // type of file mask
 S_IFIFO  =&0010000; // named pipe (fifo)
 S_IFCHR  =&0020000; // character special
 S_IFDIR  =&0040000; // directory
 S_IFBLK  =&0060000; // block special
 S_IFREG  =&0100000; // regular
 S_IFLNK  =&0120000; // symbolic link
 S_IFSOCK =&0140000; // socket
 S_ISVTX  =&0001000; // save swapped text even after use

 F_GETFL  =3;  // get file status flags
 F_SETFL  =4;  // set file status flags

 SEEK_SET =0; // set file offset to offset
 SEEK_CUR =1; // set file offset to current plus offset
 SEEK_END =2; // set file offset to EOF plus offset

 MAP_SHARED  =$0001;  // share changes
 MAP_PRIVATE =$0002;  // changes are private

 MAP_FILE   =$0000; // map from file (default)
 MAP_ANON   =$1000; // allocated from memory, swap space
 MAP_SYSTEM =$2000;

 MAP_NOCORE  =$00020000; // dont include these pages in a coredump
 MAP_NOSYNC  =$0800; // page to but do not sync underlying file
 MAP_PREFAULT_READ =$00040000; // prefault mapping for reading

 DT_UNKNOWN =0;
 DT_DIR     =4;
 DT_REG     =8;

 SCE_KERNEL_NAME_MAX        =NAME_MAX;
 SCE_KERNEL_PATH_MAX        =PATH_MAX;
 SCE_KERNEL_IOV_MAX         =IOV_MAX;
 SCE_KERNEL_MAXNAMLEN       =MAXNAMLEN;

 SCE_KERNEL_O_RDONLY        =O_RDONLY;
 SCE_KERNEL_O_WRONLY        =O_WRONLY;
 SCE_KERNEL_O_RDWR          =O_RDWR ;
 SCE_KERNEL_O_NONBLOCK      =O_NONBLOCK;
 SCE_KERNEL_O_APPEND        =O_APPEND;
 SCE_KERNEL_O_CREAT         =O_CREAT;
 SCE_KERNEL_O_TRUNC         =O_TRUNC;
 SCE_KERNEL_O_EXCL          =O_EXCL;
 SCE_KERNEL_O_DIRECT        =O_DIRECT;
 SCE_KERNEL_O_FSYNC         =O_FSYNC;
 SCE_KERNEL_O_SYNC          =O_SYNC;
 SCE_KERNEL_O_DSYNC         =O_DSYNC;
 SCE_KERNEL_O_DIRECTORY     =O_DIRECTORY;

 SCE_KERNEL_S_IFMT          =S_IFMT;
 SCE_KERNEL_S_IFDIR         =S_IFDIR;
 SCE_KERNEL_S_IFREG         =S_IFREG;

 SCE_KERNEL_S_IRUSR         =(S_IRUSR or S_IRGRP or S_IROTH or S_IXUSR or S_IXGRP or S_IXOTH);
 SCE_KERNEL_S_IWUSR         =(S_IWUSR or S_IWGRP or S_IWOTH or S_IXUSR or S_IXGRP or S_IXOTH);
 SCE_KERNEL_S_IXUSR         =(S_IXUSR or S_IXGRP or S_IXOTH);
 SCE_KERNEL_S_IRWXU         =(SCE_KERNEL_S_IRUSR or SCE_KERNEL_S_IWUSR);

 SCE_KERNEL_S_IRWU          =(SCE_KERNEL_S_IRUSR or SCE_KERNEL_S_IWUSR);
// 00777, R/W
 SCE_KERNEL_S_IRU           =(SCE_KERNEL_S_IRUSR);
// 00555, R

 SCE_KERNEL_S_INONE         =&0000000;

 //SCE_KERNEL_S_ISDIR(m)      =S_ISDIR(m);
 //SCE_KERNEL_S_ISREG(m)      =S_ISREG(m);

// for sceKernelFcntl()
 SCE_KERNEL_F_GETFL         =F_GETFL;
 SCE_KERNEL_F_SETFL         =F_SETFL;

// for sceKernelLseek()
 SCE_KERNEL_SEEK_SET        =SEEK_SET;
 SCE_KERNEL_SEEK_CUR        =SEEK_CUR;
 SCE_KERNEL_SEEK_END        =SEEK_END;

// for sceKernelMmap()
 SCE_KERNEL_MAP_NOCORE      =MAP_NOCORE;
 SCE_KERNEL_MAP_NOSYNC      =MAP_NOSYNC;
 SCE_KERNEL_MAP_PREFAULT_READ=MAP_PREFAULT_READ;
 SCE_KERNEL_MAP_PRIVATE     =MAP_PRIVATE;
 SCE_KERNEL_MAP_SHARED      =MAP_SHARED;

// for SceKernelDirent
 SCE_KERNEL_DT_UNKNOWN      =DT_UNKNOWN;
 SCE_KERNEL_DT_DIR          =DT_DIR;
 SCE_KERNEL_DT_REG          =DT_REG;

// for sceKernelSetCompress
 SCE_KERNEL_COMPRESS_FILE_MAGIC =($43534650);
 SCE_KERNEL_SET_COMPRESS_FILE   =(1);
 SCE_KERNEL_SET_REGULAR_FILE    =(0);

// for sceKernelLwfsSetAttribute
 SCE_KERNEL_LWFS_DISABLE =(0);
 SCE_KERNEL_LWFS_ENABLE  =(1);

type
 p_iovec=^iovec;
 iovec=packed record
  iov_base:Pointer; //Base address.
  iov_len :QWORD;   //Length.
 end;

 PSceKernelStat=^SceKernelStat;
 SceKernelStat=packed object
  type
   __dev_t  =DWORD;
   ino_t    =DWORD;
   mode_t   =Word;
   nlink_t  =Word;
   uid_t    =DWORD;
   gid_t    =DWORD;
   off_t    =Int64;
   blkcnt_t =Int64;
   blksize_t=DWORD;
   fflags_t =DWORD;
  var
   st_dev     :__dev_t   ;      // inode's device
   st_ino     :ino_t     ;      // inode's number
   st_mode    :mode_t    ;      // inode protection mode         S_IFMT.....
   st_nlink   :nlink_t   ;      // number of hard links
   st_uid     :uid_t     ;      // user ID of the file's owner   S_IRWXU....
   st_gid     :gid_t     ;      // group ID of the file's group  S_IRWXG....
   st_rdev    :__dev_t   ;      // device type
   st_atim    :timespec  ;      // time of last access
   st_mtim    :timespec  ;      // time of last data modification
   st_ctim    :timespec  ;      // time of last file status change
   st_size    :off_t     ;      // file size, in bytes
   st_blocks  :blkcnt_t  ;      // blocks allocated for file
   st_blksize :blksize_t ;      // optimal blocksize for I/O
   st_flags   :fflags_t  ;      // user defined flags for file
   st_gen     :DWORD     ;      // file generation number
   st_lspare  :DWORD     ;
   st_birthtim:timespec  ;      // time of file creation
 end;

function ps4_open(path:PChar;flags,mode:Integer):Integer; SysV_ABI_CDecl;
function ps4_sceKernelOpen(path:PChar;flags,mode:Integer):Integer; SysV_ABI_CDecl;
function ps4_sceKernelLseek(fd:Integer;offset:Int64;whence:Integer):Int64; SysV_ABI_CDecl;
function ps4_sceKernelWrite(fd:Integer;buf:Pointer;nbytes:Int64):Int64; SysV_ABI_CDecl;
function ps4_sceKernelRead(fd:Integer;buf:Pointer;nbytes:Int64):Int64; SysV_ABI_CDecl;
function ps4_sceKernelPread(fd:Integer;buf:Pointer;nbytes,offset:Int64):Int64; SysV_ABI_CDecl;
function ps4_close(fd:Integer):Integer; SysV_ABI_CDecl;
function ps4_sceKernelClose(fd:Integer):Integer; SysV_ABI_CDecl;

function ps4_stat(path:PChar;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
function ps4_sceKernelStat(path:PChar;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;

function ps4_fstat(fd:Integer;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
function ps4_sceKernelFstat(fd:Integer;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;

function ps4_write(fd:Integer;data:Pointer;size:QWORD):Int64; SysV_ABI_CDecl;
function ps4_read(fd:Integer;data:Pointer;size:QWORD):Int64; SysV_ABI_CDecl;

function ps4_readv(fd:Integer;vector:p_iovec;count:Integer):Int64; SysV_ABI_CDecl;

function ps4_lseek(fd:Integer;offset:Int64;whence:Integer):Int64; SysV_ABI_CDecl;

function ps4_sceKernelMkdir(path:PChar;mode:Integer):Integer; SysV_ABI_CDecl;
function ps4_mkdir(path:PChar):Integer; SysV_ABI_CDecl;

function ps4_sceKernelCheckReachability(path:PChar):Integer; SysV_ABI_CDecl;

implementation

uses
 sys_kernel,
 sys_signal,
 sys_time;

Function get_DesiredAccess(flags:Integer):DWORD;
begin
 Result:=0;
 if (flags and SCE_KERNEL_O_RDWR)<>0 then
 begin
  Result:=GENERIC_READ or GENERIC_WRITE;
 end else
 if (flags and SCE_KERNEL_O_WRONLY)<>0 then
 begin
  Result:=GENERIC_WRITE;
 end else
 begin
  Result:=GENERIC_READ;
 end;

 if (flags and SCE_KERNEL_O_APPEND)<>0 then
 begin
  Result:=Result or FILE_APPEND_DATA;
 end;
end;

Function get_CreationDisposition(flags:Integer):DWORD;
const
 CREAT_EXCL=SCE_KERNEL_O_CREAT or SCE_KERNEL_O_EXCL;
begin
 Result:=0;
 if (flags and CREAT_EXCL)=CREAT_EXCL then
 begin
  Result:=CREATE_NEW;
 end else
 if (flags and SCE_KERNEL_O_CREAT)<>0 then
 begin
  Result:=CREATE_ALWAYS;
 end else
 if (flags and SCE_KERNEL_O_TRUNC)<>0 then
 begin
  Result:=TRUNCATE_EXISTING;
 end else
 begin
  Result:=OPEN_EXISTING;
 end;
end;

var
 dev_random_nm:array[0..1] of PChar=('/dev/random','/dev/urandom');
 dev_random_fd:Integer=-1;

function _sys_open(path:PChar;flags,mode:Integer;var fd:Integer):Integer;
const
 WR_RDWR=O_WRONLY or O_RDWR;
 O_OFS=O_RDONLY or O_WRONLY or O_RDWR or O_APPEND;

var
 h:THandle;

 err:DWORD;
 dwDesiredAccess:DWORD;
 dwCreationDisposition:DWORD;

 rp:RawByteString;
 wp:WideString;
begin
 Result:=0;
 if (path=nil) then Exit(EINVAL);

 Writeln('open:',path,' ',flags,' ',mode);

 Assert((flags and O_DIRECTORY)=0,'folder open TODO');

 if ((flags and WR_RDWR)=WR_RDWR) then
 begin
  Exit(EINVAL);
 end;

 if (path[0]=#0) then
 begin
  Exit(ENOENT);
 end;

 if (CompareChar0(path^,dev_random_nm[0]^,Length(dev_random_nm[0]))=0) or
    (CompareChar0(path^,dev_random_nm[1]^,Length(dev_random_nm[1]))=0) then
 begin
  if (dev_random_fd<>-1) then
  begin
   Exit(dev_random_fd);
  end else
  begin
   h:=_get_osfhandle(0);

   Result:=_open_osfhandle(h,flags and O_OFS);

   if (Result<>0) then
   begin
    Exit(EMFILE);
   end else
   begin
    dev_random_fd:=Result;
   end;
  end;
  Exit(0);
 end;

 rp:='';
 Result:=parse_filename(path,rp);

 if (Result<>0) then
 begin
  Exit(EACCES);
 end;

 wp:=UTF8Decode(rp);

 dwDesiredAccess:=get_DesiredAccess(flags);
 dwCreationDisposition:=get_CreationDisposition(flags);

 h:=CreateFileW(
  PWideChar(wp),
  dwDesiredAccess,
  FILE_SHARE_READ,
  nil,
  dwCreationDisposition,
  FILE_ATTRIBUTE_NORMAL,
  0
 );

 if (h=INVALID_HANDLE_VALUE) then
 begin
  err:=GetLastError;
  //Writeln('GetLastError:',err{,' ',ps4_pthread_self^.sig._lock});
  Case err of
   ERROR_INVALID_DRIVE,
   ERROR_PATH_NOT_FOUND,
   ERROR_FILE_NOT_FOUND   :Exit(ENOENT);
   ERROR_ACCESS_DENIED    :Exit(EACCES);
   ERROR_BUFFER_OVERFLOW  :Exit(ENAMETOOLONG);
   ERROR_NOT_ENOUGH_MEMORY:Exit(ENOMEM);
   ERROR_ALREADY_EXISTS   :Exit(EEXIST);
   ERROR_FILE_EXISTS      :Exit(EEXIST);
   ERROR_DISK_FULL:        Exit(ENOSPC);
   else
                           Exit(EIO);
  end;
 end;

 fd:=_open_osfhandle(h,flags and O_OFS);

 if (fd<0) then
 begin
  CloseHandle(h);
  Exit(EMFILE);
 end;

end;

function ps4_open(path:PChar;flags,mode:Integer):Integer; SysV_ABI_CDecl;
var
 fd:Integer;
begin
 fd:=0;
 _sig_lock;
 Result:=_sys_open(path,flags,mode,fd);
 _sig_unlock;

 if (Result<>0) then
 begin
  Result:=_set_errno(Result);
 end else
 begin
  Result:=fd;
 end;
end;

function ps4_sceKernelOpen(path:PChar;flags,mode:Integer):Integer; SysV_ABI_CDecl;
var
 fd:Integer;
begin
 fd:=0;
 _sig_lock;
 Result:=_sys_open(path,flags,mode,fd);
 _sig_unlock;

 if (Result<>0) then
 begin
  _set_errno(Result);
  Result:=px2sce(Result);
 end else
 begin
  Result:=fd;
 end;
end;

function _sys_close(fd:Integer):Integer;
begin
 if (dev_random_fd<>-1) and (dev_random_fd=fd) then
 begin
  Exit(0);
 end;

 Result:=_close(fd);

 if (Result<>0) then
 begin
  Result:=EBADF;
 end;
end;

function ps4_close(fd:Integer):Integer; SysV_ABI_CDecl;
begin
 _sig_lock;
 Result:=_set_errno(_sys_close(fd));
 _sig_unlock;
end;

function ps4_sceKernelClose(fd:Integer):Integer; SysV_ABI_CDecl;
begin
 _sig_lock;
 Result:=_sys_close(fd);
 _sig_unlock;
 _set_errno(Result);
 Result:=px2sce(Result);
end;

function ps4_sceKernelLseek(fd:Integer;offset:Int64;whence:Integer):Int64; SysV_ABI_CDecl;
var
 h:THandle;
begin
 if (dev_random_fd=fd) then Exit(SCE_KERNEL_ERROR_EINVAL);

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 _sig_lock;
 case whence of
  SCE_KERNEL_SEEK_SET:Result:=FileSeek(h,offset,fsFromBeginning);
  SCE_KERNEL_SEEK_CUR:Result:=FileSeek(h,offset,fsFromCurrent);
  SCE_KERNEL_SEEK_END:Result:=FileSeek(h,offset,fsFromEnd);
  else
                      Result:=_set_sce_errno(SCE_KERNEL_ERROR_EINVAL);
 end;
 _sig_unlock;

 if (Result=-1) then
 begin
  Result:=_set_sce_errno(SCE_KERNEL_ERROR_EOVERFLOW);
 end else
 begin
  _set_sce_errno(0);
 end;
end;

function ps4_sceKernelWrite(fd:Integer;buf:Pointer;nbytes:Int64):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
begin
 if (dev_random_fd=fd) then Exit(SCE_KERNEL_ERROR_EINVAL);

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 if (buf=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EFAULT));
 if (nbytes<0) or (nbytes>High(Integer)) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));

 N:=0;
 _sig_lock;
 if WriteFile(h,buf^,nbytes,N,nil) then
 begin
  Result:=N;
  _set_sce_errno(0);
 end else
 begin
  Result:=_set_sce_errno(SCE_KERNEL_ERROR_EIO);
 end;
 _sig_unlock;
end;

const
 BCRYPT_USE_SYSTEM_PREFERRED_RNG=2;

function BCryptGenRandom(hAlgorithm:Pointer;
                         pbBuffer:PByte;
                         cbBuffer:DWORD;
                         dwFlags:DWORD):DWORD; stdcall; external 'Bcrypt';

function ps4_sceKernelRead(fd:Integer;buf:Pointer;nbytes:Int64):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
begin
 if (buf=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EFAULT));
 if (nbytes<0) or (nbytes>High(Integer)) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));

 if (dev_random_fd<>-1) and (dev_random_fd=fd) then
 begin
  BCryptGenRandom(nil,buf,nbytes,BCRYPT_USE_SYSTEM_PREFERRED_RNG);
  Result:=nbytes;
  _set_sce_errno(0);
  Exit;
 end;

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 N:=0;
 _sig_lock;
 if ReadFile(h,buf^,nbytes,N,nil) then
 begin
  Result:=N;
  _set_sce_errno(0);
 end else
 begin
  Result:=_set_sce_errno(SCE_KERNEL_ERROR_EIO);
 end;
 _sig_unlock;
end;

function ps4_sceKernelPread(fd:Integer;buf:Pointer;nbytes,offset:Int64):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
 O:TOVERLAPPED;
begin
 if (buf=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EFAULT));
 if (nbytes<0) or (nbytes>High(Integer)) or (offset<0) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));

 if (dev_random_fd<>-1) and (dev_random_fd=fd) then
 begin
  BCryptGenRandom(nil,buf,nbytes,BCRYPT_USE_SYSTEM_PREFERRED_RNG);
  Result:=nbytes;
  _set_sce_errno(0);
  Exit;
 end;

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 O:=Default(TOVERLAPPED);
 PInt64(@O.Offset)^:=offset;

 N:=0;
 _sig_lock;
 if ReadFile(h,buf^,nbytes,N,@O) then
 begin
  Result:=N;
  _set_sce_errno(0);
 end else
 begin
  Result:=_set_sce_errno(SCE_KERNEL_ERROR_EIO);
 end;
 _sig_unlock;
end;

function file_attr_to_st_mode(attr:DWORD):Word;
begin
 Result:=S_IRUSR;
 if ((attr and FILE_ATTRIBUTE_DIRECTORY)<>0) then
  Result:=Result or S_IFDIR
 else
  Result:=Result or S_IFREG;

 if ((attr and FILE_ATTRIBUTE_READONLY)=0) then
  Result:=Result or S_IWUSR;
end;

function ps4_stat(path:PChar;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
begin
 Result:=_set_errno(sce2px(ps4_sceKernelStat(path,stat)));
end;

function ps4_sceKernelStat(path:PChar;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
var
 rp:RawByteString;
 hfi:WIN32_FILE_ATTRIBUTE_DATA;
 err:DWORD;
begin
 if (path=nil) or (stat=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));
 if (path[0]=#0) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));
 end;

 stat^:=Default(SceKernelStat);

 rp:='';
 _sig_lock;
 Result:=parse_filename(path,rp);
 _sig_unlock;

 if (Result<>0) then
 begin
  Exit(_set_sce_errno(px2sce(EACCES)));
 end;

 hfi:=Default(WIN32_FILE_ATTRIBUTE_DATA);
 err:=SwGetFileAttributes(rp,@hfi);
 if (err<>0) then
 begin
  //Writeln('GetLastError:',err{,' ',ps4_pthread_self^.sig._lock});
  Case err of
   ERROR_ACCESS_DENIED,
   ERROR_SHARING_VIOLATION,
   ERROR_LOCK_VIOLATION,
   ERROR_SHARING_BUFFER_EXCEEDED:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_EACCES));

   ERROR_BUFFER_OVERFLOW:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENAMETOOLONG));

   ERROR_NOT_ENOUGH_MEMORY:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOMEM));

   else
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));
  end;
 end;

 stat^.st_mode    :=file_attr_to_st_mode(hfi.dwFileAttributes);
 stat^.st_size    :=hfi.nFileSizeLow or (QWORD(hfi.nFileSizeHigh) shl 32);

 stat^.st_atim    :=filetime_to_timespec(hfi.ftLastAccessTime);
 stat^.st_mtim    :=filetime_to_timespec(hfi.ftLastWriteTime);
 stat^.st_ctim    :=stat^.st_mtim;
 stat^.st_birthtim:=filetime_to_timespec(hfi.ftCreationTime);

 stat^.st_blocks  :=((stat^.st_size+511) div 512);
 stat^.st_blksize :=512;

 _set_errno(0);
 Result:=0;
end;

function ps4_fstat(fd:Integer;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
begin
 Result:=_set_errno(sce2px(ps4_sceKernelFstat(fd,stat)));
end;

function ps4_sceKernelFstat(fd:Integer;stat:PSceKernelStat):Integer; SysV_ABI_CDecl;
var
 h:THandle;
 hfi:TByHandleFileInformation;
 err:DWORD;
begin
 if (stat=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));

 stat^:=Default(SceKernelStat);

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 Case SwGetFileType(h) of
  FILE_TYPE_PIPE:
    begin
     stat^.st_dev  :=fd;
     stat^.st_rdev :=fd;
     stat^.st_mode :=S_IFIFO;
     stat^.st_nlink:=1;
    end;
  FILE_TYPE_CHAR:
    begin
     stat^.st_dev  :=fd;
     stat^.st_rdev :=fd;
     stat^.st_mode :=S_IFCHR;
     stat^.st_nlink:=1;
    end;
  FILE_TYPE_DISK:
    begin
     err:=SwGetFileInformationByHandle(h,@hfi);
     if (err<>0) then
     begin
      //Writeln('GetLastError:',err{,' ',ps4_pthread_self^.sig._lock});
      Case err of
       ERROR_ACCESS_DENIED,
       ERROR_SHARING_VIOLATION,
       ERROR_LOCK_VIOLATION,
       ERROR_SHARING_BUFFER_EXCEEDED:
         Exit(_set_sce_errno(SCE_KERNEL_ERROR_EACCES));

       ERROR_BUFFER_OVERFLOW:
         Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENAMETOOLONG));

       ERROR_NOT_ENOUGH_MEMORY:
         Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOMEM));

       else
         Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));
      end;
     end;

     stat^.st_mode    :=file_attr_to_st_mode(hfi.dwFileAttributes);
     stat^.st_size    :=hfi.nFileSizeLow or (QWORD(hfi.nFileSizeHigh) shl 32);
     stat^.st_nlink   :=Word(hfi.nNumberOfLinks);
     stat^.st_gen     :=hfi.nFileIndexLow;

     stat^.st_atim    :=filetime_to_timespec(hfi.ftLastAccessTime);
     stat^.st_mtim    :=filetime_to_timespec(hfi.ftLastWriteTime);
     stat^.st_ctim    :=stat^.st_mtim;
     stat^.st_birthtim:=filetime_to_timespec(hfi.ftCreationTime);

     stat^.st_blocks  :=((stat^.st_size+511) div 512);
     stat^.st_blksize :=512;
    end;

  else
   Exit(_set_sce_errno(SCE_KERNEL_ERROR_EBADF));
 end;

 _set_sce_errno(0);
 Result:=0;
end;

function GetStr(p:Pointer;L:SizeUint):RawByteString;
begin
 SetString(Result,P,L);
end;

function ps4_write(fd:Integer;data:Pointer;size:QWORD):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
begin
 if (data=nil) then Exit(_set_errno(EFAULT));
 if (size>High(Integer)) then Exit(_set_errno(EINVAL));

 if (dev_random_fd=fd) then Exit(_set_errno(EINVAL));

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_errno(EBADF));
 end;

 N:=0;
 _sig_lock;
 if WriteFile(h,data^,size,N,nil) then
 begin
  Result:=N;
  _set_errno(0);
 end else
 begin
  Result:=_set_errno(EIO);
 end;
 _sig_unlock;
end;

function ps4_read(fd:Integer;data:Pointer;size:QWORD):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
begin
 if (data=nil) then Exit(_set_errno(EFAULT));
 if (size>High(Integer)) then Exit(_set_errno(EINVAL));

 if (dev_random_fd<>-1) and (dev_random_fd=fd) then
 begin
  BCryptGenRandom(nil,data,size,BCRYPT_USE_SYSTEM_PREFERRED_RNG);
  Result:=size;
  _set_errno(0);
  Exit;
 end;

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_errno(EBADF));
 end;

 N:=0;
 _sig_lock;
 if ReadFile(h,data^,size,N,nil) then
 begin
  Result:=N;
  _set_errno(0);
 end else
 begin
  Result:=_set_errno(EIO);
 end;
 _sig_unlock;
end;

function ps4_readv(fd:Integer;vector:p_iovec;count:Integer):Int64; SysV_ABI_CDecl;
var
 h:THandle;
 N:DWORD;
 i:Integer;
begin
 if (vector=nil) then Exit(_set_errno(EFAULT));

 if (count=0) then Exit(_set_errno(EINVAL));

 if (dev_random_fd<>-1) and (dev_random_fd=fd) then
 begin

  Result:=0;
  For i:=0 to count-1 do
  begin
   if (vector[i].iov_base=nil) then Exit(_set_errno(EFAULT));
   if (vector[i].iov_len=0) then Exit(_set_errno(EINVAL));

   BCryptGenRandom(nil,vector[i].iov_base,vector[i].iov_len,BCRYPT_USE_SYSTEM_PREFERRED_RNG);
   Result:=Result+vector[i].iov_len;
  end;

  _set_errno(0);
  Exit;
 end;

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_errno(EBADF));
 end;

 _sig_lock;

 Result:=0;
 For i:=0 to count-1 do
 begin
  if (vector[i].iov_base=nil) then Exit(_set_errno(EFAULT));
  if (vector[i].iov_len=0) then Exit(_set_errno(EINVAL));

  N:=0;
  if ReadFile(h,vector[i].iov_base^,vector[i].iov_len,N,nil) then
  begin
   Result:=Result+N;
   if (N<vector[i].iov_len) then Exit;
  end else
  begin
   Result:=_set_errno(EIO);
   Break;
  end;

 end;

 if (Result>=0) then
 begin
  _set_errno(0);
 end;

 _sig_unlock;
end;

function ps4_lseek(fd:Integer;offset:Int64;whence:Integer):Int64; SysV_ABI_CDecl;
var
 h:THandle;
begin
 if (dev_random_fd=fd) then Exit(_set_errno(EINVAL));

 _sig_lock;
 h:=_get_osfhandle(fd);
 _sig_unlock;

 if (h=INVALID_HANDLE_VALUE) then
 begin
  Exit(_set_errno(EBADF));
 end;

 _sig_lock;
 case whence of
  SCE_KERNEL_SEEK_SET:Result:=FileSeek(h,offset,fsFromBeginning);
  SCE_KERNEL_SEEK_CUR:Result:=FileSeek(h,offset,fsFromCurrent);
  SCE_KERNEL_SEEK_END:Result:=FileSeek(h,offset,fsFromEnd);
  else
                      Result:=_set_errno(EINVAL);
 end;
 _sig_unlock;

 if (Result=-1) then
 begin
  Result:=_set_errno(EOVERFLOW);
 end else
 begin
  _set_errno(0);
 end;
end;

function ps4_sceKernelMkdir(path:PChar;mode:Integer):Integer; SysV_ABI_CDecl;
var
 fn:RawByteString;
 err:DWORD;
begin
 Result:=0;

 if (path=nil) then Exit(SCE_KERNEL_ERROR_EINVAL);
 if (path[0]=#0) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));
 end;

 Writeln('sceKernelMkdir:',path,'(',OctStr(mode,3),')');

 fn:='';
 _sig_lock;
 Result:=parse_filename(path,fn);
 _sig_unlock;

 if (Result<>0) then
 begin
  Exit(_set_sce_errno(px2sce(EACCES)));
 end;

 err:=SwCreateDir(fn);

 if (err<>0) then
 begin
  Case err of
   ERROR_INVALID_DRIVE,
   ERROR_PATH_NOT_FOUND,
   ERROR_FILE_NOT_FOUND:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));

   ERROR_ACCESS_DENIED,
   ERROR_SHARING_VIOLATION,
   ERROR_LOCK_VIOLATION,
   ERROR_SHARING_BUFFER_EXCEEDED:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_EACCES));

   ERROR_BUFFER_OVERFLOW:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENAMETOOLONG));

   ERROR_NOT_ENOUGH_MEMORY:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOMEM));

   ERROR_ALREADY_EXISTS,
   ERROR_FILE_EXISTS:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_EEXIST));

   ERROR_DISK_FULL:
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOSPC));

   else
     Exit(_set_sce_errno(SCE_KERNEL_ERROR_EIO));
  end;
 end;

 _set_sce_errno(0);
end;

function ps4_mkdir(path:PChar):Integer; SysV_ABI_CDecl;
var
 fn:RawByteString;
 err:DWORD;
begin
 Result:=0;

 if (path=nil) then Exit(_set_errno(EINVAL));
 if (path[0]=#0) then
 begin
  Exit(_set_errno(ENOENT));
 end;

 Writeln('mkdir:',path);

 fn:='';
 _sig_lock;
 Result:=parse_filename(path,fn);
 _sig_unlock;

 if (Result<>0) then
 begin
  Exit(_set_errno(EACCES));
 end;

 err:=SwCreateDir(fn);

 if (err<>0) then
 begin
  Case err of
   ERROR_INVALID_DRIVE,
   ERROR_PATH_NOT_FOUND,
   ERROR_FILE_NOT_FOUND:
     Exit(_set_errno(ENOENT));

   ERROR_ACCESS_DENIED,
   ERROR_SHARING_VIOLATION,
   ERROR_LOCK_VIOLATION,
   ERROR_SHARING_BUFFER_EXCEEDED:
     Exit(_set_errno(EACCES));

   ERROR_BUFFER_OVERFLOW:
     Exit(_set_errno(ENAMETOOLONG));

   ERROR_NOT_ENOUGH_MEMORY:
     Exit(_set_errno(ENOMEM));

   ERROR_ALREADY_EXISTS,
   ERROR_FILE_EXISTS:
     Exit(_set_errno(EEXIST));

   ERROR_DISK_FULL:
     Exit(_set_errno(ENOSPC));

   else
     Exit(_set_errno(EIO));
  end;
 end;

 _set_errno(0);
end;

function ps4_sceKernelCheckReachability(path:PChar):Integer; SysV_ABI_CDecl;
var
 fn:RawByteString;
begin
 Result:=0;

 if (path=nil) then Exit(_set_sce_errno(SCE_KERNEL_ERROR_EINVAL));
 if (path[0]=#0) then
 begin
  Exit(_set_sce_errno(SCE_KERNEL_ERROR_ENOENT));
 end;

 Writeln('sceKernelCheckReachability:',path);

 fn:='';
 _sig_lock;
 Result:=parse_filename(path,fn);
 _sig_unlock;

 if (Result<>0) then
 begin
  Exit(_set_sce_errno(px2sce(EACCES)));
 end;

 if FileExists(fn) or DirectoryExists(fn) then
 begin
  Result:=0;
  _set_errno(0);
 end else
 begin
  Result:=_set_sce_errno(SCE_KERNEL_ERROR_ENOENT);
 end;

end;

end.

