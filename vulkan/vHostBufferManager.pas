unit vHostBufferManager;

{$mode objfpc}{$H+}

interface

uses
 SysUtils,
 RWLock,
 sys_types,
 g23tree,
 Vulkan,
 vDevice,
 vMemory,
 vBuffer,
 vCmdBuffer;

type
 AVkSparseMemoryBind=array of TVkSparseMemoryBind;

 TvHostBuffer=class(TvBuffer)
  FAddr:Pointer;
  Fhost:TvPointer;
  Foffset:TVkDeviceSize; //offset inside buffer
  //
  FSparse:AVkSparseMemoryBind;
  //
  FRefs:ptruint;
  Procedure Acquire(Sender:TObject);
  procedure Release(Sender:TObject);
 end;

function FetchHostBuffer(cmd:TvCustomCmdBuffer;Addr:Pointer;Size:TVkDeviceSize;usage:TVkFlags):TvHostBuffer;

implementation

const
 buf_ext:TVkExternalMemoryBufferCreateInfo=(
  sType:VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO;
  pNext:nil;
  handleTypes:ord(VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_ALLOCATION_BIT_EXT);
 );

type
 TvAddrCompare=object
  function c(a,b:PPointer):Integer; static;
 end;

 _TvHostBufferSet=specialize T23treeSet<PPointer,TvAddrCompare>;
 TvHostBufferSet=object(_TvHostBufferSet)
  lock:TRWLock;
  Procedure Init;
  Procedure Lock_wr;
  Procedure Unlock;
 end;

var
 FHostBufferSet:TvHostBufferSet;

Procedure TvHostBufferSet.Init;
begin
 rwlock_init(lock);
end;

Procedure TvHostBufferSet.Lock_wr;
begin
 rwlock_wrlock(lock);
end;

Procedure TvHostBufferSet.Unlock;
begin
 rwlock_unlock(lock);
end;

function TvAddrCompare.c(a,b:PPointer):Integer;
begin
 Result:=Integer(a^>b^)-Integer(a^<b^);
end;

function _Find(Addr:Pointer):TvHostBuffer;
var
 i:TvHostBufferSet.Iterator;
begin
 Result:=nil;
 i:=FHostBufferSet.find(@Addr);
 if (i.Item<>nil) then
 begin
  Result:=TvHostBuffer(ptruint(i.Item^)-ptruint(@TvHostBuffer(nil).FAddr));
 end;
end;

function _fix_buf_size(var Offset,Size:TVkDeviceSize;usage:TVkFlags):TVkDeviceSize;
var
 mr:TVkMemoryRequirements;
 pAlign:TVkDeviceSize;
begin
 mr:=GetRequirements(Size,usage,@buf_ext);

 pAlign:=AlignDw(Offset,mr.alignment);
 Result:=(Offset-pAlign);

 Offset:=pAlign;
 Size  :=Size+Result;

 if (Size<mr.size) then Size:=mr.size;
end;

function _New_simple(host:TvPointer;Size:TVkDeviceSize;usage:TVkFlags):TvHostBuffer;
var
 t:TvHostBuffer;
 Offset,Foffset:TVkDeviceSize;
begin
 Offset :=host.FOffset;
 Foffset:=_fix_buf_size(Offset,Size,usage);

 t:=TvHostBuffer.Create(Size,usage,@buf_ext);

 t.Fhost  :=host;
 t.Foffset:=Foffset;
 t.BindMem(host);

 Result:=t;
end;

function VkBindSparseBufferMemory(queue:TVkQueue;buffer:TVkBuffer;bindCount:TVkUInt32;pBinds:PVkSparseMemoryBind):TVkResult;
var
 finfo:TVkFenceCreateInfo;
 fence:TVkFence;

 bind:TVkSparseBufferMemoryBindInfo;
 info:TVkBindSparseInfo;
begin
 finfo:=Default(TVkFenceCreateInfo);
 finfo.sType:=VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
 Result:=vkCreateFence(Device.FHandle,@finfo,nil,@fence);
 if (Result<>VK_SUCCESS) then
 begin
  Writeln(StdErr,'vkCreateFence:',Result);
  Exit;
 end;

 bind:=Default(TVkSparseBufferMemoryBindInfo);
 bind.buffer   :=buffer;
 bind.bindCount:=bindCount;
 bind.pBinds   :=pBinds;

 info:=Default(TVkBindSparseInfo);
 info.sType          :=VK_STRUCTURE_TYPE_BIND_SPARSE_INFO;
 info.bufferBindCount:=1;
 info.pBufferBinds   :=@bind;

 Result:=vkQueueBindSparse(queue,1,@info,fence);

 if (Result<>VK_SUCCESS) then
 begin
  Writeln(StdErr,'vkQueueBindSparse:',Result);
  vkDestroyFence(Device.FHandle,fence,nil);
  Exit;
 end;

 Result:=vkWaitForFences(Device.FHandle,1,@fence,VK_TRUE,TVkUInt64(-1));
 if (Result<>VK_SUCCESS) then
 begin
  Writeln(StdErr,'vkWaitForFences:',Result);
 end;

 vkDestroyFence(Device.FHandle,fence,nil);
end;

function Min(a,b:QWORD):QWORD; inline;
begin
 if (a<b) then Result:=a else Result:=b;
end;

function _New_sparce(queue:TVkQueue;Addr:Pointer;Size:TVkDeviceSize;usage:TVkFlags):TvHostBuffer;
var
 host:TvPointer;

 asize:qword;
 hsize:qword;
 msize:qword;

 Offset,Foffset:TVkDeviceSize;

 bind:TVkSparseMemoryBind;
 Binds:AVkSparseMemoryBind;
 i:Integer;

 t:TvHostBuffer;
begin
 Result:=nil;

 Offset :=TVkDeviceSize(Addr); //hack align at same in virtual mem
 Foffset:=_fix_buf_size(Offset,Size,usage);

 Binds:=Default(AVkSparseMemoryBind);
 host :=Default(TvPointer);
 hsize:=0;

 Offset:=0;
 asize:=Size;
 While (asize<>0) do
 begin
  if not TryGetHostPointerByAddr(addr,host,@hsize) then Exit;

  msize:=Min(hsize,asize);

  bind:=Default(TVkSparseMemoryBind);
  bind.resourceOffset:=Offset;
  bind.size          :=msize;
  bind.memory        :=host.FHandle;
  bind.memoryOffset  :=host.FOffset;

  i:=Length(Binds);
  SetLength(Binds,i+1);
  Binds[i]:=bind;

  //next
  Offset:=Offset+msize;
  addr  :=addr  +msize;
  asize :=asize -msize;
 end;

 t:=TvHostBuffer.CreateSparce(Size,usage,@buf_ext);

 t.Foffset:=Foffset;
 t.FSparse:=Binds;

 VkBindSparseBufferMemory(queue,t.FHandle,Length(Binds),@Binds[0]);

 Result:=t;
end;

function FetchHostBuffer(cmd:TvCustomCmdBuffer;Addr:Pointer;Size:TVkDeviceSize;usage:TVkFlags):TvHostBuffer;
var
 t:TvHostBuffer;
 host:TvPointer;

 _size:qword;

label
 _exit;

begin
 Result:=nil;

 FHostBufferSet.Lock_wr;

 t:=_Find(Addr);

 if (t<>nil) then
 begin
  if (t.FSize<Size) or
     ((t.FUsage and usage)<>usage) then
  begin
   usage:=usage or t.FUsage;
   FHostBufferSet.delete(@t.FAddr);
   t.Release(nil);
   t:=nil;
  end;
 end;

 if (t=nil) then
 begin
  //Writeln('NewBuf:',HexStr(Addr));
  host:=Default(TvPointer);
  if not TryGetHostPointerByAddr(addr,host,@_size) then
  begin
   Goto _exit;
  end;

  if (_size>=Size) then
  begin
   t:=_New_simple(host,Size,usage);
  end else
  begin //is Sparse buffers
   Assert(vDevice.sparseBinding,'sparseBinding not support');
   t:=_New_sparce(cmd.FQueue.FHandle,Addr,Size,usage);
  end;

  t.FAddr:=addr;

  FHostBufferSet.Insert(@t.FAddr);
  t.Acquire(nil);
 end;

 if (cmd<>nil) and (t<>nil) then
 begin
  if cmd.AddDependence(@t.Release) then
  begin
   t.Acquire(cmd);
  end;
 end;

 _exit:
 FHostBufferSet.Unlock;
 Result:=t;
end;

Procedure TvHostBuffer.Acquire(Sender:TObject);
begin
 System.InterlockedIncrement(Pointer(FRefs));
end;

procedure TvHostBuffer.Release(Sender:TObject);
begin
 if System.InterlockedDecrement(Pointer(FRefs))=nil then
 begin
  Free;
 end;
end;

initialization
 FHostBufferSet.Init;

end.


