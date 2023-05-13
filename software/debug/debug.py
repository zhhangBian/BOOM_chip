import serial
import time                                  #延时使用
import binascii
 
s = serial.Serial("/dev/ttyUSB1", 9600)     #初始化串口
flag=1
break_flag=0

while flag:
   command=input("please input debug command:")
   if len(command.split())==1:
      command_head=command.split()[0]
   elif len(command.split())==2:
      command_head=command.split()[0]
      command_tail=command.split()[1]
   elif len(command.split())==3:
      command_head=command.split()[0]
      command_mid=command.split()[1]
      command_tail=command.split()[2]


   if command_head=="trace" or command_head=="t":
      trace='01'+command_tail.rjust(8,'0')
      value=bytes.fromhex(trace)
      s.write(value)
      time.sleep(0.1)
      end_flag=1
      while end_flag:
         n=s.inWaiting()
         while n:
            data=str(binascii.b2a_hex(s.read_all()))[2:-1]
            time.sleep(0.5)
            print("debug_wb_wnum :"+data[0:2])
            print("debug_wb_wdata:"+data[2:10])
            end_flag=0
            break
   elif command_head=="break" or command_head=="b":
      breakpoint='02'+command_tail.rjust(8,'0')
      value=bytes.fromhex(breakpoint)
      break_flag=1
      s.write(value)
   elif command_head=="infor" and break_flag==1:
      if command_tail=='all':
         for reg in range(0,32):
            reg_num='04'+str('{:02X}'.format(reg))
            value=bytes.fromhex(reg_num)
            s.write(value)
            time.sleep(0.1)
            n=s.inWaiting()
            while n:
               data=str(binascii.b2a_hex(s.read_all()))[2:-1]
               time.sleep(0.1)
               print(str(reg)+":"+data)
               break
      else:
         reg_num='04'+str('{:02X}'.format(int(command_tail)))
         value=bytes.fromhex(reg_num)
         s.write(value)
         time.sleep(0.1)
         n=s.inWaiting()
         while n:
             data=str(binascii.b2a_hex(s.read_all()))[2:-1]
             time.sleep(0.1)
             print(data)
             break
   elif command_head=="infom" and break_flag==1:
      if len(command.split())==2:
         mem_addr='05'+command_tail.rjust(8,'0')
         value=bytes.fromhex(mem_addr)
         s.write(value)
         time.sleep(0.1)
         n=s.inWaiting()
         while n:
            data=str(binascii.b2a_hex(s.read_all()))[2:-1]
            time.sleep(0.1)
            print(data)
            break
      else:
         for addr in range(int(command_mid,16),int(command_tail,16)+1):
            mem_addr='05'+str(hex(addr))[2:].rjust(8,'0')
            value=bytes.fromhex(mem_addr)
            s.write(value)
            time.sleep(0.1)
            n=s.inWaiting()
            while n:
               data=str(binascii.b2a_hex(s.read_all()))[2:-1]
               time.sleep(0.1)
               print(str(hex(addr))[2:]+":"+data)
               break			   
   elif command_head=="continue" or command_head=="c" and break_flag==1:
      value=bytes.fromhex('03')
      break_flag=0
      s.write(value)
   elif command_head=="step" and break_flag==1: 
      if len(command.split())==2:
         for count in range(0,int(command_tail)):
            value=bytes.fromhex('06')
            s.write(value)
            time.sleep(0.1)
      else:
         value=bytes.fromhex('06')
         s.write(value)
   elif command_head=="list":
      value=bytes.fromhex('07')
      s.write(value)
      time.sleep(0.1)
      n=s.inWaiting()
      while n:
         data=str(binascii.b2a_hex(s.read_all()))[2:-1]
         time.sleep(0.1)
         print(data)
         break
   elif command_head=="exit":
      flag=0
   elif break_flag==0:
      print("please enter break/b command first")
   else:
      print("invalid command!please enter right command")
